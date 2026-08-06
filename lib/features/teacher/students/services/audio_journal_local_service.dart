import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class AudioJournalLocalService {
  static const String _fileName = 'audio_journals.json';

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  Future<List<Map<String, dynamic>>> getNotesForStudent(String studentId) async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return [];

      final content = await file.readAsString();
      final List<dynamic> data = json.decode(content);

      final List<Map<String, dynamic>> allNotes =
          List<Map<String, dynamic>>.from(data);

      return allNotes.where((note) => note['student_id'] == studentId).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveNote({
    required String studentId,
    required String title,
    required int durationSeconds,
  }) async {
    try {
      final file = await _getFile();
      List<Map<String, dynamic>> allNotes = [];

      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> data = json.decode(content);
        allNotes = List<Map<String, dynamic>>.from(data);
      }

      allNotes.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'student_id': studentId,
        'title': title,
        'duration_seconds': durationSeconds,
        'date': DateTime.now().toIso8601String(),
      });

      await file.writeAsString(json.encode(allNotes));
    } catch (e) {
      // Silently fail for now
    }
  }

  Future<void> deleteNote(String noteId) async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return;

      final content = await file.readAsString();
      final List<dynamic> data = json.decode(content);
      List<Map<String, dynamic>> allNotes = List<Map<String, dynamic>>.from(data);

      allNotes.removeWhere((note) => note['id'] == noteId);

      await file.writeAsString(json.encode(allNotes));
    } catch (e) {
      // Silently fail
    }
  }
}
