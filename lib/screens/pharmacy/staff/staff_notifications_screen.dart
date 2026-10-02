import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../services/notifications/notification_service.dart';

class StaffNotificationsScreen extends StatefulWidget {
  const StaffNotificationsScreen({
    super.key,
  });

  @override
  State<StaffNotificationsScreen> createState() =>
      _StaffNotificationsScreenState();
}

class _StaffNotificationsScreenState
    extends State<StaffNotificationsScreen> {
  final NotificationService _notificationService =
      NotificationService.instance;

  bool _loading = true;

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _loading = true;
    });

    try {
      final notifications =
          await _notificationService.getMyUnreadNotifications();

      if (!mounted) {
        return;
      }

      setState(() {
        _notifications = notifications;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load notifications: $e',
          ),
        ),
      );
    }
  }

  Future<void> _openNotification(
    QueryDocumentSnapshot<Map<String, dynamic>> notification,
  ) async {
    final data = notification.data();

    await _notificationService.markAsRead(
      notification.id,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _notifications.removeWhere(
        (item) => item.id == notification.id,
      );
    });

    await _showNotificationDetails(data);
  }

  Future<void> _showNotificationDetails(
    Map<String, dynamic> data,
  ) async {
    final title =
        data['title']?.toString().trim().isNotEmpty == true
            ? data['title'].toString()
            : 'Notification';

    final message =
        data['message']?.toString().trim().isNotEmpty == true
            ? data['message'].toString()
            : '';

    final itemName =
        data['itemName']?.toString().trim().isNotEmpty == true
            ? data['itemName'].toString()
            : null;

    final status =
        data['status']?.toString().trim().isNotEmpty == true
            ? data['status'].toString()
            : null;

    final createdAt = data['createdAt'];

    String dateText = '';

    if (createdAt is Timestamp) {
      final date = createdAt.toDate();

      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();

      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');

      dateText = '$day/$month/$year • $hour:$minute';
    }

    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                _notificationIcon(
                  data['type']?.toString(),
                  status,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 15,
                  ),
                ),
                if (itemName != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Product / Item',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    itemName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (status != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (dateText.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Time',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateText,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  IconData _notificationIcon(
    String? type,
    String? status,
  ) {
    switch (type) {
      case 'sale_result':
        if (status == 'failed') {
          return Icons.error_outline_rounded;
        }

        return Icons.check_circle_outline_rounded;

      case 'low_stock':
        return Icons.warning_amber_rounded;

      case 'expiry':
        return Icons.event_busy_rounded;

      case 'product_added':
        return Icons.add_box_outlined;

      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color _notificationColor(
    String? type,
    String? status,
  ) {
    final scheme = Theme.of(context).colorScheme;

    switch (type) {
      case 'sale_result':
        if (status == 'failed') {
          return scheme.error;
        }

        return scheme.primary;

      case 'low_stock':
        return Colors.orange;

      case 'expiry':
        return Colors.red;

      case 'product_added':
        return Colors.green;

      default:
        return scheme.primary;
    }
  }

  String _formatDate(dynamic createdAt) {
    if (createdAt is! Timestamp) {
      return 'Pending time';
    }

    final date = createdAt.toDate();

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year • $hour:$minute';
  }

  Widget _buildNotificationCard(
    QueryDocumentSnapshot<Map<String, dynamic>> notification,
  ) {
    final data = notification.data();

    final type = data['type']?.toString();

    final title =
        data['title']?.toString().trim().isNotEmpty == true
            ? data['title'].toString()
            : 'Notification';

    final message =
        data['message']?.toString().trim().isNotEmpty == true
            ? data['message'].toString()
            : '';

    final itemName =
        data['itemName']?.toString().trim().isNotEmpty == true
            ? data['itemName'].toString()
            : null;

    final status =
        data['status']?.toString().trim().isNotEmpty == true
            ? data['status'].toString()
            : null;

    final color = _notificationColor(
      type,
      status,
    );

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openNotification(notification),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _notificationIcon(
                    type,
                    status,
                  ),
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                    if (itemName != null) ...[
                      const SizedBox(height: 7),
                      Text(
                        itemName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 7),
                    Text(
                      _formatDate(
                        data['createdAt'],
                      ),
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadNotifications,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: _notifications.isEmpty
                  ? ListView(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 120),
                        Center(
                          child: Icon(
                            Icons.notifications_none_rounded,
                            size: 64,
                          ),
                        ),
                        SizedBox(height: 16),
                        Center(
                          child: Text(
                            'Hakuna notifications mpya.',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 30,
                            ),
                            child: Text(
                              'Notifications unazofungua zitaondoka kwenye unread list.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        30,
                      ),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        return _buildNotificationCard(
                          _notifications[index],
                        );
                      },
                    ),
            ),
    );
  }
}