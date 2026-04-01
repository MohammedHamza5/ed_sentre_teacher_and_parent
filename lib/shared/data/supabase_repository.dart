import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../shared/models/models.dart';
import 'safe_repository.dart';
import 'base_repository.dart';
import 'mixins/auth_repository_mixin.dart';
import 'mixins/teacher_repository_mixin.dart';
import 'mixins/parent_repository_mixin.dart';
import 'mixins/assignment_repository_mixin.dart';
import 'mixins/materials_repository_mixin.dart';
import 'mixins/messaging_repository_mixin.dart';
import 'mixins/notification_repository_mixin.dart';
import 'mixins/storage_repository_mixin.dart';
import 'mixins/ai_repository_mixin.dart';
import 'mixins/curriculum_repository_mixin.dart';

/// SupabaseRepository - Facade Pattern
/// All methods are now organized into domain-specific mixins for maintainability.
/// This class composes all mixins while maintaining backward compatibility.
///
/// Mixin Breakdown:
/// - AuthRepositoryMixin: Authentication, user profiles, invitation codes
/// - TeacherRepositoryMixin: Groups, students, attendance, schedule, reports, salary
/// - ParentRepositoryMixin: Children, dashboard, grades, payments, parent schedule
/// - AssignmentRepositoryMixin: Assignments and submissions CRUD
/// - MaterialsRepositoryMixin: Study materials and file uploads
/// - MessagingRepositoryMixin: Conversations, messages, realtime
/// - NotificationRepositoryMixin: Notifications and realtime
/// - StorageRepositoryMixin: Generic file storage operations
/// - AIRepositoryMixin: AI Smart Enrollment and analysis
/// - CurriculumRepositoryMixin: Subjects, chapters, and lessons CRUD
class SupabaseRepository extends BaseRepository
    with
        SafeRepositoryMixin,
        AuthRepositoryMixin,
        TeacherRepositoryMixin,
        ParentRepositoryMixin,
        AssignmentRepositoryMixin,
        MaterialsRepositoryMixin,
        MessagingRepositoryMixin,
        NotificationRepositoryMixin,
        StorageRepositoryMixin,
        AIRepositoryMixin,
        CurriculumRepositoryMixin {
  final SupabaseClient _client;

  SupabaseRepository(this._client, [Box? cacheBox]) : super(cacheBox);

  /// Expose the Supabase client - used by all mixins via the abstract getter
  @override
  SupabaseClient get client => _client;

  /// Current user ID helper - used by all mixins via the abstract getter
  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  // ═══════════════════════════════════════════════════════════════════════
  // SHARED / GENERIC (not domain-specific enough for a mixin)
  // ═══════════════════════════════════════════════════════════════════════

  /// Get center by ID
  Future<CenterModel?> getCenterById(String centerId) async {
    final response = await _client
        .from('centers')
        .select()
        .eq('id', centerId)
        .maybeSingle();

    if (response == null) return null;
    return CenterModel.fromJson(response);
  }
}
