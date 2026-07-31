import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/models/models.dart';

class AssignmentGroupSelector extends StatelessWidget {
  final List<GroupModel> groups;
  final List<GroupModel> selectedGroups;
  final Color typeColor;
  final Function(List<GroupModel>) onGroupsSelected;

  const AssignmentGroupSelector({
    super.key,
    required this.groups,
    required this.selectedGroups,
    required this.typeColor,
    required this.onGroupsSelected,
  });

  Future<void> _openGroupPicker(BuildContext context) async {
    if (groups.isEmpty) return;
    final selectedIds = selectedGroups.map((e) => e.id).toSet();

    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final allSelected = selectedIds.length == groups.length;
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
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          if (allSelected) {
                            selectedIds.clear();
                          } else {
                            selectedIds
                              ..clear()
                              ..addAll(groups.map((g) => g.id));
                          }
                          setSheetState(() {});
                        },
                        child: Text(
                          allSelected ? 'إلغاء الكل' : 'تحديد الكل',
                          style: TextStyle(color: typeColor),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: groups.map((group) {
                        final isChecked = selectedIds.contains(group.id);
                        return CheckboxListTile(
                          value: isChecked,
                          activeColor: typeColor,
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
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
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
                        backgroundColor: typeColor,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      child: Text('تم', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      final newSelectedGroups = groups
          .where((g) => result.contains(g.id))
          .toList();
      onGroupsSelected(newSelectedGroups);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedNames = selectedGroups.map((g) => g.groupName).toList();
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: (Theme.of(context).dividerTheme.color ?? Colors.grey.shade300)
              .withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.group, color: typeColor),
              SizedBox(width: 8.w),
              Text(
                'المجموعات *',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _openGroupPicker(context),
                child: Text('اختيار', style: TextStyle(color: typeColor)),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          if (selectedNames.isEmpty)
            Text(
              'لم يتم اختيار مجموعة',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            )
          else
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: selectedNames
                  .map(
                    (name) => Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: typeColor),
                      ),
                      child: Text(
                        name,
                        style: TextStyle(
                          color: typeColor,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}
