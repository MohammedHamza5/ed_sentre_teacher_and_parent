import 'dart:io';

import 'package:ed_sentre_techer_and_parent/features/exam_generator/presentation/providers/ai_exam_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

// NOTE: I'll need to make sure the import path for the provider is correct relative to the screen.
// Since the screen is in lib/features/ai/screens/ and the provider is in lib/features/exam_generator/presentation/providers/
// The path should be: ../../exam_generator/presentation/providers/ai_exam_provider.dart

// I'll use the user provided code for AIGenerateExamScreen but with corrected imports.

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
      final questions = result['questions'] as List;
      _showSuccessDialog(questions.length);
    } else if (mounted && provider.hasError) {
      _showErrorDialog(provider.error ?? 'فشل التوليد لأسباب تقنية');
    }
  }

  void _showSuccessDialog(int count) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: const Text('تم بنجاح! 🎉', style: TextStyle(color: Colors.white)),
        content: Text('تم توليد $count سؤال بجودة عالية من الملف المرفق.',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً', style: TextStyle(color: Color(0xFF8B5CF6))),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: const Text('عذراً، حدث خطأ ❌', style: TextStyle(color: Colors.white)),
        content: Text(error, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق', style: TextStyle(color: Colors.redAccent)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _generate();
            },
            child: const Text('إعادة المحاولة', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AiExamProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: const Text('مولد الامتحانات الذكي'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(20.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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

  Widget _buildLoadingState(AiExamProvider provider) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24.r),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(24.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    value: provider.progress > 0 ? provider.progress : null,
                    strokeWidth: 6,
                    color: const Color(0xFF8B5CF6),
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    provider.statusMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (provider.progress > 0) ...[
                    SizedBox(height: 12.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10.r),
                      child: LinearProgressIndicator(
                        value: provider.progress,
                        minHeight: 8.h,
                        backgroundColor: Colors.white10,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '${(provider.progress * 100).toInt()}% اكتمل',
                      style: TextStyle(color: Colors.white38, fontSize: 12.sp),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 24.h),
            TextButton(
              onPressed: () => provider.reset(),
              child: const Text('إلغاء العملية', style: TextStyle(color: Colors.white54)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadCard() {
    return GestureDetector(
      onTap: _pickFile,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 40.h),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: _selectedFile != null
                ? const Color(0xFF8B5CF6)
                : Colors.white10,
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
                  : Colors.white30,
            ),
            SizedBox(height: 12.h),
            Text(
              _selectedFile != null
                  ? _selectedFile!.path.split('/').last
                  : 'اصغط لاختيار ملف PDF المنهج',
              style: TextStyle(
                color: _selectedFile != null ? Colors.white : Colors.white30,
                fontSize: 14.sp,
              ),
            ),
            if (_selectedFile == null)
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Text(
                  '(الحد الأقصى 20 ميجابايت)',
                  style: TextStyle(color: Colors.white24, fontSize: 11.sp),
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
            color: Colors.white,
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
        style: TextStyle(color: Colors.white70, fontSize: 13.sp),
      ),
    );
  }

  Widget _buildChoiceChip(String value, String label) {
    final isSelected = _selectedDifficulty == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) => setState(() => _selectedDifficulty = value),
      backgroundColor: Colors.white.withOpacity(0.05),
      selectedColor: const Color(0xFF8B5CF6),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.white60,
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
      backgroundColor: Colors.white.withOpacity(0.05),
      selectedColor: const Color(0xFF8B5CF6).withOpacity(0.6),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.white60,
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
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: const Color(0xFF8B5CF6)),
        filled: true,
        fillColor: const Color(0xFF161B22),
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
