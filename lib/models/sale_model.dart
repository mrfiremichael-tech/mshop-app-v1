import 'package:cloud_firestore/cloud_firestore.dart';

class SaleModel {
  final String id;
  final String pharmacyId;
  final String staffId;
  final String medicineId;
  final String medicineName;
  final String customerId;
  final String customerName;
  final int quantity;
  final double unitPrice;
  final double totalAmount;
  final double profit;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SaleModel({
    required this.id,
    required this.pharmacyId,
    this.staffId = '',
    required this.medicineId,
    required this.medicineName,
    required this.customerId,
    required this.customerName,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    required this.profit,
    this.createdAt,
    this.updatedAt,
  });

  factory SaleModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};

    return SaleModel(
      id: document.id,
      pharmacyId: (data['pharmacyId'] ?? '').toString(),
      staffId: (data['staffId'] ?? '').toString(),
      medicineId: (data['medicineId'] ?? '').toString(),
      medicineName: (data['medicineName'] ?? '').toString(),
      customerId: (data['customerId'] ?? '').toString(),
      customerName: (data['customerName'] ?? '').toString(),
      quantity: _toInt(data['quantity']),
      unitPrice: _toDouble(data['unitPrice']),
      totalAmount: _toDouble(data['totalAmount']),
      profit: _toDouble(data['profit']),
      createdAt: _timestampToDateTime(data['createdAt']),
      updatedAt: _timestampToDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'pharmacyId': pharmacyId,
      'staffId': staffId,
      'medicineId': medicineId,
      'medicineName': medicineName,
      'customerId': customerId,
      'customerName': customerName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalAmount': totalAmount,
      'profit': profit,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(updatedAt!),
    };
  }

  SaleModel copyWith({
    String? id,
    String? pharmacyId,
    String? staffId,
    String? medicineId,
    String? medicineName,
    String? customerId,
    String? customerName,
    int? quantity,
    double? unitPrice,
    double? totalAmount,
    double? profit,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SaleModel(
      id: id ?? this.id,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      staffId: staffId ?? this.staffId,
      medicineId: medicineId ?? this.medicineId,
      medicineName: medicineName ?? this.medicineName,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalAmount: totalAmount ?? this.totalAmount,
      profit: profit ?? this.profit,
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
