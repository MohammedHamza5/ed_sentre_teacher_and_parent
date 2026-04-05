import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/app_colors.dart';

/// A premium skeleton loader using a fluid wave shimmer effect.
class ShimmerSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry margin;

  const ShimmerSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 16.0,
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
          width: width,
          height: height,
          margin: margin,
          decoration: BoxDecoration(
            color: AppColors.forestPrimary,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: AppColors.darkBorder),
          ),
        )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: 1500.ms,
          color: AppColors.glassWhite.withValues(alpha: 0.08),
          angle: 0.5,
          size: 2,
        );
  }
}

/// A pre-built skeleton geometry for standard list items
class ShimmerListItem extends StatelessWidget {
  const ShimmerListItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerSkeleton(width: 56, height: 56, borderRadius: 16),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const ShimmerSkeleton(width: 120, height: 16, borderRadius: 8),
                const SizedBox(height: 12),
                ShimmerSkeleton(
                  width: MediaQuery.of(context).size.width * 0.6,
                  height: 12,
                  borderRadius: 6,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
