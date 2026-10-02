import 'package:cloud_firestore/cloud_firestore.dart';

class MedicineModel {
  final String id;
  final String pharmacyId;
  final String name;
  final String category;
  final String productType;
  final String unit;
  final int quantity;
  final double buyingPrice;
  final double sellingPrice;
  final String barcode;
  final String batchNumber;
  final DateTime? expiryDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MedicineModel({
    required this.id,
    required this.pharmacyId,
    required this.name,
    required this.category,
    this.productType = 'medicine',
    required this.unit,
    required this.quantity,
    required this.buyingPrice,
    required this.sellingPrice,
    required this.barcode,
    required this.batchNumber,
    this.expiryDate,
    this.createdAt,
    this.updatedAt,
  });

  factory MedicineModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};

    return MedicineModel(
      id: snapshot.id,
      pharmacyId: data['pharmacyId']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      category: data['category']?.toString() ?? '',
      productType:
          data['productType']?.toString().isNotEmpty == true
              ? data['productType'].toString()
              : 'medicine',
      unit: data['unit']?.toString() ?? '',
      quantity: _toInt(data['quantity']),
      buyingPrice: _toDouble(data['buyingPrice']),
      sellingPrice: _toDouble(data['sellingPrice']),
      barcode: data['barcode']?.toString() ?? '',
      batchNumber: data['batchNumber']?.toString() ?? '',
      expiryDate: _toDateTime(data['expiryDate']),
      createdAt: _toDateTime(data['createdAt']),
      updatedAt: _toDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'pharmacyId': pharmacyId,
      'name': name,
      'category': category,
      'productType': productType,
      'unit': unit,
      'quantity': quantity,
      'buyingPrice': buyingPrice,
      'sellingPrice': sellingPrice,
      'barcode': barcode,
      'batchNumber': batchNumber,
      'expiryDate':
          expiryDate == null
              ? null
              : Timestamp.fromDate(expiryDate!),
      'createdAt':
          createdAt == null
              ? null
              : Timestamp.fromDate(createdAt!),
      'updatedAt':
          updatedAt == null
              ? null
              : Timestamp.fromDate(updatedAt!),
    };
  }

  double get totalStockValue {
    return quantity * buyingPrice;
  }

  bool get isLowStock {
    return quantity > 0 && quantity <= 10;
  }

  bool get isOutOfStock {
    return quantity <= 0;
  }

  // ---------------------------------------------------------------------------
  // EXPIRY
  // ---------------------------------------------------------------------------

  DateTime? get expiryDay {
    if (expiryDate == null) {
      return null;
    }

    return DateTime(
      expiryDate!.year,
      expiryDate!.month,
      expiryDate!.day,
    );
  }

  DateTime get today {
    final now = DateTime.now();

    return DateTime(
      now.year,
      now.month,
      now.day,
    );
  }

  bool get isExpired {
    final expiry = expiryDay;

    if (expiry == null) {
      return false;
    }

    return expiry.isBefore(today);
  }

  bool get expiresWithin30Days {
    final expiry = expiryDay;

    if (expiry == null) {
      return false;
    }

    if (expiry.isBefore(today)) {
      return false;
    }

    final difference =
        expiry.difference(today).inDays;

    return difference >= 0 && difference <= 30;
  }

  bool get hasExpiryAlert {
    return isExpired || expiresWithin30Days;
  }

  int? get daysUntilExpiry {
    final expiry = expiryDay;

    if (expiry == null) {
      return null;
    }

    return expiry.difference(today).inDays;
  }

  String get expiryStatus {
    if (expiryDate == null) {
      return 'No expiry date';
    }

    if (isExpired) {
      return 'Expired';
    }

    if (expiresWithin30Days) {
      return 'Expires soon';
    }

    return 'Good';
  }

  bool get isMedicine {
    return productType == 'medicine';
  }

  bool get isOtherPharmacyItem {
    return productType == 'other';
  }

  MedicineModel copyWith({
    String? id,
    String? pharmacyId,
    String? name,
    String? category,
    String? productType,
    String? unit,
    int? quantity,
    double? buyingPrice,
    double? sellingPrice,
    String? barcode,
    String? batchNumber,
    DateTime? expiryDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MedicineModel(
      id: id ?? this.id,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      name: name ?? this.name,
      category: category ?? this.category,
      productType: productType ?? this.productType,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      buyingPrice: buyingPrice ?? this.buyingPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      barcode: barcode ?? this.barcode,
      batchNumber: batchNumber ?? this.batchNumber,
      expiryDate: expiryDate ?? this.expiryDate,
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

  static DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      final parsed = DateTime.tryParse(value);

      if (parsed != null) {
        return parsed;
      }
    }

    return null;
  }
}