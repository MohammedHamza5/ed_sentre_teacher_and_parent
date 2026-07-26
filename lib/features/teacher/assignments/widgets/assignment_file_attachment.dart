import 'package:ed_sentre_techer_and_parent/core/config/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:file_picker/file_picker.dart';

/// Widget for file attachment in assignment creation.
/// Handles file picking and displaying the selected file.
class AssignmentFileAttachment extends StatelessWidget {
  final String type;
  final Color typeColor;
  final String? attachmentName;
  final VoidCallback onPickFile;
  final VoidCallback onRemoveFile;

  const AssignmentFileAttachment({
    super.key,
    required this.type,
    required this.typeColor,
    required this.attachmentName,
    required this.onPickFile,
    required this.onRemoveFile,
  });

  @override
  Widget build(BuildContext context) {
    final isRequired = type == 'exam';

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: attachmentName != null
              ? typeColor
              : (Theme.of(context).dividerTheme.color ?? Colors.grey.shade300).withValues(alpha: 0.5),
          width: attachmentName != null ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attach_file, color: typeColor),
              SizedBox(width: 8.w),
              Text(
                isRequired ? 'ملف الامتحان (PDF) *' : 'مرفق (اختياري)',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (attachmentName != null) ...[
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.picture_as_pdf, color: typeColor),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      attachmentName!,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    onPressed: onRemoveFile,
                  ),
                ],
              ),
            ),
          ] else ...[
            OutlinedButton.icon(
              onPressed: onPickFile,
              icon: Icon(Icons.upload_file, color: typeColor),
              label: Text(
                isRequired ? 'اختر ملف PDF' : 'إضافة مرفق',
                style: TextStyle(color: typeColor),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: typeColor),
                padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Static utility to pick a file using FilePicker.
  /// Returns a record of (name, path) or null.
  static Future<({String name, String? path})?> pickFile(
    BuildContext context,
  ) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'doc', 'docx'],
      );

      if (result != null && result.files.isNotEmpty) {
        return (
          name: result.files.first.name,
          path: result.files.first.path,
        );
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تعذر اختيار الملف')));
      }
    }
    return null;
  }
}
