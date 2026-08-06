import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/providers/center_provider.dart';
import '../../../../core/theming/app_spacing.dart';
import '../../../shared/data/supabase_repository.dart';
import '../../ai/provider/ai_provider.dart';
import '../../ai/screens/exam_preview_screen.dart';
import '../../ai/widgets/ai_exam_card.dart';
import '../../auth/provider/auth_provider.dart';
import '../../exam_generator/presentation/cubits/exam_generator/exam_generator_cubit.dart';
import '../../teacher/provider/teacher_provider.dart';
import '../domain/entities/chat_message.dart';
import '../presentation/cubits/ai_assistant/ai_assistant_cubit.dart';
import '../presentation/cubits/ai_assistant/ai_assistant_state.dart';
import '../presentation/widgets/ai_thinking_bubble.dart';
import '../presentation/widgets/ai_typewriter_text.dart';

class AIAssistantChatScreen extends StatefulWidget {
  final String? initialPrompt;

  const AIAssistantChatScreen({
    super.key,
    this.initialPrompt,
  });

  @override
  State<AIAssistantChatScreen> createState() => _AIAssistantChatScreenState();
}

class _AIAssistantChatScreenState extends State<AIAssistantChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _hasInputText = false;
  Map<String, dynamic> _curriculumContext = {};

  final List<String> _quickPrompts = [
    'أنشئ كويز سريع مكون من 5 أسئلة 📝',
    'ما هي أفضل طريقة لتوضيح مفهوم ميكانيكا الكم؟ 💡',
    'ساعدني في صياغة تقرير لمستوى المجموعات 📊',
    'اقترح أنشطة تفاعلية للحصة القادمة 🎯',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialPrompt != null) {
      _messageController.text = widget.initialPrompt!;
      _hasInputText = widget.initialPrompt!.trim().isNotEmpty;
    }
    _messageController.addListener(() {
      final hasText = _messageController.text.trim().isNotEmpty;
      if (hasText != _hasInputText) {
        setState(() => _hasInputText = hasText);
      }
    });
    
    // Fetch curriculum context in background
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCurriculumContext());
  }

  Future<void> _loadCurriculumContext() async {
    if (!mounted) return;
    try {
      final authProvider = context.read<AuthProvider>();
      final repo = context.read<SupabaseRepository>();
      final specializations = authProvider.teacherProfile?.specializations ?? [];
      
      if (specializations.isNotEmpty) {
        final subjectName = specializations.first;
        final payload = await repo.buildCurriculumContextPayload(subjectName);
        if (mounted) {
          setState(() => _curriculumContext = payload);
        }
      }
    } catch (e) {
      debugPrint('Error loading curriculum context: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendCustomMessage(String text, AIAssistantCubit cubit) {
    if (text.trim().isEmpty) return;

    final authProvider = context.read<AuthProvider>();
    final centerProvider = context.read<CenterProvider>();
    final teacherProvider = context.read<TeacherProvider>();
    final aiProvider = context.read<AIProvider>();

    _messageController.clear();

    final contextPayload = {
      'teacher_name': authProvider.teacherProfile?.fullName ?? '',
      'subject': authProvider.teacherProfile?.specializations?.join(', ') ?? '',
      'can_generate_exam': aiProvider.canGenerate(),
      'remaining_exam_quota': aiProvider.remainingToday,
      'groups': teacherProvider.groups
          .map((g) => {
                'id': g.id,
                'name': g.groupName,
                'level': g.gradeLevel,
              })
          .toList(),
      'curriculum_data': _curriculumContext,
      'curriculum_available': _curriculumContext['available_books'] != null &&
          (_curriculumContext['available_books'] as List).isNotEmpty,
    };

    cubit.sendMessage(
      text: text,
      teacherId: authProvider.currentUser?.id ?? '',
      centerId: centerProvider.currentCenterId ?? '',
      contextPayload: contextPayload,
    ).then((_) {
      if (mounted) {
        aiProvider.loadDailyUsage();
      }
    });

    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.I<AIAssistantCubit>(),
      child: Builder(builder: (context) {
        final cubit = context.read<AIAssistantCubit>();

        return Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: AppColors.darkBackground,
          appBar: AppBar(
            backgroundColor: AppColors.navyCard,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 36.r,
                      height: 36.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [AppColors.teal, AppColors.electric],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.teal.withValues(alpha: 0.4),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Icon(Icons.auto_awesome_rounded,
                          color: Colors.white, size: 18.sp),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 10.r,
                        height: 10.r,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.navyCard, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapW12,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المساعد الذكي للمعلم',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'مدعوم بواسطة Gemini 3.6 Flash ⚡',
                      style: TextStyle(
                        color: AppColors.teal,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: EdgeInsets.all(6.r),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(Icons.cleaning_services_rounded,
                      color: Colors.white70, size: 18.sp),
                ),
                tooltip: 'مسح المحادثة',
                onPressed: () => cubit.clearSession(),
              ),
              AppSpacing.gapW8,
            ],
          ),
          body: Column(
            children: [
              // Chat Message List
              Expanded(
                child: BlocConsumer<AIAssistantCubit, AIAssistantState>(
                  listener: (context, state) {
                    switch (state) {
                      case AIAssistantSuccess():
                        _scrollToBottom();
                      case AIAssistantFailure(:final message):
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(message),
                            backgroundColor: AppColors.danger,
                          ),
                        );
                      case _:
                        break;
                    }
                  },
                  builder: (context, state) {
                    final messages = switch (state) {
                      AIAssistantInitial() => <ChatMessage>[],
                      AIAssistantLoading(:final messages) => messages,
                      AIAssistantSuccess(:final messages) => messages,
                      AIAssistantFailure(:final messages) => messages,
                    };

                    final isLoading = state is AIAssistantLoading;
                    final totalItemCount = messages.length + (isLoading ? 1 : 0);

                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true, // Reverse list so bottom is index 0
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                      itemCount: totalItemCount,
                      itemBuilder: (context, index) {
                        if (isLoading && index == 0) {
                          return const AIThinkingBubble();
                        }

                        final messageIndex = isLoading ? index - 1 : index;
                        final msg = messages[messages.length - 1 - messageIndex];
                        final isLatestAssistantMsg = (!isLoading &&
                            messageIndex == 0 &&
                            msg.role == ChatMessageRole.assistant);

                        return _buildMessageBubble(
                          msg,
                          context,
                          cubit,
                          animate: isLatestAssistantMsg,
                        );
                      },
                    );
                  },
                ),
              ),

              // Quick Prompts Chips
              BlocBuilder<AIAssistantCubit, AIAssistantState>(
                builder: (context, state) {
                  return Container(
                    height: 42.h,
                    margin: EdgeInsets.only(bottom: 8.h),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      itemCount: _quickPrompts.length,
                      separatorBuilder: (_, __) => SizedBox(width: 8.w),
                      itemBuilder: (context, index) {
                        final prompt = _quickPrompts[index];
                        return InkWell(
                          onTap: () => _sendCustomMessage(prompt, cubit),
                          borderRadius: BorderRadius.circular(20.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 14.w, vertical: 8.h),
                            decoration: BoxDecoration(
                              color: AppColors.navyCard,
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(
                                color: AppColors.teal.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                prompt,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),

              // Input Dock
              _buildInputArea(context, cubit),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildMessageBubble(
    ChatMessage msg,
    BuildContext context,
    AIAssistantCubit cubit, {
    bool animate = false,
  }) {
    final isUser = msg.role == ChatMessageRole.user;

    if (msg.type == ChatMessageType.toolCall) {
      if (msg.toolName == 'generate_exam') {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: AIExamCard(
            args: msg.toolArgs ?? {},
            onAction: () async {
              cubit.handleToolResult(
                  msg.toolCallId ?? '', {'status': 'reviewing_exam'});
              if (context.mounted) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider<ExamGeneratorCubit>(
                      create: (_) => GetIt.I<ExamGeneratorCubit>(),
                      child: ExamPreviewScreen(examData: msg.toolArgs ?? {}),
                    ),
                  ),
                );
              }
            },
          ),
        );
      }
      return const SizedBox.shrink();
    }

    if (msg.type == ChatMessageType.toolResult) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        margin: EdgeInsets.symmetric(vertical: 6.h),
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          gradient: isUser
              ? const LinearGradient(
                  colors: [AppColors.electric, Color(0xFF0D9488)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isUser ? null : AppColors.navyCard,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18.r),
            topRight: Radius.circular(18.r),
            bottomRight: isUser ? Radius.zero : Radius.circular(18.r),
            bottomLeft: isUser ? Radius.circular(18.r) : Radius.zero,
          ),
          border: Border.all(
            color: isUser
                ? Colors.transparent
                : AppColors.teal.withValues(alpha: 0.25),
          ),
          boxShadow: [
            BoxShadow(
              color: isUser
                  ? AppColors.electric.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // AI Badge Header if Assistant
            if (!isUser) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.smart_toy_rounded,
                          color: AppColors.teal, size: 14.sp),
                      SizedBox(width: 4.w),
                      Text(
                        'المساعد الذكي',
                        style: TextStyle(
                          color: AppColors.teal,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.copy_rounded,
                        color: Colors.white54, size: 14.sp),
                    tooltip: 'نسخ النص',
                    onPressed: () {
                      Clipboard.setData(
                          ClipboardData(text: msg.content ?? ''));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم نسخ النص بنجاح ✨'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ),
              SizedBox(height: 6.h),
            ],

            // Message Content
            if (isUser)
              SelectableText(
                msg.content ?? '',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              )
            else
              AITypewriterText(
                text: msg.content ?? '',
                animate: animate,
                onTextUpdated: _scrollToBottom,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontSize: 14.sp,
                  height: 1.5,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(BuildContext context, AIAssistantCubit cubit) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.navyCard,
        border: Border(
          top: BorderSide(color: AppColors.teal.withValues(alpha: 0.15)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                style: TextStyle(color: Colors.white, fontSize: 14.sp),
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'اطلب أي شيء من المساعد الذكي...',
                  hintStyle:
                      TextStyle(color: Colors.white38, fontSize: 13.5.sp),
                  filled: true,
                  fillColor: AppColors.navyMid,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.r),
                    borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.r),
                    borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.r),
                    borderSide:
                        const BorderSide(color: AppColors.teal, width: 1.5),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                ),
                onSubmitted: (text) => _sendCustomMessage(text, cubit),
              ),
            ),
            SizedBox(width: 10.w),
            GestureDetector(
              onTap: () =>
                  _sendCustomMessage(_messageController.text, cubit),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  gradient: _hasInputText
                      ? const LinearGradient(
                          colors: [AppColors.teal, AppColors.electric],
                        )
                      : LinearGradient(
                          colors: [
                            AppColors.navyLight,
                            AppColors.navyLight.withValues(alpha: 0.7),
                          ],
                        ),
                  shape: BoxShape.circle,
                  boxShadow: _hasInputText
                      ? [
                          BoxShadow(
                            color: AppColors.teal.withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Transform.rotate(
                  angle: 3.14159, // Mirror send icon for RTL Arabic layout
                  child: Icon(
                    Icons.send_rounded,
                    color: _hasInputText ? Colors.white : Colors.white38,
                    size: 20.sp,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
