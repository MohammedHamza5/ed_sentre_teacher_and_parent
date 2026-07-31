import 'dart:io';
import 'package:ed_sentre_techer_and_parent/core/config/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/providers/center_provider.dart';
import '../../../auth/provider/auth_provider.dart';
import '../../../../shared/data/supabase_repository.dart';
import '../../../../shared/models/models.dart';
import '../../provider/teacher_provider.dart';
import '../widgets/assignment_date_selector.dart';
import '../widgets/assignment_duration_selector.dart';
import '../widgets/assignment_file_attachment.dart';
import '../widgets/assignment_group_selector.dart';
import '../widgets/assignment_publish_selector.dart';
import '../widgets/assignment_type_header.dart';
import '../widgets/assignment_archive_selector.dart';
import '../widgets/assignment_no_groups_state.dart';
import '../widgets/assignment_submit_button.dart';
import '../widgets/assignment_text_field.dart';
import '../widgets/quiz_bottom_nav.dart';
import '../widgets/quiz_questions_editor.dart';
import '../../../../core/widgets/genius/shimmer_skeleton.dart';

/// Ø´Ø§Ø´Ø© Ø¥Ù†Ø´Ø§Ø¡ ÙˆØ§Ø¬Ø¨/Ø§Ù…ØªØ­Ø§Ù†/ÙƒÙˆÙŠØ² - ØªØµÙ…ÙŠÙ… Ù…Ø¨Ø³Ù‘Ø· ÙˆÙ Ø¹Ø§Ù„
class CreateAssignmentScreen extends StatefulWidget {
  final String type; // 'assignment', 'exam', 'quiz'
  final String? initialTitle;
  final List<Map<String, dynamic>>? initialQuestions;
  final int? initialDuration;
  final int? initialMaxScore;

  const CreateAssignmentScreen({
    super.key,
    required this.type,
    this.initialTitle,
    this.initialQuestions,
    this.initialDuration,
    this.initialMaxScore,
  });

  @override
  State<CreateAssignmentScreen> createState() => _CreateAssignmentScreenState();
}

class _CreateAssignmentScreenState extends State<CreateAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _maxScoreController = TextEditingController(text: '100');
  final _durationController = TextEditingController(text: '60');

  bool _isLoading = false;
  bool _isLoadingGroups = true;

  List<GroupModel> _groups = [];
  List<GroupModel> _selectedGroups = [];

  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  DateTime? _publishDate;
  TimeOfDay? _publishTime;
  bool _startArchived = false;

  // File attachment
  String? _attachmentName;
  String? _attachmentPath;

  // Quiz questions (only for quiz type)
  int _currentStep = 0; // 0 = info, 1 = questions
  final List<Map<String, dynamic>> _questions = [];

  @override
  void initState() {
    super.initState();
    _loadGroups();

    // Pre-fill data if provided (e.g. from AI)
    if (widget.initialTitle != null) {
      _titleController.text = widget.initialTitle!;
    }
    if (widget.initialQuestions != null) {
      _questions.addAll(widget.initialQuestions!);
      // If quiz, set step to 1 (Questions) if needed? No, let user review info first.
    }
    if (widget.initialDuration != null) {
      _durationController.text = widget.initialDuration.toString();
    }
    if (widget.initialMaxScore != null) {
      _maxScoreController.text = widget.initialMaxScore.toString();
    }

    // Smart defaults
    if (widget.type == 'quiz') {
      _durationController.text = '15';
      _maxScoreController.text = '20';
    } else if (widget.type == 'exam') {
      _durationController.text = '60';
    }
    final now = DateTime.now();
    _publishDate = DateTime(now.year, now.month, now.day);
    _publishTime = TimeOfDay.fromDateTime(now);
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() => _isLoadingGroups = true);
    try {
      final auth = context.read<AuthProvider>();
      final center = context.read<CenterProvider>();

      final teacherId = auth.teacherProfile?.id;
      final centerId = center.currentCenterId;
      final teacherProvider = context.read<TeacherProvider>();

      if (teacherId != null && centerId != null) {
        _groups = List<GroupModel>.from(teacherProvider.groups);
        if (_groups.isNotEmpty) {
          _selectedGroups = [_groups.first];
        }
      }
    } catch (e) {
      debugPrint('âŒ Error loading groups: $e');
    } finally {
      if (mounted) setState(() => _isLoadingGroups = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _maxScoreController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  String get _typeLabel {
    switch (widget.type) {
      case 'exam':
        return 'Ø§Ù…ØªØ­Ø§Ù†';
      case 'quiz':
        return 'ÙƒÙˆÙŠØ²';
      default:
        return 'ÙˆØ§Ø¬Ø¨';
    }
  }

  Color get _typeColor {
    switch (widget.type) {
      case 'exam':
        return Colors.orange;
      case 'quiz':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  IconData get _typeIcon {
    switch (widget.type) {
      case 'exam':
        return Icons.quiz;
      case 'quiz':
        return Icons.bolt;
      default:
        return Icons.assignment;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Quiz uses stepper, others use single form
    if (widget.type == 'quiz') {
      return _buildQuizScreen();
    } else {
      return _buildSimpleScreen();
    }
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // SIMPLE SCREEN (Assignment & Exam)
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  Widget _buildSimpleScreen() {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          'Ø¥Ù†Ø´Ø§Ø¡ $_typeLabel',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDisplay),
      ),
      body: _isLoadingGroups
          ? Padding(
              padding: EdgeInsets.all(16.w),
              child: const CardShimmerSkeleton(itemCount: 3),
            )
          : _groups.isEmpty
          ? const AssignmentNoGroupsState()
          : Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.all(16.w),
                children: [
                  // Type Header
                  AssignmentTypeHeader(
                    typeLabel: _typeLabel,
                    type: widget.type,
                    typeColor: _typeColor,
                    typeIcon: _typeIcon,
                  ),
                  SizedBox(height: 20.h),

                  // Group Selection
                  AssignmentGroupSelector(
                    groups: _groups,
                    selectedGroups: _selectedGroups,
                    typeColor: _typeColor,
                    onGroupsSelected: (groups) {
                      setState(() => _selectedGroups = groups);
                    },
                  ),
                  SizedBox(height: 16.h),

                  // Title
                  AssignmentTextField(typeColor: _typeColor,
                    controller: _titleController,
                    label: 'Ø§Ù„Ø¹Ù†ÙˆØ§Ù† *',
                    hint: widget.type == 'exam'
                        ? 'Ù…Ø«Ø§Ù„: Ø§Ù…ØªØ­Ø§Ù† Ù†Ù‡Ø§ÙŠØ© Ø§Ù„Ø´Ù‡Ø±'
                        : 'Ù…Ø«Ø§Ù„: ÙˆØ§Ø¬Ø¨ Ø§Ù„ÙØµÙ„ Ø§Ù„Ø«Ø§Ù†ÙŠ',
                    icon: Icons.title,
                    validator: (v) =>
                        v?.isEmpty == true ? 'Ø£Ø¯Ø®Ù„ Ø§Ù„Ø¹Ù†ÙˆØ§Ù†' : null,
                  ),
                  SizedBox(height: 16.h),

                  // Description (optional for assignment)
                  if (widget.type == 'assignment') ...[
                    AssignmentTextField(typeColor: _typeColor,
                      controller: _descriptionController,
                      label: 'Ø§Ù„ØªØ¹Ù„ÙŠÙ…Ø§Øª (Ø§Ø®ØªÙŠØ§Ø±ÙŠ)',
                      hint: 'Ø£Ø¶Ù ØªØ¹Ù„ÙŠÙ…Ø§Øª Ù„Ù„Ø·Ù„Ø§Ø¨...',
                      icon: Icons.description,
                      maxLines: 3,
                    ),
                    SizedBox(height: 16.h),
                  ],

                  // File Attachment
                  AssignmentFileAttachment(
                    type: widget.type,
                    typeColor: _typeColor,
                    attachmentName: _attachmentName,
                    onPickFile: () async {
                      final result = await AssignmentFileAttachment.pickFile(
                        context,
                      );
                      if (result != null) {
                        setState(() {
                          _attachmentName = result.name;
                          _attachmentPath = result.path;
                        });
                      }
                    },
                    onRemoveFile: () => setState(() {
                      _attachmentName = null;
                      _attachmentPath = null;
                    }),
                  ),
                  SizedBox(height: 16.h),

                  AssignmentPublishSelector(
                    typeColor: _typeColor,
                    publishDate: _publishDate,
                    publishTime: _publishTime,
                    onPublishDateChanged: (d) =>
                        setState(() => _publishDate = d),
                    onPublishTimeChanged: (t) =>
                        setState(() => _publishTime = t),
                  ),
                  SizedBox(height: 16.h),
                  AssignmentArchiveSelector(
                    startArchived: _startArchived,
                    typeColor: _typeColor,
                    onChanged: (v) => setState(() => _startArchived = v),
                  ),
                  SizedBox(height: 16.h),

                  // Due Date
                  AssignmentDateSelector(
                    type: widget.type,
                    typeColor: _typeColor,
                    dueDate: _dueDate,
                    dueTime: _dueTime,
                    onDueDateChanged: (d) => setState(() => _dueDate = d),
                    onDueTimeChanged: (t) => setState(() => _dueTime = t),
                  ),
                  SizedBox(height: 16.h),

                  // Duration (for exam only)
                  if (widget.type == 'exam') ...[
                    AssignmentDurationSelector(
                      typeColor: _typeColor,
                      durationController: _durationController,
                    ),
                    SizedBox(height: 16.h),
                  ],

                  // Score
                  AssignmentTextField(typeColor: _typeColor,
                    controller: _maxScoreController,
                    label: 'Ø§Ù„Ø¯Ø±Ø¬Ø© Ø§Ù„ÙƒÙ„ÙŠØ© *',
                    hint: '100',
                    icon: Icons.grade,
                    keyboardType: TextInputType.number,
                    suffix: 'Ø¯Ø±Ø¬Ø©',
                    validator: (v) =>
                        v?.isEmpty == true ? 'Ø£Ø¯Ø®Ù„ Ø§Ù„Ø¯Ø±Ø¬Ø©' : null,
                  ),
                  SizedBox(height: 32.h),

                  // Submit Button
                  AssignmentSubmitButton(
                    isLoading: _isLoading,
                    typeColor: _typeColor,
                    typeLabel: _typeLabel,
                    onSubmit: _submit,
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedGroups.isEmpty) {
      _showError('Ø§Ø®ØªØ± Ù…Ø¬Ù…ÙˆØ¹Ø© ÙˆØ§Ø­Ø¯Ø© Ø¹Ù„Ù‰ Ø§Ù„Ø£Ù‚Ù„');
      return;
    }

    if (_dueDate == null) {
      _showError('Ø§Ø®ØªØ± Ø§Ù„Ù…ÙˆØ¹Ø¯');
      return;
    }

    if (widget.type == 'exam' &&
        _attachmentName == null &&
        _questions.isEmpty) {
      _showError(
        'Ø£Ø¶Ù Ø£Ø³Ø¦Ù„Ø© ØªÙØ§Ø¹Ù„ÙŠØ© Ø£Ùˆ Ø§Ø±ÙØ¹ Ù…Ù„Ù Ø§Ù„Ø§Ù…ØªØ­Ø§Ù†',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final centerProvider = context.read<CenterProvider>();
      final repository = context.read<SupabaseRepository>();
      final centerId = centerProvider.currentCenterId;

      if (centerId == null) throw Exception('Ø§Ù„Ø³Ù†ØªØ± ØºÙŠØ± Ù…Ø­Ø¯Ø¯');

      final dueDateTime = _dueDate!.add(
        Duration(hours: _dueTime?.hour ?? 23, minutes: _dueTime?.minute ?? 59),
      );
      final publishBase = _publishDate ?? DateTime.now();
      final publishDateTime = DateTime(
        publishBase.year,
        publishBase.month,
        publishBase.day,
        _publishTime?.hour ?? TimeOfDay.now().hour,
        _publishTime?.minute ?? TimeOfDay.now().minute,
      );
      if (publishDateTime.isAfter(dueDateTime)) {
        _showError(
          'Ù…ÙˆØ¹Ø¯ Ø§Ù„Ø¸Ù‡ÙˆØ± ÙŠØ¬Ø¨ Ø£Ù† ÙŠØ³Ø¨Ù‚ Ù…ÙˆØ¹Ø¯ Ø§Ù„ØªØ³Ù„ÙŠÙ…',
        );
        setState(() => _isLoading = false);
        return;
      }
      // Upload file to Supabase Storage if exists
      String? fileUrl;
      String? fileType;
      int? fileSize;

      if (_attachmentPath != null && _attachmentPath!.isNotEmpty) {
        final file = File(_attachmentPath!);
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_$_attachmentName';
        final storagePath = '$centerId/$fileName';

        // Upload to Storage
        await Supabase.instance.client.storage
            .from('assignments')
            .upload(storagePath, file);

        // Get public URL
        fileUrl = Supabase.instance.client.storage
            .from('assignments')
            .getPublicUrl(storagePath);

        fileType = _attachmentName?.split('.').last;
        fileSize = await file.length();
      }

      for (final group in _selectedGroups) {
        final data = {
          'title': _titleController.text,
          'description': _descriptionController.text,
          'center_id': centerId,
          'group_id': group.id,
          'course_id': group.courseId,
          'type': widget.type,
          'max_score': int.tryParse(_maxScoreController.text) ?? 100,
          'due_date': dueDateTime.toIso8601String(),
          'file_url': fileUrl,
          'file_type': fileType,
          'file_size': fileSize,
          'settings': {
            'duration_minutes': widget.type == 'exam' || widget.type == 'quiz'
                ? int.tryParse(_durationController.text)
                : null,
            'publish_at': publishDateTime.toIso8601String(),
            'archived': _startArchived,
            'display_mode': widget.type == 'exam' ? 'all' : 'single',
          },
          'time_limit_minutes': widget.type == 'exam' || widget.type == 'quiz'
              ? int.tryParse(_durationController.text)
              : null,
          'questions': _questions.asMap().entries.map((entry) {
            final i = entry.key;
            final q = entry.value;
            return {
              'id': '${DateTime.now().millisecondsSinceEpoch}_$i',
              'text': q['question'],
              'options': q['options'] ?? [],
              'correct_option_index': q['correct'] ?? 0,
              'correct_answer': q['correct_answer'],
              'points': q['marks'],
              'type': q['type'] ?? 'mcq',
              'difficulty': q['difficulty'],
            };
          }).toList(),
        };
        await repository.addAssignment(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ØªÙ… Ù†Ø´Ø± $_typeLabel Ø¨Ù†Ø¬Ø§Ø­! ðŸŽ‰'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint("Error publishing: $e");
      if (mounted) {
        _showError('ÙØ´Ù„ Ø§Ù„Ù†Ø´Ø±: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Theme.of(context).colorScheme.error),
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // QUIZ SCREEN (With Questions Step)
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  Widget _buildQuizScreen() {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          _currentStep == 0
              ? 'Ø¥Ù†Ø´Ø§Ø¡ ÙƒÙˆÙŠØ² - Ø§Ù„Ù…Ø¹Ù„ÙˆÙ…Ø§Øª'
              : 'Ø¥Ù†Ø´Ø§Ø¡ ÙƒÙˆÙŠØ² - Ø§Ù„Ø£Ø³Ø¦Ù„Ø©',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDisplay),
      ),
      body: _isLoadingGroups
          ? Padding(
              padding: EdgeInsets.all(16.w),
              child: const CardShimmerSkeleton(itemCount: 3),
            )
          : _groups.isEmpty
          ? const AssignmentNoGroupsState()
          : _currentStep == 0
          ? _buildQuizInfoStep()
          : ListView(
              padding: EdgeInsets.all(16.w),
              children: [
                QuizQuestionsEditor(
                  questions: _questions,
                  onQuestionsChanged: (q) => setState(() {
                    _questions.clear();
                    _questions.addAll(q);
                  }),
                  typeColor: _typeColor,
                  maxScoreStr: _maxScoreController.text,
                ),
              ],
            ),
      bottomNavigationBar: QuizBottomNav(
        currentStep: _currentStep,
        isLoading: _isLoading,
        typeColor: _typeColor,
        onBack: () => setState(() => _currentStep = 0),
        onNext: _goToQuestions,
        onSubmit: _submitQuiz,
      ),
    );
  }

  Widget _buildQuizInfoStep() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          // Type Header
          AssignmentTypeHeader(
            typeLabel: 'ÙƒÙˆÙŠØ²',
            type: 'quiz',
            typeColor: _typeColor,
            typeIcon: Icons.bolt,
          ),
          SizedBox(height: 20.h),

          AssignmentGroupSelector(
            groups: _groups,
            selectedGroups: _selectedGroups,
            typeColor: _typeColor,
            onGroupsSelected: (groups) {
              setState(() => _selectedGroups = groups);
            },
          ),
          SizedBox(height: 16.h),

          AssignmentTextField(typeColor: _typeColor,
            controller: _titleController,
            label: 'Ø¹Ù†ÙˆØ§Ù† Ø§Ù„ÙƒÙˆÙŠØ² *',
            hint: 'Ù…Ø«Ø§Ù„: ÙƒÙˆÙŠØ² Ø§Ù„ÙˆØ­Ø¯Ø© Ø§Ù„Ø«Ø§Ù†ÙŠØ©',
            icon: Icons.title,
            validator: (v) =>
                v?.isEmpty == true ? 'Ø£Ø¯Ø®Ù„ Ø§Ù„Ø¹Ù†ÙˆØ§Ù†' : null,
          ),
          SizedBox(height: 16.h),

          // Duration and Score Row
          Row(
            children: [
              Expanded(
                child: AssignmentTextField(typeColor: _typeColor,
                  controller: _durationController,
                  label: 'Ø§Ù„Ù…Ø¯Ø© *',
                  hint: '15',
                  icon: Icons.timer,
                  keyboardType: TextInputType.number,
                  suffix: 'Ø¯Ù‚ÙŠÙ‚Ø©',
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: AssignmentTextField(typeColor: _typeColor,
                  controller: _maxScoreController,
                  label: 'Ø§Ù„Ø¯Ø±Ø¬Ø© *',
                  hint: '20',
                  icon: Icons.grade,
                  keyboardType: TextInputType.number,
                  suffix: 'Ø¯Ø±Ø¬Ø©',
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          AssignmentPublishSelector(
            typeColor: _typeColor,
            publishDate: _publishDate,
            publishTime: _publishTime,
            onPublishDateChanged: (d) => setState(() => _publishDate = d),
            onPublishTimeChanged: (t) => setState(() => _publishTime = t),
          ),
          SizedBox(height: 16.h),
          AssignmentArchiveSelector(
                    startArchived: _startArchived,
                    typeColor: _typeColor,
                    onChanged: (v) => setState(() => _startArchived = v),
                  ),
          SizedBox(height: 16.h),
          AssignmentDateSelector(
            type: 'quiz',
            typeColor: _typeColor,
            dueDate: _dueDate,
            dueTime: _dueTime,
            onDueDateChanged: (d) => setState(() => _dueDate = d),
            onDueTimeChanged: (t) => setState(() => _dueTime = t),
          ),
        ],
      ),
    );
  }
  void _goToQuestions() {
    if (_selectedGroups.isEmpty) {
      _showError('Ø§Ø®ØªØ± Ù…Ø¬Ù…ÙˆØ¹Ø© ÙˆØ§Ø­Ø¯Ø© Ø¹Ù„Ù‰ Ø§Ù„Ø£Ù‚Ù„');
      return;
    }
    if (_titleController.text.isEmpty) {
      _showError('Ø£Ø¯Ø®Ù„ Ø¹Ù†ÙˆØ§Ù† Ø§Ù„ÙƒÙˆÙŠØ²');
      return;
    }
    setState(() => _currentStep = 1);
  }

  Future<void> _submitQuiz() async {
    if (_questions.isEmpty) {
      _showError('Ø£Ø¶Ù Ø³Ø¤Ø§Ù„ ÙˆØ§Ø­Ø¯ Ø¹Ù„Ù‰ Ø§Ù„Ø£Ù‚Ù„');
      return;
    }
    if (_dueDate == null) {
      _showError('Ø§Ø®ØªØ± Ø§Ù„Ù…ÙˆØ¹Ø¯');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final centerProvider = context.read<CenterProvider>();
      final repository = context.read<SupabaseRepository>();
      final centerId = centerProvider.currentCenterId;

      if (centerId == null) throw Exception('Ø§Ù„Ø³Ù†ØªØ± ØºÙŠØ± Ù…Ø­Ø¯Ø¯');

      final dueDateTime = _dueDate!.add(
        Duration(hours: _dueTime?.hour ?? 23, minutes: _dueTime?.minute ?? 59),
      );
      final publishBase = _publishDate ?? DateTime.now();
      final publishDateTime = DateTime(
        publishBase.year,
        publishBase.month,
        publishBase.day,
        _publishTime?.hour ?? TimeOfDay.now().hour,
        _publishTime?.minute ?? TimeOfDay.now().minute,
      );
      if (publishDateTime.isAfter(dueDateTime)) {
        _showError(
          'Ù…ÙˆØ¹Ø¯ Ø§Ù„Ø¸Ù‡ÙˆØ± ÙŠØ¬Ø¨ Ø£Ù† ÙŠØ³Ø¨Ù‚ Ù…ÙˆØ¹Ø¯ Ø§Ù„ØªØ³Ù„ÙŠÙ…',
        );
        setState(() => _isLoading = false);
        return;
      }

      for (final group in _selectedGroups) {
        final data = {
          'title': _titleController.text,
          'description': 'ÙƒÙˆÙŠØ² Ø³Ø±ÙŠØ¹ - ${_questions.length} Ø£Ø³Ø¦Ù„Ø©',
          'center_id': centerId,
          'group_id': group.id,
          'course_id': group.courseId,
          'type': 'quiz',
          'max_score': int.tryParse(_maxScoreController.text) ?? 20,
          'due_date': dueDateTime.toIso8601String(),
          'questions': _questions,
          'settings': {
            'duration_minutes': int.tryParse(_durationController.text) ?? 15,
            'auto_grade': true,
            'publish_at': publishDateTime.toIso8601String(),
            'archived': _startArchived,
          },
        };
        await repository.addAssignment(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ØªÙ… Ù†Ø´Ø± Ø§Ù„ÙƒÙˆÙŠØ² Ø¨Ù†Ø¬Ø§Ø­! ðŸŽ‰'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint("Error publishing quiz: $e");
      if (mounted) {
        _showError('ÙØ´Ù„ Ø§Ù„Ù†Ø´Ø±: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
