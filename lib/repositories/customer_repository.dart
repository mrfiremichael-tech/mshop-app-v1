import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/customer_model.dart';

class CustomerRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _customers() {
    return _firestore.collection('customers');
  }

  Stream<List<CustomerModel>> watchCustomers(String pharmacyId) {
    return _customers()
        .where('pharmacyId', isEqualTo: pharmacyId)
        .snapshots()
        .map((snapshot) {
      final customers = snapshot.docs
          .map(CustomerModel.fromFirestore)
          .toList();

      customers.sort((a, b) => a.name.toLowerCase().compareTo(
            b.name.toLowerCase(),
          ));

      return customers;
    });
  }

  Future<List<CustomerModel>> getCustomers(String pharmacyId) async {
    final snapshot = await _customers()
        .where('pharmacyId', isEqualTo: pharmacyId)
        .get();

    final customers = snapshot.docs
        .map(CustomerModel.fromFirestore)
        .toList();

    customers.sort((a, b) => a.name.toLowerCase().compareTo(
          b.name.toLowerCase(),
        ));

    return customers;
  }

  Future<CustomerModel?> getCustomerById({
    required String pharmacyId,
    required String customerId,
  }) async {
    final doc = await _customers().doc(customerId).get();

    if (!doc.exists) {
      return null;
    }

    final customer = CustomerModel.fromFirestore(doc);

    if (customer.pharmacyId != pharmacyId) {
      return null;
    }

    return customer;
  }

  Future<String> addCustomer(CustomerModel customer) async {
    final doc = _customers().doc();

    final customerToSave = customer.copyWith(
      id: doc.id,
      createdAt: customer.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await doc.set(customerToSave.toFirestore());

    return doc.id;
  }

  Future<void> updateCustomer(CustomerModel customer) async {
    if (customer.id.isEmpty) {
      throw Exception('Customer ID is required.');
    }

    final docRef = _customers().doc(customer.id);
    final existing = await docRef.get();

    if (!existing.exists) {
      throw Exception('Customer not found.');
    }

    final existingCustomer = CustomerModel.fromFirestore(existing);

    if (existingCustomer.pharmacyId != customer.pharmacyId) {
      throw Exception('You cannot update this customer.');
    }

    final updatedCustomer = customer.copyWith(
      updatedAt: DateTime.now(),
    );

    await docRef.update(updatedCustomer.toFirestore());
  }

  Future<void> deleteCustomer({
    required String pharmacyId,
    required String customerId,
  }) async {
    final docRef = _customers().doc(customerId);
    final existing = await docRef.get();

    if (!existing.exists) {
      throw Exception('Customer not found.');
    }

    final customer = CustomerModel.fromFirestore(existing);

    if (customer.pharmacyId != pharmacyId) {
      throw Exception('You cannot delete this customer.');
    }

    await docRef.delete();
  }

  Future<List<CustomerModel>> searchCustomers({
    required String pharmacyId,
    required String query,
  }) async {
    final customers = await getCustomers(pharmacyId);

    final searchText = query.trim().toLowerCase();

    if (searchText.isEmpty) {
      return customers;
    }

    return customers.where((customer) {
      return customer.name.toLowerCase().contains(searchText) ||
          customer.phone.toLowerCase().contains(searchText) ||
          customer.email.toLowerCase().contains(searchText);
    }).toList();
  }

  Future<int> getCustomerCount(String pharmacyId) async {
    final snapshot = await _customers()
        .where('pharmacyId', isEqualTo: pharmacyId)
        .get();

    return snapshot.docs.length;
  }
}