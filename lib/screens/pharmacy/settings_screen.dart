import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/app_controller.dart';
import '../../services/auth_service.dart';
import '../../services/subscription_service.dart';
import '../mshop_owner/subscription_plans_screen.dart';

class SettingsScreen extends StatefulWidget {
  final AppController appController;

  const SettingsScreen({
    super.key,
    required this.appController,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();

  bool _notificationsEnabled = true;

  AppController get appController => widget.appController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appController,
      builder: (context, _) {
        final swahili = appController.isSwahili;
        final dark = appController.isDarkMode;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              swahili ? 'Mipangilio' : 'Settings',
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SettingsSection(
                title: swahili ? 'Mwonekano' : 'Appearance',
                children: [
                  ListTile(
                    leading: Icon(
                      dark
                          ? Icons.dark_mode_outlined
                          : Icons.light_mode_outlined,
                    ),
                    title: Text(
                      swahili ? 'Mandhari' : 'Theme',
                    ),
                    subtitle: Text(
                      dark
                          ? (swahili ? 'Giza' : 'Dark')
                          : (swahili ? 'Mwanga' : 'Light'),
                    ),
                    trailing: Switch(
                      value: dark,
                      onChanged: (_) {
                        appController.toggleTheme();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SettingsSection(
                title: swahili ? 'Lugha' : 'Language',
                children: [
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: Text(
                      swahili
                          ? 'Lugha ya programu'
                          : 'App language',
                    ),
                    subtitle: Text(
                      swahili ? 'Kiswahili' : 'English',
                    ),
                    trailing: DropdownButton<Locale>(
                      value: appController.locale,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(
                          value: Locale('en'),
                          child: Text('English'),
                        ),
                        DropdownMenuItem(
                          value: Locale('sw'),
                          child: Text('Kiswahili'),
                        ),
                      ],
                      onChanged: (locale) {
                        if (locale != null) {
                          appController.setLanguage(locale);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SettingsSection(
                title: swahili ? 'Akaunti' : 'Account',
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(
                      swahili ? 'Wasifu' : 'Profile',
                    ),
                    subtitle: Text(
                      swahili
                          ? 'Hariri taarifa binafsi'
                          : 'Edit personal information',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _openProfile,
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.notifications_outlined,
                    ),
                    title: Text(
                      swahili ? 'Arifa' : 'Notifications',
                    ),
                    subtitle: Text(
                      _notificationsEnabled
                          ? (swahili ? 'Imewashwa' : 'Enabled')
                          : (swahili ? 'Imezimwa' : 'Disabled'),
                    ),
                    trailing: Switch(
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _notificationsEnabled = value;
                        });
                      },
                    ),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.security_outlined,
                    ),
                    title: Text(
                      swahili ? 'Usalama' : 'Security',
                    ),
                    subtitle: Text(
                      swahili
                          ? 'Badilisha nenosiri'
                          : 'Change password',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _openSecurity,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SettingsSection(
                title: swahili ? 'Usajili' : 'Subscription',
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.card_membership_outlined,
                    ),
                    title: Text(
                      swahili
                          ? 'Usajili Wangu'
                          : 'My Subscription',
                    ),
                    subtitle: Text(
                      swahili
                          ? 'Angalia mpango, hali na tarehe za usajili'
                          : 'View plan, status and subscription dates',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _openSubscription,
                  ),
                ],
              ),

              const SizedBox(height: 16),
              _SettingsSection(
                title: swahili ? 'Programu' : 'App',
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: Text(
                      swahili
                          ? 'Kuhusu M-Shop'
                          : 'About M-Shop',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'M-Shop Pharmacy',
                        applicationVersion: '1.0.0',
                        applicationIcon: const Icon(
                          Icons.local_pharmacy,
                          size: 40,
                        ),
                        children: [
                          Text(
                            swahili
                                ? 'Mfumo wa usimamizi wa pharmacy wa M-Shop.'
                                : 'M-Shop Pharmacy management system.',
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openProfile() async {
    final swahili = appController.isSwahili;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        swahili
            ? 'Akaunti haipatikani.'
            : 'Account not found.',
      );
      return;
    }

    Map<String, dynamic>? profile;

    try {
      profile = await _authService.getCurrentUserProfile();
    } catch (_) {
      profile = null;
    }

    if (!mounted) {
      return;
    }

    final fullNameController = TextEditingController(
      text: profile?['fullName']?.toString() ??
          user.displayName ??
          '',
    );

    final phoneController = TextEditingController(
      text: profile?['phone']?.toString() ?? '',
    );

    final pharmacyNameController = TextEditingController(
      text: profile?['pharmacyName']?.toString() ?? '',
    );

    final email = user.email ?? '-';
    final accountId = profile?['accountId']?.toString() ?? '-';

    bool saving = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final navigator = Navigator.of(dialogContext);

        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(
                swahili
                    ? 'Hariri Wasifu'
                    : 'Edit Profile',
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircleAvatar(
                        radius: 34,
                        child: Icon(
                          Icons.person,
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: 18),

                      TextField(
                        controller: fullNameController,
                        enabled: !saving,
                        textInputAction:
                            TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: swahili
                              ? 'Jina kamili'
                              : 'Full name',
                          prefixIcon: const Icon(
                            Icons.person_outline,
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 14),

                      TextField(
                        controller: phoneController,
                        enabled: !saving,
                        keyboardType: TextInputType.phone,
                        textInputAction:
                            TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: swahili
                              ? 'Namba ya simu'
                              : 'Phone number',
                          prefixIcon: const Icon(
                            Icons.phone_outlined,
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 14),

                      TextField(
                        controller:
                            pharmacyNameController,
                        enabled: !saving,
                        textInputAction:
                            TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: swahili
                              ? 'Jina la pharmacy'
                              : 'Pharmacy name',
                          prefixIcon: const Icon(
                            Icons.local_pharmacy_outlined,
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 14),

                      TextField(
                        controller: TextEditingController(
                          text: email,
                        ),
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: swahili
                              ? 'Barua pepe'
                              : 'Email',
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 14),

                      TextField(
                        controller: TextEditingController(
                          text: accountId,
                        ),
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: swahili
                              ? 'ID ya akaunti'
                              : 'Account ID',
                          prefixIcon: const Icon(
                            Icons.fingerprint,
                          ),
                          helperText: swahili
                              ? 'ID hii haiwezi kubadilishwa.'
                              : 'This ID cannot be changed.',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () {
                          navigator.pop(false);
                        },
                  child: Text(
                    swahili ? 'Ghairi' : 'Cancel',
                  ),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final fullName =
                              fullNameController.text.trim();
                          final phone =
                              phoneController.text.trim();
                          final pharmacyName =
                              pharmacyNameController.text.trim();

                          if (fullName.isEmpty ||
                              phone.isEmpty ||
                              pharmacyName.isEmpty) {
                            _showMessage(
                              swahili
                                  ? 'Jaza taarifa zote za lazima.'
                                  : 'Fill in all required fields.',
                            );
                            return;
                          }

                          setDialogState(() {
                            saving = true;
                          });

                          try {
                            await _authService
                                .updateCurrentUserProfile(
                              fullName: fullName,
                              phone: phone,
                              pharmacyName: pharmacyName,
                            );

                            if (!mounted) {
                              return;
                            }

                            navigator.pop(true);
                          } on FirebaseException catch (e) {
                            setDialogState(() {
                              saving = false;
                            });

                            _showMessage(
                              _firebaseErrorMessage(
                                e,
                                swahili,
                              ),
                            );
                          } catch (_) {
                            setDialogState(() {
                              saving = false;
                            });

                            _showMessage(
                              swahili
                                  ? 'Imeshindikana kuhifadhi taarifa.'
                                  : 'Failed to save profile.',
                            );
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          swahili
                              ? 'Hifadhi'
                              : 'Save',
                        ),
                ),
              ],
            );
          },
        );
      },
    );

    fullNameController.dispose();
    phoneController.dispose();
    pharmacyNameController.dispose();

    if (!mounted) {
      return;
    }

    if (result == true) {
      _showMessage(
        swahili
            ? 'Taarifa zimehifadhiwa kwa mafanikio.'
            : 'Profile updated successfully.',
      );
    }
  }

  String _firebaseErrorMessage(
    FirebaseException error,
    bool swahili,
  ) {
    switch (error.code) {
      case 'permission-denied':
        return swahili
            ? 'Huna ruhusa ya kuhifadhi taarifa hizi.'
            : 'You do not have permission to update this profile.';

      case 'not-found':
        return swahili
            ? 'Taarifa za akaunti hazikupatikana.'
            : 'Account profile was not found.';

      case 'network-request-failed':
        return swahili
            ? 'Hakuna muunganisho wa intaneti.'
            : 'Network connection failed.';

      default:
        return swahili
            ? 'Imeshindikana kuhifadhi taarifa.'
            : 'Failed to save profile.';
    }
  }

  void _openSecurity() {
    final swahili = appController.isSwahili;

    final currentPasswordController =
        TextEditingController();
    final newPasswordController =
        TextEditingController();
    final confirmPasswordController =
        TextEditingController();

    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool saving = false;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final navigator = Navigator.of(dialogContext);

        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(
                swahili
                    ? 'Badilisha Nenosiri'
                    : 'Change Password',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller:
                          currentPasswordController,
                      obscureText: obscureCurrent,
                      enabled: !saving,
                      decoration: InputDecoration(
                        labelText: swahili
                            ? 'Nenosiri la sasa'
                            : 'Current password',
                        prefixIcon:
                            const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setDialogState(() {
                              obscureCurrent =
                                  !obscureCurrent;
                            });
                          },
                          icon: Icon(
                            obscureCurrent
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: newPasswordController,
                      obscureText: obscureNew,
                      enabled: !saving,
                      decoration: InputDecoration(
                        labelText: swahili
                            ? 'Nenosiri jipya'
                            : 'New password',
                        prefixIcon: const Icon(
                          Icons.lock_reset_outlined,
                        ),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setDialogState(() {
                              obscureNew =
                                  !obscureNew;
                            });
                          },
                          icon: Icon(
                            obscureNew
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller:
                          confirmPasswordController,
                      obscureText: obscureConfirm,
                      enabled: !saving,
                      decoration: InputDecoration(
                        labelText: swahili
                            ? 'Thibitisha nenosiri jipya'
                            : 'Confirm new password',
                        prefixIcon: const Icon(
                          Icons.lock_clock_outlined,
                        ),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setDialogState(() {
                              obscureConfirm =
                                  !obscureConfirm;
                            });
                          },
                          icon: Icon(
                            obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () {
                          currentPasswordController.dispose();
                          newPasswordController.dispose();
                          confirmPasswordController.dispose();
                          navigator.pop();
                        },
                  child: Text(
                    swahili ? 'Ghairi' : 'Cancel',
                  ),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final current =
                              currentPasswordController
                                  .text
                                  .trim();
                          final newPassword =
                              newPasswordController
                                  .text
                                  .trim();
                          final confirm =
                              confirmPasswordController
                                  .text
                                  .trim();

                          if (current.isEmpty ||
                              newPassword.isEmpty ||
                              confirm.isEmpty) {
                            _showMessage(
                              swahili
                                  ? 'Jaza taarifa zote.'
                                  : 'Fill in all fields.',
                            );
                            return;
                          }

                          if (newPassword.length < 6) {
                            _showMessage(
                              swahili
                                  ? 'Nenosiri jipya lazima liwe na angalau herufi 6.'
                                  : 'New password must be at least 6 characters.',
                            );
                            return;
                          }

                          if (newPassword != confirm) {
                            _showMessage(
                              swahili
                                  ? 'Nenosiri jipya halifanani.'
                                  : 'New passwords do not match.',
                            );
                            return;
                          }

                          final user =
                              FirebaseAuth.instance.currentUser;

                          if (user == null ||
                              user.email == null) {
                            _showMessage(
                              swahili
                                  ? 'Akaunti haipatikani.'
                                  : 'Account not found.',
                            );
                            return;
                          }

                          setDialogState(() {
                            saving = true;
                          });

                          try {
                            final credential =
                                EmailAuthProvider.credential(
                              email: user.email!,
                              password: current,
                            );

                            await user
                                .reauthenticateWithCredential(
                              credential,
                            );

                            await user.updatePassword(
                              newPassword,
                            );

                            if (!mounted) {
                              return;
                            }

                            if (navigator.mounted) {
                              navigator.pop();
                            }

                            currentPasswordController.dispose();
                            newPasswordController.dispose();
                            confirmPasswordController.dispose();

                            _showMessage(
                              swahili
                                  ? 'Nenosiri limebadilishwa kwa mafanikio.'
                                  : 'Password changed successfully.',
                            );
                          } on FirebaseAuthException catch (e) {
                            setDialogState(() {
                              saving = false;
                            });

                            String message;

                            switch (e.code) {
                              case 'wrong-password':
                              case 'invalid-credential':
                                message = swahili
                                    ? 'Nenosiri la sasa si sahihi.'
                                    : 'Current password is incorrect.';
                                break;

                              case 'weak-password':
                                message = swahili
                                    ? 'Nenosiri jipya ni dhaifu.'
                                    : 'The new password is too weak.';
                                break;

                              case 'requires-recent-login':
                                message = swahili
                                    ? 'Tafadhali ingia tena kisha ujaribu kubadilisha nenosiri.'
                                    : 'Please sign in again and then change the password.';
                                break;

                              default:
                                message = swahili
                                    ? 'Imeshindikana kubadilisha nenosiri.'
                                    : 'Failed to change password.';
                            }

                            _showMessage(message);
                          } catch (_) {
                            setDialogState(() {
                              saving = false;
                            });

                            _showMessage(
                              swahili
                                  ? 'Kuna tatizo limetokea.'
                                  : 'Something went wrong.',
                            );
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          swahili
                              ? 'Hifadhi'
                              : 'Save',
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }


  Future<void> _openSubscription() async {
    final swahili = appController.isSwahili;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        swahili
            ? 'Akaunti haipatikani.'
            : 'Account not found.',
      );
      return;
    }

    try {
      final profile =
          await _authService.getCurrentUserProfile();

      final pharmacyId =
          profile?['pharmacyId']?.toString() ??
              user.uid;

      final subscriptionService =
          SubscriptionService.instance;

      final subscription =
          await subscriptionService.getPharmacySubscription(
        pharmacyId,
      );

      final scheduledRenewal =
          await subscriptionService.getScheduledRenewal(
        pharmacyId,
      );

      if (!mounted) {
        return;
      }

      if (subscription == null) {
        _showMessage(
          swahili
              ? 'Taarifa za usajili hazijapatikana.'
              : 'Subscription information was not found.',
        );
        return;
      }

      // ============================================================
      // CURRENT SUBSCRIPTION
      // ============================================================

      final currentPlan =
          subscription['subscriptionPlan']
                      ?.toString()
                      .trim()
                      .isNotEmpty ==
                  true
              ? subscription['subscriptionPlan'].toString()
              : (swahili ? 'Haijawekwa' : 'Not Set');

      final currentStatus =
          subscription['subscriptionStatus']
                      ?.toString()
                      .trim()
                      .isNotEmpty ==
                  true
              ? subscription['subscriptionStatus'].toString()
              : (swahili ? 'Haijawekwa' : 'Not Set');

      final currentStart = _formatSubscriptionDate(
        subscription['subscriptionStartAt'],
        swahili,
      );

      final currentEnd = _formatSubscriptionDate(
        subscription['subscriptionEndAt'],
        swahili,
      );

      // ============================================================
      // NEXT / SCHEDULED SUBSCRIPTION
      // ============================================================

      String? nextPlan;
      String? nextStatus;
      String? nextStart;
      String? nextEnd;
      String? nextPrice;
      String? nextMonths;

      if (scheduledRenewal != null) {
        final scheduledPlan =
            scheduledRenewal['plan']
                ?.toString()
                .trim();

        final scheduledStatus =
            scheduledRenewal['status']
                ?.toString()
                .trim();

        final scheduledPrice =
            scheduledRenewal['price'];

        final scheduledMonths =
            scheduledRenewal['months'];

        if (scheduledPlan != null &&
            scheduledPlan.isNotEmpty) {
          nextPlan = scheduledPlan;
        }

        if (scheduledStatus != null &&
            scheduledStatus.isNotEmpty) {
          nextStatus = scheduledStatus;
        }

        nextStart = _formatSubscriptionDate(
          scheduledRenewal['startAt'],
          swahili,
        );

        nextEnd = _formatSubscriptionDate(
          scheduledRenewal['endAt'],
          swahili,
        );

        if (scheduledPrice != null) {
          final parsedPrice =
              int.tryParse(
            scheduledPrice.toString(),
          );

          if (parsedPrice != null) {
            nextPrice =
                'TSh ${_formatSubscriptionAmount(parsedPrice)}';
          } else {
            nextPrice =
                'TSh $scheduledPrice';
          }
        }

        if (scheduledMonths != null) {
          final parsedMonths =
              int.tryParse(
            scheduledMonths.toString(),
          );

          if (parsedMonths != null) {
            nextMonths = parsedMonths == 1
                ? (swahili ? 'Mwezi 1' : '1 Month')
                : (swahili
                    ? 'Miezi $parsedMonths'
                    : '$parsedMonths Months');
          }
        }
      }

      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          final colorScheme =
              Theme.of(dialogContext).colorScheme;

          return AlertDialog(
            title: Text(
              swahili
                  ? 'Usajili Wangu'
                  : 'My Subscription',
            ),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 430,
                maxHeight:
                    MediaQuery.of(dialogContext).size.height * 0.62,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ==================================================
                    // CURRENT SUBSCRIPTION
                    // ==================================================

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        swahili
                            ? 'Usajili wa Sasa'
                            : 'Current Subscription',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    _subscriptionInfoRow(
                      icon: Icons.card_membership_outlined,
                      label: swahili ? 'Mpango' : 'Plan',
                      value: currentPlan,
                    ),

                    const SizedBox(height: 12),

                    _subscriptionInfoRow(
                      icon: Icons.verified_outlined,
                      label: swahili ? 'Hali' : 'Status',
                      value: currentStatus,
                    ),

                    const SizedBox(height: 12),

                    _subscriptionInfoRow(
                      icon: Icons.event_outlined,
                      label: swahili ? 'Mwanzo' : 'Start',
                      value: currentStart,
                    ),

                    const SizedBox(height: 12),

                    _subscriptionInfoRow(
                      icon: Icons.event_available_outlined,
                      label: swahili ? 'Mwisho' : 'End',
                      value: currentEnd,
                    ),

                    // ==================================================
                    // SCHEDULED NEXT SUBSCRIPTION
                    // ==================================================

                    if (scheduledRenewal != null &&
                        nextPlan != null) ...[
                      const SizedBox(height: 20),

                      Divider(
                        color: colorScheme.outlineVariant,
                      ),

                      const SizedBox(height: 16),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer
                              .withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.schedule_outlined,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                swahili
                                    ? 'Subscription Inayofuata'
                                    : 'Next Subscription',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: colorScheme
                                      .onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      _subscriptionInfoRow(
                        icon: Icons.card_membership_outlined,
                        label: swahili ? 'Mpango' : 'Plan',
                        value: nextPlan,
                      ),

                      if (nextStatus != null) ...[
                        const SizedBox(height: 12),
                        _subscriptionInfoRow(
                          icon: Icons.schedule_outlined,
                          label: swahili ? 'Hali' : 'Status',
                          value: nextStatus,
                        ),
                      ],

                      if (nextPrice != null) ...[
                        const SizedBox(height: 12),
                        _subscriptionInfoRow(
                          icon: Icons.payments_outlined,
                          label: swahili ? 'Bei' : 'Price',
                          value: nextPrice,
                        ),
                      ],

                      if (nextMonths != null) ...[
                        const SizedBox(height: 12),
                        _subscriptionInfoRow(
                          icon: Icons.calendar_month_outlined,
                          label: swahili ? 'Muda' : 'Duration',
                          value: nextMonths,
                        ),
                      ],

                      const SizedBox(height: 12),

                      _subscriptionInfoRow(
                        icon: Icons.event_outlined,
                        label: swahili ? 'Mwanzo' : 'Start',
                        value: nextStart ??
                            (swahili ? 'Haijawekwa' : 'Not Set'),
                      ),

                      const SizedBox(height: 12),

                      _subscriptionInfoRow(
                        icon: Icons.event_available_outlined,
                        label: swahili ? 'Mwisho' : 'End',
                        value: nextEnd ??
                            (swahili ? 'Haijawekwa' : 'Not Set'),
                      ),

                      const SizedBox(height: 14),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.60),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 20,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                swahili
                                    ? 'Malipo yamepokelewa. Subscription hii itaanza baada ya subscription ya sasa kuisha.'
                                    : 'Payment has been received. This subscription will start after the current subscription ends.',
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.4,
                                  color: colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: Text(
                  swahili ? 'Funga' : 'Close',
                ),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(dialogContext);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          SubscriptionPlansScreen(
                        appController: appController,
                      ),
                    ),
                  );
                },
                child: Text(
                  swahili
                      ? 'Weka/Renew'
                      : 'Subscribe/Renew',
                ),
              ),
            ],
          );
        },
      );
    } on FirebaseException catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        swahili
            ? 'Imeshindikana kusoma usajili: ${e.message ?? e.code}'
            : 'Failed to load subscription: ${e.message ?? e.code}',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        swahili
            ? 'Imeshindikana kusoma usajili: $e'
            : 'Failed to load subscription: $e',
      );
    }
  }

  String _formatSubscriptionAmount(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match.group(1)},',
        );
  }

  Widget _subscriptionInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 10),
        SizedBox(
          width: 74,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }

  String _formatSubscriptionDate(
    dynamic value,
    bool swahili,
  ) {
    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    } else if (value is String && value.trim().isNotEmpty) {
      date = DateTime.tryParse(value.trim());
    }

    if (date == null) {
      return swahili ? 'Haijawekwa' : 'Not Set';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
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
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              14,
              16,
              6,
            ),
            child: Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}