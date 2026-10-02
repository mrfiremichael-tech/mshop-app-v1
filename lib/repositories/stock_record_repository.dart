import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/stock_record_model.dart';

class StockRecordRepository {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(
    String pharmacyId,
  ) {
    return _firestore
        .collection('pharmacies')
        .doc(pharmacyId)
        .collection('stock_records');
  }

  Stream<List<StockRecordModel>> watchStockRecords(
    String pharmacyId,
  ) {
    return _collection(pharmacyId)
        .orderBy('stockDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                StockRecordModel.fromFirestore,
              )
              .toList(),
        );
  }

  Future<List<StockRecordModel>> getStockRecords(
    String pharmacyId,
  ) async {
    final snapshot = await _collection(pharmacyId)
        .orderBy('stockDate', descending: true)
        .get();

    return snapshot.docs
        .map(
          StockRecordModel.fromFirestore,
        )
        .toList();
  }

  Future<StockRecordModel?> getStockRecord(
    String pharmacyId,
    String recordId,
  ) async {
    final doc = await _collection(pharmacyId)
        .doc(recordId)
        .get();

    if (!doc.exists) {
      return null;
    }

    return StockRecordModel.fromFirestore(doc);
  }

  Future<String> addStockRecord(
    StockRecordModel record,
  ) async {
    final doc = await _collection(record.pharmacyId)
        .add(record.toFirestore());

    return doc.id;
  }

  Future<void> updateStockRecord(
    StockRecordModel record,
  ) async {
    await _collection(record.pharmacyId)
        .doc(record.id)
        .update(record.toFirestore());
  }

  Future<void> deleteStockRecord(
    String pharmacyId,
    String recordId,
  ) async {
    await _collection(pharmacyId)
        .doc(recordId)
        .delete();
  }

  Future<List<StockRecordModel>> getMedicineStockHistory(
    String pharmacyId,
    String medicineId,
  ) async {
    final snapshot = await _collection(pharmacyId)
        .where('medicineId', isEqualTo: medicineId)
        .get();

    final records = snapshot.docs
        .map(
          StockRecordModel.fromFirestore,
        )
        .toList();

    records.sort(
      (a, b) => b.stockDate.compareTo(a.stockDate),
    );

    return records;
  }

  Future<List<StockRecordModel>> getSupplierStockHistory(
    String pharmacyId,
    String supplierId,
  ) async {
    final snapshot = await _collection(pharmacyId)
        .where('supplierId', isEqualTo: supplierId)
        .get();

    final records = snapshot.docs
        .map(
          StockRecordModel.fromFirestore,
        )
        .toList();

    records.sort(
      (a, b) => b.stockDate.compareTo(a.stockDate),
    );

    return records;
  }

  Future<double> getTotalStockPurchases(
    String pharmacyId,
  ) async {
    final records = await getStockRecords(pharmacyId);

    return records.fold<double>(
      0,
      (total, record) => total + record.totalCost,
    );
  }

  Future<int> getTotalStockQuantity(
    String pharmacyId,
  ) async {
    final records = await getStockRecords(pharmacyId);

    return records.fold<int>(
      0,
      (total, record) => total + record.quantity,
    );
  }
}