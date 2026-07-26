import 'package:flutter/material.dart';

/// ═════════════════════════════════════════════════════════════════════════════
/// ADVANCED APP SPACING (8-pt Grid System & Ergonomic Tap Targets)
/// Enforces Section 12.2 & 12.3 of Universal AI Engineering Contract.
/// ═════════════════════════════════════════════════════════════════════════════
class AppSpacing {
  AppSpacing._(); // Prevent instantiation

  // ── Core Dimensions (8-pt & 4-pt Grid) ──────────────────────────────────
  static const double xxxs = 2.0;
  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 40.0;
  static const double huge = 48.0;
  static const double massive = 64.0;

  // ── Ergonomic Minimum Tap Target Size (Accessibility Standard) ──────────
  static const double minTapTarget = 48.0;
  static const double touchTargetMin = 48.0;
  static const Size tapTargetSize = Size(48.0, 48.0);

  // ── Standard Border Radius Values ───────────────────────────────────────
  static const double radiusXs = 6.0;
  static const double radiusSm = 12.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 20.0;
  static const double radiusXl = 24.0;
  static const double radiusCircular = 999.0;

  static const BorderRadius borderRadiusXs = BorderRadius.all(Radius.circular(radiusXs));
  static const BorderRadius borderRadiusSm = BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius borderRadiusMd = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius borderRadiusLg = BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius borderRadiusXl = BorderRadius.all(Radius.circular(radiusXl));
  static const BorderRadius borderRadiusCircular = BorderRadius.all(Radius.circular(radiusCircular));

  // ── Ready-to-Use Vertical Gaps (SizedBox) ──────────────────────────────
  static const Widget gapH2 = SizedBox(height: xxxs);
  static const Widget gapH4 = SizedBox(height: xxs);
  static const Widget gapH6 = SizedBox(height: 6.0);
  static const Widget gapH8 = SizedBox(height: xs);
  static const Widget gapH12 = SizedBox(height: sm);
  static const Widget gapH16 = SizedBox(height: md);
  static const Widget gapH20 = SizedBox(height: lg);
  static const Widget gapH24 = SizedBox(height: xl);
  static const Widget gapH32 = SizedBox(height: xxl);
  static const Widget gapH40 = SizedBox(height: xxxl);
  static const Widget gapH48 = SizedBox(height: huge);
  static const Widget gapH64 = SizedBox(height: massive);

  // ── Ready-to-Use Horizontal Gaps (SizedBox) ────────────────────────────
  static const Widget gapW2 = SizedBox(width: xxxs);
  static const Widget gapW4 = SizedBox(width: xxs);
  static const Widget gapW8 = SizedBox(width: xs);
  static const Widget gapW12 = SizedBox(width: sm);
  static const Widget gapW16 = SizedBox(width: md);
  static const Widget gapW20 = SizedBox(width: lg);
  static const Widget gapW24 = SizedBox(width: xl);
  static const Widget gapW32 = SizedBox(width: xxl);

  // ── Standardized Edge Insets (Padding & Margin) ────────────────────────
  static const EdgeInsets paddingZero = EdgeInsets.zero;
  static const EdgeInsets paddingAll4 = EdgeInsets.all(xxs);
  static const EdgeInsets paddingAll8 = EdgeInsets.all(xs);
  static const EdgeInsets paddingAll12 = EdgeInsets.all(sm);
  static const EdgeInsets paddingAll16 = EdgeInsets.all(md);
  static const EdgeInsets paddingAll20 = EdgeInsets.all(lg);
  static const EdgeInsets paddingAll24 = EdgeInsets.all(xl);

  // Horizontal Insets
  static const EdgeInsets paddingH8 = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets paddingH12 = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets paddingH16 = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets paddingH20 = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets paddingH24 = EdgeInsets.symmetric(horizontal: xl);

  // Vertical Insets
  static const EdgeInsets paddingV4 = EdgeInsets.symmetric(vertical: xxs);
  static const EdgeInsets paddingV8 = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets paddingV12 = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets paddingV16 = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets paddingV20 = EdgeInsets.symmetric(vertical: lg);

  // Symmetric Insets
  static const EdgeInsets paddingH16V8 = EdgeInsets.symmetric(horizontal: md, vertical: xs);
  static const EdgeInsets paddingH16V12 = EdgeInsets.symmetric(horizontal: md, vertical: sm);
  static const EdgeInsets paddingH20V16 = EdgeInsets.symmetric(horizontal: lg, vertical: md);

  // Card & Dialog Standard Padding
  static const EdgeInsets cardInner = EdgeInsets.all(md);
  static const EdgeInsets cardOuter = EdgeInsets.symmetric(horizontal: md, vertical: xs);
  static const EdgeInsets screenHeader = EdgeInsets.fromLTRB(md, lg, md, xs);
  static const EdgeInsets formFieldSpacing = EdgeInsets.only(bottom: md);
}
