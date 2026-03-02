import 'package:supabase_flutter/supabase_flutter.dart';
import '../base_repository.dart';

/// Storage Repository Mixin
/// Handles file uploads and public URL generation
mixin StorageRepositoryMixin on BaseRepository {
  SupabaseClient get client;

  // ═══════════════════════════════════════════════════════════════════════
  // FILE STORAGE
  // ═══════════════════════════════════════════════════════════════════════

  /// Upload file
  Future<String> uploadFile({
    required String bucket,
    required String path,
    required List<int> bytes,
    String? contentType,
  }) async {
    await client.storage
        .from(bucket)
        .uploadBinary(
          path,
          bytes as dynamic,
          fileOptions: FileOptions(contentType: contentType),
        );

    return client.storage.from(bucket).getPublicUrl(path);
  }

  /// Get public URL
  String getPublicUrl(String bucket, String path) {
    return client.storage.from(bucket).getPublicUrl(path);
  }
}
