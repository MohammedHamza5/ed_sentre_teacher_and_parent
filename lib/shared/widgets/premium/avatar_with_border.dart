import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AvatarWithBorder extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final Gradient? borderGradient;
  final double borderWidth;
  final IconData? placeholderIcon;

  const AvatarWithBorder({
    super.key,
    this.imageUrl,
    this.radius = 28,
    this.borderGradient,
    this.borderWidth = 2.5,
    this.placeholderIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultGradient = LinearGradient(
      colors: [
        theme.colorScheme.primary,
        theme.colorScheme.primary.withValues(alpha: 0.8),
      ],
    );

    return Container(
      padding: EdgeInsets.all(borderWidth),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: borderGradient ?? defaultGradient,
      ),
      child: CircleAvatar(
        radius: radius.r,
        backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
        backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
        child: imageUrl == null
            ? Icon(
                placeholderIcon ?? Icons.person,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                size: (radius * 0.9).sp,
              )
            : null,
      ),
    );
  }
}
