# 🤖 دليل الذكاء الاصطناعي لفهم نظام الأكواد والربط

> هذا الملف يشرح بالتفصيل أين يبحث المبرمج (أو الـ AI) عن الأكواد والمنطق الخاص بنظام الدعوات وربط الطلاب بالمعلمين وأولياء الأمور.

---

## 📋 الفهرس السريع

| الموضوع | الملف الرئيسي |
|---------|---------------|
| التحقق من كود الدعوة | `docs/migrations/fix_verify_invitation_code.sql` |
| جلب بيانات المستخدم وتحديد دوره | `lib/core/supabase/auth_service.dart` |
| إنشاء دعوة معلم | `lib/features/teachers/data/sources/teachers_remote_source.dart` |
| جلب أكواد الطلاب/الأولياء | `lib/features/students/data/sources/students_remote_source.dart` |

---

## 🔐 نظام أكواد الدعوة (Invitation Codes)

### أنواع الأكواد

| البادئة | النوع | مصدر الكود | مثال |
|---------|-------|------------|------|
| `T` | معلم (Teacher) | `teacher_invitations.code` أو `teacher_enrollments.invitation_code` | `T6264689`, `TA45C9F7` |
| `P` | ولي أمر (Parent) | `student_enrollments.parent_invitation_code` | `P1234567` |

### مسار التحقق من الكود

```
┌─────────────────────────────────────────────────────────────┐
│  المستخدم يدخل الكود → verify_invitation_code(p_code)       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
              ┌───────────────────────────────┐
              │  هل يبدأ بـ 'T' أم 'P'؟        │
              └───────────────────────────────┘
                    │                  │
                   'T'                'P'
                    │                  │
                    ▼                  ▼
        ┌──────────────────┐  ┌──────────────────┐
        │ بحث في:          │  │ بحث في:          │
        │ 1. teacher_      │  │ student_         │
        │    invitations   │  │ enrollments.     │
        │ 2. teacher_      │  │ parent_          │
        │    enrollments   │  │ invitation_code  │
        └──────────────────┘  └──────────────────┘
```

### 📁 الملف: `docs/migrations/fix_verify_invitation_code.sql`

**أين تبحث؟** الدالة `verify_invitation_code(p_code text)` - سطر 13

**ماذا تفعل؟**
```sql
-- كود ولي أمر (يبدأ بـ P)
FROM public.student_enrollments se
WHERE UPPER(se.parent_invitation_code) = UPPER(p_code)

-- كود معلم (يبدأ بـ T) - أولوية 1
FROM public.teacher_invitations ti
WHERE UPPER(ti.code) = UPPER(p_code)

-- كود معلم (يبدأ بـ T) - أولوية 2 (fallback)
FROM public.teacher_enrollments te
WHERE UPPER(te.invitation_code) = UPPER(p_code)
```

---

## 👤 تحديد دور المستخدم عند تسجيل الدخول

### 📁 الملف: `lib/core/supabase/auth_service.dart`

**أين تبحث؟** الدالة `_fetchUserData(String userId)` - سطر 658

**مسار التحديد:**

```
┌─────────────────────────────────────────────────┐
│  AuthService._fetchUserData(userId)              │
└─────────────────────────────────────────────────┘
                        │
                        ▼ (الخطوة 1)
          ┌───────────────────────────────┐
          │  البحث في جدول users           │
          │  .from('users').eq('id', userId) │
          └───────────────────────────────┘
                        │
                        ▼ (الخطوة 2-3)
          ┌───────────────────────────────┐
          │  البحث عن السنتر المرتبط:      │
          └───────────────────────────────┘
                        │
       ┌────────────────┼────────────────┐
       ▼                ▼                ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│ centers      │ │ student_     │ │ teacher_     │
│ .admin_      │ │ enrollments  │ │ enrollments  │
│ user_id      │ │ .student_    │ │ .teacher_    │
│              │ │ user_id      │ │ user_id      │
│ → admin      │ │ → student    │ │ → teacher    │
└──────────────┘ └──────────────┘ └──────────────┘
```

**الكود المهم (مبسط):**

```dart
// أ. البحث كـ Admin
final centerAsAdmin = await client
    .from('centers')
    .select('id, name, is_active')
    .eq('admin_user_id', userId);
if (centerAsAdmin != null) {
  role = 'center_admin';
  centerId = centerAsAdmin['id'];
}

// ب. البحث كـ Student  
final studentEnrollment = await client
    .from('student_enrollments')
    .select('center_id, centers:center_id(*)')
    .eq('student_user_id', userId)
    .eq('status', 'accepted');
if (studentEnrollment != null) {
  role = 'student';
  centerId = studentEnrollment['center_id'];
}

// ج. البحث كـ Teacher (مشابه لـ Student)
final teacherEnrollment = await client
    .from('teacher_enrollments')
    .select('center_id, centers:center_id(*)')
    .eq('teacher_user_id', userId)
    .eq('status', 'active');
```

---

## 👨‍👩‍👧 كيف يجلب ولي الأمر أبناءه؟

### الجداول المعنية

| الجدول | العلاقة |
|--------|---------|
| `student_enrollments` | يحتوي على `parent_user_id` + `student_id` |
| `students` | بيانات الطالب الأساسية |

### المسار

```
parent_user_id → student_enrollments → student_id → students
```

### الاستعلام

```sql
SELECT s.* 
FROM students s
JOIN student_enrollments se ON se.student_id = s.id
WHERE se.parent_user_id = :current_user_id
  AND se.parent_code_status = 'claimed'
```

### 📁 الملفات ذات الصلة

- `lib/features/students/data/sources/students_remote_source.dart`
- البحث عن: `parent_user_id` أو `parent_invitation_code`

---

## 👨‍🏫 كيف يجلب المعلم طلابه ومجموعاته؟

### الجداول المعنية

| الجدول | الوصف |
|--------|-------|
| `teacher_enrollments` | ربط المعلم بالمركز (`teacher_user_id` ↔ `center_id`) |
| `groups` | المجموعات (`teacher_id` = معرف المعلم) |
| `student_group_enrollments` | الطلاب في كل مجموعة |

### مسار جلب المجموعات

```
teacher_user_id → teacher_enrollments → id (teacher_id)
                                           ↓
                                        groups.teacher_id
                                           ↓
                                student_group_enrollments → students
```

### 📁 الملف: `lib/features/teachers/data/sources/teachers_remote_source.dart`

**الدوال المهمة:**

| الدالة | الغرض | السطر |
|--------|-------|-------|
| `getTeachers()` | جلب كل المعلمين في المركز | 24 |
| `createTeacherInvitation()` | إنشاء كود دعوة جديد | 197 |
| `getTeacherInvitationCode()` | جلب كود معلم موجود | 554 |

**كود جلب كود الدعوة:**

```dart
// سطر 554-568
Future<String?> getTeacherInvitationCode(String teacherId) async {
  final response = await client
      .from('teacher_enrollments')
      .select('invitation_code')
      .eq('id', teacherId)
      .maybeSingle();
  return response?['invitation_code'] as String?;
}
```

---

## 📊 هيكل الجداول الرئيسية للربط

### 1. `teacher_enrollments`

```sql
id                  UUID PRIMARY KEY
center_id           UUID → centers
teacher_user_id     UUID → users (قد يكون NULL قبل المطالبة)
invitation_code     TEXT (مثل: T6264689)
status              TEXT ('pending', 'active', 'inactive')
teacher_name        TEXT
specialty           TEXT
```

### 2. `student_enrollments`

```sql
id                          UUID PRIMARY KEY
center_id                   UUID → centers
student_id                  UUID → students
student_user_id             UUID → users (للطالب)
parent_user_id              UUID → users (لولي الأمر)
parent_invitation_code      TEXT (مثل: P1234567)
parent_code_status          TEXT ('pending', 'claimed')
invitation_code             TEXT (كود الطالب نفسه)
status                      TEXT ('pending', 'accepted')
```

### 3. `teacher_invitations` (اختياري - بديل)

```sql
id              UUID PRIMARY KEY
center_id       UUID → centers
code            TEXT (مثل: TA45C9F7)
teacher_name    TEXT
used            BOOLEAN
expires_at      TIMESTAMP
```

---

## 🔍 أين تبحث لكل حالة استخدام؟

| الحالة | ابحث في |
|--------|---------|
| التحقق من كود دعوة | `docs/migrations/fix_verify_invitation_code.sql` |
| تسجيل دخول وتحديد الدور | `lib/core/supabase/auth_service.dart` → `_fetchUserData` |
| إنشاء دعوة معلم جديد | `teachers_remote_source.dart` → `createTeacherInvitation` |
| جلب كود معلم موجود | `teachers_remote_source.dart` → `getTeacherInvitationCode` |
| جلب أكواد طالب/ولي أمر | `students_remote_source.dart` → `getInvitationCodes` |
| ربط ولي أمر بابنه | `student_enrollments.parent_user_id` + `parent_code_status` |
| ربط معلم بمجموعة | `groups.teacher_id` → `teacher_enrollments.id` |

---

## 🛠️ نصائح للـ AI عند التعديل

1. **عند تعديل منطق التحقق من الكود:**
   - ابدأ بـ `fix_verify_invitation_code.sql`
   - تأكد من مطابقة الـ prefix (T/P)

2. **عند إضافة نوع كود جديد:**
   - أضف case جديد في `verify_invitation_code`
   - أنشئ جدول أو عمود مناسب
   - أضف الكود في Dart repository

3. **عند استكشاف الأخطاء:**
   - تحقق من `auth_service.dart` لفهم كيف يتم تحديد الدور
   - تحقق من RLS policies في قاعدة البيانات
   - استخدم الـ Logs: `AppLogger.database()` موجودة في الكود

4. **العلاقات المهمة:**
   ```
   users.id ←─┬─→ centers.admin_user_id (Admin)
              ├─→ teacher_enrollments.teacher_user_id (Teacher)
              ├─→ student_enrollments.student_user_id (Student)
              └─→ student_enrollments.parent_user_id (Parent)
   ```

---

## 📝 ملخص

| العنصر | القيمة |
|--------|--------|
| **كود المعلم** | يبدأ بـ `T` - يُخزن في `teacher_invitations.code` أو `teacher_enrollments.invitation_code` |
| **كود ولي الأمر** | يبدأ بـ `P` - يُخزن في `student_enrollments.parent_invitation_code` |
| **كود الطالب** | يُخزن في `student_enrollments.invitation_code` |
| **دالة التحقق** | `public.verify_invitation_code(p_code text)` |
| **تحديد الدور** | `AuthService._fetchUserData()` يبحث في 3 جداول بالترتيب |

---

**آخر تحديث:** يناير 2026
