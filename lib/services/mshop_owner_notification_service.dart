import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MshopOwnerNotificationService {
  MshopOwnerNotificationService._();

  static final MshopOwnerNotificationService instance =
      MshopOwnerNotificationService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>>
      get _notifications =>
          _firestore.collection('mshop_notifications');

  // ============================================================
  // CURRENT M-SHOP OWNER
  // ============================================================

  String? get currentOwnerUid =>
      _auth.currentUser?.uid;

  // ============================================================
  // CREATE NOTIFICATION
  // ============================================================

  Future<void> createNotification({
    required String type,
    required String title,
    required String message,
    String? pharmacyId,
    String? pharmacyName,
    String? ownerId,
    String? ownerName,
    String? relatedId,
    String? status,
    String? plan,
    String? startDate,
    String? endDate,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    final data = <String, dynamic>{
      'type': type,
      'title': title,
      'message': message,
      'pharmacyId': pharmacyId,
      'pharmacyName': pharmacyName,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'relatedId': relatedId,
      'status': status,
      'plan': plan,
      'startDate': startDate,
      'endDate': endDate,
      'createdByUid': user.uid,
      'createdByEmail': user.email,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    };

    await _notifications.add(data);
  }

  // ============================================================
  // PHARMACY CREATED
  // ============================================================

  Future<void> pharmacyCreated({
    required String pharmacyId,
    required String pharmacyName,
    String? ownerId,
    String? ownerName,
  }) async {
    await createNotification(
      type: 'pharmacy_created',
      title: 'New pharmacy registered',
      message:
          '$pharmacyName has been registered on the M-Shop platform.',
      pharmacyId: pharmacyId,
      pharmacyName: pharmacyName,
      ownerId: ownerId,
      ownerName: ownerName,
      relatedId: pharmacyId,
      status: 'active',
    );
  }

  // ============================================================
  // PHARMACY STATUS
  // ============================================================

  Future<void> pharmacyStatusChanged({
    required String pharmacyId,
    required String pharmacyName,
    required String newStatus,
  }) async {
    final normalizedStatus =
        newStatus.trim().toLowerCase();

    final isActive =
        normalizedStatus == 'active';

    await createNotification(
      type: 'pharmacy_status_changed',
      title: isActive
          ? 'Pharmacy activated'
          : 'Pharmacy deactivated',
      message: isActive
          ? '$pharmacyName has been activated on the M-Shop platform.'
          : '$pharmacyName has been deactivated on the M-Shop platform.',
      pharmacyId: pharmacyId,
      pharmacyName: pharmacyName,
      relatedId: pharmacyId,
      status: normalizedStatus,
    );
  }

  // ============================================================
  // PHARMACY OWNER CREATED
  // ============================================================

  Future<void> pharmacyOwnerCreated({
    required String ownerId,
    required String ownerName,
    required String email,
    String? pharmacyId,
    String? pharmacyName,
  }) async {
    await createNotification(
      type: 'pharmacy_owner_created',
      title: 'New pharmacy owner registered',
      message:
          '$ownerName has registered as a pharmacy owner.',
      pharmacyId: pharmacyId,
      pharmacyName: pharmacyName,
      ownerId: ownerId,
      ownerName: ownerName,
      relatedId: ownerId,
    );
  }

  // ============================================================
  // PHARMACY OWNER STATUS
  // ============================================================

  Future<void> pharmacyOwnerStatusChanged({
    required String ownerId,
    required String ownerName,
    required String newStatus,
    String? pharmacyId,
    String? pharmacyName,
  }) async {
    final normalizedStatus =
        newStatus.trim().toLowerCase();

    final isActive =
        normalizedStatus == 'active';

    await createNotification(
      type: 'pharmacy_owner_status_changed',
      title: isActive
          ? 'Pharmacy owner activated'
          : 'Pharmacy owner deactivated',
      message: isActive
          ? '$ownerName account has been activated.'
          : '$ownerName account has been deactivated.',
      pharmacyId: pharmacyId,
      pharmacyName: pharmacyName,
      ownerId: ownerId,
      ownerName: ownerName,
      relatedId: ownerId,
      status: normalizedStatus,
    );
  }

  // ============================================================
  // SUBSCRIPTION CREATED / UPDATED
  // ============================================================

  Future<void> subscriptionUpdated({
    required String pharmacyId,
    required String pharmacyName,
    required String plan,
    required String subscriptionStatus,
    String? startDate,
    String? endDate,
  }) async {
    await createNotification(
      type: 'subscription_updated',
      title: 'Subscription updated',
      message:
          '$pharmacyName subscription has been updated to $plan.',
      pharmacyId: pharmacyId,
      pharmacyName: pharmacyName,
      relatedId: pharmacyId,
      status: subscriptionStatus,
      plan: plan,
      startDate: startDate,
      endDate: endDate,
    );
  }

  // ============================================================
  // SUBSCRIPTION EXPIRING
  // ============================================================

  Future<void> subscriptionExpiring({
    required String pharmacyId,
    required String pharmacyName,
    required String plan,
    required String endDate,
  }) async {
    await createNotification(
      type: 'subscription_expiring',
      title: 'Subscription expiring soon',
      message:
          '$pharmacyName subscription will expire on $endDate.',
      pharmacyId: pharmacyId,
      pharmacyName: pharmacyName,
      relatedId: pharmacyId,
      status: 'expiring',
      plan: plan,
      endDate: endDate,
    );
  }

  // ============================================================
  // SUBSCRIPTION EXPIRED
  // ============================================================

  Future<void> subscriptionExpired({
    required String pharmacyId,
    required String pharmacyName,
    required String plan,
    required String endDate,
  }) async {
    await createNotification(
      type: 'subscription_expired',
      title: 'Subscription expired',
      message:
          '$pharmacyName subscription has expired.',
      pharmacyId: pharmacyId,
      pharmacyName: pharmacyName,
      relatedId: pharmacyId,
      status: 'expired',
      plan: plan,
      endDate: endDate,
    );
  }

  // ============================================================
  // STAFF CREATED
  // ============================================================

  Future<void> staffCreated({
    required String staffId,
    required String staffName,
    required String pharmacyId,
    required String pharmacyName,
  }) async {
    await createNotification(
      type: 'staff_created',
      title: 'New staff added',
      message:
          '$staffName has been added to $pharmacyName.',
      pharmacyId: pharmacyId,
      pharmacyName: pharmacyName,
      relatedId: staffId,
      status: 'active',
    );
  }

  // ============================================================
  // PLATFORM INFORMATION
  // ============================================================

  Future<void> platformInformation({
    required String title,
    required String message,
    String? relatedId,
  }) async {
    await createNotification(
      type: 'platform_information',
      title: title,
      message: message,
      relatedId: relatedId,
    );
  }

  // ============================================================
  // MARK ONE AS READ
  // ============================================================

  Future<void> markAsRead(
    String notificationId,
  ) async {
    await _notifications
        .doc(notificationId)
        .update({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // MARK ALL AS READ
  // ============================================================

  Future<void> markAllAsRead(
    List<QueryDocumentSnapshot<Map<String, dynamic>>>
        documents,
  ) async {
    if (documents.isEmpty) {
      return;
    }

    final batch = _firestore.batch();

    for (final document in documents) {
      final data = document.data();

      if (data['isRead'] == true) {
        continue;
      }

      batch.update(
        document.reference,
        {
          'isRead': true,
          'readAt':
              FieldValue.serverTimestamp(),
        },
      );
    }

    await batch.commit();
  }

  // ============================================================
  // NOTIFICATION STREAM
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      streamNotifications() {
    return _notifications
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots();
  }

  // ============================================================
  // UNREAD COUNT STREAM
  // ============================================================

  Stream<int> streamUnreadCount() {
    return _notifications
        .where(
          'isRead',
          isEqualTo: false,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.length,
        );
  }
}