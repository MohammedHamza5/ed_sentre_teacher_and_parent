import 'package:flutter/foundation.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:ed_sentre_techer_and_parent/core/di/setup_di.dart';
import 'package:ed_sentre_techer_and_parent/core/services/notification_service.dart';

class ShorebirdUpdateService {
  ShorebirdUpdateService._();
  static final ShorebirdUpdateService _instance = ShorebirdUpdateService._();
  factory ShorebirdUpdateService() => _instance;

  final _updater = ShorebirdUpdater();

  Future<void> initialize() async {
    // Shorebird Code Push is only available on Android and iOS devices.
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      try {
        final isAvailable = _updater.isAvailable;
        if (isAvailable) {
          debugPrint('🐦 [Shorebird] Available on this device.');

          final currentPatch = await _updater.readCurrentPatch();
          debugPrint(
            '🐦 [Shorebird] Current Patch: ${currentPatch?.number ?? "Base Release (No Patch)"}',
          );

          // Check for updates in the background silently
          _checkForUpdates();
        } else {
          debugPrint('🐦 [Shorebird] Not available in this environment');
        }
      } catch (e, stackTrace) {
        debugPrint('♦️ [Shorebird Error] Initialization failed: $e');
        debugPrint(stackTrace.toString());
      }
    }
  }

  Future<void> _checkForUpdates() async {
    try {
      debugPrint('🐦 [Shorebird] Checking for new patches...');
      final status = await _updater.checkForUpdate();

      if (status == UpdateStatus.outdated) {
        debugPrint(
          '🐦 [Shorebird] New Patch Available! Downloading in background...',
        );

        // Download the patch in the background. It will be applied automatically
        // the next time the app starts (Cold Start) to avoid disrupting the user.
        await _updater.update();

        debugPrint(
          '🐦 [Shorebird] Patch Downloaded successfully. It will be applied on the next app restart.',
        );

        // Notify the user subtly that an update will be applied on next restart
        _showUpdateNotification();
      } else {
        debugPrint('🐦 [Shorebird] No new patch available.');
      }
    } catch (e, stackTrace) {
      debugPrint('♦️ [Shorebird Error] Update Check/Download failed: $e');
      debugPrint(stackTrace.toString());
    }
  }

  void _showUpdateNotification() {
    try {
      final notificationService = sl<NotificationService>();
      notificationService.showLocalNotification(
        title: 'تحديث جديد جاهز',
        body:
            'تم تنزيل تحديث جديد للتطبيق. سيتم تطبيقه في المرة القادمة التي تفتح فيها التطبيق.',
      );
    } catch (e) {
      debugPrint('🐦 [Shorebird] Could not show notification. Skipping...');
    }
  }
}
