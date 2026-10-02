import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/expense_model.dart';

class ExpenseRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _expenses() {
    return _firestore.collection('expenses');
  }

  Stream<List<ExpenseModel>> watchExpenses(String pharmacyId) {
    return _expenses()
        .where('pharmacyId', isEqualTo: pharmacyId)
        .snapshots()
        .map((snapshot) {
      final expenses = snapshot.docs
          .map(ExpenseModel.fromFirestore)
          .toList();

      expenses.sort((a, b) {
        final dateA = a.expenseDate ?? DateTime(1970);
        final dateB = b.expenseDate ?? DateTime(1970);

        return dateB.compareTo(dateA);
      });

      return expenses;
    });
  }

  Future<List<ExpenseModel>> getExpenses(String pharmacyId) async {
    final snapshot = await _expenses()
        .where('pharmacyId', isEqualTo: pharmacyId)
        .get();

    final expenses = snapshot.docs
        .map(ExpenseModel.fromFirestore)
        .toList();

    expenses.sort((a, b) {
      final dateA = a.expenseDate ?? DateTime(1970);
      final dateB = b.expenseDate ?? DateTime(1970);

      return dateB.compareTo(dateA);
    });

    return expenses;
  }

  Future<ExpenseModel?> getExpenseById({
    required String pharmacyId,
    required String expenseId,
  }) async {
    final doc = await _expenses().doc(expenseId).get();

    if (!doc.exists) {
      return null;
    }

    final expense = ExpenseModel.fromFirestore(doc);

    if (expense.pharmacyId != pharmacyId) {
      return null;
    }

    return expense;
  }

  Future<String> addExpense(ExpenseModel expense) async {
    final doc = _expenses().doc();

    final expenseToSave = expense.copyWith(
      id: doc.id,
      createdAt: expense.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await doc.set(expenseToSave.toFirestore());

    return doc.id;
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    if (expense.id.isEmpty) {
      throw Exception('Expense ID is required.');
    }

    final docRef = _expenses().doc(expense.id);
    final existing = await docRef.get();

    if (!existing.exists) {
      throw Exception('Expense not found.');
    }

    final existingExpense = ExpenseModel.fromFirestore(existing);

    if (existingExpense.pharmacyId != expense.pharmacyId) {
      throw Exception('You cannot update this expense.');
    }

    final updatedExpense = expense.copyWith(
      updatedAt: DateTime.now(),
    );

    await docRef.update(updatedExpense.toFirestore());
  }

  Future<void> deleteExpense({
    required String pharmacyId,
    required String expenseId,
  }) async {
    final docRef = _expenses().doc(expenseId);
    final existing = await docRef.get();

    if (!existing.exists) {
      throw Exception('Expense not found.');
    }

    final expense = ExpenseModel.fromFirestore(existing);

    if (expense.pharmacyId != pharmacyId) {
      throw Exception('You cannot delete this expense.');
    }

    await docRef.delete();
  }

  Future<List<ExpenseModel>> getExpensesBetweenDates({
    required String pharmacyId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final expenses = await getExpenses(pharmacyId);

    return expenses.where((expense) {
      final date = expense.expenseDate;

      if (date == null) {
        return false;
      }

      return !date.isBefore(startDate) && !date.isAfter(endDate);
    }).toList();
  }

  Future<double> getTotalExpenses(String pharmacyId) async {
    final expenses = await getExpenses(pharmacyId);

    return expenses.fold<double>(
      0,
      (total, expense) => total + expense.amount,
    );
  }

  Future<double> getTodayExpenses(String pharmacyId) async {
    final now = DateTime.now();

    final startOfDay = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final endOfDay = startOfDay.add(
      const Duration(days: 1),
    );

    final expenses = await getExpensesBetweenDates(
      pharmacyId: pharmacyId,
      startDate: startOfDay,
      endDate: endOfDay.subtract(
        const Duration(microseconds: 1),
      ),
    );

    return expenses.fold<double>(
      0,
      (total, expense) => total + expense.amount,
    );
  }

  Future<List<ExpenseModel>> getExpensesByCategory({
    required String pharmacyId,
    required String category,
  }) async {
    final expenses = await getExpenses(pharmacyId);

    return expenses.where((expense) {
      return expense.category.toLowerCase() == category.toLowerCase();
    }).toList();
  }

  Future<List<ExpenseModel>> searchExpenses({
    required String pharmacyId,
    required String query,
  }) async {
    final expenses = await getExpenses(pharmacyId);

    final searchText = query.trim().toLowerCase();

    if (searchText.isEmpty) {
      return expenses;
    }

    return expenses.where((expense) {
      return expense.category.toLowerCase().contains(searchText) ||
          expense.description.toLowerCase().contains(searchText) ||
          expense.paymentMethod.toLowerCase().contains(searchText) ||
          expense.reference.toLowerCase().contains(searchText);
    }).toList();
  }
}
