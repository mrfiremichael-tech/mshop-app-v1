import 'package:cloud_firestore/cloud_firestore.dart';

class StaffModel {
  final String id;
  final String pharmacyId;
  final String fullName;
  final String email;
  final String phone;
  final String role;
  final String status;
  final List<String> permissions;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const StaffModel({
    required this.id,
    required this.pharmacyId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    required this.permissions,
    this.createdAt,
    this.updatedAt,
  });

  factory StaffModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};

    final permissionsData = data['permissions'];

    final List<String> permissions =
        permissionsData is List
            ? permissionsData
                .map((permission) => permission.toString())
                .toList()
            : <String>[];

    return StaffModel(
      id: document.id,
      pharmacyId:
          (data['pharmacyId'] ?? '').toString(),
      fullName:
          (data['fullName'] ?? '').toString(),
      email:
          (data['email'] ?? '').toString(),
      phone:
          (data['phone'] ?? '').toString(),
      role: 'staff',
      status:
          (data['status'] ?? 'active').toString(),
      permissions: permissions,
      createdAt:
          _timestampToDateTime(data['createdAt']),
      updatedAt:
          _timestampToDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'pharmacyId': pharmacyId,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'role': 'staff',
      'status': status,
      'permissions': permissions,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(updatedAt!),
    };
  }

  StaffModel copyWith({
    String? id,
    String? pharmacyId,
    String? fullName,
    String? email,
    String? phone,
    String? role,
    String? status,
    List<String>? permissions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StaffModel(
      id: id ?? this.id,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      status: status ?? this.status,
      permissions:
          permissions ?? this.permissions,
      createdAt:
          createdAt ?? this.createdAt,
      updatedAt:
          updatedAt ?? this.updatedAt,
    );
  }

  bool get isActive =>
      status == 'active';

  bool hasPermission(
    String permission,
  ) {
    return permissions.contains(permission);
  }

  static DateTime? _timestampToDateTime(
    dynamic value,
  ) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }
}