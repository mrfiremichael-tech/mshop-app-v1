import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  bool get isLoggedIn => currentUser != null;

  // ============================================================
  // LOGIN
  // ============================================================

  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    if (normalizedEmail.isEmpty) {
      throw Exception('Email is required.');
    }

    if (password.isEmpty) {
      throw Exception('Password is required.');
    }

    return _auth.signInWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );
  }

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return login(
      email: email,
      password: password,
    );
  }

  // ============================================================
  // PHARMACY OWNER REGISTRATION
  // ============================================================

  Future<UserCredential> registerPharmacyOwner({
    required String fullName,
    required String pharmacyName,
    required String phone,
    required String email,
    required String password,
  }) async {
    final normalizedFullName = fullName.trim();
    final normalizedPharmacyName = pharmacyName.trim();
    final normalizedPhone = phone.trim();
    final normalizedEmail = email.trim().toLowerCase();

    if (normalizedFullName.isEmpty) {
      throw Exception('Full name is required.');
    }

    if (normalizedPharmacyName.isEmpty) {
      throw Exception('Pharmacy name is required.');
    }

    if (normalizedPhone.isEmpty) {
      throw Exception('Phone number is required.');
    }

    if (normalizedEmail.isEmpty) {
      throw Exception('Email is required.');
    }

    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters.');
    }

    final credential = await _auth.createUserWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );

    final user = credential.user;

    if (user == null) {
      throw Exception('Registration failed.');
    }

    await user.updateDisplayName(normalizedFullName);

    final uid = user.uid;

    final userReference = _firestore.collection('users').doc(uid);
    final pharmacyReference = _firestore.collection('pharmacies').doc(uid);

    final batch = _firestore.batch();

    batch.set(userReference, {
      'id': uid,
      'fullName': normalizedFullName,
      'email': normalizedEmail,
      'phone': normalizedPhone,
      'role': 'pharmacy_owner',
      'pharmacyId': uid,
      'status': 'pending_subscription',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.set(pharmacyReference, {
      'id': uid,
      'ownerId': uid,
      'name': normalizedPharmacyName,
      'email': normalizedEmail,
      'phone': normalizedPhone,
      'status': 'pending_subscription',
      'subscriptionPlan': null,
      'subscriptionStatus': 'none',
      'subscriptionStartAt': null,
      'subscriptionEndAt': null,
      'subscriptionUpdatedAt': FieldValue.serverTimestamp(),
      'trialDays': 0,
      'trialStartAt': null,
      'trialEndAt': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    return credential;
  }

  Future<UserCredential> registerPharmacy({
    required String fullName,
    required String pharmacyName,
    required String phone,
    required String email,
    required String password,
  }) {
    return registerPharmacyOwner(
      fullName: fullName,
      pharmacyName: pharmacyName,
      phone: phone,
      email: email,
      password: password,
    );
  }

  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) {
    return registerPharmacyOwner(
      fullName: fullName,
      pharmacyName: '',
      phone: phone,
      email: email,
      password: password,
    );
  }

  // ============================================================
  // CREATE STAFF FIREBASE AUTH ACCOUNT
  // ============================================================

  Future<String> createStaffAccount({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    if (normalizedEmail.isEmpty) {
      throw Exception('Staff email is required.');
    }

    if (password.length < 6) {
      throw Exception('Staff password must be at least 6 characters.');
    }

    final staffAuth = await _getSecondaryAuth();

    final credential = await staffAuth.createUserWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );

    final user = credential.user;

    if (user == null) {
      throw Exception('Failed to create Staff account.');
    }

    return user.uid;
  }

  Future<FirebaseAuth> _getSecondaryAuth() async {
    const appName = 'mshop_staff_auth';

    try {
      final app = Firebase.app(appName);
      return FirebaseAuth.instanceFor(app: app);
    } on FirebaseException {
      final app = await Firebase.initializeApp(
        name: appName,
        options: Firebase.app().options,
      );

      return FirebaseAuth.instanceFor(app: app);
    }
  }

  // ============================================================
  // FIND STAFF BY EMAIL
  // ============================================================

  Future<
      ({
        Map<String, dynamic> data,
        String documentId,
      })?> _findStaffRecord(
    User user,
  ) async {
    final email = user.email?.trim().toLowerCase();

    if (email == null || email.isEmpty) {
      return null;
    }

    final snapshot = await _firestore
        .collection('staff')
        .where(
          'email',
          isEqualTo: email,
        )
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return (
      data: snapshot.docs.first.data(),
      documentId: snapshot.docs.first.id,
    );
  }

  // ============================================================
  // CREATE STAFF USER PROFILE ON FIRST LOGIN
  //
  // This is the important part:
  // Staff does not need M-Shop Owner to configure a role.
  // Once the Pharmacy Owner creates Staff, the first successful
  // Staff login automatically creates users/{uid} as staff.
  // ============================================================

  Future<Map<String, dynamic>> _ensureStaffUserProfile(
    User user,
    Map<String, dynamic> staffData,
    String staffDocumentId,
  ) async {
    final pharmacyId = staffData['pharmacyId']?.toString();

    if (pharmacyId == null || pharmacyId.isEmpty) {
      throw Exception('Staff pharmacy information is missing.');
    }

    final status = staffData['status']?.toString() ?? 'inactive';

    if (status != 'active') {
      throw FirebaseAuthException(
        code: 'user-disabled',
        message: 'This Staff account is inactive.',
      );
    }

    final email =
        staffData['email']?.toString().trim().toLowerCase() ??
        user.email?.trim().toLowerCase() ??
        '';

    if (email.isEmpty) {
      throw Exception('Staff email information is missing.');
    }

    final fullName = staffData['fullName']?.toString() ?? '';
    final phone = staffData['phone']?.toString() ?? '';

    final userReference = _firestore
        .collection('users')
        .doc(user.uid);

    final existing = await userReference.get();

    if (!existing.exists) {
      await userReference.set({
        'id': user.uid,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'role': 'staff',
        'staffId': staffDocumentId,
        'pharmacyId': pharmacyId,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      final data = existing.data() ?? {};
      final role = data['role']?.toString();

      if (role != null && role.isNotEmpty && role != 'staff') {
        throw Exception('This account is already assigned to another role.');
      }

      if (role != 'staff') {
        await userReference.set({
          ...data,
          'id': user.uid,
          'fullName': fullName,
          'email': email,
          'phone': phone,
          'role': 'staff',
          'staffId': staffDocumentId,
          'pharmacyId': pharmacyId,
          'status': 'active',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }

    return {
      'id': user.uid,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'role': 'staff',
      'staffId': staffDocumentId,
      'pharmacyId': pharmacyId,
      'status': 'active',
      'permissions': staffData['permissions'] is List
          ? (staffData['permissions'] as List)
              .map((item) => item.toString())
              .toList()
          : <String>[],
    };
  }

  // ============================================================
  // CURRENT USER PROFILE
  // ============================================================

  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = currentUser;

    if (user == null) {
      return null;
    }

    // ------------------------------------------------------------
    // 1. Existing user document:
    //    Pharmacy Owner, M-Shop Owner, or Staff after first login.
    // ------------------------------------------------------------

    final userDocument = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();

    if (userDocument.exists) {
      final userData = userDocument.data() ?? {};
      final role = userData['role']?.toString();

      if (role == 'staff') {
        final staffRecord = await _findStaffRecord(user);

        if (staffRecord == null) {
          throw Exception('Staff record not found.');
        }

        final staffData = staffRecord.data;

        final status =
            staffData['status']?.toString() ?? 'inactive';

        if (status != 'active') {
          throw FirebaseAuthException(
            code: 'user-disabled',
            message: 'This Staff account is inactive.',
          );
        }

        final pharmacyId =
            staffData['pharmacyId']?.toString();

        if (pharmacyId == null || pharmacyId.isEmpty) {
          throw Exception('Staff pharmacy information is missing.');
        }

        final permissions = staffData['permissions'] is List
            ? (staffData['permissions'] as List)
                .map((item) => item.toString())
                .toList()
            : <String>[];

        final profile = <String, dynamic>{
          ...userData,
          ...staffData,
          'id': staffRecord.documentId,
          'staffId': staffRecord.documentId,
          'role': 'staff',
          'pharmacyId': pharmacyId,
          'permissions': permissions,
        };

        final pharmacyDocument = await _firestore
            .collection('pharmacies')
            .doc(pharmacyId)
            .get();

        if (pharmacyDocument.exists) {
          final pharmacyData = pharmacyDocument.data() ?? {};

          profile['pharmacyName'] = pharmacyData['name'];
          profile['pharmacyStatus'] = pharmacyData['status'];
          profile['subscriptionPlan'] =
              pharmacyData['subscriptionPlan'];
          profile['subscriptionStatus'] =
              pharmacyData['subscriptionStatus'];
          profile['subscriptionStartAt'] =
              pharmacyData['subscriptionStartAt'];
          profile['subscriptionEndAt'] =
              pharmacyData['subscriptionEndAt'];
        }

        return profile;
      }

      if (role == 'pharmacy_owner' || role == 'mshop_owner') {
        final pharmacyId =
            userData['pharmacyId']?.toString();

        if (pharmacyId == null || pharmacyId.isEmpty) {
          return userData;
        }

        final pharmacyDocument = await _firestore
            .collection('pharmacies')
            .doc(pharmacyId)
            .get();

        if (!pharmacyDocument.exists) {
          return userData;
        }

        final pharmacyData = pharmacyDocument.data() ?? {};

        return {
          ...userData,
          'pharmacyName': pharmacyData['name'],
          'pharmacyStatus': pharmacyData['status'],
          'subscriptionPlan':
              pharmacyData['subscriptionPlan'],
          'subscriptionStatus':
              pharmacyData['subscriptionStatus'],
          'subscriptionStartAt':
              pharmacyData['subscriptionStartAt'],
          'subscriptionEndAt':
              pharmacyData['subscriptionEndAt'],
          'subscriptionUpdatedAt':
              pharmacyData['subscriptionUpdatedAt'],
          'trialDays': pharmacyData['trialDays'],
          'trialStartAt': pharmacyData['trialStartAt'],
          'trialEndAt': pharmacyData['trialEndAt'],
        };
      }
    }

    // ------------------------------------------------------------
    // 2. No users/{uid} document:
    //    this is Staff's FIRST LOGIN.
    // ------------------------------------------------------------

    final staffRecord = await _findStaffRecord(user);

    if (staffRecord == null) {
      return null;
    }

    final profile = await _ensureStaffUserProfile(
      user,
      staffRecord.data,
      staffRecord.documentId,
    );

    final pharmacyId = profile['pharmacyId']?.toString();

    if (pharmacyId == null || pharmacyId.isEmpty) {
      throw Exception('Staff pharmacy information is missing.');
    }

    // Now the users/{uid} document exists, so the normal Firestore
    // pharmacy access rules work exactly like every later login.
    final pharmacyDocument = await _firestore
        .collection('pharmacies')
        .doc(pharmacyId)
        .get();

    if (pharmacyDocument.exists) {
      final pharmacyData = pharmacyDocument.data() ?? {};

      profile['pharmacyName'] = pharmacyData['name'];
      profile['pharmacyStatus'] = pharmacyData['status'];
      profile['subscriptionPlan'] =
          pharmacyData['subscriptionPlan'];
      profile['subscriptionStatus'] =
          pharmacyData['subscriptionStatus'];
      profile['subscriptionStartAt'] =
          pharmacyData['subscriptionStartAt'];
      profile['subscriptionEndAt'] =
          pharmacyData['subscriptionEndAt'];
    }

    return profile;
  }

  Future<Map<String, dynamic>?> getCurrentUserData() {
    return getCurrentUserProfile();
  }

  // ============================================================
  // UPDATE PROFILE
  // ============================================================

  Future<void> updateCurrentUserProfile({
    required String fullName,
    required String phone,
    required String pharmacyName,
  }) async {
    final user = currentUser;

    if (user == null) {
      throw Exception('User is not logged in.');
    }

    final normalizedFullName = fullName.trim();
    final normalizedPhone = phone.trim();

    if (normalizedFullName.isEmpty) {
      throw Exception('Full name is required.');
    }

    if (normalizedPhone.isEmpty) {
      throw Exception('Phone number is required.');
    }

    final profile = await getCurrentUserProfile();

    if (profile == null) {
      throw Exception('User profile not found.');
    }

    final role = profile['role']?.toString();

    final batch = _firestore.batch();

    if (role == 'staff') {
      final staffId = profile['staffId']?.toString();

      if (staffId == null || staffId.isEmpty) {
        throw Exception('Staff information is missing.');
      }

      batch.update(
        _firestore.collection('staff').doc(staffId),
        {
          'fullName': normalizedFullName,
          'phone': normalizedPhone,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
    } else {
      final userReference =
          _firestore.collection('users').doc(user.uid);

      batch.update(
        userReference,
        {
          'fullName': normalizedFullName,
          'phone': normalizedPhone,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      if (role == 'pharmacy_owner') {
        final pharmacyId =
            profile['pharmacyId']?.toString();

        if (pharmacyId != null && pharmacyId.isNotEmpty) {
          batch.update(
            _firestore.collection('pharmacies').doc(pharmacyId),
            {
              'name': pharmacyName.trim(),
              'phone': normalizedPhone,
              'updatedAt': FieldValue.serverTimestamp(),
            },
          );
        }
      }
    }

    await batch.commit();

    await user.updateDisplayName(normalizedFullName);
  }

  // ============================================================
  // ROLE HELPERS
  // ============================================================

  Future<String?> getCurrentUserRole() async {
    final profile = await getCurrentUserProfile();
    return profile?['role']?.toString();
  }

  Future<String?> getCurrentPharmacyId() async {
    final profile = await getCurrentUserProfile();

    if (profile == null) {
      return currentUser?.uid;
    }

    final pharmacyId = profile['pharmacyId']?.toString();

    if (pharmacyId == null || pharmacyId.isEmpty) {
      return currentUser?.uid;
    }

    return pharmacyId;
  }

  Future<bool> isPharmacyOwner() async {
    return await getCurrentUserRole() == 'pharmacy_owner';
  }

  Future<bool> isStaff() async {
    return await getCurrentUserRole() == 'staff';
  }

  // ============================================================
  // PASSWORD RESET / LOGOUT
  // ============================================================

  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    if (normalizedEmail.isEmpty) {
      throw Exception('Email is required.');
    }

    await _auth.sendPasswordResetEmail(
      email: normalizedEmail,
    );
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> signOut() async {
    await logout();
  }
}
