import 'dart:math';
import 'package:flutter/material.dart';

/// Wraps any widget (e.g., VideoPlayer, PdfViewer) with a dynamic, semi-transparent
/// watermark overlay to deter screenshots and screen recording.
class SecureWatermarkWrapper extends StatelessWidget {
  final Widget child;
  final String userId;
  final String userEmail;
  final String ipAddress;

  const SecureWatermarkWrapper({
    super.key,
    required this.child,
    required this.userId,
    required this.userEmail,
    required this.ipAddress,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // The actual content (e.g., Video or PDF)
        child,
        // The watermark overlay
        IgnorePointer(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return ClipRect(
                child: _WatermarkOverlay(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  text: '$userEmail\nID: $userId\nIP: $ipAddress',
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _WatermarkOverlay extends StatefulWidget {
  final double width;
  final double height;
  final String text;

  const _WatermarkOverlay({
    required this.width,
    required this.height,
    required this.text,
  });

  @override
  State<_WatermarkOverlay> createState() => _WatermarkOverlayState();
}

class _WatermarkOverlayState extends State<_WatermarkOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Slowly animate the watermark to make it harder to edit out
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Generate a grid of watermarks
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Slight movement
        final dx = sin(_controller.value * 2 * pi) * 20;
        final dy = cos(_controller.value * 2 * pi) * 20;

        return Transform.translate(
          offset: Offset(dx, dy),
          child: CustomPaint(
            size: Size(widget.width, widget.height),
            painter: _WatermarkPainter(
              text: widget.text,
            ),
          ),
        );
      },
    );
  }
}

class _WatermarkPainter extends CustomPainter {
  final String text;

  _WatermarkPainter({required this.text});

  @override
  void paint(Canvas canvas, Size size) {
    final textStyle = TextStyle(
      color: Colors.grey.withOpacity(0.15),
      fontSize: 16,
      fontWeight: FontWeight.bold,
    );
    final textSpan = TextSpan(
      text: text,
      style: textStyle,
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout();

    // Draw the text in a grid pattern across the canvas
    const spacing = 150.0;
    for (double x = -100; x < size.width + 100; x += spacing) {
      for (double y = -100; y < size.height + 100; y += spacing) {
        canvas.save();
        canvas.translate(x, y);
        // Rotate -45 degrees for a classic watermark look
        canvas.rotate(-pi / 4);
        textPainter.paint(
          canvas,
          Offset(-textPainter.width / 2, -textPainter.height / 2),
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WatermarkPainter oldDelegate) {
    return oldDelegate.text != text;
  }
}
