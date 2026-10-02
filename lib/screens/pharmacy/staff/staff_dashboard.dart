import 'package:flutter/material.dart';

import '../../../core/app_controller.dart';
import '../../../repositories/medicine_repository.dart';
import '../../../services/auth_service.dart';
import '../../../services/notifications/notification_service.dart';
import 'staff_notifications_screen.dart';
import 'staff_reports_screen.dart';

import '../customers/customer_list_screen.dart';
import '../expenses/expense_list_screen.dart';
import '../medicines/add_medicine_screen.dart';
import '../medicines/medicine_list_screen.dart';
import '../purchases/add_purchase_screen.dart';
import '../purchases/purchase_list_screen.dart';
import '../purchases/stock_records_screen.dart';
import '../sales/add_sale_screen.dart';
import '../sales/sales_list_screen.dart';
import '../suppliers/supplier_list_screen.dart';

class StaffDashboard extends StatefulWidget {
  final AppController appController;

  const StaffDashboard({
    super.key,
    required this.appController,
  });

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  final AuthService _authService = AuthService();

  final NotificationService _notificationService =
      NotificationService.instance;

  final MedicineRepository _medicineRepository =
      MedicineRepository();

  String _staffName = 'Staff';
  String _pharmacyName = 'M-Shop Pharmacy';
  String? _pharmacyId;

  Set<String> _permissions = {};

  bool _loading = true;
  int _unreadNotificationCount = 0;

  bool get _isSwahili =>
      widget.appController.isSwahili;

  bool _can(String permission) {
    return _permissions.contains(permission);
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _loadStaffProfile();
      _loadUnreadNotifications();
    });
  }

  Future<void> _loadStaffProfile() async {
    try {
      final profile =
          await _authService.getCurrentUserProfile();

      if (!mounted) {
        return;
      }

      final permissions =
          profile?['permissions'];

      final pharmacyId =
          profile?['pharmacyId']?.toString();

      setState(() {
        _staffName =
            profile?['fullName']?.toString() ??
                'Staff';

        _pharmacyName =
            profile?['pharmacyName']?.toString() ??
                'M-Shop Pharmacy';

        _pharmacyId = pharmacyId;

        _permissions = permissions is List
            ? permissions
                .map((e) => e.toString())
                .toSet()
            : <String>{};

        _loading = false;
      });

      await _checkMedicineAlerts();
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _checkMedicineAlerts() async {
    final pharmacyId = _pharmacyId;

    if (pharmacyId == null ||
        pharmacyId.isEmpty) {
      return;
    }

    try {
      final medicines =
          await _medicineRepository.getMedicines(
        pharmacyId,
      );

      for (final medicine in medicines) {
        if (!mounted) {
          return;
        }

        await _notificationService
            .checkAndCreateMedicineAlerts(
          pharmacyId: pharmacyId,
          medicineId: medicine.id,
          medicineName: medicine.name,
          quantity: medicine.quantity,
          isLowStock: medicine.isLowStock,
          expiryDate: medicine.expiryDate,
          isExpired: medicine.isExpired,
          expiresWithin30Days:
              medicine.expiresWithin30Days,
          unit: medicine.unit,
        );
      }

      await _loadUnreadNotifications();
    } catch (_) {
      // Alert check should never stop Staff Dashboard.
    }
  }

  Future<void> _loadUnreadNotifications() async {
    try {
      final count =
          await _notificationService
              .getUnreadCount();

      if (!mounted) {
        return;
      }

      setState(() {
        _unreadNotificationCount = count;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _unreadNotificationCount = 0;
      });
    }
  }

  Future<void> _openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const StaffNotificationsScreen(),
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadUnreadNotifications();
  }

  Future<void> _open(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => screen,
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadStaffProfile();
    await _loadUnreadNotifications();
  }

  Future<void> _openAddSale() async {
    if (_pharmacyId == null ||
        _pharmacyId!.isEmpty) {
      return;
    }

    await _open(
      AddSaleScreen(
        pharmacyId: _pharmacyId!,
      ),
    );
  }

  Future<void> _openAddMedicine() async {
    if (_pharmacyId == null ||
        _pharmacyId!.isEmpty) {
      return;
    }

    await _open(
      AddMedicineScreen(
        pharmacyId: _pharmacyId!,
      ),
    );
  }

  Future<void> _openAddPurchase() async {
    if (_pharmacyId == null ||
        _pharmacyId!.isEmpty) {
      return;
    }

    await _open(
      AddPurchaseScreen(
        pharmacyId: _pharmacyId!,
      ),
    );
  }

  Future<void> _openStockRecords() async {
    if (_pharmacyId == null ||
        _pharmacyId!.isEmpty) {
      return;
    }

    await _open(
      StockRecordsScreen(
        pharmacyId: _pharmacyId!,
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            _isSwahili
                ? 'Toka'
                : 'Logout',
          ),
          content: Text(
            _isSwahili
                ? 'Una uhakika unataka kutoka?'
                : 'Are you sure you want to logout?',
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
                _isSwahili
                    ? 'Ghairi'
                    : 'Cancel',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: Text(
                _isSwahili
                    ? 'Toka'
                    : 'Logout',
              ),
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

  Widget _sectionTitle(
    String title,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child: Text(
        title,
        style:
            const TextStyle(
          fontSize: 19,
          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }

  Widget _permissionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(16),
        child: Padding(
          padding:
              const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration:
                    BoxDecoration(
                  color:
                      Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                ),
                child: Icon(
                  icon,
                  color:
                      Theme.of(context)
                          .colorScheme
                          .primary,
                  size: 25,
                ),
              ),
              const SizedBox(
                width: 14,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                          const TextStyle(
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        )
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons
                    .chevron_right_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _viewCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 160,
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          borderRadius:
              BorderRadius.circular(16),
          child: Padding(
            padding:
                const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 28,
                  color:
                      Theme.of(context)
                          .colorScheme
                          .primary,
                ),
                const SizedBox(
                  height: 10,
                ),
                Text(
                  title,
                  textAlign:
                      TextAlign.center,
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _notificationButton() {
    return Stack(
      clipBehavior:
          Clip.none,
      children: [
        IconButton(
          tooltip: _isSwahili
              ? 'Notifications'
              : 'Notifications',
          onPressed:
              _openNotifications,
          icon:
              const Icon(
            Icons
                .notifications_none_rounded,
          ),
        ),
        if (_unreadNotificationCount >
            0)
          Positioned(
            right: 3,
            top: 3,
            child:
                Container(
              constraints:
                  const BoxConstraints(
                minWidth: 19,
                minHeight: 19,
              ),
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 5,
                vertical: 2,
              ),
              decoration:
                  BoxDecoration(
                color: Theme.of(
                  context,
                )
                    .colorScheme
                    .error,
                borderRadius:
                    BorderRadius.circular(
                  20,
                ),
                border:
                    Border.all(
                  color: Theme.of(
                    context,
                  )
                      .colorScheme
                      .surface,
                  width: 2,
                ),
              ),
              child: Text(
                _unreadNotificationCount >
                        99
                    ? '99+'
                    : _unreadNotificationCount
                        .toString(),
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  color:
                      Colors.white,
                  fontSize: 10,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title:
              const Text(
            'M-Shop Pharmacy',
          ),
        ),
        body:
            const Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    final allowedActions =
        <Widget>[];

    // ============================================================
    // KAZI ANAZORUHUSIWA KUFANYA
    // ============================================================

    if (_can('create_sales')) {
      allowedActions.add(
        _permissionCard(
          title: _isSwahili
              ? 'Fanya Sale'
              : 'Make Sale',
          subtitle: _isSwahili
              ? 'Uza dawa na bidhaa kwa mteja'
              : 'Create a customer sale',
          icon: Icons
              .point_of_sale_rounded,
          onTap:
              _openAddSale,
        ),
      );
    }

    if (_can('add_products')) {
      allowedActions.add(
        _permissionCard(
          title: _isSwahili
              ? 'Ongeza Dawa'
              : 'Add Product',
          subtitle: _isSwahili
              ? 'Ongeza dawa au bidhaa mpya'
              : 'Add a new medicine or product',
          icon: Icons
              .medication_outlined,
          onTap:
              _openAddMedicine,
        ),
      );
    }

    if (_can('add_purchases')) {
      allowedActions.add(
        _permissionCard(
          title: _isSwahili
              ? 'Ongeza Purchase'
              : 'Add Purchase',
          subtitle: _isSwahili
              ? 'Ingiza stock iliyonunuliwa'
              : 'Record purchased stock',
          icon: Icons
              .add_shopping_cart_rounded,
          onTap:
              _openAddPurchase,
        ),
      );
    }

    if (_can('add_customers')) {
      allowedActions.add(
        _permissionCard(
          title: _isSwahili
              ? 'Ongeza Customer'
              : 'Add Customer',
          subtitle: _isSwahili
              ? 'Sajili customer mpya'
              : 'Register a new customer',
          icon: Icons
              .person_add_alt_1_rounded,
          onTap: () {
            _open(
              const CustomerListScreen(),
            );
          },
        ),
      );
    }

    if (_can('add_suppliers')) {
      allowedActions.add(
        _permissionCard(
          title: _isSwahili
              ? 'Ongeza Supplier'
              : 'Add Supplier',
          subtitle: _isSwahili
              ? 'Sajili supplier mpya'
              : 'Register a new supplier',
          icon: Icons
              .local_shipping_outlined,
          onTap: () {
            _open(
              const SupplierListScreen(),
            );
          },
        ),
      );
    }

    if (_can('add_expenses')) {
      allowedActions.add(
        _permissionCard(
          title: _isSwahili
              ? 'Ongeza Expense'
              : 'Add Expense',
          subtitle: _isSwahili
              ? 'Ingiza matumizi ya famasi'
              : 'Record a pharmacy expense',
          icon: Icons
              .payments_outlined,
          onTap: () {
            _open(
              const ExpenseListScreen(),
            );
          },
        ),
      );
    }

    // ============================================================
    // VITU ANAVYORUHUSIWA KUONA
    // ============================================================

    final visibleModules =
        <Widget>[];

    if (_can('view_products')) {
      visibleModules.add(
        _viewCard(
          title: _isSwahili
              ? 'Dawa'
              : 'Products',
          icon: Icons
              .inventory_2_outlined,
          onTap: () {
            _open(
              const MedicineListScreen(),
            );
          },
        ),
      );
    }

    if (_can('view_purchases')) {
      visibleModules.add(
        _viewCard(
          title: 'Purchases',
          icon: Icons
              .shopping_cart_outlined,
          onTap: () {
            _open(
              const PurchaseListScreen(),
            );
          },
        ),
      );
    }

    if (_can('create_sales') || _can('view_sales')) {
      visibleModules.add(
        _viewCard(
          title: _isSwahili ? 'Ripoti Zangu' : 'My Reports',
          icon: Icons.analytics_outlined,
          onTap: () {
            _open(const StaffReportsScreen());
          },
        ),
      );
    }

    if (_can('view_sales')) {
      visibleModules.add(
        _viewCard(
          title: 'Sales',
          icon: Icons
              .receipt_long_outlined,
          onTap: () {
            _open(
              const SalesListScreen(),
            );
          },
        ),
      );
    }

    if (_can('view_customers')) {
      visibleModules.add(
        _viewCard(
          title: 'Customers',
          icon: Icons
              .people_outline_rounded,
          onTap: () {
            _open(
              const CustomerListScreen(),
            );
          },
        ),
      );
    }

    if (_can('view_suppliers')) {
      visibleModules.add(
        _viewCard(
          title: 'Suppliers',
          icon: Icons
              .local_shipping_outlined,
          onTap: () {
            _open(
              const SupplierListScreen(),
            );
          },
        ),
      );
    }

    if (_can('view_stock')) {
      visibleModules.add(
        _viewCard(
          title: 'Stock',
          icon: Icons
              .inventory_outlined,
          onTap: () {
            _open(
              const MedicineListScreen(),
            );
          },
        ),
      );
    }

    if (_can('view_stock_records')) {
      visibleModules.add(
        _viewCard(
          title: _isSwahili
              ? 'Rekodi za Stock'
              : 'Stock Records',
          icon:
              Icons.history_rounded,
          onTap:
              _openStockRecords,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title:
            const Text(
          'M-Shop Pharmacy',
          style:
              TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        actions: [
          _notificationButton(),
          IconButton(
            tooltip: _isSwahili
                ? 'Badili Lugha'
                : 'Change Language',
            onPressed: () {
              widget.appController
                  .toggleLanguage();

              setState(() {});
            },
            icon: const Icon(
              Icons
                  .language_rounded,
            ),
          ),
          IconButton(
            tooltip: _isSwahili
                ? 'Toka'
                : 'Logout',
            onPressed:
                _logout,
            icon:
                const Icon(
              Icons.logout_rounded,
            ),
          ),
        ],
      ),
      body:
          RefreshIndicator(
        onRefresh: () async {
          await _loadStaffProfile();
          await _loadUnreadNotifications();
        },
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
            Container(
              padding:
                  const EdgeInsets.all(
                20,
              ),
              decoration:
                  BoxDecoration(
                borderRadius:
                    BorderRadius.circular(
                  20,
                ),
                gradient:
                    LinearGradient(
                  colors: [
                    Theme.of(context)
                        .colorScheme
                        .primary,
                    Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(
                      alpha: 0.72,
                    ),
                  ],
                ),
              ),
              child:
                  Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    _isSwahili
                        ? 'Karibu'
                        : 'Welcome',
                    style:
                        const TextStyle(
                      color:
                          Colors.white70,
                      fontSize:
                          14,
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Text(
                    _staffName,
                    style:
                        const TextStyle(
                      color:
                          Colors.white,
                      fontSize:
                          24,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    _pharmacyName,
                    style:
                        const TextStyle(
                      color:
                          Colors.white,
                      fontSize:
                          14,
                    ),
                  ),
                ],
              ),
            ),

            if (allowedActions
                .isNotEmpty) ...[
              const SizedBox(
                height: 22,
              ),
              _sectionTitle(
                _isSwahili
                    ? 'Kazi Ninazoruhusiwa Kufanya'
                    : 'Actions I Am Allowed To Perform',
              ),
              ...List.generate(
                allowedActions.length,
                (index) => Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom: 10,
                  ),
                  child:
                      allowedActions[index],
                ),
              ),
            ],

            if (visibleModules
                .isNotEmpty) ...[
              const SizedBox(
                height: 14,
              ),
              _sectionTitle(
                _isSwahili
                    ? 'Ninaruhusiwa Kuona'
                    : 'What I Am Allowed To View',
              ),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children:
                    visibleModules,
              ),
            ],

            const SizedBox(
              height: 16,
            ),

            if (allowedActions.isEmpty &&
                visibleModules.isEmpty)
              Padding(
                padding:
                    const EdgeInsets.only(
                  top: 50,
                ),
                child: Center(
                  child: Text(
                    _isSwahili
                        ? 'Hakuna permissions zilizowekwa kwenye akaunti hii.'
                        : 'No permissions have been configured for this account.',
                    textAlign:
                        TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}