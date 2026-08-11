import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
// Removed AppColors import
import '../../../../shared/data/supabase_repository.dart';

class UploadMaterialDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onUpload;

  const UploadMaterialDialog({super.key, required this.onUpload});

  @override
  State<UploadMaterialDialog> createState() => _UploadMaterialDialogState();
}

class _UploadMaterialDialogState extends State<UploadMaterialDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _linkController = TextEditingController();

  String _selectedType = 'pdf'; // pdf, video, image, link
  File? _selectedFile;
  bool _isUploading = false;
  String? _uploadError;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      FileType fileType;
      List<String>? allowedExtensions;

      switch (_selectedType) {
        case 'image':
          fileType = FileType.image;
          break;
        case 'video':
          fileType = FileType.video;
          break;
        case 'pdf':
          fileType = FileType.custom;
          allowedExtensions = ['pdf'];
          break;
        default:
          fileType = FileType.any;
      }

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: fileType,
        allowedExtensions: allowedExtensions,
      );

      if (result != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          // Auto-fill title if empty
          if (_titleController.text.isEmpty) {
            _titleController.text = result.files.single.name;
          }
        });
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  Future<void> _handleUpload() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedType != 'link' && _selectedFile == null) {
      setState(() => _uploadError = 'يرجى اختيار ملف');
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadError = null;
    });

    try {
      String? fileUrl;
      final repository = context.read<SupabaseRepository>();

      // 1. Upload File if needed
      if (_selectedType != 'link' && _selectedFile != null) {
        // Create a clean path: teacher_id/timestamp_filename
        // Wait, repository.uploadFile does user path?
        // Looking at the implementation I added: it takes 'path' as arg.
        // Let's assume we pass 'materials' as the folder.
        fileUrl = await repository.uploadStudyMaterialFile(
          _selectedFile!,
          'materials',
        );
      } else {
        fileUrl = _linkController.text;
      }

      // 2. Prepare Data
      final data = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'file_type': _selectedType,
        'file_url': fileUrl,
        'is_public': true, // Default to public for now
        'created_at': DateTime.now().toIso8601String(),
        // teacher_id and center_id will be handled by caller or we pass them here?
        // Better to return the map and let the caller add user/center IDs to keep this widget dumb regarding auth.
      };

      widget.onUpload(data);
    } catch (e) {
      setState(() {
        _uploadError = e.toString();
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: Container(
        padding: EdgeInsets.all(24.w),
        constraints: BoxConstraints(maxWidth: 400.w, maxHeight: 600.h),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'إضافة محتوى جديد',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24.h),

                // Type Selector
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: [
                    _buildTypeChip('pdf', 'ملف PDF', Icons.picture_as_pdf),
                    _buildTypeChip('video', 'فيديو', Icons.video_library),
                    _buildTypeChip('image', 'صورة', Icons.image),
                    _buildTypeChip('link', 'رابط خارجي', Icons.link),
                  ],
                ),
                SizedBox(height: 24.h),

                // File Picker Area
                if (_selectedType != 'link')
                  GestureDetector(
                    onTap: _pickFile,
                    child: Container(
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: _selectedFile != null
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade300,
                          style: BorderStyle.solid,
                          width: _selectedFile != null ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _selectedFile != null
                                ? Icons.check_circle
                                : Icons.cloud_upload_outlined,
                            size: 40.sp,
                            color: _selectedFile != null
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            _selectedFile != null
                                ? _selectedFile!.path.split('/').last
                                : 'اضغط لاختيار ملف',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: _selectedFile != null
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey,
                              fontWeight: _selectedFile != null
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  TextFormField(
                    controller: _linkController,
                    decoration: const InputDecoration(
                      labelText: 'رابط خارجي (Youtube, Website...)',
                      prefixIcon: Icon(Icons.link),
                    ),
                    validator: (val) => val!.isEmpty ? 'مطلوب' : null,
                  ),

                SizedBox(height: 16.h),

                // Title
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'عنوان المحتوى',
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (val) => val!.isEmpty ? 'مطلوب' : null,
                ),
                SizedBox(height: 16.h),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'وصف (اختياري)',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                  maxLines: 2,
                ),

                SizedBox(height: 24.h),

                if (_uploadError != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: 16.h),
                    child: Text(
                      _uploadError!,
                      style: TextStyle(color: Colors.red, fontSize: 12.sp),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Action Button
                ElevatedButton(
                  onPressed: _isUploading ? null : _handleUpload,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: _isUploading
                      ? SizedBox(
                          height: 20.h,
                          width: 20.h,
                          child: const CircularProgressIndicator(
                            backgroundColor: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('رفع وحفظ'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(String id, String label, IconData icon) {
    final isSelected = _selectedType == id;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16.sp,
            color: isSelected
                ? Colors.white
                : Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          SizedBox(width: 4.w),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _selectedType = id);
      },
      backgroundColor: Theme.of(context).colorScheme.surface,
      selectedColor: Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
