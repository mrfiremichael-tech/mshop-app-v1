import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/supplier_model.dart';

class SupplierRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _suppliers() {
    return _firestore.collection('suppliers');
  }

  Stream<List<SupplierModel>> watchSuppliers(String pharmacyId) {
    return _suppliers()
        .where('pharmacyId', isEqualTo: pharmacyId)
        .snapshots()
        .map((snapshot) {
      final suppliers = snapshot.docs
          .map(SupplierModel.fromFirestore)
          .toList();

      suppliers.sort(
        (a, b) => a.name.toLowerCase().compareTo(
              b.name.toLowerCase(),
            ),
      );

      return suppliers;
    });
  }

  Future<List<SupplierModel>> getSuppliers(String pharmacyId) async {
    final snapshot = await _suppliers()
        .where('pharmacyId', isEqualTo: pharmacyId)
        .get();

    final suppliers = snapshot.docs
        .map(SupplierModel.fromFirestore)
        .toList();

    suppliers.sort(
      (a, b) => a.name.toLowerCase().compareTo(
            b.name.toLowerCase(),
          ),
    );

    return suppliers;
  }

  Future<SupplierModel?> getSupplierById({
    required String pharmacyId,
    required String supplierId,
  }) async {
    final doc = await _suppliers().doc(supplierId).get();

    if (!doc.exists) {
      return null;
    }

    final supplier = SupplierModel.fromFirestore(doc);

    if (supplier.pharmacyId != pharmacyId) {
      return null;
    }

    return supplier;
  }

  Future<String> addSupplier(SupplierModel supplier) async {
    final doc = _suppliers().doc();

    final supplierToSave = supplier.copyWith(
      id: doc.id,
      createdAt: supplier.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await doc.set(supplierToSave.toFirestore());

    return doc.id;
  }

  Future<void> updateSupplier(SupplierModel supplier) async {
    if (supplier.id.isEmpty) {
      throw Exception('Supplier ID is required.');
    }

    final docRef = _suppliers().doc(supplier.id);
    final existing = await docRef.get();

    if (!existing.exists) {
      throw Exception('Supplier not found.');
    }

    final existingSupplier = SupplierModel.fromFirestore(existing);

    if (existingSupplier.pharmacyId != supplier.pharmacyId) {
      throw Exception('You cannot update this supplier.');
    }

    final updatedSupplier = supplier.copyWith(
      updatedAt: DateTime.now(),
    );

    await docRef.update(updatedSupplier.toFirestore());
  }

  Future<void> deleteSupplier({
    required String pharmacyId,
    required String supplierId,
  }) async {
    final docRef = _suppliers().doc(supplierId);
    final existing = await docRef.get();

    if (!existing.exists) {
      throw Exception('Supplier not found.');
    }

    final supplier = SupplierModel.fromFirestore(existing);

    if (supplier.pharmacyId != pharmacyId) {
      throw Exception('You cannot delete this supplier.');
    }

    await docRef.delete();
  }

  Future<List<SupplierModel>> searchSuppliers({
    required String pharmacyId,
    required String query,
  }) async {
    final suppliers = await getSuppliers(pharmacyId);

    final searchText = query.trim().toLowerCase();

    if (searchText.isEmpty) {
      return suppliers;
    }

    return suppliers.where((supplier) {
      return supplier.name.toLowerCase().contains(searchText) ||
          supplier.phone.toLowerCase().contains(searchText) ||
          supplier.email.toLowerCase().contains(searchText) ||
          supplier.address.toLowerCase().contains(searchText);
    }).toList();
  }

  Future<int> getSupplierCount(String pharmacyId) async {
    final snapshot = await _suppliers()
        .where('pharmacyId', isEqualTo: pharmacyId)
        .get();

    return snapshot.docs.length;
  }
}