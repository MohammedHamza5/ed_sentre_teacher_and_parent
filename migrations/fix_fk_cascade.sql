-- Fix Foreign Key Constraint on teacher_enrollments
-- This allows updating teachers.user_id without violating the constraint.

-- 1. Drop the old restrictive constraint
ALTER TABLE public.teacher_enrollments
DROP CONSTRAINT IF EXISTS fk_teacher_enrollments_teacher_user_id;

-- 2. Add the new constraint with ON UPDATE CASCADE
ALTER TABLE public.teacher_enrollments
ADD CONSTRAINT fk_teacher_enrollments_teacher_user_id
FOREIGN KEY (teacher_user_id)
REFERENCES public.teachers (user_id)
ON DELETE CASCADE
ON UPDATE CASCADE;

-- 3. (Optional) Verify the constraint change
SELECT * FROM information_schema.referential_constraints 
WHERE constraint_name = 'fk_teacher_enrollments_teacher_user_id';
