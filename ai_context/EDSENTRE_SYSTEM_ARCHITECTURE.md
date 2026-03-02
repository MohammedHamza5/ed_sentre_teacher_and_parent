# 📘 EdSentre System Architecture & Developer Guide

**Target Audience:** AI Agents & Developers working on the EdSentre Mobile Applications (Teacher & Parent/Student Unified App).
**Version:** 1.0 (Genius Update)
**Backend:** Supabase (PostgreSQL + Edge Functions/RPCs)
**Frontend:** Flutter (Desktop Admin + Mobile Apps)

---

## 1. System Overview
EdSentre is a comprehensive **Educational Center Management System**. It is designed to manage Students, Teachers, Groups, Finance, and Attendance with "Smart" features that automate complex logic (Smart Pricing, Conflict-Free Scheduling, Reactive Billing).

The system consists of:
1.  **Admin Dashboard (Desktop)**: Used by center managers/receptionists to manage everything.
2.  **Teacher App (Mobile)**: For teachers to view schedules, take attendance, and view their finances.
3.  **Student/Parent App (Mobile)**: For tracking attendance, paying fees (invoices), and viewing reports.

---

## 2. Technical Architecture
The project follows a **Clean Architecture** approach with a heavy reliance on **Supabase** for backend logic (keeping the client thin and the data constraint-heavy).

### Key Components
-   **`SupabaseRepository` (`lib/shared/data/supabase_repository.dart`)**: The **Single Source of Truth** for all data operations. It wraps Supabase Client calls and maps generic JSON to strongly typed Models (`lib/shared/models`). **ALL Mobile Apps must use this repository pattern.**
-   **`CenterProvider` (`lib/core/providers/center_provider.dart`)**: Handles Multi-tenancy. Every request is scoped to a `center_id`. Users (Teachers/Students) are linked to Centers.
-   **`AppLogger`**: Custom logging system for debugging RPCs and logic flows.

---

## 3. Database Schema (Supabase / PostgreSQL)

### 👥 Users & Roles
The `users` table is the central identity table (linked to `auth.users` via trigger or manually managed).
-   **`users`**: `id`, `full_name`, `phone`, `email`, `role` (admin, teacher, student, parent), `default_center_id`.
-   **`students`**: Extends user for students. `id`, `grade_level` (e.g., 'ثالثة ثانوي'), `parent_id`, `school`, `balance`.
-   **`teachers`**: Extends user for teachers. `id`, `specializations` (array of subject names), `bio`.
-   **`parents`**: `id`, `user_id`.

### 📚 Education Structure
-   **`courses` (Subjects)**: `id`, `name` (e.g., 'Physics'), `grade_level`.
-   **`groups` (Classes)**: `id`, `course_id`, `teacher_id`, `classroom_id`, `days` (e.g., 'Sat,Mon'), `times`.
-   **`student_group_enrollments`**: Links Student <-> Group. Contains `status` (active, suspended).
-   **`schedules`**: Generated sessions based on Group times.

### 💰 The "Genius" Financial System
This is the most complex part of the system.
-   **`course_prices`**: Defines the "Menu" of prices.
    -   *Logic*: Hierarchical Pricing.
    -   Level 1 (Specific): Matches Subject + Teacher + Grade Level.
    -   Level 2 (Semi-Specific): Matches Subject + Grade Level (Any Teacher).
    -   Level 3 (General): Matches Subject (Any Grade, Any Teacher).
-   **`teacher_salary_tiers`**: Defines commission/salary brackets for teachers based on revenue.
-   **`student_invoices`**: Monthly bills. `id`, `total_amount`, `status` (pending, paid), `due_date`.
-   **`invoice_items`**: Line items *with context*. `course_name`, `amount`, **`teacher_id`**, **`group_id`**, **`grade_level`**.
    -   *Critical*: Storing `teacher_id` and `grade_level` allows the **Reactive Pricing** trigger to know *which* items to update when a price changes.
-   **`payments`**: Actual transactions. `amount`, `payment_method`.

---

## 4. Key Business Logic & RPCs
The mobile app **MUST** use these RPCs instead of raw table inserts/updates for complex operations.

### 🧠 Smart Attendance (`start_attendance_session`)
**Goal**: Start a session for a group and auto-mark students.
-   **Call**: `SupabaseClient.rpc('start_attendance_session', params: { 'p_group_id': ..., 'p_force': true/false })`
-   **Logic**:
    1.  Checks if session already exists for today.
    2.  If not, creates a new `schedules` record (if ad-hoc) or uses existing.
    3.  Fetches all active students in the group.
    4.  Bulk inserts `attendance` records with status `absent` (default) or `present`.
    5.  Returns the session ID.

### 💸 Smart Pricing (`upsert_course_price` & `simulate_price_impact`)
**Goal**: Manage prices and see effect on pending bills.
-   **`upsert_course_price`**: Inserts or Updates price. Handles the "Conflict" logic on unique keys (Subject+Teacher+Grade).
-   **`simulate_price_impact`**: Before saving a price, calling this returns: `impacted_invoices` (count), `revenue_difference` (expected +/-), and `sample_students`.
-   **Trigger `on_course_price_change`**:
    -   When a price is updated in `course_prices`, this trigger fires.
    -   It scans all **PENDING** `invoice_items` that match the subject/teacher/grade logic.
    -   It recalculates their price using `get_smart_price`.
    -   It updates the item amount and the invoice total.
    -   *Result*: You change the price, and 1000 pending bills update instantly.

### 📅 Smart Enrollment (`suggest_best_groups_for_student`)
**Goal**: Recommend groups for a student based on their grade and *availability*.
-   **Input**: Student ID, List of Course IDs.
-   **Logic**:
    1.  Finds groups for those courses matching Student's Grade.
    2.  Checks for time conflicts with Student's existing approved schedule.
    3.  Checks for Group Capacity ("Full" or not).
    4.  Returns a list of "Best Fit" groups with reasons.

### 📊 Reports
-   **`get_student_dashboard_summary`**: (For Student App) Returns:
    -   `next_session`: { course_name, time, room }
    -   `attendance_stats`: { present, absent, rate }
    -   `due_balance`: Total unpaid invoices.
    -   `latest_notifications`.

---

## 5. Mobile App Developer Guide (AI Instructions)

### A. Teacher App
**Primary Features**:
1.  **Schedule View**: Use `get_teacher_schedule(teacher_id, date_range)`.
2.  **Take Attendance**:
    -   Select Group -> Call `start_attendance_session`.
    -   List Students -> Toggle Present/Absent/Late locally -> Helper `save_attendance_bulk`.
    -   *QR Code Mode*: App scans Student QR -> Matches Student ID -> Updates local list -> Synced to DB.
3.  **My Students**: `rpc('get_teacher_students')`.
4.  **Financials**: `rpc('get_teacher_financial_report')` (Shows commission, total sessions, earnings).

### B. Parent/Student App
**Primary Features**:
1.  **Home Dashboard**: Call `get_student_dashboard_summary`.
    -   Show "Next Class" prominently.
    -   Show "Payment Due" alert if `due_balance > 0`.
2.  **Schedule**: Display weekly calendar.
3.  **Financials (Invoices)**:
    -   List `student_invoices`.
    -   Detail View: Show `invoice_items`.
    -   **Pay Now**: Integration with Payment Gateway -> On Success -> Insert `payments` record -> Trigger `settle_invoice` RPC (auto-updates invoice status to 'paid').
4.  **Attendance History**: List `attendance` records. Color code (Green=Present, Red=Absent).

### C. Common UX Patterns
-   **Offline First**: Use `hive` or `shared_preferences` to cache Schedule and Profile.
-   **Notifications**: Supabase Realtime is enabled on `notifications` table. Listen to `INSERT` where `recipient_id == current_user_id`.

## 6. Critical Warnings ⚠️
1.  **Never delete invoices manually**. Use RPCs or void them to ensure financial integrity.
2.  **Timezones**: Stored as UTC in DB. UI must convert to Local Time.
3.  **RLS (Row Level Security)**:
    -   Student App can ONLY read their own data (`auth.uid() == user_id`).
    -   Teacher App can ONLY read their Groups/Students.
    -   Do not try to bypass RLS; if data is missing, check the Policy in Supabase.

---
**End of Documentation**
