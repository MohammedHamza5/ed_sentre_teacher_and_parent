import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../core/config/app_colors.dart';
import '../../../shared/widgets/premium_widgets.dart';
import '../../../shared/data/supabase_repository.dart';
import 'package:provider/provider.dart';

/// 🎨 Teacher Attendance History Screen
class TeacherAttendanceHistoryScreen extends StatefulWidget {
  final String groupId;

  const TeacherAttendanceHistoryScreen({super.key, required this.groupId});

  @override
  State<TeacherAttendanceHistoryScreen> createState() =>
      _TeacherAttendanceHistoryScreenState();
}

class _TeacherAttendanceHistoryScreenState
    extends State<TeacherAttendanceHistoryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _history = [];
  final ScrollController _scrollController = ScrollController();
  final int _daysPerPage = 30;
  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadHistory(reset: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;
    setState(() => _isLoadingMore = true);
    await _loadHistory();
  }

  Future<void> _loadHistory({bool reset = false}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _currentPage = 0;
        _hasMore = true;
        _history = [];
      });
    }
    final repo = context.read<SupabaseRepository>();
    try {
      final history = await repo.getGroupAttendanceHistory(
        groupId: widget.groupId,
        days: _daysPerPage,
        offsetDays: _currentPage * _daysPerPage,
      );
      if (mounted) {
        setState(() {
          if (reset) {
            _history = history;
          } else {
            _history.addAll(history);
          }
          _currentPage += 1;
          _hasMore = history.isNotEmpty;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (reset) {
            _history = [];
          }
          _isLoading = false;
          _isLoadingMore = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل تحميل السجل: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('سجل الحضور', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
          ? EmptyState(
              icon: Icons.history,
              title: 'لا يوجد سجل',
              subtitle: 'لم يتم تسجيل أي حضور لهذه المجموعة بعد',
            )
          : ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(16.w),
              itemCount: _history.length + (_isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isLoadingMore && index == _history.length) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  );
                }
                final record = _history[index];
                final date = record['date'] as DateTime;
                return PremiumCard(
                  margin: EdgeInsets.only(bottom: 12.h),
                  child: ListTile(
                    leading: Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(Icons.date_range, color: AppColors.primary),
                    ),
                    title: Text(
                      DateFormat('EEEE, d MMMM', 'ar').format(date),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'حضور: ${record['present']} | تأخير: ${record['late']} | غياب: ${record['absent']}',
                      style: TextStyle(color: Colors.grey),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16.sp,
                      color: Colors.grey,
                    ),
                    onTap: () {
                      // TODO: Navigate to details for this specific date
                    },
                  ),
                ).animate().fadeIn().slideX();
              },
            ),
    );
  }
}
