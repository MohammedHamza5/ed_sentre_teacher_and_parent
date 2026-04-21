/// Error UI Widgets - مكونات عرض الأخطاء
/// ويدجتس جاهزة لعرض الأخطاء وحالات الفراغ وإعادة المحاولة
library;

import 'package:flutter/material.dart';

import '../../../../core/errors/app_exceptions.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Error View - عرض الخطأ كامل الشاشة
// ═══════════════════════════════════════════════════════════════════════════

/// عرض خطأ كامل الشاشة مع إمكانية إعادة المحاولة
class ErrorView extends StatelessWidget {
  final AppException? exception;
  final String? message;
  final String? icon;
  final VoidCallback? onRetry;
  final String retryLabel;
  final Widget? customAction;

  const ErrorView({
    super.key,
    this.exception,
    this.message,
    this.icon,
    this.onRetry,
    this.retryLabel = 'إعادة المحاولة',
    this.customAction,
  });

  /// عرض خطأ عام
  factory ErrorView.general({
    Key? key,
    String message = 'حدث خطأ غير متوقع',
    VoidCallback? onRetry,
  }) {
    return ErrorView(key: key, message: message, icon: '❌', onRetry: onRetry);
  }

  /// عرض خطأ عدم اتصال
  factory ErrorView.noConnection({Key? key, VoidCallback? onRetry}) {
    return ErrorView(
      key: key,
      exception: const NoInternetException(),
      onRetry: onRetry,
    );
  }

  /// عرض خطأ الخادم
  factory ErrorView.serverError({Key? key, VoidCallback? onRetry}) {
    return ErrorView(
      key: key,
      exception: const ServerException(),
      onRetry: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayIcon = icon ?? exception?.icon ?? '⚠️';
    final displayMessage = message ?? exception?.userMessage ?? 'حدث خطأ';
    final canRetry = exception?.canRetry ?? (onRetry != null);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // الأيقونة
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Text(
                    displayIcon,
                    style: const TextStyle(fontSize: 80),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // الرسالة
            Text(
              displayMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),

            // زر إعادة المحاولة
            if (canRetry && onRetry != null)
              _RetryButton(onPressed: onRetry!, label: retryLabel),

            // إجراء مخصص
            if (customAction != null) ...[
              const SizedBox(height: 16),
              customAction!,
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Empty View - عرض حالة الفراغ
// ═══════════════════════════════════════════════════════════════════════════

/// عرض حالة عدم وجود بيانات
class EmptyView extends StatelessWidget {
  final String icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyView({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  /// لا توجد بيانات
  factory EmptyView.noData({
    Key? key,
    String title = 'لا توجد بيانات',
    String? subtitle,
    Widget? action,
  }) {
    return EmptyView(
      key: key,
      icon: '📭',
      title: title,
      subtitle: subtitle,
      action: action,
    );
  }

  /// لا توجد نتائج بحث
  factory EmptyView.noSearchResults({Key? key, String query = ''}) {
    return EmptyView(
      key: key,
      icon: '🔍',
      title: 'لا توجد نتائج',
      subtitle: query.isNotEmpty ? 'لم يتم العثور على "$query"' : null,
    );
  }

  /// لا توجد طلاب
  factory EmptyView.noStudents({Key? key}) {
    return EmptyView(
      key: key,
      icon: '👥',
      title: 'لا يوجد طلاب',
      subtitle: 'لم يتم إضافة طلاب بعد',
    );
  }

  /// لا توجد واجبات
  factory EmptyView.noAssignments({Key? key}) {
    return EmptyView(
      key: key,
      icon: '📝',
      title: 'لا توجد واجبات',
      subtitle: 'لم يتم إنشاء واجبات بعد',
    );
  }

  /// لا توجد رسائل
  factory EmptyView.noMessages({Key? key}) {
    return EmptyView(
      key: key,
      icon: '💬',
      title: 'لا توجد رسائل',
      subtitle: 'ابدأ محادثة جديدة',
    );
  }

  /// لا توجد إشعارات
  factory EmptyView.noNotifications({Key? key}) {
    return EmptyView(
      key: key,
      icon: '🔔',
      title: 'لا توجد إشعارات',
      subtitle: 'ستظهر الإشعارات هنا',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // الأيقونة
            Text(icon, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 16),

            // العنوان
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),

            // الوصف
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
              ),
            ],

            // الإجراء
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Loading View - عرض التحميل
// ═══════════════════════════════════════════════════════════════════════════

/// عرض حالة التحميل
class LoadingView extends StatelessWidget {
  final String? message;
  final bool showProgress;
  final double? progress;

  const LoadingView({
    super.key,
    this.message,
    this.showProgress = false,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // المؤشر
          if (showProgress && progress != null)
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(value: progress, strokeWidth: 4),
            )
          else
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(),
            ),

          // الرسالة
          if (message != null) ...[
            const SizedBox(height: 24),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],

          // نسبة التقدم
          if (showProgress && progress != null) ...[
            const SizedBox(height: 8),
            Text(
              '${(progress! * 100).toInt()}%',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Async Content Builder - بناء محتوى غير متزامن
// ═══════════════════════════════════════════════════════════════════════════

/// حالات عرض المحتوى
enum AsyncContentState { loading, error, empty, success }

/// بناء محتوى مع معالجة حالات التحميل والخطأ والفراغ
class AsyncContentBuilder<T> extends StatelessWidget {
  final AsyncContentState state;
  final T? data;
  final AppException? error;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;
  final String? loadingMessage;
  final Widget? emptyWidget;
  final Widget? loadingWidget;
  final Widget? errorWidget;

  const AsyncContentBuilder({
    super.key,
    required this.state,
    this.data,
    this.error,
    required this.builder,
    this.onRetry,
    this.loadingMessage,
    this.emptyWidget,
    this.loadingWidget,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case AsyncContentState.loading:
        return loadingWidget ?? LoadingView(message: loadingMessage);

      case AsyncContentState.error:
        return errorWidget ?? ErrorView(exception: error, onRetry: onRetry);

      case AsyncContentState.empty:
        return emptyWidget ?? EmptyView.noData();

      case AsyncContentState.success:
        if (data != null) {
          return builder(data as T);
        }
        return emptyWidget ?? EmptyView.noData();
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Network Status Banner - شريط حالة الشبكة
// ═══════════════════════════════════════════════════════════════════════════

/// شريط يظهر عند انقطاع الاتصال
class NetworkStatusBanner extends StatelessWidget {
  final bool isConnected;
  final VoidCallback? onRetry;

  const NetworkStatusBanner({
    super.key,
    required this.isConnected,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: isConnected ? 0 : 48,
      color: Colors.red[700],
      child: isConnected
          ? const SizedBox()
          : SafeArea(
              bottom: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'لا يوجد اتصال بالإنترنت',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  if (onRetry != null) ...[
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: onRetry,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: const Text('إعادة'),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Retry Button - زر إعادة المحاولة
// ═══════════════════════════════════════════════════════════════════════════

class _RetryButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;

  const _RetryButton({required this.onPressed, required this.label});

  @override
  State<_RetryButton> createState() => _RetryButtonState();
}

class _RetryButtonState extends State<_RetryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePress() {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    _controller.repeat();

    widget.onPressed();

    // إيقاف التحميل بعد ثانية
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _isLoading = false);
        _controller.stop();
        _controller.reset();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _handlePress,
      icon: _isLoading
          ? RotationTransition(
              turns: _controller,
              child: const Icon(Icons.refresh, size: 20),
            )
          : const Icon(Icons.refresh, size: 20),
      label: Text(_isLoading ? 'جارٍ التحميل...' : widget.label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Shimmer Loading - تحميل متلألئ
// ═══════════════════════════════════════════════════════════════════════════

/// تأثير التحميل المتلألئ
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final bool isLoading;

  const ShimmerLoading({super.key, required this.child, this.isLoading = true});

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) return widget.child;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Color(0xFFE0E0E0),
                Color(0xFFF5F5F5),
                Color(0xFFE0E0E0),
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((s) => s.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// عناصر نائبة للتحميل
class ShimmerPlaceholder extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerPlaceholder({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
