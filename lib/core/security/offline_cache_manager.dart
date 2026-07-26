import 'dart:io';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Manages secure, encrypted storage of files for offline access.
class OfflineCacheManager {
  static const String _kEncryptionKeyId = 'offline_cache_encryption_key';
  final FlutterSecureStorage _secureStorage;
  final Uuid _uuid;

  OfflineCacheManager({
    FlutterSecureStorage? secureStorage,
    Uuid? uuid,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _uuid = uuid ?? const Uuid();

  /// Retrieves or generates a robust 32-byte encryption key for AES-256.
  Future<enc.Key> _getEncryptionKey() async {
    final existingBase64 = await _secureStorage.read(key: _kEncryptionKeyId);
    if (existingBase64 != null && existingBase64.isNotEmpty) {
      return enc.Key.fromBase64(existingBase64);
    }

    // Generate new 32-byte secure key
    final newKey = enc.Key.fromSecureRandom(32);
    await _secureStorage.write(
      key: _kEncryptionKeyId,
      value: newKey.base64,
    );
    return newKey;
  }

  /// Writes raw bytes to an encrypted file on disk.
  Future<File> writeEncryptedFile(String filename, List<int> rawBytes) async {
    final key = await _getEncryptionKey();
    // Using a fixed IV length for AES, stored alongside or freshly generated
    // For simplicity, we generate a random IV for every file and prepend it
    final iv = enc.IV.fromSecureRandom(16);
    
    final encrypter = enc.Encrypter(enc.AES(key));
    final encrypted = encrypter.encryptBytes(rawBytes, iv: iv);

    // Combine IV + encrypted data so we can decrypt later
    final finalBytes = <int>[...iv.bytes, ...encrypted.bytes];

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename.enc');
    return await file.writeAsBytes(finalBytes, flush: true);
  }

  /// Reads an encrypted file from disk and returns the raw decrypted bytes.
  Future<List<int>> readEncryptedFile(String filename) async {
    final key = await _getEncryptionKey();
    
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename.enc');
    
    if (!await file.exists()) {
      throw FileSystemException('Encrypted file not found', file.path);
    }

    final allBytes = await file.readAsBytes();
    if (allBytes.length <= 16) {
      throw FormatException('File is too small to contain IV and data');
    }

    // Extract IV (first 16 bytes) and ciphertext
    final ivBytes = allBytes.sublist(0, 16);
    final cipherBytes = allBytes.sublist(16);
    
    final iv = enc.IV(Uint8List.fromList(ivBytes));
    final encrypter = enc.Encrypter(enc.AES(key));
    
    final encrypted = enc.Encrypted(Uint8List.fromList(cipherBytes));
    final decrypted = encrypter.decryptBytes(encrypted, iv: iv);
    
    return decrypted;
  }

  /// Invalidates the entire cache by deleting the encryption key.
  /// All existing files will be rendered permanently unreadable.
  Future<void> invalidateCache() async {
    await _secureStorage.delete(key: _kEncryptionKeyId);
    
    // Optionally delete all .enc files in the documents directory to free space.
    final dir = await getApplicationDocumentsDirectory();
    final entities = await dir.list().toList();
    for (final entity in entities) {
      if (entity is File && entity.path.endsWith('.enc')) {
        await entity.delete();
      }
    }
  }
}

