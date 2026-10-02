import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../models/staff_model.dart';
import '../../../services/auth_service.dart';

class AddStaffScreen extends StatefulWidget {
  final String pharmacyId;
  final StaffModel? staff;

  const AddStaffScreen({
    super.key,
    required this.pharmacyId,
    this.staff,
  });

  @override
  State<AddStaffScreen> createState() => _AddStaffScreenState();
}

class _AddStaffScreenState extends State<AddStaffScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController =
      TextEditingController();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _phoneController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final AuthService _authService = AuthService();

  bool _isSaving = false;
  bool _isActive = true;
  bool _obscurePassword = true;

  // Staff permissions allowed by M-Shop policy.
  // Edit permissions and Staff/Pharmacy management are intentionally excluded.
  final List<String> _permissions = [
    'view_dashboard',
    'view_products',
    'add_products',
    'view_purchases',
    'add_purchases',
    'view_stock',
    'view_sales',
    'create_sales',
    'view_customers',
    'add_customers',
    'view_suppliers',
    'add_suppliers',
    'view_expenses',
    'add_expenses',
    'view_stock_records',
  ];

  final Set<String> _selectedPermissions = {};

  bool get _isEditing => widget.staff != null;

  @override
  void initState() {
    super.initState();

    final staff = widget.staff;

    if (staff != null) {
      _fullNameController.text = staff.fullName;
      _emailController.text = staff.email;
      _phoneController.text = staff.phone;
      _isActive = staff.isActive;

      // Keep only permissions that are valid for Staff.
      _selectedPermissions.addAll(
        staff.permissions.where(
          _permissions.contains,
        ),
      );
    } else {
      // All standard Staff permissions are enabled by default.
      _selectedPermissions.addAll(_permissions);
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _permissionLabel(String permission) {
    switch (permission) {
      case 'view_dashboard':
        return 'View Dashboard';

      case 'view_products':
        return 'View Products';

      case 'add_products':
        return 'Add Products';

      case 'view_purchases':
        return 'View Purchases';

      case 'add_purchases':
        return 'Add Purchases';

      case 'view_stock':
        return 'View Stock';

      case 'view_sales':
        return 'View Sales';

      case 'create_sales':
        return 'Make Sales';

      case 'view_customers':
        return 'View Customers';

      case 'add_customers':
        return 'Add Customers';

      case 'view_suppliers':
        return 'View Suppliers';

      case 'add_suppliers':
        return 'Add Suppliers';

      case 'view_expenses':
        return 'View Expenses';

      case 'add_expenses':
        return 'Add Expenses';

      case 'view_stock_records':
        return 'View Stock Records';

      default:
        return permission;
    }
  }

  Future<void> _saveStaff() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (widget.pharmacyId.trim().isEmpty) {
      _showMessage(
        'Pharmacy information is missing.',
      );
      return;
    }

    if (!_isEditing &&
        _passwordController.text.trim().isEmpty) {
      _showMessage(
        'Staff password is required.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final now = Timestamp.now();

      final email =
          _emailController.text.trim();

      final password =
          _passwordController.text.trim();

      final staffId = widget.staff?.id ??
          _firestore
              .collection('staff')
              .doc()
              .id;

      String? authUid;

      // Create Firebase Auth account only for new Staff.
      if (!_isEditing) {
        authUid =
            await _authService.createStaffAccount(
          email: email,
          password: password,
        );
      }

      // Staff is never allowed to receive edit/admin permissions.
      final safePermissions =
          _selectedPermissions
              .where(_permissions.contains)
              .toList();

      final data = <String, dynamic>{
        'pharmacyId':
            widget.pharmacyId,
        'fullName':
            _fullNameController.text.trim(),
        'email':
            email,
        'phone':
            _phoneController.text.trim(),
        'role': 'staff',
        'status':
            _isActive ? 'active' : 'inactive',
        'permissions':
            safePermissions,
        'updatedAt':
            now,
      };

      if (authUid != null &&
          authUid.trim().isNotEmpty) {
        data['authUid'] = authUid;
      }

      if (_isEditing) {
        await _firestore
            .collection('staff')
            .doc(staffId)
            .update(data);
      } else {
        data['createdAt'] = now;

        await _firestore
            .collection('staff')
            .doc(staffId)
            .set(data);
      }

      if (!mounted) {
        return;
      }

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Failed to save staff. Please check the email/password and try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  void _selectAllPermissions() {
    setState(() {
      _selectedPermissions
        ..clear()
        ..addAll(_permissions);
    });
  }

  void _clearAllPermissions() {
    setState(() {
      _selectedPermissions.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final title =
        _isEditing ? 'Edit Staff' : 'Add Staff';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              16,
              20,
              16,
              32,
            ),
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildBasicInformation(),
              const SizedBox(height: 24),
              _buildStatusSection(),
              const SizedBox(height: 24),
              _buildPermissionsSection(),
              const SizedBox(height: 28),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed:
                      _isSaving ? null : _saveStaff,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.save_outlined,
                        ),
                  label: Text(
                    _isSaving
                        ? 'Saving...'
                        : _isEditing
                            ? 'Update Staff'
                            : 'Save Staff',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest,
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            child: Icon(
              _isEditing
                  ? Icons.edit_outlined
                  : Icons.person_add_alt_1,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing
                      ? 'Update Staff Member'
                      : 'New Staff Member',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Staff can view and add pharmacy operations, but cannot edit pharmacy information or manage Staff.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInformation() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Basic Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 14),

        TextFormField(
          controller: _fullNameController,
          textCapitalization:
              TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'Full Name',
            hintText:
                'Enter staff full name',
            prefixIcon: const Icon(
              Icons.person_outline,
            ),
            border:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(14),
            ),
          ),
          validator: (value) {
            final text =
                value?.trim() ?? '';

            if (text.isEmpty) {
              return 'Full name is required.';
            }

            if (text.length < 2) {
              return 'Enter a valid full name.';
            }

            return null;
          },
        ),

        const SizedBox(height: 14),

        TextFormField(
          controller: _emailController,
          keyboardType:
              TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email',
            hintText:
                'Enter email address',
            prefixIcon: const Icon(
              Icons.email_outlined,
            ),
            border:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(14),
            ),
          ),
          validator: (value) {
            final email =
                value?.trim() ?? '';

            if (email.isEmpty) {
              return 'Email is required.';
            }

            final emailRegex = RegExp(
              r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
            );

            if (!emailRegex
                .hasMatch(email)) {
              return 'Enter a valid email address.';
            }

            return null;
          },
        ),

        const SizedBox(height: 14),

        TextFormField(
          controller:
              _phoneController,
          keyboardType:
              TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Phone',
            hintText:
                'Enter phone number',
            prefixIcon: const Icon(
              Icons.phone_outlined,
            ),
            border:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(14),
            ),
          ),
          validator: (value) {
            final phone =
                value?.trim() ?? '';

            if (phone.isEmpty) {
              return 'Phone number is required.';
            }

            if (phone.length < 7) {
              return 'Enter a valid phone number.';
            }

            return null;
          },
        ),

        if (!_isEditing) ...[
          const SizedBox(height: 14),

          TextFormField(
            controller:
                _passwordController,
            obscureText:
                _obscurePassword,
            decoration:
                InputDecoration(
              labelText:
                  'Staff Password',
              hintText:
                  'Create login password',
              prefixIcon:
                  const Icon(
                Icons.lock_outline,
              ),
              suffixIcon:
                  IconButton(
                onPressed: () {
                  setState(() {
                    _obscurePassword =
                        !_obscurePassword;
                  });
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons
                          .visibility_outlined
                      : Icons
                          .visibility_off_outlined,
                ),
              ),
              border:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),
            ),
            validator: (value) {
              final password =
                  value?.trim() ?? '';

              if (password.isEmpty) {
                return 'Password is required.';
              }

              if (password.length < 6) {
                return 'Password must be at least 6 characters.';
              }

              return null;
            },
          ),
        ],
      ],
    );
  }

  Widget _buildStatusSection() {
    return Container(
      padding:
          const EdgeInsets.all(16),
      decoration:
          BoxDecoration(
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant,
        ),
      ),
      child: SwitchListTile(
        contentPadding:
            EdgeInsets.zero,
        value: _isActive,
        onChanged: (value) {
          setState(() {
            _isActive = value;
          });
        },
        title: const Text(
          'Staff Status',
          style: TextStyle(
            fontWeight:
                FontWeight.w600,
          ),
        ),
        subtitle: Text(
          _isActive
              ? 'Staff can currently operate the pharmacy.'
              : 'Staff is currently inactive.',
        ),
        secondary: Icon(
          _isActive
              ? Icons.check_circle_outline
              : Icons.pause_circle_outline,
        ),
      ),
    );
  }

  Widget _buildPermissionsSection() {
    final allSelected =
        _selectedPermissions.length ==
            _permissions.length;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Staff Access',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: allSelected
                  ? _clearAllPermissions
                  : _selectAllPermissions,
              child: Text(
                allSelected
                    ? 'Clear All'
                    : 'Select All',
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        const Text(
          'Staff can view and add operational records. Editing pharmacy information and Staff management are Owner-only.',
        ),

        const SizedBox(height: 14),

        Container(
          decoration:
              BoxDecoration(
            borderRadius:
                BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .outlineVariant,
            ),
          ),
          child: Column(
            children:
                _permissions.map(
              (permission) {
                final selected =
                    _selectedPermissions
                        .contains(permission);

                return CheckboxListTile(
                  value: selected,
                  onChanged:
                      (value) {
                    setState(() {
                      if (value ==
                          true) {
                        _selectedPermissions
                            .add(permission);
                      } else {
                        _selectedPermissions
                            .remove(
                          permission,
                        );
                      }
                    });
                  },
                  title: Text(
                    _permissionLabel(
                      permission,
                    ),
                  ),
                  controlAffinity:
                      ListTileControlAffinity
                          .leading,
                );
              },
            ).toList(),
          ),
        ),
      ],
    );
  }
}