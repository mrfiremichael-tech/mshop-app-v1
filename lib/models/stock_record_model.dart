import 'package:cloud_firestore/cloud_firestore.dart';

class StockRecordModel {
  final String id;
  final String pharmacyId;
  final String medicineId;
  final String medicineName;
  final String supplierId;
  final String supplierName;
  final int quantity;
  final double unitCost;
  final double totalCost;
  final DateTime stockDate;
  final String addedByUid;
  final String addedByName;
  final String batchNumber;
  final DateTime? expiryDate;
  final DateTime? createdAt;

  const StockRecordModel({
    required this.id,
    required this.pharmacyId,
    required this.medicineId,
    required this.medicineName,
    required this.supplierId,
    required this.supplierName,
    required this.quantity,
    required this.unitCost,
    required this.totalCost,
    required this.stockDate,
    required this.addedByUid,
    required this.addedByName,
    required this.batchNumber,
    required this.expiryDate,
    required this.createdAt,
  });

  factory StockRecordModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return StockRecordModel(
      id: doc.id,
      pharmacyId: data['pharmacyId'] as String? ?? '',
      medicineId: data['medicineId'] as String? ?? '',
      medicineName: data['medicineName'] as String? ?? '',
      supplierId: data['supplierId'] as String? ?? '',
      supplierName: data['supplierName'] as String? ?? '',
      quantity: (data['quantity'] as num?)?.toInt() ?? 0,
      unitCost: (data['unitCost'] as num?)?.toDouble() ?? 0,
      totalCost: (data['totalCost'] as num?)?.toDouble() ?? 0,
      stockDate: _dateFromValue(data['stockDate']) ?? DateTime.now(),
      addedByUid: data['addedByUid'] as String? ?? '',
      addedByName: data['addedByName'] as String? ?? '',
      batchNumber: data['batchNumber'] as String? ?? '',
      expiryDate: _dateFromValue(data['expiryDate']),
      createdAt: _dateFromValue(data['createdAt']),
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
      'stockDate': Timestamp.fromDate(stockDate),
      'addedByUid': addedByUid,
      'addedByName': addedByName,
      'batchNumber': batchNumber,
      'expiryDate': expiryDate == null
          ? null
          : Timestamp.fromDate(expiryDate!),
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
    };
  }

  StockRecordModel copyWith({
    String? id,
    String? pharmacyId,
    String? medicineId,
    String? medicineName,
    String? supplierId,
    String? supplierName,
    int? quantity,
    double? unitCost,
    double? totalCost,
    DateTime? stockDate,
    String? addedByUid,
    String? addedByName,
    String? batchNumber,
    DateTime? expiryDate,
    DateTime? createdAt,
  }) {
    return StockRecordModel(
      id: id ?? this.id,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      medicineId: medicineId ?? this.medicineId,
      medicineName: medicineName ?? this.medicineName,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
      totalCost: totalCost ?? this.totalCost,
      stockDate: stockDate ?? this.stockDate,
      addedByUid: addedByUid ?? this.addedByUid,
      addedByName: addedByName ?? this.addedByName,
      batchNumber: batchNumber ?? this.batchNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static DateTime? _dateFromValue(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }
}