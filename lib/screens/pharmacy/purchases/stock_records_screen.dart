import 'package:flutter/material.dart';

import '../../../models/stock_record_model.dart';
import '../../../repositories/stock_record_repository.dart';
import '../../../core/localization/app_localizations.dart';

class StockRecordsScreen extends StatelessWidget {
  final String pharmacyId;

  const StockRecordsScreen({
    super.key,
    required this.pharmacyId,
  });

  @override
  Widget build(BuildContext context) {
    final repository = StockRecordRepository();

    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.stockRecords),
      ),
      body: StreamBuilder<List<StockRecordModel>>(
        stream: repository.watchStockRecords(pharmacyId),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '${l10n.failedToLoadStockRecords}\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final records = snapshot.data ?? [];

          if (records.isEmpty) {
            return const _EmptyStockRecords();
          }

          final totalQuantity = records.fold<int>(
            0,
            (total, record) => total + record.quantity,
          );

          final totalCost = records.fold<double>(
            0,
            (total, record) => total + record.totalCost,
          );

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: l10n.stockEntries,
                        value: records.length.toString(),
                        icon: Icons.inventory_2_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryCard(
                        title: l10n.totalQuantity,
                        value: totalQuantity.toString(),
                        icon: Icons.numbers_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryCard(
                        title: l10n.totalCost,
                        value:
                            'TSh ${totalCost.toStringAsFixed(0)}',
                        icon: Icons.payments_outlined,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    24,
                  ),
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final record = records[index];

                    return _StockRecordCard(
                      record: record,
                    );
                  },
                ),
              ),
            ],
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
    final primary =
        Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: primary,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _StockRecordCard extends StatelessWidget {
  final StockRecordModel record;

  const _StockRecordCard({
    required this.record,
  });

  String _formatDate(DateTime date) {
    final day =
        date.day.toString().padLeft(2, '0');
    final month =
        date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    final day =
        date.day.toString().padLeft(2, '0');
    final month =
        date.month.toString().padLeft(2, '0');

    final hour =
        date.hour.toString().padLeft(2, '0');
    final minute =
        date.minute.toString().padLeft(2, '0');

    return '$day/$month/${date.year} • '
        '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final primary =
        Theme.of(context).colorScheme.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(13),
                    color:
                        primary.withValues(alpha: 0.10),
                  ),
                  child: Icon(
                    Icons.inventory_rounded,
                    color: primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.medicineName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.stockAdded(_formatDateTime(record.stockDate)),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _InfoItem(
                    label: l10n.quantity,
                    value:
                        '${record.quantity} pcs',
                    icon: Icons.numbers_rounded,
                  ),
                ),
                Expanded(
                  child: _InfoItem(
                    label: l10n.unitCost,
                    value:
                        'TSh ${record.unitCost.toStringAsFixed(0)}',
                    icon:
                        Icons.shopping_cart_outlined,
                  ),
                ),
                Expanded(
                  child: _InfoItem(
                    label: 'Total Cost',
                    value:
                        'TSh ${record.totalCost.toStringAsFixed(0)}',
                    icon: Icons.payments_outlined,
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            _DetailRow(
              icon: Icons.local_shipping_outlined,
              label: l10n.supplier,
              value: record.supplierName.isEmpty
                  ? l10n.notSpecified
                  : record.supplierName,
            ),

            const SizedBox(height: 10),

            _DetailRow(
              icon:
                  Icons.confirmation_number_outlined,
              label: l10n.batchNumber,
              value: record.batchNumber.isEmpty
                  ? l10n.notSpecified
                  : record.batchNumber,
            ),

            const SizedBox(height: 10),

            _DetailRow(
              icon: Icons.event_outlined,
              label: l10n.expiryDate,
              value: record.expiryDate == null
                  ? l10n.notSpecified
                  : _formatDate(record.expiryDate!),
            ),

            const SizedBox(height: 10),

            _DetailRow(
              icon: Icons.person_outline_rounded,
              label: l10n.addedBy,
              value: record.addedByName.isEmpty
                  ? l10n.unknown
                  : record.addedByName,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.grey.shade600,
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 19,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 75,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyStockRecords extends StatelessWidget {
  const _EmptyStockRecords();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 72,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noStockRecords,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noStockRecordsDescription,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}