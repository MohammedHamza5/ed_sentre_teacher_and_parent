import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/config/app_colors.dart';
import '../../provider/parent_provider.dart';
import '../../../../shared/models/models.dart';

class ParentAttendanceScreen extends StatefulWidget {
  const ParentAttendanceScreen({super.key});

  @override
  State<ParentAttendanceScreen> createState() => _ParentAttendanceScreenState();
}

class _ParentAttendanceScreenState extends State<ParentAttendanceScreen> {
  bool _isLoading = true;
  List<AttendanceModel> _attendanceRecords = [];

  // Premium colors
  static const _presentColor = Colors.green;
  static const _absentColor = AppColors.danger;
  static const _lateColor = AppColors.warningAmber;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final parentProvider = context.read<ParentProvider>();
    if (parentProvider.selectedChild != null &&
        parentProvider.selectedCenter != null) {
      final records = await parentProvider.getChildAttendance();
      if (mounted) {
        setState(() {
          _attendanceRecords = records;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final presentCount = _attendanceRecords
        .where((r) => r.status == AttendanceStatus.present)
        .length;
    final absentCount = _attendanceRecords
        .where((r) => r.status == AttendanceStatus.absent)
        .length;
    final lateCount = _attendanceRecords
        .where((r) => r.status == AttendanceStatus.late)
        .length;
    final total = _attendanceRecords.length;
    final attendanceRate = total > 0
        ? ((presentCount + lateCount) / total * 100).toStringAsFixed(0)
        : '0';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
            )
          : CustomScrollView(
              slivers: [
                // Premium Header
                SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.premiumEmerald,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(32.r),
                        bottomRight: Radius.circular(32.r),
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 30.h),
                        child: Column(
                          children: [
                            // Title (centered, no back button)
                            Text(
                              'سجل الحضور',
                              style: TextStyle(
                                fontSize: 22.sp,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            SizedBox(height: 24.h),

                            // Big Rate Display
                            Container(
                              padding: EdgeInsets.all(24.w),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(24.r),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        '$attendanceRate%',
                                        style: TextStyle(
                                          fontSize: 48.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                      Text(
                                        'نسبة الحضور',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          color: Theme.of(context).colorScheme.onSurface.withValues(
                                            alpha: 0.9,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    width: 1,
                                    height: 80.h,
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                                  ),
                                  Column(
                                    children: [
                                      _buildMiniStat(
                                        'حاضر',
                                        presentCount,
                                        Theme.of(context).colorScheme.onSurface,
                                      ),
                                      SizedBox(height: 8.h),
                                      _buildMiniStat(
                                        'غائب',
                                        absentCount,
                                        Theme.of(context).colorScheme.error,
                                      ),
                                      SizedBox(height: 8.h),
                                      _buildMiniStat(
                                        'متأخر',
                                        lateCount,
                                        AppColors.warningAmber,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ).animate().fadeIn().scale(delay: 200.ms),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Records List
                SliverPadding(
                  padding: EdgeInsets.all(16.w),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'السجلات الأخيرة',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),

                if (_attendanceRecords.isEmpty)
                  SliverPadding(
                    padding: EdgeInsets.all(16.w),
                    sliver: SliverToBoxAdapter(
                      child: Container(
                        padding: EdgeInsets.all(32.w),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(color: (Theme.of(context).dividerTheme.color ?? Colors.grey.shade300)),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.event_busy,
                              size: 48.sp,
                              color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              'لا توجد سجلات حضور لابنك',
                              style: TextStyle(
                                fontSize: 16.sp,
                                color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final record = _attendanceRecords[index];
                        return _buildAttendanceCard(record, index);
                      }, childCount: _attendanceRecords.length),
                    ),
                  ),

                SliverPadding(padding: EdgeInsets.only(bottom: 100.h)),
              ],
            ),
    );
  }

  Widget _buildMiniStat(String label, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8.w,
          height: 8.w,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 8.w),
        Text(
          '$label: $count',
          style: TextStyle(color: Colors.white, fontSize: 13.sp),
        ),
      ],
    );
  }

  Widget _buildAttendanceCard(AttendanceModel record, int index) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (record.status) {
      case AttendanceStatus.present:
        statusColor = _presentColor;
        statusIcon = Icons.check_circle;
        statusText = 'حاضر';
        break;
      case AttendanceStatus.absent:
        statusColor = _absentColor;
        statusIcon = Icons.cancel;
        statusText = 'غائب';
        break;
      case AttendanceStatus.late:
        statusColor = _lateColor;
        statusIcon = Icons.watch_later;
        statusText = 'متأخر';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = 'غير محدد';
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: (Theme.of(context).dividerTheme.color ?? Colors.grey.shade300)),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Date Box
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              children: [
                Text(
                  DateFormat('dd').format(record.attendanceDate),
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                Text(
                  DateFormat('MMM', 'ar').format(record.attendanceDate),
                  style: TextStyle(fontSize: 12.sp, color: statusColor),
                ),
              ],
            ),
          ),
          SizedBox(width: 14.w),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.courseName ?? 'حصة دراسية',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  record.groupName ?? '',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
                  ),
                ),
              ],
            ),
          ),

          // Status Badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, color: Colors.white, size: 14.sp),
                SizedBox(width: 4.w),
                Text(
                  statusText,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.05);
  }
}
