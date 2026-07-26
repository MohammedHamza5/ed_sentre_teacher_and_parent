import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/app_colors.dart';
import '../../theming/app_spacing.dart';

/// ═════════════════════════════════════════════════════════════════════════════
/// UNIVERSAL ADAPTIVE SHIMMER SKELETONS (Zero Light/Dark Collision & Shimmer Revolution)
/// Enforces Section 7.3, 11.4 & 12.1 of Universal AI Engineering Contract.
/// ═════════════════════════════════════════════════════════════════════════════

/// A premium skeleton loader using a fluid wave shimmer effect adapted to Light/Dark Mode.
class ShimmerSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry margin;

  const ShimmerSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppSpacing.radiusMd,
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final baseColor = isDark ? AppColors.navyLight : AppColors.gray100;
    final shimmerColor = isDark
        ? AppColors.white.withValues(alpha: 0.08)
        : AppColors.white.withValues(alpha: 0.65);

    return Container(
          width: width,
          height: height,
          margin: margin,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: isDark ? AppColors.navyLight : AppColors.gray100,

            ),
          ),
        )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: 1400.ms,
          color: shimmerColor,
          angle: 0.35,
          size: 2,
        );
  }
}

/// A pre-built skeleton geometry for standard list items (Attendance, Chats, Records)
class ShimmerListItem extends StatelessWidget {
  const ShimmerListItem({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    return Padding(
      padding: AppSpacing.paddingH16V8,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const ShimmerSkeleton(width: 52, height: 52, borderRadius: AppSpacing.radiusMd),
          AppSpacing.gapW16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerSkeleton(width: 130, height: 16, borderRadius: AppSpacing.radiusXs),
                AppSpacing.gapH8,
                ShimmerSkeleton(
                  width: screenWidth * 0.5,
                  height: 12,
                  borderRadius: AppSpacing.radiusXs,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A premium card skeleton for Financial Invoices, Exam Scorecards, and Dashboard Stats
class CardShimmerSkeleton extends StatelessWidget {
  final int itemCount;
  const CardShimmerSkeleton({super.key, this.itemCount = 1});

  @override
  Widget build(BuildContext context) {
    if (itemCount > 1) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(itemCount, (_) => _buildCard(context)),
      );
    }
    return _buildCard(context);
  }

  Widget _buildCard(BuildContext context) {
    return Container(
      margin: AppSpacing.paddingH16V8,
      padding: AppSpacing.cardInner,
      decoration: BoxDecoration(
        color: context.themeCard,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: context.themeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const ShimmerSkeleton(width: 140, height: 20, borderRadius: AppSpacing.radiusXs),
              const ShimmerSkeleton(width: 70, height: 28, borderRadius: AppSpacing.radiusCircular),
            ],
          ),
          AppSpacing.gapH16,
          const ShimmerSkeleton(width: double.infinity, height: 12, borderRadius: AppSpacing.radiusXs),
          AppSpacing.gapH8,
          const ShimmerSkeleton(width: 200, height: 12, borderRadius: AppSpacing.radiusXs),
          AppSpacing.gapH16,
          Row(
            children: [
              const ShimmerSkeleton(width: 80, height: 24, borderRadius: AppSpacing.radiusSm),
              AppSpacing.gapW8,
              const ShimmerSkeleton(width: 110, height: 24, borderRadius: AppSpacing.radiusSm),
            ],
          ),
        ],
      ),
    );
  }
}

/// Multiple list items pre-packaged for fast rendering in student groups & attendance rosters
class TableListShimmer extends StatelessWidget {
  final int itemCount;
  const TableListShimmer({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      itemBuilder: (context, index) => const ShimmerListItem(),
    );
  }
}

/// A futuristic glowing pulse skeleton for AI Assistant & Exam Generator waiting states
class AiPulseSkeleton extends StatelessWidget {
  final String title;
  const AiPulseSkeleton({super.key, this.title = 'المساعد الذكي يحلل البيانات...'});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final primaryColor = isDark ? AppColors.electricGlow : AppColors.electric;
    
    return Container(
      margin: AppSpacing.paddingH16V12,
      padding: AppSpacing.paddingAll20,
      decoration: BoxDecoration(
        color: context.themeCard,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: primaryColor.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.08),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, color: primaryColor, size: 36)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.15, 1.15), duration: 1200.ms)
              .tint(color: AppColors.teal),
          AppSpacing.gapH16,
          Text(
            title,
            style: TextStyle(
              color: context.themeTextPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          AppSpacing.gapH16,
          const ShimmerSkeleton(width: double.infinity, height: 10, borderRadius: AppSpacing.radiusXs),
          AppSpacing.gapH8,
          const ShimmerSkeleton(width: 180, height: 10, borderRadius: AppSpacing.radiusXs),
        ],
      ),
    );
  }
}

