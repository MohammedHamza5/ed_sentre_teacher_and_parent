import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/config/app_colors.dart';

class SmartEnrollmentScreen extends StatefulWidget {
  const SmartEnrollmentScreen({super.key});

  @override
  State<SmartEnrollmentScreen> createState() => _SmartEnrollmentScreenState();
}

class _SmartEnrollmentScreenState extends State<SmartEnrollmentScreen> with SingleTickerProviderStateMixin {
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 32),
            ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
            SizedBox(height: 16.h),
            Text('تم الانضمام بنجاح! 🎉', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 8.h),
            Text('تمت إضافة المركز الجديد إلى قائمة أبنائك.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp)),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close Dialog
                Navigator.pop(context); // Close Screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                minimumSize: Size(double.infinity, 44.h),
              ),
              child: const Text('حسناً', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('تسجيل ذكي', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'مسح QR'),
            Tab(text: 'إدخال الكود'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildQRScanner_Tab(),
          _buildManualEntry_Tab(),
        ],
      ),
    );
  }

  Widget _buildQRScanner_Tab() {
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
        ).animate(onPlay: (c) => c.repeat(reverse: true)).boxShadow(
          begin: BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 5, spreadRadius: 1),
          end: BoxShadow(color: AppColors.primary.withValues(alpha: 0.6), blurRadius: 20, spreadRadius: 5),
          duration: 2.seconds,
        ),
        Positioned(
          bottom: 40.h,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(30.r),
            ),
            child: const Text(
              'وجه الكاميرا نحو رمز QR للمركز',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          )
      ],
    );
  }

  Widget _cornerLine() {
    return Container(
      width: 40.w,
      height: 40.w,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.primary, width: 6),
          left: BorderSide(color: AppColors.primary, width: 6),
        ),
      ),
    );
  }

  Widget _buildManualEntry_Tab() {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.keyboard_alt_outlined, size: 80.sp, color: AppColors.primary.withValues(alpha: 0.5)),
          SizedBox(height: 24.h),
          Text(
            'أدخل رمز الدعوة',
            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          SizedBox(height: 8.h),
          Text(
            'اطلب الرمز من إدارة المركز التعليمي',
            style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
          ),
          SizedBox(height: 32.h),
          TextField(
            controller: _codeController,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24.sp, letterSpacing: 4, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: 'ABCD-1234',
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 20.h),
            ),
          ),
          SizedBox(height: 32.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : () => _handleCodeSubmission(_codeController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text('انضمام', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
