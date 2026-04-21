import '../base_repository.dart';

import 'teacher_profile_mixin.dart';
import 'teacher_groups_mixin.dart';
import 'teacher_attendance_mixin.dart';
import 'teacher_schedule_mixin.dart';
import 'teacher_dashboard_mixin.dart';
import 'teacher_reports_mixin.dart';

// NOTE: Re-export all sub-mixins so existing imports of this file continue to work.
export 'teacher_profile_mixin.dart';
export 'teacher_groups_mixin.dart';
export 'teacher_attendance_mixin.dart';
export 'teacher_schedule_mixin.dart';
export 'teacher_dashboard_mixin.dart';
export 'teacher_reports_mixin.dart';

/// Composite mixin that combines all teacher sub-mixins.
/// This preserves backward compatibility — any class that previously used
/// `TeacherRepositoryMixin` will continue to compile without changes.
mixin TeacherRepositoryMixin
    on
        BaseRepository,
        TeacherProfileMixin,
        TeacherGroupsMixin,
        TeacherAttendanceMixin,
        TeacherScheduleMixin,
        TeacherDashboardMixin,
        TeacherReportsMixin {
}
