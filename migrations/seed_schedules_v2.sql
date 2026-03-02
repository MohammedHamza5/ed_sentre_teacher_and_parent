-- Seed Group Schedules for Testing
-- Center: be0553f2-70a2-4b1a-b773-2f27e74d66b8 (From Logs)

-- Group 1: 17f99f8c-a970-4469-9bbf-409eac0af7d6
-- Monday (2) & Wednesday (4) @ 10:00-11:30
INSERT INTO public.group_schedules (group_id, center_id, day_of_week, start_time, end_time)
VALUES 
('17f99f8c-a970-4469-9bbf-409eac0af7d6', 'be0553f2-70a2-4b1a-b773-2f27e74d66b8', 2, '10:00', '11:30'),
('17f99f8c-a970-4469-9bbf-409eac0af7d6', 'be0553f2-70a2-4b1a-b773-2f27e74d66b8', 4, '10:00', '11:30');

-- Group 2: 895a881f-2cbc-410d-9328-2714535cbca0
-- Sunday (1) & Tuesday (3) @ 12:00-13:30
INSERT INTO public.group_schedules (group_id, center_id, day_of_week, start_time, end_time)
VALUES 
('895a881f-2cbc-410d-9328-2714535cbca0', 'be0553f2-70a2-4b1a-b773-2f27e74d66b8', 1, '12:00', '13:30'),
('895a881f-2cbc-410d-9328-2714535cbca0', 'be0553f2-70a2-4b1a-b773-2f27e74d66b8', 3, '12:00', '13:30');

-- Group 3: 2848bfbd-93d8-42d1-8ffb-0caa8d6f4d3e
-- Friday (6) @ 14:00-15:30
INSERT INTO public.group_schedules (group_id, center_id, day_of_week, start_time, end_time)
VALUES 
('2848bfbd-93d8-42d1-8ffb-0caa8d6f4d3e', 'be0553f2-70a2-4b1a-b773-2f27e74d66b8', 6, '14:00', '15:30');

-- Group 4: 0c2f30d3-0857-4ec0-9add-8f3c9ff115eb
-- Wednesday (4) @ 16:00-17:30 (Later Today)
INSERT INTO public.group_schedules (group_id, center_id, day_of_week, start_time, end_time)
VALUES 
('0c2f30d3-0857-4ec0-9add-8f3c9ff115eb', 'be0553f2-70a2-4b1a-b773-2f27e74d66b8', 4, '16:00', '17:30');

-- Group 5: e40e1891-5797-47f6-8b98-3b70ce0034a4
-- Thursday (5) @ 09:00-10:30
INSERT INTO public.group_schedules (group_id, center_id, day_of_week, start_time, end_time)
VALUES 
('e40e1891-5797-47f6-8b98-3b70ce0034a4', 'be0553f2-70a2-4b1a-b773-2f27e74d66b8', 5, '09:00', '10:30');
