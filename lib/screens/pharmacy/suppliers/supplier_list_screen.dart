import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../models/supplier_model.dart';
import '../../../repositories/supplier_repository.dart';
import '../../../services/auth_service.dart';
import 'add_supplier_screen.dart';

class SupplierListScreen extends StatefulWidget {
  const SupplierListScreen({
    super.key,
  });

  @override
  State<SupplierListScreen> createState() =>
      _SupplierListScreenState();
}

class _SupplierListScreenState
    extends State<SupplierListScreen> {
  String _t(
    AppLocalizations l10n,
    String english,
    String swahili,
  ) {
    return l10n.isSwahili ? swahili : english;
  }

  final SupplierRepository _supplierRepository =
      SupplierRepository();

  final AuthService _authService = AuthService();

  final TextEditingController _searchController =
      TextEditingController();

  String? _pharmacyId;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    _loadPharmacy();

    _searchController.addListener(
      _onSearchChanged,
    );
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

      _showMessage(
        _t(
          AppLocalizations.of(context),
          'Failed to load pharmacy information: ${_cleanError(e)}',
          'Imeshindikana kupakia taarifa za famasi: ${_cleanError(e)}',
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

  Future<void> _openAddSupplier() async {
    if (_pharmacyId == null) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddSupplierScreen(
          pharmacyId: _pharmacyId!,
        ),
      ),
    );
  }

  Future<void> _editSupplier(
    SupplierModel supplier,
  ) async {
    if (_pharmacyId == null) {
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddSupplierScreen(
          pharmacyId: _pharmacyId!,
          supplier: supplier,
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _deleteSupplier(
    SupplierModel supplier,
  ) async {
    if (_pharmacyId == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            _t(
              AppLocalizations.of(dialogContext),
              'Delete Supplier',
              'Futa Msambazaji',
            ),
          ),
          content: Text(
            _t(
              AppLocalizations.of(dialogContext),
              'Are you sure you want to delete "${supplier.name}"?',
              'Una uhakika unataka kumfuta "${supplier.name}"?',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: Text(
                _t(
                  AppLocalizations.of(dialogContext),
                  'Cancel',
                  'Ghairi',
                ),
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text(
                _t(
                  AppLocalizations.of(dialogContext),
                  'Delete',
                  'Futa',
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _supplierRepository.deleteSupplier(
        pharmacyId: _pharmacyId!,
        supplierId: supplier.id,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        _t(
          AppLocalizations.of(context),
          'Supplier deleted successfully.',
          'Msambazaji amefutwa kwa mafanikio.',
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        _t(
          AppLocalizations.of(context),
          'Failed to delete supplier: ${_cleanError(e)}',
          'Imeshindikana kufuta msambazaji: ${_cleanError(e)}',
        ),
      );
    }
  }

  List<SupplierModel> _filterSuppliers(
    List<SupplierModel> suppliers,
  ) {
    if (_searchQuery.isEmpty) {
      return suppliers;
    }

    return suppliers.where((supplier) {
      return supplier.name
              .toLowerCase()
              .contains(_searchQuery) ||
          supplier.phone
              .toLowerCase()
              .contains(_searchQuery) ||
          supplier.email
              .toLowerCase()
              .contains(_searchQuery) ||
          supplier.address
              .toLowerCase()
              .contains(_searchQuery);
    }).toList();
  }

  String _cleanError(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.replaceFirst(
        'Exception: ',
        '',
      );
    }

    return message;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_t(l10n, 'Suppliers', 'Wasambazaji')),
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
        onPressed: _openAddSupplier,
        icon: const Icon(
          Icons.local_shipping_rounded,
        ),
        label: Text(_t(l10n, 'Add Supplier', 'Ongeza Msambazaji')),
      ),
      body: _pharmacyId == null
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : StreamBuilder<List<SupplierModel>>(
              stream:
                  _supplierRepository.watchSuppliers(
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
                        _t(
                          l10n,
                          'Failed to load suppliers.',
                          'Imeshindikana kupakia wasambazaji.',
                        ),
                    onRetry: () {
                      setState(() {});
                    },
                  );
                }

                final suppliers =
                    snapshot.data ?? [];

                final filteredSuppliers =
                    _filterSuppliers(
                  suppliers,
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
                                      _t(
                                        l10n,
                                        'Search supplier, phone or email...',
                                        'Tafuta msambazaji, simu au barua pepe...',
                                      ),
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
                                        BorderRadius.circular(
                                      14,
                                    ),
                                  ),
                                  filled: true,
                                ),
                              ),
                              const SizedBox(
                                height: 14,
                              ),
                              _SummaryCard(
                                count:
                                    suppliers.length,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (filteredSuppliers
                          .isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child:
                              _EmptySuppliers(
                            hasSearch:
                                _searchQuery
                                    .isNotEmpty,
                            onAdd:
                                _openAddSupplier,
                          ),
                        )
                      else
                        SliverPadding(
                          padding:
                              const EdgeInsets.fromLTRB(
                            16,
                            8,
                            16,
                            100,
                          ),
                          sliver:
                              SliverList.builder(
                            itemCount:
                                filteredSuppliers
                                    .length,
                            itemBuilder:
                                (
                              context,
                              index,
                            ) {
                              final supplier =
                                  filteredSuppliers[
                                      index];

                              return _SupplierCard(
                                supplier:
                                    supplier,
                                onEdit: () =>
                                    _editSupplier(
                                  supplier,
                                ),
                                onDelete: () =>
                                    _deleteSupplier(
                                  supplier,
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

class _SummaryCard extends StatelessWidget {
  final int count;

  const _SummaryCard({
    required this.count,
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
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(16),
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
            width: 44,
            height: 44,
            decoration:
                BoxDecoration(
              borderRadius:
                  BorderRadius.circular(13),
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(
                    alpha: 0.12,
                  ),
            ),
            child: Icon(
              Icons.local_shipping_rounded,
              color: Theme.of(context)
                  .colorScheme
                  .primary,
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
                  _t(l10n, 'Total Suppliers', 'Jumla ya Wasambazaji'),
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
                  count.toString(),
                  style:
                      const TextStyle(
                    fontSize: 20,
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

class _SupplierCard
    extends StatelessWidget {
  final SupplierModel supplier;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SupplierCard({
    required this.supplier,
    required this.onEdit,
    required this.onDelete,
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
                  width: 48,
                  height: 48,
                  decoration:
                      BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(
                          alpha: 0.1,
                        ),
                  ),
                  child: Icon(
                    Icons.local_shipping_rounded,
                    color: Theme.of(context)
                        .colorScheme
                        .primary,
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
                        supplier.name,
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
                        supplier.phone
                                .isEmpty
                            ? _t(l10n, 'No phone number', 'Hakuna namba ya simu')
                            : supplier.phone,
                        style: TextStyle(
                          color: Colors
                              .grey
                              .shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value ==
                        'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit_rounded),
                          const SizedBox(width: 10),
                          Text(
                            _t(l10n, 'Edit', 'Hariri'),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.delete_rounded,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _t(l10n, 'Delete', 'Futa'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(
              height: 16,
            ),
            if (supplier.email.isNotEmpty)
              _InfoRow(
                icon:
                    Icons.email_outlined,
                value:
                    supplier.email,
              ),
            if (supplier.address.isNotEmpty)
              _InfoRow(
                icon:
                    Icons.location_on_outlined,
                value:
                    supplier.address,
              ),
            if (supplier.notes.isNotEmpty)
              _InfoRow(
                icon:
                    Icons.notes_rounded,
                value:
                    supplier.notes,
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow
    extends StatelessWidget {
  final IconData icon;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 9,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: Colors.grey.shade600,
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: Text(
              value,
              style:
                  const TextStyle(
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySuppliers
    extends StatelessWidget {
  final bool hasSearch;
  final VoidCallback onAdd;

  const _EmptySuppliers({
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
                      .local_shipping_outlined,
              size: 64,
              color:
                  Colors.grey.shade400,
            ),
            const SizedBox(
              height: 16,
            ),
            Text(
              hasSearch
                  ? _t(l10n, 'No suppliers found', 'Hakuna wasambazaji waliopatikana')
                  : _t(l10n, 'No suppliers yet', 'Bado hakuna wasambazaji'),
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
                  ? _t(l10n, 'Try a different search.', 'Jaribu utafutaji mwingine.')
                  : _t(
                      l10n,
                      'Add your first supplier to start managing purchases.',
                      'Ongeza msambazaji wako wa kwanza kuanza kusimamia manunuzi.',
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
                      .local_shipping_rounded,
                ),
                label: Text(
                  _t(l10n, 'Add Supplier', 'Ongeza Msambazaji'),
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

  String _t(
    AppLocalizations l10n,
    String english,
    String swahili,
  ) {
    return l10n.isSwahili ? swahili : english;
  }

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
              child: Text(
                _t(
                  AppLocalizations.of(context),
                  'Retry',
                  'Jaribu tena',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}