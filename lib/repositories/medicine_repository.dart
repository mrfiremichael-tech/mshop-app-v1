import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/medicine_model.dart';

class MedicineRepository {
  final FirebaseFirestore _firestore;

  MedicineRepository({
    FirebaseFirestore? firestore,
  }) : _firestore =
            firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _medicines(
    String pharmacyId,
  ) {
    return _firestore
        .collection('medicines');
  }

  Stream<List<MedicineModel>> watchMedicines(
    String pharmacyId,
  ) {
    return _medicines(pharmacyId)
        .where(
          'pharmacyId',
          isEqualTo: pharmacyId,
        )
        .snapshots()
        .map(
          (snapshot) {
            final medicines = snapshot.docs
                .map(
                  MedicineModel.fromFirestore,
                )
                .toList();

            medicines.sort(
              (a, b) => a.name
                  .toLowerCase()
                  .compareTo(
                    b.name.toLowerCase(),
                  ),
            );

            return medicines;
          },
        );
  }

  Future<List<MedicineModel>> getMedicines(
    String pharmacyId,
  ) async {
    final snapshot = await _medicines(pharmacyId)
        .where(
          'pharmacyId',
          isEqualTo: pharmacyId,
        )
        .get();

    final medicines = snapshot.docs
        .map(
          MedicineModel.fromFirestore,
        )
        .toList();

    medicines.sort(
      (a, b) => a.name
          .toLowerCase()
          .compareTo(
            b.name.toLowerCase(),
          ),
    );

    return medicines;
  }

  Future<MedicineModel?> getMedicineById(
    String pharmacyId,
    String medicineId,
  ) async {
    final document = await _medicines(pharmacyId)
        .doc(medicineId)
        .get();

    if (!document.exists) {
      return null;
    }

    final data = document.data();

    if (data == null ||
        data['pharmacyId'] != pharmacyId) {
      return null;
    }

    return MedicineModel.fromFirestore(
      document,
    );
  }

  Future<String> addMedicine(
    MedicineModel medicine,
  ) async {
    final document =
        _medicines(medicine.pharmacyId).doc();

    final data = medicine.toFirestore();

    data['pharmacyId'] = medicine.pharmacyId;

    await document.set(data);

    return document.id;
  }

  Future<void> updateMedicine(
    MedicineModel medicine,
  ) async {
    final document = _medicines(
      medicine.pharmacyId,
    ).doc(medicine.id);

    final existing =
        await document.get();

    if (!existing.exists) {
      throw Exception(
        'Medicine not found.',
      );
    }

    final existingData =
        existing.data();

    if (existingData == null ||
        existingData['pharmacyId'] !=
            medicine.pharmacyId) {
      throw Exception(
        'Medicine does not belong to this pharmacy.',
      );
    }

    final data = medicine.toFirestore();

    data.remove('createdAt');

    data['updatedAt'] =
        FieldValue.serverTimestamp();

    await document.update(data);
  }

  Future<void> deleteMedicine({
    required String pharmacyId,
    required String medicineId,
  }) async {
    final document = _medicines(
      pharmacyId,
    ).doc(medicineId);

    final existing =
        await document.get();

    if (!existing.exists) {
      return;
    }

    final data = existing.data();

    if (data == null ||
        data['pharmacyId'] != pharmacyId) {
      throw Exception(
        'Medicine does not belong to this pharmacy.',
      );
    }

    await document.delete();
  }

  Future<void> increaseStock({
    required String pharmacyId,
    required String medicineId,
    required int quantity,
  }) async {
    if (quantity <= 0) {
      throw Exception(
        'Quantity must be greater than zero.',
      );
    }

    final document = _medicines(
      pharmacyId,
    ).doc(medicineId);

    final snapshot =
        await document.get();

    if (!snapshot.exists) {
      throw Exception(
        'Medicine not found.',
      );
    }

    final data = snapshot.data();

    if (data == null ||
        data['pharmacyId'] != pharmacyId) {
      throw Exception(
        'Medicine does not belong to this pharmacy.',
      );
    }

    final currentQuantity =
        _toInt(data['quantity']);

    await document.update({
      'quantity':
          currentQuantity + quantity,
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  Future<void> decreaseStock({
    required String pharmacyId,
    required String medicineId,
    required int quantity,
  }) async {
    if (quantity <= 0) {
      throw Exception(
        'Quantity must be greater than zero.',
      );
    }

    final document = _medicines(
      pharmacyId,
    ).doc(medicineId);

    final snapshot =
        await document.get();

    if (!snapshot.exists) {
      throw Exception(
        'Medicine not found.',
      );
    }

    final data = snapshot.data();

    if (data == null ||
        data['pharmacyId'] != pharmacyId) {
      throw Exception(
        'Medicine does not belong to this pharmacy.',
      );
    }

    final currentQuantity =
        _toInt(data['quantity']);

    if (currentQuantity < quantity) {
      throw Exception(
        'Insufficient stock.',
      );
    }

    await document.update({
      'quantity':
          currentQuantity - quantity,
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  Future<List<MedicineModel>> searchMedicines({
    required String pharmacyId,
    required String query,
  }) async {
    final medicines =
        await getMedicines(pharmacyId);

    final search =
        query.trim().toLowerCase();

    if (search.isEmpty) {
      return medicines;
    }

    return medicines.where(
      (medicine) {
        return medicine.name
                .toLowerCase()
                .contains(search) ||
            medicine.category
                .toLowerCase()
                .contains(search) ||
            medicine.barcode
                .toLowerCase()
                .contains(search) ||
            medicine.batchNumber
                .toLowerCase()
                .contains(search);
      },
    ).toList();
  }

  Future<MedicineModel?> findByBarcode({
    required String pharmacyId,
    required String barcode,
  }) async {
    final cleanBarcode =
        barcode.trim();

    if (cleanBarcode.isEmpty) {
      return null;
    }

    final snapshot = await _medicines(
      pharmacyId,
    )
        .where(
          'pharmacyId',
          isEqualTo: pharmacyId,
        )
        .where(
          'barcode',
          isEqualTo: cleanBarcode,
        )
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return MedicineModel.fromFirestore(
      snapshot.docs.first,
    );
  }

  Future<int> getTotalStock(
    String pharmacyId,
  ) async {
    final medicines =
        await getMedicines(pharmacyId);

    int total = 0;

    for (final medicine in medicines) {
      total += medicine.quantity;
    }

    return total;
  }

  Future<int> getLowStockCount(
    String pharmacyId,
  ) async {
    final medicines =
        await getMedicines(pharmacyId);

    return medicines
        .where(
          (medicine) =>
              medicine.isLowStock,
        )
        .length;
  }

  Future<int> getExpiryAlertCount(
    String pharmacyId,
  ) async {
    final medicines =
        await getMedicines(pharmacyId);

    return medicines
        .where(
          (medicine) =>
              medicine.expiresWithin30Days,
        )
        .length;
  }

  int _toInt(dynamic value) {
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
}