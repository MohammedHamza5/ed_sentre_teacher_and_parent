import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// خدمة التصدير الجماعي: كشوفات الحضور والدرجات (للطباعة PDF أو لمراجعة الإكسل CSV)
class BulkExportPdfService {
  
  /// 1. تصدير كشف الحضور والدرجات כملف PDF جداول أنيقة للطباعة والتعليق
  static Future<void> generateGroupListPdf({
    required String teacherName,
    required String subjectName,
    required String groupName,
    required List<Map<String, dynamic>> students, // متوقع: اسم، كود، نسبة حضور، تقييم
  }) async {
    final pdf = pw.Document(title: 'كشف $groupName');

    final fontRegular = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();

    final theme = pw.ThemeData.withFont(
      base: fontRegular,
      bold: fontBold,
    );

    final currentDate = DateFormat('yyyy-MM-dd', 'en_US').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(28),
        header: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('كشف حضور ودرجات الطلاب', style: pw.TextStyle(font: fontBold, fontSize: 18, color: PdfColors.blueGrey900)),
                      pw.Text('المادة: $subjectName | الأستاذ: $teacherName', style: pw.TextStyle(font: fontRegular, fontSize: 11, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.teal50,
                      border: pw.Border.all(color: PdfColors.teal700),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text('المجموعة: $groupName', style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.teal900)),
                        pw.Text(currentDate, style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColors.grey800)),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 16),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('EdSentre Management System', style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.grey500)),
                  pw.Text('صفحة ${context.pageNumber} من ${context.pagesCount}', style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColors.grey700)),
                ],
              ),
            ],
          );
        },
        build: (context) {
          return [
            pw.TableHelper.fromTextArray(
              headers: ['م', 'الكود', 'اسم الطالب', 'الهاتف', 'نسبة الحضور', 'مستوى التقييم'],
              headerStyle: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
              cellStyle: pw.TextStyle(font: fontRegular, fontSize: 10, color: PdfColors.grey900),
              cellAlignment: pw.Alignment.center,
              cellAlignments: {
                2: pw.Alignment.centerRight, // محاذاة لاسم الطالب إلى اليمين
              },
              oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
              data: List.generate(students.length, (index) {
                final student = students[index];
                return [
                  '${index + 1}',
                  student['student_code'] ?? '-',
                  student['student_name'] ?? 'طالب غير معروف',
                  student['student_phone'] ?? student['parent_phone'] ?? 'غير مسجل',
                  '${student['attendance_percentage'] ?? 0}%',
                  student['evaluation'] ?? 'جيد',
                ];
              }),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'كشف_مجموعة_${groupName.replaceAll(' ', '_')}.pdf',
    );
  }

  /// 2. تصدير كشف الحضور والدرجات כملف Excel/CSV ذكي للمشاركة والحفظ
  static Future<void> exportGroupToExcelCSV({
    required String groupName,
    required List<Map<String, dynamic>> students,
  }) async {
    // بناء رأس الإكسل 
    final buffer = StringBuffer();
    // لضمان قراءة الإكسل للحروف العربية، يجب إضافة BOM header الخاص بـ UTF-8
    buffer.write('\uFEFF');
    buffer.writeln('م,الكود,اسم الطالب,رقم الهاتف,هاتف ولي الأمر,نسبة الحضور,متوسط التقييم');

    for (int i = 0; i < students.length; i++) {
      final s = students[i];
      final name = (s['student_name'] ?? '').toString().replaceAll(',', ' ');
      final code = (s['student_code'] ?? '').toString();
      final phone = (s['student_phone'] ?? '').toString();
      final parentPhone = (s['parent_phone'] ?? '').toString();
      final attendance = (s['attendance_percentage'] ?? 0).toString();
      final eval = (s['evaluation'] ?? '').toString();
      
      buffer.writeln('${i + 1},$code,$name,$phone,$parentPhone,$attendance%,$eval');
    }

    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/كشف_$groupName.csv');
      await file.writeAsString(buffer.toString());
      
      // فتح واجهة المشاركة القياسية للجهاز (إرسال واتساب، تليجرام، حفظ في الملفات)
      await Share.shareXFiles([XFile(file.path)], text: 'مرفق كشف أكسل لبيانات المجموعة: $groupName');
    } catch (e) {
      // Ignored in production, or use custom logger
    }
  }
}
