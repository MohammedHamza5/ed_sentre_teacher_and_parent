import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../shared/models/models.dart';
import 'assignment_helper.dart';

class TeacherAssignmentsModals {
  static void showCreateOptions({
    required BuildContext context,
    required Function(String type) onNavigateToCreate,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.glassBorderHighlight,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'إنشاء جديد',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textDisplay,
              ),
            ),
            SizedBox(height: 20.h),
            Row(
              children: [
                Expanded(
                  child: _buildCreateOption(
                    icon: Icons.assignment,
                    label: 'واجب',
                    color: AppColors.accentVivid,
                    onTap: () {
                      Navigator.pop(context);
                      onNavigateToCreate('assignment');
                    },
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildCreateOption(
                    icon: Icons.quiz,
                    label: 'امتحان',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.pop(context);
                      onNavigateToCreate('exam');
                    },
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildCreateOption(
                    icon: Icons.bolt,
                    label: 'كويز سريع',
                    color: const Color(0xFF8B5CF6),
                    onTap: () {
                      Navigator.pop(context);
                      onNavigateToCreate('quiz');
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  static Widget _buildCreateOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28.sp),
            SizedBox(height: 8.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void showMoreOptions({
    required BuildContext context,
    required Map<String, dynamic> assignment,
    required VoidCallback onOpenAddToGroups,
    required VoidCallback onEditPublishAt,
    required Function(bool archived) onToggleArchive,
    required VoidCallback onDeleteAssignment,
  }) {
    final isArchived = AssignmentHelper.isArchived(assignment);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.only(top: 12.h),
                decoration: BoxDecoration(
                  color: AppColors.glassBorderHighlight,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              ListTile(
                leading: Icon(
                  Icons.group_add,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                title: Text(
                  'نشر لمجموعات إضافية',
                  style: TextStyle(color: AppColors.textDisplay),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onOpenAddToGroups();
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.copy,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                title: Text(
                  'نسخ',
                  style: TextStyle(color: AppColors.textDisplay),
                ),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: Icon(
                  Icons.share,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                title: Text(
                  'مشاركة',
                  style: TextStyle(color: AppColors.textDisplay),
                ),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: Icon(
                  Icons.schedule,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                title: Text(
                  'تعديل موعد الظهور',
                  style: TextStyle(color: AppColors.textDisplay),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onEditPublishAt();
                },
              ),
              ListTile(
                leading: Icon(
                  isArchived ? Icons.unarchive : Icons.archive,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                title: Text(
                  isArchived ? 'إلغاء الأرشفة' : 'أرشفة',
                  style: TextStyle(color: AppColors.textDisplay),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onToggleArchive(!isArchived);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: AppColors.errorRed),
                title: Text('حذف', style: TextStyle(color: AppColors.errorRed)),
                onTap: () {
                  Navigator.pop(context);
                  onDeleteAssignment();
                },
              ),
              SizedBox(height: 8.h),
            ],
          ),
        ),
      ),
    );
  }

  static Future<Set<String>?> openAddToGroups({
    required BuildContext context,
    required String? currentGroupId,
    required List<GroupModel> groups,
    required bool isLoadingGroups,
  }) async {
    if (isLoadingGroups) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('جاري تحميل المجموعات...')),
      );
      return null;
    }
    if (groups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد مجموعات متاحة')),
      );
      return null;
    }

    final selectedIds = <String>{};
    return await showModalBottomSheet<Set<String>>(
      context: context,
      backgroundColor: AppColors.darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final availableGroups =
                groups.where((g) => g.id != currentGroupId).toList();
            return Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        'اختيار المجموعات',
                        style: TextStyle(
                          color: AppColors.textDisplay,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          final allSelected =
                              selectedIds.length == availableGroups.length;
                          if (allSelected) {
                            selectedIds.clear();
                          } else {
                            selectedIds
                              ..clear()
                              ..addAll(availableGroups.map((g) => g.id));
                          }
                          setSheetState(() {});
                        },
                        child: Text(
                          selectedIds.length == availableGroups.length
                              ? 'إلغاء الكل'
                              : 'تحديد الكل',
                          style: TextStyle(color: AppColors.accentVivid),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: availableGroups.map((group) {
                        final isChecked = selectedIds.contains(group.id);
                        return CheckboxListTile(
                          value: isChecked,
                          activeColor: AppColors.accentVivid,
                          onChanged: (v) {
                            if (v == true) {
                              selectedIds.add(group.id);
                            } else {
                              selectedIds.remove(group.id);
                            }
                            setSheetState(() {});
                          },
                          title: Text(
                            group.groupName,
                            style: TextStyle(color: AppColors.textDisplay),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, selectedIds),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentVivid,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      child: const Text(
                        'تم',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
