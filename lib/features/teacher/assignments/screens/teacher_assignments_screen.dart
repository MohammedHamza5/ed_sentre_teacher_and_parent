import 'package:ed_sentre_techer_and_parent/core/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../../shared/data/supabase_repository.dart';
import '../../../../shared/models/models.dart';
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

class _TabData {
  List<Map<String, dynamic>> items = [];
  bool isLoading = true;
  bool isFetchingMore = false;
  bool hasMore = true;
  int offset = 0;
  String? error;
  final ScrollController scrollController = ScrollController();
}

class _TeacherAssignmentsScreenState extends State<TeacherAssignmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String _selectedCourseId = 'all';
  String? _error;

  Map<String, dynamic> _stats = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all';
  final int _pageSize = 20;
  List<GroupModel> _groups = [];
  bool _isLoadingGroups = true;

  String _sortOrder = 'newest';
  String _selectedGroupId = 'all';

  late final _TabData _allData = _TabData();
  late final _TabData _assignmentsData = _TabData();
  late final _TabData _examsData = _TabData();
  late final _TabData _archivedData = _TabData();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    _setupScrollController(_allData, null, false);
    _setupScrollController(_assignmentsData, 'assignment', false);
    _setupScrollController(_examsData, 'exam', false);
    _setupScrollController(_archivedData, null, true);

    _triggerRefresh();
    _loadGroups();
  }

  void _setupScrollController(
    _TabData data,
    String? typeFilter,
    bool archivedOnly,
  ) {
    data.scrollController.addListener(() {
      if (data.scrollController.position.pixels >=
          data.scrollController.position.maxScrollExtent - 200) {
        if (!data.isLoading && !data.isFetchingMore && data.hasMore) {
          _fetchPage(data, typeFilter, archivedOnly, fetchMore: true);
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _allData.scrollController.dispose();
    _assignmentsData.scrollController.dispose();
    _examsData.scrollController.dispose();
    _archivedData.scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    setState(() => _isLoadingGroups = true);
    try {
      final teacherProvider = context.read<TeacherProvider>();
      _groups = teacherProvider.groups;
    } catch (e) {
      debugPrint('Error loading groups: $e');
    } finally {
      if (mounted) setState(() => _isLoadingGroups = false);
    }
  }

  Future<void> _loadStats() async {
    try {
      final repository = context.read<SupabaseRepository>();
      final centerId = context.read<CenterProvider>().currentCenterId;
      if (centerId != null) {
        final stats = await repository.getTeacherAssignmentStats(centerId);
        if (mounted) setState(() => _stats = stats);
      }
    } catch (_) {}
  }

  void _triggerRefresh() {
    _loadStats();
    _resetData(_allData);
    _resetData(_assignmentsData);
    _resetData(_examsData);
    _resetData(_archivedData);

    _fetchPage(_allData, null, false);
    _fetchPage(_assignmentsData, 'assignment', false);
    _fetchPage(_examsData, 'exam', false);
    _fetchPage(_archivedData, null, true);
  }

  void _resetData(_TabData data) {
    data.items.clear();
    data.isLoading = true;
    data.isFetchingMore = false;
    data.hasMore = true;
    data.offset = 0;
    data.error = null;
  }

  Future<void> _fetchPage(
    _TabData data,
    String? typeFilter,
    bool archivedOnly, {
    bool fetchMore = false,
  }) async {
    if (!mounted) return;

    if (fetchMore) {
      setState(() => data.isFetchingMore = true);
    } else {
      setState(() {
        data.isLoading = true;
        data.error = null;
      });
    }

    try {
      final repository = context.read<SupabaseRepository>();
      final centerId = context.read<CenterProvider>().currentCenterId;

      if (centerId == null) {
        if (mounted) setState(() => data.isLoading = false);
        return;
      }

      final newItems = await repository.getTeacherAssignments(
        centerId: centerId,
        courseId: _selectedCourseId == 'all' ? null : _selectedCourseId,
        groupId: _selectedGroupId == 'all' ? null : _selectedGroupId,
        typeFilter: typeFilter,
        archivedOnly: archivedOnly,
        searchQuery: _searchQuery,
        statusFilter: _statusFilter,
        limit: _pageSize,
        offset: data.offset,
      );

      if (mounted) {
        setState(() {
          if (fetchMore) {
            data.items.addAll(newItems);
            data.isFetchingMore = false;
          } else {
            data.items = newItems;
            data.isLoading = false;
          }
          data.hasMore = newItems.length == _pageSize;
          data.offset += newItems.length;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          data.error = error.toString();
          data.isLoading = false;
          data.isFetchingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DefaultTabController(
        length: 4,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 180.h,
                floating: false,
                pinned: true,
                backgroundColor: Theme.of(context).colorScheme.surface,
                flexibleSpace: FlexibleSpaceBar(
                  background: TeacherAssignmentsHeader(stats: _stats),
                ),
                bottom: TabBar(
                  controller: _tabController,
                  indicatorColor: Theme.of(context).colorScheme.primary,
                  indicatorWeight: 3,
                  labelColor: Theme.of(context).colorScheme.onSurface,
                  unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
                    icon: Icon(Icons.refresh, color: Theme.of(context).colorScheme.onSurface),
                    onPressed: _triggerRefresh,
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 8.w),
                    child: SizedBox.shrink(),
                  ),
                ],
              ),
            ];
          },
          body: _error != null
              ? _buildErrorWidget()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAssignmentsList(_allData),
                    _buildAssignmentsList(_assignmentsData),
                    _buildAssignmentsList(_examsData),
                    _buildAssignmentsList(_archivedData),
                  ],
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => TeacherAssignmentsModals.showCreateOptions(
          context: context,
          onNavigateToCreate: _navigateToCreate,
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        icon: Icon(Icons.add, color: Theme.of(context).scaffoldBackgroundColor),
        label: Text(
          'إنشاء جديد',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).scaffoldBackgroundColor,
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
              color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 40.sp,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            _error ?? 'حدث خطأ',
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: 12.h),
          GeniusButton(
            label: 'إعادة المحاولة',
            icon: Icons.refresh,
            onPressed: _triggerRefresh,
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
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color:
                    (Theme.of(context).dividerTheme.color ??
                    Colors.grey.shade300),
              ),
            ),
            child: Icon(
              Icons.assignment_outlined,
              size: 52.sp,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'لا توجد بيانات',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 16.sp,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'اضغط على "إنشاء جديد" للبدء',
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.3),
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildAssignmentsList(_TabData data) {
    return CustomScrollView(
      controller: data.scrollController,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
            child: TeacherAssignmentsFilterPanel(
              stats: _stats,
              searchController: _searchController,
              searchQuery: _searchQuery,
              statusFilter: _statusFilter,
              groups: _groups,
              selectedGroupId: _selectedGroupId,
              sortOrder: _sortOrder,
              onSearchChanged: (v) {
                _searchQuery = v.toLowerCase();
                _triggerRefresh();
              },
              onSearchCleared: () {
                _searchController.clear();
                _searchQuery = '';
                _triggerRefresh();
              },
              onStatusChanged: (v) {
                setState(() => _statusFilter = v);
                _triggerRefresh();
              },
              onGroupChanged: (v) {
                setState(() => _selectedGroupId = v);
                _triggerRefresh();
              },
              onSortToggle: () {
                setState(() {
                  _sortOrder = _sortOrder == 'newest' ? 'oldest' : 'newest';
                });
                _triggerRefresh();
              },
            ),
          ),
        ),
        if (data.isLoading)
          const SliverFillRemaining(
            child: Center(child: TeacherAssignmentsSkeleton()),
          )
        else if (data.error != null)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 50.sp,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'حدث خطأ في تحميل البيانات\n${data.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                  SizedBox(height: 16.h),
                  GeniusButton(
                    label: 'إعادة المحاولة',
                    onPressed: _triggerRefresh,
                  ),
                ],
              ),
            ),
          )
        else if (data.items.isEmpty)
          SliverFillRemaining(child: _buildEmptyState())
        else ...[
          SliverPadding(
            padding: EdgeInsets.all(16.w),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final assignment = data.items[index];
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
                        onToggleArchive: (archived) =>
                            _toggleArchive(assignment, archived),
                        onDeleteAssignment: () => _deleteAssignment(assignment),
                      );
                    },
                    onShowMoreOptions: () {
                      TeacherAssignmentsModals.showMoreOptions(
                        context: context,
                        assignment: assignment,
                        onOpenAddToGroups: () => _openAddToGroups(assignment),
                        onEditPublishAt: () => _editPublishAt(assignment),
                        onToggleArchive: (archived) =>
                            _toggleArchive(assignment, archived),
                        onDeleteAssignment: () => _deleteAssignment(assignment),
                      );
                    },
                  ),
                );
              }, childCount: data.items.length),
            ),
          ),
          if (data.isFetchingMore)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
        ],
        SliverToBoxAdapter(child: SizedBox(height: 60.h)),
      ],
    );
  }

  void _navigateToCreate(String type) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateAssignmentScreen(type: type)),
    );

    if (result == true) _triggerRefresh();
  }

  void _viewSubmissions(Map<String, dynamic> assignment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubmissionsScreen(assignment: assignment),
      ),
    ).then((_) => _triggerRefresh());
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
      }
      _triggerRefresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل التحديث: $e')));
      }
    }
  }

  Future<void> _editPublishAt(Map<String, dynamic> assignment) async {
    final currentPublish =
        AssignmentHelper.getPublishDate(assignment) ?? DateTime.now();
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
        _triggerRefresh();
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
      final centerId =
          assignment['center_id'] as String? ?? centerProvider.currentCenterId;
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
        _triggerRefresh();
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
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'حذف الواجب',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: Text(
          'هل أنت متأكد من حذف "${assignment['title']}"؟',
          style: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'إلغاء',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text('حذف'),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حذف الواجب'),
              backgroundColor: Colors.green,
            ),
          );
          _triggerRefresh();
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
