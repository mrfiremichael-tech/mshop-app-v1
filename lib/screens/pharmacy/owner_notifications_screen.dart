import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../services/notifications/notification_service.dart';

class OwnerNotificationsScreen extends StatefulWidget {
  final String pharmacyId;

  const OwnerNotificationsScreen({
    super.key,
    required this.pharmacyId,
  });

  @override
  State<OwnerNotificationsScreen> createState() =>
      _OwnerNotificationsScreenState();
}

class _OwnerNotificationsScreenState
    extends State<OwnerNotificationsScreen> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final NotificationService _notificationService =
      NotificationService.instance;

  bool _loading = true;
  bool _markingAllAsRead = false;

  List<QueryDocumentSnapshot<Map<String, dynamic>>>
      _notifications = [];

  AppLocalizations get _l10n =>
      AppLocalizations.of(context);

  String _t(
    String english,
    String swahili,
  ) {
    return _l10n.isSwahili ? swahili : english;
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _loadNotifications();
    });
  }

  Future<void> _loadNotifications() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final user = _auth.currentUser;

      if (user == null) {
        if (!mounted) {
          return;
        }

        setState(() {
          _notifications = [];
          _loading = false;
        });

        return;
      }

      final snapshot = await _firestore
          .collection('notifications')
          .where(
            'pharmacyId',
            isEqualTo: widget.pharmacyId,
          )
          .where(
            'recipientUid',
            isEqualTo: user.uid,
          )
          .get();

      final notifications = List<
          QueryDocumentSnapshot<
              Map<String, dynamic>>>.from(
        snapshot.docs,
      );

      notifications.sort(
        (a, b) {
          final aDate = _getTimestamp(
            a.data()['createdAt'],
          );

          final bDate = _getTimestamp(
            b.data()['createdAt'],
          );

          if (aDate == null &&
              bDate == null) {
            return 0;
          }

          if (aDate == null) {
            return 1;
          }

          if (bDate == null) {
            return -1;
          }

          return bDate.compareTo(aDate);
        },
      );

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
        _notifications = [];
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'Failed to load notifications: $e',
              'Imeshindwa kupakia notifications: $e',
            ),
          ),
        ),
      );
    }
  }

  Timestamp? _getTimestamp(dynamic value) {
    if (value is Timestamp) {
      return value;
    }

    return null;
  }

  int get _unreadCount {
    return _notifications
        .where(
          (notification) =>
              notification.data()['isRead'] != true,
        )
        .length;
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>>
      get _unreadNotifications {
    return _notifications
        .where(
          (notification) =>
              notification.data()['isRead'] != true,
        )
        .toList();
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>>
      get _readNotifications {
    return _notifications
        .where(
          (notification) =>
              notification.data()['isRead'] == true,
        )
        .toList();
  }

  Future<void> _openNotification(
    QueryDocumentSnapshot<Map<String, dynamic>>
        notification,
  ) async {
    final data = notification.data();

    final isRead = data['isRead'] == true;

    // Notification moja tu ndiyo inakuwa read
    // unapobofya notification yenyewe.
    if (!isRead) {
      try {
        await _notificationService.markAsRead(
          notification.id,
        );

        await _loadNotifications();
      } catch (_) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _t(
                'Failed to mark notification as read.',
                'Imeshindwa kuweka notification kuwa imesomwa.',
              ),
            ),
          ),
        );
      }
    }

    if (!mounted) {
      return;
    }

    await _showNotificationDetails(data);
  }

  Future<void> _markAllAsRead() async {
    final unread = _unreadNotifications;

    if (unread.isEmpty ||
        _markingAllAsRead) {
      return;
    }

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            _t(
              'Mark all as read?',
              'Soma zote?',
            ),
          ),
          content: Text(
            _t(
              'This will mark all $_unreadCount unread notifications as read.',
              'Hii itaweka notifications zote $_unreadCount ambazo hazijasomwa kuwa zimesomwa.',
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
              child: Text(
                _t(
                  'Mark all as read',
                  'Soma zote',
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

    if (!mounted) {
      return;
    }

    setState(() {
      _markingAllAsRead = true;
    });

    try {
      for (final notification in unread) {
        await _notificationService.markAsRead(
          notification.id,
        );
      }

      await _loadNotifications();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'All notifications have been marked as read.',
              'Notifications zote zimesomwa.',
            ),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'Failed to mark all notifications as read.',
              'Imeshindwa kusoma notifications zote.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _markingAllAsRead = false;
        });
      }
    }
  }

  Future<void> _showNotificationDetails(
    Map<String, dynamic> data,
  ) async {
    final title =
        data['title']?.toString().trim();

    final message =
        data['message']?.toString().trim();

    final staffName =
        data['performedByName']
            ?.toString()
            .trim();

    final itemName =
        data['itemName']
            ?.toString()
            .trim();

    final status =
        data['status']
            ?.toString()
            .trim();

    final type =
        data['type']
            ?.toString()
            .trim();

    final createdAt =
        _getTimestamp(
      data['createdAt'],
    );

    final titleText =
        title != null &&
                title.isNotEmpty
            ? title
            : _t(
                'Staff Activity',
                'Shughuli ya Staff',
              );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                _notificationIcon(
                  type,
                  status,
                ),
                color:
                    _notificationColor(
                  type,
                  status,
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Text(
                  titleText,
                ),
              ),
            ],
          ),
          content:
              SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                if (staffName != null &&
                    staffName.isNotEmpty) ...[
                  _detailLabel(
                    _t(
                      'Staff',
                      'Staff',
                    ),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    staffName,
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(
                    height: 14,
                  ),
                ],
                if (message != null &&
                    message.isNotEmpty) ...[
                  _detailLabel(
                    _t(
                      'Action',
                      'Alichofanya',
                    ),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    message,
                    style:
                        const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(
                    height: 14,
                  ),
                ],
                if (itemName != null &&
                    itemName.isNotEmpty) ...[
                  _detailLabel(
                    _t(
                      'Product / Item',
                      'Bidhaa / Item',
                    ),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    itemName,
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(
                    height: 14,
                  ),
                ],
                if (createdAt != null) ...[
                  _detailLabel(
                    _t(
                      'Date and Time',
                      'Tarehe na Muda',
                    ),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    _formatDateTime(
                      createdAt.toDate(),
                    ),
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(
                    height: 14,
                  ),
                ],
                if (status != null &&
                    status.isNotEmpty) ...[
                  _detailLabel(
                    _t(
                      'Status',
                      'Hali',
                    ),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    _formatStatus(
                      status,
                    ),
                    style: TextStyle(
                      fontWeight:
                          FontWeight.w700,
                      color:
                          _notificationColor(
                        type,
                        status,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child: Text(
                _t(
                  'Close',
                  'Funga',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _detailLabel(
    String text,
  ) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: Theme.of(context)
            .colorScheme
            .onSurfaceVariant,
      ),
    );
  }

  String _formatDateTime(
    DateTime date,
  ) {
    final day = date.day
        .toString()
        .padLeft(2, '0');

    final month = date.month
        .toString()
        .padLeft(2, '0');

    final hour = date.hour
        .toString()
        .padLeft(2, '0');

    final minute = date.minute
        .toString()
        .padLeft(2, '0');

    return '$day/$month/${date.year} • $hour:$minute';
  }

  String _formatStatus(
    String status,
  ) {
    switch (status) {
      case 'success':
        return _t(
          'Completed successfully',
          'Imefanikiwa',
        );

      case 'failed':
        return _t(
          'Failed',
          'Imeshindikana',
        );

      default:
        return status;
    }
  }

  IconData _notificationIcon(
    String? type,
    String? status,
  ) {
    if (status == 'failed') {
      return Icons.error_outline_rounded;
    }

    switch (type) {
      case 'staff_sale':
        return Icons.point_of_sale_rounded;

      case 'staff_sale_failed':
        return Icons.error_outline_rounded;

      case 'staff_product_added':
        return Icons.medication_outlined;

      case 'staff_purchase':
        return Icons.add_shopping_cart_rounded;

      case 'staff_customer_added':
        return Icons.person_add_alt_1_rounded;

      case 'staff_supplier_added':
        return Icons.local_shipping_outlined;

      case 'staff_expense_added':
        return Icons.payments_outlined;

      case 'staff_stock_changed':
        return Icons.inventory_2_outlined;

      case 'staff_low_stock':
        return Icons.warning_amber_rounded;

      case 'staff_expiry':
        return Icons.event_busy_rounded;

      default:
        return Icons.notifications_rounded;
    }
  }

  Color _notificationColor(
    String? type,
    String? status,
  ) {
    if (status == 'failed') {
      return Theme.of(context)
          .colorScheme
          .error;
    }

    switch (type) {
      case 'staff_sale':
        return Theme.of(context)
            .colorScheme
            .primary;

      case 'staff_product_added':
        return Colors.green;

      case 'staff_low_stock':
        return Colors.orange;

      case 'staff_expiry':
        return Colors.red;

      default:
        return Theme.of(context)
            .colorScheme
            .primary;
    }
  }

  Widget _buildNotificationCard(
    QueryDocumentSnapshot<Map<String, dynamic>>
        notification,
  ) {
    final data = notification.data();

    final isRead =
        data['isRead'] == true;

    final type =
        data['type']?.toString();

    final title =
        data['title']?.toString().trim();

    final message =
        data['message']?.toString().trim();

    final staffName =
        data['performedByName']
            ?.toString()
            .trim();

    final itemName =
        data['itemName']
            ?.toString()
            .trim();

    final status =
        data['status']?.toString();

    final createdAt =
        _getTimestamp(
      data['createdAt'],
    );

    return Card(
      elevation: 0,
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child: InkWell(
        onTap: () =>
            _openNotification(
          notification,
        ),
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        child: Padding(
          padding:
              const EdgeInsets.all(15),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration:
                    BoxDecoration(
                  color:
                      _notificationColor(
                    type,
                    status,
                  ).withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child: Icon(
                  _notificationIcon(
                    type,
                    status,
                  ),
                  color:
                      _notificationColor(
                    type,
                    status,
                  ),
                ),
              ),
              const SizedBox(
                width: 13,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title != null &&
                                    title.isNotEmpty
                                ? title
                                : _t(
                                    'Staff Activity',
                                    'Shughuli ya Staff',
                                  ),
                            style:
                                TextStyle(
                              fontWeight:
                                  isRead
                                      ? FontWeight.w600
                                      : FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 9,
                            height: 9,
                            decoration:
                                BoxDecoration(
                              color:
                                  Theme.of(
                                context,
                              )
                                      .colorScheme
                                      .primary,
                              shape:
                                  BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    if (staffName !=
                            null &&
                        staffName.isNotEmpty) ...[
                      const SizedBox(
                        height: 5,
                      ),
                      Text(
                        staffName,
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    if (message !=
                            null &&
                        message.isNotEmpty) ...[
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        message,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(
                            context,
                          )
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (itemName !=
                            null &&
                        itemName.isNotEmpty) ...[
                      const SizedBox(
                        height: 5,
                      ),
                      Text(
                        itemName,
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (createdAt !=
                        null) ...[
                      const SizedBox(
                        height: 5,
                      ),
                      Text(
                        _formatDateTime(
                          createdAt.toDate(),
                        ),
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(
                            context,
                          )
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(
                width: 8,
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

  Widget _buildSection({
    required String title,
    required List<
            QueryDocumentSnapshot<
                Map<String, dynamic>>>
        notifications,
  }) {
    if (notifications.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style:
              const TextStyle(
            fontSize: 19,
            fontWeight:
                FontWeight.bold,
          ),
        ),
        const SizedBox(
          height: 12,
        ),
        for (final notification
            in notifications)
          _buildNotificationCard(
            notification,
          ),
      ],
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final unread =
        _unreadNotifications;

    final read =
        _readNotifications;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _t(
            'Notifications',
            'Notifications',
          ),
          style:
              const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton.icon(
              onPressed:
                  _markingAllAsRead
                      ? null
                      : _markAllAsRead,
              icon: _markingAllAsRead
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.done_all_rounded,
                    ),
              label: Text(
                _t(
                  'Mark all',
                  'Soma zote',
                ),
              ),
            ),
          IconButton(
            tooltip:
                _t(
              'Refresh',
              'Refresh',
            ),
            onPressed:
                _loadNotifications,
            icon:
                const Icon(
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
              onRefresh:
                  _loadNotifications,
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
                  if (_unreadCount >
                      0) ...[
                    Container(
                      padding:
                          const EdgeInsets.all(
                        16,
                      ),
                      decoration:
                          BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(
                          16,
                        ),
                        color: Theme.of(
                          context,
                        )
                            .colorScheme
                            .primary
                            .withValues(
                              alpha: 0.08,
                            ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons
                                .notifications_active_rounded,
                            color: Theme.of(
                              context,
                            )
                                .colorScheme
                                .primary,
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Expanded(
                            child: Text(
                              _t(
                                '$_unreadCount unread notification${_unreadCount == 1 ? '' : 's'}',
                                '$_unreadCount notifications ambazo hazijasomwa',
                              ),
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 22,
                    ),
                  ],
                  _buildSection(
                    title: _t(
                      'Unread',
                      'Hazijasomwa',
                    ),
                    notifications:
                        unread,
                  ),
                  if (unread.isNotEmpty &&
                      read.isNotEmpty)
                    const SizedBox(
                      height: 24,
                    ),
                  _buildSection(
                    title: _t(
                      'History',
                      'Historia',
                    ),
                    notifications:
                        read,
                  ),
                  if (unread.isEmpty &&
                      read.isEmpty)
                    Padding(
                      padding:
                          const EdgeInsets.only(
                        top: 100,
                      ),
                      child:
                          Column(
                        children: [
                          Icon(
                            Icons
                                .notifications_none_rounded,
                            size: 64,
                            color: Colors
                                .grey
                                .shade500,
                          ),
                          const SizedBox(
                            height: 16,
                          ),
                          Text(
                            _t(
                              'No notifications yet.',
                              'Hakuna notifications bado.',
                            ),
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(
                            height: 8,
                          ),
                          Text(
                            _t(
                              'Staff activities will appear here automatically.',
                              'Shughuli za Staff zitaonekana hapa moja kwa moja.',
                            ),
                            textAlign:
                                TextAlign.center,
                            style: TextStyle(
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
                ],
              ),
            ),
    );
  }
}