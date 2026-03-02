# EdSentre - Teacher & Parent App 📚

> تطبيق Flutter لإدارة التواصل بين المعلمين وأولياء الأمور في المراكز التعليمية

![Flutter](https://img.shields.io/badge/Flutter-3.8+-blue.svg)
![Supabase](https://img.shields.io/badge/Supabase-Backend-green.svg)
![AI](https://img.shields.io/badge/AI-OpenAI_GPT--4-purple.svg)

---

## 📋 نظرة عامة

**EdSentre** هو نظام متكامل لإدارة المراكز التعليمية (السناتر) يتكون من:

| التطبيق | الوصف |
|---------|-------|
| 🎓 **تطبيق المعلم** | إدارة الحضور، الواجبات، الامتحانات، المحتوى التعليمي |
| 👨‍👩‍👧 **تطبيق ولي الأمر** | متابعة الأبناء، الحضور، الدرجات، المدفوعات |
| 🤖 **المساعد الذكي** | إنشاء امتحانات وواجبات من كتب المعلم باستخدام AI |

---

## 🏗️ البنية التقنية

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter App (Dart)                    │
│         تطبيق المعلم + تطبيق ولي الأمر (نفس الـ APK)      │
├─────────────────────────────────────────────────────────┤
│                    Supabase Backend                      │
│   PostgreSQL │ Auth │ Storage │ Edge Functions │ RLS    │
├─────────────────────────────────────────────────────────┤
│                OpenAI API (via Edge Function)            │
│              GPT-4 Turbo للمساعد الذكي                   │
└─────────────────────────────────────────────────────────┘
```

### التقنيات المستخدمة

| التقنية | الاستخدام |
|---------|----------|
| **Flutter 3.8+** | تطبيق الموبايل (Android & iOS) |
| **Dart** | لغة البرمجة |
| **Supabase** | Backend-as-a-Service |
| **PostgreSQL** | قاعدة البيانات |
| **OpenAI GPT-4** | المساعد الذكي |
| **Provider** | State Management |
| **GoRouter** | Navigation |

---

## 📁 هيكل المشروع

```
lib/
├── main.dart                    # نقطة البداية
├── app_router.dart              # التوجيه والـ Routes
│
├── core/                        # الطبقة الأساسية
│   ├── config/
│   │   ├── app_colors.dart      # الألوان
│   │   ├── app_theme.dart       # الثيم (RTL + Cairo Font)
│   │   └── supabase_config.dart # إعدادات Supabase
│   │
│   ├── providers/
│   │   ├── auth_provider.dart   # مزود المصادقة
│   │   ├── center_provider.dart # مزود السنتر
│   │   ├── teacher_provider.dart
│   │   ├── parent_provider.dart
│   │   └── ai_provider.dart     # مزود المساعد الذكي
│   │
│   └── services/
│       └── ai_service.dart      # خدمة AI (Edge Function)
│
├── shared/                      # الطبقة المشتركة
│   ├── data/
│   │   └── supabase_repository.dart  # كل عمليات قاعدة البيانات
│   ├── models/                  # نماذج البيانات
│   └── widgets/                 # ويدجتس مشتركة
│
└── features/                    # الميزات
    ├── auth/                    # المصادقة
    │   └── screens/
    │       ├── splash_screen.dart
    │       ├── login_screen.dart
    │       └── invitation_code_screen.dart
    │
    ├── teacher/                 # ميزات المعلم
    │   └── screens/
    │       ├── teacher_home_screen.dart
    │       ├── teacher_assignments_screen.dart
    │       ├── teacher_materials_screen.dart
    │       ├── teacher_reports_screen.dart
    │       ├── ai_assistant_screen.dart      # المساعد الذكي
    │       └── ai_generate_exam_screen.dart
    │
    └── parent/                  # ميزات ولي الأمر
        └── screens/
            ├── parent_home_screen.dart
            ├── parent_attendance_screen.dart
            ├── parent_grades_screen.dart
            └── parent_payments_screen.dart
```

---

## 🔐 نظام المصادقة والأدوار

### كيف يعمل نظام الأدوار؟

```
┌──────────────────────────────────────────────────────────┐
│                    تسجيل مستخدم جديد                      │
└──────────────────────────────────────────────────────────┘
                            │
                            ▼
┌──────────────────────────────────────────────────────────┐
│              هل لديه كود دعوة؟                            │
└──────────────────────────────────────────────────────────┘
                   │                │
                  نعم               لا
                   │                │
                   ▼                ▼
        ┌─────────────────┐  ┌─────────────────┐
        │  إدخال الكود    │  │  لا يمكنه       │
        │  والتحقق منه   │  │  التسجيل ❌     │
        └─────────────────┘  └─────────────────┘
                   │
                   ▼
        ┌─────────────────────────────────────┐
        │     نوع الكود يحدد الدور تلقائياً    │
        └─────────────────────────────────────┘
                   │
       ┌───────────┴───────────┐
       ▼                       ▼
┌─────────────┐         ┌─────────────┐
│  معلم 🎓   │         │ ولي أمر 👨‍👩‍👧 │
└─────────────┘         └─────────────┘
```

### جدول invitation_codes

| العمود | الوصف |
|--------|-------|
| `code` | كود الدعوة (فريد) |
| `type` | `teacher` أو `parent` |
| `center_id` | السنتر المرتبط |
| `linked_student_id` | للولي أمر: الطالب المرتبط |
| `is_used` | هل تم استخدامه؟ |

---

## 🤖 المساعد الذكي (AI)

### الميزات

| الميزة | الوصف | التكلفة |
|--------|-------|---------|
| 📝 إنشاء امتحان | أسئلة مبتكرة من كتاب المعلم | 15 رصيد |
| 📋 إنشاء واجب | تمارين للمراجعة | 10 رصيد |
| ⚡ كويز سريع | 5 أسئلة سريعة | 5 رصيد |
| 📖 ملخص فصل | تلخيص ذكي | 8 رصيد |

### كيف يعمل؟

```
┌─────────────────────────────────────────────────────────┐
│  1️⃣ المعلم يرفع الكتاب/الملزمة (مرة واحدة)              │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│  2️⃣ يُخزن المحتوى في teacher_knowledge_base             │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│  3️⃣ المعلم يطلب "إنشاء امتحان" مع تحديد:               │
│     - درجة الصعوبة (سهل/متوسط/صعب/متنوع)               │
│     - عدد الأسئلة                                       │
│     - نوع الاختبار (امتحان/واجب/كويز)                  │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│  4️⃣ Edge Function تستدعي OpenAI                         │
│     ⚠️ AI يقرأ من محتوى المعلم فقط (لا إنترنت)          │
│     ✨ يخترع أسئلة جديدة (لا ينسخ من الكتاب)            │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│  5️⃣ المعلم يعاين ويعدل ثم ينشر للطلاب                   │
└─────────────────────────────────────────────────────────┘
```

### الأمان

```
┌────────────────────────────────────────────────────────────┐
│                     Flutter App                             │
│   لا يوجد API Key في الكود ✅                               │
└────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────────┐
│            Supabase Edge Function (clever-worker)           │
│   🔐 OpenAI API Key مخزن كـ Secret في السيرفر               │
└────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────────┐
│                      OpenAI API                             │
└────────────────────────────────────────────────────────────┘
```

---

## 🗄️ قاعدة البيانات (PostgreSQL)

### الجداول الرئيسية

```sql
-- المستخدمون
users                    -- بيانات المستخدمين الأساسية
teacher_profiles         -- بيانات المعلمين
parent_students          -- ربط أولياء الأمور بالطلاب

-- المراكز والمجموعات
centers                  -- السناتر
courses                  -- المواد الدراسية
groups                   -- المجموعات (الفصول)
group_students           -- الطلاب في كل مجموعة
teacher_groups           -- المعلمين في كل مجموعة

-- الحضور والدرجات
attendance               -- سجل الحضور
grades                   -- الدرجات

-- الواجبات والمحتوى
assignments              -- الواجبات والامتحانات
assignment_submissions   -- تسليمات الطلاب
study_materials          -- المحتوى التعليمي

-- نظام AI
teacher_knowledge_base   -- قاعدة معرفة المعلم (الكتب)
ai_credits               -- رصيد AI للمعلم
ai_usage_log             -- سجل الاستخدام
ai_generated_exams       -- الامتحانات المُنشأة

-- نظام الدعوات
invitation_codes         -- أكواد الدعوة
```

---

## 🚀 الإعداد والتشغيل

### 1. المتطلبات

- Flutter SDK 3.8+
- Dart 3.0+
- حساب Supabase
- حساب OpenAI (اختياري - للمساعد الذكي)

### 2. الإعداد

```bash
# Clone the repo
git clone <repo-url>
cd ed_sentre_techer_and_parent

# Install dependencies
flutter pub get
```

### 3. إعداد Supabase

1. أنشئ مشروع جديد في [supabase.com](https://supabase.com)
2. انسخ `URL` و `anon key`
3. حدّث `lib/core/config/supabase_config.dart`:

```dart
class SupabaseConfig {
  static const String url = 'YOUR_SUPABASE_URL';
  static const String anonKey = 'YOUR_ANON_KEY';
}
```

4. نفّذ ملفات SQL في Supabase SQL Editor

### 4. إعداد Edge Function (للمساعد الذكي)

1. في Supabase Dashboard → Edge Functions → Create Function
2. اسم الدالة: `clever-worker` (أو أي اسم آخر)
3. أضف الكود من `supabase/functions/clever-worker/index.ts`
4. أضف Secret:
   - Name: `OPENAI_API_KEY`
   - Value: `sk-...`

### 5. التشغيل

```bash
flutter run
```

---

## 📱 الشاشات الرئيسية

### تطبيق المعلم

| الشاشة | الوصف |
|--------|-------|
| 🏠 الرئيسية | إحصائيات + حصص اليوم |
| 📅 الجدول | جدول الحصص الأسبوعي |
| ✅ الحضور | تسجيل حضور الطلاب |
| 👥 الطلاب | قائمة طلابي |
| 📝 الواجبات | إدارة الواجبات والامتحانات |
| 📚 المحتوى | رفع الملزمات والفيديوهات |
| 📊 التقارير | تقارير أداء الطلاب |
| 🤖 المساعد الذكي | إنشاء امتحانات بـ AI |

### تطبيق ولي الأمر

| الشاشة | الوصف |
|--------|-------|
| 🏠 الرئيسية | قائمة الأبناء + اختيار السنتر |
| ✅ الحضور | سجل حضور الابن |
| 📊 الدرجات | درجات الابن |
| 💳 المدفوعات | الفواتير والمدفوعات |
| 💬 الرسائل | التواصل مع المعلمين |

---

## 🎨 التصميم

### الألوان الأساسية

```dart
static const Color primary = Color(0xFF1E88E5);      // أزرق
static const Color secondary = Color(0xFF26A69A);    // تركواز
static const Color accent = Color(0xFFFF7043);       // برتقالي
```

### الخطوط

- **العربية:** Cairo
- **الإنجليزية/الأرقام:** Roboto

### الاتجاه

التطبيق يعمل بـ **RTL (من اليمين لليسار)** افتراضياً

---

## 🔧 الصيانة والتطوير

### إضافة شاشة جديدة

1. أنشئ الملف في `lib/features/<feature>/screens/`
2. أضف Route في `lib/app_router.dart`
3. أضف أي دوال مطلوبة في `supabase_repository.dart`

### إضافة جدول جديد في قاعدة البيانات

1. أنشئ الجدول في Supabase SQL Editor
2. أضف RLS Policies للأمان
3. أضف Model في `lib/shared/models/`
4. أضف الدوال في `supabase_repository.dart`

---

## 📄 الملفات المهمة

| الملف | الوصف |
|-------|-------|
| `lib/main.dart` | نقطة البداية + Providers |
| `lib/app_router.dart` | كل الـ Routes |
| `lib/shared/data/supabase_repository.dart` | كل عمليات الـ Backend |
| `lib/core/providers/ai_provider.dart` | منطق المساعد الذكي |
| `supabase/functions/clever-worker/index.ts` | Edge Function للـ AI |

---

## 🤝 المساهمة

1. Fork the repo
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

---

## 📞 الدعم

للمساعدة أو الاستفسارات، تواصل مع فريق التطوير.

---

**تم التطوير بـ ❤️ لخدمة التعليم**
