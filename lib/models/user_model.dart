import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String role;
  final String fullName;
  final String email;
  final String phone;
  final String? pharmacyId;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.uid,
    required this.role,
    required this.fullName,
    required this.email,
    required this.phone,
    this.pharmacyId,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  bool get isMShopOwner => role == 'mshop_owner';

  bool get isPharmacyOwner => role == 'pharmacy_owner';

  bool get isStaff => role == 'staff';

  factory UserModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};

    return UserModel(
      uid: (data['uid'] ?? document.id).toString(),
      role: (data['role'] ?? '').toString(),
      fullName: (data['fullName'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      phone: (data['phone'] ?? '').toString(),
      pharmacyId: data['pharmacyId']?.toString(),
      status: (data['status'] ?? 'active').toString(),
      createdAt: _timestampToDateTime(data['createdAt']),
      updatedAt: _timestampToDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'role': role,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'pharmacyId': pharmacyId,
      'status': status,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(updatedAt!),
    };
  }

  UserModel copyWith({
    String? uid,
    String? role,
    String? fullName,
    String? email,
    String? phone,
    String? pharmacyId,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime? _timestampToDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }
}