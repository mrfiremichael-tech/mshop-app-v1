import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../services/mshop_owner_notification_service.dart';

class MshopNotificationsScreen extends StatefulWidget {
  const MshopNotificationsScreen({super.key});

  @override
  State<MshopNotificationsScreen> createState() =>
      _MshopNotificationsScreenState();
}

class _MshopNotificationsScreenState
    extends State<MshopNotificationsScreen> {
  final MshopOwnerNotificationService _notificationService =
      MshopOwnerNotificationService.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          StreamBuilder<int>(
            stream: _notificationService.streamUnreadCount(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;

              if (unreadCount == 0) {
                return const SizedBox.shrink();
              }

              return TextButton(
                onPressed: _markAllAsRead,
                child: const Text('Mark all read'),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _notificationService.streamNotifications(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildErrorState(context);
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final documents = snapshot.data?.docs ?? [];

          if (documents.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: [
                  _buildSummaryCard(
                    context,
                    unreadCount: 0,
                  ),
                  const SizedBox(height: 22),
                  _buildEmptyState(context),
                ],
              ),
            );
          }

          final notifications = documents
              .map(_notificationFromDocument)
              .toList();

          final unread = notifications
              .where((notification) => !notification.isRead)
              .toList();

          final read = notifications
              .where((notification) => notification.isRead)
              .toList();

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                _buildSummaryCard(
                  context,
                  unreadCount: unread.length,
                ),
                const SizedBox(height: 22),
                if (unread.isNotEmpty) ...[
                  _buildSectionTitle(
                    context,
                    title: 'Unread',
                    count: unread.length,
                  ),
                  const SizedBox(height: 10),
                  ...unread.map(
                    (notification) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildNotificationCard(
                        context,
                        notification,
                      ),
                    ),
                  ),
                ],
                if (unread.isNotEmpty && read.isNotEmpty)
                  const SizedBox(height: 14),
                if (read.isNotEmpty) ...[
                  _buildSectionTitle(
                    context,
                    title: 'History',
                    count: read.length,
                  ),
                  const SizedBox(height: 10),
                  ...read.map(
                    (notification) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildNotificationCard(
                        context,
                        notification,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  _PlatformNotification _notificationFromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    return _PlatformNotification(
      id: document.id,
      type: data['type']?.toString() ?? '',
      title: data['title']?.toString() ?? 'M-Shop Notification',
      message: data['message']?.toString() ?? '',
      pharmacyName: data['pharmacyName']?.toString() ?? '',
      ownerName: data['ownerName']?.toString() ?? '',
      status: data['status']?.toString() ?? '',
      plan: data['plan']?.toString() ?? '',
      dateLabel: _formatDate(data['createdAt']),
      icon: _iconForType(data['type']?.toString() ?? ''),
      isRead: data['isRead'] == true,
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required int unreadCount,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.notifications_active_outlined,
                color: colorScheme.onPrimary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'M-Shop Notifications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    unreadCount == 0
                        ? 'No unread notifications.'
                        : '$unreadCount unread notification'
                            '${unreadCount == 1 ? '' : 's'}.',
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
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

  Widget _buildSectionTitle(
    BuildContext context, {
    required String title,
    required int count,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    _PlatformNotification notification,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    final backgroundColor = notification.isRead
        ? colorScheme.surface
        : colorScheme.primaryContainer.withValues(alpha: 0.45);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: InkWell(
        onTap: () => _openNotification(notification),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  notification.icon,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: notification.isRead
                                  ? FontWeight.w600
                                  : FontWeight.w800,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.message,
                      style: TextStyle(
                        height: 1.35,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      notification.dateLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 90),
      child: Column(
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 64,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          const Text(
            'No notifications yet.',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Important M-Shop platform notifications will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 54,
              color: colorScheme.error,
            ),
            const SizedBox(height: 14),
            const Text(
              'Unable to load notifications.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please refresh and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openNotification(
    _PlatformNotification notification,
  ) async {
    if (!notification.isRead) {
      try {
        await _notificationService.markAsRead(notification.id);
      } catch (_) {}
    }

    if (!mounted) {
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              8,
              20,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        notification.icon,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        notification.title,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  notification.message,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.45,
                  ),
                ),
                if (notification.pharmacyName.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Pharmacy: ${notification.pharmacyName}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (notification.ownerName.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Owner: ${notification.ownerName}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (notification.status.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Status: ${notification.status}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (notification.plan.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Plan: ${notification.plan}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Text(
                  notification.dateLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _markAllAsRead() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('mshop_notifications')
          .where('isRead', isEqualTo: false)
          .get();

      if (snapshot.docs.isEmpty) {
        return;
      }

      final batch = FirebaseFirestore.instance.batch();

      for (final document in snapshot.docs) {
        batch.update(
          document.reference,
          {
            'isRead': true,
            'readAt': FieldValue.serverTimestamp(),
          },
        );
      }

      await batch.commit();
    } catch (_) {}
  }

  Future<void> _refresh() async {
    await Future<void>.delayed(
      const Duration(milliseconds: 300),
    );

    if (mounted) {
      setState(() {});
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'pharmacy_created':
        return Icons.local_pharmacy_outlined;
      case 'pharmacy_status_changed':
        return Icons.storefront_outlined;
      case 'pharmacy_owner_created':
        return Icons.person_add_alt_1_outlined;
      case 'pharmacy_owner_status_changed':
        return Icons.manage_accounts_outlined;
      case 'subscription_updated':
        return Icons.card_membership_outlined;
      case 'subscription_expiring':
        return Icons.schedule_outlined;
      case 'subscription_expired':
        return Icons.event_busy_outlined;
      case 'staff_created':
        return Icons.badge_outlined;
      case 'platform_information':
        return Icons.info_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _formatDate(dynamic value) {
    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    }

    if (date == null) {
      return 'Just now';
    }

    final local = date.toLocal();

    String twoDigits(int value) => value.toString().padLeft(2, '0');

    return '${twoDigits(local.day)}/${twoDigits(local.month)}/'
        '${local.year} ${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }
}

class _PlatformNotification {
  final String id;
  final String type;
  final String title;
  final String message;
  final String pharmacyName;
  final String ownerName;
  final String status;
  final String plan;
  final String dateLabel;
  final IconData icon;
  final bool isRead;

  const _PlatformNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.pharmacyName,
    required this.ownerName,
    required this.status,
    required this.plan,
    required this.dateLabel,
    required this.icon,
    required this.isRead,
  });
}