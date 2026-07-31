import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:crypto/crypto.dart' as crypto;
import '../models/update_info_model.dart';

class UpdateLocalDataSource {
  Future<String> downloadUpdate(
    UpdateInfoModel updateInfo, {
    required void Function(double) onProgress,
  }) async {
    if (Platform.isIOS) {
      onProgress(1.0);
      return updateInfo.downloadUrl;
    }

    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(updateInfo.downloadUrl));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to download update file: status ${response.statusCode}',
        );
      }

      final totalBytes = response.contentLength ?? updateInfo.fileSize;
      int receivedBytes = 0;

      final tempDir = await getTemporaryDirectory();
      final fileName = updateInfo.downloadUrl.split('/').last;
      final savePath = '${tempDir.path}/$fileName';
      final file = File(savePath);
      final sink = file.openWrite();

      await response.stream.forEach((List<int> chunk) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          onProgress(receivedBytes / totalBytes);
        }
      });

      await sink.flush();
      await sink.close();

      if (updateInfo.checksum != null && updateInfo.checksum!.isNotEmpty) {
        final bytes = await file.readAsBytes();
        final digest = crypto.sha256.convert(bytes);
        if (digest.toString().toUpperCase() !=
            updateInfo.checksum!.toUpperCase()) {
          if (await file.exists()) {
            await file.delete();
          }
          throw Exception('Checksum verification failed');
        }
      }

      return savePath;
    } finally {
      client.close();
    }
  }

  Future<bool> applyUpdate(String filePath, UpdateInfoModel updateInfo) async {
    if (Platform.isIOS) {
      final uri = Uri.parse(updateInfo.downloadUrl);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return false;
    }

    final result = await OpenFile.open(filePath);
    return result.type == ResultType.done;
  }
}
