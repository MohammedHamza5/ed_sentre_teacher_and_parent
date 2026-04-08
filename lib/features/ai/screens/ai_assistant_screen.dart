import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/config/app_colors.dart';
import '../../ai/provider/ai_provider.dart';
import '../../../core/providers/center_provider.dart';
import '../../../shared/widgets/premium_widgets.dart';
import 'ai_generate_exam_screen.dart';
import 'ai_chat_screen.dart';
import 'ai_student_analysis_screen.dart';

/// شاشة المساعد الذكي — ديزاين حي ومبهر
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

    // NOTE: Single pulse animation for the AI "breathing" effect
    // — makes the screen feel alive instead of static.
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
        color: AppColors.darkCard,
        child: CustomScrollView(
          physics: const ClampingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            _buildSliverAppBar(aiProvider),
            SliverToBoxAdapter(child: SizedBox(height: 20.h)),
            SliverToBoxAdapter(child: _buildDailyUsagePulse(aiProvider)),
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

  // ═══════════════════════════════════════════════════════════════════════
  // APP BAR
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildSliverAppBar(AIProvider aiProvider) {
    return SliverAppBar(
      expandedHeight: 130.h,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.darkSurface,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF6C3CE1),
                Color(0xFF8B5CF6),
                Color(0xFF4F46E5),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Decorative brain pattern
              Positioned(
                right: -30,
                top: -10,
                child: Icon(
                  Icons.psychology_outlined,
                  size: 160.sp,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
              Positioned(
                left: -30,
                bottom: -30,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // Title
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
                            padding: EdgeInsets.all(10.w),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Icon(
                              Icons.auto_awesome_rounded,
                              color: Colors.white,
                              size: 22.sp,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'المساعد الذكي',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'أنشئ امتحانات وحلّل أداء طلابك',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11.sp,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DAILY USAGE — Live Pulse Card (replaces credit system)
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildDailyUsagePulse(AIProvider aiProvider) {
    final used = aiProvider.todayGenerationCount;
    const limit = 5;
    final remaining = (limit - used).clamp(0, limit);
    final progress = used / limit;

    // Dynamic color based on remaining
    final Color statusColor;
    final String statusText;
    final IconData statusIcon;

    if (remaining == 0) {
      statusColor = AppColors.error;
      statusText = 'اكتمل حدك اليومي — عد غداً!';
      statusIcon = Icons.hourglass_empty_rounded;
    } else if (remaining <= 2) {
      statusColor = AppColors.warning;
      statusText = 'باقي $remaining من $limit لهذا اليوم';
      statusIcon = Icons.warning_amber_rounded;
    } else {
      statusColor = const Color(0xFF8B5CF6);
      statusText = 'باقي $remaining من $limit لهذا اليوم';
      statusIcon = Icons.bolt_rounded;
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          // NOTE: Subtle glow pulse to make the card feel "alive"
          final glowOpacity = 0.2 + (_pulseController.value * 0.15);

          return Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withValues(alpha: glowOpacity),
                  blurRadius: 20,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: child,
          );
        },
        child: Column(
          children: [
            Row(
              children: [
                // Animated icon
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        statusColor,
                        statusColor.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14.r),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    statusIcon,
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
                        'الاستخدام اليومي',
                        style: TextStyle(
                          color: AppColors.textOnDark,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Count display
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.25),
                    ),
                  ),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$remaining',
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: '/$limit',
                          style: TextStyle(
                            color: statusColor.withValues(alpha: 0.6),
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6.r),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return LinearProgressIndicator(
                    value: value,
                    minHeight: 6.h,
                    backgroundColor: AppColors.darkBorder,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SECTION HEADER
  // ═══════════════════════════════════════════════════════════════════════

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
            child: Icon(
              icon,
              color: const Color(0xFF8B5CF6),
              size: 18.sp,
            ),
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
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF6C3CE1)],
                    ),
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

  // ═══════════════════════════════════════════════════════════════════════
  // AI TOOLS — فقط الأدوات الحقيقية التي تعمل
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildAITools(AIProvider aiProvider) {
    final atLimit = aiProvider.todayGenerationCount >= 5;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          _AIToolCard(
            icon: Icons.quiz_rounded,
            label: 'إنشاء امتحان',
            description: 'أنشئ امتحان شامل من محتوى كتابك أو ملزمتك',
            gradient: const LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFFB923C)],
            ),
            tag: 'امتحان',
            isDisabled: atLimit,
            onTap: () => _openGenerateExam('exam'),
          ),
          SizedBox(height: 10.h),
          _AIToolCard(
            icon: Icons.assignment_turned_in_rounded,
            label: 'إنشاء كويز / واجب',
            description: 'كويز سريع أو واجب منزلي مخصص',
            gradient: const LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
            ),
            tag: 'واجب',
            isDisabled: atLimit,
            onTap: () => _openGenerateExam('homework'),
          ),
          SizedBox(height: 10.h),
          _AIToolCard(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'محادثة مع المساعد',
            description: 'اسأل المساعد أي سؤال — تربوي، تحضير، أفكار',
            gradient: const LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
            ),
            tag: 'محادثة',
            isDisabled: false, // NOTE: Chat is always available — no daily limit
            onTap: _openAIChat,
          ),
          SizedBox(height: 10.h),
          _AIToolCard(
            icon: Icons.analytics_rounded,
            label: 'تحليل أداء الطالب',
            description: 'تحليل شامل بالذكاء الاصطناعي لنقاط القوة والضعف',
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF34D399)],
            ),
            tag: 'تحليل',
            isDisabled: false, // NOTE: Analysis is always available
            onTap: _openStudentAnalysis,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // KNOWLEDGE BASE SECTION
  // ═══════════════════════════════════════════════════════════════════════

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
          return _buildKnowledgeCard(aiProvider.knowledgeBase[index]);
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
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                ),
              ),
              child: Icon(
                Icons.upload_file_rounded,
                color: const Color(0xFF8B5CF6),
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
                    'ارفع كتاب أو ملزمة مرة واحدة — وسينشئ AI أسئلة منها كل مرة!',
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
    );
  }

  Widget _buildKnowledgeCard(Map<String, dynamic> knowledge) {
    final title = knowledge['title'] ?? 'بدون عنوان';
    final type = knowledge['content_type'] ?? 'textbook';
    final subject = knowledge['subject_name'] ?? '';

    final (IconData typeIcon, Color typeColor) = switch (type) {
      'notes' => (Icons.note_outlined, AppColors.warning),
      'exercises' => (Icons.assignment_outlined, const Color(0xFF8B5CF6)),
      _ => (Icons.menu_book_outlined, const Color(0xFF3B82F6)),
    };

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
                            color: const Color(0xFF8B5CF6),
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
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: AlertDialog(
          backgroundColor: AppColors.darkElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
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
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'إلغاء',
                style: TextStyle(color: AppColors.textOnDarkSecondary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      final aiProvider = context.read<AIProvider>();
      final centerProvider = context.read<CenterProvider>();
      await aiProvider.deleteFromKnowledgeBase(
        knowledge['id'],
        centerProvider.currentCenterId!,
      );
    }
  }

  void _openGenerateExam(String type) {
    final aiProvider = context.read<AIProvider>();

    if (aiProvider.todayGenerationCount >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.hourglass_empty, color: Colors.white),
              SizedBox(width: 8.w),
              const Expanded(
                child: Text('اكتمل حدك اليومي (5 امتحانات). عد غداً!'),
              ),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      );
      return;
    }

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

// ═══════════════════════════════════════════════════════════════════════
// AI TOOL CARD — Premium Interactive Design
// ═══════════════════════════════════════════════════════════════════════

class _AIToolCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final LinearGradient gradient;
  final String tag;
  final bool isDisabled;
  final VoidCallback onTap;

  const _AIToolCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.gradient,
    required this.tag,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(18.r),
        splashColor: gradient.colors.first.withValues(alpha: 0.12),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isDisabled ? 0.4 : 1.0,
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(
                color: isDisabled
                    ? AppColors.darkBorder
                    : gradient.colors.first.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Icon with gradient
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    gradient: isDisabled ? null : gradient,
                    color: isDisabled ? AppColors.darkBorder : null,
                    borderRadius: BorderRadius.circular(14.r),
                    boxShadow: isDisabled
                        ? null
                        : [
                            BoxShadow(
                              color: gradient.colors.first
                                  .withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: Icon(
                    icon,
                    color: isDisabled
                        ? AppColors.textOnDarkHint
                        : Colors.white,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 14.w),
                // Label & Description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                          color: isDisabled
                              ? AppColors.textOnDarkHint
                              : AppColors.textOnDark,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.textOnDarkSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                // Tag
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: isDisabled
                        ? AppColors.darkBorder.withValues(alpha: 0.5)
                        : gradient.colors.first.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: isDisabled
                          ? AppColors.textOnDarkHint
                          : gradient.colors.first,
                    ),
                  ),
                ),
                SizedBox(width: 4.w),
                Icon(
                  isDisabled ? Icons.lock_rounded : Icons.chevron_right,
                  color: isDisabled
                      ? AppColors.textOnDarkHint
                      : AppColors.textOnDarkSecondary,
                  size: 18.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// ADD KNOWLEDGE SHEET
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
        borderSide: const BorderSide(
          color: Color(0xFF8B5CF6),
          width: 2,
        ),
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

            // Content type
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

            // Title
            TextField(
              controller: _titleController,
              style: TextStyle(color: AppColors.textOnDark),
              decoration: _inputDecoration(
                'عنوان المحتوى',
                hint: 'مثال: كتاب الرياضيات — الباب الأول',
              ),
            ),
            SizedBox(height: 12.h),

            // Subject and Grade
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

            // Content
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
                border: Border.all(
                  color: Colors.amber.withValues(alpha: 0.2),
                ),
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

            // Buttons
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
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF6C3CE1)],
                      ),
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
                                backgroundColor: Colors.white,
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
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF6C3CE1)],
                )
              : null,
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
