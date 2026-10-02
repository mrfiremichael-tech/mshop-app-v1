import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/app_controller.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/medicine_model.dart';
import '../../models/sale_model.dart';
import '../../models/stock_record_model.dart';
import '../../repositories/medicine_repository.dart';
import '../../repositories/sale_repository.dart';
import '../../repositories/stock_record_repository.dart';
import '../../services/auth_service.dart';

import 'customers/customer_list_screen.dart';
import 'expenses/expense_list_screen.dart';
import 'medicines/add_medicine_screen.dart';
import 'medicines/medicine_list_screen.dart';
import 'owner_notifications_screen.dart';
import 'purchases/add_purchase_screen.dart';
import 'purchases/purchase_list_screen.dart';
import 'purchases/stock_records_screen.dart';
import 'reports/reports_screen.dart';
import 'sales/add_sale_screen.dart';
import 'sales/sales_list_screen.dart';
import 'staff/staff_list_screen.dart';
import 'suppliers/supplier_list_screen.dart';
import 'settings_screen.dart';

class PharmacyDashboard extends StatefulWidget {
  final AppController appController;

  const PharmacyDashboard({
    super.key,
    required this.appController,
  });

  @override
  State<PharmacyDashboard> createState() =>
      _PharmacyDashboardState();
}

class _PharmacyDashboardState
    extends State<PharmacyDashboard> {
  final AuthService _authService = AuthService();

  final MedicineRepository _medicineRepository =
      MedicineRepository();

  final SaleRepository _saleRepository =
      SaleRepository();

  final StockRecordRepository _stockRecordRepository =
      StockRecordRepository();

  String? _pharmacyId;
  String _pharmacyName = 'M-Shop Pharmacy';
  String _ownerName = '';

  DateTime _selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _loadPharmacyData();
    });
  }

  Future<void> _loadPharmacyData() async {
    final l10n = AppLocalizations.of(context);

    try {
      final profile =
          await _authService.getCurrentUserProfile();

      final pharmacyId =
          await _authService.getCurrentPharmacyId();

      if (!mounted) {
        return;
      }

      setState(() {
        _pharmacyId = pharmacyId;

        if (profile != null) {
          final pharmacyName =
              profile['pharmacyName']?.toString();

          final ownerName =
              profile['fullName']?.toString();

          if (pharmacyName != null &&
              pharmacyName.isNotEmpty) {
            _pharmacyName = pharmacyName;
          }

          if (ownerName != null &&
              ownerName.isNotEmpty) {
            _ownerName = ownerName;
          }
        }
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        '${l10n.isSwahili ? 'Imeshindikana kupakia taarifa za famasi: ' : 'Failed to load pharmacy information: '}${_cleanError(e)}',
      );
    }
  }

  Future<void> _openScreen(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => screen,
      ),
    );
  }

  Future<void> _openAddMedicine() async {
    if (_pharmacyId == null) {
      return;
    }

    await _openScreen(
      AddMedicineScreen(
        pharmacyId: _pharmacyId!,
      ),
    );
  }

  Future<void> _openAddPurchase() async {
    if (_pharmacyId == null) {
      return;
    }

    await _openScreen(
      AddPurchaseScreen(
        pharmacyId: _pharmacyId!,
      ),
    );
  }

  Future<void> _openAddSale() async {
    if (_pharmacyId == null) {
      return;
    }

    await _openScreen(
      AddSaleScreen(
        pharmacyId: _pharmacyId!,
      ),
    );
  }

  Future<void> _openMedicines() async {
    await _openScreen(
      const MedicineListScreen(),
    );
  }

  Future<void> _openPurchases() async {
    await _openScreen(
      const PurchaseListScreen(),
    );
  }

  Future<void> _openStockRecords() async {
    if (_pharmacyId == null) {
      return;
    }

    await _openScreen(
      StockRecordsScreen(
        pharmacyId: _pharmacyId!,
      ),
    );
  }

  Future<void> _openSales() async {
    await _openScreen(
      const SalesListScreen(),
    );
  }

  Future<void> _openCustomers() async {
    await _openScreen(
      const CustomerListScreen(),
    );
  }

  Future<void> _openSuppliers() async {
    await _openScreen(
      const SupplierListScreen(),
    );
  }

  Future<void> _openExpenses() async {
    await _openScreen(
      const ExpenseListScreen(),
    );
  }

  Future<void> _openReports() async {
    await _openScreen(
      const ReportsScreen(),
    );
  }

  Future<void> _openStaff() async {
    await _openScreen(
      const StaffListScreen(),
    );
  }

  Future<void> _openSettings() async {
    await _openScreen(
      SettingsScreen(
        appController: widget.appController,
      ),
    );

    if (mounted) {
      await _loadPharmacyData();
    }
  }

  Future<void> _openNotifications(
    List<MedicineModel> medicines,
  ) async {
    if (_pharmacyId == null) {
      return;
    }

    await _openScreen(
      OwnerNotificationsScreen(
        pharmacyId: _pharmacyId!,
      ),
    );
  }

  Future<void> _selectMonth() async {
    final l10n = AppLocalizations.of(context);

    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(
        DateTime.now().year,
        DateTime.now().month,
        1,
      ),
      helpText:
          l10n.isSwahili
              ? 'Chagua mwezi'
              : 'Select month',
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _selectedMonth = DateTime(
        selected.year,
        selected.month,
      );
    });
  }

  Future<void> _logout() async {
    final l10n = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.logout),
          content: Text(
            l10n.logoutConfirmation,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: Text(l10n.logout),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await _authService.logout();

    if (!mounted) {
      return;
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
  }

  void _showProfileDialog() {
    final l10n = AppLocalizations.of(context);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            l10n.isSwahili
                ? 'Wasifu wa Famasi'
                : 'Pharmacy Profile',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ProfileRow(
                label: l10n.pharmacy,
                value: _pharmacyName,
              ),
              const SizedBox(height: 12),
              _ProfileRow(
                label: l10n.owner,
                value: _ownerName.isEmpty
                    ? '-'
                    : _ownerName,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(l10n.close),
            ),
          ],
        );
      },
    );
  }

  void _showMoreManagement() {
    final l10n = AppLocalizations.of(context);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: Text(
                  l10n.management,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _ManagementTile(
                title: l10n.medicines,
                icon: Icons.inventory_2_outlined,
                onTap: _openMedicines,
              ),
              _ManagementTile(
                title: l10n.purchases,
                icon: Icons.shopping_cart_outlined,
                onTap: _openPurchases,
              ),
              _ManagementTile(
                title: l10n.isSwahili
                    ? 'Rekodi za Stock'
                    : 'Stock Records',
                icon: Icons.history_rounded,
                onTap: _openStockRecords,
              ),
              _ManagementTile(
                title: l10n.sales,
                icon: Icons.receipt_long_outlined,
                onTap: _openSales,
              ),
              _ManagementTile(
                title: l10n.suppliers,
                icon: Icons.local_shipping_outlined,
                onTap: _openSuppliers,
              ),
              _ManagementTile(
                title: l10n.customers,
                icon: Icons.people_outline_rounded,
                onTap: _openCustomers,
              ),
              _ManagementTile(
                title: l10n.expenses,
                icon: Icons.payments_outlined,
                onTap: _openExpenses,
              ),
              _ManagementTile(
                title: l10n.staff,
                icon: Icons.badge_outlined,
                onTap: _openStaff,
              ),
              _ManagementTile(
                title: l10n.reports,
                icon: Icons.bar_chart_outlined,
                onTap: _openReports,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
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

  String _currency(double value) {
    return 'TSh ${value.toStringAsFixed(0)}';
  }

  String _monthName(DateTime date) {
    const englishMonths = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    const swahiliMonths = [
      'Januari',
      'Februari',
      'Machi',
      'Aprili',
      'Mei',
      'Juni',
      'Julai',
      'Agosti',
      'Septemba',
      'Oktoba',
      'Novemba',
      'Desemba',
    ];

    final months =
        AppLocalizations.of(context).isSwahili
            ? swahiliMonths
            : englishMonths;

    return '${months[date.month - 1]} ${date.year}';
  }

  DateTime _monthStart(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      1,
    );
  }

  DateTime _monthEnd(DateTime date) {
    return DateTime(
      date.year,
      date.month + 1,
      1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_pharmacyId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            l10n.appName,
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _loadPharmacyData,
        child: StreamBuilder<List<MedicineModel>>(
          stream:
              _medicineRepository.watchMedicines(
            _pharmacyId!,
          ),
          builder: (
            context,
            medicineSnapshot,
          ) {
            if (medicineSnapshot.hasError) {
              return _ErrorView(
                message:
                    l10n.failedToLoadMedicineData,
                onRetry: _loadPharmacyData,
              );
            }

            final medicines =
                medicineSnapshot.data ?? [];

            return StreamBuilder<List<SaleModel>>(
              stream: _saleRepository.watchSales(
                _pharmacyId!,
              ),
              builder: (
                context,
                saleSnapshot,
              ) {
                if (saleSnapshot.hasError) {
                  return _ErrorView(
                    message:
                        l10n.failedToLoadSalesData,
                    onRetry: _loadPharmacyData,
                  );
                }

                final sales =
                    saleSnapshot.data ?? [];

                return StreamBuilder<
                    List<StockRecordModel>>(
                  stream:
                      _stockRecordRepository
                          .watchStockRecords(
                    _pharmacyId!,
                  ),
                  builder: (
                    context,
                    stockSnapshot,
                  ) {
                    if (stockSnapshot.hasError) {
                      return _ErrorView(
                        message:
                            l10n.failedToLoadStockRecords,
                        onRetry:
                            _loadPharmacyData,
                      );
                    }

                    final stockRecords =
                        stockSnapshot.data ?? [];

                    return _buildDashboard(
                      medicines,
                      sales,
                      stockRecords,
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final l10n = AppLocalizations.of(context);

    return AppBar(
      title: Text(
        l10n.appName,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        _NotificationButton(
          pharmacyId: _pharmacyId!,
          onTap: _openNotifications,
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'profile') {
              _showProfileDialog();
            }

            if (value == 'settings') {
              _openSettings();
            }

            if (value == 'logout') {
              _logout();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  const Icon(
                    Icons.person_outline_rounded,
                  ),
                  const SizedBox(width: 10),
                  Text(l10n.profile),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  const Icon(
                    Icons.settings_outlined,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    l10n.isSwahili
                        ? 'Mipangilio'
                        : 'Settings',
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  const Icon(
                    Icons.logout_rounded,
                  ),
                  const SizedBox(width: 10),
                  Text(l10n.logout),
                ],
              ),
            ),
          ],
          child: const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 12,
            ),
            child: Icon(
              Icons.account_circle_rounded,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDashboard(
    List<MedicineModel> medicines,
    List<SaleModel> sales,
    List<StockRecordModel> stockRecords,
  ) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();

    final todayStart = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final todayEnd =
        todayStart.add(
      const Duration(days: 1),
    );

    final todaySales =
        sales.where((sale) {
      final date = sale.createdAt;

      if (date == null) {
        return false;
      }

      return !date.isBefore(todayStart) &&
          date.isBefore(todayEnd);
    }).toList();

    final todaySalesAmount =
        todaySales.fold<double>(
      0,
      (total, sale) =>
          total + sale.totalAmount,
    );

    final todayProfit =
        todaySales.fold<double>(
      0,
      (total, sale) =>
          total + sale.profit,
    );

    final totalStock =
        medicines.fold<int>(
      0,
      (total, medicine) =>
          total + medicine.quantity,
    );

    final lowStockCount =
        medicines.where(
      (medicine) => medicine.isLowStock,
    ).length;

    final monthStart =
        _monthStart(_selectedMonth);

    final monthEnd =
        _monthEnd(_selectedMonth);

    final monthSales =
        sales.where((sale) {
      final date = sale.createdAt;

      if (date == null) {
        return false;
      }

      return !date.isBefore(monthStart) &&
          date.isBefore(monthEnd);
    }).toList();

    final monthStock =
        stockRecords.where((record) {
      return !record.stockDate
              .isBefore(monthStart) &&
          record.stockDate
              .isBefore(monthEnd);
    }).toList();

    final monthlyStockIn =
        monthStock.fold<int>(
      0,
      (total, record) =>
          total + record.quantity,
    );

    final monthlyUnitsSold =
        monthSales.fold<int>(
      0,
      (total, sale) =>
          total + sale.quantity,
    );

    final monthlySales =
        monthSales.fold<double>(
      0,
      (total, sale) =>
          total + sale.totalAmount,
    );

    final monthlyProfit =
        monthSales.fold<double>(
      0,
      (total, sale) =>
          total + sale.profit,
    );

    final monthlySellThrough =
        monthlyStockIn == 0
            ? 0.0
            : (monthlyUnitsSold /
                    monthlyStockIn) *
                100;

    final performance =
        _medicinePerformance(
      medicines,
      monthSales,
      monthStock,
    );

    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        32,
      ),
      children: [
        _buildWelcomeCard(),
        const SizedBox(height: 16),
        Text(
          l10n.today,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: l10n.sales,
                value:
                    _currency(todaySalesAmount),
                icon:
                    Icons.point_of_sale_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                title: l10n.profit,
                value:
                    _currency(todayProfit),
                icon:
                    Icons.trending_up_rounded,
                valueColor: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: l10n.currentStock,
                value:
                    totalStock.toString(),
                icon:
                    Icons.inventory_2_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                title: l10n.lowStock,
                value:
                    lowStockCount.toString(),
                icon:
                    Icons.warning_amber_rounded,
                valueColor:
                    lowStockCount > 0
                        ? Colors.orange
                        : Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.monthlyPerformance,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _selectMonth,
              icon: const Icon(
                Icons.calendar_month_rounded,
                size: 18,
              ),
              label: Text(
                _monthName(_selectedMonth),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _MonthlyCard(
          stockIn: monthlyStockIn,
          unitsSold: monthlyUnitsSold,
          sales: monthlySales,
          profit: monthlyProfit,
          sellThrough:
              monthlySellThrough,
        ),
        const SizedBox(height: 20),
        _SalesRateCard(
          performance: performance,
        ),
        const SizedBox(height: 20),
        _buildQuickActions(),
        const SizedBox(height: 20),
        _buildAttentionSection(
          medicines,
        ),
      ],
    );
  }

  Widget _buildWelcomeCard() {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [
            Theme.of(context)
                .colorScheme
                .primary,
            Theme.of(context)
                .colorScheme
                .primary
                .withValues(alpha: 0.72),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            l10n.welcomeBack,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _ownerName.isEmpty
                ? _pharmacyName
                : _ownerName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _pharmacyName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  List<_MedicinePerformance>
      _medicinePerformance(
    List<MedicineModel> medicines,
    List<SaleModel> monthSales,
    List<StockRecordModel> monthStock,
  ) {
    final result =
        <_MedicinePerformance>[];

    for (final medicine in medicines) {
      final sold =
          monthSales.where(
        (sale) =>
            sale.medicineId ==
            medicine.id,
      ).fold<int>(
        0,
        (total, sale) =>
            total + sale.quantity,
      );

      final stockIn =
          monthStock.where(
        (record) =>
            record.medicineId ==
            medicine.id,
      ).fold<int>(
        0,
        (total, record) =>
            total + record.quantity,
      );

      if (sold == 0 && stockIn == 0) {
        continue;
      }

      final rate =
          (sold + medicine.quantity) == 0
              ? 0.0
              : (sold /
                      (sold + medicine.quantity)) *
                  100;

      result.add(
        _MedicinePerformance(
          medicine: medicine,
          sold: sold,
          stockIn: stockIn,
          rate: rate,
        ),
      );
    }

    result.sort(
      (a, b) =>
          b.rate.compareTo(a.rate),
    );

    return result;
  }

  Widget _buildQuickActions() {
    final l10n = AppLocalizations.of(context);

    return _SectionBox(
      title: l10n.quickActions,
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              title: l10n.newSale,
              icon:
                  Icons.point_of_sale_rounded,
              onTap: _openAddSale,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ActionButton(
              title: l10n.purchaseStock,
              icon:
                  Icons.add_shopping_cart_rounded,
              onTap: _openAddPurchase,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ActionButton(
              title: l10n.addMedicine,
              icon:
                  Icons.medication_rounded,
              onTap: _openAddMedicine,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttentionSection(
    List<MedicineModel> medicines,
  ) {
    final l10n = AppLocalizations.of(context);

    final expiryCount =
        medicines.where(
      (medicine) =>
          medicine.isExpired ||
          medicine.expiresWithin30Days,
    ).length;

    final lowStockCount =
        medicines.where(
      (medicine) => medicine.isLowStock,
    ).length;

    return _SectionBox(
      title: l10n.attention,
      child: Column(
        children: [
          _AttentionRow(
            title: l10n.lowStock,
            value: l10n.isSwahili
                ? '$lowStockCount bidhaa'
                : '$lowStockCount products',
            icon:
                Icons.warning_amber_rounded,
            color:
                lowStockCount > 0
                    ? Colors.orange
                    : Colors.green,
            onTap: _openMedicines,
          ),
          const SizedBox(height: 8),
          _AttentionRow(
            title: l10n.expiryAlerts,
            value: l10n.isSwahili
                ? '$expiryCount bidhaa'
                : '$expiryCount products',
            icon:
                Icons.event_busy_rounded,
            color:
                expiryCount > 0
                    ? Colors.red
                    : Colors.green,
            onTap: _openMedicines,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed:
                  _showMoreManagement,
              icon: const Icon(
                Icons.apps_rounded,
              ),
              label: Text(
                l10n.moreManagement,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  final String pharmacyId;
  final Future<void> Function(List<MedicineModel>) onTap;

  const _NotificationButton({
    required this.pharmacyId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return IconButton(
        tooltip: l10n.notifications,
        onPressed: null,
        icon: const Icon(
          Icons.notifications_none_rounded,
          size: 28,
        ),
      );
    }

    final stream = FirebaseFirestore.instance
        .collection('notifications')
        .where(
          'pharmacyId',
          isEqualTo: pharmacyId,
        )
        .where(
          'recipientUid',
          isEqualTo: user.uid,
        )
        .where(
          'isRead',
          isEqualTo: false,
        )
        .snapshots();

    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;

        return StreamBuilder<List<MedicineModel>>(
          stream: MedicineRepository().watchMedicines(
            pharmacyId,
          ),
          builder: (context, medicineSnapshot) {
            final medicines =
                medicineSnapshot.data ?? [];

            return IconButton(
              tooltip: l10n.notifications,
              onPressed: () => onTap(medicines),
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.notifications_none_rounded,
                    size: 28,
                  ),
                  if (count > 0)
                    Positioned(
                      right: -5,
                      top: -5,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _MetricCard
    extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final primary =
        Theme.of(context)
            .colorScheme
            .primary;

    return Container(
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(12),
              color: primary.withValues(
                alpha: 0.10,
              ),
            ),
            child: Icon(
              icon,
              size: 20,
              color: valueColor ?? primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.bold,
                    color: valueColor,
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

class _MonthlyCard
    extends StatelessWidget {
  final int stockIn;
  final int unitsSold;
  final double sales;
  final double profit;
  final double sellThrough;

  const _MonthlyCard({
    required this.stockIn,
    required this.unitsSold,
    required this.sales,
    required this.profit,
    required this.sellThrough,
  });

  String _currency(double value) {
    return 'TSh ${value.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _Item(
                  title: l10n.stockIn,
                  value:
                      l10n.isSwahili
                          ? '$stockIn vipande'
                          : '$stockIn pcs',
                  icon:
                      Icons.add_box_outlined,
                ),
              ),
              Expanded(
                child: _Item(
                  title: l10n.unitsSold,
                  value:
                      l10n.isSwahili
                          ? '$unitsSold vipande'
                          : '$unitsSold pcs',
                  icon:
                      Icons.shopping_cart_outlined,
                ),
              ),
            ],
          ),
          const Divider(height: 26),
          Row(
            children: [
              Expanded(
                child: _Item(
                  title: l10n.sales,
                  value:
                      _currency(sales),
                  icon:
                      Icons.point_of_sale_outlined,
                ),
              ),
              Expanded(
                child: _Item(
                  title: l10n.profit,
                  value:
                      _currency(profit),
                  icon:
                      Icons.trending_up_outlined,
                  valueColor:
                      Colors.green,
                ),
              ),
            ],
          ),
          const Divider(height: 26),
          Row(
            children: [
              Expanded(
                child: _Item(
                  title: l10n.sellThrough,
                  value:
                      '${sellThrough.toStringAsFixed(1)}%',
                  icon:
                      Icons.percent_rounded,
                  valueColor:
                      Theme.of(context)
                          .colorScheme
                          .primary,
                ),
              ),
              Expanded(
                child: Text(
                  l10n.unitsSoldStockInFormula,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Item
    extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _Item({
    required this.title,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 19,
          color:
              Theme.of(context)
                  .colorScheme
                  .primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      FontWeight.bold,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SalesRateCard
    extends StatelessWidget {
  final List<_MedicinePerformance>
      performance;

  const _SalesRateCard({
    required this.performance,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final visible =
        performance.take(6).toList();

    return _SectionBox(
      title: l10n.medicineSalesRate,
      child: visible.isEmpty
          ? Padding(
              padding:
                  const EdgeInsets.symmetric(
                vertical: 18,
              ),
              child: Center(
                child: Text(
                  l10n
                      .noMonthlyMedicineSalesData,
                ),
              ),
            )
          : Column(
              children:
                  visible.map(
                (item) {
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 8,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.medicine.name,
                                maxLines: 1,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Text(
                              '${item.rate.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                                color:
                                    Theme.of(
                                  context,
                                )
                                        .colorScheme
                                        .primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Expanded(
                              child:
                                  LinearProgressIndicator(
                                value:
                                    item.rate > 100
                                        ? 1
                                        : item.rate /
                                            100,
                                minHeight: 7,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${item.sold}/${item.stockIn}',
                              style:
                                  const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ).toList(),
            ),
    );
  }
}

class _MedicinePerformance {
  final MedicineModel medicine;
  final int sold;
  final int stockIn;
  final double rate;

  const _MedicinePerformance({
    required this.medicine,
    required this.sold,
    required this.stockIn,
    required this.rate,
  });
}

class _SectionBox
    extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionBox({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ActionButton
    extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style:
          OutlinedButton.styleFrom(
        padding:
            const EdgeInsets.symmetric(
          vertical: 13,
        ),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(14),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 21,
          ),
          const SizedBox(height: 5),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow:
                TextOverflow.ellipsis,
            style:
                const TextStyle(
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttentionRow
    extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AttentionRow({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(14),
      child: Container(
        padding:
            const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius:
              BorderRadius.circular(14),
          border: Border.all(
            color: Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: color,
            ),
            const SizedBox(width: 10),
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
              style: TextStyle(
                color: color,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(width: 5),
            const Icon(
              Icons.chevron_right_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

class _ManagementTile
    extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _ManagementTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }
}

class _ProfileRow
    extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: TextStyle(
              color:
                  Colors.grey.shade600,
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
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorView
    extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n =
        AppLocalizations.of(context);

    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height:
              MediaQuery.of(context)
                  .size
                  .height *
              0.65,
          child: Center(
            child: Padding(
              padding:
                  const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 60,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: onRetry,
                    child:
                        Text(l10n.retry),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
