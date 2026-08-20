import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/app_colors.dart';
import '../../../../core/providers/center_provider.dart';
import '../../provider/teacher_provider.dart';

/// 📷 Teacher Card Scanner Screen
/// Continuous multi-scan screen: teacher points camera at student cards/QR codes.
/// Each scan records attendance via record_student_attendance_by_code RPC.
/// Camera stays open between scans for rapid batch check-in.
class TeacherCardScannerScreen extends StatefulWidget {
  /// Optional: pre-select a group for attendance (from group card button).
  final String? groupId;
  final String? groupName;

  const TeacherCardScannerScreen({
    super.key,
    this.groupId,
    this.groupName,
  });

  @override
  State<TeacherCardScannerScreen> createState() =>
      _TeacherCardScannerScreenState();
}

class _TeacherCardScannerScreenState extends State<TeacherCardScannerScreen>
    with WidgetsBindingObserver {
  MobileScannerController? _scannerController;

  // Per-scan state — does not stop the camera
  bool _isProcessingScan = false;
  bool _isLoadingHistory = true;

  // Rolling list of scanned students this session (most recent first)
  // NOTE: Populated from DB on init so the list survives navigation.
  final List<_ScannedStudentResult> _sessionResults = [];

  // Anti-duplicate: prevents the camera reading the same QR twice
  // within a 3-second window. Cleared on dispose — intentional.
  // A re-entry after the window = hits DB → returns already_marked.
  final Set<String> _recentlyCodes = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestCameraAndStart();
    _loadTodayAttendance();
  }

  /// Restore today's session from DB so the list survives navigation.
  Future<void> _loadTodayAttendance() async {
    try {
      final centerId = context.read<CenterProvider>().currentCenterId;
      if (centerId == null) return;

      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final rows = await Supabase.instance.client
          .from('attendance')
          .select('student_id, students(full_name, student_code), group_id, groups(group_name), status')
          .eq('center_id', centerId)
          .eq('date', todayStr)
          .eq('status', 'present')
          .order('created_at', ascending: false)
          .limit(100);

      if (!mounted) return;

      final loaded = (rows as List).map((row) {
        final studentMap = row['students'] as Map<String, dynamic>?;
        final groupMap = row['groups'] as Map<String, dynamic>?;
        return _ScannedStudentResult.fromHistory(
          studentName: studentMap?['full_name'] as String? ?? 'طالب',
          groupName: groupMap?['group_name'] as String? ?? '—',
        );
      }).toList();

      setState(() {
        _sessionResults.addAll(loaded);
        _isLoadingHistory = false;
      });
    } catch (_) {
      // History load failure is non-critical — scanner still works
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scannerController?.start();
    } else if (state == AppLifecycleState.paused) {
      _scannerController?.stop();
    }
  }

  Future<void> _requestCameraAndStart() async {
    final status = await Permission.camera.request();
    if (!mounted) return;

    if (status.isGranted) {
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
        autoStart: true,
      );
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'يرجى السماح بالوصول للكاميرا لمسح كروت الطلاب',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController?.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Scan Handler
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (_isProcessingScan) return;

    final rawValue = capture.barcodes.firstOrNull?.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    // Debounce: skip if same code was scanned in the last 3s
    if (_recentlyCodes.contains(rawValue)) return;
    _recentlyCodes.add(rawValue);
    Future.delayed(const Duration(seconds: 3), () => _recentlyCodes.remove(rawValue));

    await _processAttendanceCode(rawValue, force: false);
  }

  Future<void> _processAttendanceCode(String code, {required bool force}) async {
    setState(() => _isProcessingScan = true);
    if (!force) HapticFeedback.mediumImpact();

    try {
      final centerId = context.read<CenterProvider>().currentCenterId;
      if (centerId == null) {
        _addResult(_ScannedStudentResult.error(
          code: code,
          message: 'لم يتم تحديد المركز',
        ));
        return;
      }

      final teacherId = context.read<TeacherProvider>().teacherId;

      final response = await Supabase.instance.client.rpc(
        'record_student_attendance_by_code',
        params: {
          'p_center_id': centerId,
          'p_student_code_or_id': code,
          if (widget.groupId != null) 'p_group_id': widget.groupId,
          'p_status': 'present',
          'p_force': force,
          if (teacherId != null) 'p_teacher_id': teacherId,
        },
      );

      if (!mounted) return;

      final data = response as Map<String, dynamic>;
      final success = data['success'] == true;

      if (success) {
        final alreadyMarked = data['already_marked'] == true;
        // NOTE: Only vibrate on a new registration — not on duplicate scan.
        if (!alreadyMarked) HapticFeedback.heavyImpact();
        _addResult(_ScannedStudentResult(
          code: code,
          studentName: data['student_name'] as String? ?? 'طالب',
          groupName: data['group_name'] as String? ?? widget.groupName ?? '—',
          status: alreadyMarked ? _ScanStatus.alreadyMarked : _ScanStatus.success,
          // NOTE: Override the RPC message for already_marked to be user-friendly.
          message: alreadyMarked
              ? 'سبق تسجيل حضوره اليوم ⚠️'
              : 'تم تسجيل الحضور بنجاح ✅',
        ));
      } else {
        final isValidationError = data['validation_error'] == true;
        
        if (isValidationError) {
          // Pause camera explicitly during dialog
          _scannerController?.stop();
          final shouldForce = await _showOverrideDialog(
            studentName: data['student_name'] as String? ?? 'طالب',
            groupName: data['group_name'] as String? ?? '—',
            reason: data['message'] as String? ?? 'غير محدد',
          );
          
          if (!mounted) return;
          _scannerController?.start();

          if (shouldForce == true) {
            // Re-call forcing the attendance
            await _processAttendanceCode(code, force: true);
            return; // Exit this execution flow since the recursive call handles the result
          } else {
            _addResult(_ScannedStudentResult.error(
              code: code,
              message: 'تم إلغاء التسجيل: ${data['message']}',
            ));
          }
        } else {
          _addResult(_ScannedStudentResult.error(
            code: code,
            message: data['message'] as String? ?? 'فشل تسجيل الحضور',
          ));
        }
      }
    } catch (e) {
      if (!mounted) return;
      _addResult(_ScannedStudentResult.error(
        code: code,
        message: 'خطأ: ${e.toString().split('\n').first}',
      ));
    } finally {
      if (mounted) setState(() => _isProcessingScan = false);
    }
  }

  Future<bool?> _showOverrideDialog({
    required String studentName,
    required String groupName,
    required String reason,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.navyMid,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
            SizedBox(width: 10.w),
            Text('تنبيه جدول الحضور', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18.sp)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الطالب: $studentName', style: GoogleFonts.cairo(color: Colors.white, fontSize: 16.sp)),
            Text('المجموعة: $groupName', style: GoogleFonts.cairo(color: Colors.white70, fontSize: 14.sp)),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8.r)),
              child: Text(reason, style: GoogleFonts.cairo(color: AppColors.warning, fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 12.h),
            Text('هل تريد تأكيد حضور الطالب بالرغم من ذلك؟', style: GoogleFonts.cairo(color: Colors.white)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.teacherPrimary, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('تأكيد الحضور الاستثنائي', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }


  void _addResult(_ScannedStudentResult result) {
    setState(() => _sessionResults.insert(0, result));
  }

  // ──────────────────────────────────────────────────────────────────────────
  // UI
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Count includes both fresh scans AND history-loaded records.
    final presentCount = _sessionResults
        .where((r) => r.status == _ScanStatus.success || r.status == _ScanStatus.fromHistory)
        .length;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'مسح كروت الحضور',
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 17.sp,
              ),
            ),
            if (widget.groupName != null)
              Text(
                widget.groupName!,
                style: GoogleFonts.cairo(
                  color: Colors.white54,
                  fontSize: 12.sp,
                ),
              ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Torch toggle
          if (_scannerController != null)
            IconButton(
              icon: Icon(Icons.flash_on, color: Colors.white, size: 24.sp),
              tooltip: 'تشغيل الفلاش',
              onPressed: () => _scannerController?.toggleTorch(),
            ),
          // Session summary badge
          Padding(
            padding: EdgeInsets.only(right: 12.w),
            child: Chip(
              backgroundColor: AppColors.success.withValues(alpha: 0.2),
              label: Text(
                '$presentCount حاضر',
                style: GoogleFonts.cairo(
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp,
                ),
              ),
              avatar: Icon(Icons.check_circle, color: AppColors.success, size: 16.sp),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Camera View (top ~55% of screen)
          Expanded(
            flex: 55,
            child: _buildCameraSection(),
          ),

          // ── Results Panel (bottom ~45%)
          Expanded(
            flex: 45,
            child: _buildResultsPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraSection() {
    if (_scannerController == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Stack(
      children: [
        // Camera feed
        MobileScanner(
          controller: _scannerController!,
          onDetect: _onBarcodeDetected,
        ),

        // Semi-transparent overlay with scan frame
        _buildScanOverlay(),

        // Processing indicator
        if (_isProcessingScan)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 3,
                ),
              ),
            ),
          ),

        // Instruction label
        Positioned(
          bottom: 16.h,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                'وجّه الكاميرا نحو كارت الطالب أو QR Code',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 13.sp,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScanOverlay() {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        Colors.black.withValues(alpha: 0.5),
        BlendMode.srcOut,
      ),
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.black,
              backgroundBlendMode: BlendMode.dstOut,
            ),
          ),
          Center(
            child: Container(
              width: 260.w,
              height: 200.w,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsPanel() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Column(
        children: [
          // Panel handle + title
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            child: Row(
              children: [
                Icon(Icons.list_alt_rounded, color: Colors.white70, size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  'سجل جلسة اليوم (${_sessionResults.length})',
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15.sp,
                  ),
                ),
                const Spacer(),
                if (_sessionResults.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => setState(() => _sessionResults.clear()),
                    icon: Icon(Icons.delete_sweep_rounded, size: 18.sp, color: Colors.red.shade300),
                    label: Text(
                      'مسح',
                      style: GoogleFonts.cairo(color: Colors.red.shade300, fontSize: 13.sp),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),

          // Results list
          Expanded(
            child: _sessionResults.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    itemCount: _sessionResults.length,
                    itemBuilder: (context, index) =>
                        _buildResultTile(_sessionResults[index], index),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_isLoadingHistory) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white24, strokeWidth: 2),
      );
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.qr_code_scanner, color: Colors.white24, size: 48.sp),
          SizedBox(height: 12.h),
          Text(
            'ابدأ المسح — ستظهر النتائج هنا',
            style: GoogleFonts.cairo(color: Colors.white38, fontSize: 14.sp),
          ),
          SizedBox(height: 6.h),
          Text(
            'لا يوجد حضور مسجّل اليوم بعد',
            style: GoogleFonts.cairo(color: Colors.white24, fontSize: 12.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildResultTile(_ScannedStudentResult result, int index) {
    final Color tileColor;
    final Color iconColor;
    final IconData icon;

    switch (result.status) {
      case _ScanStatus.success:
        tileColor = AppColors.success.withValues(alpha: 0.15);
        iconColor = AppColors.success;
        icon = Icons.check_circle_rounded;
      case _ScanStatus.alreadyMarked:
        tileColor = AppColors.warning.withValues(alpha: 0.15);
        iconColor = AppColors.warning;
        icon = Icons.warning_amber_rounded;
      case _ScanStatus.fromHistory:
        tileColor = Colors.white.withValues(alpha: 0.05);
        iconColor = Colors.white38;
        icon = Icons.history_rounded;
      case _ScanStatus.error:
        tileColor = AppColors.error.withValues(alpha: 0.15);
        iconColor = AppColors.error;
        icon = Icons.cancel_rounded;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: iconColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.studentName,
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
                Text(
                  result.message,
                  style: GoogleFonts.cairo(
                    color: Colors.white60,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
          if (result.groupName.isNotEmpty && result.groupName != '—')
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                result.groupName,
                style: GoogleFonts.cairo(
                  color: iconColor,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: index == 0 ? 0 : 50))
        .fadeIn(duration: 250.ms)
        .slideY(begin: -0.1, end: 0);
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Data Models (local — no need for full feature layer for this simple output)
// ──────────────────────────────────────────────────────────────────────────

// NOTE: fromHistory = loaded from DB on screen init (survived navigation)
// alreadyMarked = scanned again, DB confirmed already registered today
enum _ScanStatus { success, alreadyMarked, fromHistory, error }

class _ScannedStudentResult {
  final String code;
  final String studentName;
  final String groupName;
  final _ScanStatus status;
  final String message;

  const _ScannedStudentResult({
    required this.code,
    required this.studentName,
    required this.groupName,
    required this.status,
    required this.message,
  });

  factory _ScannedStudentResult.error({
    required String code,
    required String message,
  }) => _ScannedStudentResult(
        code: code,
        studentName: 'كود غير معروف',
        groupName: '—',
        status: _ScanStatus.error,
        message: message,
      );

  factory _ScannedStudentResult.fromHistory({
    required String studentName,
    required String groupName,
  }) => _ScannedStudentResult(
        code: '',
        studentName: studentName,
        groupName: groupName,
        status: _ScanStatus.fromHistory,
        message: 'حاضر (من سجل اليوم)',
      );
}
