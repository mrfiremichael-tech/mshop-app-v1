import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/purchase_model.dart';

class PurchaseRepository {
  final FirebaseFirestore _firestore;

  PurchaseRepository({
    FirebaseFirestore? firestore,
  }) : _firestore =
            firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _purchases() {
    return _firestore.collection('purchases');
  }

  Stream<List<PurchaseModel>> watchPurchases(
    String pharmacyId,
  ) {
    return _purchases()
        .where(
          'pharmacyId',
          isEqualTo: pharmacyId,
        )
        .snapshots()
        .map((snapshot) {
      final purchases = snapshot.docs
          .map(
            PurchaseModel.fromFirestore,
          )
          .toList();

      purchases.sort((a, b) {
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

      return purchases;
    });
  }

  Future<List<PurchaseModel>> getPurchases(
    String pharmacyId,
  ) async {
    final snapshot = await _purchases()
        .where(
          'pharmacyId',
          isEqualTo: pharmacyId,
        )
        .get();

    final purchases = snapshot.docs
        .map(
          PurchaseModel.fromFirestore,
        )
        .toList();

    purchases.sort((a, b) {
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

    return purchases;
  }

  Future<String> addPurchase(
    PurchaseModel purchase,
  ) async {
    if (purchase.quantity <= 0) {
      throw Exception(
        'Purchase quantity must be greater than zero.',
      );
    }

    if (purchase.unitCost < 0) {
      throw Exception(
        'Unit cost cannot be negative.',
      );
    }

    final document = _purchases().doc();

    final data = purchase.toFirestore();

    data['pharmacyId'] = purchase.pharmacyId;

    await document.set(data);

    return document.id;
  }

  Future<PurchaseModel?> getPurchaseById(
    String pharmacyId,
    String purchaseId,
  ) async {
    final document =
        await _purchases().doc(purchaseId).get();

    if (!document.exists) {
      return null;
    }

    final data = document.data();

    if (data == null ||
        data['pharmacyId'] != pharmacyId) {
      return null;
    }

    return PurchaseModel.fromFirestore(
      document,
    );
  }

  Future<double> getTotalPurchases(
    String pharmacyId,
  ) async {
    final purchases =
        await getPurchases(pharmacyId);

    double total = 0;

    for (final purchase in purchases) {
      total += purchase.totalCost;
    }

    return total;
  }

  Future<double> getTodayPurchases(
    String pharmacyId,
  ) async {
    final purchases =
        await getPurchases(pharmacyId);

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

    for (final purchase in purchases) {
      final createdAt = purchase.createdAt;

      if (createdAt == null) {
        continue;
      }

      final isToday =
          !createdAt.isBefore(startOfDay) &&
          createdAt.isBefore(endOfDay);

      if (isToday) {
        total += purchase.totalCost;
      }
    }

    return total;
  }

  Future<List<PurchaseModel>> getPurchasesForMedicine({
    required String pharmacyId,
    required String medicineId,
  }) async {
    final purchases =
        await getPurchases(pharmacyId);

    return purchases
        .where(
          (purchase) =>
              purchase.medicineId == medicineId,
        )
        .toList();
  }

  Future<List<PurchaseModel>> getPurchasesForSupplier({
    required String pharmacyId,
    required String supplierId,
  }) async {
    final purchases =
        await getPurchases(pharmacyId);

    return purchases
        .where(
          (purchase) =>
              purchase.supplierId == supplierId,
        )
        .toList();
  }
}