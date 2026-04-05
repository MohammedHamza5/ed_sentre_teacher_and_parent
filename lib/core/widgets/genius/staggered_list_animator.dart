import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Wraps any list of widgets with a 120fps staggered bounce/fade animation.
/// Automatically handles the cascading effect.
class StaggeredListAnimator extends StatelessWidget {
  final List<Widget> children;
  final Duration delayBase;
  final Duration animDuration;
  final ScrollController? controller;
  final EdgeInsetsGeometry padding;
  final bool isList; // If true, wraps in ListView. If false, wraps in Column.

  const StaggeredListAnimator({
    super.key,
    required this.children,
    this.delayBase = const Duration(milliseconds: 50),
    this.animDuration = const Duration(milliseconds: 300),
    this.controller,
    this.padding = EdgeInsets.zero,
    this.isList = true,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    final animatedChildren = AnimateList(
      interval: delayBase,
      effects: [
        FadeEffect(duration: animDuration, curve: Curves.easeOut),
        SlideEffect(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
          duration: animDuration,
          curve: Curves.easeOutBack,
        ),
      ],
      children: children.map((child) => RepaintBoundary(child: child)).toList(),
    );

    if (isList) {
      return ListView(
        controller: controller,
        padding: padding,
        physics: const BouncingScrollPhysics(),
        children: animatedChildren,
      );
    } else {
      return Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: animatedChildren,
        ),
      );
    }
  }
}
