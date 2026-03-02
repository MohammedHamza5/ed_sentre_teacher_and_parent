-- Enable RLS on tables if not already enabled
ALTER TABLE public.student_group_enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.groups ENABLE ROW LEVEL SECURITY;

-- Policy for Teachers to view their Groups
DROP POLICY IF EXISTS "Teachers can view their own groups" ON public.groups;
CREATE POLICY "Teachers can view their own groups"
ON public.groups
FOR SELECT
USING (
  teacher_id IN (
    SELECT id FROM public.teachers WHERE user_id = auth.uid()
  )
);

-- Policy for Teachers to view Enrollments in their Groups
DROP POLICY IF EXISTS "Teachers can view enrollments of their groups" ON public.student_group_enrollments;
CREATE POLICY "Teachers can view enrollments of their groups"
ON public.student_group_enrollments
FOR SELECT
USING (
  group_id IN (
    SELECT id FROM public.groups 
    WHERE teacher_id IN (
      SELECT id FROM public.teachers WHERE user_id = auth.uid()
    )
  )
);

-- Policy for Teachers to view Students who are in their groups
-- Note: 'students' table might need RLS too, but usually it's public readable or has its own logic.
-- Assuming 'students' is restricted, we need a policy there too.

ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Teachers can view students in their groups" ON public.students;
CREATE POLICY "Teachers can view students in their groups"
ON public.students
FOR SELECT
USING (
  id IN (
    SELECT student_id FROM public.student_group_enrollments
    WHERE group_id IN (
      SELECT id FROM public.groups 
      WHERE teacher_id IN (
        SELECT id FROM public.teachers WHERE user_id = auth.uid()
      )
    )
  )
);
