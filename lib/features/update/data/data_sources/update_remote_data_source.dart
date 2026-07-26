import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/update_info_model.dart';

class UpdateRemoteDataSource {
  final SupabaseClient _supabase;

  UpdateRemoteDataSource(this._supabase);

  Future<UpdateInfoModel?> getLatestVersion() async {
    final platform = Platform.isAndroid
        ? 'teacher_android'
        : Platform.isIOS
            ? 'teacher_ios'
            : Platform.isWindows
                ? 'teacher_windows'
                : 'teacher_android';

    final response = await _supabase
        .from('app_versions')
        .select()
        .eq('platform', platform)
        .order('created_at', ascending: false)
        .limit(1);

    if (response.isEmpty) {
      return null;
    }

    return UpdateInfoModel.fromJson(response.first as Map<String, dynamic>);
  }
}
