import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Manages OS-level screen protection to prevent screenshots and screen recording.
class ScreenProtectionManager {
  // Assuming we use a method channel to talk to native iOS/Android code
  // Alternatively, this could wrap a package like `flutter_windowmanager` or `screen_protector`.
  static const MethodChannel _channel = MethodChannel('com.edsentre/screen_protection');

  /// Enables OS-level screenshot blocking (e.g., FLAG_SECURE on Android).
  static Future<void> enableScreenshotProtection() async {
    if (kIsWeb) return; // Not reliably possible on Web
    try {
      await _channel.invokeMethod('enableSecureMode');
    } on PlatformException catch (e) {
      debugPrint('Failed to enable secure mode: ${e.message}');
    }
  }

  /// Disables OS-level screenshot blocking.
  static Future<void> disableScreenshotProtection() async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod('disableSecureMode');
    } on PlatformException catch (e) {
      debugPrint('Failed to disable secure mode: ${e.message}');
    }
  }

  /// Listens for screen recording events (especially relevant for iOS where 
  /// recording can't always be blocked natively, only detected).
  ///
  /// The native side should emit events when `UIScreen.capturedDidChangeNotification` fires.
  static Stream<bool> get isScreenRecordingStream {
    if (kIsWeb) return Stream.value(false);
    const EventChannel eventChannel = EventChannel('com.edsentre/screen_recording_events');
    return eventChannel.receiveBroadcastStream().map((dynamic event) => event as bool);
  }

  /// Checks the current state of screen recording immediately.
  static Future<bool> isScreenBeingRecorded() async {
    if (kIsWeb) return false;
    try {
      final bool isRecording = await _channel.invokeMethod('isScreenRecording');
      return isRecording;
    } on PlatformException catch (_) {
      return false;
    }
  }
}
