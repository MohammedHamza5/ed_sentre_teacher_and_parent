import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/config/app_colors.dart';
import '../../ai/provider/ai_provider.dart';
import '../../../core/providers/center_provider.dart';
import '../../teacher/assignments/create_assignment_screen.dart';

/// شاشة إنشاء امتحان بـ AI
class AIGenerateExamScreen extends StatefulWidget {
  final String? knowledgeBaseId;
  final String? knowledgeTitle;
  final String examType;

  const AIGenerateExamScreen({
    super.key,
    this.knowledgeBaseId,
    this.knowledgeTitle,
    this.examType = 'exam',
  });

  @override
  State<AIGenerateExamScreen> createState() => _AIGenerateExamScreenState();
}

class _AIGenerateExamScreenState extends State<AIGenerateExamScreen> {
  String _difficulty = 'medium';
  int _questionCount = 10;
  String _examType = 'exam';

  File? _selectedFile;
  bool _isUploading = false;

  Map<String, dynamic>? _generatedExam;
  bool _isGenerated = false;

  @override
  void initState() {
    super.initState();
    _examType = widget.examType;
    _questionCount = widget.examType == 'quiz' ? 5 : 10;
  }

  @override
  Widget build(BuildContext context) {
    final aiProvider = context.watch<AIProvider>();

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(
          _isGenerated ? 'معاينة الامتحان' : 'إنشاء امتحان بـ AI',
          style: TextStyle(color: AppColors.textOnDark),
        ),
        backgroundColor: AppColors.darkCard,
        foregroundColor: AppColors.textOnDark,
        elevation: 0,
        actions: [
          if (_isGenerated)
            TextButton.icon(
              onPressed: _publishExam,
              icon: const Icon(Icons.publish, color: Colors.white),
              label: const Text('نشر', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _isGenerated ? _buildPreview() : _buildSettings(aiProvider),
    );
  }

  Widget _buildSettings(AIProvider aiProvider) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // بطاقة المحتوى المحدد
          _buildSelectedContent(),
          SizedBox(height: 24.h),

          // نوع الاختبار
          _buildSectionTitle('📝 نوع الاختبار'),
          SizedBox(height: 12.h),
          _buildExamTypeSelector(),
          SizedBox(height: 24.h),

          // درجة الصعوبة
          _buildSectionTitle('📊 درجة الصعوبة'),
          SizedBox(height: 12.h),
          _buildDifficultySelector(),
          SizedBox(height: 24.h),

          // عدد الأسئلة
          _buildSectionTitle('🔢 عدد الأسئلة'),
          SizedBox(height: 12.h),
          _buildQuestionCountSlider(),
          SizedBox(height: 32.h),

          // معلومات التكلفة
          _buildCostInfo(aiProvider),
          SizedBox(height: 24.h),

          // زر الإنشاء
          Container(
            width: double.infinity,
            height: 50.h,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: (aiProvider.isGenerating || _isUploading)
                  ? null
                  : _generate,
              icon: (aiProvider.isGenerating || _isUploading)
                  ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(
                _isUploading
                    ? 'جاري رفع الملف...'
                    : (aiProvider.isGenerating
                          ? 'جاري الإنشاء...'
                          : 'إنشاء الامتحان 🪄'),
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),

          // رسالة خطأ
          if (aiProvider.generationError != null) ...[
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: AppColors.error, size: 20.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      aiProvider.generationError!,
                      style: TextStyle(fontSize: 13.sp, color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectedContent() {
    final hasKnowledge =
        widget.knowledgeBaseId != null && widget.knowledgeTitle != null;
    final hasFile = _selectedFile != null;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.menu_book,
                  color: AppColors.primary,
                  size: 28.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasKnowledge
                          ? 'المحتوى المحدد من القاعدة'
                          : (hasFile ? 'ملف PDF المرفق' : 'لم يتم تحديد محتوى'),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textOnDarkSecondary,
                      ),
                    ),
                    Text(
                      hasKnowledge
                          ? widget.knowledgeTitle!
                          : (hasFile
                                ? _selectedFile!.uri.pathSegments.last
                                : 'ارفق ملف PDF لإنشاء امتحان'),
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textOnDark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (hasKnowledge || hasFile)
                Icon(Icons.check_circle, color: AppColors.success, size: 24.sp),
            ],
          ),
          if (!hasKnowledge) ...[
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _pickPdfFile,
                icon: Icon(
                  hasFile ? Icons.edit : Icons.upload_file,
                  color: AppColors.primary,
                ),
                label: Text(
                  hasFile ? 'تغيير الملف' : 'إرفاق ملف PDF',
                  style: TextStyle(color: AppColors.primary),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickPdfFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.bold,
        color: AppColors.textOnDark,
      ),
    );
  }

  Widget _buildExamTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildTypeOption('exam', 'امتحان', Icons.quiz, Colors.orange),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildTypeOption(
            'assignment',
            'واجب',
            Icons.assignment,
            const Color(0xFF3B82F6),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildTypeOption(
            'quiz',
            'كويز',
            Icons.bolt,
            const Color(0xFF8B5CF6),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeOption(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = _examType == value;
    return InkWell(
      onTap: () {
        setState(() {
          _examType = value;
          if (value == 'quiz') _questionCount = 5;
        });
      },
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : AppColors.darkCard,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? color : AppColors.darkBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : AppColors.textOnDarkSecondary,
              size: 28.sp,
            ),
            SizedBox(height: 8.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : AppColors.textOnDarkSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultySelector() {
    return Row(
      children: [
        Expanded(child: _buildDifficultyOption('easy', 'سهل', Colors.green)),
        SizedBox(width: 8.w),
        Expanded(
          child: _buildDifficultyOption('medium', 'متوسط', Colors.orange),
        ),
        SizedBox(width: 8.w),
        Expanded(child: _buildDifficultyOption('hard', 'صعب', Colors.red)),
        SizedBox(width: 8.w),
        Expanded(
          child: _buildDifficultyOption(
            'mixed',
            'متنوع',
            const Color(0xFF8B5CF6),
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultyOption(String value, String label, Color color) {
    final isSelected = _difficulty == value;
    return InkWell(
      onTap: () => setState(() => _difficulty = value),
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : AppColors.darkCard,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? color : AppColors.darkBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? color : AppColors.textOnDarkSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCountSlider() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$_questionCount سؤال',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textOnDark,
              ),
            ),
            Text(
              _getEstimatedTime(),
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.textOnDarkSecondary,
              ),
            ),
          ],
        ),
        Slider(
          value: _questionCount.toDouble(),
          min: 5,
          max: 30,
          divisions: 25,
          activeColor: AppColors.primary,
          inactiveColor: AppColors.darkBorder,
          label: '$_questionCount',
          onChanged: (v) => setState(() => _questionCount = v.round()),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '5',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textOnDarkSecondary,
              ),
            ),
            Text(
              '30',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textOnDarkSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getEstimatedTime() {
    final minutes = _questionCount * 2;
    return 'الوقت المقدر: $minutes دقيقة';
  }

  Widget _buildCostInfo(AIProvider aiProvider) {
    final cost = _examType == 'quiz' ? 5 : (_examType == 'exam' ? 15 : 10);
    final hasEnough = aiProvider.totalCredits >= cost;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: hasEnough
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: hasEnough
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasEnough ? Icons.check_circle : Icons.warning,
            color: hasEnough ? AppColors.success : AppColors.error,
            size: 24.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasEnough ? 'رصيدك كافٍ' : 'رصيد غير كافٍ',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: hasEnough ? AppColors.success : AppColors.error,
                  ),
                ),
                Text(
                  'التكلفة: $cost رصيد • رصيدك: ${aiProvider.totalCredits}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: hasEnough
                        ? AppColors.success.withValues(alpha: 0.8)
                        : AppColors.error.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // معاينة الامتحان المُنشأ
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildPreview() {
    if (_generatedExam == null) return const SizedBox();

    final questions = _generatedExam!['questions'] as List? ?? [];
    final title = _generatedExam!['title'] as String? ?? 'امتحان';
    final totalMarks = _generatedExam!['total_marks'] ?? 0;
    final estimatedTime = _generatedExam!['estimated_time_minutes'] ?? 30;

    return Column(
      children: [
        // Header
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            border: Border(
              bottom: BorderSide(
                color: AppColors.success.withValues(alpha: 0.3),
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success, size: 24.sp),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تم إنشاء الامتحان بنجاح! ✨',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                    Text(
                      '${questions.length} سؤال • $totalMarks درجة • $estimatedTime دقيقة',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.success.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Questions List
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: questions.length,
            itemBuilder: (context, index) {
              final q = questions[index] as Map<String, dynamic>;
              return _buildQuestionPreview(index + 1, q);
            },
          ),
        ),

        // Bottom Actions
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            border: Border(top: BorderSide(color: AppColors.darkBorder)),
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _regenerate,
                    icon: Icon(Icons.refresh, color: AppColors.textOnDark),
                    label: Text(
                      'إعادة إنشاء',
                      style: TextStyle(color: AppColors.textOnDark),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.darkBorder),
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _publishExam,
                      icon: const Icon(Icons.publish),
                      label: const Text('نشر للطلاب'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionPreview(int num, Map<String, dynamic> question) {
    final type = question['type'] as String? ?? 'multiple_choice';
    final text = question['question'] as String? ?? '';

    // Safely parse options since AI might return String instead of List
    final optionsRaw = question['options'];
    List<dynamic> options = [];
    if (optionsRaw is List) {
      options = optionsRaw;
    } else if (optionsRaw is String && optionsRaw.isNotEmpty) {
      options = [optionsRaw];
    }
    final correct = question['correct_answer'] as int? ?? 0;
    final difficulty = question['difficulty'] as String? ?? 'medium';
    final marks = question['marks'] ?? 2;

    Color diffColor;
    switch (difficulty) {
      case 'easy':
        diffColor = Colors.green;
        break;
      case 'hard':
        diffColor = Colors.red;
        break;
      default:
        diffColor = Colors.orange;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$num',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: diffColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  difficulty == 'easy'
                      ? 'سهل'
                      : (difficulty == 'hard' ? 'صعب' : 'متوسط'),
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: diffColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '$marks درجات',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textOnDarkSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Question
          Text(
            text,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textOnDark,
            ),
          ),
          SizedBox(height: 12.h),

          // Options
          if (type == 'multiple_choice' && options.isNotEmpty)
            ...List.generate(options.length, (i) {
              final isCorrect = i == correct;
              return Container(
                margin: EdgeInsets.only(bottom: 8.h),
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: isCorrect
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: isCorrect ? AppColors.success : AppColors.darkBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCorrect
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: isCorrect
                          ? AppColors.success
                          : AppColors.textOnDarkSecondary,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        options[i].toString(),
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: isCorrect
                              ? AppColors.success
                              : AppColors.textOnDark,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

          // True/False
          if (type == 'true_false')
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: correct == 0
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.darkSurface,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: correct == 0
                            ? AppColors.success
                            : AppColors.darkBorder,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'صح',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: correct == 0
                              ? AppColors.success
                              : AppColors.textOnDark,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: correct == 1
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.darkSurface,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: correct == 1
                            ? AppColors.success
                            : AppColors.darkBorder,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'خطأ',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: correct == 1
                              ? AppColors.success
                              : AppColors.textOnDark,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Actions
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> _generate() async {
    if (widget.knowledgeBaseId == null && _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'الرجاء اختيار محتوى من قاعدة المعرفة أو إرفاق ملف PDF',
          ),
        ),
      );
      return;
    }

    final aiProvider = context.read<AIProvider>();
    String? filePath;

    // Upload file if selected
    if (_selectedFile != null && widget.knowledgeBaseId == null) {
      setState(() => _isUploading = true);

      filePath = await aiProvider.uploadDocumentToStorage(_selectedFile!);

      setState(() => _isUploading = false);

      if (filePath == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('فشل رفع الملف. الرجاء المحاولة مرة أخرى.'),
            ),
          );
        }
        return;
      }
    }

    final result = await aiProvider.generateExam(
      knowledgeBaseId: widget.knowledgeBaseId,
      difficulty: _difficulty,
      questionCount: _questionCount,
      examType: _examType,
      filePath: filePath,
    );

    if (result != null && mounted) {
      setState(() {
        _generatedExam = result;
        _isGenerated = true;
      });
    }
  }

  void _regenerate() {
    setState(() {
      _isGenerated = false;
      _generatedExam = null;
    });
  }

  Future<void> _publishExam() async {
    if (_generatedExam == null) return;

    final aiProvider = context.read<AIProvider>();
    final centerProvider = context.read<CenterProvider>();

    // 1. Save to Bank (Optional but good for history)
    await aiProvider.saveGeneratedExam(
      centerId: centerProvider.currentCenterId!,
      knowledgeBaseId: widget.knowledgeBaseId,
      title: _generatedExam!['title'] ?? 'امتحان',
      examType: _examType,
      difficulty: _difficulty,
      examData: _generatedExam!,
    );

    // 2. Navigate to CreateAssignmentScreen for Publishing
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateAssignmentScreen(
            type: 'quiz', // Always quiz for interactive questions
            initialTitle: _generatedExam!['title'] ?? 'امتحان',
            initialQuestions: (_generatedExam!['questions'] as List)
                .map((e) => Map<String, dynamic>.from(e))
                .toList(),
            initialDuration: _generatedExam!['estimated_time_minutes'],
            initialMaxScore: _generatedExam!['total_marks'],
          ),
        ),
      );
    }
  }
}
