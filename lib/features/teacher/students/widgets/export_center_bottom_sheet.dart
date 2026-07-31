import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/config/app_colors.dart';
import '../../reports/services/bulk_export_pdf_service.dart';
import '../../reports/services/student_id_cards_pdf_service.dart';

class ExportCenterBottomSheet extends StatefulWidget {
  final List<Map<String, dynamic>> students;
  final String groupName;
  final String teacherName;
  final String subjectName;

  const ExportCenterBottomSheet({
    super.key,
    required this.students,
    required this.groupName,
    required this.teacherName,
    required this.subjectName,
  });

  @override
  State<ExportCenterBottomSheet> createState() => _ExportCenterBottomSheetState();
}

class _ExportCenterBottomSheetState extends State<ExportCenterBottomSheet> {
  bool _isExporting = false;

  Future<void> _handleExportAction(Future<void> Function() action) async {
    setState(() => _isExporting = true);
    try {
      await action();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ تم التصدير بنجاح!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ حدث خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
      decoration: BoxDecoration(
        color: AppColors.navyCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.import_export_rounded, color: AppColors.primary, size: 28.sp),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مركز التصدير والطباعة',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'يتم التصدير لعدد ${widget.students.length} طالب',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 32.h),

          if (_isExporting)
            Center(
              child: Column(
                children: [
                  const CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16.h),
                  const Text('جاري معالجة وتصدير الملفات...', style: TextStyle(color: Colors.white70)),
                  SizedBox(height: 32.h),
                ],
              ),
            )
          else ...[
            // PDF Option
            _buildExportOption(
              title: 'كشف الغياب والدرجات (PDF)',
              subtitle: 'ملف جاهز للطباعة والتعليق في القاعة',
              icon: Icons.picture_as_pdf_rounded,
              color: Colors.redAccent,
              onTap: () => _handleExportAction(() => BulkExportPdfService.generateGroupListPdf(
                teacherName: widget.teacherName,
                subjectName: widget.subjectName,
                groupName: widget.groupName,
                students: widget.students,
              )),
            ),
            
            SizedBox(height: 16.h),
            
            // Excel Option
            _buildExportOption(
              title: 'جدول البيانات الذكي (Excel / CSV)',
              subtitle: 'ملف للمشاركة على واتساب والمراجعة بالكمبيوتر',
              icon: Icons.table_chart_rounded,
              color: Colors.greenAccent,
              onTap: () => _handleExportAction(() => BulkExportPdfService.exportGroupToExcelCSV(
                groupName: widget.groupName,
                students: widget.students,
              )),
            ),

            SizedBox(height: 16.h),

            // Barcode ID Cards Option
            _buildExportOption(
              title: 'كارنيهات وبطاقات الطلاب (باركود)',
              subtitle: 'ورقة A4 تحتوي على كارنيهات الطلاب لمسح الحضور',
              icon: Icons.badge_rounded,
              color: Colors.orangeAccent,
              onTap: () => _handleExportAction(() => StudentIdCardsPdfService.generateIdCardsPdf(
                teacherName: widget.teacherName,
                subjectName: widget.subjectName,
                groupName: widget.groupName,
                students: widget.students,
              )),
            ),
            
            SizedBox(height: 16.h),
          ],
        ],
      ),
    );
  }

  Widget _buildExportOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: color, size: 26.sp),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 16.sp),
          ],
        ),
      ),
    );
  }
}
