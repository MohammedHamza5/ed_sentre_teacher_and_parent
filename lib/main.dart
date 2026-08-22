import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/config/supabase_config.dart';
import 'core/config/app_theme.dart';
import 'core/providers/providers.dart';

import 'core/errors/error_handler.dart';
import 'core/services/network_monitor.dart';
import 'core/services/notification_service.dart';
import 'core/services/shorebird_update_service.dart';
import 'core/utils/app_logger.dart';
import 'shared/data/supabase_repository.dart';
import 'demo/mock_supabase_repository.dart';
import 'core/config/app_config.dart';
import 'shared/widgets/error_widgets.dart';
import 'core/router/app_router.dart';
import 'core/di/setup_di.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

// https://supabase.com/dashboard/project/mbmqrmgdgygznbqvvfqi // MCP Supabase

// NOTE: يجب أن تكون top-level function وليست method داخل class
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('🔔 [FCM Background] ${message.notification?.title}');
}

void main() async {
  // التقاط الأخطاء في Zone آمن
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // إعداد معلومات الإصدار للتطبيق
      await AppConfig.initVersion();

      // إعداد DI للتطبيق وللميزات مثل ExamGenerator
      await setupDI();

      // إعداد معالج الأخطاء العام
      setupGlobalErrorHandler();

      // تهيئة AppLogger
      await AppLogger.instance.initialize();
      log.info('🚀 App Starting...', tag: 'Main');

      // Initialize Shorebird Code Push Service for OTA updates
      if (!kIsWeb) {
        await ShorebirdUpdateService().initialize();
      }

      // ── تحذير أمان في Debug إذا كانت الـ credentials hardcoded ────────────
      SupabaseConfig.warnIfUsingDefaults();

      // Set preferred orientations
      if (!kIsWeb) {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      }

      // Initialize Hive for local storage
      await Hive.initFlutter();
      await Hive.openBox('app_cache');

      // Initialize Firebase
      log.info('Initializing Firebase...', tag: 'Main');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      if (!kIsWeb) {
        FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler,
        );
      }

      // Initialize Supabase
      log.info('Initializing Supabase...', tag: 'Main');
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
        // تفعيل Debug logs في وضع التطوير فقط
        debug: kDebugMode,
      );
      log.info('✅ Supabase initialized', tag: 'Main');

      // تهيئة مراقب الشبكة
      NetworkMonitor.instance;
      log.info('✅ Network Monitor initialized', tag: 'Main');

      // Initialize Notification Service
      if (!kIsWeb) {
        await NotificationService().initialize();
        log.info('🔔 Notification Service initialized', tag: 'Main');
      }

      // ── تهيئة إعدادات التطبيق (Theme) قبل runApp ─────────────────────────
      final appSettings = AppSettingsProvider();
      await appSettings.initialize();
      log.info(
        '🎨 App settings initialized (theme: ${appSettings.themeMode.name})',
        tag: 'Main',
      );

      runApp(EdSentreApp(appSettings: appSettings));
      log.info('✅ App Started Successfully', tag: 'Main');
    },
    (error, stackTrace) {
      // معالجة الأخطاء غير الملتقطة
      ErrorHandler.instance.handle(error, stackTrace);
    },
  );
}

class EdSentreApp extends StatelessWidget {
  /// نمرر AppSettingsProvider من main() لضمان تهيئته قبل بناء الـ Widget tree
  final AppSettingsProvider appSettings;

  const EdSentreApp({super.key, required this.appSettings});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppConfig.instance,
      builder: (context, _) {
        final repository = AppConfig.isDemoMode
            ? MockSupabaseRepository()
            : SupabaseRepository(Supabase.instance.client);

        return MultiProvider(
          key: ValueKey(AppConfig.isDemoMode),
          providers: [
            // Repository Provider
            Provider<SupabaseRepository>.value(value: repository),

            // ✅ App Settings — Theme و اللغة وغيرها
            ChangeNotifierProvider<AppSettingsProvider>.value(
              value: appSettings,
            ),

            // Auth Provider
            ChangeNotifierProvider(create: (_) => AuthProvider(repository)),

            // Center Provider
            ChangeNotifierProvider(create: (_) => CenterProvider(repository)),

            // Teacher Provider - لإدارة بيانات المعلم
            ChangeNotifierProvider(create: (_) => TeacherProvider(repository)),

            // Parent Provider - لإدارة بيانات ولي الأمر
            ChangeNotifierProvider(create: (_) => ParentProvider(repository)),

            // AI Provider - للمساعد الذكي (يستخدم Edge Function للأمان)
            ChangeNotifierProvider(create: (_) => AIProvider(repository)),

            // AI Exam Provider - للتوليد من الملفات
            ChangeNotifierProvider(
              create: (_) => AiExamProvider(Supabase.instance.client),
            ),

            // Update Provider - لإدارة التحديثات
            ChangeNotifierProvider(
              create: (_) => UpdateProvider(sl())..checkForUpdates(),
            ),
          ],

          // ✅ Consumer<AppSettingsProvider> يضمن إعادة بناء MaterialApp
          //    فوراً عند تغيير الـ ThemeMode من شاشة الإعدادات
          child: Consumer<AppSettingsProvider>(
            builder: (context, settings, _) {
              return ScreenUtilInit(
                designSize: const Size(375, 812), // iPhone X design size
                minTextAdapt: true,
                splitScreenMode: true,
                builder: (context, child) {
                  return MaterialApp.router(
                    title: 'EdSentre',
                    debugShowCheckedModeBanner: false,

                    // ✅ ThemeMode ديناميكي بدلاً من ThemeMode.dark الثابت
                    theme: AppTheme.lightTheme,
                    darkTheme: AppTheme.darkTheme,
                    themeMode: settings.themeMode,

                    // Localization - RTL for Arabic
                    locale: const Locale('ar'),
                    supportedLocales: const [Locale('ar'), Locale('en')],
                    localizationsDelegates: const [
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                    ],

                    // Router
                    routerConfig: AppRouter.router,

                    // Builder for RTL support + Network Banner
                    builder: (context, child) {
                      return Directionality(
                        textDirection: TextDirection.rtl,
                        child: Column(
                          children: [
                            // شريط حالة الشبكة
                            ListenableBuilder(
                              listenable: NetworkMonitor.instance,
                              builder: (context, _) {
                                return NetworkStatusBanner(
                                  isConnected:
                                      NetworkMonitor.instance.isConnected,
                                );
                              },
                            ),
                            // المحتوى الرئيسي
                            Expanded(child: child ?? const SizedBox()),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
