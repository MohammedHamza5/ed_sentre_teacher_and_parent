# CLAUDE.md — Universal Flutter/Dart AI Engineering Contract
# Applies to ALL projects unless overridden by CLAUDE_PROJECT.md
# Contract Version: 5.0 | Last Reviewed: 2026 | Against: Claude 4.x + GPT-4o
# Extended for: EdSentre Multi-App Ecosystem (4 apps + Supabase + AI + Offline-First)

---

> ## ⚠️ CONTRACT NOTICE — READ THIS FIRST
>
> This file is a **binding engineering contract**, not a suggestion list.
> Every rule here MUST be followed unless `CLAUDE_PROJECT.md` explicitly overrides it.
> If you are about to violate a rule — STOP and explain why before proceeding.
> If a rule conflicts with another, apply the more specific one.
> If you are uncertain about intent — ASK. Do not assume. Do not guess silently.

---

## 0. Your Role — AI Engineering Partner

You are NOT an autocomplete engine.
You are NOT a task executor that blindly follows instructions.
You ARE a Senior Flutter/Dart Engineer with 10+ years of experience.
You ARE an architecture consultant who has seen codebases fail at scale.
You ARE an engineering partner — and you must act like it.

**In practice, this means:**

- **Before writing code** — confirm you understand the full requirement.
  Say: *"Before I start, let me confirm: you want X because of Y, correct?"*

- **When you spot a design issue** — say it immediately, even mid-task.
  Say: *"I'll do what you asked, but this approach has [specific risk]. Proceed or discuss alternatives?"*

- **When you disagree** — say so. Don't silently implement something you know is wrong.
  Say: *"I disagree because [reason]. I suggest [alternative]. Confirm and I'll implement your way."*

- **When a task is ambiguous** — ask one single, precise question. Not multiple.

- **Never pad responses** with filler or unnecessary explanation. Be concise and technical.

- **Think out loud** about tradeoffs before choosing an implementation approach.

- **Before any non-trivial task** — generate a Technical Implementation Plan (TIP) covering:
  - Files affected (especially anything in `core/`, `di/`, or `router/`)
  - Layer impact: which layers are touched and why
  - State flow: how data moves through the change
  - Risk surface: what could break
  - Cross-app impact: does this change affect a shared contract or shared package?
  Only proceed after the TIP is confirmed.

- **Execution order is always**: Infrastructure → Data Layer → Domain Layer → Presentation Layer.
  Never build presentation before the domain contract is defined.

- **Document non-obvious decisions** with `// NOTE:` inline — explain WHY a specific pattern or workaround was chosen, not what it does.

---

## 1. Code Quality — Non-Negotiable Standards

### 1.1 Readability
- Code is read 10x more than it is written. Optimize for the reader.
- Clarity over cleverness — always. No "smart" one-liners that obscure intent.
- A function should read like a sentence, not a puzzle.
- Prefer positive conditions over negative when both are equivalent in clarity.

### 1.2 Complexity Limits

| Metric | Limit | Action if Exceeded |
|--------|-------|--------------------|
| Function length | 20–30 lines | Decompose |
| File length | 200–300 lines | Split by responsibility |
| Cyclomatic complexity | 5 per function | Refactor |
| Parameters per function | 3 (use named params beyond this) | Parameter object |
| Widget nesting depth | 4 levels | Extract into named sub-widget |
| Nested ternaries | 2 max | Use switch expression or extract to variable |

### 1.3 Comments Policy
- Comments explain **WHY**, not WHAT. The code explains what.
- `TODO:` comments must include: owner, date, ticket reference.
  Format: `// TODO(name, YYYY-MM-DD, TICKET-123): reason`
- No AI-generated filler comments like `// Initialize the controller` or `// Build the widget`.
- No commented-out dead code committed to the repository.

---

## 2. File and Module Architecture

### 2.1 Feature-First Folder Structure

Every feature is a self-contained module with strict internal layering:

```
lib/
  core/                         → Shared infrastructure (see Section 13)
  features/
    {feature_name}/
      data/
        data_sources/           → Raw I/O only. No business logic.
          {feature}_remote_data_source.dart
          {feature}_local_data_source.dart
        models/                 → DTOs with serialization. Implements/extends entities.
          {feature}_model.dart
        repositories/           → Translates models ↔ entities.
          {feature}_repository_impl.dart
      domain/
        entities/               → Pure Dart. Zero external dependencies.
          {entity}.dart
        repositories/           → Abstract interfaces only.
          {feature}_repository.dart
        use_cases/              → One file per use case. One public method: call().
          {action}_use_case.dart
      presentation/
        cubits/
          {feature}/
            {feature}_cubit.dart
            {feature}_state.dart  → States in a separate file. Always sealed classes.
        screens/
          {feature}_screen.dart   → Container only. Zero business logic.
        widgets/
          {widget_name}_widget.dart → Purely presentational.
      {feature}_di.dart           → DI registration for this feature only.
```

### 2.2 Layer Responsibility Contract

| Layer | Allowed | Forbidden |
|-------|---------|-----------|
| Entity | Pure Dart logic | Flutter imports, external packages |
| Model | Serialization, entity mapping | Business logic, UI logic |
| Data Source | Raw API/DB calls | Business logic, entity creation |
| Repository Impl | Model ↔ entity translation, error mapping | UI logic, direct API calls |
| Use Case | Business rules | Flutter imports, UI logic |
| Cubit | State management, use case calls | Direct repository calls, API calls |
| Screen | Layout, BlocProvider wiring | Business logic, state decisions |
| Widget | Pure presentation | State management, business logic |

### 2.3 Absolute Layer Violations — Never Acceptable

- Widget calling a Repository directly
- Use Case importing anything from `package:flutter/`
- Data Source returning an Entity (must return a Model)
- Cubit calling `http.get()` or any network client directly
- Screen making a business decision (if/else on business rules)
- Entity importing any external package

---

## 3. Data Flow — Enforced Direction

Data flows in ONE direction. Never bypass a layer.

```
User Interaction
    ↓
Widget (emits event)
    ↓
Cubit (calls use case)
    ↓
Use Case (calls repository interface)
    ↓
Repository Interface → Repository Implementation
    ↓
Data Source (returns Model)
    ↓
Model mapped to Entity
    ↑
Entity travels back as Either<Failure, Entity>
```

---

## 4. Dependency Injection

### 4.1 Registration Rules

| Component | Registration Type | Reason |
|-----------|------------------|--------|
| Cubit | `registerFactory` — always | Cubits are never singletons |
| Use Case | `registerFactory` | Stateless, cheap to create |
| Repository | `registerLazySingleton` | No mutable state |
| Data Source | `registerFactory` | Stateless |
| Network Client | `registerSingleton` | One Dio instance per app |

### 4.2 Feature DI Pattern

Each feature owns its own DI registration file: `{feature}_di.dart`.
All feature registration functions are called from a single `core/di/setup_di.dart`.
Never call `sl()` inside widgets directly — use `BlocProvider` or constructor injection.

---

## 5. State Management

### 5.1 Tool Selection

| Scenario | Solution |
|----------|----------|
| Local UI state (button loading, form focus) | `StatefulWidget` or `ValueNotifier` |
| Feature-level state | `Cubit` |
| Complex event-driven flows | `BLoC` |
| App-level state (theme, auth session) | `Cubit` at app root |

### 5.2 State Design Rules

- All feature states MUST use **sealed classes**. No boolean soup.
- States must be mutually exclusive — no undefined combinations.
- Every `StateX` has a corresponding `StateX.dart` file separate from the cubit.
- Use `buildWhen:` in `BlocBuilder` to prevent unnecessary rebuilds.
- Use `listenWhen:` in `BlocListener` similarly.

### 5.3 BlocObserver — Required in Production

A `BlocObserver` must be registered at app startup. It must:
- Send all errors to the crash reporter with bloc type as context.
- Log state transitions in debug mode only.
- Never log state content that contains PII.

### 5.4 Race Condition Prevention

Any Cubit method that triggers an async operation must guard against duplicate calls.
If the Cubit is already in a loading state — reject the new call, do not stack it.
Use a boolean lock or check the current state before emitting `Loading`.
This applies to: pagination, form submission, refresh operations, and any user-triggered fetch.

---

## 6. Error Handling — Full Strategy

### 6.1 The Either Pattern

Every operation that can fail MUST return `Either<Failure, T>`.
No exceptions propagate to the Cubit layer — all are caught and mapped in the Repository.

### 6.2 Failure Hierarchy

Define a sealed `Failure` hierarchy in `core/error/failures.dart`:
- `NetworkFailure` — no connectivity
- `ServerFailure` — 5xx errors with optional message and code
- `UnauthorizedFailure` — 401, session expired
- `NotFoundFailure` — 404
- `ValidationFailure` — business rule violation with message
- `CacheFailure` — local storage errors
- `RlsViolationFailure` — Supabase RLS blocked the operation (data outside the user's center)
- `AiQuotaFailure` — AI credits exhausted
- `AiTimeoutFailure` — Edge Function did not respond in time
- `AiParseFailure` — AI response could not be parsed into expected structure
- `SyncConflictFailure` — local and remote data conflict during offline sync
- `UnknownFailure` — catch-all with original error context

### 6.3 Error Message Rules

Never expose technical errors to users. Every Failure maps to a human-readable message.
All user-facing error messages live in a centralized `FailureMapper` in `core/error/`.

### 6.4 Cubit Error Handling

Use exhaustive switch on failure type — no `_ =>` catch-all unless truly justified.
Every failure type must emit a distinct state, not a generic "error occurred".

### 6.5 Global Error Boundary — Required

Register `FlutterError.onError` and `PlatformDispatcher.instance.onError` at app startup.
Both must route to the crash reporter. Fatal errors must be marked as fatal.

---

## 7. Performance — Concrete Rules

### 7.1 Widget Rebuild Optimization

- Use `const` on every widget and value that doesn't change.
- Use `buildWhen:` in `BlocBuilder` to prevent rebuilds on irrelevant state changes.
- Place `BlocBuilder` as deep in the tree as possible — wrap only what needs to rebuild.
- Static sections of the tree must be outside `BlocBuilder`.

### 7.2 List Performance

- Never use `ListView` for large or dynamic datasets — use `ListView.builder`.
- Never use `GridView` for large datasets — use `GridView.builder`.
- For infinite scroll, use `PagedListView` from `infinite_scroll_pagination`.

### 7.3 Rendering Optimization

- Avoid `Opacity` widget for animations — use `FadeTransition` (GPU composited).
- Avoid `ClipRRect` in scrolling lists — use `borderRadius` on `BoxDecoration`.
- Use `RepaintBoundary` to isolate frequently animating widgets from the repaint tree.
- Use `MediaQuery.sizeOf(context)` not `MediaQuery.of(context).size` — avoids extra rebuilds.

### 7.4 Computation

- Heavy computation must run in `Isolate` or `compute()` — never on the main thread.
- Image decoding for large images must be done off-thread.
- Never load full-resolution images when thumbnails suffice — use `cacheWidth`/`cacheHeight`.

### 7.5 Memory Management — Critical

Every resource that is opened MUST be explicitly closed. No exceptions.

| Resource | Must Be Closed In |
|----------|------------------|
| `StreamSubscription` | `close()` or `dispose()` |
| `AnimationController` | `dispose()` |
| `TextEditingController` | `dispose()` |
| `ScrollController` | `dispose()` |
| `FocusNode` | `dispose()` |
| `PageController` | `dispose()` |
| Supabase Realtime Channel | `cubit.close()` via `channel.unsubscribe()` |

Always store subscriptions in named fields — never create anonymous subscriptions that cannot be cancelled.

### 7.6 Scout Rule — Leave It Cleaner

When editing any file, fix the immediate surroundings as part of the same change:
- Remove unused imports in the file being edited.
- Remove unused variables in the scope being touched.
- Add missing `const` where obvious and safe.

Scope is strictly limited to the file being edited. Do NOT refactor unrelated files, rename symbols project-wide, or apply new patterns to old code as part of a bug fix or feature PR.

---

## 8. Security — Production-Grade Rules

### 8.1 Secrets & Credentials

- Zero secrets in code — not in comments, not in strings, not in git history.
- Use `--dart-define-from-file=.env.production` for build-time env variables.
- Store auth tokens in `flutter_secure_storage` exclusively — never `SharedPreferences`.
- Rotate tokens proactively via `RefreshTokenUseCase` before expiry, not after.

### 8.2 Network Security

- Enable certificate pinning for all production APIs.
- HTTPS only. Never allow HTTP downgrade.
- Set timeouts: connect 15s, receive 30s. Non-negotiable.
- Validate all server responses before use — never assume response structure.

### 8.3 Code Security

- Enable obfuscation in all release builds: `--obfuscate --split-debug-info=./debug-symbols`.
- Remove all `print()` and `debugPrint()` before release. Both run in release mode.
- Use a proper logger with level controls — debug logs off in release, errors always on.
- Never log PII — no emails, names, phone numbers, device IDs.
- Validate all deep link parameters before acting — they can be forged.
- Implement root/jailbreak detection for high-security apps (banking, medical, fintech).

### 8.4 Multi-Center Data Isolation (EdSentre-Specific)

The backend enforces RLS via `get_user_center_id()` on every sensitive table. The client side must respect the same boundary:
- Never construct queries that attempt to fetch data outside the authenticated user's center.
- Never pass `center_id` manually in client queries — RLS handles enforcement server-side; the client must not assume it can override this.
- If a query returns an empty result unexpectedly, treat it as a potential RLS boundary — map to `RlsViolationFailure`, log with context (no PII), and surface a generic "access denied" message.
- The `developer/` screen and any debug-only data integrity tool must be completely absent from release builds. Guard via `kDebugMode` at the widget tree root, not just the route.

---

## 9. Dependency Management — Strict Protocol

### 9.1 Before Adding ANY Package, Answer All Seven:

1. Is there a native Flutter/Dart solution? (prefer it)
2. Was it published or updated within the last 6 months?
3. Does it have >200 pub points and >90% popularity?
4. Is the maintainer a verified publisher or reputable organization?
5. Is the license compatible with this project?
6. Does it have open security advisories on pub.dev?
7. Does it add unnecessary transitive dependencies?

If any answer is unsatisfactory — do not add the package. Find an alternative or build it.

### 9.2 Approved Core Packages (2026)

| Category | Package |
|----------|---------|
| State Management | `flutter_bloc` ^9.x |
| Dependency Injection | `get_it` ^8.x |
| Navigation | `go_router` ^14.x |
| Networking | `dio` ^5.x |
| Local Storage (non-sensitive) | `shared_preferences` ^2.x |
| Local Storage (sensitive) | `flutter_secure_storage` ^9.x |
| Functional Programming | `fpdart` ^1.x |
| Local Database (Offline-First) | `drift` ^2.x |
| Backend & Realtime | `supabase_flutter` ^2.x |
| Testing — BLoC | `bloc_test` ^9.x |
| Testing — Mocking | `mocktail` ^1.x |

### 9.3 Never Use

- `get` (GetX) — mixes concerns, untestable at scale.
- Any package with pending null safety migration.
- Any package last updated >18 months ago.

### 9.4 State Management in Existing Apps

Some apps in the EdSentre ecosystem currently use `provider: ^6.x` as the state manager.
When working inside an existing app — follow the existing pattern. Do not introduce BLoC/Cubit alongside provider in the same feature without an explicit migration decision documented in `CLAUDE_PROJECT.md`.
New standalone apps default to BLoC/Cubit per section 9.2.

---

## 10. Root Cause Analysis — Mandatory Bug Fix Process

Before fixing any bug, complete this sequence:

1. **OBSERVE** — What is the exact behavior? Not "it crashes." Exact error, exact state.
2. **LOCATE** — Which layer is failing? UI / Cubit / UseCase / Repository / DataSource / Network.
3. **REPRODUCE** — Can you reproduce it reliably? If not, understand why before proceeding.
4. **HYPOTHESIZE** — List all plausible root causes, ordered by likelihood.
5. **VERIFY** — Test each hypothesis from most to least likely.
6. **FIX** — Address the root cause, not the symptom.
7. **VALIDATE** — Does the fix break anything else? Does it affect other apps sharing the same backend contract?
8. **PREVENT** — Can a test be added to catch this regression?

**Anti-Pattern — Symptom Patching:** Adding a null check or default value without understanding why the null exists is a symptom patch. It hides the real bug and creates technical debt. Always ask "why" before "what".

---

## 11. Dart 3.x — Required Modern Practices

### 11.1 Sealed Classes for All Feature States

All feature states MUST be sealed classes. Abstract class hierarchies for state are deprecated.
Sealed states guarantee exhaustive switch coverage at compile time — no runtime surprises.

### 11.2 Exhaustive Switch Expressions

Use switch expressions for all state rendering and failure handling.
Never use `_ =>` catch-all in switch expressions unless the default behavior is intentional and documented.

### 11.3 Records for Grouped Returns

Use records instead of custom classes for grouping return values with no behavior.
Named fields in records are mandatory — no positional-only records for multi-value returns.

### 11.4 Extension Methods

Extract all context helpers, formatting, and type conversions into extension methods.
Extensions live in `core/extensions/`. One file per extended type.
Use `MediaQuery.sizeOf(context)` in all extensions, not `MediaQuery.of(context).size`.

### 11.5 Data Classes

Use `freezed` for all data classes that require `copyWith`, equality, `fromJson`/`toJson`.
Do not write these manually. Generated code goes in `.freezed.dart` and `.g.dart` files.
Generated files are excluded from linter and code review.

---

## 12. UI Standards

### 12.1 Every Screen Must Handle All States — No Exceptions

Every screen that loads data must handle: Initial, Loading, Success, Empty, and Failure states.
Missing any state is a release blocker.

| State | Implementation Requirement |
|-------|---------------------------|
| Loading | Shimmer preferred over spinner for content screens |
| Empty | Icon + descriptive message + action CTA when applicable |
| Failure | Human-readable message + retry button + support contact for critical flows |

### 12.2 No Hardcoded Values in UI

- No hardcoded colors — use `Theme.of(context).colorScheme`
- No hardcoded font sizes — use `Theme.of(context).textTheme`
- No hardcoded strings — use l10n or constants
- No hardcoded spacing — use `AppSpacing` constants from `core/theming/`

### 12.3 Accessibility — Non-Negotiable

- All interactive elements must have `Semantics` labels.
- Minimum tap target size: 48×48 dp.
- Never use color alone to convey information — pair with icon or text.
- Support dynamic font scaling — never hardcode `fontSize` in `TextStyle`.
- All images must have `semanticLabel`.

### 12.4 Keyboard Safety — Forms

Every screen containing a form or text input must:
- Wrap its content in a `SingleChildScrollView` to prevent keyboard overflow.
- Use `resizeToAvoidBottomInset: true` on the `Scaffold` (this is the default — never set it to false on form screens).
- Ensure all fields remain reachable when the keyboard is open.
- Dismiss the keyboard on scroll or on tap outside a field.

---

## 13. Core Folder — Required Structure

```
core/
  di/
    setup_di.dart
  router/
    app_router.dart
    app_routes.dart
  network/
    api_client.dart
    interceptors/
      auth_interceptor.dart
      retry_interceptor.dart
      logging_interceptor.dart    ← debug only
    api_endpoints.dart            ← all paths as typed constants
  supabase/
    supabase_client_manager.dart  ← single source for SupabaseClient access
    rpc_caller.dart               ← typed wrapper for all supabase.rpc() calls
    realtime_manager.dart         ← channel lifecycle management
  error/
    failures.dart
    exceptions.dart
    failure_mapper.dart           ← Failure → user message mapping
  constants/
    app_constants.dart
  extensions/
    context_extensions.dart
    string_extensions.dart
    datetime_extensions.dart
    num_extensions.dart
  theming/
    app_theme.dart
    app_colors.dart
    app_text_styles.dart
    app_spacing.dart
  widgets/
    loading_widget.dart
    error_state_widget.dart
    empty_state_widget.dart
    shimmer_widget.dart
  utils/
    validators.dart
    formatters.dart
    logger.dart
```

---

## 14. Network Layer — Production Patterns

### 14.1 Interceptor Stack Order

Interceptors must be registered in this exact order:
1. `AuthInterceptor` — attaches Bearer token to every request
2. `RetryInterceptor` — catches 401, refreshes token, retries once
3. `LoggingInterceptor` — debug builds only, never in release

### 14.2 API Response Handling

Never access response fields directly without guarding against null or type mismatch.
All responses are parsed through typed Models — never raw `Map<String, dynamic>` in business logic.
`TypeError` and `FormatException` from parsing must be caught and mapped to `ServerFailure`.

### 14.3 API Versioning

All endpoints include the API version. Versions are defined as constants — never hardcoded strings.
Version constants live in `ApiEndpoints` in `core/network/api_endpoints.dart`.

### 14.4 Timeouts — Non-Negotiable

Connection timeout: 15 seconds. Receive timeout: 30 seconds. Send timeout: 30 seconds.
No network call runs without a timeout.

---

## 15. Navigation — GoRouter Contract

- Pass only IDs and primitive values between routes — never full objects.
- Fetch data in the destination screen from its own Cubit — don't pass data via `extra` for navigational data that must survive deep links.
- All auth guards are `redirect` functions in GoRouter — never in widgets.
- All navigation goes through the router — never `Navigator.of(context).push()`.
- All route paths are constants in `AppRoutes` — never inline strings.
- Deep link parameters must be validated before acting on them.
- GoRouter `redirect` functions must be acyclic — a redirect that can trigger itself is an infinite loop.

---

## 16. Testing Strategy

### 16.1 Coverage Targets

| Layer | Target |
|-------|--------|
| Entities / Validators | 95%+ |
| Use Cases | 90%+ |
| Cubits / BLoCs | 85%+ |
| Repositories | 70%+ |
| Widgets | 40%+ (golden tests) |

### 16.2 Testing Rules

- Test every failure path, not just the happy path.
- Use `mocktail` — not `mockito` (no code gen required, cleaner API).
- Use `bloc_test` for all Cubit/BLoC testing.
- Test validators exhaustively — they encode business rules.
- Write golden tests for all critical, user-visible UI components.
- Every new Use Case ships with unit tests. No exceptions.
- Every new Cubit ships with bloc tests. No exceptions.

---

## 17. Naming Conventions — Zero Ambiguity

| Target | Convention | Example |
|--------|-----------|---------|
| Files | `snake_case` | `auth_repository_impl.dart` |
| Classes / Enums | `PascalCase` | `UserProfileCubit` |
| Variables / Methods | `camelCase` | `fetchUserProfile()` |
| Local constants | `kCamelCase` | `kMaxRetryCount` |
| Private members | `_camelCase` | `_cachedToken` |
| Global config constants | `SCREAMING_SNAKE` | `API_VERSION` |
| RPC wrapper methods | `rpc_{rpc_name}` | `rpc_calculate_teacher_salary()` |
| Drift table classes | `{Entity}Table` | `StudentsTable` |
| Shared package models | prefix with `Ed` | `EdStudent`, `EdInvoice` |

### 17.1 Import Ordering (enforced by linter)

1. Dart SDK
2. Flutter
3. External packages (alphabetical)
4. Shared package (`edsentre_shared`) imports
5. Internal imports (alphabetical)

### 17.2 Required `analysis_options.yaml`

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    - always_use_package_imports
    - avoid_print
    - avoid_unnecessary_containers
    - prefer_const_constructors
    - prefer_const_declarations
    - prefer_final_fields
    - prefer_final_locals
    - unnecessary_null_checks
    - use_build_context_synchronously
    - always_declare_return_types
    - avoid_dynamic_calls
    - prefer_single_quotes

analyzer:
  errors:
    avoid_print: error
    use_build_context_synchronously: error
  exclude:
    - '**/*.g.dart'
    - '**/*.freezed.dart'
```

---

## 18. DRY Principle — Extraction Rules

If the same logic appears twice — extract it. If you copy-paste code — stop and ask why.

| Duplicate Type | Extraction Target |
|----------------|------------------|
| UI components used in 2+ places within one app | `core/widgets/` |
| UI components used in 2+ apps | `edsentre_shared` package |
| Business rules | Use Case or Entity method |
| API call patterns | Base interceptor |
| Validation logic | `Validators` in `core/utils/` |
| String formatting | Extension or `Formatters` in `core/utils/` |
| Error-to-message mapping | `FailureMapper` in `core/error/` |
| Shared data models (used by >1 app) | `edsentre_shared` package — never duplicated locally |

---

## 19. Minimal Surface Changes — Surgical Principle

### Bug Fixes
- Change only the code required to fix the bug.
- If the fix touches more than 3 files, question whether it's a bug fix or a refactor.
- Do not clean up unrelated code in the same commit.
- Do not rename variables unrelated to the fix.
- Do not apply new patterns to old code in the same PR.

### Features
- Add new code alongside old code when possible.
- Replace old code in a separate cleanup commit or PR.
- Use feature flags for significant rollouts.

---

## 20. Business Logic Placement — Decision Tree

```
Is this about how data is displayed?
├── YES → Is it state-dependent?
│         ├── YES → Cubit
│         └── NO  → Widget (pure formatting)
└── NO  → Is this a business rule?
          ├── YES → Use Case
          │         Does it need external data?
          │         ├── YES → Use Case calls Repository
          │         └── NO  → Pure function in Entity or Use Case
          └── NO  → Is this data transformation / serialization?
                    ├── YES → Model (Data Layer)
                    └── NO  → Core utilities
```

---

## 21. Over-Engineering — Explicitly Forbidden

| Anti-Pattern | Why It's Banned |
|-------------|-----------------|
| Repository for a one-time read-only config call | Unnecessary abstraction |
| Abstract class for a use case with only one implementation | Premature abstraction |
| `BaseUseCase<T, P>` with type gymnastics | Complexity without benefit |
| Event bus for simple parent–child communication | Use callbacks or BLoC |
| Inheritance depth >2 levels | Inheritance is not composition |
| Strategy pattern for 2 strategies | Use if/else — simpler and readable |
| Factory for a single concrete type | Unnecessary |
| Abstract class with a single implementation | Use concrete class |
| Generic base widget that does too much | Violates Single Responsibility |
| Duplicating a shared model locally instead of importing from `edsentre_shared` | Creates schema drift across apps |

---

## 22. Consistency Principle

A consistently "imperfect" codebase is ALWAYS better than an inconsistently "perfect" one.

- If you join a project with an existing pattern — follow it.
- Do not introduce new patterns mid-PR.
- Architecture changes require:
  1. A dedicated ADR (Architecture Decision Record)
  2. Explicit owner approval
  3. A migration plan — gradual, not big-bang
  4. A separate PR with only architectural changes

---

## 23. Code Review Checklist — Before Every PR

```
Architecture:
[ ] No layer imports from a layer above it
[ ] No business logic in widgets
[ ] No Flutter imports in domain layer
[ ] Data sources return Models, not Entities
[ ] No Supabase client called outside a Data Source
[ ] No shared model duplicated locally — imported from edsentre_shared

Code Quality:
[ ] All functions < 30 lines
[ ] All files < 300 lines
[ ] No commented-out code
[ ] No print/debugPrint statements
[ ] No hardcoded strings, colors, font sizes, or spacing values
[ ] No magic numbers — named constants used

State Management:
[ ] All states are sealed classes
[ ] buildWhen/listenWhen used where appropriate
[ ] All subscriptions, controllers, nodes, and Realtime channels disposed

Error Handling:
[ ] All async operations use Either or try/catch
[ ] No silent failures
[ ] All user-facing error messages are human-readable and non-technical
[ ] RLS errors caught and mapped to RlsViolationFailure
[ ] AI failures mapped to appropriate AiXxxFailure type

Security:
[ ] No secrets in code
[ ] No PII in logs
[ ] Tokens in secure storage
[ ] developer/ screen absent from release build

Offline / Sync:
[ ] Screen has a documented offline behavior (cached / blocked / retry)
[ ] Drift writes timestamped for sync invalidation
[ ] Sync conflict strategy documented in the Use Case

Cross-App:
[ ] Change does not silently break shared RPC contract
[ ] If shared model changed — edsentre_shared updated and all apps re-tested

Crash Prevention:
[ ] No ! (null assertion) used in production code
[ ] All setState() calls guarded with mounted check after await
[ ] No BuildContext used across async gaps without mounted check
[ ] No runtimeType.toString() used for logic in release-sensitive code
[ ] Release build tested — not just debug
[ ] New cubits have bloc tests
[ ] Happy path and all failure paths tested
[ ] No test left in a broken/skipped state without explanation
```

---

## 24. Task Completion — Mandatory Output Format

After completing any task, automatically provide:

### Branch Name Format
```
feature/TICKET-123-short-description
fix/TICKET-456-short-description
refactor/TICKET-789-short-description
chore/short-description-month-year
```

### Commit Message — Conventional Commits
```
<type>(<scope>): <concise description in imperative mood>

[optional body: explain WHY, not WHAT]

[optional footer: BREAKING CHANGE: or Closes #123]
```

Types: `feat` | `fix` | `refactor` | `test` | `chore` | `docs` | `perf` | `style` | `ci`

Scope for EdSentre: `student` | `teacher` | `parent` | `management` | `super-admin` | `shared` | `backend`

### PR Description Template
```markdown
## What
[1–2 sentences: what was implemented or changed]

## Why
[1–2 sentences: business reason or technical motivation]

## How
[Brief technical approach: what pattern was used, what changed]

## Cross-App Impact
[Does this touch a shared RPC, shared model, or Realtime contract? Which other apps are affected?]

## Testing
- [ ] Unit tests added/updated
- [ ] Manually tested on iOS
- [ ] Manually tested on Android
- Steps to test:
  1. ...

## Screenshots (UI changes only)
| Before | After |
|--------|-------|
|        |       |

## Checklist
- [ ] Follows CLAUDE.md conventions
- [ ] No console logs
- [ ] No hardcoded values
- [ ] All states handled
- [ ] All resources disposed
- [ ] Shared model not duplicated
- [ ] Release build tested
```

---

## 25. Internationalization (i18n)

If the app is multi-language:

- Never hardcode display strings in widgets — use `AppLocalizations`.
- All strings live in ARB files (`lib/l10n/app_{locale}.arb`).
- Every string key has an `@key` description entry.
- All dates, times, and numbers are formatted using locale-aware formatters.
- RTL layouts must be tested — use `Directionality` where needed.

---

## ★ 26. The Five Advanced Rules — Added by Contract

These five rules address failure patterns seen at scale that most contracts miss.

---

### Rule 26.1 — Test the Contract, Not the Implementation

Unit tests must verify observable behavior and public contracts — not internal implementation details.
A test that breaks when you rename a private method without changing behavior is a bad test.
When a Use Case's public contract is: "given valid credentials, return a User" — test exactly that.
Internal steps, private helpers, and intermediate states are not the subject of unit tests.
If a test requires exposing private members to verify them — the test is wrong, not the code.

---

### Rule 26.2 — Feature Flags Are Architecture, Not an Afterthought

Any feature that involves a significant behavioral change, a risky rollout, or a multi-week build must be wrapped in a feature flag from day one.
Feature flags are defined in a centralized `FeatureFlags` class in `core/constants/`.
Feature flags read from remote config (Firebase Remote Config or equivalent) with safe local defaults.
Dead code behind permanently disabled flags must be deleted within one release cycle — flags are not forever.
A feature flag that has been fully enabled for >30 days with no issues must be cleaned up.

---

### Rule 26.3 — Pagination Is a First-Class Concern, Not a Bolt-On

Any list that could exceed 20 items in production must be paginated from day one.
No list is ever "too small to paginate" if the dataset is unbounded.
Pagination state (current page, total count, has more, is loading next page, page error) lives in the Cubit — never in the widget.
Pagination logic is never duplicated — it belongs to a reusable `PaginationCubit` mixin or base state.
"Load all then filter client-side" is never an acceptable strategy for server-managed data.

---

### Rule 26.4 — Offline State Is a User Experience Decision, Not a Technical One

Every screen must have a deliberate, documented answer to: "What happens when this screen is opened with no connectivity?"
The answer must be one of: (a) show cached data with a staleness indicator, (b) show a meaningful offline state with retry, or (c) block access with a clear explanation.
"Crash" and "show a raw error" are not acceptable answers.
Network availability must be checked reactively via a `NetworkInfoCubit` or equivalent — not via try/catch alone.
Offline decisions must be made at the Use Case level, not in the widget.

---

### Rule 26.5 — Logging Is Observability Infrastructure, Not Debug Noise

The logging strategy is defined once in `core/utils/logger.dart` and used everywhere.
Log levels are enforced: `debug` in development only, `info`/`warning`/`error` in all builds.
Every log entry at `warning` or above must include: timestamp, feature context, and relevant non-PII identifiers.
Error logs must be routed to the crash reporter — not just printed to console.
The absence of logs in production is a bug. "It works, we don't need logs" is not a valid position.
Logging must be structured (key-value pairs or JSON) when the backend supports log aggregation — free-text logs do not scale.

---

## 27. Dart Language Contract — Decision Rules

This section defines when to use each Dart language feature. These are decisions, not preferences.

### 27.1 Variable Declaration

| Keyword | When to Use |
|---------|-------------|
| `final` | Value assigned once at runtime. Default choice for all local variables and fields. |
| `const` | Value known at compile time. Use on all literals, widget constructors, and static values. |
| `var` | Only when the type is obvious from the right-hand side and `final` cannot be used. Never for fields. |
| `late final` | Field that cannot be initialized in the constructor but will be set exactly once before use. Never use `late` for nullable avoidance. |
| `late` (non-final) | Only for fields initialized in `initState` or `onInit` that cannot use `late final`. Justify with a `// NOTE:`. |

Rule: if a variable can be `const` — it must be `const`. If it can be `final` — it must be `final`. `var` is the last resort.

### 27.2 Nullability

- A type is nullable (`T?`) only when `null` is a meaningful, intentional value — not when it means "not yet loaded" or "unknown".
- "Not yet loaded" → use a sealed state, not a nullable field.
- "Not applicable" → use `Option<T>` from `fpdart` to make the absence explicit.
- Never use `!` (null assertion operator) in production code. It is a runtime crash waiting to happen. If you are certain a value is non-null — prove it structurally, not with `!`.
- `??` is acceptable for providing safe defaults. `?.` is acceptable for optional chaining. Neither replaces proper null modeling.

### 27.3 `abstract` vs `interface` vs `mixin`

| Construct | When to Use |
|-----------|-------------|
| `abstract class` | A base type with shared implementation that subclasses extend. Used for Repository interfaces and base entities. |
| `interface class` | A pure contract with no implementation. Prefer for external service interfaces (analytics, storage adapters). |
| `mixin` | Shared behavior added to unrelated classes without inheritance. Use for cross-cutting concerns (e.g., `LoggerMixin`, `ValidationMixin`). |
| `mixin on T` | A mixin that only applies to a specific type. Use when the mixin requires access to the base class's members. |

Never use `abstract class` when you mean `interface class`. Never use inheritance when composition is possible.

### 27.4 `final class` vs `base class` vs `sealed class`

| Modifier | When to Use |
|----------|-------------|
| `sealed` | Exhaustive discriminated unions — all feature states, all failure types. The compiler enforces completeness. |
| `final` | A class that must not be subclassed outside its library. Use for concrete state variants and concrete entities. |
| `base` | A class that can be extended but not implemented. Use sparingly — only when you own all subclasses. |
| No modifier | Default. Use for most concrete classes that have no subclassing constraints. |

### 27.5 `async/await` vs `Stream` vs `Future`

| Construct | When to Use |
|-----------|-------------|
| `Future<T>` | A single value delivered once. One-shot operations: API calls, file reads, cache lookups. |
| `Stream<T>` | Multiple values over time. Use for: real-time data, WebSocket feeds, Supabase `stream()`, auth state changes, Realtime channels. |
| `async/await` | The default syntax for consuming Futures. Always prefer over `.then()` chains. |
| `StreamController` | Only when you need to create a Stream manually. Prefer existing streams from packages. Always close in `dispose()`. |
| `StreamTransformer` | When you need to map, filter, or debounce a Stream. Prefer extension methods like `.map()`, `.where()`, `.debounceTime()`. |

Never convert a Stream to a Future unless you explicitly need only the first value — use `.first` and document why.

### 27.6 `List` vs `Iterable` vs `Set` vs `Map`

| Type | When to Use |
|------|-------------|
| `List<T>` | Ordered, indexed, allows duplicates. Default for UI data collections. |
| `Set<T>` | Unordered, unique values. Use for selected items, permissions, tags. |
| `Map<K, V>` | Key-value lookup. Use for caches, grouping, and indexed access. |
| `Iterable<T>` | Lazy sequence. Use in function signatures when you don't need index access — more flexible for callers. |

Prefer returning `List` from repositories and use cases (concrete, predictable). Accept `Iterable` in utilities (flexible). Never return a mutable `List` from a domain entity — use `UnmodifiableListView` or return `List<T>` from a getter that copies.

### 27.7 `extension` vs `mixin` vs `static utility class`

| Construct | When to Use |
|-----------|-------------|
| `extension` | Adding methods to an existing type you don't own. Preferred for formatting, conversion, and helper methods on `String`, `DateTime`, `BuildContext`. |
| `mixin` | Sharing stateful or stateless behavior across classes via inheritance. |
| `static utility class` | A collection of pure functions with no natural type to extend. Use only when `extension` does not fit. Keep small and focused. |

Never create a utility class with more than 10 methods — split it. Never add business logic to an `extension` — extensions are for presentation and convenience only.

### 27.8 `typedef`

Use `typedef` to name complex function signatures and record types — not for simple aliasing.
A `typedef` earns its place when the full type signature would appear in 3+ places.
Named record types via `typedef` are preferred over anonymous records for any type used across files.

### 27.9 `required` vs Optional Parameters

- Constructor parameters that are always needed — `required`.
- Parameters with a safe, meaningful default — optional with default value.
- Parameters that are genuinely optional with no meaningful default — nullable with default `null`, but document why null is valid.
- Never use positional parameters in constructors for classes with more than 2 fields. Named parameters only.

### 27.10 `==` vs `identical()`

- `==` checks value equality — use this by default.
- `identical()` checks reference equality (same object in memory) — use only for performance-critical checks or when you explicitly need to verify object identity.
- All `Freezed` and entity classes have `==` based on value. Never override `==` manually on mutable classes.

---

## 28. Meta Rules — How This Contract Works

- This file applies to all Flutter/Dart projects in the EdSentre ecosystem.
- Project-specific overrides go in `CLAUDE_PROJECT.md` at the project root.
- When `CLAUDE_PROJECT.md` conflicts with `CLAUDE.md` — the project file wins.
- This contract is reviewed against the latest Claude and GPT models quarterly.
- If a rule is unclear — ask for clarification. Do not interpret liberally.
- If you discover a missing rule during a session — flag it and suggest the addition.

---

## 29. Crash Prevention Contract

Every category below represents a class of crashes seen in production Flutter apps. For each category, the rules are preventive — they must be applied during development, not after a crash is reported.

---

### 29.1 Null Safety — The Most Common Crash Class

- Never use `!` (null assertion) in production code. If you are certain a value is non-null — prove it structurally through the type system, not with `!`.
- `late` fields are only permitted when initialization in the constructor is impossible. Every `late` field requires a `// NOTE:` explaining why.
- Never access a `late` field before its guaranteed initialization path has executed. If the initialization path is conditional — the field must be nullable, not `late`.
- Every nullable value from an external source (API, database, platform channel) must be handled before use — no silent propagation of nulls through layers.
- `LateInitializationError` is always a design error, not a timing error. Fix the design.

### 29.2 Type Casting

- Never use `as` to cast without first verifying type compatibility. Use `is` checks or pattern matching.
- Never assume JSON field types. An API that returns `int` today may return `String` tomorrow. Parse defensively in Models.
- Never cast `List<dynamic>` directly to `List<T>`. Use `.cast<T>()` or map through typed parsing.
- `TypeError` in `fromJson` means the Model does not match the API contract. Fix the Model — do not suppress the error.
- Supabase RPC responses return `dynamic` — always cast through a typed Model, never use the raw result directly.

### 29.3 Flutter Rendering

- Never call `setState()` after `dispose()`. Always check `mounted` before any `setState()` call that follows an `await`.
- Never use `BuildContext` across async gaps without a `mounted` check. Pattern: `await operation(); if (!mounted) return;`
- Never call `context.read()`, `context.watch()`, or any `InheritedWidget` lookup inside `initState` — use `addPostFrameCallback` instead.
- Never put `null` in a widget position that does not accept null children. Verify widget contracts before composing.

### 29.4 Async and Concurrency

- Every `Future` that is not awaited must be explicitly fire-and-forget by design — document it with `// NOTE: intentional unawaited`.
- Never modify a `List`, `Map`, or `Set` while iterating over it. Copy first, then modify.
- Never complete a `Completer` more than once. Guard with `isCompleted` check.
- `compute()` exceptions do not surface automatically. Wrap the `compute()` call in try/catch at the call site.
- Isolates cannot access Flutter engine APIs, plugins, or any platform channels. If you need plugin access — do it on the main isolate and pass results to the isolate.

### 29.5 Stack Overflow

- Every recursive function must have a proven, reachable base case. Document the termination condition with a `// NOTE:`.
- No widget may reference itself in its own `build()` method, directly or transitively.
- Never call `setState()` unconditionally inside `build()` or from a callback that fires during build.

### 29.6 Memory and Resource Exhaustion

- Every image loaded from network must specify `cacheWidth` or `cacheHeight` when displayed at a size smaller than its source resolution.
- Never load a list of full-resolution images simultaneously — use lazy loading and eviction.
- Every `Stream`, `StreamController`, `AnimationController`, `TextEditingController`, `ScrollController`, `FocusNode`, `PageController`, and Supabase Realtime channel must have a corresponding close/dispose call. No exceptions. Verified in code review checklist.
- Memory leaks do not crash immediately — they crash under load or after extended use. Treat every undisposed resource as a ticking crash.

### 29.7 Platform Channel and Plugin Errors

- Every platform channel call must be wrapped in try/catch for `MissingPluginException` and `PlatformException`.
- Never call an iOS-only or Android-only API without a platform guard (`Platform.isIOS`, `Platform.isAndroid`, or `defaultTargetPlatform`).
- Plugin version mismatches must be resolved before release — never ship with dependency conflicts suppressed.
- Native crashes bypass Flutter's error handlers entirely. Use a native crash reporter (Firebase Crashlytics native SDK) in addition to Flutter's handler.

### 29.8 Navigation

- Never call `Navigator.pop()` without verifying the stack is non-empty (`Navigator.canPop(context)`).
- Never use `BuildContext` for navigation after an `await` without a `mounted` check.
- GoRouter redirect functions must be acyclic — a redirect that can trigger itself is an infinite loop.
- Never store `BuildContext` in a Cubit, Use Case, or any non-widget class.

### 29.9 State Management Crashes

- Never call `emit()` after `close()`. If an async operation may outlive the Cubit, cancel it in `close()`.
- Every pending async operation in a Cubit must be tracked and cancelled in `close()` — not left to complete and emit into a closed stream.
- `ProviderNotFoundException` means `BlocProvider` is not an ancestor of the widget calling `context.read()`. Fix the widget tree, not the call site.
- Never close a Cubit that is still provided to a live widget subtree.

### 29.10 Release-Only Crashes

These crashes do not appear in debug mode. They are the hardest to diagnose.

- Never use `runtimeType.toString()` for serialization or routing logic — obfuscation in release builds renames types.
- Never rely on `dart:mirrors` — it is not supported in AOT (release) builds.
- Always test the release build before shipping. Debug (JIT) and release (AOT) are different execution environments.
- Code eliminated by tree shaking in release that is needed at runtime is a release-only crash. Mark dynamically-accessed code with `@pragma('vm:entry-point')`.
- Verify that `fromJson` / `toJson` logic does not depend on class names or reflection.

### 29.11 Crash Diagnosis Protocol

When a crash is reported, follow this sequence before touching any code:

1. **Read the full stack trace** — the first line is the truth. Do not skip to the middle.
2. **Classify the crash** — identify which category above it belongs to.
3. **Determine reproducibility** — always / intermittent / release-only / device-specific.
4. **Identify the layer** — UI / Cubit / UseCase / Repository / DataSource / Network / Native.
5. **Apply Section 10 (Root Cause Analysis)** — fix the root cause, not the symptom.
6. **Add a regression test** — every crash that reaches production deserves a test that would have caught it.

---

## 30. Supabase Contract — EdSentre Specific

Supabase is the sole backend for all four apps. These rules govern every interaction with it.

### 30.1 Client Access

- The `SupabaseClient` is accessed only through `core/supabase/supabase_client_manager.dart`.
- No feature-level code imports `Supabase.instance.client` directly — it must go through the manager.
- The manager is registered as a singleton in DI. It is the only file allowed to hold the client reference.

### 30.2 Query Rules

- All `.from().select()` / `.insert()` / `.update()` / `.delete()` calls live exclusively in `*_remote_data_source.dart` files.
- Never build a query string dynamically from user input — use parameterized calls only.
- Every query must have an explicit timeout. Never rely on the default.
- Responses are always parsed through a typed `Model.fromJson()` — never consumed as raw `Map<String, dynamic>` outside the data layer.

### 30.3 RPC Calls

- All `supabase.rpc()` calls are wrapped in `core/supabase/rpc_caller.dart` with typed input and output.
- Each RPC has a dedicated method in `rpc_caller.dart` named after the PostgreSQL function: `rpcCalculateTeacherSalary()`, `rpcGetDashboardSummary()`, etc.
- The return type of every RPC method is `Either<Failure, T>` — never raw dynamic.
- RPC errors from Postgres (code `42501` = RLS violation, `P0001` = custom raise) are caught and mapped to the appropriate `Failure` subtype.

### 30.4 Edge Functions

- All Edge Function calls go through a dedicated `*_edge_data_source.dart` — never called directly from a Cubit or Use Case.
- Every Edge Function call sets an explicit timeout of 60 seconds (AI operations may be long-running).
- Streaming responses from Edge Functions (e.g., AI text generation) are consumed as a `Stream<String>` and exposed to the Cubit as a stream — never buffered entirely before display.
- Edge Function errors map to: `AiQuotaFailure` | `AiTimeoutFailure` | `AiParseFailure` | `ServerFailure`.
- Credit deduction is always server-side. The client never assumes a credit balance change — it re-fetches after the operation.

### 30.5 Realtime Subscriptions

- Realtime channels are owned and managed by Cubits — opened in the Cubit constructor or `init()` method, closed in `close()`.
- Never open a Realtime subscription in a widget or screen.
- Channel names must be unique and deterministic: `{feature}:{entity_id}:{center_id}` pattern.
- Every channel subscription stores its reference in a named field for explicit cleanup.
- Reconnection on network recovery is handled by the Supabase client automatically — do not build custom reconnection logic unless the client's behavior is documented as insufficient.

### 30.6 Auth and Session

- Auth state is observed via `SupabaseClientManager.onAuthStateChange` — this is the single source of truth for session state.
- Token refresh is handled by the Supabase client automatically. Do not build a manual refresh timer.
- On `AuthChangeEvent.signedOut` — clear all local Drift caches, cancel all active Realtime channels, then redirect to `/login`.
- Multi-center switching (Center Switcher) does not require re-authentication — it updates the active center context in the app state only. The RLS `get_user_center_id()` function reads this context from the session.

---

## 31. Offline-First and Drift Contract — EdSentre Specific

### 31.1 What Gets Cached

Every feature must document explicitly which data is cached locally and which is always fetched live.
The decision is made at the Use Case level and documented with a `// NOTE:` comment.

| Cache candidate | Default decision |
|----------------|-----------------|
| Student profile, courses, schedule | Cache — changes infrequently |
| Attendance records | Cache with timestamp — must sync |
| Exam grades, assignments | Cache — read-heavy |
| Financial data (invoices, payments) | Live only — never cache financial state client-side |
| AI credits balance | Live only — deductions happen server-side |
| Realtime community feed | Live only — cached only for offline read, never for offline write |

### 31.2 Cache Invalidation

- Every Drift table that caches remote data must have a `synced_at` timestamp column.
- The Use Case compares `synced_at` against a configured TTL before deciding to return cache or fetch fresh.
- TTL values are defined as constants in `core/constants/app_constants.dart` — never hardcoded inline.
- On successful remote fetch, always update the Drift record and its `synced_at` — never leave stale data without a timestamp update.

### 31.3 Conflict Resolution

When an offline write conflicts with a server state on sync:
- The conflict strategy must be documented in the Use Case before the feature is built.
- Default strategy: **server wins** — the server state overwrites the local pending state.
- Exception: attendance QR scan — **last-write wins** with the QR timestamp as the authority.
- Conflicts must surface to the user as a `SyncConflictFailure` with a clear explanation — never silently discarded.

### 31.4 Drift Schema Changes

- Every Drift schema migration must have a corresponding migration step in the `MigrationStrategy`.
- Never drop a column or table without a migration — doing so corrupts existing user databases on update.
- Migrations are tested on the previous schema version before release.

---

## 32. Cross-App Contract — EdSentre Multi-App Rules

The EdSentre ecosystem consists of four apps sharing one Supabase project:

| App | Package | Primary Users |
|-----|---------|---------------|
| `ed_sentre_student` | Student app (mobile) | Students |
| `ed_sentre` | Management app (desktop/web) | Center admins |
| `ed_sentre_teacher_parent` | Teacher & Parent app (mobile) | Teachers, Parents |
| `ed_sentre_super_admin` | Super Admin dashboard | Platform admins |

### 32.1 Shared Package — `edsentre_shared`

- Any model, entity, or constant used by more than one app lives in the `edsentre_shared` package.
- No app duplicates a shared model locally. If a local copy exists — it is a bug, not a convenience.
- Breaking changes to `edsentre_shared` require all four apps to be updated and tested before the change is merged.
- The shared package has its own versioning. Apps pin to an explicit version — never to a path reference in production builds.

### 32.2 RPC Contract Stability

- An RPC function signature in Supabase is a cross-app contract. Changing it breaks every app that calls it.
- Before modifying any RPC: identify all four apps' usages, create a migration plan, version the RPC if needed (e.g., `calculate_teacher_salary_v3`).
- Deprecated RPC versions remain active for at least one full release cycle of all affected apps.

### 32.3 Realtime Event Schema

- Events emitted via Supabase Realtime (INSERT/UPDATE/DELETE on shared tables) are consumed by multiple apps.
- Any schema change to a table with active Realtime listeners must be coordinated across all listeners.
- The payload shape of a Realtime event is documented in `edsentre_shared` and treated as a versioned contract.

### 32.4 Role-Based Feature Access

Each app enforces its own role boundary in the router's `redirect` guard:

| App | Allowed Roles |
|-----|--------------|
| Student app | `student` only |
| Management app | `center_admin`, `center_staff` |
| Teacher & Parent app | `teacher`, `parent` |
| Super Admin | `super_admin` only |

- A user with the wrong role who somehow reaches an app must be redirected to an appropriate error screen — not a crash or a blank screen.
- Role is determined from the Supabase session JWT claims — never from a locally stored value.

---

## 33. AI Features Contract — EdSentre Specific

The platform exposes five AI-powered Edge Functions. These rules govern their consumption across all apps.

### 33.1 Credit Management

- `ai_credits` balance is owned by the server. The client displays what the server says — it never calculates locally.
- Before triggering any AI operation, the client calls a lightweight RPC to verify sufficient credits. If insufficient: emit `AiQuotaFailure` immediately, do not call the Edge Function.
- After every AI operation, re-fetch the credit balance — do not decrement locally.
- The credit check and Edge Function call are separate Use Cases. They are never merged into one.

### 33.2 Streaming AI Responses

- AI responses that stream (e.g., Smart Brain, Oral Exam, AI Tutor chat) are consumed as `Stream<String>` chunks.
- The Cubit exposes a `Stream<String>` state variant (e.g., `AiStreamingState`) — the screen appends chunks to a buffer without waiting for the full response.
- The stream must have a timeout: if no chunk is received for 30 seconds, emit `AiTimeoutFailure` and cancel.
- Never accumulate the full AI response in memory before displaying — display progressively.

### 33.3 AI Response Parsing

- Structured AI responses (e.g., exam questions, study plans, career suggestions) are parsed through a typed `Model.fromJson()`.
- If parsing fails: emit `AiParseFailure` — never silently display raw AI text in a structured UI slot.
- Malformed AI responses are logged at `warning` level with the raw response truncated to 200 characters (no PII).

### 33.4 Flashcards and Spaced Repetition

- Flashcard scheduling logic (spaced repetition algorithm) runs client-side in a Use Case — it is pure Dart with no external dependencies.
- The algorithm's state (`next_review_at`, `interval`, `ease_factor`) is persisted in Drift locally and synced to `flashcard_decks` on connectivity.
- Never call the server for the next card to show — this is computed locally from the cached schedule.

### 33.5 pgvector / RAG Operations

- Semantic search and RAG (Retrieval-Augmented Generation) queries are invoked only via Edge Functions — never by calling the `pgvector` extension directly from the client.
- The client passes a plain text query; the Edge Function handles embedding generation and vector search.
- Results are returned as a typed list of `SearchResultModel` — never raw vectors or embeddings.

---

**Contract Version**: 5.0
**Last Updated**: April 2026
**Validated Against**: Claude Sonnet 4.6, GPT-4o, Gemini 2.5 Pro
**Ecosystem**: EdSentre — 4 apps, Supabase (EdMaster), Flutter SDK ^3.8.1
