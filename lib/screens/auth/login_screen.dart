import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/app_controller.dart';
import '../../services/auth_service.dart';
import '../../services/subscription_service.dart';
import 'forgot_password_screen.dart';
import 'registration/registration_screen.dart';
import '../pharmacy/pharmacy_dashboard.dart';
import '../pharmacy/staff/staff_dashboard.dart';
import '../mshop_owner/mshop_owner_dashboard.dart';
import '../mshop_owner/subscription_plans_screen.dart';

class LoginScreen extends StatefulWidget {
  final AppController appController;

  const LoginScreen({
    super.key,
    required this.appController,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  final AuthService _authService = AuthService();

  final SubscriptionService _subscriptionService =
      SubscriptionService.instance;

  bool _isLoading = false;
  bool _obscurePassword = true;

  bool get _isSwahili =>
      widget.appController.isSwahili;

  String get _welcomeText =>
      _isSwahili ? 'Karibu Tena' : 'Welcome Back';

  String get _subtitleText => _isSwahili
      ? 'Ingia kwenye akaunti yako ya M-Shop Pharmacy'
      : 'Sign in to your M-Shop Pharmacy account';

  String get _emailLabel =>
      _isSwahili ? 'Barua pepe' : 'Email';

  String get _emailHint => _isSwahili
      ? 'Ingiza barua pepe yako'
      : 'Enter your email';

  String get _emailRequired => _isSwahili
      ? 'Barua pepe inahitajika.'
      : 'Email is required.';

  String get _invalidEmail => _isSwahili
      ? 'Ingiza barua pepe sahihi.'
      : 'Please enter a valid email address.';

  String get _passwordLabel =>
      _isSwahili ? 'Nenosiri' : 'Password';

  String get _passwordHint => _isSwahili
      ? 'Ingiza nenosiri lako'
      : 'Enter your password';

  String get _passwordRequired => _isSwahili
      ? 'Nenosiri linahitajika.'
      : 'Password is required.';

  String get _passwordTooShort => _isSwahili
      ? 'Nenosiri lazima liwe na angalau herufi 6.'
      : 'Password must be at least 6 characters.';

  String get _forgotPassword => _isSwahili
      ? 'Umesahau nenosiri?'
      : 'Forgot Password?';

  String get _loginLabel =>
      _isSwahili ? 'INGIA' : 'LOGIN';

  String get _orLabel =>
      _isSwahili ? 'AU' : 'OR';

  String get _createAccountLabel => _isSwahili
      ? 'FUNGUA AKAUNTI YA PHARMACY'
      : 'CREATE PHARMACY ACCOUNT';

  String get _footerLabel => _isSwahili
      ? 'Mfumo wa Usimamizi wa M-Shop Pharmacy'
      : 'M-Shop Pharmacy Management System';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleLanguage() {
    if (_isLoading) {
      return;
    }

    widget.appController.toggleLanguage();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      final profile =
          await _authService.getCurrentUserProfile();

      if (!mounted) {
        return;
      }

      final role = profile?['role']?.toString();

      // ---------------------------------------------------------------------
      // PHARMACY OWNER
      // ---------------------------------------------------------------------

      if (role == 'pharmacy_owner') {
        final pharmacyId =
            profile?['pharmacyId']?.toString();

        bool hasValidSubscriptionAccess = false;

        if (pharmacyId != null &&
            pharmacyId.isNotEmpty) {
          hasValidSubscriptionAccess =
              await _subscriptionService.hasValidAccess(
            pharmacyId,
          );
        }

        if (!mounted) {
          return;
        }

        if (!hasValidSubscriptionAccess) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => SubscriptionPlansScreen(
                appController:
                    widget.appController,
              ),
            ),
            (route) => false,
          );

          return;
        }

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => PharmacyDashboard(
              appController:
                  widget.appController,
            ),
          ),
          (route) => false,
        );

        return;
      }

      // ---------------------------------------------------------------------
      // STAFF
      // ---------------------------------------------------------------------

      if (role == 'staff') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => StaffDashboard(
              appController:
                  widget.appController,
            ),
          ),
          (route) => false,
        );

        return;
      }

      // ---------------------------------------------------------------------
      // M-SHOP OWNER
      // ---------------------------------------------------------------------

      if (role == 'mshop_owner') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => MshopOwnerDashboard(
              appController:
                  widget.appController,
            ),
          ),
          (route) => false,
        );

        return;
      }

      await _authService.logout();

      if (!mounted) {
        return;
      }

      _showMessage(
        _isSwahili
            ? 'Aina ya akaunti haijatambuliwa.'
            : 'Your account role is not configured.',
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }

      String message;

      switch (e.code) {
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          message = _isSwahili
              ? 'Barua pepe au nenosiri si sahihi.'
              : 'Incorrect email or password.';
          break;

        case 'invalid-email':
          message = _isSwahili
              ? 'Barua pepe si sahihi.'
              : 'Please enter a valid email address.';
          break;

        case 'user-disabled':
          message = _isSwahili
              ? 'Akaunti hii imezuiwa.'
              : 'This account has been disabled.';
          break;

        case 'too-many-requests':
          message = _isSwahili
              ? 'Majaribio ya kuingia ni mengi. Jaribu tena baadaye.'
              : 'Too many login attempts. Please try again later.';
          break;

        case 'network-request-failed':
          message = _isSwahili
              ? 'Hakuna muunganisho wa internet.'
              : 'Network error. Check your internet connection.';
          break;

        default:
          message = _isSwahili
              ? 'Kuingia kumeshindikana. Jaribu tena.'
              : 'Login failed. Please try again.';
      }

      _showMessage(message);
    } catch (e, stackTrace) {
      debugPrint('LOGIN ERROR: $e');
      debugPrint('LOGIN STACK: $stackTrace');

      if (!mounted) {
        return;
      }

      _showMessage(
        _isSwahili
            ? 'Tatizo la kuingia: $e'
            : 'Login error: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _openForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const ForgotPasswordScreen(),
      ),
    );
  }

  void _openRegistration() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RegistrationScreen(
          appController:
              widget.appController,
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding:
                  const EdgeInsets.fromLTRB(
                24,
                70,
                24,
                30,
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
                        _buildLogo(),

                        const SizedBox(height: 24),

                        Text(
                          _welcomeText,
                          textAlign: TextAlign.center,
                          style:
                              const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          _subtitleText,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colorScheme
                                .onSurfaceVariant,
                          ),
                        ),

                        const SizedBox(height: 32),

                        Text(
                          _emailLabel,
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 8),

                        TextFormField(
                          controller:
                              _emailController,
                          enabled: !_isLoading,
                          keyboardType:
                              TextInputType.emailAddress,
                          textInputAction:
                              TextInputAction.next,
                          decoration:
                              _inputDecoration(
                            hint: _emailHint,
                            icon:
                                Icons.email_outlined,
                          ),
                          validator: (value) {
                            final email =
                                value?.trim() ?? '';

                            if (email.isEmpty) {
                              return _emailRequired;
                            }

                            final regex = RegExp(
                              r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                            );

                            if (!regex.hasMatch(
                                email)) {
                              return _invalidEmail;
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 18),

                        Text(
                          _passwordLabel,
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 8),

                        TextFormField(
                          controller:
                              _passwordController,
                          enabled: !_isLoading,
                          obscureText:
                              _obscurePassword,
                          textInputAction:
                              TextInputAction.done,
                          onFieldSubmitted: (_) {
                            if (!_isLoading) {
                              _login();
                            }
                          },
                          decoration:
                              _inputDecoration(
                            hint: _passwordHint,
                            icon:
                                Icons.lock_outline_rounded,
                            suffix:
                                IconButton(
                              onPressed:
                                  _isLoading
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
                              return _passwordRequired;
                            }

                            if (password.length <
                                6) {
                              return _passwordTooShort;
                            }

                            return null;
                          },
                        ),

                        Align(
                          alignment:
                              Alignment.centerRight,
                          child: TextButton(
                            onPressed:
                                _isLoading
                                    ? null
                                    : _openForgotPassword,
                            child: Text(
                              _forgotPassword,
                              style:
                                  const TextStyle(
                                color:
                                    Color(0xFF0B8F4D),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        SizedBox(
                          height: 54,
                          child:
                              ElevatedButton(
                            onPressed:
                                _isLoading
                                    ? null
                                    : _login,
                            style:
                                ElevatedButton
                                    .styleFrom(
                              backgroundColor:
                                  const Color(
                                0xFF0B8F4D,
                              ),
                              foregroundColor:
                                  Colors.white,
                              elevation: 0,
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  14,
                                ),
                              ),
                            ),
                            child:
                                _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child:
                                            CircularProgressIndicator(
                                          strokeWidth:
                                              2.5,
                                          color:
                                              Colors.white,
                                        ),
                                      )
                                    : Text(
                                        _loginLabel,
                                        style:
                                            const TextStyle(
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color:
                                    Colors.grey.shade300,
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                _orLabel,
                                style:
                                    TextStyle(
                                  color: Colors
                                      .grey
                                      .shade600,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color:
                                    Colors.grey.shade300,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        OutlinedButton(
                          onPressed:
                              _isLoading
                                  ? null
                                  : _openRegistration,
                          style:
                              OutlinedButton
                                  .styleFrom(
                            minimumSize:
                                const Size.fromHeight(
                              52,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                14,
                              ),
                            ),
                          ),
                          child: Text(
                            _createAccountLabel,
                            textAlign:
                                TextAlign.center,
                            style:
                                const TextStyle(
                              color:
                                  Color(0xFF0B8F4D),
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        Text(
                          _footerLabel,
                          textAlign:
                              TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                colorScheme
                                    .onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            Positioned(
              top: 10,
              right: 16,
              child: Material(
                color:
                    const Color(0xFFF1F7F3),
                borderRadius:
                    BorderRadius.circular(22),
                child: InkWell(
                  onTap: _toggleLanguage,
                  borderRadius:
                      BorderRadius.circular(22),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    child: Row(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.language_rounded,
                          size: 18,
                          color:
                              Color(0xFF0B8F4D),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isSwahili
                              ? 'SW'
                              : 'EN',
                          style:
                              const TextStyle(
                            color:
                                Color(0xFF0B8F4D),
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Center(
      child: Image.asset(
        'assets/images/mshop_logo.png',
        height: 145,
        fit: BoxFit.contain,
        errorBuilder:
            (context, error, stackTrace) {
          return const Icon(
            Icons.local_pharmacy_outlined,
            size: 90,
          );
        },
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(
        icon,
        color:
            const Color(0xFF0B8F4D),
      ),
      suffixIcon: suffix,
      filled: true,
      fillColor:
          const Color(0xFFF8FAF9),
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide:
            const BorderSide(
          color:
              Color(0xFFE1E5E2),
        ),
      ),
      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide:
            const BorderSide(
          color:
              Color(0xFFE1E5E2),
        ),
      ),
      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide:
            const BorderSide(
          color:
              Color(0xFF0B8F4D),
          width: 2,
        ),
      ),
    );
  }
}

