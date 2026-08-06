import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

/// خدمة إنشاء وتصدير التقرير الشهري لمتابعة أداء الطالب (للطباعة والمشاركة مع أولياء الأمور)
class StudentReportPdfService {
  static Future<Uint8List> generatePdfBytes({
    required String studentName,
    required String studentCode,
    required String groupName,
    required String teacherName,
    required String subjectName,
    required String teacherNotes,
    required String evaluationRating,
    required int attendancePercentage,
    required int examsAverage,
    required int homeworkCompletion,
    List<Map<String, dynamic>>? recentScores,
  }) async {
    final pdf = pw.Document(title: 'تقرير متابعة $studentName');

    final fontRegular = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();

    final theme = pw.ThemeData.withFont(
      base: fontRegular,
      bold: fontBold,
    );

    final currentDate = DateFormat('yyyy-MM-dd', 'en_US').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // ─── الترويسة الرئيسية ──────────────────────────────────────────
              _buildHeader(
                teacherName: teacherName,
                subjectName: subjectName,
                currentDate: currentDate,
                fontBold: fontBold,
                fontRegular: fontRegular,
              ),
              pw.SizedBox(height: 16),

              // ─── بطاقة الطالب والتقييم العام ──────────────────────────────
              _buildStudentCard(
                studentName: studentName,
                studentCode: studentCode,
                groupName: groupName,
                evaluationRating: evaluationRating,
                fontBold: fontBold,
                fontRegular: fontRegular,
              ),
              pw.SizedBox(height: 20),

              // ─── مؤشرات الأداء الثلاثية ─────────────────────────────────────
              pw.Text('مؤشرات الأداء خلال الشهر:', style: pw.TextStyle(font: fontBold, fontSize: 14, color: PdfColors.blueGrey900)),
              pw.SizedBox(height: 10),
              _buildMetricsRow(
                attendance: attendancePercentage,
                exams: examsAverage,
                homework: homeworkCompletion,
                fontBold: fontBold,
                fontRegular: fontRegular,
              ),
              pw.SizedBox(height: 20),

              // ─── جدول أحدث الاختبارات والأنشطة ──────────────────────────────
              if (recentScores != null && recentScores.isNotEmpty) ...[
                pw.Text('سجل الاختبارات الأخيرة:', style: pw.TextStyle(font: fontBold, fontSize: 14, color: PdfColors.blueGrey900)),
                pw.SizedBox(height: 8),
                _buildScoresTable(recentScores, fontBold, fontRegular),
                pw.SizedBox(height: 20),
              ],

              // ─── ملاحظات المعلم وتوجيهاته ─────────────────────────────────
              _buildNotesBox(teacherNotes, fontBold, fontRegular),
              pw.Spacer(),

              // ─── التوقيع والتذييل ─────────────────────────────────────────
              _buildFooter(teacherName, fontBold, fontRegular),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> generateStudentReport({
    required String studentName,
    required String studentCode,
    required String groupName,
    required String teacherName,
    required String subjectName,
    required String teacherNotes,
    required String evaluationRating,
    required int attendancePercentage,
    required int examsAverage,
    required int homeworkCompletion,
    List<Map<String, dynamic>>? recentScores,
  }) async {
    final bytes = await generatePdfBytes(
      studentName: studentName,
      studentCode: studentCode,
      groupName: groupName,
      teacherName: teacherName,
      subjectName: subjectName,
      teacherNotes: teacherNotes,
      evaluationRating: evaluationRating,
      attendancePercentage: attendancePercentage,
      examsAverage: examsAverage,
      homeworkCompletion: homeworkCompletion,
      recentScores: recentScores,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: 'تقرير_المستوى_${studentName.replaceAll(' ', '_')}.pdf',
    );
  }

  static pw.Widget _buildHeader({
    required String teacherName,
    required String subjectName,
    required String currentDate,
    required pw.Font fontBold,
    required pw.Font fontRegular,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColors.blueGrey900,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('تقرير المتابعة والتقييم الشهري', style: pw.TextStyle(font: fontBold, fontSize: 18, color: PdfColors.white)),
              pw.SizedBox(height: 4),
              pw.Text('المادة: $subjectName | الأستاذ: $teacherName', style: pw.TextStyle(font: fontRegular, fontSize: 12, color: PdfColors.blueGrey200)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('تاريخ الإصدار', style: pw.TextStyle(font: fontRegular, fontSize: 10, color: PdfColors.blueGrey300)),
              pw.Text(currentDate, style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.amber400)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildStudentCard({
    required String studentName,
    required String studentCode,
    required String groupName,
    required String evaluationRating,
    required pw.Font fontBold,
    required pw.Font fontRegular,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                children: [
                  pw.Text('اسم الطالب/ة: ', style: pw.TextStyle(font: fontRegular, fontSize: 13, color: PdfColors.grey700)),
                  pw.Text(studentName, style: pw.TextStyle(font: fontBold, fontSize: 14, color: PdfColors.blueGrey900)),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Row(
                children: [
                  pw.Text('المجموعة / الكود: ', style: pw.TextStyle(font: fontRegular, fontSize: 11, color: PdfColors.grey700)),
                  pw.Text('$groupName (#$studentCode)', style: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColors.blue900)),
                ],
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: pw.BoxDecoration(
              color: PdfColors.teal50,
              border: pw.Border.all(color: PdfColors.teal700, width: 1.5),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Column(
              children: [
                pw.Text('التقييم التراكمي العالي', style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColors.teal900)),
                pw.SizedBox(height: 2),
                pw.Text(evaluationRating, style: pw.TextStyle(font: fontBold, fontSize: 13, color: PdfColors.teal900)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildMetricsRow({
    required int attendance,
    required int exams,
    required int homework,
    required pw.Font fontBold,
    required pw.Font fontRegular,
  }) {
    return pw.Row(
      children: [
        pw.Expanded(child: _buildMetricItem('نسبة المواظبة والحضور', '$attendance%', PdfColors.blue700, fontBold, fontRegular)),
        pw.SizedBox(width: 12),
        pw.Expanded(child: _buildMetricItem('متوسط درجات الاختبارات', '$exams%', PdfColors.green700, fontBold, fontRegular)),
        pw.SizedBox(width: 12),
        pw.Expanded(child: _buildMetricItem('التزام حل الواجبات', '$homework%', PdfColors.purple700, fontBold, fontRegular)),
      ],
    );
  }

  static pw.Widget _buildMetricItem(String title, String value, PdfColor color, pw.Font fontBold, pw.Font fontRegular) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        color: PdfColors.white,
      ),
      alignment: pw.Alignment.center,
      child: pw.Column(
        children: [
          pw.Text(title, style: pw.TextStyle(font: fontRegular, fontSize: 11, color: PdfColors.grey800), textAlign: pw.TextAlign.center),
          pw.SizedBox(height: 6),
          pw.Text(value, style: pw.TextStyle(font: fontBold, fontSize: 18, color: color)),
        ],
      ),
    );
  }

  static pw.Widget _buildScoresTable(List<Map<String, dynamic>> scores, pw.Font fontBold, pw.Font fontRegular) {
    return pw.TableHelper.fromTextArray(
      headers: ['اسم الاختبار / التقييم', 'الدرجة التي حصل عليها', 'الدرجة العظمى', 'التقدير'],
      headerStyle: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColors.white),
      headerDecoration: pw.BoxDecoration(color: PdfColors.blueGrey800),
      cellStyle: pw.TextStyle(font: fontRegular, fontSize: 10),
      cellAlignment: pw.Alignment.center,
      data: scores.map((s) => [
        s['title'] ?? 'اختبار دوري',
        '${s['score'] ?? 0}',
        '${s['total'] ?? 10}',
        s['grade'] ?? 'جيد جداً'
      ]).toList(),
    );
  }

  static pw.Widget _buildNotesBox(String notes, pw.Font fontBold, pw.Font fontRegular) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColors.amber50,
        border: pw.Border.all(color: PdfColors.amber600, width: 1.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('📌 ملاحظات وتوجيهات المعلم لولي الأمر:', style: pw.TextStyle(font: fontBold, fontSize: 13, color: PdfColors.amber900)),
          pw.SizedBox(height: 6),
          pw.Text(
            notes.isEmpty ? 'طالب مجتهد وملتزم داخل القاعة، نرجو الاستمرار على نفس هذا العطاء العالي بالمتابعة المستمرة في المنزل.' : notes,
            style: pw.TextStyle(font: fontRegular, fontSize: 11, color: PdfColors.grey900, lineSpacing: 3),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(String teacherName, pw.Font fontBold, pw.Font fontRegular) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Divider(color: PdfColors.grey400, thickness: 1),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('يعتمد من إدارة الأستاذ: $teacherName', style: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColors.blueGrey900)),
                pw.SizedBox(height: 2),
                pw.Text('تطبيق EdSentre — النظام الأحدث لإدارة المدارس والمعلمين المستقلين', style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColors.grey500)),
              ],
            ),
            pw.Container(
              width: 100,
              height: 40,
              alignment: pw.Alignment.center,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300, style: pw.BorderStyle.dashed),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Text('ختم / توقيع المعلم', style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColors.grey400)),
            ),
          ],
        ),
      ],
    );
  }
}
