import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance =
      NotificationService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>>
      get _notifications =>
          _firestore.collection('notifications');

  // ============================================================
  // CURRENT USER PROFILE
  // ============================================================

  Future<Map<String, dynamic>?> _getCurrentUserProfile() async {
    final user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    final doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();

    if (!doc.exists) {
      return null;
    }

    final data = doc.data();

    if (data == null) {
      return null;
    }

    return {
      'uid': user.uid,
      ...data,
    };
  }

  String _getDisplayName({
    required User user,
    required Map<String, dynamic>? profile,
    String fallback = 'User',
  }) {
    final fullName =
        profile?['fullName']?.toString().trim();

    if (fullName != null && fullName.isNotEmpty) {
      return fullName;
    }

    final name =
        profile?['name']?.toString().trim();

    if (name != null && name.isNotEmpty) {
      return name;
    }

    final email = user.email?.trim();

    if (email != null && email.isNotEmpty) {
      return email;
    }

    return fallback;
  }

  // ============================================================
  // GET PHARMACY OWNER
  // ============================================================

  Future<String?> _getOwnerId(
    String pharmacyId,
  ) async {
    final pharmacyDoc = await _firestore
        .collection('pharmacies')
        .doc(pharmacyId)
        .get();

    if (!pharmacyDoc.exists) {
      return null;
    }

    final data = pharmacyDoc.data();

    if (data == null) {
      return null;
    }

    final ownerId =
        data['ownerId']?.toString().trim();

    if (ownerId == null || ownerId.isEmpty) {
      return null;
    }

    return ownerId;
  }

  // ============================================================
  // STAFF NOTIFICATION
  // ============================================================

  Future<void> createStaffNotification({
    required String pharmacyId,
    required String type,
    required String title,
    required String message,
    String? itemName,
    String? status,
    String? relatedId,
    String? alertKey,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    final profile =
        await _getCurrentUserProfile();

    final role =
        profile?['role']?.toString();

    if (role != 'staff') {
      return;
    }

    final staffName = _getDisplayName(
      user: user,
      profile: profile,
      fallback: 'Staff',
    );

    await _notifications.add({
      'pharmacyId': pharmacyId,
      'recipientUid': user.uid,
      'recipientRole': 'staff',
      'type': type,
      'title': title,
      'message': message,
      'itemName': itemName,
      'status': status,
      'relatedId': relatedId,
      'alertKey': alertKey,
      'performedByUid': user.uid,
      'performedByName': staffName,
      'createdAt':
          FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }

  // ============================================================
  // OWNER NORMAL NOTIFICATION
  // ============================================================

  Future<void> createOwnerNotification({
    required String pharmacyId,
    required String type,
    required String title,
    required String message,
    String? itemName,
    String? status,
    String? relatedId,
    String? alertKey,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    final profile =
        await _getCurrentUserProfile();

    final performedByName =
        _getDisplayName(
      user: user,
      profile: profile,
      fallback: 'User',
    );

    final ownerId =
        await _getOwnerId(pharmacyId);

    if (ownerId == null || ownerId.isEmpty) {
      return;
    }

    await _notifications.add({
      'pharmacyId': pharmacyId,
      'recipientUid': ownerId,
      'recipientRole': 'pharmacy_owner',
      'type': type,
      'title': title,
      'message': message,
      'itemName': itemName,
      'status': status,
      'relatedId': relatedId,
      'alertKey': alertKey,
      'performedByUid': user.uid,
      'performedByName': performedByName,
      'createdAt':
          FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }

  // ============================================================
  // OWNER ALERT NOTIFICATION
  //
  // IMPORTANT:
  // Staff does NOT read Owner notifications first.
  //
  // We directly try to create the deterministic document.
  //
  // First time:
  //     set() creates the document.
  //
  // Later checks:
  //     set() becomes an update and Firestore rules reject it.
  //     That permission error is ignored because the notification
  //     already exists.
  // ============================================================

  Future<void> _createOwnerAlertNotification({
    required String pharmacyId,
    required String type,
    required String title,
    required String message,
    required String relatedId,
    required String alertKey,
    String? itemName,
    String? status,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    final profile =
        await _getCurrentUserProfile();

    final performedByName =
        _getDisplayName(
      user: user,
      profile: profile,
      fallback: 'Staff',
    );

    final ownerId =
        await _getOwnerId(pharmacyId);

    if (ownerId == null || ownerId.isEmpty) {
      return;
    }

    final notificationId =
        'owner_alert_${ownerId}_$alertKey';

    final notificationRef =
        _notifications.doc(notificationId);

    try {
      await notificationRef.set({
        'pharmacyId': pharmacyId,
        'recipientUid': ownerId,
        'recipientRole': 'pharmacy_owner',
        'type': type,
        'title': title,
        'message': message,
        'itemName': itemName,
        'status': status,
        'relatedId': relatedId,
        'alertKey': alertKey,
        'performedByUid': user.uid,
        'performedByName': performedByName,
        'createdAt':
            FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied' ||
          e.code == 'already-exists') {
        return;
      }

      rethrow;
    }
  }

  // ============================================================
  // TWO-WAY NOTIFICATION
  // ============================================================

  Future<void> createTwoWayNotification({
    required String pharmacyId,
    required String staffType,
    required String staffTitle,
    required String staffMessage,
    required String ownerType,
    required String ownerTitle,
    required String ownerMessage,
    String? itemName,
    String? status,
    String? relatedId,
  }) async {
    await createStaffNotification(
      pharmacyId: pharmacyId,
      type: staffType,
      title: staffTitle,
      message: staffMessage,
      itemName: itemName,
      status: status,
      relatedId: relatedId,
    );

    await createOwnerNotification(
      pharmacyId: pharmacyId,
      type: ownerType,
      title: ownerTitle,
      message: ownerMessage,
      itemName: itemName,
      status: status,
      relatedId: relatedId,
    );
  }

  // ============================================================
  // CHECK DUPLICATE STAFF ALERT
  // ============================================================

  Future<bool> _staffAlertAlreadyExists({
    required String pharmacyId,
    required String type,
    required String relatedId,
    required String alertKey,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      return true;
    }

    final snapshot = await _notifications
        .where(
          'pharmacyId',
          isEqualTo: pharmacyId,
        )
        .where(
          'recipientUid',
          isEqualTo: user.uid,
        )
        .get();

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final existingType =
          data['type']?.toString();

      final existingRelatedId =
          data['relatedId']?.toString();

      final existingAlertKey =
          data['alertKey']?.toString();

      if (existingType == type &&
          existingRelatedId == relatedId &&
          existingAlertKey == alertKey) {
        return true;
      }
    }

    return false;
  }

  // ============================================================
  // LOW STOCK NOTIFICATION
  // ============================================================

  Future<void> createLowStockNotification({
    required String pharmacyId,
    required String medicineId,
    required String medicineName,
    required int quantity,
    required String unit,
  }) async {
    final relatedId = medicineId;

    final alertKey =
        'low_stock_$medicineId';

    final exists =
        await _staffAlertAlreadyExists(
      pharmacyId: pharmacyId,
      type: 'low_stock',
      relatedId: relatedId,
      alertKey: alertKey,
    );

    if (!exists) {
      await createStaffNotification(
        pharmacyId: pharmacyId,
        type: 'low_stock',
        title: 'Low Stock Alert',
        message:
            '$medicineName stock is low.',
        itemName: medicineName,
        status: 'warning',
        relatedId: medicineId,
        alertKey: alertKey,
      );
    }

    // OWNER
    await _createOwnerAlertNotification(
      pharmacyId: pharmacyId,
      type: 'low_stock',
      title: 'Low Stock Alert',
      message:
          '$medicineName stock is low.',
      itemName: medicineName,
      status: 'warning',
      relatedId: medicineId,
      alertKey: alertKey,
    );
  }

  // ============================================================
  // EXPIRY NOTIFICATION
  // ============================================================

  Future<void> createExpiryNotification({
    required String pharmacyId,
    required String medicineId,
    required String medicineName,
    required DateTime expiryDate,
    required bool isExpired,
  }) async {
    final relatedId = medicineId;

    final alertLevel =
        isExpired
            ? 'expired'
            : 'expiring_soon';

    final alertKey =
        'expiry_${medicineId}_$alertLevel';

    final exists =
        await _staffAlertAlreadyExists(
      pharmacyId: pharmacyId,
      type: 'expiry',
      relatedId: relatedId,
      alertKey: alertKey,
    );

    final formattedDate =
        _formatDate(expiryDate);

    if (!exists) {
      if (isExpired) {
        await createStaffNotification(
          pharmacyId: pharmacyId,
          type: 'expiry',
          title: 'Expired Product',
          message:
              '$medicineName has expired.',
          itemName: medicineName,
          status: 'expired',
          relatedId: medicineId,
          alertKey: alertKey,
        );
      } else {
        await createStaffNotification(
          pharmacyId: pharmacyId,
          type: 'expiry',
          title: 'Expiry Alert',
          message:
              '$medicineName will expire on $formattedDate.',
          itemName: medicineName,
          status: 'expiring_soon',
          relatedId: medicineId,
          alertKey: alertKey,
        );
      }
    }

    // OWNER
    if (isExpired) {
      await _createOwnerAlertNotification(
        pharmacyId: pharmacyId,
        type: 'expiry',
        title: 'Expired Product',
        message:
            '$medicineName has expired.',
        itemName: medicineName,
        status: 'expired',
        relatedId: medicineId,
        alertKey: alertKey,
      );
    } else {
      await _createOwnerAlertNotification(
        pharmacyId: pharmacyId,
        type: 'expiry',
        title: 'Expiry Alert',
        message:
            '$medicineName will expire on $formattedDate.',
        itemName: medicineName,
        status: 'expiring_soon',
        relatedId: medicineId,
        alertKey: alertKey,
      );
    }
  }

  // ============================================================
  // CHECK MEDICINE STATUS
  // ============================================================

  Future<void> checkAndCreateMedicineAlerts({
    required String pharmacyId,
    required String medicineId,
    required String medicineName,
    required int quantity,
    required bool isLowStock,
    required DateTime? expiryDate,
    required bool isExpired,
    required bool expiresWithin30Days,
    String unit = '',
  }) async {
    final profile =
        await _getCurrentUserProfile();

    final role =
        profile?['role']?.toString();

    if (role != 'staff') {
      return;
    }

    // LOW STOCK
    if (isLowStock) {
      await createLowStockNotification(
        pharmacyId: pharmacyId,
        medicineId: medicineId,
        medicineName: medicineName,
        quantity: quantity,
        unit: unit,
      );
    }

    // EXPIRY
    if (expiryDate != null &&
        (isExpired ||
            expiresWithin30Days)) {
      await createExpiryNotification(
        pharmacyId: pharmacyId,
        medicineId: medicineId,
        medicineName: medicineName,
        expiryDate: expiryDate,
        isExpired: isExpired,
      );
    }
  }

  // ============================================================
  // READ UNREAD NOTIFICATIONS
  // ============================================================

  Future<List<
          QueryDocumentSnapshot<
              Map<String, dynamic>>>>
      getMyUnreadNotifications() async {
    final user = _auth.currentUser;

    if (user == null) {
      return [];
    }

    final profile =
        await _getCurrentUserProfile();

    final pharmacyId =
        profile?['pharmacyId']?.toString();

    if (pharmacyId == null ||
        pharmacyId.isEmpty) {
      return [];
    }

    final snapshot = await _notifications
        .where(
          'pharmacyId',
          isEqualTo: pharmacyId,
        )
        .where(
          'recipientUid',
          isEqualTo: user.uid,
        )
        .where(
          'isRead',
          isEqualTo: false,
        )
        .get();

    final docs = List<
        QueryDocumentSnapshot<
            Map<String, dynamic>>>.from(
      snapshot.docs,
    );

    docs.sort(
      (a, b) {
        final aTime =
            a.data()['createdAt'];

        final bTime =
            b.data()['createdAt'];

        if (aTime is Timestamp &&
            bTime is Timestamp) {
          return bTime.compareTo(aTime);
        }

        if (aTime is Timestamp) {
          return -1;
        }

        if (bTime is Timestamp) {
          return 1;
        }

        return 0;
      },
    );

    return docs;
  }

  // ============================================================
  // UNREAD COUNT
  // ============================================================

  Future<int> getUnreadCount() async {
    final notifications =
        await getMyUnreadNotifications();

    return notifications.length;
  }

  // ============================================================
  // WATCH UNREAD NOTIFICATIONS
  // ============================================================

  Stream<List<
          QueryDocumentSnapshot<
              Map<String, dynamic>>>>
      watchMyUnreadNotifications() {
    final user = _auth.currentUser;

    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('notifications')
        .where(
          'recipientUid',
          isEqualTo: user.uid,
        )
        .where(
          'isRead',
          isEqualTo: false,
        )
        .snapshots()
        .map(
      (snapshot) {
        final docs = List<
            QueryDocumentSnapshot<
                Map<String, dynamic>>>.from(
          snapshot.docs,
        );

        docs.sort(
          (a, b) {
            final aTime =
                a.data()['createdAt'];

            final bTime =
                b.data()['createdAt'];

            if (aTime is Timestamp &&
                bTime is Timestamp) {
              return bTime.compareTo(aTime);
            }

            if (aTime is Timestamp) {
              return -1;
            }

            if (bTime is Timestamp) {
              return 1;
            }

            return 0;
          },
        );

        return docs;
      },
    );
  }

  // ============================================================
  // MARK AS READ
  // ============================================================

  Future<void> markAsRead(
    String notificationId,
  ) async {
    await _notifications
        .doc(notificationId)
        .update({
      'isRead': true,
      'readAt':
          FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // MARK AS UNREAD
  // ============================================================

  Future<void> markAsUnread(
    String notificationId,
  ) async {
    await _notifications
        .doc(notificationId)
        .update({
      'isRead': false,
      'readAt':
          FieldValue.delete(),
    });
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> deleteNotification(
    String notificationId,
  ) async {
    await _notifications
        .doc(notificationId)
        .delete();
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formatDate(
    DateTime date,
  ) {
    final day =
        date.day.toString().padLeft(2, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }
}