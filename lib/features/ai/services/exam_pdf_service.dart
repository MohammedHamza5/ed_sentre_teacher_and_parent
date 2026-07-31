import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// خدمة توليد ملفات الـ PDF لاختبارات الذكاء الاصطناعي مع دعم خط عربي كامل
class ExamPdfService {
  /// بناء وعرض وثيقة الـ PDF للطباعة أو المشاركة
  static Future<void> generateAndPrintExam({
    required String title,
    required String description,
    required int durationMinutes,
    required List<Map<String, dynamic>> questions,
    required bool isModelAnswer,
    String? teacherName,
    String? subjectName,
  }) async {
    final pdf = pw.Document(
      title: title,
      author: teacherName ?? 'EdSentre Teacher',
    );

    // تحميل الخط العربي الاحترافي (Cairo) من سحابة خطوط جوجل وإدراجه بالكاش
    final fontRegular = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();

    final theme = pw.ThemeData.withFont(
      base: fontRegular,
      bold: fontBold,
    );

    int totalMarks = 0;
    for (final q in questions) {
      totalMarks += (q['marks'] as num? ?? 2).toInt();
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(
          title: title,
          description: description,
          durationMinutes: durationMinutes,
          totalMarks: totalMarks,
          teacherName: teacherName ?? 'المعلم المستقل',
          subjectName: subjectName ?? 'اختبار تقييم المستوى',
          isModelAnswer: isModelAnswer,
          fontBold: fontBold,
          fontRegular: fontRegular,
        ),
        footer: (context) => _buildFooter(context, fontRegular),
        build: (context) {
          return [
            pw.SizedBox(height: 12),
            if (!isModelAnswer) _buildStudentInfoBox(fontBold),
            pw.SizedBox(height: 16),
            ...List.generate(questions.length, (index) {
              return _buildQuestionItem(
                index: index + 1,
                question: questions[index],
                isModelAnswer: isModelAnswer,
                fontBold: fontBold,
                fontRegular: fontRegular,
              );
            }),
          ];
        },
      ),
    );

    // استعراض نافذة نظام التشغيل الرسمية للطباعة أو التصدير (PDF)
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${title.replaceAll(' ', '_')}_${isModelAnswer ? 'نموذج_إجابة' : 'ورقة_طالب'}.pdf',
    );
  }

  /// ترويسة الصفحة الأولى والتالية في المستند
  static pw.Widget _buildHeader({
    required String title,
    required String description,
    required int durationMinutes,
    required int totalMarks,
    required String teacherName,
    required String subjectName,
    required bool isModelAnswer,
    required pw.Font fontBold,
    required pw.Font fontRegular,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey600, width: 1.5),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            color: PdfColors.grey100,
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    teacherName,
                    style: pw.TextStyle(font: fontBold, fontSize: 14, color: PdfColors.blue900),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    subjectName,
                    style: pw.TextStyle(font: fontRegular, fontSize: 11, color: PdfColors.grey700),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    title,
                    style: pw.TextStyle(font: fontBold, fontSize: 16),
                  ),
                  if (isModelAnswer)
                    pw.Container(
                      margin: const pw.EdgeInsets.only(top: 4),
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.green700,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Text(
                        'نموذج الإجابة الرسمي (Model Answer)',
                        style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.white),
                      ),
                    ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'المدة: $durationMinutes دقيقة',
                    style: pw.TextStyle(font: fontBold, fontSize: 11),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'الدرجة الكلية: $totalMarks درجة',
                    style: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColors.red800),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (description.isNotEmpty) ...[
          pw.SizedBox(height: 6),
          pw.Text(
            description,
            style: pw.TextStyle(font: fontRegular, fontSize: 11, color: PdfColors.grey600),
          ),
        ],
        pw.SizedBox(height: 8),
        pw.Divider(color: PdfColors.grey400, thickness: 1),
      ],
    );
  }

  /// مربع اسم الطالب ورقم المجموعة في ورقة الطلاب
  static pw.Widget _buildStudentInfoBox(pw.Font fontBold) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey500, style: pw.BorderStyle.dashed),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('اسم الطالب / .................................................................', style: pw.TextStyle(font: fontBold, fontSize: 12)),
          pw.Text('كود الطالب / المجموعة: ...........................', style: pw.TextStyle(font: fontBold, fontSize: 12)),
        ],
      ),
    );
  }

  /// بناء عنصر السؤال الواحد واختياراته
  static pw.Widget _buildQuestionItem({
    required int index,
    required Map<String, dynamic> question,
    required bool isModelAnswer,
    required pw.Font fontBold,
    required pw.Font fontRegular,
  }) {
    final text = question['text']?.toString() ?? 'سؤال بدون نص';
    final marks = (question['marks'] as num? ?? 2).toInt();
    final options = (question['options'] as List?)?.cast<String>() ?? [];
    final correctIndex = (question['correct_answer'] as int?) ?? 0;
    final explanation = question['explanation']?.toString() ?? '';

    final letters = ['أ', 'ب', 'ج', 'د', 'هـ'];

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 14),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: index % 2 == 0 ? PdfColors.grey50 : PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: PdfColors.grey200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text(
                  '($index) $text',
                  style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.black),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blueGrey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(
                  '$marks درجات',
                  style: pw.TextStyle(font: fontBold, fontSize: 10),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Wrap(
            spacing: 20,
            runSpacing: 6,
            children: List.generate(options.length, (optIndex) {
              final isThisCorrect = isModelAnswer && (optIndex == correctIndex);
              final letter = optIndex < letters.length ? letters[optIndex] : '${optIndex + 1}';

              return pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: isThisCorrect
                    ? pw.BoxDecoration(
                        color: PdfColors.green100,
                        border: pw.Border.all(color: PdfColors.green700, width: 1),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                      )
                    : null,
                child: pw.Row(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Container(
                      width: 18,
                      height: 18,
                      alignment: pw.Alignment.center,
                      decoration: pw.BoxDecoration(
                        shape: pw.BoxShape.circle,
                        border: pw.Border.all(color: isThisCorrect ? PdfColors.green700 : PdfColors.grey600),
                        color: isThisCorrect ? PdfColors.green700 : PdfColors.white,
                      ),
                      child: pw.Text(
                        letter,
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 9,
                          color: isThisCorrect ? PdfColors.white : PdfColors.grey800,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 6),
                    pw.Text(
                      options[optIndex],
                      style: pw.TextStyle(
                        font: isThisCorrect ? fontBold : fontRegular,
                        fontSize: 11,
                        color: isThisCorrect ? PdfColors.green900 : PdfColors.grey900,
                      ),
                    ),
                    if (isThisCorrect) ...[
                      pw.SizedBox(width: 6),
                      pw.Text(
                        '(إجابة صحيحة ✓)',
                        style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.green800),
                      ),
                    ]
                  ],
                ),
              );
            }),
          ),
          if (isModelAnswer && explanation.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(
                color: PdfColors.amber50,
                border: pw.Border(right: pw.BorderSide(color: PdfColors.amber700, width: 3)),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('💡 للتفهم والتحليل: ', style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.amber900)),
                  pw.Expanded(
                    child: pw.Text(explanation, style: pw.TextStyle(font: fontRegular, fontSize: 10, color: PdfColors.grey800)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// تزيين أسفل الصفحة وحمية أرقام الصفحات
  static pw.Widget _buildFooter(pw.Context context, pw.Font fontRegular) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'تم الإنشاء بواسطة تطبيق EdSentre المطور للمعلمين المستقلين',
          style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColors.grey500),
        ),
        pw.Text(
          'صفحة ${context.pageNumber} من ${context.pagesCount}',
          style: pw.TextStyle(font: fontRegular, fontSize: 10, color: PdfColors.grey700),
        ),
      ],
    );
  }
}
