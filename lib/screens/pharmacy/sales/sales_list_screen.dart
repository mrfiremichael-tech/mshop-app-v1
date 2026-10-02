import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../models/sale_model.dart';
import '../../../repositories/sale_repository.dart';
import '../../../services/auth_service.dart';
import 'add_sale_screen.dart';

class SalesListScreen extends StatefulWidget {
  const SalesListScreen({
    super.key,
  });

  @override
  State<SalesListScreen> createState() =>
      _SalesListScreenState();
}

class _SalesListScreenState
    extends State<SalesListScreen> {
  String _t(
    AppLocalizations l10n,
    String english,
    String swahili,
  ) {
    return l10n.isSwahili ? swahili : english;
  }

  final SaleRepository _saleRepository =
      SaleRepository();

  final AuthService _authService =
      AuthService();

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
            _t(
              AppLocalizations.of(context),
              'Failed to load pharmacy information: $e',
              'Imeshindikana kupakia taarifa za famasi: $e',
            ),
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

  Future<void> _openAddSale() async {
    if (_pharmacyId == null) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddSaleScreen(
          pharmacyId: _pharmacyId!,
        ),
      ),
    );
  }

  List<SaleModel> _filterSales(
    List<SaleModel> sales,
  ) {
    if (_searchQuery.isEmpty) {
      return sales;
    }

    return sales.where((sale) {
      return sale.medicineName
              .toLowerCase()
              .contains(_searchQuery) ||
          sale.customerName
              .toLowerCase()
              .contains(_searchQuery);
    }).toList();
  }

  double _totalSales(
    List<SaleModel> sales,
  ) {
    return sales.fold<double>(
      0,
      (total, sale) =>
          total + sale.totalAmount,
    );
  }

  double _totalProfit(
    List<SaleModel> sales,
  ) {
    return sales.fold<double>(
      0,
      (total, sale) =>
          total + sale.profit,
    );
  }

  int _totalItemsSold(
    List<SaleModel> sales,
  ) {
    return sales.fold<int>(
      0,
      (total, sale) =>
          total + sale.quantity,
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
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sales),
        actions: [
          IconButton(
            tooltip: _t(l10n, 'Refresh', 'Onyesha upya'),
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
        onPressed: _openAddSale,
        icon: const Icon(
          Icons.point_of_sale_rounded,
        ),
        label: Text(
          l10n.addSale,
        ),
      ),
      body: _pharmacyId == null
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : StreamBuilder<List<SaleModel>>(
              stream:
                  _saleRepository.watchSales(
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
                        l10n.failedToLoadSalesData,
                    onRetry: () {
                      setState(() {});
                    },
                  );
                }

                final sales =
                    snapshot.data ?? [];

                final filteredSales =
                    _filterSales(sales);

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
                                      _t(l10n, 'Search medicine or customer...', 'Tafuta dawa au mteja...'),
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
                                          'Sales',
                                      value:
                                          sales
                                              .length
                                              .toString(),
                                      icon: Icons
                                          .point_of_sale_rounded,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Expanded(
                                    child:
                                        _SummaryCard(
                                      title:
                                          'Items Sold',
                                      value:
                                          _totalItemsSold(
                                        sales,
                                      ).toString(),
                                      icon: Icons
                                          .inventory_2_rounded,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child:
                                        _SummaryCard(
                                      title:
                                          'Total Sales',
                                      value:
                                          _formatCurrency(
                                        _totalSales(
                                          sales,
                                        ),
                                      ),
                                      icon: Icons
                                          .payments_rounded,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Expanded(
                                    child:
                                        _SummaryCard(
                                      title:
                                          'Total Profit',
                                      value:
                                          _formatCurrency(
                                        _totalProfit(
                                          sales,
                                        ),
                                      ),
                                      icon: Icons
                                          .trending_up_rounded,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (filteredSales
                          .isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child:
                              _EmptySales(
                            hasSearch:
                                _searchQuery
                                    .isNotEmpty,
                            onAdd:
                                _openAddSale,
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
                                filteredSales
                                    .length,
                            itemBuilder:
                                (
                              context,
                              index,
                            ) {
                              final sale =
                                  filteredSales[
                                      index];

                              return _SaleCard(
                                sale: sale,
                                date:
                                    _formatDate(
                                  sale.createdAt,
                                ),
                                time:
                                    _formatTime(
                                  sale.createdAt,
                                ),
                                total:
                                    _formatCurrency(
                                  sale.totalAmount,
                                ),
                                profit:
                                    _formatCurrency(
                                  sale.profit,
                                ),
                                unitPrice:
                                    _formatCurrency(
                                  sale.unitPrice,
                                ),
                                l10n: l10n,
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

class _SummaryCard extends StatelessWidget {
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
            decoration:
                BoxDecoration(
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

class _SaleCard
    extends StatelessWidget {
  final SaleModel sale;
  final String date;
  final String time;
  final String total;
  final String profit;
  final String unitPrice;
  final AppLocalizations l10n;

  const _SaleCard({
    required this.sale,
    required this.date,
    required this.time,
    required this.total,
    required this.profit,
    required this.unitPrice,
    required this.l10n,
  });

  String _t(
    AppLocalizations l10n,
    String english,
    String swahili,
  ) {
    return l10n.isSwahili ? swahili : english;
  }

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
                        .green
                        .withValues(
                      alpha: 0.08,
                    ),
                  ),
                  child: const Icon(
                    Icons
                        .point_of_sale_rounded,
                    color: Colors.green,
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
                        sale.medicineName,
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
                        sale.customerName
                                .isEmpty
                            ? _t(l10n, 'Walk-in customer', 'Mteja wa kawaida')
                            : sale.customerName,
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
              label: l10n.quantity,
              value:
                  sale.quantity.toString(),
            ),
            _InfoRow(
              label: _t(l10n, 'Unit Price', 'Bei ya Kipimo'),
              value: unitPrice,
            ),
            _InfoRow(
              label: l10n.totalSale,
              value: total,
            ),
            _InfoRow(
              label: l10n.profit,
              value: profit,
              valueColor: Colors.green,
            ),
            if (sale.customerName
                .isNotEmpty)
              _InfoRow(
                label: l10n.customer,
                value:
                    sale.customerName,
              ),
            _InfoRow(
              label: _t(l10n, 'Date', 'Tarehe'),
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
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
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
                  TextStyle(
                fontWeight:
                    FontWeight.w600,
                fontSize: 13,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySales
    extends StatelessWidget {
  final bool hasSearch;
  final VoidCallback onAdd;

  const _EmptySales({
    required this.hasSearch,
    required this.onAdd,
  });

  String _t(
    AppLocalizations l10n,
    String english,
    String swahili,
  ) {
    return l10n.isSwahili ? swahili : english;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

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
                      .point_of_sale_outlined,
              size: 64,
              color:
                  Colors.grey.shade400,
            ),
            const SizedBox(
              height: 16,
            ),
            Text(
              hasSearch
                  ? _t(l10n, 'No sales found', 'Hakuna mauzo yaliyopatikana')
                  : _t(l10n, 'No sales yet', 'Bado hakuna mauzo'),
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
                  ? _t(l10n, 'Try another search.', 'Jaribu utafutaji mwingine.')
                  : _t(
                      l10n,
                      'Record your first sale to start tracking sales and profit.',
                      'Rekodi uuzaji wako wa kwanza kuanza kufuatilia mauzo na faida.',
                    ),
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
                  Icons
                      .point_of_sale_rounded,
                ),
                label: Text(
                  l10n.addSale,
                ),
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
              child: const Text(
                'Retry',
              ),
            ),
          ],
        ),
      ),
    );
  }
}