---
name: edsentre_ecosystem
description: Provides deep system-wide context, business logic, shared database contracts, and architecture definitions for the EdSentre 4-app ecosystem.
---

# 📖 EdSentre Ecosystem Master Knowledge Base

This skill provides the comprehensive context of the **EdSentre Multi-App Ecosystem** to ensure that any AI assistant working on an isolated project remains fully aware of the business logic, database contracts, and integration points of the entire system.

---

## 🏢 1. The 4-App Ecosystem Structure

EdSentre consists of four distinct Flutter/Dart applications sharing a single Supabase backend:

1. **Management App (`ed_sentre`)**
   * **Platforms**: Windows Desktop (primary) + Web.
   * **Role**: Admin ERP for center owners and staff.
   * **Core Workflows**: Billing, student registration, scheduling, printing invoices, automated teacher payroll calculation, audit logs, and checking attendance-payment links.

2. **Student App (`ed_sentre_student`)**
   * **Platforms**: Android + iOS Mobile.
   * **Role**: Gamified learning environment and exam portal.
   * **Core Workflows**: Taking exams/quizzes (Offline-First via Drift), AI Tutor chat, XP/Gamification, and viewing academic progress.

3. **Teacher & Parent App (`ed_sentre_techer_and_parent`)**
   * **Platforms**: Android + iOS Mobile.
   * **Role**: Dual-role application for instructors and guardians.
   * **Core Workflows**: 
     * **Teacher**: Group management, QR attendance scan, AI Exam generation, and entering manual grades.
     * **Parent**: Real-time tracking of student entry/exit, fee notifications, and invite-only secure login.

4. **Super Admin Dashboard (`ed_sentre_super_admin`)**
   * **Platforms**: Windows Desktop.
   * **Role**: Global system administration and telemetry.
   * **Core Workflows**: Subscription management, center verification, AI token quota control, and navigation audit tracking.

---

## 🔑 2. Shared Database & API Contract (Supabase)

All apps interact with a single Supabase instance. Schema and RPC changes represent a shared contract.

### 2.1 Multi-Tenant Data Isolation (RLS)
* The database enforces Center Isolation using Row Level Security (RLS) via a custom SQL function `get_user_center_id()`.
* **Client Constraint**: Clients must **never** attempt to pass `center_id` to bypass security. The backend infers the center context from the user's active session.
* Unexpected empty results from queries must be caught and mapped to `RlsViolationFailure` at the repository level.

### 2.2 Key Database Tables
* `centers`: Central tenant table storing center metadata, subscriptions, and active configurations.
* `users`: Profiles of students, teachers, parents, and admins.
* `students`: Core student records containing parent linkage, academic details, and cumulative XP.
* `courses` & `classes`: Academic schedule definition.
* `attendance`: Clock-in/out records linked to payments.
* `invoices` & `payments`: Financial records (strictly live-fetched, never cached).
* `exams` & `student_grades`: Exam structures, local exam progress (Drift), and final evaluated marks.
* `ai_credits`: Token and credit tracking for AI features (calculated server-side).

### 2.3 Shared RPC Interface (`core/supabase/rpc_caller.dart`)
Any RPC call must go through the typed `RpcCaller` class:
* `rpcCalculateTeacherSalary`: Calculations based on teacher shares and attendance.
* `rpcGetDashboardSummary`: Fast aggregation of financial/academic stats.
* `rpcVerifyParentInviteCode`: Validates parent invite credentials before link creation.

---

## 📡 3. Offline-First & Drift Database Architecture

To survive network drops, `ed_sentre_student` utilizes an offline-first architecture powered by Drift (SQLite).

### 3.1 Local Caching Matrix
* **Cached**: Student profiles, class schedules, assignments, and exam templates (expires after TTL).
* **Live Only**: Invoices, payment history, AI credit balances, and real-time community feeds.
* Every cached table has a `synced_at` column to compare against the local TTL defined in `AppConstants`.

### 3.2 Conflict Resolution Contracts
* **Server Wins**: Default strategy. The server's state overrides local edits if a conflict arises during sync.
* **Last-Write Wins**: Applied exclusively to attendance QR scanning. The device's local scan timestamp is the authority.

---

## 🤖 4. AI Engine Specifications

EdSentre incorporates 7 operational AI services run through Supabase Edge Functions:

| Edge Function Name | Input Data | Expected Output | Client Handling |
| :--- | :--- | :--- | :--- |
| `ai_exam_generator` | PDF/Text Documents | Structured JSON of Questions | Parse via `Model.fromJson` or emit `AiParseFailure` |
| `ai_teacher_assistant` | RAG query + Course ID | Contextual answer / Homework | Standard REST payload |
| `ai_tutor` | Chat history + Question | Token stream (Markdown text) | Progressive stream rendering |
| `oral_exam` | Speech audio | STT transcript + TTS evaluation | Audio stream & JSON score |
| `career_compass` | Academic grades + Profile | Career recommendation report | Structured PDF/Markdown |
| `process_book` | PDF book upload | Embeddings in pgvector | No direct client access (background only) |
| `smart_notifications` | User activity data | Custom push notification text | Local or FCM trigger |

---

## ⚠️ 5. Cross-App Development Guidelines

To prevent breaking changes in a multi-app ecosystem:
1. **Never change a shared table schema** without updating the other apps.
2. **Never change an RPC signature** directly. Create a new versioned RPC (e.g., `rpcCalculateTeacherSalaryV2`) and deprecate the old one.
3. Keep shared models, entities, and constants inside the shared library (`edsentre_shared`).
4. Keep the Router guards robust to prevent role escalation between apps.
