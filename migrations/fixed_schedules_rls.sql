-- Simplify RLS for group_schedules to ensure teachers can see them.
ALTER TABLE public.group_schedules ENABLE ROW LEVEL SECURITY;

-- Remove potentially conflicting or complex policies (optional, but good for cleanup)
-- We'll add a new robust policy.

DROP POLICY IF EXISTS "Teacher Access to Schedules" ON public.group_schedules;

CREATE POLICY "Teacher Access to Schedules"
ON public.group_schedules
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.teacher_enrollments
    WHERE teacher_enrollments.center_id = group_schedules.center_id
    AND teacher_enrollments.teacher_user_id = auth.uid()
    AND teacher_enrollments.status = 'active'
  )
);

-- Ensure Dashboard Stats queries can execute
-- "getTeacherDashboardStats" queries: groups, student_group_enrollments, group_schedules, assignment_submissions, messages.

-- Fix specific RLS for assignment_submissions if needed
-- The existing one seemed complex. Let's add a simple one for teachers.

DROP POLICY IF EXISTS "Teacher View Submissions" ON public.assignment_submissions;

CREATE POLICY "Teacher View Submissions"
ON public.assignment_submissions
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.assignments
    WHERE assignments.id = assignment_submissions.assignment_id
    AND assignments.teacher_user_id = auth.uid()
  )
);
