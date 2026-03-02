-- ============================================================
-- fix_teacher_data_access.sql
-- إصلاح شامل لصلاحيات المعلم على بيانات المجموعات والطلاب
-- تاريخ: 2025
-- ============================================================
-- كيفية التطبيق:
--   1. افتح Supabase Dashboard → SQL Editor
--   2. الصق هذا الملف كاملاً ثم اضغط Run
-- ============================================================


-- ================================================================
-- STEP 0: تشخيص المشكلة - تحقق من البيانات الموجودة
-- ================================================================

-- اعرض عدد المجموعات لكل معلم
DO $$
BEGIN
  RAISE NOTICE '=== تشخيص البيانات ===';
  RAISE NOTICE 'عدد المجموعات الكلي: %', (SELECT COUNT(*) FROM public.groups);
  RAISE NOTICE 'عدد المعلمين: %', (SELECT COUNT(*) FROM public.teachers);
  RAISE NOTICE 'عدد تسجيلات المعلمين في السناتر: %', (SELECT COUNT(*) FROM public.teacher_enrollments WHERE status = ''active'');
  RAISE NOTICE 'عدد تسجيلات الطلاب في المجموعات: %', (SELECT COUNT(*) FROM public.student_group_enrollments WHERE status = ''active'');
END $$;


-- ================================================================
-- STEP 1: إصلاح RLS على جدول groups
-- ================================================================

-- تفعيل RLS
ALTER TABLE public.groups ENABLE ROW LEVEL SECURITY;

-- حذف السياسات القديمة المتعارضة
DROP POLICY IF EXISTS "Teachers can view their own groups"           ON public.groups;
DROP POLICY IF EXISTS "Teacher can view own groups"                  ON public.groups;
DROP POLICY IF EXISTS "teacher_groups_select"                        ON public.groups;
DROP POLICY IF EXISTS "groups_select_policy"                         ON public.groups;
DROP POLICY IF EXISTS "Enable read access for all users"             ON public.groups;
DROP POLICY IF EXISTS "Allow teacher to read own groups"             ON public.groups;

-- سياسة جديدة: المعلم يرى مجموعاته فقط
-- تدعم كلا الحالتين: teacher_id = teachers.id أو teacher_id = user_id مباشرة
CREATE POLICY "teacher_select_own_groups"
ON public.groups
FOR SELECT
USING (
  -- الحالة 1: teacher_id يساوي teachers.id الخاص بالمعلم الحالي
  teacher_id IN (
    SELECT id FROM public.teachers WHERE user_id = auth.uid()
  )
  OR
  -- الحالة 2: teacher_id يساوي user_id مباشرة (في حال الإدخال اليدوي)
  teacher_id = auth.uid()
  OR
  -- الحالة 3: المستخدم admin للسنتر
  center_id IN (
    SELECT id FROM public.centers WHERE admin_user_id = auth.uid()
  )
);

-- سياسة: المعلم يستطيع تعديل مجموعاته
DROP POLICY IF EXISTS "teacher_update_own_groups" ON public.groups;
CREATE POLICY "teacher_update_own_groups"
ON public.groups
FOR UPDATE
USING (
  teacher_id IN (
    SELECT id FROM public.teachers WHERE user_id = auth.uid()
  )
  OR teacher_id = auth.uid()
);


-- ================================================================
-- STEP 2: إصلاح RLS على جدول student_group_enrollments
-- ================================================================

ALTER TABLE public.student_group_enrollments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Teachers can view enrollments of their groups"  ON public.student_group_enrollments;
DROP POLICY IF EXISTS "teacher_enrollments_select"                     ON public.student_group_enrollments;
DROP POLICY IF EXISTS "Enable read access for all users"               ON public.student_group_enrollments;

CREATE POLICY "teacher_select_group_enrollments"
ON public.student_group_enrollments
FOR SELECT
USING (
  group_id IN (
    SELECT g.id FROM public.groups g
    WHERE g.teacher_id IN (
      SELECT id FROM public.teachers WHERE user_id = auth.uid()
    )
    OR g.teacher_id = auth.uid()
  )
  OR
  center_id IN (
    SELECT id FROM public.centers WHERE admin_user_id = auth.uid()
  )
);

-- سياسة: المعلم يستطيع إضافة وتعديل تسجيلات طلاب مجموعاته
DROP POLICY IF EXISTS "teacher_insert_group_enrollments" ON public.student_group_enrollments;
CREATE POLICY "teacher_insert_group_enrollments"
ON public.student_group_enrollments
FOR INSERT
WITH CHECK (
  group_id IN (
    SELECT g.id FROM public.groups g
    WHERE g.teacher_id IN (
      SELECT id FROM public.teachers WHERE user_id = auth.uid()
    )
    OR g.teacher_id = auth.uid()
  )
  OR
  center_id IN (
    SELECT id FROM public.centers WHERE admin_user_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "teacher_update_group_enrollments" ON public.student_group_enrollments;
CREATE POLICY "teacher_update_group_enrollments"
ON public.student_group_enrollments
FOR UPDATE
USING (
  group_id IN (
    SELECT g.id FROM public.groups g
    WHERE g.teacher_id IN (
      SELECT id FROM public.teachers WHERE user_id = auth.uid()
    )
    OR g.teacher_id = auth.uid()
  )
);


-- ================================================================
-- STEP 3: إصلاح RLS على جدول students
-- ================================================================

ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Teachers can view students in their groups"  ON public.students;
DROP POLICY IF EXISTS "teacher_students_select"                      ON public.students;
DROP POLICY IF EXISTS "Enable read access for all users"             ON public.students;

CREATE POLICY "teacher_select_own_students"
ON public.students
FOR SELECT
USING (
  -- الطالب في إحدى مجموعات المعلم
  id IN (
    SELECT sge.student_id
    FROM public.student_group_enrollments sge
    JOIN public.groups g ON g.id = sge.group_id
    WHERE (
      g.teacher_id IN (
        SELECT id FROM public.teachers WHERE user_id = auth.uid()
      )
      OR g.teacher_id = auth.uid()
    )
  )
  OR
  -- admin السنتر يرى جميع الطلاب
  id IN (
    SELECT sge2.student_id
    FROM public.student_group_enrollments sge2
    JOIN public.groups g2 ON g2.id = sge2.group_id
    WHERE g2.center_id IN (
      SELECT id FROM public.centers WHERE admin_user_id = auth.uid()
    )
  )
);

-- سياسة: المعلم يستطيع إضافة طلاب جدد
DROP POLICY IF EXISTS "teacher_insert_students" ON public.students;
CREATE POLICY "teacher_insert_students"
ON public.students
FOR INSERT
WITH CHECK (true); -- المعلم المسجّل يستطيع إضافة طلاب جدد

-- سياسة: المعلم يستطيع تعديل بيانات طلابه
DROP POLICY IF EXISTS "teacher_update_students" ON public.students;
CREATE POLICY "teacher_update_students"
ON public.students
FOR UPDATE
USING (
  id IN (
    SELECT sge.student_id
    FROM public.student_group_enrollments sge
    JOIN public.groups g ON g.id = sge.group_id
    WHERE g.teacher_id IN (
      SELECT id FROM public.teachers WHERE user_id = auth.uid()
    )
    OR g.teacher_id = auth.uid()
  )
);


-- ================================================================
-- STEP 4: إصلاح RLS على جدول teachers (المعلم يرى بياناته)
-- ================================================================

ALTER TABLE public.teachers ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "teacher_select_own_profile"  ON public.teachers;
DROP POLICY IF EXISTS "Enable read access for all"  ON public.teachers;

CREATE POLICY "teacher_select_own_profile"
ON public.teachers
FOR SELECT
USING (
  user_id = auth.uid()
  OR
  -- يمكن لـ admin رؤية جميع المعلمين
  EXISTS (
    SELECT 1 FROM public.teacher_enrollments te
    JOIN public.centers c ON c.id = te.center_id
    WHERE c.admin_user_id = auth.uid()
      AND te.teacher_id = teachers.id
  )
);

DROP POLICY IF EXISTS "teacher_update_own_profile" ON public.teachers;
CREATE POLICY "teacher_update_own_profile"
ON public.teachers
FOR UPDATE
USING (user_id = auth.uid());


-- ================================================================
-- STEP 5: إصلاح RLS على جدول teacher_enrollments
-- ================================================================

ALTER TABLE public.teacher_enrollments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "teacher_select_own_enrollment"  ON public.teacher_enrollments;
DROP POLICY IF EXISTS "Enable read access for all"     ON public.teacher_enrollments;

CREATE POLICY "teacher_select_own_enrollment"
ON public.teacher_enrollments
FOR SELECT
USING (
  teacher_user_id = auth.uid()
  OR
  teacher_id IN (
    SELECT id FROM public.teachers WHERE user_id = auth.uid()
  )
  OR
  center_id IN (
    SELECT id FROM public.centers WHERE admin_user_id = auth.uid()
  )
);


-- ================================================================
-- STEP 6: إصلاح RLS على جدول courses (المعلم يرى المواد)
-- ================================================================

ALTER TABLE public.courses ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "courses_select_policy"        ON public.courses;
DROP POLICY IF EXISTS "Enable read access for all"   ON public.courses;

-- أي مستخدم مسجّل يرى المواد المتاحة في سناتره
CREATE POLICY "authenticated_select_courses"
ON public.courses
FOR SELECT
USING (
  center_id IN (
    SELECT te.center_id FROM public.teacher_enrollments te
    WHERE te.teacher_user_id = auth.uid()
       OR te.teacher_id IN (SELECT id FROM public.teachers WHERE user_id = auth.uid())
  )
  OR
  center_id IN (
    SELECT id FROM public.centers WHERE admin_user_id = auth.uid()
  )
);


-- ================================================================
-- STEP 7: إصلاح RLS على جدول group_schedules / schedules
-- ================================================================

-- group_schedules
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'group_schedules'
  ) THEN
    EXECUTE 'ALTER TABLE public.group_schedules ENABLE ROW LEVEL SECURITY';

    EXECUTE 'DROP POLICY IF EXISTS "teacher_select_group_schedules" ON public.group_schedules';
    EXECUTE 'DROP POLICY IF EXISTS "Teacher Access to Schedules"    ON public.group_schedules';

    EXECUTE $policy$
      CREATE POLICY "teacher_select_group_schedules"
      ON public.group_schedules
      FOR SELECT
      USING (
        group_id IN (
          SELECT g.id FROM public.groups g
          WHERE g.teacher_id IN (SELECT id FROM public.teachers WHERE user_id = auth.uid())
             OR g.teacher_id = auth.uid()
        )
        OR
        center_id IN (
          SELECT id FROM public.centers WHERE admin_user_id = auth.uid()
        )
      )
    $policy$;
  END IF;
END $$;

-- schedules (جدول بديل)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'schedules'
  ) THEN
    EXECUTE 'ALTER TABLE public.schedules ENABLE ROW LEVEL SECURITY';

    EXECUTE 'DROP POLICY IF EXISTS "teacher_select_schedules" ON public.schedules';

    EXECUTE $policy$
      CREATE POLICY "teacher_select_schedules"
      ON public.schedules
      FOR SELECT
      USING (
        group_id IN (
          SELECT g.id FROM public.groups g
          WHERE g.teacher_id IN (SELECT id FROM public.teachers WHERE user_id = auth.uid())
             OR g.teacher_id = auth.uid()
        )
      )
    $policy$;
  END IF;
END $$;


-- ================================================================
-- STEP 8: إصلاح تسجيلات الطلاب التي تفتقر إلى center_id
-- ================================================================
-- هذا يصلح مشكلة إضافة الطلاب بدون center_id (NOT NULL constraint)

-- تحديث أي صفوف موجودة بدون center_id (اجلبها من المجموعة)
UPDATE public.student_group_enrollments sge
SET center_id = g.center_id
FROM public.groups g
WHERE sge.group_id = g.id
  AND sge.center_id IS NULL;


-- ================================================================
-- STEP 9: إصلاح teacher_id في المجموعات إذا كان يحتوي على user_id بدلاً من teachers.id
-- ================================================================
-- إذا كانت المجموعات مُنشأة مع teacher_id = auth.uid() (user_id) بدلاً من teachers.id
-- هذا الإصلاح يستبدل user_id بـ teachers.id الصحيح

UPDATE public.groups g
SET teacher_id = t.id
FROM public.teachers t
WHERE g.teacher_id = t.user_id  -- teacher_id يحتوي على user_id بالخطأ
  AND g.teacher_id != t.id;     -- وليس teachers.id

-- عدد الصفوف المُصلَحة
DO $$
DECLARE
  v_count INTEGER;
BEGIN
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RAISE NOTICE 'تم تصحيح teacher_id في % مجموعة', v_count;
END $$;


-- ================================================================
-- STEP 10: التحقق من النتيجة
-- ================================================================

DO $$
DECLARE
  v_policies_groups INTEGER;
  v_policies_sge    INTEGER;
  v_policies_stu    INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_policies_groups
  FROM pg_policies WHERE tablename = 'groups' AND schemaname = 'public';

  SELECT COUNT(*) INTO v_policies_sge
  FROM pg_policies WHERE tablename = 'student_group_enrollments' AND schemaname = 'public';

  SELECT COUNT(*) INTO v_policies_stu
  FROM pg_policies WHERE tablename = 'students' AND schemaname = 'public';

  RAISE NOTICE '=== النتيجة ===';
  RAISE NOTICE 'سياسات جدول groups: %',                      v_policies_groups;
  RAISE NOTICE 'سياسات جدول student_group_enrollments: %',   v_policies_sge;
  RAISE NOTICE 'سياسات جدول students: %',                    v_policies_stu;
  RAISE NOTICE 'تم تطبيق إصلاح RLS بنجاح ✅';
END $$;
