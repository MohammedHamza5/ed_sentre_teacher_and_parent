import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/app_colors.dart';
import '../../../../features/auth/provider/auth_provider.dart';
import '../services/student_report_pdf_service.dart';

class StudentReportBottomSheet extends StatefulWidget {
  final Map<String, dynamic> student;

  const StudentReportBottomSheet({super.key, required this.student});

  @override
  State<StudentReportBottomSheet> createState() => _StudentReportBottomSheetState();
}

class _StudentReportBottomSheetState extends State<StudentReportBottomSheet> {
  final _notesController = TextEditingController();
  String _selectedRating = '⭐⭐⭐⭐⭐ مميز جداً';
  final List<String> _ratings = [
    '⭐⭐⭐⭐⭐ مميز جداً',
    '👍 ملتزم وجيد جداً',
    '📘 بحاجة لزيادة التركيز',
    '⚠️ يحتاج متابعة فورية من ولي الأمر',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _getTeacherName(AuthProvider auth) {
    return auth.teacherProfile?.fullName ?? auth.currentUser?.fullName ?? 'المعلم الأستاذ';
  }

  String _getSubjectName(AuthProvider auth) {
    final specs = auth.teacherProfile?.specializations;
    if (specs != null && specs.isNotEmpty) {
      return specs.first;
    }
    return 'المادة الدراسية';
  }

  Future<void> _generatePdf() async {
    final auth = context.read<AuthProvider>();
    final teacherName = _getTeacherName(auth);
    final subjectName = _getSubjectName(auth);
    final studentName = widget.student['student_name']?.toString() ?? 'طالب';
    final studentCode = widget.student['student_code']?.toString() ?? '1000';
    final groupName = widget.student['group_name']?.toString() ?? 'مجموعة أساسية';

    await StudentReportPdfService.generateStudentReport(
      studentName: studentName,
      studentCode: studentCode,
      groupName: groupName,
      teacherName: teacherName,
      subjectName: subjectName,
      teacherNotes: _notesController.text.trim(),
      evaluationRating: _selectedRating,
      attendancePercentage: 94, // يمكن ربطه لاحقاً بديناميكية سجل الحضور الفعلي
      examsAverage: 88,
      homeworkCompletion: 90,
      recentScores: [
        {'title': 'اختبار الفصل الأول', 'score': 18, 'total': 20, 'grade': 'ممتاز'},
        {'title': 'تقييم الحصة السريع', 'score': 9, 'total': 10, 'grade': 'ممتاز'},
      ],
    );
  }

  Future<void> _sendViaWhatsApp() async {
    final auth = context.read<AuthProvider>();
    final teacherName = _getTeacherName(auth);
    final subjectName = _getSubjectName(auth);
    final studentName = widget.student['student_name']?.toString() ?? 'طالب';

    // البحث عن هاتف ولي الأمر أو الهاتف المسجل للطالب
    var phone = widget.student['parent_phone']?.toString() ?? widget.student['student_phone']?.toString() ?? '';
    phone = phone.replaceAll('+', '').replaceAll(' ', '').replaceAll('-', '');
    if (phone.startsWith('01')) {
      phone = '2$phone'; // ضبط الكود المصري تلقائياً لو بدأ بـ 01
    }

    final notesText = _notesController.text.trim().isEmpty
        ? 'أداؤه في الحصص مستقر وندعوكم للمزيد من المتابعة المنزلية الهادفة لتحقيق التفوق الختامي.'
        : _notesController.text.trim();

    final message = '''
السلام عليكم ورحمة الله،
إليكم تقرير المستوى لمتابعة أداء الطالب/ة *($studentName)* بمادة ($subjectName) من الأستاذ: $teacherName.

📊 *التقييم التراكمي*: $_selectedRating
📝 *ملاحظات المعلم*:
$notesText

💡 تم إصدار مستند التقرير الفني المفصل كملف PDF على نظام EdSentre للمزيد من الاطلاع. مع تمنياتنا بالتفوق والنجاح الدائم!
''';

    final uri = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر فتح تطبيق الواتساب، تأكد من وجود رقم صالح: $phone'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentName = widget.student['student_name']?.toString() ?? 'طالب';
    final groupName = widget.student['group_name']?.toString() ?? 'المجموعة';

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20.w,
          right: 20.w,
          top: 20.h,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Header ──────────────────────────────────────────────────────
              Center(
                child: Container(
                  width: 45.w,
                  height: 5.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  CircleAvatar(
                    radius: 22.r,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                    child: Icon(Icons.analytics_rounded, color: AppColors.primary),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تقرير المستوى والتقييم الشهري',
                          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: AppColors.textOnDark),
                        ),
                        Text(
                          '$studentName ($groupName)',
                          style: TextStyle(fontSize: 12.sp, color: AppColors.textOnDarkHint),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),

              // ─── Rating Selection ──────────────────────────────────────────
              Text(
                'اختر مستوى التقييم العام لهذا الشهر:',
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: AppColors.textOnDark),
              ),
              SizedBox(height: 10.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: _ratings.map((rating) {
                  final isSelected = _selectedRating == rating;
                  return ChoiceChip(
                    label: Text(rating),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surface.withValues(alpha: 0.5),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textOnDarkHint,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12.sp,
                    ),
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedRating = rating);
                    },
                  );
                }).toList(),
              ),
              SizedBox(height: 20.h),

              // ─── Notes Field ───────────────────────────────────────────────
              Text(
                'ملاحظات المعلم وتوجيهاته لولي الأمر (اختياري):',
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: AppColors.textOnDark),
              ),
              SizedBox(height: 8.h),
              TextField(
                controller: _notesController,
                maxLines: 3,
                style: TextStyle(color: AppColors.textOnDark, fontSize: 13.sp),
                decoration: InputDecoration(
                  hintText: 'اكتب هنا أي توجيه لولي الأمر بخصوص مستواه أو أخباره...',
                  hintStyle: TextStyle(color: AppColors.textOnDarkHint, fontSize: 12.sp),
                  filled: true,
                  fillColor: AppColors.surface.withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
              SizedBox(height: 24.h),

              // ─── Actions ───────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _generatePdf();
                      },
                      icon: Icon(Icons.picture_as_pdf_rounded, size: 18.sp, color: Colors.white),
                      label: Text('تصدير PDF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _sendViaWhatsApp();
                      },
                      icon: Icon(Icons.send_rounded, size: 18.sp, color: Colors.white),
                      label: Text('إرسال واتساب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366), // اللون الرسمي لواتساب
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
