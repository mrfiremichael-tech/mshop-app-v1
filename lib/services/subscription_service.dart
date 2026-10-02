import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionService {
  SubscriptionService._();

  static final SubscriptionService instance =
      SubscriptionService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // SUBSCRIPTION STATUSES
  // ============================================================

  static const String statusPending = 'Pending';
  static const String statusTrial = 'Trial';
  static const String statusActive = 'Active';
  static const String statusExpired = 'Expired';
  static const String statusSuspended = 'Suspended';
  static const String statusCancelled = 'Cancelled';
  static const String statusScheduled = 'Scheduled';

  // ============================================================
  // PHARMACY STATUSES
  // ============================================================

  static const String pharmacyStatusActive = 'active';
  static const String pharmacyStatusInactive = 'inactive';
  static const String pharmacyStatusPending =
      'pending_subscription';

  // ============================================================
  // PRICES
  // ============================================================

  static const int basicPrice = 15000;
  static const int standardPrice = 30000;
  static const int premiumPrice = 40000;

  static const int defaultTrialDays = 7;

  // ============================================================
  // CURRENT SUBSCRIPTION FIELDS
  // ============================================================

  static const String fieldStatus = 'status';

  static const String fieldSubscriptionStatus =
      'subscriptionStatus';

  static const String fieldSubscriptionPlan =
      'subscriptionPlan';

  static const String fieldSubscriptionStartAt =
      'subscriptionStartAt';

  static const String fieldSubscriptionEndAt =
      'subscriptionEndAt';

  static const String fieldSubscriptionUpdatedAt =
      'subscriptionUpdatedAt';

  // ============================================================
  // SCHEDULED RENEWAL FIELDS
  // ============================================================

  static const String fieldNextStatus =
      'nextSubscriptionStatus';

  static const String fieldNextPlan =
      'nextSubscriptionPlan';

  static const String fieldNextStartAt =
      'nextSubscriptionStartAt';

  static const String fieldNextEndAt =
      'nextSubscriptionEndAt';

  static const String fieldNextPrice =
      'nextSubscriptionPrice';

  static const String fieldNextMonths =
      'nextSubscriptionMonths';

  static const String fieldNextCreatedAt =
      'nextSubscriptionCreatedAt';

  // ============================================================
  // PLAN HELPERS
  // ============================================================

  int monthsForPlan(String plan) {
    switch (plan.trim().toLowerCase()) {
      case 'basic':
        return 1;

      case 'standard':
        return 2;

      case 'premium':
        return 3;

      default:
        throw ArgumentError(
          'Unknown subscription plan: $plan',
        );
    }
  }

  int priceForPlan(String plan) {
    switch (plan.trim().toLowerCase()) {
      case 'basic':
        return basicPrice;

      case 'standard':
        return standardPrice;

      case 'premium':
        return premiumPrice;

      default:
        throw ArgumentError(
          'Unknown subscription plan: $plan',
        );
    }
  }

  // ============================================================
  // STATUS HELPERS
  // ============================================================

  bool isSubscriptionActive(String? status) {
    final normalized =
        status?.trim().toLowerCase() ?? '';

    return normalized == 'active' ||
        normalized == 'trial';
  }

  bool isExpiredStatus(String? status) {
    return status?.trim().toLowerCase() ==
        'expired';
  }

  bool isScheduledStatus(String? status) {
    return status?.trim().toLowerCase() ==
        'scheduled';
  }

  // ============================================================
  // DATE HELPERS
  // ============================================================

  DateTime normalizeDate(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    );
  }

  DateTime addDays(
    DateTime date,
    int days,
  ) {
    return normalizeDate(date).add(
      Duration(days: days),
    );
  }

  DateTime addCalendarMonths(
    DateTime date,
    int months,
  ) {
    final normalized =
        normalizeDate(date);

    final year =
        normalized.year +
            ((normalized.month - 1 + months) ~/ 12);

    final month =
        ((normalized.month - 1 + months) % 12) + 1;

    final lastDay =
        DateTime(
          year,
          month + 1,
          0,
        ).day;

    final day =
        normalized.day > lastDay
            ? lastDay
            : normalized.day;

    return DateTime(
      year,
      month,
      day,
    );
  }

  DateTime calculateSubscriptionEndDate({
    required DateTime startDate,
    required String plan,
  }) {
    final months =
        monthsForPlan(plan);

    final nextPeriod =
        addCalendarMonths(
          startDate,
          months,
        );

    return nextPeriod.subtract(
      const Duration(days: 1),
    );
  }

  DateTime calculateTrialEndDate({
    required DateTime startDate,
    int trialDays = defaultTrialDays,
  }) {
    if (trialDays <= 0) {
      throw ArgumentError(
        'Trial days must be greater than 0.',
      );
    }

    return addDays(
      startDate,
      trialDays,
    ).subtract(
      const Duration(days: 1),
    );
  }

  // ============================================================
  // NEXT SUBSCRIPTION START
  // ============================================================

  DateTime nextSubscriptionStartDate({
    required DateTime activationDate,
    DateTime? currentEndDate,
    String? currentStatus,
  }) {
    final today =
        normalizeDate(activationDate);

    if (!isSubscriptionActive(
      currentStatus,
    )) {
      return today;
    }

    if (currentEndDate == null) {
      return today;
    }

    final normalizedEnd =
        normalizeDate(
      currentEndDate,
    );

    if (normalizedEnd.isBefore(today)) {
      return today;
    }

    return normalizedEnd.add(
      const Duration(days: 1),
    );
  }

  // ============================================================
  // GET SUBSCRIPTION
  // ============================================================

  Future<Map<String, dynamic>?>
      getPharmacySubscription(
    String pharmacyId,
  ) async {
    final snapshot =
        await _firestore
            .collection('pharmacies')
            .doc(pharmacyId)
            .get();

    if (!snapshot.exists) {
      return null;
    }

    return snapshot.data();
  }

  // ============================================================
  // START 7-DAY FREE TRIAL
  // ============================================================

  Future<Map<String, dynamic>>
      startTrial({
    required String pharmacyId,
    int trialDays = defaultTrialDays,
    DateTime? startDate,
  }) async {
    // M-Shop free trial must always be exactly 7 days.
    if (trialDays != defaultTrialDays) {
      throw ArgumentError(
        'M-Shop free trial must be exactly 7 days.',
      );
    }

    final pharmacyRef =
        _firestore
            .collection('pharmacies')
            .doc(pharmacyId);

    return _firestore.runTransaction<
        Map<String, dynamic>>(
      (transaction) async {
        final snapshot =
            await transaction.get(
          pharmacyRef,
        );

        if (!snapshot.exists) {
          throw Exception(
            'Pharmacy not found.',
          );
        }

        final data =
            snapshot.data() ??
                <String, dynamic>{};

        // ========================================================
        // CHECK THAT TRIAL HAS NOT ALREADY BEEN USED
        // ========================================================

        final currentSubscriptionStatus =
            data[
              fieldSubscriptionStatus
            ]?.toString().trim() ??
                'none';

        final currentTrialDays =
            data['trialDays'];

        final currentTrialStart =
            data['trialStartAt'];

        final currentTrialEnd =
            data['trialEndAt'];

        final trialAlreadyUsed =
            currentTrialDays is num &&
                currentTrialDays > 0;

        if (trialAlreadyUsed ||
            currentTrialStart != null ||
            currentTrialEnd != null ||
            currentSubscriptionStatus
                    .toLowerCase() !=
                'none') {
          throw Exception(
            'The 7-day free trial has already been used '
            'or subscription is already active.',
          );
        }

        // ========================================================
        // CALCULATE TRIAL DATES
        // ========================================================

        final start =
            normalizeDate(
          startDate ??
              DateTime.now(),
        );

        final end =
            calculateTrialEndDate(
          startDate: start,
          trialDays: trialDays,
        );

        final trialEndDateTime =
            DateTime(
          end.year,
          end.month,
          end.day,
          23,
          59,
          59,
        );

        // ========================================================
        // ACTIVATE TRIAL
        // ========================================================

        transaction.update(
          pharmacyRef,
          {
            fieldStatus:
                pharmacyStatusActive,

            fieldSubscriptionStatus:
                statusTrial,

            fieldSubscriptionPlan:
                '',

            fieldSubscriptionStartAt:
                Timestamp.fromDate(
              start,
            ),

            fieldSubscriptionEndAt:
                Timestamp.fromDate(
              trialEndDateTime,
            ),

            fieldSubscriptionUpdatedAt:
                FieldValue.serverTimestamp(),

            // ----------------------------------------------------
            // TRIAL INFORMATION
            // ----------------------------------------------------

            'trialDays':
                trialDays,

            'trialStartAt':
                Timestamp.fromDate(
              start,
            ),

            'trialEndAt':
                Timestamp.fromDate(
              trialEndDateTime,
            ),

            'updatedAt':
                FieldValue.serverTimestamp(),

            // ----------------------------------------------------
            // REMOVE ANY SCHEDULED SUBSCRIPTION
            // ----------------------------------------------------

            fieldNextStatus:
                FieldValue.delete(),

            fieldNextPlan:
                FieldValue.delete(),

            fieldNextStartAt:
                FieldValue.delete(),

            fieldNextEndAt:
                FieldValue.delete(),

            fieldNextPrice:
                FieldValue.delete(),

            fieldNextMonths:
                FieldValue.delete(),

            fieldNextCreatedAt:
                FieldValue.delete(),
          },
        );

        return {
          fieldStatus:
              pharmacyStatusActive,

          fieldSubscriptionStatus:
              statusTrial,

          fieldSubscriptionPlan:
              '',

          fieldSubscriptionStartAt:
              start,

          fieldSubscriptionEndAt:
              end,

          'trialDays':
              trialDays,

          'trialStartAt':
              start,

          'trialEndAt':
              end,
        };
      },
    );
  }

  // ============================================================
  // ACTIVATE SUBSCRIPTION OR SCHEDULE RENEWAL
  // ============================================================

  Future<Map<String, dynamic>>
      activateSubscription({
    required String pharmacyId,
    required String plan,
    DateTime? activationDate,
  }) async {
    final normalizedPlan =
        plan.trim();

    final months =
        monthsForPlan(
      normalizedPlan,
    );

    final price =
        priceForPlan(
      normalizedPlan,
    );

    final pharmacyRef =
        _firestore
            .collection('pharmacies')
            .doc(pharmacyId);

    return _firestore.runTransaction<
        Map<String, dynamic>>(
      (transaction) async {
        final snapshot =
            await transaction.get(
          pharmacyRef,
        );

        if (!snapshot.exists) {
          throw Exception(
            'Pharmacy not found.',
          );
        }

        final data =
            snapshot.data() ??
                <String, dynamic>{};

        final today =
            normalizeDate(
          activationDate ??
              DateTime.now(),
        );

        final currentStatus =
            data[
              fieldSubscriptionStatus
            ]?.toString();

        final currentEnd =
            readDate(
          data[
            fieldSubscriptionEndAt
          ],
        );

        // --------------------------------------------------------
        // CURRENT SUBSCRIPTION BADO INAENDELEA
        // --------------------------------------------------------

        if (isSubscriptionActive(
          currentStatus,
        )) {
          if (currentEnd != null) {
            final normalizedEnd =
                normalizeDate(
              currentEnd,
            );

            if (!normalizedEnd.isBefore(
              today,
            )) {
              final nextStart =
                  normalizedEnd.add(
                const Duration(days: 1),
              );

              final nextEnd =
                  calculateSubscriptionEndDate(
                startDate:
                    nextStart,
                plan:
                    normalizedPlan,
              );

              transaction.update(
                pharmacyRef,
                {
                  fieldStatus:
                      pharmacyStatusActive,

                  // CURRENT SUBSCRIPTION
                  fieldSubscriptionStatus:
                      currentStatus,

                  fieldSubscriptionUpdatedAt:
                      FieldValue.serverTimestamp(),

                  // NEXT SUBSCRIPTION
                  fieldNextStatus:
                      statusScheduled,

                  fieldNextPlan:
                      normalizedPlan,

                  fieldNextStartAt:
                      Timestamp.fromDate(
                    nextStart,
                  ),

                  fieldNextEndAt:
                      Timestamp.fromDate(
                    DateTime(
                      nextEnd.year,
                      nextEnd.month,
                      nextEnd.day,
                      23,
                      59,
                      59,
                    ),
                  ),

                  fieldNextPrice:
                      price,

                  fieldNextMonths:
                      months,

                  fieldNextCreatedAt:
                      FieldValue.serverTimestamp(),
                },
              );

              return {
                'scheduled':
                    true,

                'renewalFromExisting':
                    true,

                'subscriptionPlan':
                    normalizedPlan,

                'subscriptionPrice':
                    price,

                'subscriptionMonths':
                    months,

                'subscriptionStatus':
                    currentStatus,

                'pharmacyStatus':
                    pharmacyStatusActive,

                'currentSubscriptionEndAt':
                    normalizedEnd,

                'nextSubscriptionStatus':
                    statusScheduled,

                'nextSubscriptionPlan':
                    normalizedPlan,

                'nextSubscriptionStartAt':
                    nextStart,

                'nextSubscriptionEndAt':
                    nextEnd,
              };
            }
          }
        }

        // --------------------------------------------------------
        // CURRENT SUBSCRIPTION IMEISHA / HAKUNA
        // --------------------------------------------------------

        final startDate =
            today;

        final endDate =
            calculateSubscriptionEndDate(
          startDate:
              startDate,
          plan:
              normalizedPlan,
        );

        transaction.update(
          pharmacyRef,
          {
            fieldStatus:
                pharmacyStatusActive,

            fieldSubscriptionStatus:
                statusActive,

            fieldSubscriptionPlan:
                normalizedPlan,

            fieldSubscriptionStartAt:
                Timestamp.fromDate(
              startDate,
            ),

            fieldSubscriptionEndAt:
                Timestamp.fromDate(
              DateTime(
                endDate.year,
                endDate.month,
                endDate.day,
                23,
                59,
                59,
              ),
            ),

            fieldSubscriptionUpdatedAt:
                FieldValue.serverTimestamp(),

            // Ondoa scheduled renewal yoyote
            // iliyokuwa imebaki.
            fieldNextStatus:
                FieldValue.delete(),

            fieldNextPlan:
                FieldValue.delete(),

            fieldNextStartAt:
                FieldValue.delete(),

            fieldNextEndAt:
                FieldValue.delete(),

            fieldNextPrice:
                FieldValue.delete(),

            fieldNextMonths:
                FieldValue.delete(),

            fieldNextCreatedAt:
                FieldValue.delete(),
          },
        );

        return {
          'scheduled':
              false,

          'renewalFromExisting':
              false,

          'subscriptionPlan':
              normalizedPlan,

          'subscriptionPrice':
              price,

          'subscriptionMonths':
              months,

          'subscriptionStatus':
              statusActive,

          'pharmacyStatus':
              pharmacyStatusActive,

          'subscriptionStartAt':
              startDate,

          'subscriptionEndAt':
              endDate,
        };
      },
    );
  }

  // ============================================================
  // EXPIRE CURRENT SUBSCRIPTION
  // AND ACTIVATE SCHEDULED RENEWAL
  // ============================================================

  Future<bool>
      expireSubscriptionIfNeeded(
    String pharmacyId, {
    DateTime? checkDate,
  }) async {
    final pharmacyRef =
        _firestore
            .collection('pharmacies')
            .doc(pharmacyId);

    return _firestore.runTransaction<bool>(
      (transaction) async {
        final snapshot =
            await transaction.get(
          pharmacyRef,
        );

        if (!snapshot.exists) {
          return false;
        }

        final data =
            snapshot.data() ??
                <String, dynamic>{};

        final currentStatus =
            data[
              fieldSubscriptionStatus
            ]?.toString();

        if (!isSubscriptionActive(
          currentStatus,
        )) {
          return false;
        }

        final currentEnd =
            readDate(
          data[
            fieldSubscriptionEndAt
          ],
        );

        if (currentEnd == null) {
          return false;
        }

        final today =
            normalizeDate(
          checkDate ??
              DateTime.now(),
        );

        final normalizedEnd =
            normalizeDate(
          currentEnd,
        );

        // Bado current subscription haijaisha.
        if (today.isBefore(
          normalizedEnd.add(
            const Duration(days: 1),
          ),
        )) {
          return false;
        }

        // ========================================================
        // CHECK SCHEDULED RENEWAL
        // ========================================================

        final nextStatus =
            data[
              fieldNextStatus
            ]?.toString();

        final nextPlanValue =
            data[
              fieldNextPlan
            ];

        final nextPlan =
            nextPlanValue is String
                ? nextPlanValue.trim()
                : '';

        final nextStart =
            readDate(
          data[
            fieldNextStartAt
          ],
        );

        final nextEnd =
            readDate(
          data[
            fieldNextEndAt
          ],
        );

        // Kama scheduled renewal haijakamilika,
        // expire current subscription kawaida.
        if (!isScheduledStatus(
              nextStatus,
            ) ||
            nextPlan.isEmpty ||
            nextStart == null ||
            nextEnd == null) {
          transaction.update(
            pharmacyRef,
            {
              fieldStatus:
                  pharmacyStatusInactive,

              fieldSubscriptionStatus:
                  statusExpired,

              fieldSubscriptionUpdatedAt:
                  FieldValue.serverTimestamp(),
            },
          );

          return true;
        }

        final scheduledStart =
            normalizeDate(
          nextStart,
        );

        final scheduledEnd =
            normalizeDate(
          nextEnd,
        );

        // Scheduled renewal bado haijafika.
        if (scheduledStart.isAfter(
          today,
        )) {
          transaction.update(
            pharmacyRef,
            {
              fieldStatus:
                  pharmacyStatusInactive,

              fieldSubscriptionStatus:
                  statusExpired,

              fieldSubscriptionUpdatedAt:
                  FieldValue.serverTimestamp(),
            },
          );

          return true;
        }

        // ========================================================
        // ACTIVATE SCHEDULED RENEWAL
        // ========================================================

        transaction.update(
          pharmacyRef,
          {
            fieldStatus:
                pharmacyStatusActive,

            fieldSubscriptionStatus:
                statusActive,

            fieldSubscriptionPlan:
                nextPlan,

            fieldSubscriptionStartAt:
                Timestamp.fromDate(
              scheduledStart,
            ),

            fieldSubscriptionEndAt:
                Timestamp.fromDate(
              DateTime(
                scheduledEnd.year,
                scheduledEnd.month,
                scheduledEnd.day,
                23,
                59,
                59,
              ),
            ),

            fieldSubscriptionUpdatedAt:
                FieldValue.serverTimestamp(),

            // Scheduled renewal imetumika.
            fieldNextStatus:
                FieldValue.delete(),

            fieldNextPlan:
                FieldValue.delete(),

            fieldNextStartAt:
                FieldValue.delete(),

            fieldNextEndAt:
                FieldValue.delete(),

            fieldNextPrice:
                FieldValue.delete(),

            fieldNextMonths:
                FieldValue.delete(),

            fieldNextCreatedAt:
                FieldValue.delete(),
          },
        );

        return true;
      },
    );
  }

  // ============================================================
  // VALID ACCESS
  // ============================================================

  Future<bool>
      hasValidAccess(
    String pharmacyId, {
    DateTime? checkDate,
  }) async {
    await expireSubscriptionIfNeeded(
      pharmacyId,
      checkDate: checkDate,
    );

    final data =
        await getPharmacySubscription(
      pharmacyId,
    );

    if (data == null) {
      return false;
    }

    final subscriptionStatus =
        data[
          fieldSubscriptionStatus
        ]?.toString();

    if (!isSubscriptionActive(
      subscriptionStatus,
    )) {
      return false;
    }

    final pharmacyStatus =
        data[
          fieldStatus
        ]?.toString()
          .trim()
          .toLowerCase();

    return pharmacyStatus ==
        pharmacyStatusActive;
  }

  // ============================================================
  // GET SCHEDULED RENEWAL
  // ============================================================

  Future<Map<String, dynamic>?>
      getScheduledRenewal(
    String pharmacyId,
  ) async {
    final data =
        await getPharmacySubscription(
      pharmacyId,
    );

    if (data == null) {
      return null;
    }

    final status =
        data[
          fieldNextStatus
        ]?.toString();

    if (!isScheduledStatus(
      status,
    )) {
      return null;
    }

    final planValue =
        data[
          fieldNextPlan
        ];

    final plan =
        planValue is String
            ? planValue.trim()
            : '';

    final start =
        readDate(
      data[
        fieldNextStartAt
      ],
    );

    final end =
        readDate(
      data[
        fieldNextEndAt
      ],
    );

    if (plan.isEmpty ||
        start == null ||
        end == null) {
      return null;
    }

    return {
      'status':
          statusScheduled,

      'plan':
          plan,

      'price':
          data[
            fieldNextPrice
          ],

      'months':
          data[
            fieldNextMonths
          ],

      'startAt':
          start,

      'endAt':
          end,

      'createdAt':
          readDate(
        data[
          fieldNextCreatedAt
        ],
      ),
    };
  }

  // ============================================================
  // CANCEL SCHEDULED RENEWAL
  // ============================================================

  Future<void>
      cancelScheduledRenewal(
    String pharmacyId,
  ) async {
    await _firestore
        .collection('pharmacies')
        .doc(pharmacyId)
        .update({
      fieldNextStatus:
          FieldValue.delete(),

      fieldNextPlan:
          FieldValue.delete(),

      fieldNextStartAt:
          FieldValue.delete(),

      fieldNextEndAt:
          FieldValue.delete(),

      fieldNextPrice:
          FieldValue.delete(),

      fieldNextMonths:
          FieldValue.delete(),

      fieldNextCreatedAt:
          FieldValue.delete(),

      fieldSubscriptionUpdatedAt:
          FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // READ DATE
  // ============================================================

  DateTime? readDate(
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

  // ============================================================
  // DAYS REMAINING
  // ============================================================

  int? daysRemaining(
    DateTime? endDate, {
    DateTime? fromDate,
  }) {
    if (endDate == null) {
      return null;
    }

    final start =
        normalizeDate(
      fromDate ??
          DateTime.now(),
    );

    final end =
        normalizeDate(
      endDate,
    );

    return end
        .difference(start)
        .inDays;
  }
}