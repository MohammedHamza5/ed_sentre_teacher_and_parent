import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/app_colors.dart';

enum GeniusButtonVariant {
  primary, // Vibrant Green Accent Gradient
  secondary, // Deep Forest Outline
  destructive, // Alert Coral
  glass, // Translucent Glass
}

class GeniusButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final GeniusButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final double height;
  final EdgeInsetsGeometry padding;

  const GeniusButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = GeniusButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height = 56.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 24.0),
  });

  @override
  State<GeniusButton> createState() => _GeniusButtonState();
}

class _GeniusButtonState extends State<GeniusButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  void _handleHover(bool isHovering) {
    setState(() => _isHovered = isHovering);
  }

  void _handleTapDown(TapDownDetails details) {
    HapticFeedback.lightImpact();
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    if (widget.onPressed != null && !widget.isLoading) {
      widget.onPressed!();
    }
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onPressed == null || widget.isLoading;

    Widget buttonContent = Row(
      mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading)
          const SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        else if (widget.icon != null) ...[
          Icon(widget.icon, size: 20, color: _getTextColor(isDisabled)),
          const SizedBox(width: 8),
        ],
        if (!widget.isLoading)
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 16,
              letterSpacing: 0.5,
              fontWeight: FontWeight.bold,
              color: _getTextColor(isDisabled),
            ),
          ),
      ],
    );

    return MouseRegion(
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      cursor: isDisabled
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: isDisabled ? null : _handleTapDown,
        onTapUp: isDisabled ? null : _handleTapUp,
        onTapCancel: isDisabled ? null : _handleTapCancel,
        child:
            AnimatedContainer(
                  duration: 200.ms,
                  curve: Curves.easeOutCirc,
                  height: widget.height,
                  padding: widget.padding,
                  decoration: _getDecoration(isDisabled),
                  child: buttonContent,
                )
                .animate(target: _isPressed ? 1 : 0)
                .scale(
                  end: const Offset(0.95, 0.95),
                  curve: Curves.easeOutCubic,
                  duration: 150.ms,
                ),
      ),
    );
  }

  Color _getTextColor(bool isDisabled) {
    if (isDisabled) return AppColors.textDisabled;
    switch (widget.variant) {
      case GeniusButtonVariant.primary:
      case GeniusButtonVariant.destructive:
        return Colors.white;
      case GeniusButtonVariant.secondary:
        return AppColors.accentVivid;
      case GeniusButtonVariant.glass:
        return AppColors.textDisplay;
    }
  }

  BoxDecoration _getDecoration(bool isDisabled) {
    final borderRadius = BorderRadius.circular(16.0);

    if (isDisabled) {
      return BoxDecoration(
        color: AppColors.forestPrimary,
        borderRadius: borderRadius,
        border: Border.all(color: AppColors.darkBorder),
      );
    }

    switch (widget.variant) {
      case GeniusButtonVariant.primary:
        return BoxDecoration(
          gradient: AppColors.accentGradient,
          borderRadius: borderRadius,
          boxShadow: _isHovered
              ? [
                  const BoxShadow(
                    color: AppColors.heroGlow,
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        );
      case GeniusButtonVariant.secondary:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: borderRadius,
          border: Border.all(
            color: _isHovered ? AppColors.accentVivid : AppColors.accentMid,
            width: 2,
          ),
        );
      case GeniusButtonVariant.destructive:
        return BoxDecoration(
          color: AppColors.alertCoral,
          borderRadius: borderRadius,
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: AppColors.alertCoral.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: -2,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        );
      case GeniusButtonVariant.glass:
        return BoxDecoration(
          color: AppColors.glassFrost,
          borderRadius: borderRadius,
          border: Border.all(color: AppColors.glassBorderHighlight),
        );
    }
  }
}
