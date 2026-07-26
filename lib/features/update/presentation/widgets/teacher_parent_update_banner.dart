import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/network_monitor.dart';
import '../providers/update_provider.dart';

/// Banner widget for displaying update notification with Offline & Data Sync Protection
class TeacherParentUpdateBanner extends StatelessWidget {
  const TeacherParentUpdateBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UpdateProvider>(
      builder: (context, updateProvider, _) {
        final status = updateProvider.status;
        final info = updateProvider.updateInfo;

        if (status == UpdateStatus.initial ||
            status == UpdateStatus.checking ||
            status == UpdateStatus.notAvailable ||
            info == null) {
          return const SizedBox.shrink();
        }

        final isConnected = NetworkMonitor.instance.isConnected;

        return Container(
          width: double.infinity,
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          padding: EdgeInsets.all(14.r),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primaryContainer,
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.85),
              ],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    info.isMandatory ? Icons.system_update_alt : Icons.tips_and_updates,
                    color: Theme.of(context).colorScheme.primary,
                    size: 26.sp,
                    semanticLabel: 'أيقونة التحديث',
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      info.isMandatory ? 'تحديث ضروري متاح (${info.version})' : 'تحديث جديد متوفر (${info.version})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                info.changelogAr ?? 'تحسينات جديدة على سرعة واستقرار مزامنة الجداول والتقارير الأكاديمية.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.9),
                    ),
              ),
              if (!isConnected && status == UpdateStatus.available) ...[
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Icon(Icons.wifi_off, size: 18.sp, color: Theme.of(context).colorScheme.error),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        'لا يمكن تحميل التحديث الآن لعدم توفر اتصال نشط بالإنترنت.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
              if (status == UpdateStatus.downloading) ...[
                SizedBox(height: 12.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: LinearProgressIndicator(
                    value: updateProvider.progress > 0 ? updateProvider.progress : null,
                    minHeight: 8.h,
                    backgroundColor: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'جاري تنزيل ملف التحديث بأمان... ${(updateProvider.progress * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                ),
              ],
              if (status == UpdateStatus.failure) ...[
                SizedBox(height: 8.h),
                Text(
                  updateProvider.errorMessage ?? 'حدث خطأ أثناء تنزيل التحديث',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
              SizedBox(height: 12.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!info.isMandatory && status == UpdateStatus.available)
                    TextButton(
                      onPressed: () {
                        updateProvider.reset();
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      ),
                      child: Text(
                        'تأجيل',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  SizedBox(width: 8.w),
                  ElevatedButton.icon(
                    onPressed: (status == UpdateStatus.downloading || (!isConnected && status == UpdateStatus.available))
                        ? null
                        : () {
                            if (status == UpdateStatus.readyToInstall || status == UpdateStatus.failure && updateProvider.filePath != null) {
                              updateProvider.installUpdate();
                            } else {
                              updateProvider.downloadUpdate();
                            }
                          },
                    icon: Icon(
                      status == UpdateStatus.readyToInstall ? Icons.install_mobile : Icons.download,
                      size: 20.sp,
                    ),
                    label: Text(
                      status == UpdateStatus.readyToInstall
                          ? 'تثبيت الآن'
                          : (status == UpdateStatus.failure && updateProvider.filePath == null)
                              ? 'إعادة المحاولة'
                              : 'تحديث الآن',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
