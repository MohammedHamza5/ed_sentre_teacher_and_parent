import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

extension PremiumAnimations on Widget {
  Widget animateFadeSlide({int delay = 0}) {
    return animate(
      delay: Duration(milliseconds: delay),
    ).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget animateScaleIn({int delay = 0}) {
    return animate(delay: Duration(milliseconds: delay))
        .fadeIn(duration: 300.ms)
        .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1));
  }

  Widget animateSlideRight({int delay = 0}) {
    return animate(
      delay: Duration(milliseconds: delay),
    ).fadeIn(duration: 400.ms).slideX(begin: 0.1, end: 0);
  }
}
