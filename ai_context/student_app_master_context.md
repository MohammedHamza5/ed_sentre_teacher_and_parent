# Student App Context for Unified Teacher & Parent App AI

## 1. Project Overview
**Application Name:** EdSentre Student App
**Purpose:** A mobile application for students to manage their educational activities within the EdSentre ecosystem.
**Tech Stack:** 
- **Frontend:** Flutter (Dart)
- **Backend:** Supabase (PostgreSQL, Auth, Edge Functions, Realtime)
- **Local Database:** Drift (SQLite) for Offline Mode
- **State Management:** Provider / Riverpod

## 2. Core Architecture & Data Flow

### 2.1. Authentication & User Identity
- **Supabase Auth:** Users sign up/login via Supabase Auth.
- **Identity Resolution:** 
  - `auth.users.id` (UUID) maps to `public.students.user_id`.
  - Most application logic resolves the **Student ID** (`public.students.id`) from the **User ID** upon login.
- **Context:** The Teacher/Parent app must understand that a "Student" is an entity linked 1:1 to a generic "User" account in the student context.

### 2.2. Enrollment Model (Critical for Teachers)
- **Courses vs Groups:**
  - `courses`: The academic subject (e.g., "Mathematics 101").
  - `groups`: The specific execution of a course (e.g., "Group A - Sat/Mon").
- **Enrollment:**
  - Students enroll in **Groups** (`student_group_enrollments`), not directly in Courses.
  - Teachers are assigned to **Courses** or **Groups** (check `teacher_courses` or `teacher_enrollments`).

### 2.3. Data Fetching Strategy (RPCs)
The Student App relies heavily on Postgres Functions (RPCs) for improved performance and security. The Teacher App should be aware of these data structures:
- `get_student_dashboard_summary(p_user_id, p_center_id)`: aggregating stats.
- `get_student_courses(p_center_id)`: fetching active courses.
- `get_student_schedule(p_day_of_week, p_center_id)`: fetching daily schedule.

## 3. Database Schema - Integration Points

### 3.1. Key Tables
| Table | Key Information | Notes for Teacher App AI |
| :--- | :--- | :--- |
| `students` | `id`, `user_id`, `code`, `full_name` | The recipient of all teacher actions (grades, attendance). |
| `schedules` | `id`, `course_id`, `classroom_id`, `start_time` | Shared resource. **Note:** Uses `classroom_id` FK to `classrooms` table. |
| `notifications` | `user_id`, `is_read`, `title`, `body` | Teacher actions (e.g., "Assignment Graded") trigger inserts here. uses `user_id`. |
| `assignments` | `id`, `subject_id` (links to `courses`) | Teachers create these. Students `submit` answering them. |
| `assignment_submissions` | `assignment_id`, `student_user_id` | Where teachers allow grading. |
| `attendance` | `student_id`, `session_id`, `status` | Teachers mark this; Students view it. |

### 3.2. Recent Schema Nuances (Important!)
*   **Notifications Table:** Uses **`user_id`** column (UUID) and **`is_read`** (boolean). *Do not use `recipient_id` or `read_at`.*
*   **Schedules Table:** Links to rooms via **`classroom_id`**, not `room_id`.
*   **Assignments:** Linked via **`subject_id`** which corresponds to `courses.id`.

### 3.3. Offline Capability
The Student App caches data locally using **Drift**.
*   Teachers should be aware that updates (e.g., changing a grade) might not reflect *instantly* if the student is offline, but real-time subscriptions are in place for online users.

## 4. Feature Parity & Handoffs

### 4.1. Assignments Loop
1.  **Teacher App:** Creates Assignment -> stored in `assignments` table.
2.  **Student App:** Sees assignment in "Pending" list (via `get_student_dashboard_summary`).
3.  **Student App:** Submits work -> stored in `assignment_submissions`.
4.  **Teacher App:** Sees submission, grades it, updates score/feedback.
5.  **Student App:** Receives notification, sees "Graded" status.

### 4.2. Schedule & Attendance
1.  **Teacher App:** Sets up `schedules`.
2.  **Teacher App:** Starts a generic "Session" or Class.
3.  **Teacher App:** Marks attendance for enrolled students.
4.  **Student App:** View in `AttendanceScreen`.

### 4.3. Messaging
- Shared `messages` and `conversations` tables.
- Real-time chat integration is vital for Teacher-Student communication.

## 5. UI/UX Design Language
- **Design System:** Responsive (flutter_screenutil).
- **Theme:** Modern, tiered color palette (Primary, Secondary, Surface).
- **Navigation:** GoRouter based.

## 6. Access & Security
- **RLS (Row Level Security):** Strict policies are in place.
    - Students can only `SELECT` their own data.
    - Teachers have broader `INSERT/UPDATE` rights for their groups.
    - *Teacher App API must ensure it acts with appropriate privileges (or Service Role if acting as Admin).*

---
*Created by EdSentre Student App Dev Agent for seamless ecosystem integration.*
