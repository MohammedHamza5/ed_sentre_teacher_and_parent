import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/center_provider.dart';
import '../../../auth/provider/auth_provider.dart';
import '../../../../shared/data/supabase_repository.dart';
import '../../../../shared/models/models.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/widgets/genius/genius_button.dart';

import 'create_assignment_screen.dart';
import 'submissions_screen.dart';

// Extracted Widgets
import '../widgets/teacher_assignments_header.dart';
import '../widgets/teacher_assignments_skeleton.dart';
import '../widgets/teacher_assignments_filter_panel.dart';
import '../widgets/teacher_assignment_card.dart';
import '../widgets/teacher_assignments_modals.dart';
import '../widgets/assignment_helper.dart';

class TeacherAssignmentsScreen extends StatefulWidget {
  const TeacherAssignmentsScreen({super.key});

  @override
  State<TeacherAssignmentsScreen> createState() =>
      _TeacherAssignmentsScreenState();
}

class _TeacherAssignmentsScreenState extends State<TeacherAssignmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String _selectedCourseId = 'all';
  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _assignments = [];
  Map<String, dynamic> _stats = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all';
  final int _pageSize = 20;
  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  List<GroupModel> _groups = [];
  bool _isLoadingGroups = true;

  String _sortOrder = 'newest';
  String _selectedGroupId = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData(reset: true);
    _loadGroups();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    setState(() => _isLoadingGroups = true);
    try {
      final auth = context.read<AuthProvider>();
      final centerProvider = context.read<CenterProvider>();
      final repository = context.read<SupabaseRepository>();
      final teacherId = auth.teacherProfile?.id;
      final centerId = centerProvider.currentCenterId;
      if (teacherId != null && centerId != null) {
        _groups = await repository.getTeacherGroups(teacherId, centerId);
      }
    } catch (e) {
      debugPrint('Error loading groups: $e');
    } finally {
      if (mounted) setState(() => _isLoadingGroups = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;
    setState(() => _isLoadingMore = true);
    await _loadData();
  }

  Future<void> _loadData({bool reset = false}) async {
    setState(() {
      if (reset) {
        _isLoading = true;
        _currentPage = 0;
        _hasMore = true;
        _assignments = [];
      }
      _error = null;
    });

    try {
      final repository = context.read<SupabaseRepository>();
      final centerProvider = context.read<CenterProvider>();
      final centerId = centerProvider.currentCenterId;

      if (centerId == null) {
        setState(() {
          _error = 'لم يتم تحديد السنتر';
          _isLoading = false;
        });
        return;
      }

      final assignments = await repository.getTeacherAssignments(
        centerId: centerId,
        courseId: _selectedCourseId == 'all' ? null : _selectedCourseId,
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );

      final stats = reset
          ? await repository.getTeacherAssignmentStats(centerId)
          : _stats;

      if (mounted) {
        setState(() {
          if (reset) {
            _assignments = assignments;
          } else {
            _assignments.addAll(assignments);
          }
          _stats = stats;
          _currentPage += 1;
          _hasMore = assignments.length == _pageSize;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e, stack) {
      debugPrint('Error loading assignments: $e\n$stack');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.forestDeep,
      body: DefaultTabController(
        length: 4,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 180.h,
                floating: false,
                pinned: true,
                backgroundColor: AppColors.forestPrimary,
                flexibleSpace: FlexibleSpaceBar(
                  background: TeacherAssignmentsHeader(stats: _stats),
                ),
                bottom: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.accentVivid,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withValues(alpha: 0.5),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                  tabs: const [
                    Tab(text: 'الكل'),
                    Tab(text: 'واجبات'),
                    Tab(text: 'امتحانات'),
                    Tab(text: 'مؤرشفة'),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: () => _loadData(reset: true),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 8.w),
                    child: const SizedBox.shrink(),
                  ),
                ],
              ),
            ];
          },
          body: _isLoading
              ? const TeacherAssignmentsSkeleton()
              : _error != null
                  ? _buildErrorWidget()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildAssignmentsList(null),
                        _buildAssignmentsList('assignment'),
                        _buildAssignmentsList('exam'),
                        _buildAssignmentsList(null, archivedOnly: true),
                      ],
                    ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => TeacherAssignmentsModals.showCreateOptions(
          context: context,
          onNavigateToCreate: _navigateToCreate,
        ),
        backgroundColor: AppColors.accentVivid,
        elevation: 0,
        icon: const Icon(Icons.add, color: AppColors.forestDeep),
        label: const Text(
          'إنشاء جديد',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.forestDeep,
          ),
        ),
      ).animate().scale(delay: 300.ms),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: AppColors.errorRed.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 40.sp,
              color: AppColors.errorRed,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            _error ?? 'حدث خطأ',
            style: TextStyle(
              color: AppColors.textDisplay.withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: 12.h),
          GeniusButton(
            label: 'إعادة المحاولة',
            icon: Icons.refresh,
            onPressed: _loadData,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.glassBorderHighlight),
            ),
            child: Icon(
              Icons.assignment_outlined,
              size: 52.sp,
              color: AppColors.textDisplay.withValues(alpha: 0.3),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'لا توجد بيانات',
            style: TextStyle(
              color: AppColors.textDisplay,
              fontWeight: FontWeight.bold,
              fontSize: 16.sp,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'اضغط على "إنشاء جديد" للبدء',
            style: TextStyle(
              color: AppColors.textDisplay.withValues(alpha: 0.3),
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildAssignmentsList(
    String? typeFilter, {
    bool archivedOnly = false,
  }) {
    final filtered = _assignments.where((a) {
      final archived = AssignmentHelper.isArchived(a);
      if (archivedOnly && !archived) return false;
      if (!archivedOnly && archived) return false;
      if (typeFilter == null) return true;
      if (typeFilter == 'exam') {
        return a['type'] == 'exam' || a['type'] == 'quiz';
      }
      return a['type'] == typeFilter;
    }).toList();

    // NOTE: Search filter only — sorting is handled in filteredFinal below
    final filteredWithSearch = filtered.where((a) {
      if (_searchQuery.isEmpty) return true;
      final title = (a['title'] ?? '').toString().toLowerCase();
      final course = (a['course_name'] ?? '').toString().toLowerCase();
      return title.contains(_searchQuery) || course.contains(_searchQuery);
    }).toList();

    final filteredFinal = filteredWithSearch.where((a) {
      if (_statusFilter == 'all') return true;
      final dueDate = DateTime.tryParse(a['due_date'] ?? '');
      final ended = dueDate != null && DateTime.now().isAfter(dueDate);
      if (_statusFilter == 'active') return !ended;
      if (_statusFilter == 'ended') return ended;
      return true;
    }).where((a) {
      if (_selectedGroupId == 'all') return true;
      return a['course_id'] == _selectedGroupId ||
             a['group_id'] == _selectedGroupId;
    }).toList()..sort((a, b) {
        final aDue = DateTime.tryParse(a['due_date'] ?? '');
        final bDue = DateTime.tryParse(b['due_date'] ?? '');
        if (aDue != null && bDue != null) {
          return _sortOrder == 'newest'
              ? bDue.compareTo(aDue)
              : aDue.compareTo(bDue);
        }
        return 0; // fallback if no dates
      });

    if (filteredFinal.isEmpty) return _buildEmptyState();

    if (filteredFinal.length < 6 &&
        _hasMore &&
        !_isLoadingMore &&
        !_isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadMore());
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 200) {
          _loadMore();
        }
        return false;
      },
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: filteredFinal.length + 2 + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == 0) {
            return TeacherAssignmentsFilterPanel(
              stats: _stats,
              searchController: _searchController,
              searchQuery: _searchQuery,
              statusFilter: _statusFilter,
              groups: _groups,
              selectedGroupId: _selectedGroupId,
              sortOrder: _sortOrder,
              onSearchChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              onSearchCleared: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              onStatusChanged: (v) => setState(() => _statusFilter = v),
              onGroupChanged: (v) => setState(() => _selectedGroupId = v),
              onSortToggle: () {
                setState(() => _sortOrder = _sortOrder == 'newest' ? 'oldest' : 'newest');
              },
            );
          }

          if (_isLoadingMore && index == filteredFinal.length + 1) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: Center(
                child: CircularProgressIndicator(
                  backgroundColor: AppColors.accentVivid,
                ),
              ),
            );
          }
          if (index == filteredFinal.length + 1 + (_isLoadingMore ? 1 : 0)) {
            return SizedBox(height: 60.h);
          }
          final itemIndex = index - 1;
          final assignment = filteredFinal[itemIndex];
          return Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: TeacherAssignmentCard(
              assignment: assignment,
              onViewSubmissions: () => _viewSubmissions(assignment),
              onOpenDetails: () {
                TeacherAssignmentsModals.showMoreOptions(
                  context: context,
                  assignment: assignment,
                  onOpenAddToGroups: () => _openAddToGroups(assignment),
                  onEditPublishAt: () => _editPublishAt(assignment),
                  onToggleArchive: (archived) => _toggleArchive(assignment, archived),
                  onDeleteAssignment: () => _deleteAssignment(assignment),
                );
              },
              onShowMoreOptions: () {
                TeacherAssignmentsModals.showMoreOptions(
                  context: context,
                  assignment: assignment,
                  onOpenAddToGroups: () => _openAddToGroups(assignment),
                  onEditPublishAt: () => _editPublishAt(assignment),
                  onToggleArchive: (archived) => _toggleArchive(assignment, archived),
                  onDeleteAssignment: () => _deleteAssignment(assignment),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _navigateToCreate(String type) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateAssignmentScreen(type: type)),
    );

    if (result == true) _loadData();
  }

  void _viewSubmissions(Map<String, dynamic> assignment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubmissionsScreen(assignment: assignment),
      ),
    ).then((_) => _loadData(reset: true));
  }

  Future<void> _toggleArchive(
    Map<String, dynamic> assignment,
    bool archived,
  ) async {
    try {
      final repository = context.read<SupabaseRepository>();
      final settings = AssignmentHelper.extractSettingsMap(assignment);
      settings['archived'] = archived;
      await repository.updateAssignment(assignment['id'], {
        'settings': AssignmentHelper.buildSettingsPayload(assignment, settings),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              archived
                  ? 'تمت الأرشفة ويمكنك إيجادها في تبويب مؤرشفة'
                  : 'تم إلغاء الأرشفة',
            ),
          ),
        );
        _loadData(reset: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل التحديث: $e')));
      }
    }
  }

  Future<void> _editPublishAt(Map<String, dynamic> assignment) async {
    final currentPublish = AssignmentHelper.getPublishDate(assignment) ?? DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: currentPublish,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate == null || !mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: currentPublish.hour,
        minute: currentPublish.minute,
      ),
    );
    if (pickedTime == null || !mounted) return;

    final publishDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    final dueDate = DateTime.tryParse(assignment['due_date'] ?? '');
    if (dueDate != null && publishDateTime.isAfter(dueDate)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('موعد الظهور يجب أن يسبق موعد التسليم')),
        );
      }
      return;
    }

    try {
      final repository = context.read<SupabaseRepository>();
      final settings = AssignmentHelper.extractSettingsMap(assignment);
      settings['publish_at'] = publishDateTime.toIso8601String();
      await repository.updateAssignment(assignment['id'], {
        'settings': AssignmentHelper.buildSettingsPayload(assignment, settings),
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم تحديث موعد الظهور')));
        _loadData(reset: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل التحديث: $e')));
      }
    }
  }

  Future<void> _openAddToGroups(Map<String, dynamic> assignment) async {
    final selectedIds = await TeacherAssignmentsModals.openAddToGroups(
      context: context,
      currentGroupId: assignment['group_id'] as String?,
      groups: _groups,
      isLoadingGroups: _isLoadingGroups,
    );
    
    if (selectedIds != null && selectedIds.isNotEmpty) {
      await _duplicateAssignmentToGroups(assignment, selectedIds);
    }
  }

  Future<void> _duplicateAssignmentToGroups(
    Map<String, dynamic> assignment,
    Set<String> groupIds,
  ) async {
    try {
      final repository = context.read<SupabaseRepository>();
      final centerProvider = context.read<CenterProvider>();
      final centerId = assignment['center_id'] as String? ?? centerProvider.currentCenterId;
      if (centerId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('لم يتم تحديد السنتر')));
        return;
      }

      final settings = AssignmentHelper.extractSettingsMap(assignment);
      settings.putIfAbsent(
        'publish_at',
        () => DateTime.now().toIso8601String(),
      );

      for (final groupId in groupIds) {
        final group = _groups.firstWhere((g) => g.id == groupId);
        final data = {
          'title': assignment['title'],
          'description': assignment['description'],
          'center_id': centerId,
          'group_id': groupId,
          'course_id': group.courseId,
          'type': assignment['type'],
          'max_score': assignment['max_score'],
          'due_date': assignment['due_date'],
          'file_url': assignment['file_url'],
          'file_type': assignment['file_type'],
          'file_size': assignment['file_size'],
          'questions': assignment['questions'],
          'settings': settings,
        };
        await repository.addAssignment(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت الإضافة للمجموعات بنجاح')),
        );
        _loadData(reset: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل الإضافة: $e')));
      }
    }
  }

  Future<void> _deleteAssignment(Map<String, dynamic> assignment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: Text(
          'حذف الواجب',
          style: TextStyle(color: AppColors.textDisplay),
        ),
        content: Text(
          'هل أنت متأكد من حذف "${assignment['title']}"؟',
          style: TextStyle(color: AppColors.textDisplay.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'إلغاء',
              style: TextStyle(
                color: AppColors.textDisplay.withValues(alpha: 0.7),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      try {
        final repository = context.read<SupabaseRepository>();
        final assignmentId = assignment['id']?.toString();
        if (assignmentId == null || assignmentId.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تعذر تحديد العنصر للحذف')),
          );
          return;
        }
        await repository.deleteAssignment(assignmentId);
        if (mounted) {
          setState(() {
            _assignments.removeWhere(
              (item) => item['id']?.toString() == assignmentId,
            );
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حذف الواجب'),
              backgroundColor: Colors.green,
            ),
          );
          _loadData(reset: true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('فشل الحذف: $e')));
        }
      }
    }
  }
}
