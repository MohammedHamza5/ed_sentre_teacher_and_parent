import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/models/exam_models.dart';
import '../services/question_bank_local_service.dart';

class ImportFromBankDialog extends StatefulWidget {
  final Color typeColor;
  
  const ImportFromBankDialog({super.key, required this.typeColor});

  @override
  State<ImportFromBankDialog> createState() => _ImportFromBankDialogState();
}

class _ImportFromBankDialogState extends State<ImportFromBankDialog> {
  final _service = QuestionBankLocalService();
  List<SavedQuestion> _questions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final questions = await _service.getSavedQuestions();
    setState(() {
      _questions = questions;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.inventory_2_outlined, color: widget.typeColor),
                SizedBox(width: 8.w),
                Text(
                  'استيراد من البنك',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_questions.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 32.h),
                child: Center(
                  child: Text(
                    'بنك الأسئلة فارغ.',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _questions.length,
                  separatorBuilder: (context, index) => SizedBox(height: 8.h),
                  itemBuilder: (context, index) {
                    final sq = _questions[index];
                    final q = sq.question;
                    return InkWell(
                      onTap: () => Navigator.pop(context, q),
                      borderRadius: BorderRadius.circular(12.r),
                      child: Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          border: Border.all(color: widget.typeColor.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              q.text,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 8.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  q.type == QuestionType.mcq ? 'اختياري' : 'مقالي',
                                  style: TextStyle(color: widget.typeColor, fontSize: 12.sp),
                                ),
                                Icon(Icons.add_circle, color: widget.typeColor, size: 20.sp),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
