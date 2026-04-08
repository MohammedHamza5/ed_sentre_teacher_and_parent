import 'dart:io';

import 'package:ed_sentre_techer_and_parent/core/config/app_colors.dart';
import 'package:ed_sentre_techer_and_parent/features/ai/screens/exam_preview_screen.dart';
import 'package:ed_sentre_techer_and_parent/features/exam_generator/presentation/providers/ai_exam_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

/// شاشة توليد الامتحانات بالذكاء الاصطناعي
/// المعلم يختار ملف PDF + إعدادات → يتم التوليد → ينتقل لشاشة المعاينة والنشر
class AIGenerateExamScreen extends StatefulWidget {
  final String? knowledgeBaseId;
  final String? knowledgeTitle;
  final String? examType;

  const AIGenerateExamScreen({
    super.key,
    this.knowledgeBaseId,
    this.knowledgeTitle,
    this.examType,
  });

  @override
  State<AIGenerateExamScreen> createState() => _AIGenerateExamScreenState();
}

class _AIGenerateExamScreenState extends State<AIGenerateExamScreen> {
  final _questionCountController = TextEditingController(text: '10');
  late String _selectedDifficulty;
  late String _selectedType;
  File? _selectedFile;

  @override
  void initState() {
    super.initState();
    _selectedDifficulty = 'medium';
    _selectedType = widget.examType ?? 'exam';
  }

  @override
  void dispose() {
    _questionCountController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() => _selectedFile = File(result.files.single.path!));
    }
  }

  void _generate() async {
    final provider = context.read<AiExamProvider>();
    final count = int.tryParse(_questionCountController.text) ?? 10;

    if (widget.knowledgeBaseId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'التوليد من قاعدة المعرفة النصية قيد التطوير حالياً. يرجى استخدام ملف PDF.',
          ),
        ),
      );
      return;
    }

    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار ملف PDF أولاً')),
      );
      return;
    }

    final result = await provider.generateFromPdf(
      pdfFile: _selectedFile!,
      questionCount: count,
      difficulty: _selectedDifficulty,
      examType: _selectedType,
    );

    if (result != null && mounted) {
      // NOTE: بدلاً من إظهار dialog بسيط، ننتقل لشاشة المعاينة الكاملة
      final published = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: provider,
            child: ExamPreviewScreen(examData: result),
          ),
        ),
      );

      if (published == true && mounted) {
        provider.reset();
        Navigator.pop(context, true);
      }
    } else if (mounted && provider.hasError) {
      _showErrorDialog(provider.error ?? 'فشل التوليد لأسباب تقنية');
    }
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'عذراً، حدث خطأ ❌',
          style: TextStyle(color: AppColors.textOnDark),
        ),
        content: Text(
          error,
          style: TextStyle(color: AppColors.textOnDarkSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إغلاق', style: TextStyle(color: AppColors.error)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _generate();
            },
            child: Text(
              'إعادة المحاولة',
              style: TextStyle(color: AppColors.textOnDark),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AiExamProvider>();

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(
          'مولد الامتحانات الذكي',
          style: TextStyle(color: AppColors.textOnDark),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textOnDark),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(20.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(),
                SizedBox(height: 24.h),
                _buildUploadCard(),
                SizedBox(height: 24.h),
                _buildSettingsSection(),
                SizedBox(height: 32.h),
                _buildGenerateButton(),
              ],
            ),
          ),
          if (provider.isLoading)
            Container(
              color: Colors.black87,
              child: _buildLoadingState(provider),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: AppColors.premiumRoyal,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(Icons.auto_awesome, color: Colors.white, size: 28.sp),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إنشاء امتحان بالذكاء الاصطناعي',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'ارفع ملف PDF وسيُنشئ لك أسئلة احترافية',
                  style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(AiExamProvider provider) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutBack,
          builder: (context, val, child) {
            return Transform.scale(
              scale: val,
              child: Opacity(
                opacity: val.clamp(0.0, 1.0),
                child: child,
              ),
            );
          },
          child: Container(
            padding: EdgeInsets.all(32.r),
            decoration: BoxDecoration(
              color: AppColors.darkSurface.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(32.r),
              border: Border.all(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDynamicAiIcon(provider),
                SizedBox(height: 32.h),
                Text(
                  'المساعد الذكي يعمل...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  provider.statusMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF8B5CF6),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 32.h),
                _buildSmartProgressIndicators(provider),
                SizedBox(height: 24.h),
                if (provider.progress > 0)
                  TextButton.icon(
                    onPressed: () => provider.reset(),
                    icon: Icon(Icons.close, color: AppColors.textOnDarkHint, size: 18.sp),
                    label: Text(
                      'إلغاء العملية',
                      style: TextStyle(color: AppColors.textOnDarkHint, fontSize: 14.sp),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicAiIcon(AiExamProvider provider) {
    // Determine icon and animation based on state
    IconData iconData = Icons.auto_awesome;
    Color iconColor = const Color(0xFF8B5CF6);
    bool isSpinning = false;
    bool isPulsing = false;

    if (provider.state == GenState.reading || provider.state == GenState.uploading) {
      iconData = Icons.document_scanner_rounded;
      iconColor = AppColors.info;
      isPulsing = true;
    } else if (provider.state == GenState.generating) {
      iconData = Icons.memory;
      iconColor = AppColors.success;
      isSpinning = true;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: isSpinning ? 2 * 3.14159 : 0),
      duration: isSpinning ? const Duration(seconds: 4) : const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Transform.rotate(
          angle: value,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 1.0, end: isPulsing ? 1.2 : 1.0),
            duration: const Duration(seconds: 1),
            curve: Curves.easeInOut,
            onEnd: () {
              // Not directly loopable with TweenBuilder without state changes, but this provides a simple effect
            },
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: Container(
                  padding: EdgeInsets.all(24.r),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: iconColor.withValues(alpha: 0.1),
                    border: Border.all(color: iconColor.withValues(alpha: 0.3), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: iconColor.withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: Icon(iconData, color: iconColor, size: 48.sp),
                ),
              );
            },
          ),
        );
      },
      onEnd: () {
        if (isSpinning) setState(() {}); // Hack for continuous spinning if needed (better to use AnimationController, but this suffices for quick stateless effect if tied to state updates)
      },
    );
  }

  Widget _buildSmartProgressIndicators(AiExamProvider provider) {
    if (provider.progress == 0) return const SizedBox.shrink();

    return Column(
      children: [
        // Main Progress Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: Stack(
            children: [
              Container(
                height: 12.h,
                width: double.infinity,
                color: Colors.white.withValues(alpha: 0.05),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                height: 12.h,
                width: MediaQuery.of(context).size.width * 0.7 * provider.progress,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFC084FC)],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24.h),
        // AI Thinking Steps (Simulated)
        _buildChecklistItem('قراءة وتحليل المنهج', provider.progress >= 0.2),
        SizedBox(height: 8.h),
        _buildChecklistItem('استخراج المفاهيم المعقدة', provider.progress >= 0.4),
        SizedBox(height: 8.h),
        _buildChecklistItem('هندسة الأسئلة المتدرجة الصعوبة', provider.progress >= 0.6),
        SizedBox(height: 8.h),
        _buildChecklistItem('صياغة خيارات الإجابة والمشتتات (Traps)', provider.progress >= 0.9),
      ],
    );
  }

  Widget _buildChecklistItem(String title, bool isCompleted) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.all(4.r),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted ? AppColors.success.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
            border: Border.all(
              color: isCompleted ? AppColors.success : Colors.white.withValues(alpha: 0.2),
            ),
          ),
          child: Icon(
            isCompleted ? Icons.check : Icons.hourglass_bottom,
            size: 12.sp,
            color: isCompleted ? AppColors.success : Colors.white.withValues(alpha: 0.5),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: isCompleted ? Colors.white : Colors.white.withValues(alpha: 0.4),
              fontSize: 13.sp,
              fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
              decoration: isCompleted ? TextDecoration.none : TextDecoration.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadCard() {
    return GestureDetector(
      onTap: _pickFile,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 40.h),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: _selectedFile != null
                ? const Color(0xFF8B5CF6)
                : AppColors.darkBorder,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              _selectedFile != null
                  ? Icons.picture_as_pdf
                  : Icons.cloud_upload_outlined,
              size: 48.sp,
              color: _selectedFile != null
                  ? const Color(0xFF8B5CF6)
                  : AppColors.textOnDarkHint,
            ),
            SizedBox(height: 12.h),
            Text(
              _selectedFile != null
                  ? _selectedFile!.path.split(Platform.pathSeparator).last
                  : 'اضغط لاختيار ملف PDF المنهج',
              style: TextStyle(
                color: _selectedFile != null
                    ? AppColors.textOnDark
                    : AppColors.textOnDarkHint,
                fontSize: 14.sp,
              ),
            ),
            if (_selectedFile == null)
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Text(
                  '(الحد الأقصى 20 ميجابايت)',
                  style: TextStyle(
                    color: AppColors.textOnDarkHint,
                    fontSize: 11.sp,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'إعدادات الامتحان',
          style: TextStyle(
            color: AppColors.textOnDark,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16.h),

        // Question Count
        _buildTextField(
          label: 'عدد الأسئلة',
          controller: _questionCountController,
          icon: Icons.format_list_numbered,
          keyboardType: TextInputType.number,
        ),

        SizedBox(height: 16.h),

        // Difficulty
        _buildLabel('مستوى الصعوبة'),
        Row(
          children: [
            _buildChoiceChip('easy', 'سهل'),
            SizedBox(width: 8.w),
            _buildChoiceChip('medium', 'متوسط'),
            SizedBox(width: 8.w),
            _buildChoiceChip('hard', 'صعب'),
          ],
        ),

        SizedBox(height: 16.h),

        // Type
        _buildLabel('نوع التوليد'),
        Row(
          children: [
            _buildTypeChip('exam', 'امتحان'),
            SizedBox(width: 8.w),
            _buildTypeChip('quiz', 'كويز'),
          ],
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        text,
        style: TextStyle(color: AppColors.textOnDarkSecondary, fontSize: 13.sp),
      ),
    );
  }

  Widget _buildChoiceChip(String value, String label) {
    final isSelected = _selectedDifficulty == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) => setState(() => _selectedDifficulty = value),
      backgroundColor: AppColors.darkCard,
      selectedColor: const Color(0xFF8B5CF6),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textOnDarkSecondary,
        fontSize: 12.sp,
      ),
    );
  }

  Widget _buildTypeChip(String value, String label) {
    final isSelected = _selectedType == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) => setState(() => _selectedType = value),
      backgroundColor: AppColors.darkCard,
      selectedColor: const Color(0xFF8B5CF6).withValues(alpha: 0.6),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textOnDarkSecondary,
        fontSize: 12.sp,
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: AppColors.textOnDark),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.textOnDarkHint),
        prefixIcon: Icon(icon, color: const Color(0xFF8B5CF6)),
        filled: true,
        fillColor: AppColors.darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      height: 54.h,
      child: ElevatedButton(
        onPressed: _generate,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8B5CF6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome, color: Colors.white),
            SizedBox(width: 10.w),
            Text(
              'ابدأ التوليد السحري',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
