import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/app_colors.dart';
import '../../ai/provider/ai_provider.dart';
import '../../../../core/providers/center_provider.dart';

// Extracted Widgets
import '../widgets/ai_assistant_header.dart';
import '../widgets/ai_daily_usage_pulse.dart';
import '../widgets/ai_tool_card.dart';
import '../widgets/add_knowledge_sheet.dart';
import '../widgets/knowledge_card.dart';

// Navigation Screens
import 'ai_generate_exam_screen.dart';
import 'ai_chat_screen.dart';
import 'ai_student_analysis_screen.dart';

/// الشاشة الرئيسية للمساعد الذكي
class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    // Pulse animation for the AI "breathing" effect
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final aiProvider = context.read<AIProvider>();
    final centerProvider = context.read<CenterProvider>();
    final centerId = centerProvider.currentCenterId;

    await aiProvider.loadDailyUsage();
    if (centerId != null) {
      await aiProvider.loadKnowledgeBase(centerId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final aiProvider = context.watch<AIProvider>();

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: RefreshIndicator(
        onRefresh: _loadData,
        backgroundColor: AppColors.primary,
        color: Theme.of(context).colorScheme.surface,
        child: CustomScrollView(
          physics: const ClampingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            const AIAssistantHeader(),
            SliverToBoxAdapter(child: SizedBox(height: 20.h)),
            SliverToBoxAdapter(
              child: AIDailyUsagePulse(
                used: aiProvider.todayGenerationCount,
                limit: 5,
                pulseAnimation: _pulseController,
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 24.h)),
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                'أدوات الذكاء الاصطناعي',
                Icons.auto_awesome_rounded,
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 12.h)),
            SliverToBoxAdapter(child: _buildAITools(aiProvider)),
            SliverToBoxAdapter(child: SizedBox(height: 24.h)),
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                'قاعدة المعرفة',
                Icons.menu_book_rounded,
                onAdd: _addKnowledge,
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 12.h)),
            SliverToBoxAdapter(child: _buildKnowledgeBaseSection(aiProvider)),
            SliverToBoxAdapter(child: SizedBox(height: 100.h)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon, {
    VoidCallback? onAdd,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, color: const Color(0xFF8B5CF6), size: 18.sp),
          ),
          SizedBox(width: 10.w),
          Text(
            title,
            style: TextStyle(
              color: AppColors.textOnDark,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          if (onAdd != null)
            IconButton(
              onPressed: onAdd,
              icon: Icon(Icons.add_circle_outline_rounded),
              color: const Color(0xFF8B5CF6),
              tooltip: 'إضافة محتوى',
            ),
        ],
      ),
    );
  }

  Widget _buildAITools(AIProvider aiProvider) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          _buildToolItem(
            icon: Icons.quiz_rounded,
            label: 'توليد امتحان كامل',
            description: 'امتحان شامل لكل المقرر مع تحديد مستوى الصعوبة',
            gradient: const LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFF6C3CE1)],
            ),
            tag: 'الاستخدام الموصى به',
            onTap: () => _openGenerateExam('full'),
            aiProvider: aiProvider,
          ),
          SizedBox(height: 12.h),
          _buildToolItem(
            icon: Icons.assignment_rounded,
            label: 'توليد واجب ذكي',
            description: 'واجب قصير لدرس محدد مع أسئلة متنوعة',
            gradient: const LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
            ),
            tag: 'تخصيص كامل',
            onTap: () => _openGenerateExam('homework'),
            aiProvider: aiProvider,
          ),
          SizedBox(height: 12.h),
          _buildToolItem(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'مساعد المعلم التعاوني',
            description:
                'اسأل AI عن أفكار للامتحانات أو طرق الشرح (لا يستهلك الحد)',
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)],
            ),
            tag: 'دردشة حرة',
            onTap: _openAIChat,
            aiProvider: aiProvider,
            bypassLimit: true,
          ),
          SizedBox(height: 12.h),
          _buildToolItem(
            icon: Icons.analytics_rounded,
            label: 'تحليل أداء الطلاب',
            description: 'تقارير ذكية عن نقاط قوة وضعف الطلاب (لا يستهلك الحد)',
            gradient: const LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
            ),
            tag: 'قريباً',
            onTap: _openStudentAnalysis,
            isDisabled: true,
            aiProvider: aiProvider,
          ),
        ],
      ),
    );
  }

  Widget _buildToolItem({
    required IconData icon,
    required String label,
    required String description,
    required LinearGradient gradient,
    required String tag,
    required VoidCallback onTap,
    required AIProvider aiProvider,
    bool isDisabled = false,
    bool bypassLimit = false,
  }) {
    // If not bypassed and usage is >= 5, it's disabled.
    final overLimit = !bypassLimit && aiProvider.todayGenerationCount >= 5;
    final actuallyDisabled = isDisabled || overLimit;

    void handleTap() {
      if (actuallyDisabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('لقد استنفدت حدك اليومي. حاول غداً.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        );
        return;
      }
      onTap();
    }

    return AIToolCard(
      icon: icon,
      label: label,
      description: description,
      gradient: gradient,
      tag: tag,
      isDisabled: actuallyDisabled,
      onTap: handleTap,
    );
  }

  Widget _buildKnowledgeBaseSection(AIProvider aiProvider) {
    if (aiProvider.isLoadingKnowledge) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
        ),
      );
    }

    if (aiProvider.knowledgeBase.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: (Theme.of(context).dividerTheme.color ?? Colors.grey.shade300)),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.my_library_books_rounded,
                  color: const Color(0xFF8B5CF6),
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'قاعدة المعرفة فارغة',
                      style: TextStyle(
                        color: AppColors.textOnDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'أضف الملازم، الكتب، والتمارين هنا ليتمكن الذكاء الاصطناعي من استخراج الأسئلة منها.',
                      style: TextStyle(
                        color: AppColors.textOnDarkSecondary,
                        fontSize: 12.sp,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: aiProvider.knowledgeBase.length,
      itemBuilder: (context, index) {
        final item = aiProvider.knowledgeBase[index];
        return KnowledgeCard(
          item: item,
          onDelete: () => _deleteKnowledge(item['id'].toString()),
        );
      },
    );
  }

  Future<void> _deleteKnowledge(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'حذف المحتوى',
          style: TextStyle(color: AppColors.textOnDark, fontSize: 18.sp),
        ),
        content: Text(
          'هل أنت متأكد من حذف هذا المحتوى؟ لن يستخدمه الذكاء الاصطناعي بعد الآن.',
          style: TextStyle(color: AppColors.textOnDarkSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'إلغاء',
              style: TextStyle(color: AppColors.textOnDarkSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('حذف', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;
    final aiProvider = context.read<AIProvider>();
    final centerId = context.read<CenterProvider>().currentCenterId;
    if (centerId == null) return;

    try {
      await aiProvider.deleteFromKnowledgeBase(centerId, id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حذف المحتوى بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ أثناء الحذف: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _addKnowledge() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) => const AddKnowledgeSheet(),
    );
  }

  void _openGenerateExam(String type) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AIGenerateExamScreen(examType: type)),
    );
  }

  void _openAIChat() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AIChatScreen()),
    );
  }

  void _openStudentAnalysis() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AIStudentAnalysisScreen()),
    );
  }
}
