import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../provider/teacher_provider.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/data/supabase_repository.dart';

// Extracted Widgets
import '../widgets/group_details_header.dart';
import '../widgets/group_details_helper.dart';
import '../widgets/group_students_tab.dart';
import '../widgets/group_schedule_tab.dart';
import '../widgets/group_attendance_tab.dart';
import '../widgets/group_info_tab.dart';

/// 🎨 Teacher Group Details Screen - Forest Dark Edition
class TeacherGroupDetailsScreen extends StatefulWidget {
  final String groupId;

  const TeacherGroupDetailsScreen({super.key, required this.groupId});

  @override
  State<TeacherGroupDetailsScreen> createState() =>
      _TeacherGroupDetailsScreenState();
}

class _TeacherGroupDetailsScreenState extends State<TeacherGroupDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  GroupModel? _group;
  List<Map<String, dynamic>> _students = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGroupData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGroupData() async {
    setState(() => _isLoading = true);
    final teacherProvider = context.read<TeacherProvider>();
    final repo = context.read<SupabaseRepository>();

    try {
      final group = teacherProvider.groups.firstWhere(
        (g) => g.id == widget.groupId,
      );
      _group = group;

      final studentsResponse = await repo.getGroupStudents(widget.groupId);
      _students = studentsResponse.map((e) {
        final student = e['students'] as Map<String, dynamic>;
        return {
          'student_name': student['full_name'],
          'student_phone': student['phone'],
          'student_avatar': student['avatar_url'],
          'student_id': student['id'],
          'enrollment_id': e['id'],
        };
      }).toList();

      if (_students.isEmpty) {
        _students = teacherProvider.getStudentsForGroup(widget.groupId);
      }
    } catch (e) {
      debugPrint('Error loading group details: $e');
      _error = e.toString();
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final canMonitorNow = GroupDetailsHelper.isClassActive(_group);
    final tabBarHeight = kTextTabBarHeight + 12.h;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
            )
          : _group == null
          ? _buildErrorState()
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    expandedHeight: 260.h,
                    floating: false,
                    pinned: true,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    title: innerBoxIsScrolled
                        ? Text(
                            _group!.groupName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 18.sp,
                            ),
                          )
                        : null,
                    centerTitle: true,
                    leading: IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      onPressed: () => context.pop(),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      background: GroupDetailsHeader(
                        group: _group!,
                        tabBarHeight: tabBarHeight,
                      ),
                    ),
                    actions: [
                      IconButton(
                        onPressed: _group?.groupCode == null
                            ? null
                            : () async {
                                final code = _group!.groupCode!;
                                await Clipboard.setData(
                                  ClipboardData(text: code),
                                );
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'تم نسخ كود المجموعة: $code',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).scaffoldBackgroundColor,
                                      ),
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                        icon: Icon(
                          Icons.copy_all_rounded,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        tooltip: 'نسخ كود المجموعة',
                      ),
                      IconButton(
                        onPressed: () {
                          if (canMonitorNow) {
                            context.push(
                              '/teacher/attendance/${widget.groupId}',
                            );
                            return;
                          }
                          _showMonitorWindowHint();
                        },
                        icon: Icon(
                          Icons.fact_check_rounded,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        tooltip: 'مراقبة الحضور',
                      ),
                      SizedBox(width: 4.w),
                    ],
                    bottom: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      indicatorColor: Theme.of(context).colorScheme.primary,
                      labelColor: Theme.of(context).colorScheme.primary,
                      unselectedLabelColor:
                          (Theme.of(context).textTheme.bodySmall?.color ??
                          Colors.grey),
                      indicatorWeight: 3,
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(
                          icon: Icon(Icons.people_alt_rounded),
                          text: 'الطلاب',
                        ),
                        Tab(
                          icon: Icon(Icons.schedule_rounded),
                          text: 'المواعيد',
                        ),
                        Tab(
                          icon: Icon(Icons.fact_check_rounded),
                          text: 'الحضور',
                        ),
                        Tab(
                          icon: Icon(Icons.info_outline_rounded),
                          text: 'معلومات',
                        ),
                      ],
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  GroupStudentsTab(students: _students),
                  GroupScheduleTab(group: _group!),
                  GroupAttendanceTab(
                    groupId: widget.groupId,
                    isLiveActive: canMonitorNow,
                    repository: context.read<SupabaseRepository>(),
                    onShowMonitorWindowHint: _showMonitorWindowHint,
                  ),
                  GroupInfoTab(group: _group!),
                ],
              ),
            ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
              Icons.error_outline_rounded,
              size: 64.sp,
              color: Theme.of(context).colorScheme.error,
            ),
          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
          SizedBox(height: 24.h),
          Text(
            'لم يتم العثور على المجموعة',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
          if (_error != null) ...[
            SizedBox(height: 12.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      (Theme.of(context).textTheme.bodySmall?.color ??
                      Colors.grey),
                ),
              ).animate().fadeIn(delay: 300.ms),
            ),
          ],
        ],
      ),
    );
  }

  void _showMonitorWindowHint() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'المراقبة متاحة قبل الحصة بـ 30 دقيقة وحتى بعدها بـ 30 دقيقة فقط',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
