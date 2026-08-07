import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui' as ui;

import '../../../../core/config/app_colors.dart';
import '../../../../core/widgets/genius/shimmer_skeleton.dart';

class SmartEnrollmentScreen extends StatefulWidget {
  const SmartEnrollmentScreen({super.key});

  @override
  State<SmartEnrollmentScreen> createState() => _SmartEnrollmentScreenState();
}

class _SmartEnrollmentScreenState extends State<SmartEnrollmentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _handleCodeSubmission(String code) {
    if (code.isEmpty) return;

    setState(() => _isLoading = true);

    // Mock API Call
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSuccessDialog();
      }
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
          side: const BorderSide(color: AppColors.divider),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check, color: Colors.white, size: 32),
            ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
            SizedBox(height: 16.h),
            Text(
              'تم الانضمام بنجاح! 🎉',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'تمت إضافة المركز الجديد إلى قائمة أبنائك.',
              textAlign: TextAlign.center,
              style: TextStyle(color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey), fontSize: 14.sp),
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close Dialog
                Navigator.pop(context); // Close Screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                minimumSize: Size(double.infinity, 44.h),
              ),
              child: Text('حسناً', style: TextStyle(color: Theme.of(context).scaffoldBackgroundColor, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Theme.of(context).colorScheme.surface, // Using Forest Primary for a deeper background
      appBar: AppBar(
        title: Text(
          'تسجيل ذكي',
          style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
          indicatorColor: Theme.of(context).colorScheme.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'مسح QR'),
            Tab(text: 'إدخال الكود'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildQrScannerTab(), _buildManualEntryTab()],
      ),
    );
  }

  Widget _buildQrScannerTab() {
    return Stack(
      alignment: Alignment.center,
      children: [
        MobileScanner(
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              if (barcode.rawValue != null && !_isLoading) {
                _handleCodeSubmission(barcode.rawValue!);
                break; // Only process first code
              }
            }
          },
        ),
        Container(
              width: 250.w,
              height: 250.w,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 4),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _cornerLine(),
                      Transform.rotate(angle: 1.57, child: _cornerLine()),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Transform.rotate(angle: -1.57, child: _cornerLine()),
                      Transform.rotate(angle: 3.14, child: _cornerLine()),
                    ],
                  ),
                ],
              ),
            )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .boxShadow(
              begin: BoxShadow(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                blurRadius: 5,
                spreadRadius: 1,
              ),
              end: BoxShadow(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
                blurRadius: 20,
                spreadRadius: 5,
              ),
              duration: 2.seconds,
            ),
        Positioned(
          bottom: 40.h,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30.r),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(30.r),
                  border: Border.all(color: (Theme.of(context).dividerTheme.color ?? Colors.grey.shade300)),
                ),
                child: Text(
                  'وجه الكاميرا نحو رمز QR للمركز',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_isLoading)
          Container(
            color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.85),
            padding: EdgeInsets.symmetric(horizontal: 28.w),
            child: const Center(
              child: CardShimmerSkeleton(itemCount: 1),
            ),
          ),
      ],
    );
  }

  Widget _cornerLine() {
    return Container(
      width: 40.w,
      height: 40.w,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.primary, width: 6),
          left: BorderSide(color: Theme.of(context).colorScheme.primary, width: 6),
        ),
      ),
    );
  }

  Widget _buildManualEntryTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 40.h),
          Icon(
            Icons.keyboard_alt_outlined,
            size: 80.sp,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
          SizedBox(height: 24.h),
          Text(
            'أدخل رمز الدعوة',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'اطلب الرمز من إدارة المركز التعليمي',
            style: TextStyle(fontSize: 14.sp, color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey)),
          ),
          SizedBox(height: 32.h),
          TextField(
            controller: _codeController,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24.sp,
              letterSpacing: 4,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: 'ABCD-1234',
              hintStyle: TextStyle(color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey).withValues(alpha: 0.5)),
              fillColor: Theme.of(context).colorScheme.surface,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 20.h),
            ),
          ),
          SizedBox(height: 32.h),
          SizedBox(
            width: double.infinity,
            height: 52.h,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () => _handleCodeSubmission(_codeController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.sync_rounded, color: Theme.of(context).scaffoldBackgroundColor, size: 22.sp),
                        SizedBox(width: 10.w),
                        Text(
                          'جاري التحقق وإضافة المركز...',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).scaffoldBackgroundColor,
                          ),
                        ),
                      ],
                    ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(duration: 600.ms)
                  : Text(
                      'انضمام',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).scaffoldBackgroundColor,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

