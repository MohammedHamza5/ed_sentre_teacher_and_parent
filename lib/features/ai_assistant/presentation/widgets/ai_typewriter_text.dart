import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/config/app_colors.dart';

class AITypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final bool animate;
  final VoidCallback? onTextUpdated;
  final VoidCallback? onComplete;

  const AITypewriterText({
    super.key,
    required this.text,
    required this.style,
    this.animate = true,
    this.onTextUpdated,
    this.onComplete,
  });

  @override
  State<AITypewriterText> createState() => _AITypewriterTextState();
}

class _AITypewriterTextState extends State<AITypewriterText>
    with SingleTickerProviderStateMixin {
  late String _displayedText;
  Timer? _timer;
  int _currentIndex = 0;
  bool _isTypingComplete = false;

  late AnimationController _cursorController;

  @override
  void initState() {
    super.initState();

    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    if (!widget.animate) {
      _displayedText = widget.text;
      _isTypingComplete = true;
    } else {
      _displayedText = '';
      _startTyping();
    }
  }

  @override
  void didUpdateWidget(covariant AITypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      if (!widget.animate) {
        _displayedText = widget.text;
        _isTypingComplete = true;
      } else {
        _timer?.cancel();
        _currentIndex = 0;
        _displayedText = '';
        _isTypingComplete = false;
        _startTyping();
      }
    }
  }

  void _startTyping() {
    if (widget.text.isEmpty) {
      setState(() {
        _isTypingComplete = true;
      });
      widget.onComplete?.call();
      return;
    }

    // Type chunk by chunk for ultra-smooth & fast streaming
    const interval = Duration(milliseconds: 16); // ~60fps smooth typing
    const stepSize = 2; // 2 chars per tick for responsive speed

    _timer = Timer.periodic(interval, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_currentIndex < widget.text.length) {
        final nextIndex = (_currentIndex + stepSize).clamp(0, widget.text.length);
        setState(() {
          _displayedText = widget.text.substring(0, nextIndex);
          _currentIndex = nextIndex;
        });

        widget.onTextUpdated?.call();

        if (_currentIndex >= widget.text.length) {
          timer.cancel();
          setState(() {
            _isTypingComplete = true;
          });
          widget.onComplete?.call();
        }
      } else {
        timer.cancel();
        setState(() {
          _isTypingComplete = true;
        });
        widget.onComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cursorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SelectableText.rich(
          TextSpan(
            children: [
              TextSpan(text: _displayedText, style: widget.style),
              if (!_isTypingComplete)
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: AnimatedBuilder(
                    animation: _cursorController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _cursorController.value,
                        child: Container(
                          margin: EdgeInsets.only(right: 3.w),
                          width: 8.w,
                          height: 14.h,
                          decoration: BoxDecoration(
                            color: AppColors.teal,
                            borderRadius: BorderRadius.circular(2.r),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.teal.withValues(alpha: 0.8),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
