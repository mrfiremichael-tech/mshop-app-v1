import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/app_controller.dart';
import '../../services/mshop_owner_notification_service.dart';
import '../auth/login_screen.dart';
import 'pharmacies/pharmacies_screen.dart';
import 'pharmacy_owners/pharmacy_owners_screen.dart';
import 'staff/staff_overview_screen.dart';
import 'subscriptions/subscriptions_screen.dart';
import 'notifications/mshop_notifications_screen.dart';

class MshopOwnerDashboard extends StatefulWidget {
  final AppController appController;

  const MshopOwnerDashboard({
    super.key,
    required this.appController,
  });

  @override
  State<MshopOwnerDashboard> createState() =>
      _MshopOwnerDashboardState();
}

class _MshopOwnerDashboardState
    extends State<MshopOwnerDashboard> {
  final MshopOwnerNotificationService _notificationService =
      MshopOwnerNotificationService.instance;

  bool get _isSwahili => widget.appController.isSwahili;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'M-Shop Owner',
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              _isSwahili
                  ? 'Usimamizi wa mfumo wa M-Shop'
                  : 'M-Shop platform management',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          StreamBuilder<int>(
            stream: _notificationService.streamUnreadCount(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;

              return IconButton(
                tooltip:
                    _isSwahili ? 'Notifications' : 'Notifications',
                onPressed: _openNotifications,
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.notifications_none_rounded,
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: -7,
                        top: -7,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.error,
                            borderRadius:
                                BorderRadius.circular(20),
                            border: Border.all(
                              color:
                                  colorScheme.surface,
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            unreadCount > 99
                                ? '99+'
                                : unreadCount.toString(),
                            style: TextStyle(
                              color: colorScheme.onError,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            tooltip: _isSwahili
                ? 'Mipangilio'
                : 'Settings',
            onPressed: () => _showMessage(
              _isSwahili
                  ? 'Mipangilio ya M-Shop itaunganishwa hapa.'
                  : 'M-Shop settings will be connected here.',
            ),
            icon: const Icon(
              Icons.settings_outlined,
            ),
          ),
          IconButton(
            tooltip: _isSwahili
                ? 'Toka'
                : 'Logout',
            onPressed: _logout,
            icon: const Icon(
              Icons.logout_rounded,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshDashboard,
          child: ListView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              16,
              18,
              16,
              28,
            ),
            children: [
              _buildWelcomeCard(context),
              const SizedBox(height: 22),
              Text(
                _isSwahili
                    ? 'Usimamizi wa Platform'
                    : 'Platform Management',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              _buildManagementGrid(context),
              const SizedBox(height: 24),
              _buildRulesCard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius:
                    BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.admin_panel_settings_rounded,
                color: colorScheme.onPrimary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    _isSwahili
                        ? 'Karibu kwenye M-Shop'
                        : 'Welcome to M-Shop',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color:
                          colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isSwahili
                        ? 'Hapa unasimamia M-Shop platform bila kuingia kwenye biashara za pharmacy.'
                        : 'Manage the M-Shop platform without operating pharmacy business data.',
                    style: TextStyle(
                      height: 1.35,
                      color: colorScheme
                          .onPrimaryContainer
                          .withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementGrid(
    BuildContext context,
  ) {
    final items = <_OwnerModuleItem>[
      _OwnerModuleItem(
        icon: Icons.local_pharmacy_outlined,
        title: 'Pharmacies',
        subtitle: _isSwahili
            ? 'Simamia pharmacies za platform'
            : 'Manage pharmacies on the platform',
        onTap: _openPharmacies,
      ),
      _OwnerModuleItem(
        icon: Icons.person_outline_rounded,
        title: 'Pharmacy Owners',
        subtitle: _isSwahili
            ? 'Simamia accounts za pharmacy owners'
            : 'Manage pharmacy owner accounts',
        onTap: _openPharmacyOwners,
      ),
      _OwnerModuleItem(
        icon: Icons.groups_outlined,
        title: 'Staff',
        subtitle: _isSwahili
            ? 'Tazama staff wa pharmacies'
            : 'View staff across pharmacies',
        onTap: _openStaff,
      ),
      _OwnerModuleItem(
        icon: Icons.card_membership_outlined,
        title: 'Subscriptions',
        subtitle: _isSwahili
            ? 'Simamia plans na subscription status'
            : 'Manage plans and subscription status',
        onTap: _openSubscriptions,
      ),
      _OwnerModuleItem(
        icon: Icons.notifications_none_rounded,
        title: 'Notifications',
        subtitle: _isSwahili
            ? 'Taarifa muhimu za platform'
            : 'Important platform notifications',
        onTap: _openNotifications,
      ),
      _OwnerModuleItem(
        icon: Icons.tune_rounded,
        title: 'Platform Settings',
        subtitle: _isSwahili
            ? 'Mipangilio ya M-Shop platform'
            : 'M-Shop platform settings',
        onTap: () => _openModule(
          'Platform Settings',
        ),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide =
            constraints.maxWidth >= 760;
        final crossAxisCount =
            isWide ? 3 : 2;
        final childAspectRatio =
            isWide ? 1.18 : 0.92;

        return GridView.builder(
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio:
                childAspectRatio,
          ),
          itemBuilder: (context, index) =>
              _buildModuleCard(
            context,
            items[index],
          ),
        );
      },
    );
  }

  Widget _buildModuleCard(
    BuildContext context,
    _OwnerModuleItem item,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
        side: BorderSide(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: InkWell(
        onTap: item.onTap,
        borderRadius:
            BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color:
                      colorScheme.primaryContainer,
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Icon(
                  item.icon,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              const Spacer(),
              Text(
                item.title,
                maxLines: 2,
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.subtitle,
                maxLines: 3,
                overflow:
                    TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.25,
                  color:
                      colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRulesCard(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme
          .surfaceContainerHighest
          .withValues(alpha: 0.45),
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _isSwahili
                    ? 'M-Shop Owner anaangalia na kusimamia platform. Mauzo, stock, purchases, customers, suppliers na expenses za pharmacy hazitawekwa kwenye dashboard hii.'
                    : 'The M-Shop Owner manages the platform. Pharmacy sales, stock, purchases, customers, suppliers, and expenses are not shown on this dashboard.',
                style: TextStyle(
                  height: 1.4,
                  color:
                      colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openPharmacyOwners() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const PharmacyOwnersScreen(),
      ),
    );
  }

  void _openPharmacies() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const PharmaciesScreen(),
      ),
    );
  }

  void _openStaff() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const StaffOverviewScreen(),
      ),
    );
  }

  void _openSubscriptions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const SubscriptionsScreen(),
      ),
    );
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const MshopNotificationsScreen(),
      ),
    );
  }

  Future<void> _refreshDashboard() async {
    await Future<void>.delayed(
      const Duration(milliseconds: 300),
    );

    if (mounted) {
      setState(() {});
    }
  }

  void _openModule(String moduleName) {
    _showMessage(
      _isSwahili
          ? '$moduleName itaunganishwa hatua inayofuata.'
          : '$moduleName will be connected in the next step.',
    );
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          appController:
              widget.appController,
        ),
      ),
      (route) => false,
    );
  }
}

class _OwnerModuleItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OwnerModuleItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}