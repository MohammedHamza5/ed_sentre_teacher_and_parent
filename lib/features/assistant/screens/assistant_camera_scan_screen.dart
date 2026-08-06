import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../../features/auth/provider/auth_provider.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/drawer/drawer_logout_dialog.dart';
import '../presentation/widgets/student_action_bottom_sheet.dart';

class AssistantCameraScanScreen extends StatefulWidget {
  const AssistantCameraScanScreen({super.key});

  @override
  State<AssistantCameraScanScreen> createState() =>
      _AssistantCameraScanScreenState();
}

class _AssistantCameraScanScreenState extends State<AssistantCameraScanScreen> {
  late final MobileScannerController _scannerController;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
      );
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      _scannerController.dispose();
    }
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    setState(() => _isProcessing = true);
    _scannerController.pause();

    final studentId = code;
    const activeSessionId = '00000000-0000-0000-0000-000000000000';

    await StudentActionBottomSheet.show(
      context,
      studentId: studentId,
      studentName: 'جاري التحقق من بيانات الطالب...',
      sessionId: activeSessionId,
    );

    if (mounted) {
      setState(() => _isProcessing = false);
      _scannerController.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    // NOTE: MobileScanner is unavailable on web — show a rich Web Command Dashboard.
    if (kIsWeb) {
      return _buildWebFallback(context);
    }
    return _buildMobileScanner(context);
  }

  Widget _buildWebFallback(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          tooltip: 'القائمة',
          onPressed: openAssistantDrawer,
        ),
        title: const Text(
          'لوحة المساعد الميداني',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: 'تسجيل الخروج',
            onPressed: () => confirmDrawerLogout(
              context,
              context.read<AuthProvider>(),
            ),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 540),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colorScheme.outline.withOpacity(0.12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.qr_code_scanner_rounded,
                    size: 46,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'وضع التشغيل عبر الحاسب (Web)',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'كاميرا المسح السريع مخصصة لتطبيقات الهواتف والتابلت. أثناء التواجد على الويب، يمكنك إنجاز نفس المهام بالسرعة المطلوبة عبر أدوات البحث والقاعات المتطورة:',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                    height: 1.6,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),

                // Primary Action: Manual Lookup
                ElevatedButton.icon(
                  onPressed: () => context.go('/assistant/manual-lookup'),
                  icon: const Icon(Icons.person_search_rounded, size: 24),
                  label: const Text(
                    'البحث اليدوي عن طالب (تسجيل حضور / سداد)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Secondary Action: Live Rooms
                OutlinedButton.icon(
                  onPressed: () => context.go('/assistant/rooms'),
                  icon: const Icon(Icons.meeting_room_rounded, size: 24),
                  label: const Text(
                    'مراقبة حالة القاعات المباشرة',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    side: BorderSide(
                      color: colorScheme.primary.withOpacity(0.5),
                      width: 1.5,
                    ),
                    foregroundColor: colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Divider(color: colorScheme.outline.withOpacity(0.1)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bolt_rounded,
                      color: colorScheme.tertiary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'نظام التزامن اللحظي فعال ومتصل بالسنتر',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileScanner(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          MobileScanner(controller: _scannerController, onDetect: _onDetect),
          Container(
            decoration: ShapeDecoration(
              shape: QrScannerOverlayShape(
                borderColor: colorScheme.primary,
                borderRadius: 20,
                borderLength: 40,
                borderWidth: 8,
                cutOutSize: MediaQuery.of(context).size.width * 0.72,
              ),
            ),
          ),

          // Floating Top Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Status Pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.qr_code_scanner_rounded,
                          color: Color(0xFF10B981),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'الماسح السريع يعمل',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Action Buttons (Menu, Torch, Switch, Logout)
                  Row(
                    children: [
                      _buildHeaderButton(
                        onTap: openAssistantDrawer,
                        child: const Icon(
                          Icons.menu_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildHeaderButton(
                        onTap: () => _scannerController.toggleTorch(),
                        child: ValueListenableBuilder(
                          valueListenable: _scannerController,
                          builder: (context, state, child) {
                            final isOn = state.torchState == TorchState.on;
                            return Icon(
                              isOn
                                  ? Icons.flash_on_rounded
                                  : Icons.flash_off_rounded,
                              color: isOn
                                  ? const Color(0xFFFBBF24)
                                  : Colors.white,
                              size: 24,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildHeaderButton(
                        onTap: () => _scannerController.switchCamera(),
                        child: const Icon(
                          Icons.flip_camera_ios_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildHeaderButton(
                        onTap: () => confirmDrawerLogout(
                          context,
                          context.read<AuthProvider>(),
                        ),
                        child: const Icon(
                          Icons.logout_rounded,
                          color: Colors.redAccent,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bottom Hint instruction text over scanner
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: const Text(
                  'قم بتوجيه كاميرا الهاتف نحو كود الطالب (QR Code)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),

          // Processing Overlay
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.75),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: colorScheme.primary),
                      const SizedBox(height: 16),
                      Text(
                        'جاري فحص وتجهيز الكارت...',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton({
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Material(
      color: Colors.black.withOpacity(0.65),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth * t,
      overlayColor: overlayColor,
      borderRadius: borderRadius * t,
      borderLength: borderLength * t,
      cutOutSize: cutOutSize * t,
    );
  }

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10.0);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return getLeftTopPath(rect)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.top);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;
    final borderOffset = borderWidth / 2;
    final mBorderLength = borderLength > cutOutSize / 2
        ? cutOutSize / 2
        : borderLength;
    final mBorderRadius = borderRadius > cutOutSize / 2
        ? cutOutSize / 2
        : borderRadius;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final cutOutRect = Rect.fromLTWH(
      rect.left + width / 2 - cutOutSize / 2 + borderOffset,
      rect.top + height / 2 - cutOutSize / 2 + borderOffset,
      cutOutSize - borderOffset * 2,
      cutOutSize - borderOffset * 2,
    );

    canvas.saveLayer(
      Rect.fromLTWH(rect.left, rect.top, width, height),
      Paint(),
    );

    canvas.drawRect(
      Rect.fromLTWH(rect.left, rect.top, width, height),
      backgroundPaint,
    );

    canvas.drawRect(cutOutRect, Paint()..blendMode = BlendMode.clear);

    canvas.restore();

    // Draw custom corner brackets
    final r = mBorderRadius;
    final l = mBorderLength;
    final t = cutOutRect.top;
    final b = cutOutRect.bottom;
    final left = cutOutRect.left;
    final right = cutOutRect.right;

    final cornerPath = Path()
      // Top-Left
      ..moveTo(left, t + l)
      ..lineTo(left, t + r)
      ..arcToPoint(Offset(left + r, t), radius: Radius.circular(r))
      ..lineTo(left + l, t)
      // Top-Right
      ..moveTo(right - l, t)
      ..lineTo(right - r, t)
      ..arcToPoint(Offset(right, t + r), radius: Radius.circular(r))
      ..lineTo(right, t + l)
      // Bottom-Right
      ..moveTo(right, b - l)
      ..lineTo(right, b - r)
      ..arcToPoint(Offset(right - r, b), radius: Radius.circular(r))
      ..lineTo(right - l, b)
      // Bottom-Left
      ..moveTo(left + l, b)
      ..lineTo(left + r, b)
      ..arcToPoint(Offset(left, b - r), radius: Radius.circular(r))
      ..lineTo(left, b - l);

    canvas.drawPath(cornerPath, borderPaint);
  }
}
