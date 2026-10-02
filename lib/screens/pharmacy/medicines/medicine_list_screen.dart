import 'package:flutter/material.dart';

import '../../../models/medicine_model.dart';
import '../../../repositories/medicine_repository.dart';
import '../../../services/auth_service.dart';
import '../../../core/localization/app_localizations.dart';
import 'add_medicine_screen.dart';
import 'edit_medicine_screen.dart';

class MedicineListScreen extends StatefulWidget {
  const MedicineListScreen({
    super.key,
  });

  @override
  State<MedicineListScreen> createState() =>
      _MedicineListScreenState();
}

class _MedicineListScreenState extends State<MedicineListScreen> {
  final MedicineRepository _medicineRepository = MedicineRepository();
  final AuthService _authService = AuthService();

  final TextEditingController _searchController =
      TextEditingController();

  String? _pharmacyId;
  String _searchQuery = '';
  bool _showLowStockOnly = false;
  bool _showExpiryOnly = false;

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

      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${l10n.failedToLoadPharmacyInformation} ${_cleanError(e)}',
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

  Future<void> _openAddMedicine() async {
    if (_pharmacyId == null) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddMedicineScreen(
          pharmacyId: _pharmacyId!,
        ),
      ),
    );
  }

  Future<void> _openEditMedicine(
    MedicineModel medicine,
  ) async {
    if (_pharmacyId == null) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditMedicineScreen(
          pharmacyId: _pharmacyId!,
          medicine: medicine,
        ),
      ),
    );
  }

  Future<void> _deleteMedicine(
    MedicineModel medicine,
  ) async {
    if (_pharmacyId == null) {
      return;
    }

    final l10n = AppLocalizations.of(context);

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.deleteMedicine),
          content: Text(
            l10n.deleteMedicineConfirmation(medicine.name),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text(l10n.deleteMedicine),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      await _medicineRepository.deleteMedicine(
        pharmacyId: _pharmacyId!,
        medicineId: medicine.id,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.medicineDeletedSuccessfully,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${l10n.failedToDeleteMedicine}: ${_cleanError(e)}',
          ),
        ),
      );
    }
  }

  String _cleanError(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.replaceFirst('Exception: ', '');
    }

    return message;
  }

  List<MedicineModel> _filterMedicines(
    List<MedicineModel> medicines,
  ) {
    return medicines.where((medicine) {
      final matchesSearch =
          _searchQuery.isEmpty ||
              medicine.name
                  .toLowerCase()
                  .contains(_searchQuery) ||
              medicine.category
                  .toLowerCase()
                  .contains(_searchQuery) ||
              medicine.barcode
                  .toLowerCase()
                  .contains(_searchQuery) ||
              medicine.batchNumber
                  .toLowerCase()
                  .contains(_searchQuery);

      final matchesLowStock =
          !_showLowStockOnly ||
          medicine.isLowStock;

      final matchesExpiry =
          !_showExpiryOnly ||
          medicine.isExpired ||
          medicine.expiresWithin30Days;

      return matchesSearch &&
          matchesLowStock &&
          matchesExpiry;
    }).toList();
  }

  int _lowStockCount(
    List<MedicineModel> medicines,
  ) {
    return medicines
        .where((medicine) => medicine.isLowStock)
        .length;
  }

  int _expiryCount(
    List<MedicineModel> medicines,
  ) {
    return medicines
        .where(
          (medicine) =>
              medicine.isExpired ||
              medicine.expiresWithin30Days,
        )
        .length;
  }

  Color _stockColor(
    MedicineModel medicine,
  ) {
    if (medicine.isOutOfStock) {
      return Colors.red;
    }

    if (medicine.isLowStock) {
      return Colors.orange;
    }

    return Colors.green;
  }

  Color _expiryColor(
    MedicineModel medicine,
  ) {
    if (medicine.isExpired) {
      return Colors.red;
    }

    if (medicine.expiresWithin30Days) {
      return Colors.orange;
    }

    return Colors.green;
  }

  String _stockLabel(
    MedicineModel medicine,
    AppLocalizations l10n,
  ) {
    if (medicine.isOutOfStock) {
      return l10n.outOfStock;
    }

    if (medicine.isLowStock) {
      return l10n.lowStock;
    }

    return l10n.inStock;
  }

  String _expiryLabel(
    MedicineModel medicine,
    AppLocalizations l10n,
  ) {
    if (medicine.expiryDate == null) {
      return l10n.noExpiryDate;
    }

    if (medicine.isExpired) {
      return l10n.expired;
    }

    if (medicine.expiresWithin30Days) {
      return l10n.expiresSoon;
    }

    return l10n.good;
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '-';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month =
        date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String _formatCurrency(double value) {
    return 'TSh ${value.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.medicines),
        actions: [
          IconButton(
            tooltip: l10n.refresh,
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
        onPressed: _openAddMedicine,
        icon: const Icon(
          Icons.add_rounded,
        ),
        label: Text(l10n.addMedicine),
      ),
      body: _pharmacyId == null
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : StreamBuilder<List<MedicineModel>>(
              stream:
                  _medicineRepository.watchMedicines(
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
                        l10n.failedToLoadMedicines,
                    onRetry: () {
                      setState(() {});
                    },
                  );
                }

                final medicines =
                    snapshot.data ?? [];

                final filteredMedicines =
                    _filterMedicines(
                  medicines,
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
                                      l10n.searchMedicine,
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
                                height: 12,
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child:
                                        _FilterCard(
                                      label:
                                          l10n.lowStock,
                                      count:
                                          _lowStockCount(
                                        medicines,
                                      ),
                                      icon: Icons
                                          .warning_amber_rounded,
                                      selected:
                                          _showLowStockOnly,
                                      onTap: () {
                                        setState(() {
                                          _showLowStockOnly =
                                              !_showLowStockOnly;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Expanded(
                                    child:
                                        _FilterCard(
                                      label:
                                          l10n.expiryAlerts,
                                      count:
                                          _expiryCount(
                                        medicines,
                                      ),
                                      icon: Icons
                                          .event_busy_rounded,
                                      selected:
                                          _showExpiryOnly,
                                      onTap: () {
                                        setState(() {
                                          _showExpiryOnly =
                                              !_showExpiryOnly;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (filteredMedicines
                          .isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child:
                              _EmptyMedicines(
                            hasFilter:
                                _searchQuery.isNotEmpty ||
                                    _showLowStockOnly ||
                                    _showExpiryOnly,
                            onAdd:
                                _openAddMedicine,
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
                                filteredMedicines.length,
                            itemBuilder:
                                (context, index) {
                              final medicine =
                                  filteredMedicines[
                                      index];

                              return _MedicineCard(
                                medicine:
                                    medicine,
                                stockColor:
                                    _stockColor(
                                  medicine,
                                ),
                                stockLabel:
                                    _stockLabel(
                                  medicine,
                                  l10n,
                                ),
                                expiryColor:
                                    _expiryColor(
                                  medicine,
                                ),
                                expiryLabel:
                                    _expiryLabel(
                                  medicine,
                                  l10n,
                                ),
                                expiryDate:
                                    _formatDate(
                                  medicine.expiryDate,
                                ),
                                buyingPrice:
                                    _formatCurrency(
                                  medicine
                                      .buyingPrice,
                                ),
                                sellingPrice:
                                    _formatCurrency(
                                  medicine
                                      .sellingPrice,
                                ),
                                onEdit: () =>
                                    _openEditMedicine(
                                  medicine,
                                ),
                                onDelete: () =>
                                    _deleteMedicine(
                                  medicine,
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

class _FilterCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _FilterCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius:
          BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius:
              BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? Theme.of(context)
                    .colorScheme
                    .primary
                : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
          color: selected
              ? Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(
                    alpha: 0.08,
                  )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected
                  ? Theme.of(context)
                      .colorScheme
                      .primary
                  : Colors.grey.shade700,
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
            CircleAvatar(
              radius: 14,
              child: Text(
                count.toString(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicineCard
    extends StatelessWidget {
  final MedicineModel medicine;
  final Color stockColor;
  final String stockLabel;
  final Color expiryColor;
  final String expiryLabel;
  final String expiryDate;
  final String buyingPrice;
  final String sellingPrice;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MedicineCard({
    required this.medicine,
    required this.stockColor,
    required this.stockLabel,
    required this.expiryColor,
    required this.expiryLabel,
    required this.expiryDate,
    required this.buyingPrice,
    required this.sellingPrice,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Card(
      margin:
          const EdgeInsets.only(bottom: 12),
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
                    Icons.medication_rounded,
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
                        medicine.name,
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
                        medicine.category.isEmpty
                            ? l10n.noCategory
                            : medicine.category,
                        style: TextStyle(
                          color: Colors
                              .grey
                              .shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<
                    String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value ==
                        'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder:
                      (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons
                                .edit_rounded,
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Text(l10n.editMedicine),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons
                                .delete_rounded,
                            color: Colors.red,
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Text(
                            l10n.deleteMedicine,
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusChip(
                  label: stockLabel,
                  color: stockColor,
                ),
                _StatusChip(
                  label: expiryLabel,
                  color: expiryColor,
                ),
              ],
            ),
            const SizedBox(
              height: 14,
            ),
            _InfoRow(
              label: l10n.totalStock,
              value:
                  '${medicine.quantity} ${medicine.unit}',
            ),
            _InfoRow(
              label: l10n.buyingPrice,
              value: buyingPrice,
            ),
            _InfoRow(
              label: l10n.sellingPrice,
              value: sellingPrice,
            ),
            _InfoRow(
              label: l10n.batchNumber,
              value: medicine
                      .batchNumber.isEmpty
                  ? '-'
                  : medicine.batchNumber,
            ),
            _InfoRow(
              label: l10n.expiryDate,
              value: expiryDate,
            ),
            if (medicine
                .barcode.isNotEmpty)
              _InfoRow(
                label: l10n.barcode,
                value: medicine.barcode,
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip
    extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(30),
        color: color.withValues(
          alpha: 0.1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight:
              FontWeight.w700,
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
            width: 115,
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

class _EmptyMedicines
    extends StatelessWidget {
  final bool hasFilter;
  final VoidCallback onAdd;

  const _EmptyMedicines({
    required this.hasFilter,
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
              hasFilter
                  ? Icons
                      .search_off_rounded
                  : Icons
                      .medication_outlined,
              size: 64,
              color:
                  Colors.grey.shade400,
            ),
            const SizedBox(
              height: 16,
            ),
            Text(
              hasFilter
                  ? AppLocalizations.of(context).noMedicinesFound
                  : AppLocalizations.of(context).noMedicinesYet,
              style: const TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              hasFilter
                  ? AppLocalizations.of(context).tryDifferentSearch
                  : AppLocalizations.of(context).addFirstMedicine,
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    Colors.grey.shade600,
              ),
            ),
            if (!hasFilter) ...[
              const SizedBox(
                height: 20,
              ),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(
                  Icons.add_rounded,
                ),
                label: Text(
                  AppLocalizations.of(context).addMedicine,
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
              child: Text(
                AppLocalizations.of(context).retry,
              ),
            ),
          ],
        ),
      ),
    );
  }
}