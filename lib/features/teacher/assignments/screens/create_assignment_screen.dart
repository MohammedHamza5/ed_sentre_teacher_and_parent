import 'dart:io';
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

/// شاشة إنشاء واجب/امتحان/كويز - تصميم مبسط وفعال
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
        return 'امتحان';
      case 'quiz':
        return 'كويز';
      default:
        return 'واجب';
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
          'إنشاء $_typeLabel',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
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
                    label: 'العنوان *',
                    hint: widget.type == 'exam'
                        ? 'مثال: امتحان نهاية الشهر'
                        : 'مثال: واجب الفصل الثاني',
                    icon: Icons.title,
                    validator: (v) =>
                        v?.isEmpty == true ? 'أدخل العنوان' : null,
                  ),
                  SizedBox(height: 16.h),

                  // Description (optional for assignment)
                  if (widget.type == 'assignment') ...[
                    AssignmentTextField(typeColor: _typeColor,
                      controller: _descriptionController,
                      label: 'التعليمات (اختياري)',
                      hint: 'أضف تعليمات للطلاب...',
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
                    label: 'الدرجة الكلية *',
                    hint: '100',
                    icon: Icons.grade,
                    keyboardType: TextInputType.number,
                    suffix: 'درجة',
                    validator: (v) =>
                        v?.isEmpty == true ? 'أدخل الدرجة' : null,
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
      _showError('اختر مجموعة واحدة على الأقل');
      return;
    }

    if (_dueDate == null) {
      _showError('اختر الموعد');
      return;
    }

    if (widget.type == 'exam' &&
        _attachmentName == null &&
        _questions.isEmpty) {
      _showError(
        'أضف أسئلة تفاعلية أو ارفع ملف الامتحان',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final centerProvider = context.read<CenterProvider>();
      final repository = context.read<SupabaseRepository>();
      final centerId = centerProvider.currentCenterId;

      if (centerId == null) throw Exception('السنتر غير محدد');

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
          'موعد الظهور يجب أن يسبق موعد التسليم',
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
            content: Text('تم نشر $_typeLabel بنجاح! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint("Error publishing: $e");
      if (mounted) {
        _showError('فشل النشر: $e');
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

  // -------------------------------------------------------------------------
  // QUIZ SCREEN (With Questions Step)
  // -------------------------------------------------------------------------

  Widget _buildQuizScreen() {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          _currentStep == 0
              ? 'إنشاء كويز - المعلومات'
              : 'إنشاء كويز - الأسئلة',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
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
            typeLabel: 'كويز',
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
            label: 'عنوان الكويز *',
            hint: 'مثال: كويز الوحدة الثانية',
            icon: Icons.title,
            validator: (v) =>
                v?.isEmpty == true ? 'أدخل العنوان' : null,
          ),
          SizedBox(height: 16.h),

          // Duration and Score Row
          Row(
            children: [
              Expanded(
                child: AssignmentTextField(typeColor: _typeColor,
                  controller: _durationController,
                  label: 'المدة *',
                  hint: '15',
                  icon: Icons.timer,
                  keyboardType: TextInputType.number,
                  suffix: 'دقيقة',
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: AssignmentTextField(typeColor: _typeColor,
                  controller: _maxScoreController,
                  label: 'الدرجة *',
                  hint: '20',
                  icon: Icons.grade,
                  keyboardType: TextInputType.number,
                  suffix: 'درجة',
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
      _showError('اختر مجموعة واحدة على الأقل');
      return;
    }
    if (_titleController.text.isEmpty) {
      _showError('أدخل عنوان الكويز');
      return;
    }
    setState(() => _currentStep = 1);
  }

  Future<void> _submitQuiz() async {
    if (_questions.isEmpty) {
      _showError('أضف سؤال واحد على الأقل');
      return;
    }
    if (_dueDate == null) {
      _showError('اختر الموعد');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final centerProvider = context.read<CenterProvider>();
      final repository = context.read<SupabaseRepository>();
      final centerId = centerProvider.currentCenterId;

      if (centerId == null) throw Exception('السنتر غير محدد');

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
          'موعد الظهور يجب أن يسبق موعد التسليم',
        );
        setState(() => _isLoading = false);
        return;
      }

      for (final group in _selectedGroups) {
        final data = {
          'title': _titleController.text,
          'description': 'كويز سريع - ${_questions.length} أسئلة',
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
            content: Text('تم نشر الكويز بنجاح! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint("Error publishing quiz: $e");
      if (mounted) {
        _showError('فشل النشر: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
