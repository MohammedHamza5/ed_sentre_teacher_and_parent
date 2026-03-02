-- Align Group Schedules with Group Names to avoid confusion
-- Center: be0553f2-70a2-4b1a-b773-2f27e74d66b8

-- Cleanup previous seeds (optional, but good practice to avoid duplicates if we didn't use ON CONFLICT)
DELETE FROM public.group_schedules WHERE center_id = 'be0553f2-70a2-4b1a-b773-2f27e74d66b8';

-- 1. "Chemistry - 2nd Sec - Friday" (17f99f8c...)
-- Name says Friday -> Schedule: Friday (6)
INSERT INTO public.group_schedules (group_id, center_id, day_of_week, start_time, end_time)
VALUES ('17f99f8c-a970-4469-9bbf-409eac0af7d6', 'be0553f2-70a2-4b1a-b773-2f27e74d66b8', 6, '14:00', '15:30');

-- 2. "Chemistry - 1st Sec" (895a881f...)
-- Generic name -> Schedule: Tuesday (3) AND Wednesday (4) [To show TODAY]
INSERT INTO public.group_schedules (group_id, center_id, day_of_week, start_time, end_time)
VALUES 
('895a881f-2cbc-410d-9328-2714535cbca0', 'be0553f2-70a2-4b1a-b773-2f27e74d66b8', 3, '12:00', '13:30'),
('895a881f-2cbc-410d-9328-2714535cbca0', 'be0553f2-70a2-4b1a-b773-2f27e74d66b8', 4, '12:00', '13:30');

-- 3. "Chemistry - 3rd Sec" (2848bfbd...)
-- Generic name -> Schedule: Monday (2)
INSERT INTO public.group_schedules (group_id, center_id, day_of_week, start_time, end_time)
VALUES ('2848bfbd-93d8-42d1-8ffb-0caa8d6f4d3e', 'be0553f2-70a2-4b1a-b773-2f27e74d66b8', 2, '10:00', '11:30');

-- 4. "Chemistry - 2nd Sec" (0c2f30d3...)
-- Generic name -> Schedule: Wednesday (4) [To show TODAY]
INSERT INTO public.group_schedules (group_id, center_id, day_of_week, start_time, end_time)
VALUES ('0c2f30d3-0857-4ec0-9add-8f3c9ff115eb', 'be0553f2-70a2-4b1a-b773-2f27e74d66b8', 4, '16:00', '17:30');

-- 5. "Chemistry - 3rd Sec - Saturday" (e40e1891...)
-- Name says Saturday -> Schedule: Saturday (0)
INSERT INTO public.group_schedules (group_id, center_id, day_of_week, start_time, end_time)
VALUES ('e40e1891-5797-47f6-8b98-3b70ce0034a4', 'be0553f2-70a2-4b1a-b773-2f27e74d66b8', 0, '09:00', '10:30');
