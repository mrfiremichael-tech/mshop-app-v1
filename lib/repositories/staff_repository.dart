import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/staff_model.dart';

class StaffRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _staff() {
    return _firestore.collection('staff');
  }

  Stream<List<StaffModel>> watchStaff(String pharmacyId) {
    return _staff()
        .where('pharmacyId', isEqualTo: pharmacyId)
        .snapshots()
        .map((snapshot) {
      final staff = snapshot.docs
          .map(StaffModel.fromFirestore)
          .toList();

      staff.sort(
        (a, b) => a.fullName.toLowerCase().compareTo(
              b.fullName.toLowerCase(),
            ),
      );

      return staff;
    });
  }

  Future<List<StaffModel>> getStaff(String pharmacyId) async {
    final snapshot = await _staff()
        .where('pharmacyId', isEqualTo: pharmacyId)
        .get();

    final staff = snapshot.docs
        .map(StaffModel.fromFirestore)
        .toList();

    staff.sort(
      (a, b) => a.fullName.toLowerCase().compareTo(
            b.fullName.toLowerCase(),
          ),
    );

    return staff;
  }

  Future<StaffModel?> getStaffById({
    required String pharmacyId,
    required String staffId,
  }) async {
    final doc = await _staff().doc(staffId).get();

    if (!doc.exists) {
      return null;
    }

    final staff = StaffModel.fromFirestore(doc);

    if (staff.pharmacyId != pharmacyId) {
      return null;
    }

    return staff;
  }

  Future<String> addStaff(StaffModel staff) async {
    final doc = _staff().doc();

    final staffToSave = staff.copyWith(
      id: doc.id,
      createdAt: staff.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await doc.set(staffToSave.toFirestore());

    return doc.id;
  }

  Future<void> updateStaff(StaffModel staff) async {
    if (staff.id.isEmpty) {
      throw Exception('Staff ID is required.');
    }

    final docRef = _staff().doc(staff.id);
    final existing = await docRef.get();

    if (!existing.exists) {
      throw Exception('Staff member not found.');
    }

    final existingStaff = StaffModel.fromFirestore(existing);

    if (existingStaff.pharmacyId != staff.pharmacyId) {
      throw Exception('You cannot update this staff member.');
    }

    final updatedStaff = staff.copyWith(
      updatedAt: DateTime.now(),
    );

    await docRef.update(updatedStaff.toFirestore());
  }

  Future<void> deleteStaff({
    required String pharmacyId,
    required String staffId,
  }) async {
    final docRef = _staff().doc(staffId);
    final existing = await docRef.get();

    if (!existing.exists) {
      throw Exception('Staff member not found.');
    }

    final staff = StaffModel.fromFirestore(existing);

    if (staff.pharmacyId != pharmacyId) {
      throw Exception('You cannot delete this staff member.');
    }

    await docRef.delete();
  }

  Future<void> updateStaffStatus({
    required String pharmacyId,
    required String staffId,
    required String status,
  }) async {
    final docRef = _staff().doc(staffId);
    final existing = await docRef.get();

    if (!existing.exists) {
      throw Exception('Staff member not found.');
    }

    final staff = StaffModel.fromFirestore(existing);

    if (staff.pharmacyId != pharmacyId) {
      throw Exception('You cannot update this staff member.');
    }

    await docRef.update({
      'status': status,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> updatePermissions({
    required String pharmacyId,
    required String staffId,
    required List<String> permissions,
  }) async {
    final docRef = _staff().doc(staffId);
    final existing = await docRef.get();

    if (!existing.exists) {
      throw Exception('Staff member not found.');
    }

    final staff = StaffModel.fromFirestore(existing);

    if (staff.pharmacyId != pharmacyId) {
      throw Exception('You cannot update this staff member.');
    }

    await docRef.update({
      'permissions': permissions,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<List<StaffModel>> searchStaff({
    required String pharmacyId,
    required String query,
  }) async {
    final staff = await getStaff(pharmacyId);

    final searchText = query.trim().toLowerCase();

    if (searchText.isEmpty) {
      return staff;
    }

    return staff.where((member) {
      return member.fullName.toLowerCase().contains(searchText) ||
          member.email.toLowerCase().contains(searchText) ||
          member.phone.toLowerCase().contains(searchText) ||
          member.role.toLowerCase().contains(searchText);
    }).toList();
  }

  Future<int> getStaffCount(String pharmacyId) async {
    final snapshot = await _staff()
        .where('pharmacyId', isEqualTo: pharmacyId)
        .get();

    return snapshot.docs.length;
  }

  Future<int> getActiveStaffCount(String pharmacyId) async {
    final staff = await getStaff(pharmacyId);

    return staff.where((member) => member.isActive).length;
  }
}