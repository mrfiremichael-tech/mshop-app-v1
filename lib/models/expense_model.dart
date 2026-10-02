import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String id;
  final String pharmacyId;
  final String category;
  final String description;
  final double amount;
  final String paymentMethod;
  final String reference;
  final DateTime? expenseDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ExpenseModel({
    required this.id,
    required this.pharmacyId,
    required this.category,
    required this.description,
    required this.amount,
    required this.paymentMethod,
    required this.reference,
    this.expenseDate,
    this.createdAt,
    this.updatedAt,
  });

  factory ExpenseModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};

    return ExpenseModel(
      id: document.id,
      pharmacyId: (data['pharmacyId'] ?? '').toString(),
      category: (data['category'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      amount: _toDouble(data['amount']),
      paymentMethod: (data['paymentMethod'] ?? '').toString(),
      reference: (data['reference'] ?? '').toString(),
      expenseDate: _timestampToDateTime(data['expenseDate']),
      createdAt: _timestampToDateTime(data['createdAt']),
      updatedAt: _timestampToDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'pharmacyId': pharmacyId,
      'category': category,
      'description': description,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'reference': reference,
      'expenseDate': expenseDate == null
          ? null
          : Timestamp.fromDate(expenseDate!),
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(updatedAt!),
    };
  }

  ExpenseModel copyWith({
    String? id,
    String? pharmacyId,
    String? category,
    String? description,
    double? amount,
    String? paymentMethod,
    String? reference,
    DateTime? expenseDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      category: category ?? this.category,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      reference: reference ?? this.reference,
      expenseDate: expenseDate ?? this.expenseDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
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
