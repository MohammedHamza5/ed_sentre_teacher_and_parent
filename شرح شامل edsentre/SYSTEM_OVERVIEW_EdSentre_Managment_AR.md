# توثيق نظام EdSentre بالكامل (نسخة عربية)

## مقدمة
- EdSentre هو نظام متكامل لإدارة المراكز التعليمية يركز على الأداء، الأمان، والعمل في وضع Offline عند انقطاع الإنترنت.
- يعتمد النظام على معمارية "Feature-Based Repository" مع فصل مصادر البيانات إلى RemoteSource و LocalSource لكل ميزة.
- التكامل الخلفي يتم عبر Supabase مع قواعد RLS مفعّلة وعمليات RPC مخصصة للمنطق المعقد.
- التطبيق مبني بـ Flutter ويستخدم MultiProvider و BLoC لإدارة الحالة، وGoRouter للتوجيه، مع منظومة مراقبة صحية وسجلات مركزية.

## فلسفة المعمارية
- فصل الميزات: كل ميزة لها Repository خاص بها مع RemoteSource و LocalSource مستقلين.
- Offline-First: يسبق التخزين المحلي والاسترجاع من الكاش عمليات الشبكة كلما أمكن، مع NetworkMonitor للكشف الآني عن الاتصال.
- Injection مركزي: يتم حقن جميع الـRepositories والـProviders في [main.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/main.dart) عبر MultiProvider وBlocProvider.
- توجيه آمن: يستخدم [app_router.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/core/routing/app_router.dart) GoRouter مع ردود فعل مباشرة على تغيّرات Auth.
- مراقبة شاملة: منظومة سجلات مركزية [app_logger.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/core/monitoring/app_logger.dart) وتقرير صحة النظام [system_health_monitor.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/core/monitoring/system_health_monitor.dart).

## المكونات الأساسية
- الواجهة والتطبيق:
  - الحقن والتشغيل: [main.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/main.dart)
  - الهيكل العام: [app_shell.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/shared/widgets/layout/app_shell.dart) و [app_sidebar.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/shared/widgets/navigation/app_sidebar.dart)
  - مؤشر الاتصال: [offline_banner.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/shared/widgets/offline/offline_banner.dart)
  - التوجيه: [app_router.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/core/routing/app_router.dart) و [route_names.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/core/routing/route_names.dart)
- مزودو الحالة:
  - الإعدادات: [settings_provider.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/core/providers/settings_provider.dart)
  - بيانات السنتر: [center_provider.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/core/providers/center_provider.dart)
  - الصلاحيات: [permission_service.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/core/services/permission_service.dart)
- الشبكة والتخزين المحلي:
  - مراقبة الشبكة: [network_monitor.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/core/offline/network_monitor.dart)
  - الكاش المحلي العام: [local_cache_service.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/core/offline/local_cache_service.dart)
- Supabase:
  - إدارة العميل: [supabase_client.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/core/supabase/supabase_client.dart)
  - الإعدادات: [supabase_config.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/core/supabase/supabase_config.dart) و [environment.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/core/supabase/environment.dart)
  - المصادقة والخدمات: [auth_service.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/core/supabase/auth_service.dart)
- إدارة الأخطاء والمراقبة:
  - المعالجة: [error_handler.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/core/error/error_handler.dart)
  - السجلات والصحة: [app_logger.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/core/monitoring/app_logger.dart) و [system_health_monitor.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/core/monitoring/system_health_monitor.dart)
- المزامنة وقاعدة البيانات المحلية:
  - قاعدة البيانات Drift: [app_database.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/core/database/app_database.dart)
  - خدمة المزامنة: [sync_service.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/core/sync/sync_service.dart)

## إدارة التوجيه (Routing)
- يستخدم GoRouter بواجهتين root وshell لاحتواء الـSidebar.
- إعادة التوجيه تعتمد مباشرة على حالة Supabase Auth عبر [app_router.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/core/routing/app_router.dart#L55-L79).
- جميع المسارات الرئيسة معرفة في [route_names.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/core/routing/route_names.dart) مع أسماء واضحة.

## إدارة المصادقة (Auth)
- إدارة جلسات Supabase مع تخزين آمن عبر [secure_local_storage.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/core/storage/secure_local_storage.dart).
- تدفق تسجيل الدخول والتسجيل ومعالجة الأخطاء في [auth_service.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/core/supabase/auth_service.dart).
- BLoC للمصادقة في [auth_bloc.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/features/auth/bloc/auth_bloc.dart) مع مؤقت جلسة وإعادة ضبطها عند التفاعل.

## الصلاحيات والأدوار
- تحميل الدور والصلاحيات والمجموعات المتاحة للمستخدم من RPCs:
  - get_my_role, get_my_permissions, get_my_groups
- التنفيذ في [permission_service.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/core/services/permission_service.dart).
- يوفّر حراس وصول بسيطة في الواجهة عبر PermissionGuard.

## نماذج البيانات الأساسية (Domain Models)
- جميع النماذج الموحدة في [models.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/shared/models/models.dart) وتضم:
  - الطلاب Student، المعلمين Teacher، المواد Subject، القاعات Room
  - المدفوعات Payment مع PaymentMethod/PaymentStatus
  - الحضور AttendanceRecord
  - إعدادات الفوترة BillingConfig وStudentBillingStatus

## ميزات النظام (Features)
- Dashboard:
  - شاشة: [dashboard_screen.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/features/dashboard/presentation/screens/dashboard_screen.dart)
  - مستودع: [dashboard_repository.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/features/dashboard/data/repositories/dashboard_repository.dart)
  - RPC: get_dashboard_summary
- Students:
  - شاشة: [students_screen.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/features/students/presentation/screens/students_screen.dart)
  - BLoC: [students_bloc.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/features/students/bloc/students_bloc.dart)
  - Repository: [students_repository.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/features/students/data/repositories/students_repository.dart)
  - RPCs: get_students_roster
- Teachers:
  - شاشات وإدارة الرواتب والدعوات: [teachers_screen.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/features/teachers/presentation/screens/teachers_screen.dart)
  - Repository: [teachers_repository.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/features/teachers/data/repositories/teachers_repository.dart)
  - RPCs: create_teacher_invitation, get_teacher_salary_detailed
- Subjects:
  - شاشة: [subjects_screen.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/features/subjects/presentation/screens/subjects_screen.dart)
  - Repository: [subjects_repository.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/features/subjects/data/repositories/subjects_repository.dart)
- Groups:
  - شاشة الإدارة: [groups_management_screen.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/features/groups/presentation/groups_management_screen.dart)
  - Repository: [groups_repository.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/features/groups/data/repositories/groups_repository.dart)
  - RPC: auto_enroll_course_students
- Schedule:
  - شاشة: [schedule_screen.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/features/schedule/presentation/screens/schedule_screen.dart)
  - Repository: [schedule_repository.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/features/schedule/data/repositories/schedule_repository.dart)
- Attendance:
  - شاشات: [attendance_screen.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/features/attendance/presentation/screens/attendance_screen.dart) و [take_attendance_screen.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/features/attendance/presentation/screens/take_attendance_screen.dart)
  - Repository: [attendance_repository.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/features/attendance/data/repositories/attendance_repository.dart)
  - RPCs: start_attendance_session, get_attendance_session_status, end_attendance_session, get_group_attendance_sheet
- Payments:
  - شاشات: [payments_screen.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/features/payments/presentation/screens/payments_screen.dart) و [record_payment_screen.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/features/payments/presentation/screens/record_payment_screen.dart)
  - Repository: [payment_repository.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/features/payments/data/repositories/payment_repository.dart)
  - RemoteSource: [payments_remote_source.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/features/payments/data/sources/payments_remote_source.dart)
  - LocalSource: [payments_local_source.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/features/payments/data/sources/payments_local_source.dart)
  - RPCs: get_or_create_student_invoice, add_payment_to_invoice, recalculate_invoice, get_student_balance_summary, get_student_account_statement
- Reports:
  - شاشات: [reports_screen.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/features/reports/presentation/screens/reports_screen.dart) و [smart_financial_dashboard_screen.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/features/reports/presentation/screens/smart_financial_dashboard_screen.dart) و [students_report_screen.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/features/reports/presentation/students_report_screen.dart)
  - Repository: [reports_repository.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/features/reports/data/reports_repository.dart)
  - RPCs: get_student_profitability وغيرها
- Notifications:
  - شاشة: [notifications_screen.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/features/notifications/presentation/screens/notifications_screen.dart)
  - RPCs: get_my_notifications, mark_notification_read, mark_all_notifications_read, get_unread_notifications_count, check_overdue_payments, check_consecutive_absences
- Settings:
  - شاشة الإعدادات العامة وأسعار الدورات: [settings_screen.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/features/settings/presentation/screens/settings_screen.dart) و [course_prices_screen.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/features/settings/presentation/screens/course_prices_screen.dart)
  - Repository: [settings_repository.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/features/settings/data/repositories/settings_repository.dart)
  - RemoteSource: [settings_remote_source.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/features/settings/data/sources/settings_remote_source.dart)
  - RPC: simulate_price_impact، بالإضافة إلى admin_upsert_user في واجهات الفريق.
- Support:
  - شاشات: [support_tickets_screen.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/features/support/presentation/screens/support_tickets_screen.dart) و [ticket_chat_screen.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/features/support/presentation/screens/ticket_chat_screen.dart)
  - RPCs: open_support_ticket, get_ticket_details
- Search:
  - شاشة: [search_screen.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/features/search/presentation/screens/search_screen.dart)
- Profile/Messages:
  - [profile_screen.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/features/profile/presentation/screens/profile_screen.dart) و [messages_screen.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/features/messages/presentation/screens/messages_screen.dart)

## المنظومة المالية والدفع
- المعمارية:
  - المستودع المالي يدعم الكاش المحلي مع TTL وFallback عند انقطاع الإنترنت: [payment_repository.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/features/payments/data/repositories/payment_repository.dart#L22-L51).
  - مصادر البيانات:
    - Remote: [payments_remote_source.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/features/payments/data/sources/payments_remote_source.dart)
    - Local: [payments_local_source.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/features/payments/data/sources/payments_local_source.dart)
- الفواتير:
  - إنشاء/جلب الفاتورة الذكية عبر RPC get_or_create_student_invoice.
  - إضافة دفعة للفاتورة: add_payment_to_invoice وإعادة الحساب: recalculate_invoice.
- ملخص رصيد الطالب:
  - RPC get_student_balance_summary لإرجاع totals وbalance.
- التسعير:
  - إدارة أسعار المواد والدورات عبر [settings_remote_source.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/features/settings/data/sources/settings_remote_source.dart#L144-L219).
  - محاكاة أثر تغيير السعر: simulate_price_impact.
- الفوترة الذكية BillingConfig:
  - إعدادات الدفع الشهرية/بالحصة/مختلط في [billing_models.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/shared/models/billing_models.dart).

## العمل في وضع Offline والمزامنة
- الكشف عن حالة الاتصال:
  - [network_monitor.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/core/offline/network_monitor.dart) مع فحص دوري وتحويل تلقائي للحالة.
- التخزين المؤقت:
  - خدمة عامة للكاش مرتبطة بالسنتر: [local_cache_service.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/core/offline/local_cache_service.dart).
  - مصادر محلية Feature-Specific مثل المدفوعات: [payments_local_source.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/features/payments/data/sources/payments_local_source.dart).
- قاعدة بيانات محلية:
  - Drift مع جداول متعددة وإضافة center_id في الهجرات: [app_database.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/core/database/app_database.dart#L42-L66).
- خدمة المزامنة:
  - سحب/دفع التغييرات وجدولة دورية كل 5 دقائق: [sync_service.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/core/sync/sync_service.dart).

## المراقبة والسجلات ومعالجة الأخطاء
- سجلات موحّدة مع أنواع ومستويات متعددة وطباعة منسّقة: [app_logger.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/core/monitoring/app_logger.dart).
- تقرير صحة النظام الدوري والتقرير الشامل: [system_health_monitor.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/core/monitoring/system_health_monitor.dart).
- معالج أخطاء متمركز مع رسائل ودعم SnackBar: [error_handler.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/core/error/error_handler.dart).

## الأمان والتكوين
- Supabase:
  - الاتصال يتم عبر Anon Key مع RLS مفعّلة: [supabase_client.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/core/supabase/supabase_client.dart#L26-L41).
  - إعدادات البيئة: [environment.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/core/supabase/environment.dart).
  - تخزين آمن لرموز الجلسة: [secure_local_storage.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/core/storage/secure_local_storage.dart).
- الصلاحيات:
  - تحميل الدور والصلاحيات عبر RPC، وحراس وصول في الواجهة.
- الخصوصية:
  - تجنّب طباعة البيانات الحساسة في السجلات الإنتاجية وتعطيل enableLogging في الإنتاج.

## تدفق العمل الأساسي (Journey)
- تسجيل الدخول:
  - تنظيف بيانات محلية قديمة، الاتصال Auth، جلب بيانات المستخدم والسنتر، حفظ center_id محلياً، ثم حقن الحالة: [auth_service.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/core/supabase/auth_service.dart).
- استخدام التطبيق:
  - التوجيه حسب الحالة، تحميل بيانات السنتر في [center_provider.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/core/providers/center_provider.dart)، تحميل الصلاحيات، تحديث العدادات والإشعارات.
- التعامل مع فقدان الاتصال:
  - إظهار لافتة Offline واعتماد الكاش المحلي في الـRepositories.
- المزامنة:
  - سحب/دفع التغييرات دورياً؛ إعادة محاولة مع Backoff عند الفشل.

## ملحق: أهم RPCs المستخدمة
- المدفوعات والفواتير: get_or_create_student_invoice، add_payment_to_invoice، recalculate_invoice، get_student_balance_summary، get_student_account_statement
- الحضور: start_attendance_session، get_attendance_session_status، end_attendance_session، get_group_attendance_sheet
- الطلاب والمعلمين: get_students_roster، create_teacher_invitation، get_teacher_salary_detailed
- اللوحة والتحليلات: get_dashboard_summary، get_student_profitability
- الإشعارات: get_my_notifications، mark_notification_read، mark_all_notifications_read، get_unread_notifications_count، check_overdue_payments، check_consecutive_absences
- الصلاحيات: get_my_role، get_my_permissions، get_my_groups
- التسعير: simulate_price_impact، admin_upsert_user

## ملحق: مكونات واجهة مشتركة
- المؤشرات والمكونات:
  - [sync_status_indicator.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/shared/widgets/sync/sync_status_indicator.dart)
  - [connection_status_indicator.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/shared/widgets/connectivity/connection_status_indicator.dart)
  - [stat_card.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/shared/widgets/cards/stat_card.dart)
  - [search_bar.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/shared/widgets/search/search_bar.dart)

## مصادر إضافية
- إرشادات الاختبار: [SYSTEM_TESTING_GUIDE.md](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/SYSTEM_TESTING_GUIDE.md)
- دليل الإنتاج: [Production-Grade.md](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/Production-Grade.md)
- تقارير المشكلات الإدارية: [ADMIN_ISSUES_REPORT.md](file:///c:/Users/KimoStore/StudioProjects/ed_sentre/lib/ADMIN_ISSUES_REPORT.md)

