import 'package:cloud_firestore/cloud_firestore.dart';

class PharmacyModel {
  final String pharmacyId;
  final String ownerId;
  final String name;
  final String ownerName;
  final String phone;
  final String email;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PharmacyModel({
    required this.pharmacyId,
    required this.ownerId,
    required this.name,
    required this.ownerName,
    required this.phone,
    required this.email,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory PharmacyModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};

    return PharmacyModel(
      pharmacyId:
          (data['pharmacyId'] ?? document.id).toString(),
      ownerId: (data['ownerId'] ?? '').toString(),
      name: (data['name'] ?? '').toString(),
      ownerName: (data['ownerName'] ?? '').toString(),
      phone: (data['phone'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      status: (data['status'] ?? 'active').toString(),
      createdAt: _timestampToDateTime(data['createdAt']),
      updatedAt: _timestampToDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'pharmacyId': pharmacyId,
      'ownerId': ownerId,
      'name': name,
      'ownerName': ownerName,
      'phone': phone,
      'email': email,
      'status': status,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(updatedAt!),
    };
  }

  PharmacyModel copyWith({
    String? pharmacyId,
    String? ownerId,
    String? name,
    String? ownerName,
    String? phone,
    String? email,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PharmacyModel(
      pharmacyId: pharmacyId ?? this.pharmacyId,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      ownerName: ownerName ?? this.ownerName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
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