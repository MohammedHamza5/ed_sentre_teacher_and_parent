import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

/// Manages a persistent, cryptographically secure identifier for this specific device.
/// Used for binding a user's session to their physical hardware to prevent account sharing.
class DeviceBindingManager {
  static const String _kDeviceIdKey = 'secure_device_binding_id';
  final FlutterSecureStorage _secureStorage;
  final Uuid _uuid;
  final SupabaseClient _supabase;

  DeviceBindingManager({
    FlutterSecureStorage? secureStorage,
    Uuid? uuid,
    SupabaseClient? supabase,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
       _uuid = uuid ?? const Uuid(),
       _supabase = supabase ?? Supabase.instance.client;

  /// Retrieves the existing device ID, or generates and securely stores a new one if it doesn't exist.
  /// Then registers the device with Supabase, which will automatically revoke older devices for this user.
  Future<String> registerDeviceWithServer() async {
    String? deviceId = await _secureStorage.read(key: _kDeviceIdKey);
    if (deviceId == null || deviceId.isEmpty) {
      deviceId = _uuid.v4();
      await _secureStorage.write(key: _kDeviceIdKey, value: deviceId);
    }

    String deviceName = 'Unknown Device';
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceName = '${androidInfo.manufacturer} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceName = iosInfo.name;
      }
    } catch (_) {
      // Ignore device info errors
    }

    // Call the Supabase RPC to register this device and revoke others
    try {
      await _supabase.rpc(
        'register_user_device',
        params: {'p_device_identifier': deviceId, 'p_device_name': deviceName},
      );
    } catch (_) {
      // Ignore RPC failure (e.g., offline mode or unauthorized)
    }

    return deviceId;
  }


  /// Clears the device ID. This should generally only be done upon a complete app reset
  /// or if a binding needs to be forcibly revoked client-side.
  Future<void> clearDeviceBinding() async {
    await _secureStorage.delete(key: _kDeviceIdKey);
  }
}
