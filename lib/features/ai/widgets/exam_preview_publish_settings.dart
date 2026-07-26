import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../shared/models/models.dart';

class ExamPreviewPublishSettings extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController durationController;
  final List<GroupModel> groups;
  final Set<String> selectedGroupIds;
  final ValueChanged<Set<String>> onSelectionChanged;
  final bool showAnswersAfter;
  final ValueChanged<bool> onShowAnswersChanged;
  final bool shuffleQuestions;
  final ValueChanged<bool> onShuffleChanged;

  const ExamPreviewPublishSettings({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.durationController,
    required this.groups,
    required this.selectedGroupIds,
    required this.onSelectionChanged,
    required this.showAnswersAfter,
    required this.onShowAnswersChanged,
    required this.shuffleQuestions,
    required this.onShuffleChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Group by Grade Level (or Course Name as fallback)
    final Map<String, List<GroupModel>> groupedGroups = {};
    for (final g in groups) {
      final key = (g.gradeLevel?.isNotEmpty == true)
          ? g.gradeLevel!
          : (g.courseName?.isNotEmpty == true ? g.courseName! : 'عام');
      if (!groupedGroups.containsKey(key)) {
        groupedGroups[key] = [];
      }
      groupedGroups[key]!.add(g);
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: (Theme.of(context).dividerTheme.color ?? Colors.grey.shade300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'إعدادات النشر',
            style: TextStyle(
              color: AppColors.textOnDark,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),
          _buildInput(
            controller: titleController,
            label: 'عنوان الامتحان',
            icon: Icons.title,
          ),
          SizedBox(height: 12.h),
          _buildInput(
            controller: descriptionController,
            label: 'وصف (اختياري)',
            icon: Icons.description,
            maxLines: 2,
          ),
          SizedBox(height: 12.h),
          _buildInput(
            controller: durationController,
            label: 'المدة (بالدقائق)',
            icon: Icons.timer,
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 16.h),
          Text(
            'المجموعات المستهدفة (يمكنك اختيار أكثر من مجموعة أو سنة دراسية)',
            style: TextStyle(
              color: AppColors.textOnDarkSecondary,
              fontSize: 13.sp,
            ),
          ),
          SizedBox(height: 8.h),
          if (groups.isEmpty)
            Text(
              'لا توجد مجموعات مسجلة',
              style: TextStyle(color: AppColors.error, fontSize: 13.sp),
            )
          else
            ...groupedGroups.entries.map((entry) {
              final gradeName = entry.key;
              final gradeGroups = entry.value;
              final allSelected = gradeGroups.every(
                  (g) => selectedGroupIds.contains(g.id));

              return Container(
                margin: EdgeInsets.only(bottom: 12.h),
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: (Theme.of(context).dividerTheme.color ?? Colors.grey.shade300)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          gradeName,
                          style: TextStyle(
                            color: AppColors.textOnDark,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            final newSelection = Set<String>.from(selectedGroupIds);
                            if (allSelected) {
                              newSelection.removeAll(gradeGroups.map((g) => g.id));
                            } else {
                              newSelection.addAll(gradeGroups.map((g) => g.id));
                            }
                            onSelectionChanged(newSelection);
                          },
                          icon: Icon(
                            allSelected
                                ? Icons.deselect
                                : Icons.select_all,
                            size: 16.sp,
                            color: const Color(0xFF8B5CF6),
                          ),
                          label: Text(
                            allSelected ? 'إلغاء الكل' : 'تحديد السنة كاملة',
                            style: TextStyle(
                              color: const Color(0xFF8B5CF6),
                              fontSize: 12.sp,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: gradeGroups.map((g) {
                        final isSelected = selectedGroupIds.contains(g.id);
                        return FilterChip(
                          label: Text(g.groupName),
                          selected: isSelected,
                          onSelected: (selected) {
                            final newSelection = Set<String>.from(selectedGroupIds);
                            if (selected) {
                              newSelection.add(g.id);
                            } else {
                              newSelection.remove(g.id);
                            }
                            onSelectionChanged(newSelection);
                          },
                          selectedColor: const Color(0xFF8B5CF6).withOpacity(0.2),
                          checkmarkColor: const Color(0xFF8B5CF6),
                          backgroundColor: Theme.of(context).colorScheme.surface,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? const Color(0xFF8B5CF6)
                                : AppColors.textOnDarkSecondary,
                            fontSize: 12.sp,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.r),
                            side: BorderSide(
                              color: isSelected
                                  ? const Color(0xFF8B5CF6)
                                  : (Theme.of(context).dividerTheme.color ?? Colors.grey.shade300),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            }),
          SizedBox(height: 16.h),
          _buildSwitch(
            'إظهار الإجابات بعد الحل',
            showAnswersAfter,
            onShowAnswersChanged,
          ),
          _buildSwitch(
            'ترتيب الأسئلة عشوائي',
            shuffleQuestions,
            onShuffleChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(color: AppColors.textOnDark, fontSize: 14.sp),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.textOnDarkHint),
        prefixIcon: Icon(icon, color: AppColors.primary),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildSwitch(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: TextStyle(color: AppColors.textOnDarkSecondary, fontSize: 13.sp),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
    );
  }
}
