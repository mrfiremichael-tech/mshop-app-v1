import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/sale_model.dart';

class SaleRepository {
  final FirebaseFirestore _firestore;

  SaleRepository({
    FirebaseFirestore? firestore,
  }) : _firestore =
            firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _sales() {
    return _firestore.collection('sales');
  }

  // ============================================================
  // SALES
  // OWNER  -> SALES ZOTE ZA PHARMACY
  // STAFF  -> MAUZO YAKE TU
  // ============================================================

  Stream<List<SaleModel>> watchSales(
    String pharmacyId,
  ) async* {
    final currentUser =
        FirebaseAuth.instance.currentUser;

    Query<Map<String, dynamic>> query = _sales().where(
      'pharmacyId',
      isEqualTo: pharmacyId,
    );

    if (currentUser != null) {
      final userSnapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final role =
          userSnapshot.data()?['role']?.toString();

      if (role == 'staff') {
        query = query.where(
          'staffId',
          isEqualTo: currentUser.uid,
        );
      }
    }

    yield* query.snapshots().map((snapshot) {
      final sales = snapshot.docs
          .map(
            SaleModel.fromFirestore,
          )
          .toList();

      _sortByNewest(sales);

      return sales;
    });
  }

  Future<List<SaleModel>> getSales(
    String pharmacyId,
  ) async {
    final snapshot = await _sales()
        .where(
          'pharmacyId',
          isEqualTo: pharmacyId,
        )
        .get();

    final sales = snapshot.docs
        .map(
          SaleModel.fromFirestore,
        )
        .toList();

    _sortByNewest(sales);

    return sales;
  }

  // ============================================================
  // STAFF - OWN SALES ONLY
  // ============================================================

  Stream<List<SaleModel>> watchSalesForStaff({
    required String pharmacyId,
    required String staffId,
  }) {
    return _sales()
        .where(
          'pharmacyId',
          isEqualTo: pharmacyId,
        )
        .where(
          'staffId',
          isEqualTo: staffId,
        )
        .snapshots()
        .map((snapshot) {
      final sales = snapshot.docs
          .map(
            SaleModel.fromFirestore,
          )
          .toList();

      _sortByNewest(sales);

      return sales;
    });
  }

  Future<List<SaleModel>> getSalesForStaff({
    required String pharmacyId,
    required String staffId,
  }) async {
    final snapshot = await _sales()
        .where(
          'pharmacyId',
          isEqualTo: pharmacyId,
        )
        .where(
          'staffId',
          isEqualTo: staffId,
        )
        .get();

    final sales = snapshot.docs
        .map(
          SaleModel.fromFirestore,
        )
        .toList();

    _sortByNewest(sales);

    return sales;
  }

  Future<List<SaleModel>> getSalesForStaffBetweenDates({
    required String pharmacyId,
    required String staffId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final sales = await getSalesForStaff(
      pharmacyId: pharmacyId,
      staffId: staffId,
    );

    return sales.where((sale) {
      final createdAt = sale.createdAt;

      if (createdAt == null) {
        return false;
      }

      return !createdAt.isBefore(startDate) &&
          createdAt.isBefore(endDate);
    }).toList();
  }

  Future<SaleModel?> getSaleById(
    String pharmacyId,
    String saleId,
  ) async {
    final document =
        await _sales().doc(saleId).get();

    if (!document.exists) {
      return null;
    }

    final data = document.data();

    if (data == null ||
        data['pharmacyId'] != pharmacyId) {
      return null;
    }

    return SaleModel.fromFirestore(
      document,
    );
  }

  Future<String> addSale(
    SaleModel sale,
  ) async {
    if (sale.quantity <= 0) {
      throw Exception(
        'Sale quantity must be greater than zero.',
      );
    }

    if (sale.unitPrice < 0) {
      throw Exception(
        'Unit price cannot be negative.',
      );
    }

    final document = _sales().doc();

    final data = sale.toFirestore();

    data['pharmacyId'] = sale.pharmacyId;

    await document.set(data);

    return document.id;
  }

  Future<double> getTotalSales(
    String pharmacyId,
  ) async {
    final sales =
        await getSales(pharmacyId);

    double total = 0;

    for (final sale in sales) {
      total += sale.totalAmount;
    }

    return total;
  }

  Future<double> getTotalProfit(
    String pharmacyId,
  ) async {
    final sales =
        await getSales(pharmacyId);

    double total = 0;

    for (final sale in sales) {
      total += sale.profit;
    }

    return total;
  }

  Future<double> getTodaySales(
    String pharmacyId,
  ) async {
    final sales =
        await getSales(pharmacyId);

    final now = DateTime.now();

    final startOfDay = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final endOfDay = startOfDay.add(
      const Duration(days: 1),
    );

    double total = 0;

    for (final sale in sales) {
      final createdAt = sale.createdAt;

      if (createdAt == null) {
        continue;
      }

      final isToday =
          !createdAt.isBefore(startOfDay) &&
          createdAt.isBefore(endOfDay);

      if (isToday) {
        total += sale.totalAmount;
      }
    }

    return total;
  }

  Future<double> getTodayProfit(
    String pharmacyId,
  ) async {
    final sales =
        await getSales(pharmacyId);

    final now = DateTime.now();

    final startOfDay = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final endOfDay = startOfDay.add(
      const Duration(days: 1),
    );

    double total = 0;

    for (final sale in sales) {
      final createdAt = sale.createdAt;

      if (createdAt == null) {
        continue;
      }

      final isToday =
          !createdAt.isBefore(startOfDay) &&
          createdAt.isBefore(endOfDay);

      if (isToday) {
        total += sale.profit;
      }
    }

    return total;
  }

  Future<double> getTotalSalesForStaff({
    required String pharmacyId,
    required String staffId,
  }) async {
    final sales = await getSalesForStaff(
      pharmacyId: pharmacyId,
      staffId: staffId,
    );

    double total = 0;

    for (final sale in sales) {
      total += sale.totalAmount;
    }

    return total;
  }

  Future<double> getTotalProfitForStaff({
    required String pharmacyId,
    required String staffId,
  }) async {
    final sales = await getSalesForStaff(
      pharmacyId: pharmacyId,
      staffId: staffId,
    );

    double total = 0;

    for (final sale in sales) {
      total += sale.profit;
    }

    return total;
  }

  Future<double> getTodaySalesForStaff({
    required String pharmacyId,
    required String staffId,
  }) async {
    final sales = await getSalesForStaff(
      pharmacyId: pharmacyId,
      staffId: staffId,
    );

    final now = DateTime.now();

    final startOfDay = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final endOfDay = startOfDay.add(
      const Duration(days: 1),
    );

    double total = 0;

    for (final sale in sales) {
      final createdAt = sale.createdAt;

      if (createdAt == null) {
        continue;
      }

      if (!createdAt.isBefore(startOfDay) &&
          createdAt.isBefore(endOfDay)) {
        total += sale.totalAmount;
      }
    }

    return total;
  }

  Future<double> getTodayProfitForStaff({
    required String pharmacyId,
    required String staffId,
  }) async {
    final sales = await getSalesForStaff(
      pharmacyId: pharmacyId,
      staffId: staffId,
    );

    final now = DateTime.now();

    final startOfDay = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final endOfDay = startOfDay.add(
      const Duration(days: 1),
    );

    double total = 0;

    for (final sale in sales) {
      final createdAt = sale.createdAt;

      if (createdAt == null) {
        continue;
      }

      if (!createdAt.isBefore(startOfDay) &&
          createdAt.isBefore(endOfDay)) {
        total += sale.profit;
      }
    }

    return total;
  }

  Future<List<SaleModel>> getSalesForMedicine({
    required String pharmacyId,
    required String medicineId,
  }) async {
    final sales =
        await getSales(pharmacyId);

    return sales
        .where(
          (sale) =>
              sale.medicineId == medicineId,
        )
        .toList();
  }

  Future<List<SaleModel>> getSalesForCustomer({
    required String pharmacyId,
    required String customerId,
  }) async {
    final sales =
        await getSales(pharmacyId);

    return sales
        .where(
          (sale) =>
              sale.customerId == customerId,
        )
        .toList();
  }

  Future<List<SaleModel>> getSalesBetweenDates({
    required String pharmacyId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final sales =
        await getSales(pharmacyId);

    return sales.where((sale) {
      final createdAt = sale.createdAt;

      if (createdAt == null) {
        return false;
      }

      return !createdAt.isBefore(startDate) &&
          createdAt.isBefore(endDate);
    }).toList();
  }

  void _sortByNewest(
    List<SaleModel> sales,
  ) {
    sales.sort((a, b) {
      final aDate = a.createdAt;
      final bDate = b.createdAt;

      if (aDate == null && bDate == null) {
        return 0;
      }

      if (aDate == null) {
        return 1;
      }

      if (bDate == null) {
        return -1;
      }

      return bDate.compareTo(aDate);
    });
  }
}
