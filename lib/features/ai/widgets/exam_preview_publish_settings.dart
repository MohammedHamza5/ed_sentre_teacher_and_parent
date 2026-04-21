import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../shared/models/models.dart';

class ExamPreviewPublishSettings extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController durationController;
  final List<GroupModel> groups;
  final GroupModel? selectedGroup;
  final ValueChanged<GroupModel?> onGroupChanged;
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
    required this.selectedGroup,
    required this.onGroupChanged,
    required this.showAnswersAfter,
    required this.onShowAnswersChanged,
    required this.shuffleQuestions,
    required this.onShuffleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.darkBorder),
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
            'المجموعة المستهدفة',
            style: TextStyle(
              color: AppColors.textOnDarkSecondary,
              fontSize: 13.sp,
            ),
          ),
          SizedBox(height: 8.h),
          if (groups.isEmpty)
            Text(
              'لا توجد مجموعات',
              style: TextStyle(color: AppColors.error, fontSize: 13.sp),
            )
          else
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              decoration: BoxDecoration(
                color: AppColors.darkInput,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<GroupModel>(
                  value: selectedGroup,
                  isExpanded: true,
                  dropdownColor: AppColors.darkElevated,
                  style: TextStyle(
                    color: AppColors.textOnDark,
                    fontSize: 14.sp,
                  ),
                  items: groups.map((g) {
                    return DropdownMenuItem(value: g, child: Text(g.groupName));
                  }).toList(),
                  onChanged: onGroupChanged,
                ),
              ),
            ),
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
        fillColor: AppColors.darkInput,
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
