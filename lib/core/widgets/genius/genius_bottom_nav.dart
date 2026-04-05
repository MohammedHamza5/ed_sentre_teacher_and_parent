import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/app_colors.dart';

class NavItem {
  final IconData icon;
  final String label;

  NavItem({required this.icon, required this.label});
}

class GeniusBottomNav extends StatelessWidget {
  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onItemSelected;

  const GeniusBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (items.length < 2 || items.length > 5) {
      throw Exception('GeniusBottomNav requires exactly 2 to 5 items.');
    }

    return Padding(
      padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 24.0),
      child: RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.glassFrost,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: AppColors.glassBorderHighlight,
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(items.length, (index) {
                  final isSelected = index == currentIndex;
                  final item = items[index];

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onItemSelected(index),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                            duration: 300.ms,
                            curve: Curves.easeOutBack,
                            padding: EdgeInsets.all(isSelected ? 8.0 : 4.0),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.accentVivid.withValues(
                                      alpha: 0.15,
                                    )
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              item.icon,
                              color: isSelected
                                  ? AppColors.accentVivid
                                  : AppColors.textMuted,
                              size: isSelected ? 26 : 24,
                            ),
                          ),
                          if (isSelected)
                            const SizedBox(
                              height: 4,
                            ).animate().fade(duration: 200.ms),
                          if (isSelected)
                            Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: AppColors.accentVivid,
                                shape: BoxShape.circle,
                              ),
                            ).animate().scale(
                              curve: Curves.easeOutBack,
                              duration: 300.ms,
                            ),
                        ],
                      ),
                    ),
                  ));
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
