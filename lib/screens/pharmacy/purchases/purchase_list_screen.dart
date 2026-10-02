import 'package:flutter/material.dart';

import '../../../models/purchase_model.dart';
import '../../../repositories/purchase_repository.dart';
import '../../../services/auth_service.dart';
import '../../../core/localization/app_localizations.dart';
import 'add_purchase_screen.dart';

String _t(BuildContext context, String english, String swahili) {
  return AppLocalizations.of(context).isSwahili ? swahili : english;
}

class PurchaseListScreen extends StatefulWidget {
  const PurchaseListScreen({
    super.key,
  });

  @override
  State<PurchaseListScreen> createState() =>
      _PurchaseListScreenState();
}

class _PurchaseListScreenState
    extends State<PurchaseListScreen> {
  final PurchaseRepository _purchaseRepository =
      PurchaseRepository();

  final AuthService _authService = AuthService();

  final TextEditingController _searchController =
      TextEditingController();

  String? _pharmacyId;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPharmacy();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();

    super.dispose();
  }

  Future<void> _loadPharmacy() async {
    try {
      final pharmacyId =
          await _authService.getCurrentPharmacyId();

      if (!mounted) {
        return;
      }

      setState(() {
        _pharmacyId = pharmacyId;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_t(context, 'Failed to load pharmacy information:', 'Imeshindikana kupakia taarifa za famasi:')} $e',
          ),
        ),
      );
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery =
          _searchController.text.trim().toLowerCase();
    });
  }

  Future<void> _openAddPurchase() async {
    if (_pharmacyId == null) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddPurchaseScreen(
          pharmacyId: _pharmacyId!,
        ),
      ),
    );
  }

  List<PurchaseModel> _filterPurchases(
    List<PurchaseModel> purchases,
  ) {
    if (_searchQuery.isEmpty) {
      return purchases;
    }

    return purchases.where((purchase) {
      return purchase.medicineName
              .toLowerCase()
              .contains(_searchQuery) ||
          purchase.supplierName
              .toLowerCase()
              .contains(_searchQuery);
    }).toList();
  }

  double _totalCost(
    List<PurchaseModel> purchases,
  ) {
    return purchases.fold<double>(
      0,
      (total, purchase) =>
          total + purchase.totalCost,
    );
  }

  String _formatCurrency(double value) {
    return 'TSh ${value.toStringAsFixed(0)}';
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '-';
    }

    final day =
        date.day.toString().padLeft(2, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String _formatTime(DateTime? date) {
    if (date == null) {
      return '';
    }

    final hour =
        date.hour.toString().padLeft(2, '0');

    final minute =
        date.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_t(context, 'Purchases', 'Manunuzi')),
        actions: [
          IconButton(
            tooltip: _t(context, 'Refresh', 'Onyesha upya'),
            onPressed: () {
              setState(() {});
            },
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: _openAddPurchase,
        icon: const Icon(
          Icons.add_shopping_cart_rounded,
        ),
        label: Text(_t(context, 'Add Purchase', 'Ongeza Manunuzi')),
      ),
      body: _pharmacyId == null
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : StreamBuilder<List<PurchaseModel>>(
              stream:
                  _purchaseRepository.watchPurchases(
                _pharmacyId!,
              ),
              builder: (
                context,
                snapshot,
              ) {
                if (snapshot.connectionState ==
                        ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child:
                        CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return _ErrorState(
                    message:
                        _t(context, 'Failed to load purchases.', 'Imeshindikana kupakia manunuzi.'),
                    onRetry: () {
                      setState(() {});
                    },
                  );
                }

                final purchases =
                    snapshot.data ?? [];

                final filteredPurchases =
                    _filterPurchases(
                  purchases,
                );

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                  },
                  child: CustomScrollView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(
                            16,
                            16,
                            16,
                            8,
                          ),
                          child: Column(
                            children: [
                              TextField(
                                controller:
                                    _searchController,
                                decoration:
                                    InputDecoration(
                                  hintText:
                                      _t(context, 'Search medicine or supplier...', 'Tafuta dawa au msambazaji...'),
                                  prefixIcon:
                                      const Icon(
                                    Icons
                                        .search_rounded,
                                  ),
                                  suffixIcon:
                                      _searchQuery
                                              .isNotEmpty
                                          ? IconButton(
                                              onPressed: () {
                                                _searchController
                                                    .clear();
                                              },
                                              icon:
                                                  const Icon(
                                                Icons
                                                    .clear_rounded,
                                              ),
                                            )
                                          : null,
                                  border:
                                      OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      14,
                                    ),
                                  ),
                                  filled: true,
                                ),
                              ),
                              const SizedBox(
                                height: 14,
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child:
                                        _SummaryCard(
                                      title:
                                          _t(context, 'Purchases', 'Manunuzi'),
                                      value:
                                          purchases
                                              .length
                                              .toString(),
                                      icon: Icons
                                          .shopping_cart_rounded,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Expanded(
                                    child:
                                        _SummaryCard(
                                      title:
                                          _t(context, 'Total Cost', 'Gharama ya Jumla'),
                                      value:
                                          _formatCurrency(
                                        _totalCost(
                                          purchases,
                                        ),
                                      ),
                                      icon: Icons
                                          .payments_rounded,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (filteredPurchases
                          .isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child:
                              _EmptyPurchases(
                            hasSearch:
                                _searchQuery
                                    .isNotEmpty,
                            onAdd:
                                _openAddPurchase,
                          ),
                        )
                      else
                        SliverPadding(
                          padding:
                              const EdgeInsets
                                  .fromLTRB(
                            16,
                            8,
                            16,
                            100,
                          ),
                          sliver:
                              SliverList.builder(
                            itemCount:
                                filteredPurchases
                                    .length,
                            itemBuilder:
                                (
                              context,
                              index,
                            ) {
                              final purchase =
                                  filteredPurchases[
                                      index];

                              return _PurchaseCard(
                                purchase:
                                    purchase,
                                date:
                                    _formatDate(
                                  purchase
                                      .createdAt,
                                ),
                                time:
                                    _formatTime(
                                  purchase
                                      .createdAt,
                                ),
                                total:
                                    _formatCurrency(
                                  purchase
                                      .totalCost,
                                ),
                                unitCost:
                                    _formatCurrency(
                                  purchase
                                      .unitCost,
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _SummaryCard
    extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(16),
        color: Theme.of(context)
            .colorScheme
            .primary
            .withValues(
              alpha: 0.08,
            ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(12),
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(
                    alpha: 0.12,
                  ),
            ),
            child: Icon(
              icon,
              color: Theme.of(context)
                  .colorScheme
                  .primary,
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: TextStyle(
                    color:
                        Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseCard
    extends StatelessWidget {
  final PurchaseModel purchase;
  final String date;
  final String time;
  final String total;
  final String unitCost;

  const _PurchaseCard({
    required this.purchase,
    required this.date,
    required this.time,
    required this.total,
    required this.unitCost,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      elevation: 1,
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration:
                      BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(
                      13,
                    ),
                    color: Colors
                        .blue
                        .withValues(
                      alpha: 0.08,
                    ),
                  ),
                  child: const Icon(
                    Icons
                        .shopping_cart_rounded,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        purchase
                            .medicineName,
                        style:
                            const TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        purchase
                            .supplierName
                            .isEmpty
                            ? _t(context, 'No supplier', 'Hakuna msambazaji')
                            : purchase
                                .supplierName,
                        style: TextStyle(
                          color: Colors
                              .grey
                              .shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 16,
            ),
            _InfoRow(
              label: _t(context, 'Quantity', 'Kiasi'),
              value:
                  purchase.quantity
                      .toString(),
            ),
            _InfoRow(
              label: _t(context, 'Unit Cost', 'Gharama kwa Kipimo'),
              value: unitCost,
            ),
            _InfoRow(
              label: _t(context, 'Total Cost', 'Gharama ya Jumla'),
              value: total,
            ),
            if (purchase
                .supplierName
                .isNotEmpty)
              _InfoRow(
                label: _t(context, 'Supplier', 'Msambazaji'),
                value:
                    purchase.supplierName,
              ),
            _InfoRow(
              label: _t(context, 'Date', 'Tarehe'),
              value: time.isEmpty
                  ? date
                  : '$date • $time',
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow
    extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 8,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 95,
            child: Text(
              label,
              style: TextStyle(
                color:
                    Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPurchases
    extends StatelessWidget {
  final bool hasSearch;
  final VoidCallback onAdd;

  const _EmptyPurchases({
    required this.hasSearch,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              hasSearch
                  ? Icons
                      .search_off_rounded
                  : Icons
                      .shopping_cart_outlined,
              size: 64,
              color:
                  Colors.grey.shade400,
            ),
            const SizedBox(
              height: 16,
            ),
            Text(
              hasSearch
                  ? _t(context, 'No purchases found', 'Hakuna manunuzi yaliyopatikana')
                  : _t(context, 'No purchases yet', 'Bado hakuna manunuzi'),
              style:
                  const TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              hasSearch
                  ? _t(context, 'Try another search.', 'Jaribu utafutaji mwingine.')
                  : _t(context, 'Add your first purchase to increase your stock.', 'Ongeza manunuzi yako ya kwanza ili kuongeza stock.'),
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    Colors.grey.shade600,
              ),
            ),
            if (!hasSearch) ...[
              const SizedBox(
                height: 20,
              ),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(
                  Icons.add_shopping_cart_rounded,
                ),
                label: Text(_t(context, 'Add Purchase', 'Ongeza Manunuzi')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorState
    extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons
                  .error_outline_rounded,
              size: 60,
              color: Colors.red,
            ),
            const SizedBox(
              height: 16,
            ),
            Text(
              message,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                fontSize: 16,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            FilledButton(
              onPressed: onRetry,
              child: Text(_t(context, 'Retry', 'Jaribu tena')),
            ),
          ],
        ),
      ),
    );
  }
}