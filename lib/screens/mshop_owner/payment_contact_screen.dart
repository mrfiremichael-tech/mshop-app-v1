import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_controller.dart';

class PaymentContactScreen extends StatefulWidget {
  const PaymentContactScreen({
    super.key,
    required this.appController,
    required this.plan,
    required this.price,
    required this.months,
  });

  final AppController appController;
  final String plan;
  final int price;
  final int months;

  @override
  State<PaymentContactScreen> createState() =>
      _PaymentContactScreenState();
}

class _PaymentContactScreenState
    extends State<PaymentContactScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final TextEditingController _transactionController =
      TextEditingController();

  static const String mpesaNumber = '0747967671';
  static const String airtelNumber = '0685559830';
  static const String ownerName = 'Michael Omeme';
  static const String whatsappNumber = '0685559830';

  String _paymentMethod = 'M-Pesa';
  bool _isSubmitting = false;

  bool get _isSwahili =>
      widget.appController.isSwahili;

  String get _transactionLabel => _isSwahili
      ? 'Namba ya Muamala'
      : 'Transaction Reference';

  String get _transactionHint => _isSwahili
      ? 'Ingiza namba ya muamala uliyopewa baada ya malipo'
      : 'Enter the transaction reference you received after payment';

  String get _submitLabel => _isSwahili
      ? 'NIMETUMA MALIPO'
      : 'I HAVE PAID';

  String get _paymentMethodLabel => _isSwahili
      ? 'Njia ya Malipo'
      : 'Payment Method';

  @override
  void dispose() {
    _transactionController.dispose();
    super.dispose();
  }

  void _copyNumber(
    BuildContext context,
    String number,
    String label,
  ) {
    Clipboard.setData(
      ClipboardData(text: number),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$label number copied'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  String _formatAmount(int amount) {
    return 'TZS ${amount.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        )}';
  }

  String _durationText() {
    if (widget.months == 1) {
      return _isSwahili ? 'Mwezi 1' : '1 Month';
    }

    return _isSwahili
        ? 'Miezi ${widget.months}'
        : '${widget.months} Months';
  }

  Future<Map<String, dynamic>?> _getPharmacyData(
    String pharmacyId,
  ) async {
    final snapshot = await _firestore
        .collection('pharmacies')
        .doc(pharmacyId)
        .get();

    if (!snapshot.exists) {
      return null;
    }

    return snapshot.data();
  }

  Future<Map<String, dynamic>?> _getUserData(
    String uid,
  ) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .get();

    if (!snapshot.exists) {
      return null;
    }

    return snapshot.data();
  }

  Future<void> _submitPaymentRequest() async {
    FocusScope.of(context).unfocus();

    final transactionReference =
        _transactionController.text.trim();

    if (transactionReference.isEmpty) {
      _showMessage(
        _isSwahili
            ? 'Tafadhali ingiza namba ya muamala.'
            : 'Please enter the transaction reference.',
      );

      return;
    }

    if (transactionReference.length < 4) {
      _showMessage(
        _isSwahili
            ? 'Namba ya muamala si sahihi.'
            : 'The transaction reference is too short.',
      );

      return;
    }

    final user = _auth.currentUser;

    if (user == null) {
      _showMessage(
        _isSwahili
            ? 'Tafadhali ingia kwenye akaunti yako kwanza.'
            : 'Please log in first.',
      );

      return;
    }

    if (_isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final pharmacyData =
          await _getPharmacyData(user.uid);

      final userData =
          await _getUserData(user.uid);

      if (pharmacyData == null) {
        throw Exception(
          _isSwahili
              ? 'Taarifa za pharmacy hazijapatikana.'
              : 'Pharmacy information was not found.',
        );
      }

      final pharmacyName =
          pharmacyData['name']?.toString().trim() ??
              '';

      final ownerNameFromFirestore =
          userData?['fullName']
                  ?.toString()
                  .trim() ??
              user.displayName?.trim() ??
              '';

      final email =
          userData?['email']
                  ?.toString()
                  .trim() ??
              user.email?.trim() ??
              '';

      final phone =
          userData?['phone']
                  ?.toString()
                  .trim() ??
              pharmacyData['phone']
                  ?.toString()
                  .trim() ??
              '';

      final paymentRequestReference =
          _firestore
              .collection(
                'subscription_payment_requests',
              )
              .doc();

      await paymentRequestReference.set({
        'id': paymentRequestReference.id,

        'pharmacyId': user.uid,
        'ownerId': user.uid,

        'pharmacyName': pharmacyName,
        'ownerName': ownerNameFromFirestore,
        'email': email,
        'phone': phone,

        'plan': widget.plan,
        'price': widget.price,
        'months': widget.months,

        'paymentMethod': _paymentMethod,
        'transactionReference':
            transactionReference,

        'status': 'pending',

        'createdAt':
            FieldValue.serverTimestamp(),
        'updatedAt':
            FieldValue.serverTimestamp(),
      });

      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
      });

      await _showSuccessDialog(
        transactionReference,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
      });

      _showMessage(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
      );
    }
  }

  Future<void> _showSuccessDialog(
    String transactionReference,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final colorScheme =
            Theme.of(dialogContext).colorScheme;

        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _isSwahili
                      ? 'Ombi Limetumwa'
                      : 'Request Submitted',
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                _isSwahili
                    ? 'Ombi lako la subscription limepokelewa na linasubiri uthibitisho wa M-Shop Owner.'
                    : 'Your subscription payment request has been received and is waiting for M-Shop Owner verification.',
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme
                      .surfaceContainerHighest,
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isSwahili
                          ? 'Transaction Reference'
                          : 'Transaction Reference',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 5),
                    SelectableText(
                      transactionReference,
                      style: const TextStyle(
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isSwahili
                          ? 'Hali: Inasubiri uthibitisho'
                          : 'Status: Pending verification',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.w700,
                        color:
                            colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(
                _isSwahili
                    ? 'IMEELEWEKA'
                    : 'OK',
              ),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('M-Shop Payment'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          16,
          18,
          16,
          28,
        ),
        children: [
          Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            color: colorScheme.primaryContainer,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(22),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration:
                            BoxDecoration(
                          color:
                              colorScheme.primary,
                          borderRadius:
                              BorderRadius.circular(
                            16,
                          ),
                        ),
                        child: Icon(
                          Icons
                              .payments_outlined,
                          color: colorScheme
                              .onPrimary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'M-Shop Subscription Payment',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight:
                                FontWeight.w800,
                            color: colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _isSwahili
                        ? 'Fanya malipo kwa kutumia M-Pesa au Airtel Money, kisha ingiza namba ya muamala hapa chini.'
                        : 'Make payment using M-Pesa or Airtel Money, then enter the transaction reference below.',
                    style: TextStyle(
                      height: 1.4,
                      color: colorScheme
                          .onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(18),
              side: BorderSide(
                color: colorScheme
                    .outlineVariant,
              ),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    _isSwahili
                        ? 'Subscription uliyochagua'
                        : 'Selected Subscription',
                    style:
                        const TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.plan,
                          style:
                              const TextStyle(
                            fontSize: 22,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        _formatAmount(
                          widget.price,
                        ),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.w800,
                          color:
                              colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _durationText(),
                    style: TextStyle(
                      color: colorScheme
                          .onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          _buildPaymentCard(
            context,
            title: 'M-Pesa',
            number: mpesaNumber,
            owner: ownerName,
            icon:
                Icons.phone_android_rounded,
            onCopy: () => _copyNumber(
              context,
              mpesaNumber,
              'M-Pesa',
            ),
          ),

          const SizedBox(height: 12),

          _buildPaymentCard(
            context,
            title: 'Airtel Money',
            number: airtelNumber,
            owner: ownerName,
            icon:
                Icons.phone_android_rounded,
            onCopy: () => _copyNumber(
              context,
              airtelNumber,
              'Airtel Money',
            ),
          ),

          const SizedBox(height: 20),

          Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(18),
              side: BorderSide(
                color: colorScheme
                    .outlineVariant,
              ),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    _paymentMethodLabel,
                    style:
                        const TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<
                      String>(
                    initialValue:
                        _paymentMethod,
                    decoration:
                        InputDecoration(
                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'M-Pesa',
                        child:
                            Text('M-Pesa'),
                      ),
                      DropdownMenuItem(
                        value: 'Airtel Money',
                        child: Text(
                          'Airtel Money',
                        ),
                      ),
                    ],
                    onChanged: _isSubmitting
                        ? null
                        : (value) {
                            if (value ==
                                null) {
                              return;
                            }

                            setState(() {
                              _paymentMethod =
                                  value;
                            });
                          },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(18),
              side: BorderSide(
                color: colorScheme
                    .outlineVariant,
              ),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    _transactionLabel,
                    style:
                        const TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isSwahili
                        ? 'Baada ya kulipa, utaona namba ya muamala kwenye ujumbe wa mtandao wako.'
                        : 'After payment, you will receive the transaction reference from your mobile money provider.',
                    style: TextStyle(
                      height: 1.4,
                      color: colorScheme
                          .onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller:
                        _transactionController,
                    enabled:
                        !_isSubmitting,
                    textCapitalization:
                        TextCapitalization
                            .characters,
                    decoration:
                        InputDecoration(
                      labelText:
                          _transactionLabel,
                      hintText:
                          _transactionHint,
                      prefixIcon: const Icon(
                        Icons
                            .confirmation_number_outlined,
                      ),
                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting
                  ? null
                  : _submitPaymentRequest,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Icon(
                      Icons
                          .send_rounded,
                    ),
              label: Text(
                _isSubmitting
                    ? (_isSwahili
                        ? 'INATUMA...'
                        : 'SUBMITTING...')
                    : _submitLabel,
                style:
                    const TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            color: colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.55),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(18),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color:
                            colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _isSwahili
                              ? 'Ombi lako litabaki Pending mpaka M-Shop Owner athibitishe malipo. Subscription haitawashwa automatic.'
                              : 'Your request will remain Pending until the M-Shop Owner verifies the payment. The subscription will not be activated automatically.',
                          style: TextStyle(
                            height: 1.4,
                            color: colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.chat_outlined,
                        color:
                            colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _isSwahili
                              ? 'Unaweza pia kutuma uthibitisho kupitia WhatsApp: $whatsappNumber'
                              : 'You can also send payment proof through WhatsApp: $whatsappNumber',
                          style: TextStyle(
                            height: 1.4,
                            color: colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(
    BuildContext context, {
    required String title,
    required String number,
    required String owner,
    required IconData icon,
    required VoidCallback onCopy,
  }) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
        side: BorderSide(
          color:
              colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
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
                icon,
                color:
                    colorScheme.primary,
              ),
            ),
            const SizedBox(width: 14),
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
                      fontSize: 17,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    number,
                    style:
                        const TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    owner,
                    style: TextStyle(
                      color: colorScheme
                          .onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Copy',
              onPressed: onCopy,
              icon: const Icon(
                Icons.copy_outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }
}