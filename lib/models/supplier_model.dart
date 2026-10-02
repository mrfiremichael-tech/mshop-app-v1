import 'package:cloud_firestore/cloud_firestore.dart';

class SupplierModel {
  final String id;
  final String pharmacyId;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SupplierModel({
    required this.id,
    required this.pharmacyId,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory SupplierModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};

    return SupplierModel(
      id: document.id,
      pharmacyId: (data['pharmacyId'] ?? '').toString(),
      name: (data['name'] ?? '').toString(),
      phone: (data['phone'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      address: (data['address'] ?? '').toString(),
      notes: (data['notes'] ?? '').toString(),
      createdAt: _timestampToDateTime(data['createdAt']),
      updatedAt: _timestampToDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'pharmacyId': pharmacyId,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'notes': notes,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(updatedAt!),
    };
  }

  SupplierModel copyWith({
    String? id,
    String? pharmacyId,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SupplierModel(
      id: id ?? this.id,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      notes: notes ?? this.notes,
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