import 'package:flutter/material.dart';

import '../../../models/expense_model.dart';
import '../../../repositories/expense_repository.dart';
import '../../../services/notifications/notification_service.dart';

class AddExpenseScreen extends StatefulWidget {
  final String pharmacyId;
  final ExpenseModel? expense;

  const AddExpenseScreen({
    super.key,
    required this.pharmacyId,
    this.expense,
  });

  bool get isEditing => expense != null;

  @override
  State<AddExpenseScreen> createState() =>
      _AddExpenseScreenState();
}

class _AddExpenseScreenState
    extends State<AddExpenseScreen> {
  final ExpenseRepository _expenseRepository =
      ExpenseRepository();

  final NotificationService _notificationService =
      NotificationService.instance;

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _descriptionController;
  late final TextEditingController _amountController;
  late final TextEditingController _referenceController;

  String _category = 'General';
  String _paymentMethod = 'Cash';

  DateTime _expenseDate = DateTime.now();

  bool _saving = false;

  final List<String> _categories = [
    'General',
    'Rent',
    'Electricity',
    'Water',
    'Transport',
    'Salaries',
    'Internet',
    'Maintenance',
    'Supplies',
    'Other',
  ];

  final List<String> _paymentMethods = [
    'Cash',
    'Bank',
    'Mobile Money',
    'Card',
    'Other',
  ];

  @override
  void initState() {
    super.initState();

    final expense = widget.expense;

    _descriptionController = TextEditingController(
      text: expense?.description ?? '',
    );

    _amountController = TextEditingController(
      text: expense == null
          ? ''
          : _formatNumber(expense.amount),
    );

    _referenceController = TextEditingController(
      text: expense?.reference ?? '',
    );

    if (expense != null) {
      if (_categories.contains(expense.category)) {
        _category = expense.category;
      } else if (expense.category.isNotEmpty) {
        _category = 'Other';
      }

      if (_paymentMethods.contains(expense.paymentMethod)) {
        _paymentMethod = expense.paymentMethod;
      } else if (expense.paymentMethod.isNotEmpty) {
        _paymentMethod = 'Other';
      }

      _expenseDate =
          expense.expenseDate ?? DateTime.now();
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _referenceController.dispose();

    super.dispose();
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toString();
  }

  String _formatCurrency(double value) {
    return 'TSh ${value.toStringAsFixed(0)}';
  }

  String _formatDate(DateTime date) {
    final day =
        date.day.toString().padLeft(2, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String? _descriptionValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Description is required.';
    }

    return null;
  }

  String? _amountValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Amount is required.';
    }

    final amount =
        double.tryParse(value.trim());

    if (amount == null) {
      return 'Enter a valid amount.';
    }

    if (amount <= 0) {
      return 'Amount must be greater than 0.';
    }

    return null;
  }

  Future<void> _selectExpenseDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Select expense date',
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      _expenseDate = selectedDate;
    });
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount =
        double.parse(_amountController.text.trim());

    final description =
        _descriptionController.text.trim();

    final reference =
        _referenceController.text.trim();

    setState(() {
      _saving = true;
    });

    try {
      final now = DateTime.now();

      if (widget.isEditing) {
        final existingExpense =
            widget.expense!;

        final updatedExpense =
            existingExpense.copyWith(
          pharmacyId: widget.pharmacyId,
          category: _category,
          description: description,
          amount: amount,
          paymentMethod: _paymentMethod,
          reference: reference,
          expenseDate: _expenseDate,
          updatedAt: now,
        );

        await _expenseRepository.updateExpense(
          updatedExpense,
        );

        // ----------------------------------------------------------
        // OWNER NOTIFICATION - EXPENSE UPDATED
        // ----------------------------------------------------------
        try {
          await _notificationService
              .createOwnerNotification(
            pharmacyId: widget.pharmacyId,
            type: 'staff_expense_updated',
            title: 'Staff updated an expense',
            message:
                'A staff member updated expense "$description" '
                'under category "$_category" '
                'with amount ${_formatCurrency(amount)}.',
            itemName: description,
            status: 'success',
            relatedId: existingExpense.id,
          );
        } catch (_) {
          // Expense already updated.
          // Notification failure must not undo the update.
        }
      } else {
        final expense = ExpenseModel(
          id: '',
          pharmacyId: widget.pharmacyId,
          category: _category,
          description: description,
          amount: amount,
          paymentMethod: _paymentMethod,
          reference: reference,
          expenseDate: _expenseDate,
          createdAt: now,
          updatedAt: now,
        );

        await _expenseRepository.addExpense(
          expense,
        );

        // ----------------------------------------------------------
        // OWNER NOTIFICATION - EXPENSE ADDED
        // ----------------------------------------------------------
        try {
          await _notificationService
              .createOwnerNotification(
            pharmacyId: widget.pharmacyId,
            type: 'staff_expense_added',
            title: 'Staff added an expense',
            message:
                'A staff member added expense "$description" '
                'under category "$_category" '
                'with amount ${_formatCurrency(amount)}.',
            itemName: description,
            status: 'success',
          );
        } catch (_) {
          // Expense already saved.
          // Notification failure must not undo the save.
        }
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'Expense updated successfully.'
                : 'Expense added successfully.',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      // ------------------------------------------------------------
      // OWNER NOTIFICATION - EXPENSE FAILURE
      // ------------------------------------------------------------
      try {
        await _notificationService
            .createOwnerNotification(
          pharmacyId: widget.pharmacyId,
          type: widget.isEditing
              ? 'staff_expense_updated'
              : 'staff_expense_added',
          title: widget.isEditing
              ? 'Staff expense update failed'
              : 'Staff expense addition failed',
          message:
              'A staff member failed to '
              '${widget.isEditing ? 'update' : 'add'} '
              'expense "$description" '
              'under category "$_category". '
              'Error: ${_cleanError(e)}',
          itemName: description,
          status: 'failed',
          relatedId: widget.expense?.id,
        );
      } catch (_) {
        // Keep the original expense error.
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to save expense: ${_cleanError(e)}',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  String _cleanError(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.replaceFirst(
        'Exception: ',
        '',
      );
    }

    return message;
  }

  InputDecoration _inputDecoration(
    String label,
    IconData icon, {
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Theme.of(context)
              .colorScheme
              .primary,
          width: 2,
        ),
      ),
      filled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.isEditing;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          editing
              ? 'Edit Expense'
              : 'Add Expense',
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding:
                const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              32,
            ),
            children: [
              _buildHeader(editing),

              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                initialValue: _category,
                isExpanded: true,
                decoration: _inputDecoration(
                  'Category',
                  Icons.category_outlined,
                ),
                items: _categories.map(
                  (category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  },
                ).toList(),
                onChanged: _saving
                    ? null
                    : (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          _category = value;
                        });
                      },
              ),

              const SizedBox(height: 14),

              TextFormField(
                controller:
                    _descriptionController,
                textInputAction:
                    TextInputAction.next,
                textCapitalization:
                    TextCapitalization.sentences,
                decoration: _inputDecoration(
                  'Description',
                  Icons.description_outlined,
                  hint:
                      'e.g. Pharmacy rent payment',
                ),
                validator:
                    _descriptionValidator,
              ),

              const SizedBox(height: 14),

              TextFormField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction:
                    TextInputAction.next,
                decoration: _inputDecoration(
                  'Amount',
                  Icons.payments_outlined,
                  hint: 'Enter amount',
                ),
                validator:
                    _amountValidator,
              ),

              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                initialValue: _paymentMethod,
                isExpanded: true,
                decoration: _inputDecoration(
                  'Payment Method',
                  Icons
                      .account_balance_wallet_outlined,
                ),
                items: _paymentMethods.map(
                  (method) {
                    return DropdownMenuItem<String>(
                      value: method,
                      child: Text(method),
                    );
                  },
                ).toList(),
                onChanged: _saving
                    ? null
                    : (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          _paymentMethod = value;
                        });
                      },
              ),

              const SizedBox(height: 14),

              InkWell(
                borderRadius:
                    BorderRadius.circular(14),
                onTap:
                    _saving
                        ? null
                        : _selectExpenseDate,
                child: InputDecorator(
                  decoration:
                      _inputDecoration(
                    'Expense Date',
                    Icons.event_outlined,
                  ),
                  child: Text(
                    _formatDate(
                      _expenseDate,
                    ),
                    style:
                        const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              TextFormField(
                controller:
                    _referenceController,
                textInputAction:
                    TextInputAction.done,
                decoration: _inputDecoration(
                  'Reference',
                  Icons.tag_rounded,
                  hint:
                      'Receipt number or reference (optional)',
                ),
              ),

              const SizedBox(height: 24),

              _buildTotalCard(),

              const SizedBox(height: 24),

              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed:
                      _saving
                          ? null
                          : _saveExpense,
                  icon: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.save_rounded,
                        ),
                  label: Text(
                    _saving
                        ? 'Saving...'
                        : editing
                            ? 'Update Expense'
                            : 'Save Expense',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool editing) {
    return Container(
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(18),
        color: Theme.of(context)
            .colorScheme
            .primary
            .withValues(alpha: 0.08),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration:
                BoxDecoration(
              borderRadius:
                  BorderRadius.circular(14),
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.12),
            ),
            child: Icon(
              editing
                  ? Icons.edit_rounded
                  : Icons.receipt_long_rounded,
              color: Theme.of(context)
                  .colorScheme
                  .primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  editing
                      ? 'Update Expense'
                      : 'Expense Information',
                  style:
                      const TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  editing
                      ? 'Update the expense record.'
                      : 'Record pharmacy operating expenses.',
                  style:
                      const TextStyle(
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard() {
    final amount =
        double.tryParse(
              _amountController.text
                  .trim(),
            ) ??
            0;

    return Container(
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(18),
        color: Colors.orange
            .withValues(alpha: 0.08),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration:
                BoxDecoration(
              borderRadius:
                  BorderRadius.circular(13),
              color: Colors.orange
                  .withValues(
                alpha: 0.12,
              ),
            ),
            child: const Icon(
              Icons.payments_rounded,
              color: Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Expense Amount',
                  style: TextStyle(
                    color:
                        Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatCurrency(amount),
                  style:
                      const TextStyle(
                    fontSize: 22,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}