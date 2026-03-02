import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Centralized Animations Helper for EdSentre
/// Uses `flutter_animate` for consistent, performant animations.
class AppAnimations {
  /// Standard duration for most UI transitions
  static const Duration defaultDuration = Duration(milliseconds: 300);
  
  /// Duration for slower, emphasize animations
  static const Duration slowDuration = Duration(milliseconds: 600);

  // --- List & Card Animations ---

  /// Slide up and fade in animation for lists
  /// [delay] is the index * 50ms usually
  static Widget slideUpFade({
    required Widget child,
    Duration delay = Duration.zero,
  }) {
    return child
        .animate(delay: delay)
        .fadeIn(duration: defaultDuration, curve: Curves.easeOut)
        .slideY(begin: 0.2, end: 0, duration: defaultDuration, curve: Curves.easeOut);
  }

  /// Scale in animation for dialogs or popups
  static Widget scaleIn({
    required Widget child,
    Duration delay = Duration.zero,
  }) {
    return child
        .animate(delay: delay)
        .fadeIn(duration: defaultDuration)
        .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), curve: Curves.easeOutBack);
  }

  // --- Interactive Animations ---

  /// Button press effect (Scale down slightly)
  static Widget buttonPress({
    required Widget child,
  }) {
    // This is a helper, but usually requires a StatefulWidget to trigger.
    // For simple usage, wrap in Animate() in the widget tree.
    return child;
  }
}

// Extension to make it easier to apply standard animations
extension EdSentreAnimate on Widget {
  /// Applies the standard slide-up fade animation
  Widget animateSlideUp({int index = 0}) {
    return AppAnimations.slideUpFade(
      child: this,
      delay: Duration(milliseconds: 50 * index),
    );
  }

  /// Applies the standard scale-in animation
  Widget animateScaleIn({Duration delay = Duration.zero}) {
    return AppAnimations.scaleIn(child: this, delay: delay);
  }
}
