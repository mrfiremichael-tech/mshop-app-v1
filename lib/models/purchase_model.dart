import 'package:cloud_firestore/cloud_firestore.dart';

class PurchaseModel {
  final String id;
  final String pharmacyId;
  final String medicineId;
  final String medicineName;
  final String supplierId;
  final String supplierName;
  final int quantity;
  final double unitCost;
  final double totalCost;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PurchaseModel({
    required this.id,
    required this.pharmacyId,
    required this.medicineId,
    required this.medicineName,
    required this.supplierId,
    required this.supplierName,
    required this.quantity,
    required this.unitCost,
    required this.totalCost,
    this.createdAt,
    this.updatedAt,
  });

  factory PurchaseModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};

    return PurchaseModel(
      id: document.id,
      pharmacyId: (data['pharmacyId'] ?? '').toString(),
      medicineId: (data['medicineId'] ?? '').toString(),
      medicineName: (data['medicineName'] ?? '').toString(),
      supplierId: (data['supplierId'] ?? '').toString(),
      supplierName: (data['supplierName'] ?? '').toString(),
      quantity: _toInt(data['quantity']),
      unitCost: _toDouble(data['unitCost']),
      totalCost: _toDouble(data['totalCost']),
      createdAt: _timestampToDateTime(data['createdAt']),
      updatedAt: _timestampToDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'pharmacyId': pharmacyId,
      'medicineId': medicineId,
      'medicineName': medicineName,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'quantity': quantity,
      'unitCost': unitCost,
      'totalCost': totalCost,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(updatedAt!),
    };
  }

  PurchaseModel copyWith({
    String? id,
    String? pharmacyId,
    String? medicineId,
    String? medicineName,
    String? supplierId,
    String? supplierName,
    int? quantity,
    double? unitCost,
    double? totalCost,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PurchaseModel(
      id: id ?? this.id,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      medicineId: medicineId ?? this.medicineId,
      medicineName: medicineName ?? this.medicineName,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
      totalCost: totalCost ?? this.totalCost,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static int _toInt(dynamic value) {
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

  static double _toDouble(dynamic value) {
    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
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