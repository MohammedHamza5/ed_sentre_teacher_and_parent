import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/config/app_colors.dart';
import '../../../teacher/provider/teacher_provider.dart';
import '../../../../core/providers/center_provider.dart';
import '../../../../shared/data/supabase_repository.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  // Results
  List<Map<String, dynamic>> _studentResults = [];
  List<dynamic> _groupResults = [];
  List<Map<String, dynamic>> _materialResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() => _query = query);
    if (query.length > 1) {
      _performSearch(query);
    } else {
      setState(() {
        _studentResults = [];
        _groupResults = [];
        _materialResults = [];
      });
    }
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isSearching = true);
    final lowerQuery = query.toLowerCase();

    // 1. Local Search (Students & Groups) via TeacherProvider
    final teacherProvider = context.read<TeacherProvider>();

    // Students
    final allStudents = teacherProvider.students; // List<Map<String, dynamic>>
    final students = allStudents.where((s) {
      final name = (s['student_name'] ?? '').toString().toLowerCase();
      final code = (s['student_code'] ?? '').toString().toLowerCase();
      final phone = (s['student_phone'] ?? '').toString().toLowerCase();
      return name.contains(lowerQuery) ||
          code.contains(lowerQuery) ||
          phone.contains(lowerQuery);
    }).toList();

    // Groups
    final allGroups = teacherProvider.groups;
    final groups = allGroups.where((g) {
      final name = g.groupName.toLowerCase();
      final course = (g.courseName ?? '').toLowerCase();
      return name.contains(lowerQuery) || course.contains(lowerQuery);
    }).toList();

    // 2. Remote Search (Materials)
    // We search materials via Repo because they might not be loaded
    List<Map<String, dynamic>> materials = [];
    try {
      final centerId = context.read<CenterProvider>().currentCenterId;
      if (centerId != null) {
        final repo = context.read<SupabaseRepository>();
        final allMaterials = await repo.getTeacherMaterials(centerId: centerId);
        materials = allMaterials.where((m) {
          final title = (m['title'] ?? '').toString().toLowerCase();
          final desc = (m['description'] ?? '').toString().toLowerCase();
          return title.contains(lowerQuery) || desc.contains(lowerQuery);
        }).toList();
      }
    } catch (e) {
      debugPrint('Error searching materials: $e');
    }

    if (mounted) {
      setState(() {
        _studentResults = students;
        _groupResults = groups;
        _materialResults = materials;
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'ابحث عن طالب، مجموعة، أو ملف...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: AppColors.textHint, fontSize: 16.sp),
          ),
          onChanged: _onSearchChanged,
          style: TextStyle(fontSize: 16.sp),
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                _onSearchChanged('');
              },
            ),
        ],
      ),
      body: _query.length < 2
          ? _buildInitialState()
          : _isSearching
          ? const Center(child: CircularProgressIndicator())
          : _buildResultsList(),
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64.sp,
            color: AppColors.textHint.withValues(alpha: 0.3),
          ),
          SizedBox(height: 16.h),
          Text(
            'ابدأ الكتابة للبحث',
            style: TextStyle(fontSize: 16.sp, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    final hasResults =
        _studentResults.isNotEmpty ||
        _groupResults.isNotEmpty ||
        _materialResults.isNotEmpty;

    if (!hasResults) {
      return Center(
        child: Text(
          'لا توجد نتائج',
          style: TextStyle(fontSize: 16.sp, color: AppColors.textSecondary),
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        if (_studentResults.isNotEmpty)
          _buildSection('الطلاب', _studentResults, 'student'),
        if (_groupResults.isNotEmpty)
          _buildSection('المجموعات', _groupResults, 'group'),
        if (_materialResults.isNotEmpty)
          _buildSection('المواد الدراسية', _materialResults, 'material'),
      ],
    );
  }

  Widget _buildSection(String title, List<dynamic> items, String type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 8.h),
          child: Text(
            '$title (${items.length})',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        ...items.map((item) => _buildResultItem(item, type)),
        SizedBox(height: 24.h),
      ],
    );
  }

  Widget _buildResultItem(dynamic item, String type) {
    String title = '';
    String subtitle = '';
    IconData icon = Icons.circle;
    Color color = AppColors.primary;
    VoidCallback onTap = () {};

    if (type == 'student') {
      title = item['student_name'];
      subtitle = item['student_code'] ?? '';
      icon = Icons.person;
      color = AppColors.secondary;
      // onTap = () => context.push('/teacher/student/${item['id']}'); // Todo: Route
    } else if (type == 'group') {
      title = item.groupName;
      subtitle = item.courseName ?? '';
      icon = Icons.class_;
      color = AppColors.primary;
      onTap = () => context.push('/teacher/attendance/${item.id}');
    } else if (type == 'material') {
      title = item['title'];
      subtitle = item['file_type'] ?? 'ملف';
      icon = Icons.description;
      color = Colors.orange;
      // onTap = () => context.push('/teacher/materials/view/...');
    }

    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color, size: 20.sp),
        ),
        title: Text(
          title,
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
        subtitle: subtitle.isNotEmpty
            ? Text(subtitle, style: TextStyle(fontSize: 12.sp))
            : null,
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    ).animate().fadeIn().slideY(begin: 0.1, curve: Curves.easeOut);
  }
}
