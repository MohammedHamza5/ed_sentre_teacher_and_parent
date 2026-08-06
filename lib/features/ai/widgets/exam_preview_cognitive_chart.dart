import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/config/app_colors.dart';

class ExamPreviewCognitiveChart extends StatelessWidget {
  final Map<String, dynamic> cognitiveLevelDistribution;

  const ExamPreviewCognitiveChart({
    super.key,
    required this.cognitiveLevelDistribution,
  });

  @override
  Widget build(BuildContext context) {
    if (cognitiveLevelDistribution.isEmpty) return const SizedBox.shrink();

    // Mapping specific Bloom's taxonomy levels to colors
    final colors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFFEC4899), // Pink
      const Color(0xFFF43F5E), // Rose
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF10B981), // Emerald
    ];

    final entries = cognitiveLevelDistribution.entries.toList();

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: const Color(0xFF8B5CF6), size: 24.sp),
              SizedBox(width: 8.w),
              Text(
                'التوزيع المعرفي للأسئلة',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          SizedBox(
            height: 180.h,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 30.r,
                      sections: _buildPieChartSections(entries, colors),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  flex: 3,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _buildLegendItems(context, entries, colors),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(List<MapEntry<String, dynamic>> entries, List<Color> colors) {
    return List.generate(entries.length, (i) {
      final entry = entries[i];
      final percentage = (entry.value as num?)?.toDouble() ?? 0.0;
      final color = colors[i % colors.length];

      return PieChartSectionData(
        color: color,
        value: percentage,
        title: '${percentage.toInt()}%',
        radius: 35.r,
        titleStyle: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }

  List<Widget> _buildLegendItems(BuildContext context, List<MapEntry<String, dynamic>> entries, List<Color> colors) {
    return List.generate(entries.length, (i) {
      final entry = entries[i];
      final label = entry.key;
      final percentage = (entry.value as num?)?.toDouble() ?? 0.0;
      final color = colors[i % colors.length];

      return Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: Row(
          children: [
            Container(
              width: 12.w,
              height: 12.h,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 12.sp,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${percentage.toInt()}%',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    });
  }
}
