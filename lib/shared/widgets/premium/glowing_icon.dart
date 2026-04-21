import 'package:flutter/material.dart';

class GlowingIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? color;
  final double glowRadius;

  const GlowingIcon({
    super.key,
    required this.icon,
    this.size = 24,
    this.color,
    this.glowRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: effectiveColor.withValues(alpha: 0.4),
            blurRadius: glowRadius,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(icon, size: size, color: effectiveColor),
    );
  }
}
