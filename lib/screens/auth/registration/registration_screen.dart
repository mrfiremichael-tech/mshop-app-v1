import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/app_controller.dart';
import '../../../services/auth_service.dart';
import '../../mshop_owner/subscription_plans_screen.dart';

class RegistrationScreen extends StatefulWidget {
  final AppController appController;

  const RegistrationScreen({
    super.key,
    required this.appController,
  });

  @override
  State<RegistrationScreen> createState() =>
      _RegistrationScreenState();
}

class _RegistrationScreenState
    extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController =
      TextEditingController();

  final _pharmacyNameController =
      TextEditingController();

  final _phoneController =
      TextEditingController();

  final _emailController =
      TextEditingController();

  final _passwordController =
      TextEditingController();

  final _confirmPasswordController =
      TextEditingController();

  final AuthService _authService =
      AuthService();

  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool get _isSwahili =>
      widget.appController.isSwahili;

  String get _pageTitle => _isSwahili
      ? 'Fungua Akaunti'
      : 'Create Owner Account';

  String get _mainTitle => _isSwahili
      ? 'Fungua akaunti yako ya M-Shop'
      : 'Create your M-Shop Owner account';

  String get _subtitle => _isSwahili
      ? 'Jaza taarifa zako ili kuendelea.'
      : 'Enter your details to continue.';

  String get _fullNameLabel =>
      _isSwahili ? 'Jina Kamili' : 'Full Name';

  String get _pharmacyNameLabel =>
      _isSwahili ? 'Jina la Pharmacy' : 'Pharmacy Name';

  String get _phoneLabel =>
      _isSwahili ? 'Namba ya Simu' : 'Phone Number';

  String get _emailLabel =>
      _isSwahili ? 'Barua Pepe' : 'Email';

  String get _passwordLabel =>
      _isSwahili ? 'Nenosiri' : 'Password';

  String get _confirmPasswordLabel =>
      _isSwahili
          ? 'Thibitisha Nenosiri'
          : 'Confirm Password';

  String get _createAccountLabel =>
      _isSwahili
          ? 'FUNGUA AKAUNTI'
          : 'CREATE ACCOUNT';

  String get _alreadyHaveAccount =>
      _isSwahili
          ? 'Tayari una akaunti? Ingia'
          : 'Already have an account? Login';

  @override
  void dispose() {
    _fullNameController.dispose();
    _pharmacyNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_passwordController.text !=
        _confirmPasswordController.text) {
      _showMessage(
        _isSwahili
            ? 'Nenosiri hazifanani.'
            : 'Passwords do not match.',
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await _authService.registerPharmacyOwner(
        fullName: _fullNameController.text.trim(),
        pharmacyName:
            _pharmacyNameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      // OTP imezimwa kwa sasa.
      // Baada ya registration tunaenda moja kwa moja
      // kwenye Subscription Plans.

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => SubscriptionPlansScreen(
            appController: widget.appController,
          ),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        _firebaseErrorMessage(e),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        _cleanError(e),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  String _firebaseErrorMessage(
    FirebaseAuthException error,
  ) {
    switch (error.code) {
      case 'email-already-in-use':
        return _isSwahili
            ? 'Barua pepe hii tayari imetumika.'
            : 'This email is already in use.';

      case 'invalid-email':
        return _isSwahili
            ? 'Barua pepe si sahihi.'
            : 'Please enter a valid email address.';

      case 'weak-password':
        return _isSwahili
            ? 'Nenosiri ni dhaifu. Tumia angalau herufi 6.'
            : 'Password is too weak. Use at least 6 characters.';

      case 'network-request-failed':
        return _isSwahili
            ? 'Tatizo la internet. Angalia muunganisho wako.'
            : 'Network error. Check your internet connection.';

      case 'operation-not-allowed':
        return _isSwahili
            ? 'Usajili wa Email/Password haujawashwa kwenye Firebase.'
            : 'Email/password registration is not enabled in Firebase.';

      case 'user-disabled':
        return _isSwahili
            ? 'Akaunti hii imezuiwa.'
            : 'This account has been disabled.';

      default:
        return error.message ??
            (_isSwahili
                ? 'Usajili umeshindikana.'
                : 'Registration failed.');
    }
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst(
          'Exception: ',
          '',
        );
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

  InputDecoration _decoration(
    String label,
    IconData icon,
  ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(
        icon,
        color: const Color(0xFF0B8F4D),
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAF9),
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE1E5E2),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE1E5E2),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFF0B8F4D),
          width: 2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_pageTitle),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            18,
            20,
            32,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 460,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),

                    Center(
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration:
                            const BoxDecoration(
                          color: Color(0xFFEAF7F0),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.local_pharmacy_outlined,
                          size: 46,
                          color: Color(0xFF0B8F4D),
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    Text(
                      _mainTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      _subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color:
                            colorScheme.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: 28),

                    TextFormField(
                      controller: _fullNameController,
                      enabled: !_loading,
                      textInputAction:
                          TextInputAction.next,
                      decoration: _decoration(
                        _fullNameLabel,
                        Icons.person_outline,
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return _isSwahili
                              ? 'Jina kamili linahitajika'
                              : 'Full name is required';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller:
                          _pharmacyNameController,
                      enabled: !_loading,
                      textInputAction:
                          TextInputAction.next,
                      decoration: _decoration(
                        _pharmacyNameLabel,
                        Icons.local_pharmacy_outlined,
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return _isSwahili
                              ? 'Jina la pharmacy linahitajika'
                              : 'Pharmacy name is required';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _phoneController,
                      enabled: !_loading,
                      keyboardType:
                          TextInputType.phone,
                      textInputAction:
                          TextInputAction.next,
                      decoration: _decoration(
                        _phoneLabel,
                        Icons.phone_outlined,
                      ).copyWith(
                        hintText: '0747967671',
                      ),
                      validator: (value) {
                        final phone =
                            value?.trim() ?? '';

                        if (phone.isEmpty) {
                          return _isSwahili
                              ? 'Namba ya simu inahitajika'
                              : 'Phone number is required';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _emailController,
                      enabled: !_loading,
                      keyboardType:
                          TextInputType.emailAddress,
                      textInputAction:
                          TextInputAction.next,
                      decoration: _decoration(
                        _emailLabel,
                        Icons.email_outlined,
                      ),
                      validator: (value) {
                        final email =
                            value?.trim() ?? '';

                        if (email.isEmpty) {
                          return _isSwahili
                              ? 'Barua pepe inahitajika'
                              : 'Email is required';
                        }

                        final emailRegex =
                            RegExp(
                          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                        );

                        if (!emailRegex.hasMatch(
                          email,
                        )) {
                          return _isSwahili
                              ? 'Weka barua pepe sahihi'
                              : 'Enter a valid email';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller:
                          _passwordController,
                      enabled: !_loading,
                      obscureText:
                          _obscurePassword,
                      textInputAction:
                          TextInputAction.next,
                      decoration: _decoration(
                        _passwordLabel,
                        Icons.lock_outline_rounded,
                      ).copyWith(
                        suffixIcon: IconButton(
                          onPressed: _loading
                              ? null
                              : () {
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
                      ),
                      validator: (value) {
                        final password =
                            value ?? '';

                        if (password.isEmpty) {
                          return _isSwahili
                              ? 'Nenosiri linahitajika'
                              : 'Password is required';
                        }

                        if (password.length < 6) {
                          return _isSwahili
                              ? 'Nenosiri lazima liwe na angalau herufi 6'
                              : 'Password must be at least 6 characters';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller:
                          _confirmPasswordController,
                      enabled: !_loading,
                      obscureText:
                          _obscureConfirmPassword,
                      textInputAction:
                          TextInputAction.done,
                      onFieldSubmitted: (_) {
                        if (!_loading) {
                          _register();
                        }
                      },
                      decoration: _decoration(
                        _confirmPasswordLabel,
                        Icons.lock_outline_rounded,
                      ).copyWith(
                        suffixIcon: IconButton(
                          onPressed: _loading
                              ? null
                              : () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons
                                    .visibility_outlined
                                : Icons
                                    .visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) {
                        final confirm =
                            value ?? '';

                        if (confirm.isEmpty) {
                          return _isSwahili
                              ? 'Thibitisha nenosiri'
                              : 'Confirm password';
                        }

                        if (confirm !=
                            _passwordController.text) {
                          return _isSwahili
                              ? 'Nenosiri hazifanani'
                              : 'Passwords do not match';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 28),

                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed:
                            _loading
                                ? null
                                : _register,
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF0B8F4D),
                          foregroundColor:
                              Colors.white,
                          elevation: 0,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _createAccountLabel,
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextButton(
                      onPressed: _loading
                          ? null
                          : () {
                              Navigator.pop(context);
                            },
                      child: Text(
                        _alreadyHaveAccount,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF0B8F4D),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}