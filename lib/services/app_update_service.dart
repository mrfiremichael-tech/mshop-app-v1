import 'package:flutter/material.dart';
import 'package:in_app_update_me/in_app_update_me.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppUpdateService {
  AppUpdateService._();

  static final AppUpdateService instance =
      AppUpdateService._();

  final InAppUpdateMe _updater =
      InAppUpdateMe();

  // Tutaiweka URL halisi ya update manifest
  // baada ya kuandaa Firebase Hosting.
  static const String updateCheckUrl =
      'https://mshop-pharmacy.web.app/app_updates/app_update.json';

  Future<void> checkForForcedUpdate(
    BuildContext context,
  ) async {
    try {
      final packageInfo =
          await PackageInfo.fromPlatform();

      final currentVersion =
          packageInfo.version.trim();

      final info =
          await _updater.checkForUpdate(
        useStore: false,
        updateUrl: updateCheckUrl,
        currentVersion: currentVersion,
        timeout:
            const Duration(seconds: 15),
      );

      if (!context.mounted) {
        return;
      }

      if (info == null ||
          info.updateAvailable != true) {
        return;
      }

      if (info.shouldForceUpdate != true) {
        return;
      }

      await ForceUpdateDialog.show(
        context,
        info,
        const UpdateConfig(
          useStore: false,
          forceUpdate: true,
          minimumPriority:
              UpdatePriority.low,
        ),
        onError: (error) {
          debugPrint(
            'M-Shop update error: $error',
          );
        },
      );
    } catch (error) {
      debugPrint(
        'M-Shop update check failed: $error',
      );
    }
  }
}