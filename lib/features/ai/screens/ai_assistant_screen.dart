import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/config/app_colors.dart';
import '../../ai/provider/ai_provider.dart';
import '../../../core/providers/center_provider.dart';
import '../../../shared/widgets/premium_widgets.dart';
import 'ai_generate_exam_screen.dart';
import 'ai_chat_screen.dart';
import 'ai_student_analysis_screen.dart';

/// شاشة المساعد الذكي الرئيسية - Premium Dark Mode
class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final aiProvider = context.read<AIProvider>();
    final centerProvider = context.read<CenterProvider>();
    final centerId = centerProvider.currentCenterId;

    await aiProvider.loadCredits();
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
        color: AppColors.primary,
        backgroundColor: AppColors.darkCard,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            _buildSliverAppBar(aiProvider),
            SliverToBoxAdapter(child: SizedBox(height: 16.h)),
            SliverToBoxAdapter(child: _buildWelcomeCard()),
            SliverToBoxAdapter(child: SizedBox(height: 24.h)),
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                'قاعدة المعرفة',
                Icons.menu_book,
                onAdd: _addKnowledge,
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 12.h)),
            SliverToBoxAdapter(child: _buildKnowledgeBaseSection(aiProvider)),
            SliverToBoxAdapter(child: SizedBox(height: 24.h)),
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                'أدوات المساعد',
                Icons.build_circle_outlined,
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 12.h)),
            SliverToBoxAdapter(child: _buildAITools(aiProvider)),
            SliverToBoxAdapter(child: SizedBox(height: 24.h)),
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                'الرصيد والاستخدام',
                Icons.monetization_on_outlined,
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 12.h)),
            SliverToBoxAdapter(child: _buildCreditsCard(aiProvider)),
            SliverToBoxAdapter(child: SizedBox(height: 80.h)),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(AIProvider aiProvider) {
    return SliverAppBar(
      expandedHeight: 140.h,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.darkSurface,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA), Color(0xFF6366F1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Animated AI brain decoration
              Positioned(
                right: -40,
                top: -20,
                child: Icon(
                  Icons.psychology_outlined,
                  size: 180.sp,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
              Positioned(
                bottom: -20,
                left: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: EdgeInsets.only(right: 20.w, bottom: 16.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Icon(
                              Icons.smart_toy_rounded,
                              color: Colors.white,
                              size: 22.sp,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            'المساعد الذكي',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'أنشئ امتحانات وواجبات بالذكاء الاصطناعي',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        // Credit badge
        Container(
          margin: EdgeInsets.only(left: 12.w, top: 8.h),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.stars, size: 16.sp, color: Colors.amber),
              SizedBox(width: 4.w),
              Text(
                '${aiProvider.totalCredits}',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 8.w),
      ],
    );
  }

  Widget _buildWelcomeCard() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: PremiumCard(
        hasGlow: true,
        glowColor: const Color(0xFF8B5CF6),
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                    ),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مرحباً بك في المساعد الذكي',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textOnDark,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'أنشئ امتحانات وواجبات من كتبك وملازمك',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.textOnDarkSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outlined,
                    color: Colors.amber,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'ارفع الكتاب مرة واحدة، وسينشئ لك AI أسئلة جديدة!',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textOnDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
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
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, color: AppColors.primaryLight, size: 18.sp),
          ),
          SizedBox(width: 10.w),
          Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textOnDark,
            ),
          ),
          const Spacer(),
          if (onAdd != null)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onAdd,
                borderRadius: BorderRadius.circular(10.r),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.add, color: Colors.white, size: 14.sp),
                      SizedBox(width: 4.w),
                      Text(
                        'إضافة',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildKnowledgeBaseSection(AIProvider aiProvider) {
    if (aiProvider.knowledgeBase.isEmpty) {
      return _buildEmptyKnowledge();
    }

    return SizedBox(
      height: 140.h,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        scrollDirection: Axis.horizontal,
        itemCount: aiProvider.knowledgeBase.length,
        separatorBuilder: (_, __) => SizedBox(width: 12.w),
        itemBuilder: (context, index) {
          return _buildKnowledgeCard(aiProvider.knowledgeBase[index], index);
        },
      ),
    );
  }

  Widget _buildEmptyKnowledge() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: PremiumCard(
        onTap: _addKnowledge,
        padding: EdgeInsets.all(20.w),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Icon(
                Icons.upload_file_rounded,
                color: AppColors.primaryLight,
                size: 30.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'لا يوجد محتوى بعد',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15.sp,
                      color: AppColors.textOnDark,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'اضغط لإضافة كتاب أو ملزمة ليتمكن AI من إنشاء الامتحانات',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textOnDarkSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textOnDarkHint,
              size: 16.sp,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildKnowledgeCard(Map<String, dynamic> knowledge, int index) {
    final title = knowledge['title'] ?? 'بدون عنوان';
    final type = knowledge['content_type'] ?? 'textbook';
    final subject = knowledge['subject_name'] ?? '';

    IconData typeIcon;
    Color typeColor;
    switch (type) {
      case 'notes':
        typeIcon = Icons.note_outlined;
        typeColor = AppColors.warning;
        break;
      case 'exercises':
        typeIcon = Icons.assignment_outlined;
        typeColor = AppColors.accent;
        break;
      default:
        typeIcon = Icons.menu_book_outlined;
        typeColor = AppColors.primary;
    }

    return SizedBox(
          width: 200.w,
          child: PremiumCard(
            padding: EdgeInsets.all(14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(typeIcon, color: typeColor, size: 18.sp),
                    ),
                    const Spacer(),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        size: 18.sp,
                        color: AppColors.textOnDarkHint,
                      ),
                      color: AppColors.darkElevated,
                      onSelected: (action) =>
                          _handleKnowledgeAction(action, knowledge),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'generate',
                          child: Row(
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                size: 16.sp,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'إنشاء امتحان',
                                style: TextStyle(color: AppColors.textOnDark),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete,
                                size: 16.sp,
                                color: AppColors.error,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'حذف',
                                style: TextStyle(color: AppColors.error),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.sp,
                    color: AppColors.textOnDark,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subject.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(
                    subject,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.textOnDarkSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        )
        .animate(delay: Duration(milliseconds: 100 * index))
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.1, end: 0);
  }

  Widget _buildAITools(AIProvider aiProvider) {
    final tools = [
      {
        'icon': Icons.quiz_outlined,
        'label': 'إنشاء امتحان',
        'desc': 'امتحان شامل من المحتوى',
        'color': AppColors.warning,
        'credits': 10,
        'enabled': true,
        'onTap': () => _openGenerateExam('exam'),
      },
      {
        'icon': Icons.assignment_outlined,
        'label': 'واجب منزلي',
        'desc': 'واجب مخصص من المحتوى',
        'color': AppColors.primary,
        'credits': 5,
        'enabled': true,
        'onTap': () => _openGenerateExam('homework'),
      },
      {
        'icon': Icons.summarize_outlined,
        'label': 'ملخص تلقائي',
        'desc': 'ملخص مبسط للمحتوى',
        'color': AppColors.secondary,
        'credits': 3,
        'enabled': true,
        'onTap': _generateSummary,
      },
      {
        'icon': Icons.chat_bubble_outline,
        'label': 'محادثة AI',
        'desc': 'اسأل المساعد الذكي',
        'color': const Color(0xFF8B5CF6),
        'credits': 1,
        'enabled': true,
        'onTap': _openAIChat,
      },
      {
        'icon': Icons.analytics_outlined,
        'label': 'تحليل طالب',
        'desc': 'تحليل شامل لأداء الطالب',
        'color': AppColors.accent,
        'credits': 5,
        'enabled': true,
        'onTap': _openStudentAnalysis,
      },
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: tools.asMap().entries.map((entry) {
          final i = entry.key;
          final tool = entry.value;
          return Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: _buildToolCard(
              icon: tool['icon'] as IconData,
              label: tool['label'] as String,
              description: tool['desc'] as String,
              color: tool['color'] as Color,
              credits: tool['credits'] as int,
              enabled: tool['enabled'] as bool,
              onTap: tool['onTap'] as VoidCallback,
              index: i,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildToolCard({
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    required int credits,
    required bool enabled,
    required VoidCallback onTap,
    required int index,
  }) {
    return PremiumCard(
          onTap: enabled ? onTap : null,
          padding: EdgeInsets.all(16.w),
          child: Opacity(
            opacity: enabled ? 1.0 : 0.5,
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: color.withValues(alpha: 0.2)),
                  ),
                  child: Icon(icon, color: color, size: 24.sp),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                          color: AppColors.textOnDark,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.textOnDarkSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Credits badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.stars, size: 12.sp, color: Colors.amber),
                      SizedBox(width: 3.w),
                      Text(
                        '$credits',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textOnDarkHint,
                  size: 18.sp,
                ),
              ],
            ),
          ),
        )
        .animate(delay: Duration(milliseconds: 80 * index))
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.05, end: 0);
  }

  Widget _buildCreditsCard(AIProvider aiProvider) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: PremiumCard(
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCreditStat(
                  'الرصيد الكلي',
                  aiProvider.totalCredits,
                  Colors.amber,
                ),
                Container(width: 1, height: 50.h, color: AppColors.darkBorder),
                _buildCreditStat(
                  'المجاني',
                  aiProvider.freeCredits,
                  AppColors.success,
                ),
                Container(width: 1, height: 50.h, color: AppColors.darkBorder),
                _buildCreditStat(
                  'المدفوع',
                  aiProvider.paidCredits,
                  AppColors.primary,
                ),
              ],
            ),
            SizedBox(height: 16.h),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6.r),
              child: LinearProgressIndicator(
                value: aiProvider.totalCredits > 0
                    ? aiProvider.paidCredits / aiProvider.totalCredits
                    : 0,
                minHeight: 6.h,
                backgroundColor: AppColors.darkBorder,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF8B5CF6),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: GradientButton(
                text: 'شراء رصيد إضافي',
                icon: Icons.add_shopping_cart,
                onPressed: _buyCredits,
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFFB923C)],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 200.ms);
  }

  Widget _buildCreditStat(String label, int value, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.stars, color: color, size: 18.sp),
        ),
        SizedBox(height: 8.h),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textOnDark,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.sp,
            color: AppColors.textOnDarkSecondary,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════════════════

  void _addKnowledge() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => const _AddKnowledgeSheet(),
    ).then((_) => _loadData());
  }

  void _handleKnowledgeAction(String action, Map<String, dynamic> knowledge) {
    switch (action) {
      case 'generate':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AIGenerateExamScreen(
              knowledgeBaseId: knowledge['id'],
              knowledgeTitle: knowledge['title'],
            ),
          ),
        );
        break;
      case 'delete':
        _deleteKnowledge(knowledge);
        break;
    }
  }

  Future<void> _deleteKnowledge(Map<String, dynamic> knowledge) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkElevated,
        title: Text(
          'حذف المحتوى',
          style: TextStyle(color: AppColors.textOnDark),
        ),
        content: Text(
          'هل تريد حذف "${knowledge['title']}"؟',
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
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final aiProvider = context.read<AIProvider>();
      final centerProvider = context.read<CenterProvider>();
      await aiProvider.deleteFromKnowledgeBase(
        knowledge['id'],
        centerProvider.currentCenterId!,
      );
    }
  }

  void _openGenerateExam(String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AIGenerateExamScreen(
          examType: type,
        ),
      ),
    );
  }

  void _generateSummary() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('قريباً...'),
        backgroundColor: AppColors.darkElevated,
      ),
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

  void _buyCredits() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('قريباً...'),
        backgroundColor: AppColors.darkElevated,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// شاشة إضافة محتوى لقاعدة المعرفة - Dark Mode
// ═══════════════════════════════════════════════════════════════════════

class _AddKnowledgeSheet extends StatefulWidget {
  const _AddKnowledgeSheet();

  @override
  State<_AddKnowledgeSheet> createState() => _AddKnowledgeSheetState();
}

class _AddKnowledgeSheetState extends State<_AddKnowledgeSheet> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _subjectController = TextEditingController();
  final _gradeController = TextEditingController();

  String _contentType = 'textbook';
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _subjectController.dispose();
    _gradeController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: AppColors.textOnDarkSecondary),
      hintStyle: TextStyle(color: AppColors.textOnDarkHint),
      filled: true,
      fillColor: AppColors.darkInput,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: AppColors.darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: AppColors.darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.darkBorder,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'إضافة محتوى جديد',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textOnDark,
              ),
            ),
            SizedBox(height: 20.h),

            // نوع المحتوى
            Text(
              'نوع المحتوى',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textOnDark,
              ),
            ),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 8.w,
              children: [
                _buildTypeChip('textbook', 'كتاب', Icons.menu_book),
                _buildTypeChip('notes', 'ملازم', Icons.note),
                _buildTypeChip('exercises', 'تمارين', Icons.assignment),
              ],
            ),
            SizedBox(height: 16.h),

            // العنوان
            TextField(
              controller: _titleController,
              style: TextStyle(color: AppColors.textOnDark),
              decoration: _inputDecoration(
                'عنوان المحتوى',
                hint: 'مثال: كتاب الرياضيات - الباب الأول',
              ),
            ),
            SizedBox(height: 12.h),

            // المادة والصف
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _subjectController,
                    style: TextStyle(color: AppColors.textOnDark),
                    decoration: _inputDecoration('المادة'),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: TextField(
                    controller: _gradeController,
                    style: TextStyle(color: AppColors.textOnDark),
                    decoration: _inputDecoration('الصف'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // المحتوى النصي
            TextField(
              controller: _contentController,
              style: TextStyle(color: AppColors.textOnDark),
              decoration: _inputDecoration(
                'المحتوى النصي',
                hint: 'الصق محتوى الكتاب أو الملزمة هنا...',
              ),
              maxLines: 8,
            ),
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Colors.amber,
                    size: 16.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'انسخ محتوى الفصل من ملف Word أو PDF والصقه هنا',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.textOnDarkSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // أزرار
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textOnDarkSecondary,
                      side: BorderSide(color: AppColors.darkBorder),
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: const Text('إلغاء'),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 20.w,
                              height: 20.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('حفظ'),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(String value, String label, IconData icon) {
    final isSelected = _contentType == value;
    return GestureDetector(
      onTap: () => setState(() => _contentType = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected ? null : AppColors.darkCard,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.darkBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16.sp,
              color: isSelected ? Colors.white : AppColors.textOnDarkSecondary,
            ),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : AppColors.textOnDarkSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('أدخل العنوان والمحتوى'),
          backgroundColor: AppColors.darkElevated,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final aiProvider = context.read<AIProvider>();
      final centerProvider = context.read<CenterProvider>();

      await aiProvider.addToKnowledgeBase(
        centerId: centerProvider.currentCenterId!,
        title: _titleController.text,
        contentType: _contentType,
        extractedText: _contentController.text,
        subjectName: _subjectController.text,
        gradeLevel: _gradeController.text,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم إضافة المحتوى بنجاح ✅'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
