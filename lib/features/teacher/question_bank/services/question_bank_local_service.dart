import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'package:ed_sentre_techer_and_parent/shared/models/exam_models.dart'; // للحصول على ExamQuestion

class SavedQuestion {
  final String id;
  final ExamQuestion question;
  final DateTime savedAt;
  final List<String> tags;

  SavedQuestion({
    required this.id,
    required this.question,
    required this.savedAt,
    this.tags = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question.toJson(),
        'savedAt': savedAt.toIso8601String(),
        'tags': tags,
      };

  factory SavedQuestion.fromJson(Map<String, dynamic> json) => SavedQuestion(
        id: json['id'] as String,
        question: ExamQuestion.fromJson(json['question'] as Map<String, dynamic>),
        savedAt: DateTime.parse(json['savedAt'] as String),
        tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      );
}

class QuestionBankLocalService {
  static const String _fileName = 'personal_question_bank.json';

  Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<List<SavedQuestion>> getSavedQuestions() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return [];

      final contents = await file.readAsString();
      if (contents.isEmpty) return [];

      final List<dynamic> jsonList = jsonDecode(contents);
      return jsonList.map((e) => SavedQuestion.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error reading question bank: $e');
      return [];
    }
  }

  Future<void> saveQuestion(ExamQuestion question, {List<String> tags = const []}) async {
    try {
      final questions = await getSavedQuestions();
      
      // لا تحفظ السؤال إذا كان موجوداً مسبقاً بنفس النص
      if (questions.any((q) => q.question.text == question.text)) return;

      questions.insert(0, SavedQuestion(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        question: question,
        savedAt: DateTime.now(),
        tags: tags,
      ));

      final file = await _getFile();
      await file.writeAsString(jsonEncode(questions.map((q) => q.toJson()).toList()));
    } catch (e) {
      debugPrint('Error saving to question bank: $e');
    }
  }

  Future<void> deleteQuestion(String savedQuestionId) async {
    try {
      final questions = await getSavedQuestions();
      questions.removeWhere((q) => q.id == savedQuestionId);

      final file = await _getFile();
      await file.writeAsString(jsonEncode(questions.map((q) => q.toJson()).toList()));
    } catch (e) {
      debugPrint('Error deleting from question bank: $e');
    }
  }
}
