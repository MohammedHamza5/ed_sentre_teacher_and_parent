import '../../../../core/config/app_config.dart';
import '../../../../core/errors/errors.dart';
import '../data_sources/update_local_data_source.dart';
import '../data_sources/update_remote_data_source.dart';
import '../models/update_info_model.dart';

class UpdateRepository {
  final UpdateRemoteDataSource remoteDataSource;
  final UpdateLocalDataSource localDataSource;

  UpdateRepository({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  Future<Result<UpdateInfoModel?>> checkUpdate() async {
    try {
      final remoteVersion = await remoteDataSource.getLatestVersion();
      if (remoteVersion == null) {
        return Result.success(null);
      }

      final currentVersion = AppConfig.appVersion;
      if (_isNewerVersion(remoteVersion.version, currentVersion)) {
        return Result.success(remoteVersion);
      }
      return Result.success(null);
    } catch (e, st) {
      return Result.failure(ServerException(message: e.toString(), originalError: e, stackTrace: st));
    }
  }

  Future<Result<String>> downloadUpdate(
    UpdateInfoModel updateInfo, {
    required void Function(double) onProgress,
  }) async {
    try {
      final path = await localDataSource.downloadUpdate(updateInfo, onProgress: onProgress);
      return Result.success(path);
    } catch (e, st) {
      return Result.failure(ServerException(message: e.toString(), originalError: e, stackTrace: st));
    }
  }

  Future<Result<bool>> applyUpdate(String filePath, UpdateInfoModel updateInfo) async {
    try {
      final result = await localDataSource.applyUpdate(filePath, updateInfo);
      return Result.success(result);
    } catch (e, st) {
      return Result.failure(ServerException(message: e.toString(), originalError: e, stackTrace: st));
    }
  }

  bool _isNewerVersion(String remote, String current) {
    try {
      final cleanRemote = remote.split('+').first;
      final cleanCurrent = current.split('+').first;
      
      final remoteBuild = remote.contains('+') ? int.tryParse(remote.split('+').last) ?? 0 : 0;
      final currentBuild = current.contains('+') ? int.tryParse(current.split('+').last) ?? 0 : 0;

      final rParts = cleanRemote.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final cParts = cleanCurrent.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      for (int i = 0; i < 3; i++) {
        final r = i < rParts.length ? rParts[i] : 0;
        final c = i < cParts.length ? cParts[i] : 0;
        if (r > c) return true;
        if (r < c) return false;
      }

      return remoteBuild > currentBuild;
    } catch (_) {
      return false;
    }
  }
}
