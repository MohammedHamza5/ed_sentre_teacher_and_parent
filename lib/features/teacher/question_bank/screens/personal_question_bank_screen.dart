import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/widgets/genius/glass_card.dart';
import '../../../../shared/models/exam_models.dart';
import '../services/question_bank_local_service.dart';

class PersonalQuestionBankScreen extends StatefulWidget {
  const PersonalQuestionBankScreen({super.key});

  @override
  State<PersonalQuestionBankScreen> createState() => _PersonalQuestionBankScreenState();
}

class _PersonalQuestionBankScreenState extends State<PersonalQuestionBankScreen> {
  final QuestionBankLocalService _service = QuestionBankLocalService();
  List<SavedQuestion> _allQuestions = [];
  List<SavedQuestion> _filteredQuestions = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() => _isLoading = true);
    final questions = await _service.getSavedQuestions();
    setState(() {
      _allQuestions = questions;
      _filteredQuestions = questions;
      _isLoading = false;
    });
  }

  void _filterQuestions(String query) {
    _searchQuery = query;
    setState(() {
      if (query.isEmpty) {
        _filteredQuestions = _allQuestions;
      } else {
        _filteredQuestions = _allQuestions.where((q) {
          final textMatch = q.question.text.toLowerCase().contains(query.toLowerCase());
          final tagMatch = q.tags.any((t) => t.toLowerCase().contains(query.toLowerCase()));
          return textMatch || tagMatch;
        }).toList();
      }
    });
  }

  Future<void> _deleteQuestion(String id) async {
    await _service.deleteQuestion(id);
    _loadQuestions();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف السؤال من بنك الأسئلة.'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'بنك الأسئلة الشخصي',
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
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: 100.h,
            left: -50.w,
            child: Container(
              width: 300.w,
              height: 300.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.amber.withValues(alpha: 0.1),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Search Bar
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                  child: TextField(
                    onChanged: _filterQuestions,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'ابحث عن سؤال أو وسم...',
                      hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                      prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                
                // List of Questions
                Expanded(
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : _filteredQuestions.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.inventory_2_outlined, size: 80.sp, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                                  SizedBox(height: 16.h),
                                  Text(
                                    _searchQuery.isEmpty ? 'بنك الأسئلة فارغ حالياً' : 'لا توجد نتائج للبحث',
                                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 16.sp),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                              itemCount: _filteredQuestions.length,
                              separatorBuilder: (context, index) => SizedBox(height: 16.h),
                              itemBuilder: (context, index) {
                                final sq = _filteredQuestions[index];
                                final q = sq.question;
                                
                                return GlassCard(
                                  padding: EdgeInsets.all(16.w),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              q.text,
                                              style: TextStyle(
                                                fontSize: 15.sp,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textDisplay,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                                            onPressed: () => _deleteQuestion(sq.id),
                                            tooltip: 'حذف من البنك',
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8.h),
                                      if (q.type == QuestionType.mcq && q.options != null) ...[
                                        Wrap(
                                          spacing: 8.w,
                                          runSpacing: 8.h,
                                          children: (q.options as List).map((opt) {
                                            final isCorrect = opt == q.correctAnswer;
                                            return Container(
                                              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                              decoration: BoxDecoration(
                                                color: isCorrect ? Colors.green.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                                                border: Border.all(color: isCorrect ? Colors.greenAccent : Colors.transparent),
                                                borderRadius: BorderRadius.circular(8.r),
                                              ),
                                              child: Text(
                                                opt.toString(),
                                                style: TextStyle(
                                                  color: isCorrect ? Colors.greenAccent : Colors.white70,
                                                  fontSize: 12.sp,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                        SizedBox(height: 12.h),
                                      ],
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(6.r),
                                            ),
                                            child: Text(
                                              q.type == QuestionType.mcq ? 'اختيار من متعدد' : 'مقالي',
                                              style: TextStyle(color: AppColors.primary, fontSize: 11.sp),
                                            ),
                                          ),
                                          Text(
                                            'الدرجة: ${q.marks}',
                                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12.sp),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
