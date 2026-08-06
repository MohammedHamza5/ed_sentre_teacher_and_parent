import 'dart:io';
import 'package:ed_sentre_techer_and_parent/core/providers/center_provider.dart';
import 'package:ed_sentre_techer_and_parent/features/ai/provider/ai_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/config/app_colors.dart';

/// Sheet for adding new knowledge content (textbook, notes, exercises).
class AddKnowledgeSheet extends StatefulWidget {
  const AddKnowledgeSheet({super.key});

  @override
  State<AddKnowledgeSheet> createState() => _AddKnowledgeSheetState();
}

class _AddKnowledgeSheetState extends State<AddKnowledgeSheet> {
  final _titleController = TextEditingController();
  final _subjectController = TextEditingController();
  final _gradeController = TextEditingController();

  String _contentType = 'textbook';
  bool _isLoading = false;
  File? _selectedFile;

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    _gradeController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
      hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: (Theme.of(context).dividerTheme.color ?? Colors.grey.shade300)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: (Theme.of(context).dividerTheme.color ?? Colors.grey.shade300)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: (Theme.of(context).dividerTheme.color ?? Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'إضافة محتوى جديد',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 20.h),

            // Content type
            Text(
              'نوع المحتوى',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 8.w,
              children: [
                _buildTypeChip('textbook', 'كتاب', Icons.menu_book),
                _buildTypeChip('notes', 'ملازم', Icons.note),
                _buildTypeChip('exercises', 'تمارين', Icons.assignment),
              ],
            ),
            SizedBox(height: 16.h),

            // Title
            TextField(
              controller: _titleController,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: _inputDecoration(
                'عنوان المحتوى',
                hint: 'مثال: كتاب الرياضيات — الباب الأول',
              ),
            ),
            SizedBox(height: 12.h),

            // Subject and Grade
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _subjectController,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    decoration: _inputDecoration('المادة'),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: TextField(
                    controller: _gradeController,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    decoration: _inputDecoration('الصف'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // PDF Upload
            Text(
              'ملف المحتوى (PDF)',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 8.h),
            GestureDetector(
              onTap: _pickPdf,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: _selectedFile == null ? (Theme.of(context).dividerTheme.color ?? Colors.grey.shade300) : const Color(0xFF8B5CF6),
                    width: _selectedFile == null ? 1 : 2,
                  ),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        _selectedFile == null ? Icons.upload_file : Icons.picture_as_pdf,
                        color: _selectedFile == null ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7) : const Color(0xFF8B5CF6),
                        size: 32.sp,
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        _selectedFile == null
                            ? 'اضغط لاختيار ملف PDF'
                            : _selectedFile!.path.split(Platform.pathSeparator).last,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _selectedFile == null ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7) : Theme.of(context).colorScheme.onSurface,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 20.h),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      side: BorderSide(color: (Theme.of(context).dividerTheme.color ?? Colors.grey.shade300)),
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text('إلغاء'),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF6C3CE1)],
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 20.w,
                              height: 20.w,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                backgroundColor: Colors.white,
                              ),
                            )
                          : Text('حفظ'),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(String value, String label, IconData icon) {
    final isSelected = _contentType == value;
    return GestureDetector(
      onTap: () => setState(() => _contentType = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF6C3CE1)],
                )
              : null,
          color: isSelected ? null : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? Colors.transparent : (Theme.of(context).dividerTheme.color ?? Colors.grey.shade300),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16.sp,
              color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_titleController.text.isEmpty || _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('أدخل العنوان واختر ملف PDF'),
          backgroundColor: AppColors.darkElevated,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final aiProvider = context.read<AIProvider>();
      final centerProvider = context.read<CenterProvider>();

      // Upload file to Supabase storage
      final fileUrl = await aiProvider.uploadDocumentToStorage(_selectedFile!);
      if (fileUrl == null) {
        throw Exception('فشل في رفع الملف');
      }

      await aiProvider.addToKnowledgeBase(
        centerId: centerProvider.currentCenterId!,
        title: _titleController.text,
        contentType: _contentType,
        extractedText: '', // No longer extracting text
        subjectName: _subjectController.text,
        gradeLevel: _gradeController.text,
        fileUrl: fileUrl,
        fileName: _selectedFile!.path.split(Platform.pathSeparator).last,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إضافة المحتوى بنجاح ✅'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          // If title is empty, use the file name
          if (_titleController.text.isEmpty) {
            _titleController.text = result.files.single.name.replaceAll('.pdf', '');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في اختيار الملف: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

