import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/app_controller.dart';
import '../../services/subscription_service.dart';
import '../pharmacy/pharmacy_dashboard.dart';
import 'payment_contact_screen.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  final AppController appController;

  const SubscriptionPlansScreen({
    super.key,
    required this.appController,
  });

  @override
  State<SubscriptionPlansScreen> createState() =>
      _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState
    extends State<SubscriptionPlansScreen> {
  static const int basicPrice = 15000;
  static const int standardPrice = 30000;
  static const int premiumPrice = 40000;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final SubscriptionService _subscriptionService =
      SubscriptionService.instance;

  int _selectedPlan = 0;

  bool _isLoadingSubscription = true;
  bool _trialUsed = false;
  bool _trialActive = false;
  bool _paidFlowUsed = false;
  DateTime? _trialStartDate;
  DateTime? _trialEndDate;

  bool _isStartingTrial = false;

  bool get _isSwahili =>
      widget.appController.isSwahili;

  String get _screenTitle =>
      _isSwahili ? 'Chagua Kifurushi' : 'Choose a Plan';

  String get _mainTitle => _isSwahili
      ? 'Chagua Jinsi ya Kuendelea'
      : 'Choose How to Continue';

  String get _mainDescription => _isSwahili
      ? 'Anza trial ya siku 7 au chagua subscription ya kulipia.'
      : 'Start your 7-day free trial or choose a paid subscription plan.';

  String get _summaryTitle =>
      _isSwahili ? 'Muhtasari wa Kifurushi' : 'Plan Summary';

  String get _planLabel =>
      _isSwahili ? 'Kifurushi' : 'Plan';

  String get _priceLabel =>
      _isSwahili ? 'Bei' : 'Price';

  String get _durationLabel =>
      _isSwahili ? 'Muda' : 'Duration';

  String get _startDateLabel =>
      _isSwahili ? 'Tarehe ya kuanza' : 'Start date';

  String get _endDateLabel =>
      _isSwahili ? 'Tarehe ya kuisha' : 'End date';

  String get _savingLabel =>
      _isSwahili ? 'Umeokoa' : 'You save';

  String get _basicDuration =>
      _isSwahili ? 'Mwezi 1' : '1 Month';

  String get _standardDuration =>
      _isSwahili ? 'Miezi 2' : '2 Months';

  String get _premiumDuration =>
      _isSwahili ? 'Miezi 3' : '3 Months';

  String get _basicDescription => _isSwahili
      ? 'Kwa matumizi ya mwezi mmoja'
      : 'For one month of use';

  String get _standardDescription => _isSwahili
      ? 'Kwa matumizi ya miezi miwili'
      : 'For two months of use';

  String get _premiumDescription => _isSwahili
      ? 'Miezi 3 kwa bei yenye punguzo'
      : '3 months at a discounted price';

  String get _premiumBadge =>
      _isSwahili ? 'PUNGUFU' : 'SAVE';

  @override
  void initState() {
    super.initState();
    _loadSubscriptionState();
  }

  Future<void> _loadSubscriptionState() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        if (!mounted) {
          return;
        }

        setState(() {
          _isLoadingSubscription = false;
        });

        return;
      }

      final pharmacySnapshot = await _firestore
          .collection('pharmacies')
          .doc(user.uid)
          .get();

      if (!pharmacySnapshot.exists) {
        if (!mounted) {
          return;
        }

        setState(() {
          _isLoadingSubscription = false;
        });

        return;
      }

      final data = pharmacySnapshot.data();

      if (data == null) {
        if (!mounted) {
          return;
        }

        setState(() {
          _isLoadingSubscription = false;
        });

        return;
      }

      final trialDays = _readInt(
        data['trialDays'],
      );

      final trialStart = _readDate(
        data['trialStartAt'],
      );

      final trialEnd = _readDate(
        data['trialEndAt'],
      );

      final subscriptionStatus =
          data['subscriptionStatus']
              ?.toString();

      final subscriptionPlan =
          data['subscriptionPlan']
              ?.toString()
              .trim();

      // ---------------------------------------------------------------
      // PAID FLOW HISTORY
      // ---------------------------------------------------------------
      // Once an owner has entered the paid subscription flow, the
      // free trial must never become available again on that account.
      //
      // We check both:
      // 1. Existing paid subscription data on the pharmacy document.
      // 2. Any subscription payment request belonging to this pharmacy.
      //
      // The second check is important when a payment is still PENDING.
      // ---------------------------------------------------------------

      bool hasPaidSubscription =
          subscriptionPlan != null &&
              subscriptionPlan.isNotEmpty;

      bool hasPaymentRequest = false;

      try {
        final paymentRequestSnapshot =
            await _firestore
                .collection(
                  'subscription_payment_requests',
                )
                .where(
                  'pharmacyId',
                  isEqualTo: user.uid,
                )
                .limit(1)
                .get();

        hasPaymentRequest =
            paymentRequestSnapshot.docs.isNotEmpty;
      } catch (_) {
        // Keep the normal trial check working if payment-request
        // history cannot be read. Existing subscription data is still
        // enough to block the trial for an already-paid account.
      }

      final paidFlowUsed =
          hasPaidSubscription ||
              hasPaymentRequest;

      final today = DateTime.now();

      final trialIsCurrentlyActive =
          subscriptionStatus ==
                  SubscriptionService.statusTrial &&
              trialEnd != null &&
              !today.isAfter(
                trialEnd,
              );

      final trialHasBeenUsed =
          trialDays > 0 ||
              trialStart != null ||
              trialEnd != null ||
              subscriptionStatus ==
                  SubscriptionService.statusTrial ||
              paidFlowUsed;

      if (!mounted) {
        return;
      }

      setState(() {
        _trialUsed = trialHasBeenUsed;
        _trialActive = trialIsCurrentlyActive;
        _paidFlowUsed = paidFlowUsed;
        _trialStartDate = trialStart;
        _trialEndDate = trialEnd;
        _isLoadingSubscription = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingSubscription = false;
      });

      _showMessage(
        _isSwahili
            ? 'Imeshindikana kusoma taarifa za subscription.'
            : 'Failed to load subscription information.',
      );
    }
  }

  int _readInt(dynamic value) {
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

  DateTime? _readDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }

  DateTime get _startDate {
    final now = DateTime.now();

    return DateTime(
      now.year,
      now.month,
      now.day,
    );
  }

  DateTime _addMonths(
    DateTime date,
    int months,
  ) {
    final year =
        date.year +
            ((date.month - 1 + months) ~/ 12);

    final month =
        ((date.month - 1 + months) % 12) + 1;

    final lastDayOfTargetMonth =
        DateTime(
          year,
          month + 1,
          0,
        ).day;

    final day =
        date.day > lastDayOfTargetMonth
            ? lastDayOfTargetMonth
            : date.day;

    return DateTime(
      year,
      month,
      day,
    );
  }

  DateTime _getEndDate(int months) {
    final futureDate = _addMonths(
      _startDate,
      months,
    );

    return futureDate.subtract(
      const Duration(days: 1),
    );
  }

  String _formatDate(DateTime date) {
    final day =
        date.day.toString().padLeft(2, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    final year =
        date.year.toString();

    return '$day/$month/$year';
  }

  String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match.group(1)},',
        );
  }

  String _getPlanName() {
    switch (_selectedPlan) {
      case 0:
        return 'Basic';

      case 1:
        return 'Standard';

      default:
        return 'Premium';
    }
  }

  int _getPrice() {
    switch (_selectedPlan) {
      case 0:
        return basicPrice;

      case 1:
        return standardPrice;

      default:
        return premiumPrice;
    }
  }

  int _getMonths() {
    switch (_selectedPlan) {
      case 0:
        return 1;

      case 1:
        return 2;

      default:
        return 3;
    }
  }

  int _getSaving() {
    switch (_selectedPlan) {
      case 0:
        return 0;

      case 1:
        return 0;

      default:
        return 5000;
    }
  }

  String _getSelectedDuration() {
    switch (_selectedPlan) {
      case 0:
        return _basicDuration;

      case 1:
        return _standardDuration;

      default:
        return _premiumDuration;
    }
  }

  Future<void> _startFreeTrial() async {
    if (_trialUsed) {
      _showMessage(
        _paidFlowUsed
            ? (_isSwahili
                ? 'Akaunti hii tayari imeingia kwenye subscription ya kulipia. Free Trial haipatikani tena.'
                : 'This account has already entered the paid subscription flow. The free trial is no longer available.')
            : (_isSwahili
                ? 'Trial yako ya siku 7 tayari imetumika.'
                : 'Your 7-day free trial has already been used.'),
      );

      return;
    }

    if (_isStartingTrial) {
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

    setState(() {
      _isStartingTrial = true;
    });

    try {
      await _subscriptionService.startTrial(
        pharmacyId: user.uid,
        trialDays:
            SubscriptionService.defaultTrialDays,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _trialUsed = true;
        _trialActive = true;
        _isStartingTrial = false;
        _trialStartDate = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
        );
        _trialEndDate =
            SubscriptionService.instance
                .calculateTrialEndDate(
          startDate: DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
          ),
          trialDays:
              SubscriptionService.defaultTrialDays,
        );
      });

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => PharmacyDashboard(
            appController:
                widget.appController,
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isStartingTrial = false;
      });

      _showMessage(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
      );
    }
  }

  void _continueToPayment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentContactScreen(
          appController:
              widget.appController,
          plan: _getPlanName(),
          price: _getPrice(),
          months: _getMonths(),
        ),
      ),
    );
  }

  void _showMessage(String message) {
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

  @override
  Widget build(BuildContext context) {
    final selectedMonths = _getMonths();

    final endDate = _getEndDate(
      selectedMonths,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_screenTitle),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoadingSubscription
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : ListView(
                padding:
                    const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  28,
                ),
                children: [
                  Text(
                    _mainTitle,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    _mainDescription,
                    style: TextStyle(
                      fontSize: 15,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 24),

                  _buildTrialSection(),

                  const SizedBox(height: 24),

                  Text(
                    _isSwahili
                        ? 'Subscription za Kulipia'
                        : 'Paid Subscription Plans',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 12),

                  RadioGroup<int>(
                    groupValue:
                        _selectedPlan,
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      setState(() {
                        _selectedPlan = value;
                      });
                    },
                    child: Column(
                      children: [
                        _buildPlanCard(
                          index: 0,
                          name: 'Basic',
                          duration:
                              _basicDuration,
                          price: basicPrice,
                          saving: 0,
                          icon:
                              Icons.calendar_month,
                          description:
                              _basicDescription,
                        ),

                        const SizedBox(
                          height: 14,
                        ),

                        _buildPlanCard(
                          index: 1,
                          name: 'Standard',
                          duration:
                              _standardDuration,
                          price:
                              standardPrice,
                          saving: 0,
                          icon: Icons
                              .calendar_view_month,
                          description:
                              _standardDescription,
                        ),

                        const SizedBox(
                          height: 14,
                        ),

                        _buildPlanCard(
                          index: 2,
                          name: 'Premium',
                          duration:
                              _premiumDuration,
                          price:
                              premiumPrice,
                          saving: 5000,
                          icon: Icons
                              .workspace_premium,
                          description:
                              _premiumDescription,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Container(
                    padding:
                        const EdgeInsets.all(16),
                    decoration:
                        BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outlineVariant,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          _summaryTitle,
                          style:
                              const TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(
                          height: 16,
                        ),

                        _summaryRow(
                          _planLabel,
                          'M-Shop ${_getPlanName()}',
                        ),

                        _summaryRow(
                          _priceLabel,
                          'TSh ${_formatAmount(_getPrice())}',
                        ),

                        _summaryRow(
                          _durationLabel,
                          _getSelectedDuration(),
                        ),

                        _summaryRow(
                          _startDateLabel,
                          _formatDate(
                            _startDate,
                          ),
                        ),

                        _summaryRow(
                          _endDateLabel,
                          _formatDate(
                            endDate,
                          ),
                        ),

                        if (_getSaving() >
                            0)
                          _summaryRow(
                            _savingLabel,
                            'TSh ${_formatAmount(_getSaving())}',
                            valueColor:
                                Colors.green,
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width:
                        double.infinity,
                    height: 54,
                    child:
                        ElevatedButton(
                      onPressed:
                          _continueToPayment,
                      child: Text(
                        _isSwahili
                            ? 'ENDELEA NA ${_getPlanName().toUpperCase()}'
                            : 'CONTINUE WITH ${_getPlanName().toUpperCase()}',
                        style:
                            const TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    _isSwahili
                        ? 'Baada ya malipo, M-Shop Owner atathibitisha malipo na ku-activate subscription yako.'
                        : 'After payment, the M-Shop Owner will confirm your payment and activate your subscription.',
                    textAlign:
                        TextAlign.center,
                    style:
                        const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTrialSection() {
    final colorScheme =
        Theme.of(context).colorScheme;

    if (_trialUsed) {
      return Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(22),
          side: BorderSide(
            color: _trialActive
                ? colorScheme.primary
                : colorScheme.outlineVariant,
            width: _trialActive ? 2 : 1,
          ),
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
                      color: _trialActive
                          ? colorScheme.primary
                          : colorScheme
                              .outlineVariant,
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                    ),
                    child: Icon(
                      _trialActive
                          ? Icons
                              .check_circle_outline
                          : Icons
                              .history_outlined,
                      color: _trialActive
                          ? colorScheme
                              .onPrimary
                          : colorScheme
                              .onSurfaceVariant,
                      size: 28,
                    ),
                  ),

                  const SizedBox(
                    width: 14,
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          _isSwahili
                              ? '7-Day Free Trial'
                              : '7-Day Free Trial',
                          style:
                              const TextStyle(
                            fontSize: 20,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),

                        const SizedBox(
                          height: 4,
                        ),

                        Text(
                          _trialActive
                              ? (_isSwahili
                                  ? 'Trial yako inaendelea.'
                                  : 'Your trial is currently active.')
                              : _paidFlowUsed
                                  ? (_isSwahili
                                      ? 'Akaunti hii tayari imeingia kwenye subscription ya kulipia. Free Trial haipatikani tena.'
                                      : 'This account has already entered the paid subscription flow. The free trial is no longer available.')
                                  : (_isSwahili
                                      ? 'Trial yako tayari imetumika.'
                                      : 'Your free trial has already been used.'),
                          style: TextStyle(
                            color: colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Container(
                padding:
                    const EdgeInsets.all(14),
                decoration:
                    BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child: Column(
                  children: [
                    _trialInfoRow(
                      _isSwahili
                          ? 'Tarehe ya kuanza'
                          : 'Start date',
                      _trialStartDate !=
                              null
                          ? _formatDate(
                              _trialStartDate!,
                            )
                          : '-',
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    _trialInfoRow(
                      _isSwahili
                          ? 'Tarehe ya kuisha'
                          : 'End date',
                      _trialEndDate != null
                          ? _formatDate(
                              _trialEndDate!,
                            )
                          : '-',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration:
                    BoxDecoration(
                  color: _trialActive
                      ? colorScheme.primary
                          .withValues(
                          alpha: 0.10,
                        )
                      : colorScheme
                          .surfaceContainerHighest,
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _trialActive
                          ? Icons.info_outline
                          : Icons.lock_outline,
                      color: _trialActive
                          ? colorScheme.primary
                          : colorScheme
                              .onSurfaceVariant,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: Text(
                        _trialActive
                            ? (_isSwahili
                                ? 'Baada ya trial kuisha, chagua paid subscription ili kuendelea kutumia Dashboard.'
                                : 'After the trial ends, choose a paid subscription to continue using the Dashboard.')
                            : _paidFlowUsed
                                ? (_isSwahili
                                    ? 'Akaunti hii tayari imeingia kwenye paid subscription. Trial ya bure haiwezi kuanzishwa tena.'
                                    : 'This account has already entered the paid subscription flow. The free trial cannot be started again.')
                                : (_isSwahili
                                    ? 'Trial ya bure haiwezi kuanzishwa tena kwenye account hii.'
                                    : 'The free trial cannot be started again on this account.'),
                        style:
                            TextStyle(
                          height: 1.4,
                          color: colorScheme
                              .onSurfaceVariant,
                        ),
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

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: const Color(0xFFB6F3D0),
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(22),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(14),
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
                    color: const Color(
                      0xFF197149,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),
                  child: const Icon(
                    Icons
                        .card_giftcard_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                ),

                const SizedBox(
                  width: 14,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      const Text(
                        '7-Day Free Trial',
                        style:
                            TextStyle(
                          fontSize: 20,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        _isSwahili
                            ? 'Tumia M-Shop bure kwa siku 7.'
                            : 'Try M-Shop free for 7 days.',
                        style:
                            const TextStyle(
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Text(
              _isSwahili
                  ? 'Pata access kamili ya Pharmacy Dashboard kwa siku 7. Baada ya trial kuisha, paid subscription itahitajika kuendelea.'
                  : 'Get full access to the Pharmacy Dashboard for 7 days. After the trial ends, a paid subscription is required to continue.',
              style:
                  const TextStyle(
                height: 1.4,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 14),

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              decoration:
                  BoxDecoration(
                color: Colors.white
                    .withValues(
                  alpha: 0.45,
                ),
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons
                        .calendar_today_outlined,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: Text(
                      _isSwahili
                          ? 'Muda: siku 7'
                          : 'Duration: 7 days',
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),
                  const Text(
                    'TSh 0',
                    style:
                        TextStyle(
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(
                    0xFF197149,
                  ),
                  foregroundColor:
                      Colors.white,
                  elevation: 0,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      28,
                    ),
                  ),
                ),
                onPressed:
                    _isStartingTrial
                        ? null
                        : _startFreeTrial,
                child:
                    _isStartingTrial
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color:
                                  Colors.white,
                            ),
                          )
                        : Text(
                            _isSwahili
                                ? 'ANZA TRIAL YA SIKU 7'
                                : 'START 7-DAY FREE TRIAL',
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _trialInfoRow(
    String title,
    String value,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard({
    required int index,
    required String name,
    required String duration,
    required int price,
    required int saving,
    required IconData icon,
    required String description,
  }) {
    final isSelected =
        _selectedPlan == index;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedPlan = index;
        });
      },
      borderRadius:
          BorderRadius.circular(18),
      child: AnimatedContainer(
        duration:
            const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.all(18),
        decoration:
            BoxDecoration(
          borderRadius:
              BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? Theme.of(context)
                    .colorScheme
                    .primary
                : Theme.of(context)
                    .colorScheme
                    .outlineVariant,
            width:
                isSelected ? 2 : 1,
          ),
          color: isSelected
              ? Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(
                    alpha: 0.06,
                  )
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration:
                  BoxDecoration(
                shape:
                    BoxShape.circle,
                color: isSelected
                    ? Theme.of(context)
                        .colorScheme
                        .primary
                    : Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? Colors.white
                    : Theme.of(context)
                        .colorScheme
                        .primary,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        name,
                        style:
                            const TextStyle(
                          fontSize: 19,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      if (name ==
                          'Premium') ...[
                        const SizedBox(
                          width: 8,
                        ),
                        Container(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration:
                              BoxDecoration(
                            color: Colors
                                .orange
                                .withValues(
                              alpha: 0.15,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              20,
                            ),
                          ),
                          child: Text(
                            _premiumBadge,
                            style:
                                const TextStyle(
                              fontSize: 10,
                              fontWeight:
                                  FontWeight
                                      .bold,
                              color:
                                  Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    duration,
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),

                  const SizedBox(
                    height: 3,
                  ),

                  Text(
                    description,
                    style:
                        const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  Text(
                    'TSh ${_formatAmount(price)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                      color: Theme.of(
                        context,
                      )
                          .colorScheme
                          .primary,
                    ),
                  ),

                  if (saving > 0)
                    Padding(
                      padding:
                          const EdgeInsets.only(
                        top: 4,
                      ),
                      child: Text(
                        _isSwahili
                            ? 'Unaokoa TSh ${_formatAmount(saving)}'
                            : 'You save TSh ${_formatAmount(saving)}',
                        style:
                            const TextStyle(
                          fontSize: 12,
                          color:
                              Colors.green,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            Radio<int>(
              value: index,
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(
    String title,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              title,
              style:
                  const TextStyle(
                color: Colors.grey,
              ),
            ),
          ),

          const SizedBox(width: 12),

          Flexible(
            child: Text(
              value,
              textAlign:
                  TextAlign.right,
              style: TextStyle(
                fontWeight:
                    FontWeight.w600,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}