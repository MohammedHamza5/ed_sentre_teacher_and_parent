import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Archive toggle switch for assignments — hides from students until unarchived.
class AssignmentArchiveSelector extends StatelessWidget {
  final bool startArchived;
  final Color typeColor;
  final ValueChanged<bool> onChanged;

  const AssignmentArchiveSelector({
    super.key,
    required this.startArchived,
    required this.typeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: (Theme.of(context).dividerTheme.color ?? Colors.grey.shade300)
              .withValues(alpha: 0.5),
        ),
      ),
      child: SwitchListTile(
        value: startArchived,
        activeColor: typeColor,
        onChanged: onChanged,
        title: Text(
          '\u0623\u0631\u0634\u0641\u0629 \u0639\u0646\u062f \u0627\u0644\u0625\u0646\u0634\u0627\u0621',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 14.sp,
          ),
        ),
        subtitle: Text(
          '\u0644\u0646 \u064a\u0638\u0647\u0631 \u0644\u0644\u0637\u0644\u0627\u0628 \u0625\u0644\u0627 \u0628\u0639\u062f \u0625\u0644\u063a\u0627\u0621 \u0627\u0644\u0623\u0631\u0634\u0641\u0629',
          style: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
            fontSize: 12.sp,
          ),
        ),
      ),
    );
  }
}
