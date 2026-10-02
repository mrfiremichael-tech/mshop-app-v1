import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../services/subscription_service.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() =>
      _SubscriptionsScreenState();
}

class _SubscriptionsScreenState
    extends State<SubscriptionsScreen> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final SubscriptionService _subscriptionService =
      SubscriptionService.instance;

  String _searchQuery = '';

  static const List<String> _plans = <String>[
    'Basic',
    'Standard',
    'Premium',
  ];

  static const List<String> _statuses = <String>[
    'Pending',
    'Trial',
    'Active',
    'Expired',
    'Suspended',
    'Cancelled',
  ];

  String _readString(
    Map<String, dynamic> data,
    String key, {
    String fallback = 'Not Set',
  }) {
    final value = data[key];

    if (value is String &&
        value.trim().isNotEmpty) {
      return value.trim();
    }

    return fallback;
  }

  int _readInt(
    dynamic value,
  ) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  DateTime? _readDate(
    dynamic value,
  ) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String &&
        value.trim().isNotEmpty) {
      return DateTime.tryParse(
        value.trim(),
      );
    }

    return null;
  }

  bool _isActive(
    String status,
  ) {
    final normalized =
        status.trim().toLowerCase();

    return normalized == 'active' ||
        normalized == 'trial';
  }

  String _formatDate(
    DateTime? date,
  ) {
    if (date == null) {
      return 'Not Set';
    }

    final day =
        date.day.toString().padLeft(
              2,
              '0',
            );

    final month =
        date.month.toString().padLeft(
              2,
              '0',
            );

    return '$day/$month/${date.year}';
  }

  String _formatDateTime(
    DateTime? date,
  ) {
    if (date == null) {
      return 'Not Set';
    }

    final day =
        date.day.toString().padLeft(
              2,
              '0',
            );

    final month =
        date.month.toString().padLeft(
              2,
              '0',
            );

    final hour =
        date.hour.toString().padLeft(
              2,
              '0',
            );

    final minute =
        date.minute.toString().padLeft(
              2,
              '0',
            );

    return '$day/$month/${date.year} '
        '$hour:$minute';
  }

  String _formatAmount(
    int amount,
  ) {
    return amount.toString().replaceAllMapped(
          RegExp(
            r'(\d)(?=(\d{3})+(?!\d))',
          ),
          (match) =>
              '${match.group(1)},',
        );
  }

  Future<void> _refresh() async {
    await Future<void>.delayed(
      const Duration(
        milliseconds: 300,
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  Future<String> _getMshopOwnerName() async {
    final user = _auth.currentUser;

    final displayName =
        user?.displayName?.trim();

    if (displayName != null &&
        displayName.isNotEmpty) {
      return displayName;
    }

    return 'M-Shop Owner';
  }

  Future<void> _verifyPaymentRequest(
    PaymentRequestItem item,
  ) async {
    final data = item.data;

    final currentStatus =
        _readString(
      data,
      'status',
      fallback: 'pending',
    ).toLowerCase();

    if (currentStatus != 'pending') {
      _showMessage(
        'This payment request has already been processed.',
      );

      return;
    }

    final pharmacyId =
        _readString(
      data,
      'pharmacyId',
      fallback: '',
    );

    final plan =
        _readString(
      data,
      'plan',
      fallback: '',
    );

    final price =
        _readInt(
      data['price'],
    );

    final transactionReference =
        _readString(
      data,
      'transactionReference',
      fallback: 'Not Set',
    );

    if (pharmacyId.isEmpty) {
      _showMessage(
        'Pharmacy ID is missing.',
      );

      return;
    }

    if (!_plans.contains(plan)) {
      _showMessage(
        'Invalid subscription plan.',
      );

      return;
    }

    final expectedPrice =
        _subscriptionService
            .priceForPlan(plan);

    if (price != expectedPrice) {
      _showMessage(
        'Payment amount does not match the selected plan.',
      );

      return;
    }

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Verify Payment',
          ),
          content: Column(
            mainAxisSize:
                MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Pharmacy: ${_readString(
                  data,
                  'pharmacyName',
                  fallback: 'Unknown Pharmacy',
                )}',
              ),
              const SizedBox(
                height: 6,
              ),
              Text(
                'Owner: ${_readString(
                  data,
                  'ownerName',
                  fallback: 'Unknown Owner',
                )}',
              ),
              const SizedBox(
                height: 6,
              ),
              Text(
                'Plan: $plan',
              ),
              const SizedBox(
                height: 6,
              ),
              Text(
                'Amount: TSh ${_formatAmount(price)}',
              ),
              const SizedBox(
                height: 6,
              ),
              Text(
                'Payment: ${_readString(
                  data,
                  'paymentMethod',
                  fallback: 'Not Set',
                )}',
              ),
              const SizedBox(
                height: 6,
              ),
              Text(
                'Transaction: $transactionReference',
              ),
              const SizedBox(
                height: 16,
              ),
              const Text(
                'Confirm that the payment has been verified before activating the subscription.',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child: const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              child: const Text(
                'Verify & Activate',
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
      _showLoadingDialog(
        'Activating subscription...',
      );

      await _subscriptionService.activateSubscription(
        pharmacyId: pharmacyId,
        plan: plan,
      );

      final ownerName =
          await _getMshopOwnerName();

      await _firestore
          .collection(
            'subscription_payment_requests',
          )
          .doc(item.id)
          .update({
        'status': 'verified',
        'verifiedAt':
            FieldValue.serverTimestamp(),
        'verifiedByUid':
            _auth.currentUser?.uid,
        'verifiedByName':
            ownerName,
        'updatedAt':
            FieldValue.serverTimestamp(),
      });

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();

      _showSuccessMessage(
        'Payment verified and subscription activated successfully.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();

      _showMessage(
        'Failed to activate subscription: $error',
      );
    }
  }

  Future<void> _rejectPaymentRequest(
    PaymentRequestItem item,
  ) async {
    final data = item.data;

    final currentStatus =
        _readString(
      data,
      'status',
      fallback: 'pending',
    ).toLowerCase();

    if (currentStatus != 'pending') {
      _showMessage(
        'This payment request has already been processed.',
      );

      return;
    }

    final reasonController =
        TextEditingController();

    final rejected =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Reject Payment',
          ),
          content: Column(
            mainAxisSize:
                MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                _readString(
                  data,
                  'pharmacyName',
                  fallback: 'Unknown Pharmacy',
                ),
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
              const SizedBox(
                height: 6,
              ),
              Text(
                'Transaction: ${_readString(
                  data,
                  'transactionReference',
                  fallback: 'Not Set',
                )}',
              ),
              const SizedBox(
                height: 18,
              ),
              TextField(
                controller:
                    reasonController,
                maxLines: 3,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Reason for rejection',
                  hintText:
                      'Optional',
                  border:
                      OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child: const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    Colors.red,
              ),
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              child: const Text(
                'Reject Payment',
              ),
            ),
          ],
        );
      },
    );

    final reason =
        reasonController.text.trim();

    reasonController.dispose();

    if (rejected != true) {
      return;
    }

    try {
      final ownerName =
          await _getMshopOwnerName();

      await _firestore
          .collection(
            'subscription_payment_requests',
          )
          .doc(item.id)
          .update({
        'status': 'rejected',
        'verifiedAt':
            FieldValue.serverTimestamp(),
        'verifiedByUid':
            _auth.currentUser?.uid,
        'verifiedByName':
            ownerName,
        'rejectionReason':
            reason.isEmpty
                ? 'Payment was not verified.'
                : reason,
        'updatedAt':
            FieldValue.serverTimestamp(),
      });

      _showSuccessMessage(
        'Payment request rejected.',
      );
    } catch (error) {
      _showMessage(
        'Failed to reject payment request: $error',
      );
    }
  }

  void _showLoadingDialog(
    String message,
  ) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(
                width: 16,
              ),
              Expanded(
                child: Text(message),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
  }

  void _showSuccessMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _openManage(
    SubscriptionItem item,
  ) async {
    final updated =
        await showDialog<bool>(
      context: context,
      builder: (_) {
        return ManageSubscriptionDialog(
          item: item,
          plans: _plans,
          statuses: _statuses,
          subscriptionService:
              _subscriptionService,
          formatDate:
              _formatDate,
          formatAmount:
              _formatAmount,
        );
      },
    );

    if (!mounted ||
        updated != true) {
      return;
    }

    _showSuccessMessage(
      'Subscription updated successfully.',
    );
  }

  void _showDetails(
    SubscriptionItem item,
  ) {
    final pharmacyName =
        _readString(
      item.data,
      'name',
      fallback: 'Unnamed Pharmacy',
    );

    final ownerName =
        _readString(
      item.data,
      'ownerName',
      fallback: 'Owner not set',
    );

    final plan =
        _readString(
      item.data,
      'subscriptionPlan',
    );

    final status =
        _readString(
      item.data,
      'subscriptionStatus',
    );

    final startDate =
        _formatDate(
      _readDate(
        item.data[
          'subscriptionStartAt'
        ],
      ),
    );

    final endDate =
        _formatDate(
      _readDate(
        item.data[
          'subscriptionEndAt'
        ],
      ),
    );

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              8,
              20,
              24,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  pharmacyName,
                  style:
                      const TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                const SizedBox(
                  height: 6,
                ),
                Text(ownerName),
                const SizedBox(
                  height: 20,
                ),
                _detailRow(
                  'Plan',
                  plan,
                ),
                _detailRow(
                  'Status',
                  status,
                ),
                _detailRow(
                  'Start',
                  startDate,
                ),
                _detailRow(
                  'End',
                  endDate,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRequestsSection() {
    return StreamBuilder<
        QuerySnapshot<
            Map<String, dynamic>>>(
      stream: _firestore
          .collection(
            'subscription_payment_requests',
          )
          .snapshots(),
      builder: (
        context,
        snapshot,
      ) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return Card(
            margin:
                const EdgeInsets.only(
              bottom: 16,
            ),
            child: Padding(
              padding:
                  const EdgeInsets.all(
                18,
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2.5,
                    ),
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  Text(
                    'Loading payment requests...',
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Card(
            margin:
                const EdgeInsets.only(
              bottom: 16,
            ),
            child: Padding(
              padding:
                  const EdgeInsets.all(
                18,
              ),
              child: Text(
                'Failed to load payment requests:\n${snapshot.error}',
                style:
                    const TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
          );
        }

        final documents =
            snapshot.data?.docs ?? [];

        final requests =
            documents.map(
          (doc) {
            return PaymentRequestItem(
              id: doc.id,
              data: doc.data(),
            );
          },
        ).toList();

        requests.sort(
          (
            PaymentRequestItem a,
            PaymentRequestItem b,
          ) {
            final aDate =
                _readDate(
              a.data['createdAt'],
            );

            final bDate =
                _readDate(
              b.data['createdAt'],
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

            return bDate.compareTo(
              aDate,
            );
          },
        );

        final pendingRequests =
            requests.where(
          (
            PaymentRequestItem item,
          ) {
            return _readString(
                  item.data,
                  'status',
                  fallback: 'pending',
                )
                    .toLowerCase() ==
                'pending';
          },
        ).toList();

        final verifiedRequests =
            requests.where(
          (
            PaymentRequestItem item,
          ) {
            return _readString(
                  item.data,
                  'status',
                  fallback: '',
                )
                    .toLowerCase() ==
                'verified';
          },
        ).length;

        final rejectedRequests =
            requests.where(
          (
            PaymentRequestItem item,
          ) {
            return _readString(
                  item.data,
                  'status',
                  fallback: '',
                )
                    .toLowerCase() ==
                'rejected';
          },
        ).length;

        return Column(
          children: [
            Card(
              margin:
                  const EdgeInsets.only(
                bottom: 12,
              ),
              elevation: 0,
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  18,
                ),
                side: BorderSide(
                  color: pendingRequests
                          .isNotEmpty
                      ? Theme.of(
                          context,
                        )
                          .colorScheme
                          .primary
                      : Theme.of(
                          context,
                        )
                          .colorScheme
                          .outlineVariant,
                ),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.all(
                  16,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration:
                          BoxDecoration(
                        color: Theme.of(
                          context,
                        )
                            .colorScheme
                            .primaryContainer,
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                      ),
                      child: Icon(
                        Icons
                            .receipt_long_outlined,
                        color: Theme.of(
                          context,
                        )
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
                            CrossAxisAlignment
                                .start,
                        children: [
                          const Text(
                            'Payment Requests',
                            style:
                                TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),
                          const SizedBox(
                            height: 4,
                          ),
                          Text(
                            pendingRequests
                                    .isEmpty
                                ? 'No pending payment requests'
                                : '${pendingRequests.length} payment request(s) waiting for verification',
                            style:
                                TextStyle(
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
                    if (pendingRequests
                        .isNotEmpty)
                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration:
                            BoxDecoration(
                          color: Theme.of(
                            context,
                          )
                              .colorScheme
                              .primary,
                          borderRadius:
                              BorderRadius
                                  .circular(
                            30,
                          ),
                        ),
                        child: Text(
                          pendingRequests
                              .length
                              .toString(),
                          style:
                              TextStyle(
                            color: Theme.of(
                              context,
                            )
                                .colorScheme
                                .onPrimary,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            if (requests.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _requestSummaryCard(
                        label: 'Pending',
                        value:
                            pendingRequests
                                .length,
                        icon:
                            Icons.pending_actions_outlined,
                      ),
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    Expanded(
                      child: _requestSummaryCard(
                        label: 'Verified',
                        value:
                            verifiedRequests,
                        icon:
                            Icons.verified_outlined,
                      ),
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    Expanded(
                      child: _requestSummaryCard(
                        label: 'Rejected',
                        value:
                            rejectedRequests,
                        icon:
                            Icons
                                .cancel_outlined,
                      ),
                    ),
                  ],
                ),
              ),

            if (requests.isEmpty)
              Card(
                margin:
                    const EdgeInsets.only(
                  bottom: 16,
                ),
                elevation: 0,
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    24,
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons
                              .inbox_outlined,
                          size: 42,
                          color: Theme.of(
                            context,
                          )
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        const Text(
                          'No payment requests yet.',
                          style:
                              TextStyle(
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            if (requests.isNotEmpty)
              ...requests.map(
                (
                  PaymentRequestItem item,
                ) {
                  return Padding(
                    padding:
                        const EdgeInsets.only(
                      bottom: 12,
                    ),
                    child:
                        _buildPaymentRequestCard(
                      item,
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Widget _requestSummaryCard({
    required String label,
    required int value,
    required IconData icon,
  }) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme
          .surfaceContainerHighest
          .withValues(
        alpha: 0.55,
      ),
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 19,
              color:
                  colorScheme.primary,
            ),
            const SizedBox(
              height: 5,
            ),
            Text(
              value.toString(),
              style:
                  const TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme
                    .onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRequestCard(
    PaymentRequestItem item,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    final data = item.data;

    final pharmacyName =
        _readString(
      data,
      'pharmacyName',
      fallback: 'Unknown Pharmacy',
    );

    final ownerName =
        _readString(
      data,
      'ownerName',
      fallback: 'Unknown Owner',
    );

    final plan =
        _readString(
      data,
      'plan',
      fallback: 'Not Set',
    );

    final paymentMethod =
        _readString(
      data,
      'paymentMethod',
      fallback: 'Not Set',
    );

    final transactionReference =
        _readString(
      data,
      'transactionReference',
      fallback: 'Not Set',
    );

    final status =
        _readString(
      data,
      'status',
      fallback: 'pending',
    );

    final price =
        _readInt(
      data['price'],
    );

    final months =
        _readInt(
      data['months'],
    );

    final createdAt =
        _readDate(
      data['createdAt'],
    );

    final statusNormalized =
        status.toLowerCase();

    final isPending =
        statusNormalized ==
            'pending';

    final isVerified =
        statusNormalized ==
            'verified';

    final isRejected =
        statusNormalized ==
            'rejected';

    Color statusColor;

    if (isVerified) {
      statusColor =
          Colors.green;
    } else if (isRejected) {
      statusColor =
          Colors.red;
    } else {
      statusColor =
          colorScheme.primary;
    }

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        side: BorderSide(
          color: isPending
              ? colorScheme.primary
              : colorScheme
                  .outlineVariant,
          width:
              isPending ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration:
                      BoxDecoration(
                    color: colorScheme
                        .primaryContainer,
                    borderRadius:
                        BorderRadius.circular(
                      13,
                    ),
                  ),
                  child: Icon(
                    Icons
                        .local_pharmacy_outlined,
                    color: colorScheme
                        .primary,
                  ),
                ),
                const SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        pharmacyName,
                        style:
                            const TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                      const SizedBox(
                        height: 3,
                      ),
                      Text(
                        ownerName,
                        style: TextStyle(
                          color: colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        statusColor
                            .withValues(
                      alpha: 0.10,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      30,
                    ),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style:
                        TextStyle(
                      color:
                          statusColor,
                      fontSize: 11,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 14,
            ),

            const Divider(),

            const SizedBox(
              height: 10,
            ),

            _requestInfoRow(
              icon: Icons
                  .card_membership_outlined,
              label: 'Plan',
              value: plan,
            ),

            const SizedBox(
              height: 8,
            ),

            _requestInfoRow(
              icon:
                  Icons.payments_outlined,
              label: 'Amount',
              value:
                  'TSh ${_formatAmount(price)}',
            ),

            const SizedBox(
              height: 8,
            ),

            _requestInfoRow(
              icon:
                  Icons.calendar_month_outlined,
              label: 'Duration',
              value: months == 1
                  ? '1 Month'
                  : '$months Months',
            ),

            const SizedBox(
              height: 8,
            ),

            _requestInfoRow(
              icon:
                  Icons.account_balance_wallet_outlined,
              label: 'Method',
              value:
                  paymentMethod,
            ),

            const SizedBox(
              height: 8,
            ),

            _requestInfoRow(
              icon: Icons
                  .confirmation_number_outlined,
              label: 'Transaction',
              value:
                  transactionReference,
            ),

            const SizedBox(
              height: 8,
            ),

            _requestInfoRow(
              icon:
                  Icons.access_time_outlined,
              label: 'Submitted',
              value:
                  _formatDateTime(
                createdAt,
              ),
            ),

            if (isRejected) ...[
              const SizedBox(
                height: 10,
              ),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(
                  12,
                ),
                decoration:
                    BoxDecoration(
                  color: Colors.red
                      .withValues(
                    alpha: 0.06,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
                child: Text(
                  'Reason: ${_readString(
                    data,
                    'rejectionReason',
                    fallback:
                        'Payment was not verified.',
                  )}',
                  style:
                      const TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
            ],

            if (isVerified) ...[
              const SizedBox(
                height: 10,
              ),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(
                  12,
                ),
                decoration:
                    BoxDecoration(
                  color: Colors.green
                      .withValues(
                    alpha: 0.06,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
                child: Text(
                  'Verified by ${_readString(
                    data,
                    'verifiedByName',
                    fallback:
                        'M-Shop Owner',
                  )}',
                  style:
                      const TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
            ],

            if (isPending) ...[
              const SizedBox(
                height: 16,
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          () =>
                              _rejectPaymentRequest(
                        item,
                      ),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.red,
                      ),
                      label:
                          const Text(
                        'Reject',
                        style:
                            TextStyle(
                          color: Colors.red,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed:
                          () =>
                              _verifyPaymentRequest(
                        item,
                      ),
                      icon: const Icon(
                        Icons
                            .verified_rounded,
                      ),
                      label:
                          const Text(
                        'Verify & Activate',
                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _requestInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: colorScheme.primary,
        ),
        const SizedBox(
          width: 10,
        ),
        SizedBox(
          width: 82,
          child: Text(
            label,
            style: TextStyle(
              color: colorScheme
                  .onSurfaceVariant,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            overflow:
                TextOverflow.ellipsis,
            maxLines: 2,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Subscriptions'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding:
              const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            30,
          ),
          children: [
            // ============================================================
            // PAYMENT REQUESTS - LIVE
            // ============================================================
            _buildPaymentRequestsSection(),

            const SizedBox(
              height: 10,
            ),

            // ============================================================
            // SUBSCRIPTIONS
            // ============================================================
            StreamBuilder<
                QuerySnapshot<
                    Map<String, dynamic>>>(
              stream: _firestore
                  .collection('pharmacies')
                  .snapshots(),
              builder: (
                context,
                snapshot,
              ) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Padding(
                    padding:
                        EdgeInsets.only(
                      top: 40,
                    ),
                    child: Center(
                      child:
                          CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding:
                          const EdgeInsets
                              .all(24),
                      child: Text(
                        'Failed to load subscriptions:\n${snapshot.error}',
                        textAlign:
                            TextAlign.center,
                      ),
                    ),
                  );
                }

                final docs =
                    snapshot.data?.docs ??
                        <QueryDocumentSnapshot<
                            Map<String,
                                dynamic>>>[];

                final items =
                    docs.map(
                  (doc) {
                    return SubscriptionItem(
                      id: doc.id,
                      data: doc.data(),
                    );
                  },
                ).toList();

                final query =
                    _searchQuery
                        .trim()
                        .toLowerCase();

                final filtered =
                    items.where(
                  (
                    SubscriptionItem item,
                  ) {
                    if (query.isEmpty) {
                      return true;
                    }

                    final name =
                        _readString(
                      item.data,
                      'name',
                      fallback: '',
                    ).toLowerCase();

                    final owner =
                        _readString(
                      item.data,
                      'ownerName',
                      fallback: '',
                    ).toLowerCase();

                    final plan =
                        _readString(
                      item.data,
                      'subscriptionPlan',
                      fallback: '',
                    ).toLowerCase();

                    final status =
                        _readString(
                      item.data,
                      'subscriptionStatus',
                      fallback: '',
                    ).toLowerCase();

                    return name
                            .contains(
                          query,
                        ) ||
                        owner.contains(
                          query,
                        ) ||
                        plan.contains(
                          query,
                        ) ||
                        status.contains(
                          query,
                        );
                  },
                ).toList();

                final activeCount =
                    items.where(
                  (
                    SubscriptionItem item,
                  ) {
                    return _isActive(
                      _readString(
                        item.data,
                        'subscriptionStatus',
                      ),
                    );
                  },
                ).length;

                final inactiveCount =
                    items.length -
                        activeCount;

                return Column(
                  children: [
                    _buildSectionHeader(
                      title:
                          'Subscriptions',
                      subtitle:
                          'Manage pharmacy subscription access',
                      icon: Icons
                          .card_membership_outlined,
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    _buildSummary(
                      total:
                          items.length,
                      active:
                          activeCount,
                      inactive:
                          inactiveCount,
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    TextField(
                      onChanged:
                          (String value) {
                        setState(() {
                          _searchQuery =
                              value;
                        });
                      },
                      decoration:
                          InputDecoration(
                        hintText:
                            'Search pharmacy, owner, plan or status...',
                        prefixIcon:
                            const Icon(
                          Icons
                              .search_rounded,
                        ),
                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            14,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    if (filtered.isEmpty)
                      const Padding(
                        padding:
                            EdgeInsets.only(
                          top: 50,
                        ),
                        child: Center(
                          child: Text(
                            'No subscriptions found',
                            style:
                                TextStyle(
                              fontSize: 17,
                              fontWeight:
                                  FontWeight
                                      .w700,
                            ),
                          ),
                        ),
                      )
                    else
                      ...filtered.map(
                        (
                          SubscriptionItem item,
                        ) {
                          return Padding(
                            padding:
                                const EdgeInsets
                                    .only(
                              bottom: 12,
                            ),
                            child:
                                _buildSubscriptionCard(
                              item,
                            ),
                          );
                        },
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color:
          colorScheme.primaryContainer,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          18,
        ),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration:
                  BoxDecoration(
                color:
                    colorScheme.primary,
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),
              child: Icon(
                icon,
                color:
                    colorScheme.onPrimary,
              ),
            ),
            const SizedBox(
              width: 12,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    title,
                    style:
                        const TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    subtitle,
                    style:
                        TextStyle(
                      color: colorScheme
                          .onPrimaryContainer,
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

  Widget _buildSummary({
    required int total,
    required int active,
    required int inactive,
  }) {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            icon:
                Icons
                    .card_membership_outlined,
            value:
                total.toString(),
            label: 'Total',
          ),
        ),
        const SizedBox(
          width: 10,
        ),
        Expanded(
          child: _summaryCard(
            icon:
                Icons
                    .check_circle_outline_rounded,
            value:
                active.toString(),
            label: 'Active',
          ),
        ),
        const SizedBox(
          width: 10,
        ),
        Expanded(
          child: _summaryCard(
            icon:
                Icons
                    .pause_circle_outline_rounded,
            value:
                inactive.toString(),
            label: 'Inactive',
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme
          .surfaceContainerHighest
          .withValues(
        alpha: 0.55,
      ),
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          16,
        ),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .start,
          children: [
            Icon(
              icon,
              color:
                  colorScheme.primary,
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              value,
              style:
                  const TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
            Text(
              label,
              style:
                  TextStyle(
                color: colorScheme
                    .onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard(
    SubscriptionItem item,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    final pharmacyName =
        _readString(
      item.data,
      'name',
      fallback: 'Unnamed Pharmacy',
    );

    final ownerName =
        _readString(
      item.data,
      'ownerName',
      fallback: 'Owner not set',
    );

    final plan =
        _readString(
      item.data,
      'subscriptionPlan',
      fallback: 'Not Set',
    );

    final status =
        _readString(
      item.data,
      'subscriptionStatus',
      fallback: 'Not Set',
    );

    final startDate =
        _formatDate(
      _readDate(
        item.data[
          'subscriptionStartAt'
        ],
      ),
    );

    final endDate =
        _formatDate(
      _readDate(
        item.data[
          'subscriptionEndAt'
        ],
      ),
    );

    final active =
        _isActive(status);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        side: BorderSide(
          color: colorScheme
              .outlineVariant,
        ),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration:
                      BoxDecoration(
                    color: colorScheme
                        .primaryContainer,
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                  child: Icon(
                    Icons
                        .local_pharmacy_outlined,
                    color: colorScheme
                        .primary,
                  ),
                ),
                const SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        pharmacyName,
                        style:
                            const TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                      const SizedBox(
                        height: 3,
                      ),
                      Text(
                        ownerName,
                        style:
                            TextStyle(
                          color: colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration:
                      BoxDecoration(
                    color: active
                        ? colorScheme
                            .primaryContainer
                        : colorScheme
                            .surfaceContainerHighest,
                    borderRadius:
                        BorderRadius.circular(
                      30,
                    ),
                  ),
                  child: Text(
                    status,
                    style:
                        TextStyle(
                      color: active
                          ? colorScheme
                              .onPrimaryContainer
                          : colorScheme
                              .onSurfaceVariant,
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 14,
            ),

            const Divider(),

            const SizedBox(
              height: 10,
            ),

            _infoRow(
              icon:
                  Icons.card_membership_outlined,
              label: 'Plan',
              value: plan,
            ),

            const SizedBox(
              height: 8,
            ),

            _infoRow(
              icon:
                  Icons.play_circle_outline_rounded,
              label: 'Start',
              value: startDate,
            ),

            const SizedBox(
              height: 8,
            ),

            _infoRow(
              icon:
                  Icons.event_outlined,
              label: 'End',
              value: endDate,
            ),

            const SizedBox(
              height: 16,
            ),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () {
                    _showDetails(item);
                  },
                  child:
                      const Text(
                    'View Details',
                  ),
                ),
                const SizedBox(
                  width: 8,
                ),
                FilledButton(
                  onPressed: () {
                    _openManage(item);
                  },
                  child:
                      const Text(
                    'Manage',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color:
              colorScheme.primary,
        ),
        const SizedBox(
          width: 10,
        ),
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: TextStyle(
              color: colorScheme
                  .onSurfaceVariant,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            overflow:
                TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// MANAGE SUBSCRIPTION DIALOG
// ============================================================================

class ManageSubscriptionDialog
    extends StatefulWidget {
  final SubscriptionItem item;
  final List<String> plans;
  final List<String> statuses;
  final SubscriptionService subscriptionService;
  final String Function(DateTime?)
      formatDate;
  final String Function(int)
      formatAmount;

  const ManageSubscriptionDialog({
    super.key,
    required this.item,
    required this.plans,
    required this.statuses,
    required this.subscriptionService,
    required this.formatDate,
    required this.formatAmount,
  });

  @override
  State<ManageSubscriptionDialog>
      createState() =>
          _ManageSubscriptionDialogState();
}

class _ManageSubscriptionDialogState
    extends State<ManageSubscriptionDialog> {
  late String _selectedPlan;
  late String _selectedStatus;

  bool _saving = false;
  String? _errorMessage;

  DateTime _today() {
    final now =
        DateTime.now();

    return DateTime(
      now.year,
      now.month,
      now.day,
    );
  }

  DateTime? _readDate(
    dynamic value,
  ) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String &&
        value.trim().isNotEmpty) {
      return DateTime.tryParse(
        value.trim(),
      );
    }

    return null;
  }

  String _readString(
    String key, {
    String fallback = 'Not Set',
  }) {
    final value =
        widget.item.data[key];

    if (value is String &&
        value.trim().isNotEmpty) {
      return value.trim();
    }

    return fallback;
  }

  @override
  void initState() {
    super.initState();

    _selectedPlan =
        _readString(
      'subscriptionPlan',
      fallback: 'Basic',
    );

    if (!widget.plans.contains(
      _selectedPlan,
    )) {
      _selectedPlan =
          'Basic';
    }

    _selectedStatus =
        _readString(
      'subscriptionStatus',
      fallback:
          SubscriptionService
              .statusPending,
    );

    if (!widget.statuses.contains(
      _selectedStatus,
    )) {
      _selectedStatus =
          SubscriptionService
              .statusPending;
    }
  }

  DateTime _previewStartDate() {
    final currentStatus =
        _readString(
      'subscriptionStatus',
      fallback:
          SubscriptionService
              .statusPending,
    );

    final currentEndDate =
        _readDate(
      widget.item.data[
        'subscriptionEndAt'
      ],
    );

    return widget
        .subscriptionService
        .nextSubscriptionStartDate(
      activationDate:
          _today(),
      currentEndDate:
          currentEndDate,
      currentStatus:
          currentStatus,
    );
  }

  DateTime _previewEndDate() {
    return widget
        .subscriptionService
        .calculateSubscriptionEndDate(
      startDate:
          _previewStartDate(),
      plan:
          _selectedPlan,
    );
  }

  bool _isEarlyRenewal() {
    final currentStatus =
        _readString(
      'subscriptionStatus',
      fallback:
          SubscriptionService
              .statusPending,
    );

    final currentEndDate =
        _readDate(
      widget.item.data[
        'subscriptionEndAt'
      ],
    );

    if (currentEndDate ==
        null) {
      return false;
    }

    return widget
            .subscriptionService
            .isSubscriptionActive(
              currentStatus,
            ) &&
        !currentEndDate.isBefore(
          _today(),
        );
  }

  Future<void> _save() async {
    if (_saving) {
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      if (_selectedStatus ==
          SubscriptionService
              .statusActive) {
        await widget
            .subscriptionService
            .activateSubscription(
          pharmacyId:
              widget.item.id,
          plan:
              _selectedPlan,
        );
      } else {
        await FirebaseFirestore
            .instance
            .collection(
              'pharmacies',
            )
            .doc(
              widget.item.id,
            )
            .update({
          'subscriptionStatus':
              _selectedStatus,
          'subscriptionUpdatedAt':
              FieldValue
                  .serverTimestamp(),
        });
      }

      if (!mounted) {
        return;
      }

      Navigator.of(
        context,
      ).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
        _errorMessage =
            error.toString();
      });
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final pharmacyName =
        _readString(
      'name',
      fallback:
          'Unnamed Pharmacy',
    );

    final currentEndDate =
        _readDate(
      widget.item.data[
        'subscriptionEndAt'
      ],
    );

    final previewStart =
        _previewStartDate();

    final previewEnd =
        _previewEndDate();

    final months =
        _selectedPlan ==
                'Basic'
            ? 1
            : _selectedPlan ==
                    'Standard'
                ? 2
                : 3;

    final price =
        _selectedPlan ==
                'Basic'
            ? 15000
            : _selectedPlan ==
                    'Standard'
                ? 30000
                : 40000;

    return AlertDialog(
      title: Text(
        'Manage $pharmacyName',
      ),
      content:
          SingleChildScrollView(
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            DropdownButtonFormField<
                String>(
              initialValue:
                  _selectedPlan,
              decoration:
                  const InputDecoration(
                labelText:
                    'Plan',
                prefixIcon:
                    Icon(
                  Icons
                      .card_membership_outlined,
                ),
                border:
                    OutlineInputBorder(),
              ),
              items: widget.plans
                  .map(
                (
                  String plan,
                ) {
                  return DropdownMenuItem<
                      String>(
                    value:
                        plan,
                    child:
                        Text(plan),
                  );
                },
              ).toList(),
              onChanged:
                  _saving
                      ? null
                      : (
                          String? value,
                        ) {
                          if (value ==
                              null) {
                            return;
                          }

                          setState(() {
                            _selectedPlan =
                                value;
                          });
                        },
            ),

            const SizedBox(
              height: 10,
            ),

            Align(
              alignment:
                  Alignment.centerLeft,
              child: Text(
                'Bei: TSh ${widget.formatAmount(price)}',
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            DropdownButtonFormField<
                String>(
              initialValue:
                  _selectedStatus,
              decoration:
                  const InputDecoration(
                labelText:
                    'Status',
                prefixIcon:
                    Icon(
                  Icons
                      .toggle_on_outlined,
                ),
                border:
                    OutlineInputBorder(),
              ),
              items:
                  widget.statuses
                      .map(
                (
                  String status,
                ) {
                  return DropdownMenuItem<
                      String>(
                    value:
                        status,
                    child:
                        Text(status),
                  );
                },
              ).toList(),
              onChanged:
                  _saving
                      ? null
                      : (
                          String? value,
                        ) {
                          if (value ==
                              null) {
                            return;
                          }

                          setState(() {
                            _selectedStatus =
                                value;
                          });
                        },
            ),

            const SizedBox(
              height: 18,
            ),

            Container(
              width:
                  double.infinity,
              padding:
                  const EdgeInsets.all(
                14,
              ),
              decoration:
                  BoxDecoration(
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
                color:
                    Theme.of(
                  context,
                )
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(
                      alpha: 0.55,
                    ),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  const Text(
                    'Subscription Period',
                    style:
                        TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  _previewRow(
                    'Muda',
                    months == 1
                        ? 'Mwezi 1'
                        : 'Miezi $months',
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  _previewRow(
                    'Start',
                    widget
                        .formatDate(
                      previewStart,
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  _previewRow(
                    'End',
                    widget
                        .formatDate(
                      previewEnd,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            if (_isEarlyRenewal() &&
                currentEndDate != null)
              Container(
                width:
                    double.infinity,
                padding:
                    const EdgeInsets.all(
                  12,
                ),
                decoration:
                    BoxDecoration(
                  color: Colors
                      .green
                      .withValues(
                    alpha: 0.08,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                  border: Border.all(
                    color: Colors
                        .green
                        .withValues(
                      alpha: 0.25,
                    ),
                  ),
                ),
                child: Text(
                  'Early renewal: ya sasa inaisha ${widget.formatDate(currentEndDate)}. Mpya itaanza ${widget.formatDate(previewStart)}.',
                  style:
                      const TextStyle(
                    fontSize: 12,
                    color:
                        Colors.green,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              )
            else
              const Text(
                'Subscription ikiwa imeisha, mpya itaanza siku ya activation.',
                style:
                    TextStyle(
                  fontSize: 12,
                  color:
                      Colors.grey,
                ),
              ),

            if (_errorMessage !=
                null) ...[
              const SizedBox(
                height: 12,
              ),
              Text(
                _errorMessage!,
                style:
                    const TextStyle(
                  color:
                      Colors.red,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving
              ? null
              : () {
                  Navigator.of(
                    context,
                  ).pop(false);
                },
          child:
              const Text('Cancel'),
        ),
        FilledButton(
          onPressed:
              _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Activate',
                ),
        ),
      ],
    );
  }

  Widget _previewRow(
    String label,
    String value,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style:
                const TextStyle(
              color: Colors.grey,
              fontWeight:
                  FontWeight.w600,
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

// ============================================================================
// MODELS
// ============================================================================

class SubscriptionItem {
  final String id;
  final Map<String, dynamic> data;

  const SubscriptionItem({
    required this.id,
    required this.data,
  });
}

class PaymentRequestItem {
  final String id;
  final Map<String, dynamic> data;

  const PaymentRequestItem({
    required this.id,
    required this.data,
  });
}