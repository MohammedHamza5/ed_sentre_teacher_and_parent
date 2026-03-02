/// Network Monitor - مراقب حالة الشبكة
/// يراقب حالة الاتصال ويوفر واجهة للتفاعل معها
library;

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Network Monitor - مراقب الشبكة
// ═══════════════════════════════════════════════════════════════════════════

class NetworkMonitor extends ChangeNotifier {
  static NetworkMonitor? _instance;
  static NetworkMonitor get instance => _instance ??= NetworkMonitor._();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isConnected = true;
  bool _wasConnected = true;
  ConnectivityResult _connectionType = ConnectivityResult.none;
  DateTime? _lastDisconnectedAt;
  DateTime? _lastReconnectedAt;

  NetworkMonitor._() {
    _init();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Getters
  // ─────────────────────────────────────────────────────────────────────────

  /// هل متصل؟
  bool get isConnected => _isConnected;

  /// هل كان متصلاً؟
  bool get wasConnected => _wasConnected;

  /// نوع الاتصال
  ConnectivityResult get connectionType => _connectionType;

  /// هل على WiFi؟
  bool get isOnWifi => _connectionType == ConnectivityResult.wifi;

  /// هل على بيانات الجوال؟
  bool get isOnMobile => _connectionType == ConnectivityResult.mobile;

  /// وقت آخر انقطاع
  DateTime? get lastDisconnectedAt => _lastDisconnectedAt;

  /// وقت آخر اتصال
  DateTime? get lastReconnectedAt => _lastReconnectedAt;

  /// مدة الانقطاع (إذا كان غير متصل)
  Duration? get disconnectionDuration {
    if (_isConnected || _lastDisconnectedAt == null) return null;
    return DateTime.now().difference(_lastDisconnectedAt!);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Initialization
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _init() async {
    // التحقق الأولي
    final results = await _connectivity.checkConnectivity();
    _updateConnectionStatus(results);

    // الاستماع للتغييرات
    _subscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    _wasConnected = _isConnected;

    // اختيار أفضل نوع اتصال
    if (results.contains(ConnectivityResult.wifi)) {
      _connectionType = ConnectivityResult.wifi;
      _isConnected = true;
    } else if (results.contains(ConnectivityResult.mobile)) {
      _connectionType = ConnectivityResult.mobile;
      _isConnected = true;
    } else if (results.contains(ConnectivityResult.ethernet)) {
      _connectionType = ConnectivityResult.ethernet;
      _isConnected = true;
    } else {
      _connectionType = ConnectivityResult.none;
      _isConnected = false;
    }

    // تحديث الأوقات
    if (!_isConnected && _wasConnected) {
      _lastDisconnectedAt = DateTime.now();
    } else if (_isConnected && !_wasConnected) {
      _lastReconnectedAt = DateTime.now();
    }

    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Methods
  // ─────────────────────────────────────────────────────────────────────────

  /// التحقق يدوياً من الاتصال
  Future<bool> checkConnection() async {
    final results = await _connectivity.checkConnectivity();
    _updateConnectionStatus(results);
    return _isConnected;
  }

  /// انتظار حتى يتوفر الاتصال
  Future<void> waitForConnection({Duration? timeout}) async {
    if (_isConnected) return;

    final completer = Completer<void>();
    Timer? timer;

    void listener() {
      if (_isConnected && !completer.isCompleted) {
        completer.complete();
        timer?.cancel();
        removeListener(listener);
      }
    }

    addListener(listener);

    if (timeout != null) {
      timer = Timer(timeout, () {
        if (!completer.isCompleted) {
          completer.completeError(
            TimeoutException('انتهت مهلة انتظار الاتصال'),
          );
          removeListener(listener);
        }
      });
    }

    return completer.future;
  }

  /// اسم نوع الاتصال بالعربية
  String get connectionTypeName {
    switch (_connectionType) {
      case ConnectivityResult.wifi:
        return 'واي فاي';
      case ConnectivityResult.mobile:
        return 'بيانات الجوال';
      case ConnectivityResult.ethernet:
        return 'كابل إنترنت';
      case ConnectivityResult.bluetooth:
        return 'بلوتوث';
      case ConnectivityResult.vpn:
        return 'VPN';
      default:
        return 'غير متصل';
    }
  }

  /// أيقونة نوع الاتصال
  IconData get connectionIcon {
    switch (_connectionType) {
      case ConnectivityResult.wifi:
        return Icons.wifi;
      case ConnectivityResult.mobile:
        return Icons.signal_cellular_alt;
      case ConnectivityResult.ethernet:
        return Icons.cable;
      case ConnectivityResult.bluetooth:
        return Icons.bluetooth;
      case ConnectivityResult.vpn:
        return Icons.vpn_key;
      default:
        return Icons.wifi_off;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Network Aware Builder - بناء حسب حالة الشبكة
// ═══════════════════════════════════════════════════════════════════════════

/// ويدجت يبني حسب حالة الشبكة
class NetworkAwareBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, bool isConnected) builder;
  final Widget? offlineWidget;

  const NetworkAwareBuilder({
    super.key,
    required this.builder,
    this.offlineWidget,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: NetworkMonitor.instance,
      builder: (context, _) {
        final isConnected = NetworkMonitor.instance.isConnected;

        if (!isConnected && offlineWidget != null) {
          return offlineWidget!;
        }

        return builder(context, isConnected);
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Network Status Listener - مستمع حالة الشبكة
// ═══════════════════════════════════════════════════════════════════════════

/// ويدجت يستمع لتغييرات الشبكة
class NetworkStatusListener extends StatefulWidget {
  final Widget child;
  final void Function(bool isConnected)? onStatusChanged;
  final void Function()? onConnected;
  final void Function()? onDisconnected;

  const NetworkStatusListener({
    super.key,
    required this.child,
    this.onStatusChanged,
    this.onConnected,
    this.onDisconnected,
  });

  @override
  State<NetworkStatusListener> createState() => _NetworkStatusListenerState();
}

class _NetworkStatusListenerState extends State<NetworkStatusListener> {
  bool _wasConnected = true;

  @override
  void initState() {
    super.initState();
    NetworkMonitor.instance.addListener(_onNetworkChange);
    _wasConnected = NetworkMonitor.instance.isConnected;
  }

  @override
  void dispose() {
    NetworkMonitor.instance.removeListener(_onNetworkChange);
    super.dispose();
  }

  void _onNetworkChange() {
    final isConnected = NetworkMonitor.instance.isConnected;

    if (isConnected != _wasConnected) {
      widget.onStatusChanged?.call(isConnected);

      if (isConnected) {
        widget.onConnected?.call();
      } else {
        widget.onDisconnected?.call();
      }

      _wasConnected = isConnected;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// ═══════════════════════════════════════════════════════════════════════════
// Offline Overlay - طبقة عدم الاتصال
// ═══════════════════════════════════════════════════════════════════════════

/// طبقة تظهر فوق المحتوى عند انقطاع الاتصال
class OfflineOverlay extends StatelessWidget {
  final Widget child;
  final Widget? overlay;
  final bool showOverlay;

  const OfflineOverlay({
    super.key,
    required this.child,
    this.overlay,
    this.showOverlay = true,
  });

  @override
  Widget build(BuildContext context) {
    return NetworkAwareBuilder(
      builder: (context, isConnected) {
        return Stack(
          children: [
            child,
            if (!isConnected && showOverlay)
              Positioned.fill(
                child:
                    overlay ??
                    Container(
                      color: Colors.black54,
                      child: Center(
                        child: Card(
                          margin: const EdgeInsets.all(32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.wifi_off,
                                  size: 64,
                                  color: Colors.red,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'لا يوجد اتصال بالإنترنت',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'تحقق من اتصالك بالإنترنت وحاول مرة أخرى',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: Colors.grey[600]),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    NetworkMonitor.instance.checkConnection();
                                  },
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('إعادة المحاولة'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
              ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Connection Quality Indicator - مؤشر جودة الاتصال
// ═══════════════════════════════════════════════════════════════════════════

/// مؤشر يعرض جودة/نوع الاتصال
class ConnectionQualityIndicator extends StatelessWidget {
  final bool showLabel;
  final double iconSize;

  const ConnectionQualityIndicator({
    super.key,
    this.showLabel = true,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: NetworkMonitor.instance,
      builder: (context, _) {
        final monitor = NetworkMonitor.instance;
        final color = monitor.isConnected ? Colors.green : Colors.red;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(monitor.connectionIcon, size: iconSize, color: color),
            if (showLabel) ...[
              const SizedBox(width: 4),
              Text(
                monitor.connectionTypeName,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
