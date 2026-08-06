import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../shared/data/supabase_repository.dart';
import '../../../../core/widgets/genius/glass_card.dart';
import '../../../../core/config/app_colors.dart';

class FlashGradingScreen extends StatefulWidget {
  final Map<String, dynamic> assignment;
  final List<Map<String, dynamic>> studentsToGrade;

  const FlashGradingScreen({
    super.key,
    required this.assignment,
    required this.studentsToGrade,
  });

  @override
  State<FlashGradingScreen> createState() => _FlashGradingScreenState();
}

class _FlashGradingScreenState extends State<FlashGradingScreen> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  late List<bool> _isSavingList;
  late List<bool> _isSavedList;
  
  String get _assignmentId => widget.assignment['id']?.toString() ?? '';
  double get _maxScore => (widget.assignment['max_score'] as num?)?.toDouble() ?? 100;

  @override
  void initState() {
    super.initState();
    _controllers = widget.studentsToGrade.map((s) {
      final score = s['score'];
      return TextEditingController(text: score != null ? score.toString() : '');
    }).toList();

    _focusNodes = List.generate(widget.studentsToGrade.length, (index) => FocusNode());
    _isSavingList = List.generate(widget.studentsToGrade.length, (index) => false);
    _isSavedList = List.generate(widget.studentsToGrade.length, (index) {
      return widget.studentsToGrade[index]['score'] != null;
    });

    // نعطي التركيز لأول طالب ليس له درجة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final firstEmptyIndex = widget.studentsToGrade.indexWhere((s) => s['score'] == null);
      if (firstEmptyIndex != -1 && _focusNodes.isNotEmpty) {
        FocusScope.of(context).requestFocus(_focusNodes[firstEmptyIndex]);
      } else if (_focusNodes.isNotEmpty) {
        FocusScope.of(context).requestFocus(_focusNodes[0]);
      }
    });
  }

  @override
  void dispose() {
    for (var c in _controllers) { c.dispose(); }
    for (var f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  Future<void> _saveGrade(int index, String value) async {
    if (value.isEmpty) return;
    
    final score = double.tryParse(value);
    if (score == null || score < 0 || score > _maxScore) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('الدرجة غير صالحة. الدرجة النهائية من $_maxScore'), backgroundColor: Colors.red),
      );
      _controllers[index].clear();
      FocusScope.of(context).requestFocus(_focusNodes[index]);
      return;
    }

    setState(() {
      _isSavingList[index] = true;
      _isSavedList[index] = false;
    });

    try {
      final repository = context.read<SupabaseRepository>();
      final studentUserId = widget.studentsToGrade[index]['student_user_id'];
      final submissionId = widget.studentsToGrade[index]['submission_id']; // قد يكون null لو لم يسلم الطالب

      // Upsert grade logic
      if (submissionId != null) {
        await repository.gradeSubmission(
          submissionId: submissionId,
          score: score,
        );
      } else {
        // إنشاء تسليم جديد للورقي
        await repository.client.from('assignment_submissions').insert({
          'assignment_id': _assignmentId,
          'student_user_id': studentUserId,
          'score': score,
          'graded_by': repository.currentUserId,
          'graded_at': DateTime.now().toIso8601String(),
          'status': 'graded',
          'submission_text': 'Paper Exam / Manual Entry',
        });
      }

      if (!mounted) return;
      setState(() {
        _isSavedList[index] = true;
      });

      // الانتقال للطالب التالي أوتوماتيكياً
      if (index + 1 < _focusNodes.length) {
        FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
      } else {
        FocusScope.of(context).unfocus();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم رصد درجات جميع الطلاب بنجاح! 🎉'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ أثناء الحفظ: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingList[index] = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'الرصد السريع (Flash Grading)',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
        elevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
      body: ListView.separated(
        padding: EdgeInsets.fromLTRB(20.w, MediaQuery.of(context).padding.top + 70.h, 20.w, 100.h),
        itemCount: widget.studentsToGrade.length,
        separatorBuilder: (context, index) => SizedBox(height: 12.h),
        itemBuilder: (context, index) {
          final student = widget.studentsToGrade[index];
          final name = student['student_name'] ?? 'طالب';
          
          return GlassCard(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDisplay,
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                
                // حقل الإدخال السريع
                SizedBox(
                  width: 90.w,
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20.sp, 
                      fontWeight: FontWeight.bold, 
                      color: _isSavedList[index] ? Colors.greenAccent : Colors.white
                    ),
                    decoration: InputDecoration(
                      hintText: '$_maxScore',
                      hintStyle: TextStyle(color: Colors.white30),
                      filled: true,
                      fillColor: AppColors.primary.withValues(alpha: 0.1),
                      contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: AppColors.primary, width: 2),
                      ),
                      suffixIcon: _isSavingList[index] 
                        ? Padding(
                            padding: const EdgeInsets.all(12),
                            child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                          )
                        : _isSavedList[index] 
                          ? Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 20.sp)
                          : null,
                    ),
                    onSubmitted: (value) => _saveGrade(index, value),
                    textInputAction: index == widget.studentsToGrade.length - 1 ? TextInputAction.done : TextInputAction.next,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
