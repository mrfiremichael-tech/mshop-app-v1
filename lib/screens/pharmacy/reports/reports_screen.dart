import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../models/expense_model.dart';
import '../../../models/medicine_model.dart';
import '../../../models/purchase_model.dart';
import '../../../models/sale_model.dart';
import '../../../repositories/expense_repository.dart';
import '../../../repositories/medicine_repository.dart';
import '../../../repositories/purchase_repository.dart';
import '../../../repositories/sale_repository.dart';
import '../../../services/auth_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({
    super.key,
  });

  @override
  State<ReportsScreen> createState() =>
      _ReportsScreenState();
}

class _ReportsScreenState
    extends State<ReportsScreen> {
  String _t(
    AppLocalizations l10n,
    String english,
    String swahili,
  ) {
    return l10n.isSwahili ? swahili : english;
  }

  final AuthService _authService = AuthService();

  final MedicineRepository _medicineRepository =
      MedicineRepository();

  final PurchaseRepository _purchaseRepository =
      PurchaseRepository();

  final SaleRepository _saleRepository =
      SaleRepository();

  final ExpenseRepository _expenseRepository =
      ExpenseRepository();

  late DateTime _startDate;
  late DateTime _endDate;

  bool _loading = true;

  List<SaleModel> _sales = [];
  List<PurchaseModel> _purchases = [];
  List<ExpenseModel> _expenses = [];
  List<MedicineModel> _medicines = [];

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _startDate = DateTime(
      now.year,
      now.month,
      now.day,
    );

    _endDate = DateTime(
      now.year,
      now.month,
      now.day,
      23,
      59,
      59,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _loadReports();
    });
  }

  Future<void> _loadReports() async {
    final l10n = AppLocalizations.of(context);
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final pharmacyId =
          await _authService.getCurrentPharmacyId();

      if (pharmacyId == null ||
          pharmacyId.isEmpty) {
        throw Exception(
          _t(
            l10n,
            'Pharmacy information not found.',
            'Taarifa za famasi hazikupatikana.',
          ),
        );
      }

      final results = await Future.wait([
        _medicineRepository.getMedicines(
          pharmacyId,
        ),
        _purchaseRepository.getPurchases(
          pharmacyId,
        ),
        _saleRepository.getSalesBetweenDates(
          pharmacyId: pharmacyId,
          startDate: _startDate,
          endDate: _endDate,
        ),
        _expenseRepository.getExpensesBetweenDates(
          pharmacyId: pharmacyId,
          startDate: _startDate,
          endDate: _endDate,
        ),
      ]);

      final medicines =
          results[0] as List<MedicineModel>;

      final purchases =
          results[1] as List<PurchaseModel>;

      final sales =
          results[2] as List<SaleModel>;

      final expenses =
          results[3] as List<ExpenseModel>;

      final filteredPurchases =
          purchases.where((purchase) {
        final date = purchase.createdAt;

        if (date == null) {
          return false;
        }

        return !date.isBefore(_startDate) &&
            !date.isAfter(_endDate);
      }).toList();

      if (!mounted) {
        return;
      }

      setState(() {
        _medicines = medicines;
        _purchases = filteredPurchases;
        _sales = sales;
        _expenses = expenses;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });

      final l10n = AppLocalizations.of(context);

      _showMessage(
        _t(
          l10n,
          'Failed to load reports: ${_cleanError(e)}',
          'Imeshindikana kupakia ripoti: ${_cleanError(e)}',
        ),
      );
    }
  }

  Future<void> _selectStartDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (selectedDate == null) {
      return;
    }

    setState(() {
      _startDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );

      if (_endDate.isBefore(_startDate)) {
        _endDate = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          23,
          59,
          59,
        );
      }
    });
  }

  Future<void> _selectEndDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _endDate.isBefore(_startDate)
          ? _startDate
          : _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now(),
    );

    if (selectedDate == null) {
      return;
    }

    setState(() {
      _endDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        23,
        59,
        59,
      );
    });

    await _loadReports();
  }

  void _setToday() {
    final now = DateTime.now();

    setState(() {
      _startDate = DateTime(
        now.year,
        now.month,
        now.day,
      );

      _endDate = DateTime(
        now.year,
        now.month,
        now.day,
        23,
        59,
        59,
      );
    });

    _loadReports();
  }

  void _setThisMonth() {
    final now = DateTime.now();

    setState(() {
      _startDate = DateTime(
        now.year,
        now.month,
        1,
      );

      _endDate = DateTime(
        now.year,
        now.month + 1,
        0,
        23,
        59,
        59,
      );
    });

    _loadReports();
  }

  void _setLast30Days() {
    final now = DateTime.now();

    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(
      const Duration(days: 29),
    );

    setState(() {
      _startDate = start;

      _endDate = DateTime(
        now.year,
        now.month,
        now.day,
        23,
        59,
        59,
      );
    });

    _loadReports();
  }

  double get _totalSales {
    return _sales.fold<double>(
      0,
      (total, sale) =>
          total + sale.totalAmount,
    );
  }

  double get _totalProfit {
    return _sales.fold<double>(
      0,
      (total, sale) =>
          total + sale.profit,
    );
  }

  double get _totalExpenses {
    return _expenses.fold<double>(
      0,
      (total, expense) =>
          total + expense.amount,
    );
  }

  double get _netProfit {
    return _totalProfit - _totalExpenses;
  }

  int get _itemsSold {
    return _sales.fold<int>(
      0,
      (total, sale) =>
          total + sale.quantity,
    );
  }

  int get _itemsPurchased {
    return _purchases.fold<int>(
      0,
      (total, purchase) =>
          total + purchase.quantity,
    );
  }

  int get _lowStockCount {
    return _medicines
        .where(
          (medicine) =>
              medicine.isLowStock,
        )
        .length;
  }

  int get _expiryAlertCount {
    return _medicines
        .where(
          (medicine) =>
              medicine.isExpired ||
              medicine.expiresWithin30Days,
        )
        .length;
  }

  double get _stockValue {
    return _medicines.fold<double>(
      0,
      (total, medicine) =>
          total + medicine.totalStockValue,
    );
  }

  String _formatCurrency(double value) {
    return 'TSh ${value.toStringAsFixed(0)}';
  }

  String _formatDate(DateTime date) {
    final day =
        date.day.toString().padLeft(2, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
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
        title: Text(
          _t(l10n, 'Reports', 'Ripoti'),
        ),
        actions: [
          IconButton(
            tooltip: _t(l10n, 'Refresh', 'Onyesha upya'),
            onPressed:
                _loading ? null : _loadReports,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadReports,
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  32,
                ),
                children: [
                  _buildDateRangeCard(),
                  const SizedBox(
                    height: 16,
                  ),
                  _buildFinancialOverview(),
                  const SizedBox(
                    height: 16,
                  ),
                  _buildOperationalOverview(),
                  const SizedBox(
                    height: 16,
                  ),
                  _buildStockOverview(),
                  const SizedBox(
                    height: 16,
                  ),
                  _buildSalesSection(),
                  const SizedBox(
                    height: 16,
                  ),
                  _buildPurchaseSection(),
                  const SizedBox(
                    height: 16,
                  ),
                  _buildExpenseSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildDateRangeCard() {
    final l10n = AppLocalizations.of(context);    return Container(
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(18),
        color: Theme.of(context)
            .colorScheme
            .primary
            .withValues(
              alpha: 0.08,
            ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.date_range_rounded,
              ),
              const SizedBox(width: 10),
              Text(
                _t(l10n, 'Report Period', 'Kipindi cha Ripoti'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 14,
          ),
          Row(
            children: [
              Expanded(
                child: _DateButton(
                  label: _t(l10n, 'From', 'Kuanzia'),
                  value:
                      _formatDate(
                    _startDate,
                  ),
                  onTap:
                      _selectStartDate,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DateButton(
                  label: _t(l10n, 'To', 'Hadi'),
                  value:
                      _formatDate(
                    _endDate,
                  ),
                  onTap:
                      _selectEndDate,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 12,
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: _setToday,
                child:
                    Text(_t(l10n, 'Today', 'Leo')),
              ),
              OutlinedButton(
                onPressed: _setThisMonth,
                child:
                    Text(_t(l10n, 'This Month', 'Mwezi Huu')),
              ),
              OutlinedButton(
                onPressed: _setLast30Days,
                child:
                    Text(_t(l10n, 'Last 30 Days', 'Siku 30 Zilizopita')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialOverview() {
    final l10n = AppLocalizations.of(context);    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          _t(l10n, 'Financial Overview', 'Muhtasari wa Fedha'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight:
                FontWeight.bold,
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        LayoutBuilder(
          builder: (
            context,
            constraints,
          ) {
            final cards = [
              _ReportCard(
                title: _t(l10n, 'Sales', 'Mauzo'),
                value:
                    _formatCurrency(
                  _totalSales,
                ),
                icon:
                    Icons.point_of_sale_rounded,
              ),
              _ReportCard(
                title: _t(l10n, 'Gross Profit', 'Faida Ghafi'),
                value:
                    _formatCurrency(
                  _totalProfit,
                ),
                icon:
                    Icons.trending_up_rounded,
              ),
              _ReportCard(
                title: _t(l10n, 'Expenses', 'Gharama'),
                value:
                    _formatCurrency(
                  _totalExpenses,
                ),
                icon:
                    Icons.receipt_long_rounded,
              ),
              _ReportCard(
                title: _t(l10n, 'Net Profit', 'Faida Halisi'),
                value:
                    _formatCurrency(
                  _netProfit,
                ),
                icon:
                    Icons.account_balance_wallet_rounded,
                valueColor:
                    _netProfit >= 0
                        ? Colors.green
                        : Colors.red,
              ),
            ];

            if (constraints.maxWidth >= 700) {
              return GridView.builder(
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(),
                itemCount: cards.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.5,
                ),
                itemBuilder:
                    (context, index) {
                  return cards[index];
                },
              );
            }

            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: cards[0],
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: cards[1],
                    ),
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                Row(
                  children: [
                    Expanded(
                      child: cards[2],
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: cards[3],
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildOperationalOverview() {
    final l10n = AppLocalizations.of(context);    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          _t(l10n, 'Operational Overview', 'Muhtasari wa Uendeshaji'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight:
                FontWeight.bold,
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        Row(
          children: [
            Expanded(
              child: _MiniReportCard(
                title: _t(l10n, 'Sales', 'Mauzo'),
                value:
                    _sales.length.toString(),
                subtitle:
                    _t(l10n, 'Transactions', 'Miamala'),
                icon:
                    Icons.point_of_sale_rounded,
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              child: _MiniReportCard(
                title: _t(l10n, 'Items Sold', 'Vipimo Vilivyouzwa'),
                value:
                    _itemsSold.toString(),
                subtitle: _t(l10n, 'Units', 'Vipimo'),
                icon:
                    Icons.inventory_2_rounded,
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
              child: _MiniReportCard(
                title: _t(l10n, 'Purchases', 'Manunuzi'),
                value:
                    _purchases.length.toString(),
                subtitle:
                    _t(l10n, 'Transactions', 'Miamala'),
                icon:
                    Icons.add_shopping_cart_rounded,
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              child: _MiniReportCard(
                title: _t(l10n, 'Items Bought', 'Vipimo Vilivyonunuliwa'),
                value:
                    _itemsPurchased.toString(),
                subtitle: _t(l10n, 'Units', 'Vipimo'),
                icon:
                    Icons.inventory_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStockOverview() {
    final l10n = AppLocalizations.of(context);    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          _t(l10n, 'Stock Overview', 'Muhtasari wa Stock'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight:
                FontWeight.bold,
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        _StockReportRow(
          title: _t(l10n, 'Total Products', 'Jumla ya Bidhaa'),
          value:
              _medicines.length.toString(),
          icon:
              Icons.medication_rounded,
        ),
        _StockReportRow(
          title: _t(l10n, 'Stock Value', 'Thamani ya Stock'),
          value:
              _formatCurrency(
            _stockValue,
          ),
          icon:
              Icons.inventory_2_rounded,
        ),
        _StockReportRow(
          title: _t(l10n, 'Low Stock', 'Stock Ndogo'),
          value:
              _lowStockCount.toString(),
          icon:
              Icons.warning_amber_rounded,
          valueColor:
              _lowStockCount > 0
                  ? Colors.orange
                  : Colors.green,
        ),
        _StockReportRow(
          title: _t(l10n, 'Expiry Alerts', 'Tahadhari za Muda wa Kuisha'),
          value:
              _expiryAlertCount.toString(),
          icon:
              Icons.event_busy_rounded,
          valueColor:
              _expiryAlertCount > 0
                  ? Colors.red
                  : Colors.green,
        ),
      ],
    );
  }

  Widget _buildSalesSection() {
    final l10n = AppLocalizations.of(context);    return _ReportListSection<SaleModel>(
      title: _t(l10n, 'Recent Sales', 'Mauzo ya Karibuni'),
      emptyMessage:
          _t(l10n, 'No sales in this period.', 'Hakuna mauzo katika kipindi hiki.'),
      items:
          _sales.take(5).toList(),
      itemBuilder: (sale) {
        return _TransactionRow(
          title:
              sale.medicineName,
          subtitle:
              '${sale.quantity} ${_t(l10n, 'units', 'vipimo')} • '
              '${sale.customerName.isEmpty ? _t(l10n, 'Walk-in Customer', 'Mteja wa kawaida') : sale.customerName}',
          amount:
              _formatCurrency(
            sale.totalAmount,
          ),
          secondary:
              _t(
                l10n,
                'Profit ${_formatCurrency(sale.profit)}',
                'Faida ${_formatCurrency(sale.profit)}',
              ),
          icon:
              Icons.point_of_sale_rounded,
        );
      },
    );
  }

  Widget _buildPurchaseSection() {
    final l10n = AppLocalizations.of(context);    return _ReportListSection<PurchaseModel>(
      title: _t(l10n, 'Recent Purchases', 'Manunuzi ya Karibuni'),
      emptyMessage:
          _t(l10n, 'No purchases in this period.', 'Hakuna manunuzi katika kipindi hiki.'),
      items:
          _purchases.take(5).toList(),
      itemBuilder: (purchase) {
        return _TransactionRow(
          title:
              purchase.medicineName,
          subtitle:
              '${purchase.quantity} ${_t(l10n, 'units', 'vipimo')} • '
              '${purchase.supplierName.isEmpty ? _t(l10n, 'No Supplier', 'Hakuna Msambazaji') : purchase.supplierName}',
          amount:
              _formatCurrency(
            purchase.totalCost,
          ),
          secondary:
              _t(
                l10n,
                'Unit ${_formatCurrency(purchase.unitCost)}',
                'Kipimo ${_formatCurrency(purchase.unitCost)}',
              ),
          icon:
              Icons.add_shopping_cart_rounded,
        );
      },
    );
  }

  Widget _buildExpenseSection() {
    final l10n = AppLocalizations.of(context);    return _ReportListSection<ExpenseModel>(
      title: _t(l10n, 'Recent Expenses', 'Gharama za Karibuni'),
      emptyMessage:
          _t(l10n, 'No expenses in this period.', 'Hakuna gharama katika kipindi hiki.'),
      items:
          _expenses.take(5).toList(),
      itemBuilder: (expense) {
        return _TransactionRow(
          title:
              expense.description.isEmpty
                  ? _t(l10n, 'Expense', 'Gharama')
                  : expense.description,
          subtitle:
              '${expense.category} • '
              '${expense.paymentMethod}',
          amount:
              _formatCurrency(
            expense.amount,
          ),
          secondary:
              expense.reference.isEmpty
                  ? _t(l10n, 'No reference', 'Hakuna kumbukumbu')
                  : expense.reference,
          icon:
              Icons.receipt_long_rounded,
        );
      },
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius:
          BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius:
              BorderRadius.circular(14),
          border: Border.all(
            color:
                Colors.grey.shade300,
          ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color:
                    Colors.grey.shade600,
                fontSize: 11,
              ),
            ),
            const SizedBox(
              height: 4,
            ),
            Text(
              value,
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportCard
    extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _ReportCard({
    required this.title,
    required this.value,
    required this.icon,
    this.valueColor,
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
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Theme.of(context)
                .colorScheme
                .primary,
          ),
          const Spacer(),
          Text(
            title,
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
            style: TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniReportCard
    extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  const _MiniReportCard({
    required this.title,
    required this.value,
    required this.subtitle,
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
        border: Border.all(
          color:
              Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context)
                .colorScheme
                .primary,
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
                  style: TextStyle(
                    color:
                        Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  value,
                  style:
                      const TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color:
                        Colors.grey.shade600,
                    fontSize: 11,
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

class _StockReportRow
    extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _StockReportRow({
    required this.title,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 8,
      ),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color:
              Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: valueColor ??
                Theme.of(context)
                    .colorScheme
                    .primary,
          ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child: Text(
              title,
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style:
                TextStyle(
              fontWeight:
                  FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionRow
    extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final String secondary;
  final IconData icon;

  const _TransactionRow({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.secondary,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 8,
      ),
      padding:
          const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color:
              Colors.grey.shade300,
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
                    alpha: 0.08,
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
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  subtitle,
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
                  height: 2,
                ),
                Text(
                  secondary,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: TextStyle(
                    color:
                        Colors.grey.shade600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            width: 8,
          ),
          Text(
            amount,
            style:
                const TextStyle(
              fontWeight:
                  FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportListSection<T>
    extends StatelessWidget {
  final String title;
  final String emptyMessage;
  final List<T> items;
  final Widget Function(T item)
      itemBuilder;

  const _ReportListSection({
    required this.title,
    required this.emptyMessage,
    required this.items,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style:
              const TextStyle(
            fontSize: 18,
            fontWeight:
                FontWeight.bold,
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.all(20),
            decoration:
                BoxDecoration(
              borderRadius:
                  BorderRadius.circular(14),
              border: Border.all(
                color:
                    Colors.grey.shade300,
              ),
            ),
            child: Text(
              emptyMessage,
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    Colors.grey.shade600,
              ),
            ),
          )
        else
          ...items.map(itemBuilder),
      ],
    );
  }
}
