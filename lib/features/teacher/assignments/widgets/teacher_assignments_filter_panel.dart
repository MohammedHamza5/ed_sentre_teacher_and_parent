import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../shared/models/models.dart';

class TeacherAssignmentsFilterPanel extends StatelessWidget {
  final Map<String, dynamic> stats;
  final TextEditingController searchController;
  final String searchQuery;
  final String statusFilter;
  final List<GroupModel> groups;
  final String selectedGroupId;
  final String sortOrder;

  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchCleared;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onGroupChanged;
  final VoidCallback onSortToggle;

  const TeacherAssignmentsFilterPanel({
    super.key,
    required this.stats,
    required this.searchController,
    required this.searchQuery,
    required this.statusFilter,
    required this.groups,
    required this.selectedGroupId,
    required this.sortOrder,
    required this.onSearchChanged,
    required this.onSearchCleared,
    required this.onStatusChanged,
    required this.onGroupChanged,
    required this.onSortToggle,
  });

  Widget _buildUrgentTasksPanel(BuildContext context) {
    final pendingVal = stats['pending_grading'] ?? 0;
    if (pendingVal == 0) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: AppColors.danger,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'المهام العاجلة: يحتاج للتصحيح!',
                  style: TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
                Text(
                  'يوجد $pendingVal امتحانات/واجبات تحتاج لتقييمك الآن.',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 12.sp),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, String value, String label) {
    final isSelected = statusFilter == value;
    final borderColor = Theme.of(context).dividerTheme.color ?? Colors.grey.shade300;
    return GestureDetector(
      onTap: () => onStatusChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildGroupDropdown(BuildContext context) {
    final borderColor = Theme.of(context).dividerTheme.color ?? Colors.grey.shade300;
    return Container(
      height: 48.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 0.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedGroupId,
          isExpanded: true,
          dropdownColor: Theme.of(context).colorScheme.surface,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13.sp),
          icon: Icon(Icons.arrow_drop_down_rounded, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
          items: [
            DropdownMenuItem(
              value: 'all',
              child: Text('كافة المجاميع والمراحل'),
            ),
            ...groups.map(
              (g) => DropdownMenuItem(value: g.id, child: Text(g.groupName)),
            ),
          ],
          onChanged: (v) {
            if (v != null) onGroupChanged(v);
          },
        ),
      ),
    );
  }

  Widget _buildSortToggle(BuildContext context) {
    bool isNewest = sortOrder == 'newest';
    final borderColor = Theme.of(context).dividerTheme.color ?? Colors.grey.shade300;
    return InkWell(
      onTap: onSortToggle,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        height: 48.h,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isNewest ? Icons.sort_rounded : Icons.sort_by_alpha_rounded,
              color: AppColors.primary,
              size: 20.sp,
            ),
            SizedBox(width: 6.w),
            Text(
              isNewest ? 'الأحدث' : 'الأقدم',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildUrgentTasksPanel(context),
        Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: (Theme.of(context).dividerTheme.color ?? Colors.grey.shade300)),
          ),
          child: Column(
            children: [
              TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14.sp),
                decoration: InputDecoration(
                  hintText: 'ابحث عن واجب أو مادة...',
                  hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    size: 20.sp,
                  ),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          onPressed: onSearchCleared,
                          icon: Icon(
                            Icons.close_rounded,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.3),
                            size: 18.sp,
                          ),
                        )
                      : null,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: (Theme.of(context).dividerTheme.color ?? Colors.grey.shade300),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: (Theme.of(context).dividerTheme.color ?? Colors.grey.shade300),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              SizedBox(
                height: 36.h,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildStatusChip(context, 'all', 'الكل'),
                    SizedBox(width: 8.w),
                    _buildStatusChip(context, 'active', 'نشطة'),
                    SizedBox(width: 8.w),
                    _buildStatusChip(context, 'ended', 'منتهية'),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              Divider(color: (Theme.of(context).dividerTheme.color ?? Colors.grey.shade300)),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(child: _buildGroupDropdown(context)),
                  SizedBox(width: 12.w),
                  _buildSortToggle(context),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
