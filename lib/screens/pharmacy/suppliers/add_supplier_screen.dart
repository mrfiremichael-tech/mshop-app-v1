import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../models/supplier_model.dart';
import '../../../services/notifications/notification_service.dart';

class AddSupplierScreen extends StatefulWidget {
  final String pharmacyId;
  final SupplierModel? supplier;

  const AddSupplierScreen({
    super.key,
    required this.pharmacyId,
    this.supplier,
  });

  bool get isEditing => supplier != null;

  @override
  State<AddSupplierScreen> createState() =>
      _AddSupplierScreenState();
}

class _AddSupplierScreenState
    extends State<AddSupplierScreen> {
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

    final supplier = widget.supplier;

    if (supplier != null) {
      _nameController.text = supplier.name;
      _phoneController.text = supplier.phone;
      _emailController.text = supplier.email;
      _addressController.text = supplier.address;
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

  Future<void> _saveSupplier() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'You must be logged in to save a supplier.',
      );
      return;
    }

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final address = _addressController.text.trim();

    if (name.isEmpty) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      String supplierId;

      if (widget.supplier == null) {
        final supplierRef =
            _firestore.collection('suppliers').doc();

        supplierId = supplierRef.id;

        await supplierRef.set({
          'id': supplierId,
          'pharmacyId': widget.pharmacyId,
          'name': name,
          'phone': phone,
          'email': email,
          'address': address,
          'createdAt':
              FieldValue.serverTimestamp(),
          'updatedAt':
              FieldValue.serverTimestamp(),
        });

        // ------------------------------------------------------------
        // OWNER NOTIFICATION - SUPPLIER ADDED
        // ------------------------------------------------------------
        try {
          await _notificationService
              .createOwnerNotification(
            pharmacyId: widget.pharmacyId,
            type: 'staff_supplier_added',
            title: 'Staff added a supplier',
            message:
                'A staff member added supplier "$name".',
            itemName: name,
            status: 'success',
            relatedId: supplierId,
          );
        } catch (_) {
          // Supplier already saved.
          // Notification failure must not undo the save.
        }

        if (!mounted) {
          return;
        }

        _showMessage(
          'Supplier added successfully.',
        );
      } else {
        supplierId = widget.supplier!.id;

        final supplierRef = _firestore
            .collection('suppliers')
            .doc(supplierId);

        await supplierRef.update({
          'name': name,
          'phone': phone,
          'email': email,
          'address': address,
          'updatedAt':
              FieldValue.serverTimestamp(),
        });

        // ------------------------------------------------------------
        // OWNER NOTIFICATION - SUPPLIER UPDATED
        // ------------------------------------------------------------
        try {
          await _notificationService
              .createOwnerNotification(
            pharmacyId: widget.pharmacyId,
            type: 'staff_supplier_updated',
            title: 'Staff updated a supplier',
            message:
                'A staff member updated supplier "$name".',
            itemName: name,
            status: 'success',
            relatedId: supplierId,
          );
        } catch (_) {
          // Supplier already updated.
          // Notification failure must not undo the update.
        }

        if (!mounted) {
          return;
        }

        _showMessage(
          'Supplier updated successfully.',
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
      // OWNER NOTIFICATION - SUPPLIER FAILURE
      // ------------------------------------------------------------
      try {
        await _notificationService
            .createOwnerNotification(
          pharmacyId: widget.pharmacyId,
          type: widget.supplier == null
              ? 'staff_supplier_added'
              : 'staff_supplier_updated',
          title: widget.supplier == null
              ? 'Staff supplier addition failed'
              : 'Staff supplier update failed',
          message:
              'A staff member failed to ${widget.supplier == null ? 'add' : 'update'} supplier "$name". Error: ${_cleanError(e)}',
          itemName: name,
          status: 'failed',
          relatedId: widget.supplier?.id,
        );
      } catch (_) {
        // Keep the original error.
      }

      if (!mounted) {
        return;
      }

      _showMessage(
        'Failed to save supplier: ${_cleanError(e)}',
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
      return 'Supplier name is required.';
    }

    if (name.length < 2) {
      return 'Supplier name is too short.';
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
              ? 'Edit Supplier'
              : 'Add Supplier',
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
                  'Supplier Name',
                  Icons.local_shipping_outlined,
                  hint: 'Enter supplier name',
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
                  hint: 'Enter supplier address',
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed:
                      _saving ? null : _saveSupplier,
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
                              : Icons.local_shipping_rounded,
                        ),
                  label: Text(
                    _saving
                        ? 'Saving...'
                        : editing
                            ? 'Update Supplier'
                            : 'Save Supplier',
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
                  : Icons.local_shipping_rounded,
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
                      ? 'Supplier Information'
                      : 'New Supplier',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  editing
                      ? 'Update supplier information.'
                      : 'Add a new supplier to the pharmacy.',
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