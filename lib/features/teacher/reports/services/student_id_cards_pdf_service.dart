import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// خدمة تصميم وتوليد كارنيهات الطلاب المجمعة للطباعة (تحتوي على باركود لتسجيل الحضور)
class StudentIdCardsPdfService {
  
  /// توليد شبكة من كارنيهات الباركود לلطلاب للطباعة في ورقة A4
  static Future<void> generateIdCardsPdf({
    required String teacherName,
    required String subjectName,
    required String groupName,
    required List<Map<String, dynamic>> students, 
  }) async {
    final pdf = pw.Document(title: 'كارنيهات مجموعة $groupName');

    final fontRegular = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();

    final theme = pw.ThemeData.withFont(
      base: fontRegular,
      bold: fontBold,
    );

    // حساب كم صفحة نحتاج (كل صفحة فيها شبكة 3x3 أو 2x4 بطاقات مثلاً)
    // هنا سنرصهم بشكل مرن باستخدام Wrap أو GridView
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(20),
        header: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Text('بطاقات عبور الطلاب (كارنيهات الباركود) - مجموعة: $groupName', 
                style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.blueGrey900)),
              pw.SizedBox(height: 16),
            ],
          );
        },
        build: (context) {
          return [
            pw.Wrap(
              spacing: 20,
              runSpacing: 20,
              alignment: pw.WrapAlignment.center,
              children: students.map((student) {
                return _buildSingleIdCard(
                  studentName: student['student_name'] ?? 'طالب غير مسجل',
                  studentCode: (student['student_code'] ?? '0000').toString(),
                  groupName: groupName,
                  teacherName: teacherName,
                  subjectName: subjectName,
                  fontBold: fontBold,
                  fontRegular: fontRegular,
                );
              }).toList(),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'كارنيهات_${groupName.replaceAll(' ', '_')}.pdf',
    );
  }

  /// تصميم بطاقة كارنيه واحدة
  static pw.Widget _buildSingleIdCard({
    required String studentName,
    required String studentCode,
    required String groupName,
    required String teacherName,
    required String subjectName,
    required pw.Font fontBold,
    required pw.Font fontRegular,
  }) {
    // مقاس كارت تقريبي: العرض 200 والارتفاع 130
    return pw.Container(
      width: 220,
      height: 140,
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: PdfColors.blueGrey300, width: 2),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
      ),
      child: pw.Column(
        children: [
          // رأس البطاقة - المعلم والمادة
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue900,
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(10),
                topRight: pw.Radius.circular(10),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('EdSentre Card', style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.amber400)),
                pw.Text('$subjectName | $teacherName', style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.white)),
              ],
            ),
          ),
          
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Column(
              children: [
                pw.SizedBox(height: 4),
                // اسم الطالب والمجموعة
                pw.Text(
                  studentName,
                  style: pw.TextStyle(font: fontBold, fontSize: 14, color: PdfColors.blueGrey900),
                  maxLines: 1,
                  overflow: pw.TextOverflow.clip,
                ),
                pw.Text(
                  groupName,
                  style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColors.grey700),
                ),
                
                pw.SizedBox(height: 12),
                
                // الباركود الخاص بالكود (Code128 مناسب للأكواد الرقمية/النصية ويعطي شكل احترافي)
                pw.Container(
                  width: 140,
                  height: 35,
                  child: pw.BarcodeWidget(
                    data: studentCode,
                    barcode: pw.Barcode.code128(),
                    color: PdfColors.black,
                    drawText: false, // لا نريد رسم النص المدمج مع الباركود لنجعله أوضح
                  ),
                ),
                pw.SizedBox(height: 4),
                // الكود تحت الباركود بخط عريض
                pw.Text(
                  studentCode,
                  style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.blue900, letterSpacing: 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
