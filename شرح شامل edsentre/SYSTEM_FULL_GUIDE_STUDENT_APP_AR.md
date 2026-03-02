# EdSentre Student — التوثيق الشامل للنظام والتطبيق

## الفهرس
- نظرة عامة
- التقنية والبنية
- تدفق التشغيل
- الوحدات الأساسية
- قاعدة البيانات المحلية (Drift)
- المستودعات (Repositories) وواجهات البيانات
- مقدمو الحالة (Providers)
- التوجيه (Routing) والواجهات
- الميزات الرئيسية
- الذكاء الاصطناعي في التطبيق
- الأمن والخصوصية
- الإعداد والتشغيل
- الاختبارات والجودة
- قيود معروفة وتحسينات لاحقة
- مسرد دوال الـ RPC

## نظرة عامة
- تطبيق الطالب ضمن منظومة EdSentre لإدارة المراكز التعليمية.
- يعتمد على Supabase كخادم بيانات ومصادقة، مع دعم وضع بدون إنترنت عبر Drift.
- يوفر تجربة متعددة المراكز للطالب، مع إدارة الحضور، الجداول، الدرجات، المواد، الرسائل، الإشعارات والمدفوعات.

## التقنية والبنية
- الواجهة: Flutter (Material 3) مع ScreenUtil للقياسات المتجاوبة.
- إدارة الحالة: Provider + ChangeNotifier (مدعوم بـ GetIt/Injectable للـ DI).
- التوجيه: go_router مع مراقب تنقل مخصص.
- الخادم: Supabase (PostgreSQL + Auth + Storage + Realtime) عبر RPCs وجداول.
- التخزين المحلي: Drift (ORM) لتوفير Offline-first ومزامنة لاحقة.
- الترجمة: نظام l10n مع ملفات ARB ودعم العربية واللغات الأخرى.
- الثيم: ثيم فاتح/داكن مخصص مع ألوان ونصوص موحدة.

روابط مرجعية:
- التهيئة الرئيسية: [main.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/main.dart)
- إعدادات التطبيق: [app_settings.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/core/config/app_settings.dart)
- إعدادات البيئة: [app_config.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/core/config/app_config.dart)
- Supabase: [supabase_config.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/core/config/supabase_config.dart)
- الحقن والـ DI: [injection.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/core/di/injection.dart)
- التوجيه: [app_router.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/core/routing/app_router.dart), [route_constants.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/core/routing/route_constants.dart)
- الثيم: [app_theme.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/core/theme/app_theme.dart)
- الترجمة: [l10n](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/l10n/app_localizations.dart)

## تدفق التشغيل
1. بدء التشغيل:
   - تهيئة Flutter وقيود الاتجاه.
   - تحميل إعدادات المستخدم (اللغة/الثيم) من التخزين المحلي.
   - طباعة وفحص إعدادات البيئة.
   - تهيئة Supabase (باستخدام مفاتيح البيئة أو مفاتيح افتراضية في التطوير).
   - تهيئة الحاوية (GetIt/Injectable) وتسجيل الخدمات والمستودعات.
   - تشغيل التطبيق.
   - المرجع: [main.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/main.dart#L17-L60)

2. التوجيه العام:
   - استخدام GoRouter مع مسارات محددة للشاشات الأساسية والميزات.
   - شاشة Splash تدير التحويل الأولي حسب حالة الدخول والمركز.
   - المرجع: [app_router.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/core/routing/app_router.dart)

3. الإعدادات العالمية:
   - الثيم واللغة قابلة للتبديل ومحفوظة في SharedPreferences.
   - المرجع: [app_settings.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/core/config/app_settings.dart)

## الوحدات الأساسية
- AppConfig: إدارة القيم المعرّفة بالبيئة وأعلام الميزات.
- SupabaseConfig: تهيئة Supabase والوصول إلى العملاء (auth/storage/realtime) مع فحوصات الحالة.
- الحقن (GetIt/Injectable): تسجيل الخدمات والمستودعات والـ DAOs.
- NetworkInfo: التحقق من الاتصال وحدث تغيّر الاتصال.
- الترجمة والـ l10n: دعم تعدد اللغات مع العربية كلغة افتراضية.

مراجع:
- [app_config.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/core/config/app_config.dart)
- [supabase_config.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/core/config/supabase_config.dart)
- [injection.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/core/di/injection.dart)
- [network_info.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/core/network/network_info.dart)

## قاعدة البيانات المحلية (Drift)
- ملف القاعدة: [app_database.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/core/database/app_database.dart)
- الجداول المدعومة:
  - الطلاب: [students_table.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/core/database/tables/students_table.dart)
  - المواد والدورات: [courses_table.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/core/database/tables/courses_table.dart)
  - الجدول: [schedules_table.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/core/database/tables/schedules_table.dart)
  - الحضور: [attendance_table.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/core/database/tables/attendance_table.dart)
  - الدرجات: [grades_table.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/core/database/tables/grades_table.dart)
  - الواجبات: [assignments_table.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/core/database/tables/assignments_table.dart)
  - المدفوعات: [payments_table.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/core/database/tables/payments_table.dart)
  - الإشعارات: [notifications_table.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/core/database/tables/notifications_table.dart)
  - المواد الدراسية: [study_materials_table.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/core/database/tables/study_materials_table.dart)
  - المحادثات والرسائل: [conversations_table.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/core/database/tables/conversations_table.dart), [messages_table.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/core/database/tables/messages_table.dart)
- نهج المزامنة:
  - حفظ البيانات المسترجعة من Supabase في القاعدة المحلية مع أعلام isSynced و lastSyncedAt.
  - استخدام التخزين المحلي في وضع عدم الاتصال والاعتماد على RPC للخادم عند الاتصال.

## المستودعات (Repositories) وواجهات البيانات
- قاعدة عامة: [base_repository.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/core/repositories/base_repository.dart)
  - تغليف النتائج RepositoryResult<T>.
  - تنفيذ executeQuery/executeRpc مع تسجيل تلقائي للأخطاء والنجاح.
  - الوصول إلى SupabaseClient و AppDatabase و AppLogger.

- الطلاب: [student_repository.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/core/repositories/student_repository.dart)
  - ensure_student_exists، get_full_student_profile، get_student_centers_detailed، get_student_dashboard_summary.

- الدورات: [course_repository.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/core/repositories/course_repository.dart)
  - get_student_courses، جلب الدورات حسب السنتر مع تخزين محلي (تجهيز الكاش لاحقاً).

- الجدول: [schedule_repository.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/core/repositories/schedule_repository.dart)
  - get_student_schedule، تجميع أسبوعي، حفظ في الكاش.

- الحضور: [attendance_repository.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/core/repositories/attendance_repository.dart)
  - calculate_attendance_rate، calculate_detailed_attendance_rate، get_student_attendance، scan_attendance_qr.

- الدرجات: [grade_repository.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/core/repositories/grade_repository.dart)
  - get_academic_performance، get_student_grades.

- المواد الدراسية: [material_repository.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/core/repositories/material_repository.dart)
  - get_student_materials مع كاش محلي، increment_download_count.

- الرسائل: [message_repository.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/core/repositories/message_repository.dart)
  - get_student_conversations، get_available_teachers، subscribeToMessages، send_message، mark_messages_read.

- الإشعارات: [notification_repository.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/core/repositories/notification_repository.dart)
  - get_user_notifications، mark_notification_as_read، mark_all_notifications_read.

- المدفوعات: [payment_repository.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/core/repositories/payment_repository.dart)
  - get_student_invoice_summary، generate_student_monthly_invoice، تحويل الملخص القديم.

## مقدمو الحالة (Providers)
- المصادقة: [auth_provider.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/core/providers/auth_provider.dart)
  - تسجيل الدخول بكود الدعوة (إنشاء بريد من الكود، التسجيل/التسجيل دخول).
  - دعوة الطالب Claim عبر RPC، التحقق/إضافة الجهاز (دعم تعدد الأجهزة).
  - حفظ بيانات الطالب محلياً واسترجاعها، تسجيل الخروج، إدارة الأخطاء.

- السنتر: [center_provider.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/core/providers/center_provider.dart)
  - تحميل مراكز الطالب عبر RPC مع آلية احتياط، حفظ واختيار المركز الحالي، إضافة مركز عبر كود دعوة.

- بيانات الطالب: [student_data_provider.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/core/providers/student_data_provider.dart)
  - تحميل ملخص اللوحة + إحصائيات الحضور + قائمة الدورات مركزياً لتوحيد الأرقام في الشاشات.

- الأمان: [secure_auth_service.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/core/services/secure_auth_service.dart)
  - تخزين آمن للتوكن، مهلة الجلسة، التحقق من صلاحية الجلسة.

## التوجيه (Routing) والواجهات
- تعريف المسارات والأسماء: [route_constants.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/core/routing/route_constants.dart)
- أمثلة شاشات موجودة:
  - تسجيل الدخول: [login_screen.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/features/auth/screens/login_screen.dart)
  - الرئيسية/لوحة: [main_screen.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/features/main/screens/main_screen.dart), [dashboard_screen.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/features/dashboard/screens/dashboard_screen.dart)
  - الدورات: [courses_screen.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/features/courses/screens/courses_screen.dart)
  - الجدول: [schedule_screen.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/features/schedule/screens/schedule_screen.dart)
  - الدرجات: [grades_screen.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/features/grades/screens/grades_screen.dart)
  - المواد الدراسية: [materials_screen.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/features/materials/screens/materials_screen.dart)
  - الرسائل: [chat_list_screen.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/features/messages/screens/chat_list_screen.dart), [chat_screen.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/features/messages/screens/chat_screen.dart)
  - المدفوعات: [payments_screen.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/features/payments/screens/payments_screen.dart)
  - الملف الشخصي: [profile_screen.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/features/profile/screens/profile_screen.dart)
  - الإعدادات: [settings_screen.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/features/settings/screens/settings_screen.dart), [about_screen.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/features/settings/screens/about_screen.dart)
  - شاشة البداية: [splash_screen.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/features/splash/screens/splash_screen.dart)
  - مسح QR للحضور: [scan_qr_screen.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/features/attendance/screens/scan_qr_screen.dart)

ملاحظة: بعض المسارات المشار إليها في محوّل المسارات قد تكون تحت التطوير أو متاحة في فروع أخرى.

## الميزات الرئيسية
- تسجيل الدخول بكود الدعوة:
  - إنشاء بريد من الكود، كلمة المرور الافتراضية هي الكود إن لم تكن خاصة.
  - إنشاء المستخدم الجديد وربط الملف الطلابي عبر claim_student_profile.
  - التحقق/إضافة الجهاز عبر verify_or_add_device (دعم عدة أجهزة).
  - المرجع: [auth_provider.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/core/providers/auth_provider.dart#L66-L214)

- اختيار/التبديل بين المراكز:
  - تحميل المراكز عبر RPC مع Fallback، حفظ المركز المختار، التبديل السريع.
  - المرجع: [center_provider.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/core/providers/center_provider.dart)

- لوحة الطالب الموحدة:
  - ملخص شامل: الدورات/الواجبات/الإشعارات/الجلسة القادمة/الجدول اليومي/المدفوعات.
  - المرجع: [student_repository.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/core/repositories/student_repository.dart#L468-L486), [student_data_provider.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/core/providers/student_data_provider.dart)

- الجدول والحصص:
  - جلب جدول اليوم/الأسبوع، تحديد الجلسات القادمة، تخزين محلي للسرعة.
  - المرجع: [schedule_repository.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/core/repositories/schedule_repository.dart)

- الحضور:
  - حساب نسبة الحضور، إحصاءات مفصلة، سجل الحضور، مسح QR لتسجيل الحضور.
  - المرجع: [attendance_repository.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/core/repositories/attendance_repository.dart)

- الدرجات:
  - الملخص الأكاديمي وتوزيع الدرجات وقوائم درجات المواد.
  - المرجع: [grade_repository.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/core/repositories/grade_repository.dart)

- المواد الدراسية:
  - تنزيل وفتح ملفات، كاش محلي، عداد تحميلات.
  - المرجع: [material_repository.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/core/repositories/material_repository.dart)

- الرسائل مع المعلمين:
  - إدارة المحادثات، جلب الرسائل، إرسال/قراءة، اشتراك لحظي عبر Realtime.
  - المرجع: [message_repository.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/core/repositories/message_repository.dart)

- الإشعارات:
  - جلب الإشعارات، تمييز كمقروء، العد الآني غير المقروء.
  - المرجع: [notification_repository.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/core/repositories/notification_repository.dart)

- المدفوعات والفاتورة الذكية:
  - ملخص شهري، إنشاء فاتورة، تحويل لواجهة قديمة.
  - المرجع: [payment_repository.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/core/repositories/payment_repository.dart)

## الذكاء الاصطناعي في التطبيق
- خدمة المعلم الذكي: [ai_service.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/core/services/ai_service.dart)
  - محادثة تعليمية، تلخيص نص، توليد بطاقات مراجعة (Flashcards).
- إعداد المفتاح: [ai_config.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/core/config/ai_config.dart)
  - تنبيه أمني: يفضل نقل المفاتيح إلى متغيرات بيئية وعدم تضمينها في المستودع.
- شاشات الذكاء:
  - الطالب الذكي، خطة المذاكرة، الامتحان الشفهي: [student_ai_screen.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/features/ai_tutor/screens/student_ai_screen.dart), [study_plan_screen.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/features/ai_tutor/screens/study_plan_screen.dart), [oral_exam_screen.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/features/ai_tutor/screens/oral_exam_screen.dart)

## الأمن والخصوصية
- قواعد RLS في Supabase لعزل بيانات المراكز والمستخدمين.
- تخزين آمن للتوكنات عبر flutter_secure_storage وإدارة مهلة الجلسة.
- تحذير: وجود مفاتيح Supabase وAI بشكل صريح في التطوير؛ يجب استخدام --dart-define أو ملفات بيئة خارجية للإنتاج.
- المرجع: [secure_auth_service.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/core/services/secure_auth_service.dart), [supabase_config.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/core/config/supabase_config.dart), [app_config.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/lib/core/config/app_config.dart)

## الإعداد والتشغيل
- المتطلبات: Flutter/Dart وفق pubspec، Supabase مشروع مهيأ.
- التبعيات: [pubspec.yaml](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_student/pubspec.yaml)
- تشغيل:
  - تثبيت الحزم: flutter pub get
  - توليد كود Drift: build_runner (إذا لزم)
  - تشغيل مع متغيرات بيئية: flutter run --dart-define-from-file=<env-file>

## الاختبارات والجودة
- حزم الاختبار: flutter_test، mockito، bloc_test (للنمط Bloc عند اللزوم).
- تحليل ثابت: flutter_lints.
- يفضل إضافة اختبارات تكامل للمستودعات وواجهات RPC الأساسية.

## قيود معروفة وتحسينات لاحقة
- بعض آليات الكاش معلقة بسبب عدم توليد الـ Companions لبعض الجداول؛ يلزم توحيد المخطط وتوليد الشيفرة.
- وجود مفاتيح حساسة مباشرة في ملفات التهيئة أثناء التطوير؛ يجب نقلها لبيئة آمنة.
- بعض الشاشات المشار إليها في التوجيه قد تكون تحت البناء أو في فروع مختلفة.

## مسرد دوال الـ RPC (حسب الاستخدام في التطبيق)
- ensure_student_exists: التحقق/إنشاء سجل الطالب.
- claim_student_profile: ربط ملف الطالب عند المستخدم الجديد.
- verify_or_add_device: إدارة الأجهزة المتعددة للمستخدم.
- get_full_student_profile: جلب ملف الطالب الكامل.
- get_student_centers_detailed: مراكز الطالب مع تفاصيل.
- switch_active_center: تغيير المركز النشط.
- get_student_home_stats / get_student_dashboard_summary: ملخص لوحة الطالب.
- get_student_courses: دورات الطالب مع اسم المعلم.
- get_student_schedule: جدول الطالب (اليوم/الأسبوع).
- calculate_attendance_rate / calculate_detailed_attendance_rate: إحصاءات الحضور.
- get_student_attendance: سجل الحضور وتصفية حسب المادة/التواريخ.
- scan_attendance_qr: تسجيل الحضور عبر QR.
- get_available_teachers / get_student_conversations / get_or_create_conversation: نظام المحادثات.
- send_message / mark_messages_read: رسائل وإدارتها.
- get_user_notifications / mark_notification_as_read / mark_all_notifications_read: الإشعارات.
- get_student_invoice_summary / generate_student_monthly_invoice: الفاتورة الذكية الشهرية.
- increment_download_count: عدّاد تحميلات المواد الدراسية.

---

هذا المستند يقدّم صورة كاملة وعملية عن نظام EdSentre Student، ويربط كل ميزة بمصدرها البرمجي لضمان سهولة الصيانة والتوسعة.

