import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/models/exam_models.dart';
import '../../question_bank/services/question_bank_local_service.dart';
import '../../question_bank/widgets/import_from_bank_dialog.dart';

class QuizQuestionsEditor extends StatefulWidget {
  final List<Map<String, dynamic>> questions;
  final Function(List<Map<String, dynamic>>) onQuestionsChanged;
  final Color typeColor;
  final String maxScoreStr;

  const QuizQuestionsEditor({
    super.key,
    required this.questions,
    required this.onQuestionsChanged,
    required this.typeColor,
    required this.maxScoreStr,
  });

  @override
  State<QuizQuestionsEditor> createState() => _QuizQuestionsEditorState();
}

class _QuizQuestionsEditorState extends State<QuizQuestionsEditor> {
  void _addQuestion() {
    showDialog(
      context: context,
      builder: (context) => QuestionDialog(
        typeColor: widget.typeColor,
        onSave: (q) {
          final updated = List<Map<String, dynamic>>.from(widget.questions)..add(q);
          widget.onQuestionsChanged(updated);
        },
      ),
    );
  }

  void _removeQuestionAt(int index) {
    final updated = List<Map<String, dynamic>>.from(widget.questions)..removeAt(index);
    widget.onQuestionsChanged(updated);
  }

  void _importFromBank() async {
    final ExamQuestion? importedQuestion = await showDialog<ExamQuestion>(
      context: context,
      builder: (context) => ImportFromBankDialog(typeColor: widget.typeColor),
    );

    if (importedQuestion != null) {
      final qMap = <String, dynamic>{
        'question': importedQuestion.text,
        'type': importedQuestion.type.name,
        'marks': importedQuestion.marks,
      };
      
      if (importedQuestion.options != null && importedQuestion.options!.isNotEmpty) {
        qMap['options'] = importedQuestion.options!;
        if (importedQuestion.correctAnswer != null) {
          qMap['correct'] = importedQuestion.options!.indexOf(importedQuestion.correctAnswer!);
        }
      } else if (importedQuestion.correctAnswer != null) {
         qMap['correct_answer'] = importedQuestion.correctAnswer!;
      }

      final updated = List<Map<String, dynamic>>.from(widget.questions)..add(qMap);
      widget.onQuestionsChanged(updated);
    }
  }

  void _saveToBank(int index) async {
    final q = widget.questions[index];
    final examQ = ExamQuestion(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      assignmentId: 'bank',
      text: q['question'] ?? '',
      type: q['type'] == 'mcq' ? QuestionType.mcq : QuestionType.essay,
      marks: (q['marks'] as num?)?.toDouble() ?? 5.0,
      options: (q['options'] as List?)?.map((e) => e.toString()).toList(),
      correctAnswer: q['correct'] != null && q['options'] != null 
          ? (q['correct'] >= 0 ? q['options'][q['correct']] : null) 
          : q['correct_answer'],
      orderIndex: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await QuestionBankLocalService().saveQuestion(examQ);
    if(mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحفظ في البنك 🌟', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Questions count
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: widget.typeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: widget.typeColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.quiz, color: widget.typeColor),
              SizedBox(width: 12.w),
              Text(
                'عدد الأسئلة: ${widget.questions.length}',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                'الدرجة لكل سؤال: ${widget.questions.isNotEmpty ? ((int.tryParse(widget.maxScoreStr) ?? 20) / widget.questions.length).toStringAsFixed(1) : '—'}',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),

        // Questions List
        if (widget.questions.isEmpty)
          Container(
            padding: EdgeInsets.all(32.w),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.quiz,
                  size: 48.sp,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                SizedBox(height: 12.h),
                Text(
                  'لا توجد أسئلة',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'أضف سؤال واحد على الأقل',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          )
        else
          ...List.generate(widget.questions.length, (i) => _buildQuestionCard(context, i)),

        SizedBox(height: 16.h),

        // Add & Import Question Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _addQuestion,
                icon: Icon(Icons.add_circle_outline, color: widget.typeColor),
                label: Text('إضافة سؤال', style: TextStyle(color: widget.typeColor, fontSize: 13.sp)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: widget.typeColor),
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _importFromBank,
                icon: Icon(Icons.inventory_2_outlined, color: widget.typeColor),
                label: Text('من البنك', style: TextStyle(color: widget.typeColor, fontSize: 13.sp)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: widget.typeColor),
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuestionCard(BuildContext context, int index) {
    final q = widget.questions[index];
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: widget.typeColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14.r,
                backgroundColor: widget.typeColor,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(color: Colors.white, fontSize: 12.sp),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  q['question'] ?? '',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.save_alt_rounded,
                  color: widget.typeColor,
                  size: 20.sp,
                ),
                onPressed: () => _saveToBank(index),
                tooltip: 'حفظ في البنك',
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error,
                  size: 20.sp,
                ),
                onPressed: () => _removeQuestionAt(index),
              ),
            ],
          ),
          if (q['options'] != null) ...[
            SizedBox(height: 8.h),
            ...List.generate(
              (q['options'] as List).length,
              (i) => Padding(
                padding: EdgeInsets.only(right: 32.w, top: 4.h),
                child: Row(
                  children: [
                    Icon(
                      q['correct'] == i
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      size: 16.sp,
                      color: q['correct'] == i
                          ? Colors.green
                          : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      q['options'][i],
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: q['correct'] == i
                            ? Colors.green
                            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Question Dialog - Supports MCQ, True/False, Short Answer, Essay
// ════════════════════════════════════════════════════════════════════
class QuestionDialog extends StatefulWidget {
  final Color typeColor;
  final Function(Map<String, dynamic>) onSave;

  const QuestionDialog({super.key, required this.typeColor, required this.onSave});

  @override
  State<QuestionDialog> createState() => _QuestionDialogState();
}

class _QuestionDialogState extends State<QuestionDialog> {
  final _questionController = TextEditingController();
  final _options = List.generate(4, (_) => TextEditingController());
  final _correctAnswerController = TextEditingController();
  int _correctOption = 0;
  String _selectedType = 'mcq';
  String? _errorText;

  @override
  void dispose() {
    _questionController.dispose();
    for(final c in _options){
      c.dispose();
    }
    _correctAnswerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      title: Text(
        'إضافة سؤال',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type selector
            Text(
              'نوع السؤال:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 13.sp,
              ),
            ),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 6.w,
              runSpacing: 6.h,
              children: [
                _buildTypeChip('mcq', 'اختيار من متعدد', Icons.list),
                _buildTypeChip('true_false', 'صح/خطأ', Icons.check_circle_outline),
                _buildTypeChip('short_answer', 'إجابة قصيرة', Icons.short_text),
                _buildTypeChip('essay', 'مقال', Icons.article),
              ],
            ),
            SizedBox(height: 16.h),

            // Question text
            TextField(
              controller: _questionController,
              onChanged: (_) {
                if (_errorText != null) setState(() => _errorText = null);
              },
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'نص السؤال',
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: widget.typeColor),
                ),
              ),
              maxLines: 2,
            ),
            SizedBox(height: 16.h),

            // Type-specific content
            if (_selectedType == 'mcq') _buildMCQOptions(),
            if (_selectedType == 'true_false') _buildTrueFalseOptions(),
            if (_selectedType == 'short_answer') _buildShortAnswerField(),
            if (_selectedType == 'essay') _buildEssayInfo(),

            if (_errorText != null) ...[
              SizedBox(height: 8.h),
              Text(
                _errorText!,
                style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12.sp),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'إلغاء',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _onSave,
          style: ElevatedButton.styleFrom(backgroundColor: widget.typeColor),
          child: Text('إضافة', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildTypeChip(String type, String label, IconData icon) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected
              ? widget.typeColor.withValues(alpha: 0.2)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected
                ? widget.typeColor
                : (Theme.of(context).dividerTheme.color ?? Colors.grey.shade300).withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14.sp,
              color: isSelected
                  ? widget.typeColor
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            SizedBox(width: 4.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                color: isSelected
                    ? widget.typeColor
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMCQOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الخيارات:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 8.h),
        ...List.generate(
          4,
          (i) => Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: GestureDetector(
              onTap: () => setState(() => _correctOption = i),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: _correctOption == i
                        ? widget.typeColor
                        : Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Radio<int>(
                      value: i,
                      groupValue: _correctOption,
                      onChanged: (v) => setState(() => _correctOption = v!),
                      activeColor: widget.typeColor,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _options[i],
                        onChanged: (_) {
                          if (_errorText != null) {
                            setState(() => _errorText = null);
                          }
                        },
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                        decoration: InputDecoration(
                          hintText: 'الخيار ${i + 1}',
                          hintStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 8.h,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrueFalseOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الإجابة الصحيحة:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _correctOption = 0),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  decoration: BoxDecoration(
                    color: _correctOption == 0
                        ? Colors.green.withValues(alpha: 0.15)
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: _correctOption == 0
                          ? Colors.green
                          : Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'صح ✅',
                      style: TextStyle(
                        color: _correctOption == 0
                            ? Colors.green
                            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _correctOption = 1),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  decoration: BoxDecoration(
                    color: _correctOption == 1
                        ? Colors.red.withValues(alpha: 0.15)
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: _correctOption == 1
                          ? Colors.red
                          : Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'خطأ ❌',
                      style: TextStyle(
                        color: _correctOption == 1
                            ? Colors.red
                            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShortAnswerField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الإجابة الصحيحة:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: _correctAnswerController,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: 'اكتب الإجابة الصحيحة للتصحيح التلقائي',
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: widget.typeColor),
            ),
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          'سيتم مقارنة إجابة الطالب بهذه الإجابة (بدون حساسية للأحرف)',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            fontSize: 10.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildEssayInfo() {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue, size: 18.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'سؤال مقالي - يحتاج تصحيح يدوي من المعلم',
              style: TextStyle(color: Colors.blue, fontSize: 12.sp),
            ),
          ),
        ],
      ),
    );
  }

  void _onSave() {
    final question = _questionController.text.trim();
    if (question.isEmpty) {
      setState(() => _errorText = 'اكتب نص السؤال');
      return;
    }

    Map<String, dynamic> data = {'question': question, 'type': _selectedType};
    data['marks'] = 0;
    
    switch (_selectedType) {
      case 'mcq':
        final options = _options.map((c) => c.text.trim()).toList();
        final filledCount = options.where((o) => o.isNotEmpty).length;
        if (filledCount < 2) {
          setState(() => _errorText = 'أدخل خيارين على الأقل');
          return;
        }
        if (options[_correctOption].isEmpty) {
          setState(() => _errorText = 'اختر إجابة صحيحة غير فارغة');
          return;
        }
        data['options'] = options;
        data['correct'] = _correctOption;
        break;
      case 'true_false':
        data['options'] = ['صح', 'خطأ'];
        data['correct'] = _correctOption;
        break;
      case 'short_answer':
        final correctAnswer = _correctAnswerController.text.trim();
        if (correctAnswer.isEmpty) {
          setState(() => _errorText = 'أدخل الإجابة الصحيحة');
          return;
        }
        data['correct_answer'] = correctAnswer;
        data['options'] = <String>[];
        data['correct'] = 0;
        break;
      case 'essay':
        data['options'] = <String>[];
        data['correct'] = -1;
        break;
    }
    
    widget.onSave(data);
    Navigator.pop(context);
  }
}
