import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../models/customer_model.dart';
import '../../../services/notifications/notification_service.dart';

class AddCustomerScreen extends StatefulWidget {
  final String pharmacyId;
  final CustomerModel? customer;

  const AddCustomerScreen({
    super.key,
    required this.pharmacyId,
    this.customer,
  });

  bool get isEditing => customer != null;

  @override
  State<AddCustomerScreen> createState() =>
      _AddCustomerScreenState();
}

class _AddCustomerScreenState
    extends State<AddCustomerScreen> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final NotificationService _notificationService =
      NotificationService.instance;

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController =
      TextEditingController();

  final TextEditingController _phoneController =
      TextEditingController();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _addressController =
      TextEditingController();

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final customer = widget.customer;

    if (customer != null) {
      _nameController.text = customer.name;
      _phoneController.text = customer.phone;
      _emailController.text = customer.email;
      _addressController.text = customer.address;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();

    super.dispose();
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

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'You must be logged in to save a customer.',
      );
      return;
    }

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final address = _addressController.text.trim();

    setState(() {
      _saving = true;
    });

    try {
      final now = FieldValue.serverTimestamp();

      String customerId;

      if (widget.customer == null) {
        final customerRef =
            _firestore.collection('customers').doc();

        customerId = customerRef.id;

        await customerRef.set({
          'id': customerId,
          'pharmacyId': widget.pharmacyId,
          'name': name,
          'phone': phone,
          'email': email,
          'address': address,
          'createdAt': now,
          'updatedAt': now,
        });

        // ------------------------------------------------------------
        // OWNER NOTIFICATION - CUSTOMER ADDED
        // ------------------------------------------------------------
        try {
          await _notificationService
              .createOwnerNotification(
            pharmacyId: widget.pharmacyId,
            type: 'staff_customer_added',
            title: 'Staff added a customer',
            message:
                'A staff member added customer "$name".',
            itemName: name,
            status: 'success',
            relatedId: customerId,
          );
        } catch (_) {
          // Customer already saved.
          // Notification failure must not undo the save.
        }

        if (!mounted) {
          return;
        }

        _showMessage(
          'Customer added successfully.',
        );
      } else {
        customerId = widget.customer!.id;

        final customerRef = _firestore
            .collection('customers')
            .doc(customerId);

        await customerRef.update({
          'name': name,
          'phone': phone,
          'email': email,
          'address': address,
          'updatedAt': now,
        });

        // ------------------------------------------------------------
        // OWNER NOTIFICATION - CUSTOMER UPDATED
        // ------------------------------------------------------------
        try {
          await _notificationService
              .createOwnerNotification(
            pharmacyId: widget.pharmacyId,
            type: 'staff_customer_updated',
            title: 'Staff updated a customer',
            message:
                'A staff member updated customer "$name".',
            itemName: name,
            status: 'success',
            relatedId: customerId,
          );
        } catch (_) {
          // Customer already updated.
          // Notification failure must not undo the update.
        }

        if (!mounted) {
          return;
        }

        _showMessage(
          'Customer updated successfully.',
        );
      }

      if (!mounted) {
        return;
      }

      Navigator.pop(
        context,
        true,
      );
    } catch (e) {
      // ------------------------------------------------------------
      // OWNER NOTIFICATION - CUSTOMER SAVE FAILED
      // ------------------------------------------------------------
      try {
        await _notificationService
            .createOwnerNotification(
          pharmacyId: widget.pharmacyId,
          type: widget.customer == null
              ? 'staff_customer_added'
              : 'staff_customer_updated',
          title: widget.customer == null
              ? 'Staff customer addition failed'
              : 'Staff customer update failed',
          message:
              'A staff member failed to ${widget.customer == null ? 'add' : 'update'} customer "$name". Error: ${_cleanError(e)}',
          itemName: name,
          status: 'failed',
          relatedId: widget.customer?.id,
        );
      } catch (_) {
        // Keep the original customer error.
      }

      if (!mounted) {
        return;
      }

      _showMessage(
        'Failed to save customer: ${_cleanError(e)}',
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  String? _nameValidator(String? value) {
    final name = value?.trim() ?? '';

    if (name.isEmpty) {
      return 'Customer name is required.';
    }

    if (name.length < 2) {
      return 'Customer name is too short.';
    }

    return null;
  }

  String? _phoneValidator(String? value) {
    final phone = value?.trim() ?? '';

    if (phone.isEmpty) {
      return 'Phone number is required.';
    }

    if (phone.length < 7) {
      return 'Enter a valid phone number.';
    }

    return null;
  }

  String? _emailValidator(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return null;
    }

    final emailRegex = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!emailRegex.hasMatch(email)) {
      return 'Enter a valid email address.';
    }

    return null;
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
        borderRadius: BorderRadius.circular(14),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
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
              ? 'Edit Customer'
              : 'Add Customer',
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              32,
            ),
            children: [
              _buildHeader(editing),
              const SizedBox(height: 20),

              TextFormField(
                controller: _nameController,
                textInputAction:
                    TextInputAction.next,
                textCapitalization:
                    TextCapitalization.words,
                decoration: _inputDecoration(
                  'Customer Name',
                  Icons.person_outline_rounded,
                  hint: 'Enter customer name',
                ),
                validator: _nameValidator,
              ),

              const SizedBox(height: 14),

              TextFormField(
                controller: _phoneController,
                keyboardType:
                    TextInputType.phone,
                textInputAction:
                    TextInputAction.next,
                decoration: _inputDecoration(
                  'Phone',
                  Icons.phone_outlined,
                  hint: 'Enter phone number',
                ),
                validator: _phoneValidator,
              ),

              const SizedBox(height: 14),

              TextFormField(
                controller: _emailController,
                keyboardType:
                    TextInputType.emailAddress,
                textInputAction:
                    TextInputAction.next,
                decoration: _inputDecoration(
                  'Email',
                  Icons.email_outlined,
                  hint: 'Enter email address',
                ),
                validator: _emailValidator,
              ),

              const SizedBox(height: 14),

              TextFormField(
                controller: _addressController,
                textInputAction:
                    TextInputAction.done,
                textCapitalization:
                    TextCapitalization.words,
                maxLines: 3,
                decoration: _inputDecoration(
                  'Address',
                  Icons.location_on_outlined,
                  hint: 'Enter customer address',
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed:
                      _saving ? null : _saveCustomer,
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
                      : Icon(
                          editing
                              ? Icons.save_rounded
                              : Icons.person_add_alt_1_rounded,
                        ),
                  label: Text(
                    _saving
                        ? 'Saving...'
                        : editing
                            ? 'Update Customer'
                            : 'Save Customer',
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context)
            .colorScheme
            .primary
            .withValues(alpha: 0.08),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
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
                  : Icons.person_add_alt_1_rounded,
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
                      ? 'Customer Information'
                      : 'New Customer',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  editing
                      ? 'Update customer information.'
                      : 'Add a new customer to the pharmacy.',
                  style: const TextStyle(
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
}