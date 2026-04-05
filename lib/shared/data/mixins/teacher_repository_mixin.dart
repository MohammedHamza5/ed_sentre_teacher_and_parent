import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/models.dart';
import '../base_repository.dart';

/// Teacher Repository Mixin
/// Handles all teacher-specific data operations:
/// groups, students, attendance, schedule, dashboard, reports, salary
mixin TeacherRepositoryMixin on BaseRepository {
  SupabaseClient get client;
  String? get currentUserId;

  // ═══════════════════════════════════════════════════════════════════════
  // TEACHER PROFILE & CENTERS
  // ═══════════════════════════════════════════════════════════════════════

  /// Get teacher record by user ID
  Future<TeacherModel?> getTeacherByUserId(String userId) async {
    final response = await client
        .from('teachers')
        .select('*, users!inner(full_name, phone, avatar_url)')
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;
    return TeacherModel.fromJson(response);
  }

  /// Get teacher's centers (using teacher_enrollments table)
  ///
  /// ⚠️  Schema Inconsistency Workaround:
  /// ─────────────────────────────────────────────────────────────────────
  /// بعض السجلات في teacher_enrollments تستخدم `teacher_user_id`
  /// (= auth user UUID)، وأخرى تستخدم `teacher_id` (= teachers.id UUID).
  ///
  /// هذا يحدث عندما يُنشأ بعض السجلات عبر trigger يُسجّل user_id مباشرةً،
  /// وأخرى عبر Admin panel يُسجّل teacher_id من جدول teachers.
  ///
  /// الحل المثالي: توحيد الـ schema في Supabase (migration) لضمان أن
  /// جميع السجلات تستخدم نفس الـ identifier.
  /// حتى ذلك الحين، نجرّب الاحتمالات الأربعة بترتيب.
  /// ─────────────────────────────────────────────────────────────────────
  Future<List<CenterModel>> getTeacherCentersEnrolled(
    String teacherUserId, {
    String? teacherTableId,
  }) async {
    // قائمة بأزواج (عمود، قيمة) نجرّبها بالترتيب حتى نجد نتيجة غير فارغة
    final idsToTry = <(String field, String value)>[
      ('teacher_user_id', teacherUserId),
      ('teacher_id', teacherUserId),
      if (teacherTableId != null && teacherTableId != teacherUserId) ...[
        ('teacher_id', teacherTableId),
        ('teacher_user_id', teacherTableId),
      ],
    ];

    for (final (field, value) in idsToTry) {
      final response = await client
          .from('teacher_enrollments')
          .select('centers!inner(*)')
          .eq(field, value)
          .eq('status', 'active');

      if ((response as List).isNotEmpty) {
        debugPrint(
          '✅ [TeacherRepo] Found centers via $field=$value '
          '(${response.length} centers)',
        );
        return response.map((e) => CenterModel.fromJson(e['centers'])).toList();
      }
    }

    debugPrint(
      '⚠️  [TeacherRepo] No centers found for userId=$teacherUserId'
      '${teacherTableId != null ? " / teacherId=$teacherTableId" : ""}. '
      'Check teacher_enrollments schema consistency.',
    );
    return [];
  }

  /// Get user's centers (teacher enrollments)
  Future<List<CenterModel>> getTeacherCenters(String teacherId) async {
    final response = await client
        .from('teacher_enrollments')
        .select('centers!inner(*)')
        .eq('teacher_id', teacherId)
        .eq('status', 'active');

    return (response as List)
        .map((e) => CenterModel.fromJson(e['centers']))
        .toList();
  }

  /// Get teacher enrollment details for a specific center (includes salary info)
  Future<TeacherEnrollmentModel?> getTeacherEnrollment({
    required String centerId,
    required String teacherUserId,
  }) async {
    final response = await client
        .from('teacher_enrollments')
        .select()
        .eq('center_id', centerId)
        .eq('teacher_user_id', teacherUserId)
        .eq('status', 'active')
        .maybeSingle();

    if (response == null) return null;
    return TeacherEnrollmentModel.fromJson(response);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // GROUPS & STUDENTS
  // ═══════════════════════════════════════════════════════════════════════

  /// Get teacher's groups (classes)
  Future<List<GroupModel>> getTeacherGroups(
    String teacherId,
    String centerId,
  ) async {
    debugPrint(
      '🔎 [Repo] getTeacherGroups: Teacher=$teacherId, Center=$centerId',
    );
    debugPrint('🔎 [Repo] getTeacherGroups: START');
    debugPrint('   - TeacherID: $teacherId');
    debugPrint('   - CenterID: $centerId');
    try {
      debugPrint('   - Querying groups table...');
      // ✅ FIX: Added center_id filter, is_active=true, deleted_at IS NULL
      var response = await client
          .from('groups')
          .select('*, courses(name)')
          .eq('teacher_id', teacherId)
          .eq('center_id', centerId)
          .eq('is_active', true)
          .isFilter('deleted_at', null)
          .order('day_of_week');

      debugPrint(
        '✅ [Repo] getTeacherGroups: Found ${(response as List).length} groups'
        ' (teacher=$teacherId, center=$centerId)',
      );

      final groupModels = (response as List)
          .map(
            (e) => GroupModel.fromJson({
              ...e,
              'course_name': e['courses']?['name'],
            }),
          )
          .toList();

      if (groupModels.isNotEmpty) {
        final groupIds = groupModels.map((g) => g.id).toList();
        debugPrint(
          '🔍 [Repo] Fetching schedules (from schedules table) for Group IDs: $groupIds',
        );

        // ✅ FIX: Try 'group_schedules' first (canonical table), fallback to 'schedules'
        List allScheduleRows = [];
        try {
          final schedulesResponse = await client
              .from('group_schedules')
              .select('*, classrooms(name)')
              .inFilter('group_id', groupIds);
          allScheduleRows = schedulesResponse as List;
          debugPrint(
            '✅ [Repo] Loaded ${allScheduleRows.length} rows from group_schedules',
          );
        } catch (e1) {
          debugPrint(
            '⚠️ [Repo] group_schedules failed ($e1), trying schedules table...',
          );
          try {
            final schedulesResponse = await client
                .from('schedules')
                .select('*, classrooms(name)')
                .inFilter('group_id', groupIds);
            allScheduleRows = schedulesResponse as List;
            debugPrint(
              '✅ [Repo] Loaded ${allScheduleRows.length} rows from schedules (fallback)',
            );
          } catch (e2) {
            debugPrint('⚠️ [Repo] Both schedule tables failed: $e2');
          }
        }

        final allSchedules = allScheduleRows.map((e) {
          final roomName = e['classrooms']?['name'] as String?;
          return ScheduleItem.fromJson({...e, 'room_name': roomName});
        }).toList();

        debugPrint(
          '✅ [Repo] Found ${allSchedules.length} total schedule items',
        );

        for (var i = 0; i < groupModels.length; i++) {
          final groupSchedules = allSchedules
              .where((s) => s.groupId == groupModels[i].id)
              .toList();
          groupModels[i] = groupModels[i].copyWith(schedules: groupSchedules);
          debugPrint(
            '   👉 Group "${groupModels[i].groupName}" has ${groupSchedules.length} schedules',
          );
        }
      }

      debugPrint(
        '   - Parsed ${groupModels.length} GroupModels with schedules',
      );
      debugPrint('🔎 [Repo] getTeacherGroups: END');
      return groupModels;
    } catch (e, stack) {
      debugPrint('❌ [Repo] getTeacherGroups Error: $e');
      debugPrint('   Stack: $stack');
      return [];
    }
  }

  /// Get teacher's students for a specific group
  Future<List<Map<String, dynamic>>> getGroupStudents(String groupId) async {
    final response = await client
        .from('student_group_enrollments')
        .select('*, students!inner(id, full_name, phone, avatar_url)')
        .eq('group_id', groupId)
        .eq('status', 'active');

    return List<Map<String, dynamic>>.from(response);
  }

  /// Get teacher's students
  Future<List<Map<String, dynamic>>> getTeacherStudents({
    required String teacherId,
    required String centerId,
    int? limit,
    int? offset,
  }) async {
    debugPrint('🔎 [Repo] getTeacherStudents: START');
    debugPrint('   - TeacherID: $teacherId');
    debugPrint('   - CenterID: $centerId');

    try {
      debugPrint('   - calling getTeacherGroups...');
      final groups = await getTeacherGroups(teacherId, centerId);
      debugPrint(
        '   - Found ${groups.length} groups for teacher (via getTeacherGroups)',
      );

      if (groups.isEmpty) {
        debugPrint('⚠️ No groups found. Returning empty list.');
        return [];
      }
      final groupIds = groups.map((g) => g.id).toList();
      debugPrint('ℹ️ Filtering by Group IDs: $groupIds');

      debugPrint('🚀 Executing Supabase Query on student_group_enrollments...');

      var query = client
          .from('student_group_enrollments')
          .select('''
            id,
            group_id,
            student_id,
            status,
            students!inner(
              id,
              user_id,
              full_name,
              phone,
              avatar_url,
              student_code
            )
          ''')
          .inFilter('group_id', groupIds)
          .eq('status', 'active')
          .order('id', ascending: false);
      if (limit != null && offset != null) {
        query = query.range(offset, offset + limit - 1);
      } else if (limit != null) {
        query = query.limit(limit);
      }
      final response = await query;

      debugPrint('✅ Response received from DB.');
      final listData = response as List;
      debugPrint('   - Rows count: ${listData.length}');
      if (listData.isNotEmpty) {
        debugPrint('   - First Row: ${listData.first}');
      } else {
        debugPrint('⚠️ [Repo] Query returned EMPTY list.');
      }

      final data = List<Map<String, dynamic>>.from(listData);

      return data.map((e) {
        final student = e['students'] as Map<String, dynamic>;
        final groupId = e['group_id'] as String;

        final group = groups.firstWhere(
          (g) => g.id == groupId,
          orElse: () => GroupModel(
            id: groupId,
            groupName: 'Unknown',
            teacherId: teacherId,
            centerId: centerId,
            courseId: '',
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        return {
          'id': student['id'],
          'user_id': student['user_id'],
          'student_user_id': student['user_id'],
          'student_name': student['full_name'],
          'student_phone': student['phone'],
          'student_avatar': student['avatar_url'],
          'student_code': student['student_code'],
          'group_id': group.id,
          'group_name': group.groupName,
          'course_name': group.courseName ?? 'مادة',
          'enrollment_id': e['id'],
        };
      }).toList();
    } catch (e, stack) {
      debugPrint('❌ [Repo] getTeacherStudents Error: $e');
      debugPrint('   Stack: $stack');
      return [];
    }
  }

  /// Add a new student and enroll them in a group
  Future<void> addStudent({
    required String fullName,
    required String phone,
    required String gradeLevel,
    required String groupId,
    required String centerId,
    String? code,
  }) async {
    final studentCode = code ?? _generateStudentCode();

    final studentResponse = await client
        .from('students')
        .insert({
          'full_name': fullName,
          'phone': phone,
          'student_code': studentCode,
          'grade_level': gradeLevel,
        })
        .select('id')
        .single();

    final studentId = studentResponse['id'] as String;

    // ✅ FIX: Added center_id (NOT NULL in schema)
    await client.from('student_group_enrollments').insert({
      'student_id': studentId,
      'group_id': groupId,
      'center_id': centerId,
      'status': 'active',
      'enrollment_date': DateTime.now().toIso8601String(),
    });
  }

  String _generateStudentCode() {
    final now = DateTime.now().millisecondsSinceEpoch.toString();
    return 'WS-${now.substring(now.length - 6)}';
  }

  /// Suggest best groups for a student
  Future<List<Map<String, dynamic>>> suggestBestGroups({
    required String centerId,
    required String courseId,
    String? studentId,
    String? gradeLevel,
  }) async {
    try {
      final response = await client.rpc(
        'suggest_best_groups_for_student',
        params: {
          'p_center_id': centerId,
          'p_course_id': courseId,
          'p_student_id': studentId,
          'p_grade_level': gradeLevel,
        },
      );
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error suggesting groups: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ATTENDANCE
  // ═══════════════════════════════════════════════════════════════════════

  /// Start attendance session
  Future<Map<String, dynamic>> startAttendanceSession({
    required String groupId,
    required String centerId,
    bool force = false,
  }) async {
    final response = await client.rpc(
      'start_attendance_session',
      params: {
        'p_group_id': groupId,
        'p_center_id': centerId,
        'p_force': force,
      },
    );
    return response as Map<String, dynamic>;
  }

  /// Save attendance for multiple students
  Future<void> saveAttendanceBulk({
    required String centerId,
    required String groupId,
    required String sessionId,
    required List<Map<String, dynamic>> attendanceList,
  }) async {
    for (final item in attendanceList) {
      await client.from('attendance').upsert({
        'center_id': centerId,
        'group_id': groupId,
        'session_id': sessionId,
        'student_id': item['student_id'],
        'status': item['status'],
        'attendance_date': DateTime.now().toIso8601String().split('T')[0],
        'notes': item['notes'],
      });
    }
  }

  /// Get attendance monitor data for a specific group and date
  Future<List<Map<String, dynamic>>> getGroupAttendanceForToday(
    String groupId, {
    DateTime? date,
  }) async {
    final targetDate = date ?? DateTime.now();
    final startOfDay = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
    ).toIso8601String();
    final endOfDay = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      23,
      59,
      59,
    ).toIso8601String();

    try {
      final studentsResponse = await client
          .from('student_group_enrollments')
          .select('''
            student_id,
            students:students!inner(
              id,
              full_name,
              avatar_url,
              student_code
            )
          ''')
          .eq('group_id', groupId)
          .eq('status', 'active');

      final students = List<Map<String, dynamic>>.from(
        studentsResponse as List,
      );

      final attendanceResponse = await client
          .from('attendance')
          .select('student_id, status, check_in_time')
          .eq('group_id', groupId)
          .gte('attendance_date', startOfDay)
          .lte('attendance_date', endOfDay);

      final attendanceRecords = List<Map<String, dynamic>>.from(
        attendanceResponse as List,
      );

      return students.map((enrollment) {
        final student = enrollment['students'] as Map<String, dynamic>;
        final studentId = enrollment['student_id'];

        final record = attendanceRecords.firstWhere(
          (r) => r['student_id'] == studentId,
          orElse: () => {},
        );

        return {
          'id': student['id'],
          'student_id': studentId,
          'name': student['full_name'],
          'code': student['student_code'],
          'avatar_url': student['avatar_url'],
          'attendance_status': record.isNotEmpty ? record['status'] : 'pending',
          'check_in_time': record['check_in_time'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching group attendance: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getGroupAttendanceHistory({
    required String groupId,
    int days = 30,
    int offsetDays = 0,
  }) async {
    try {
      final endDate = DateTime.now().subtract(Duration(days: offsetDays));
      final startDate = endDate.subtract(Duration(days: days - 1));
      final fromDateString = startDate.toIso8601String().split('T')[0];
      final toDateString = endDate.toIso8601String().split('T')[0];

      final studentsResponse = await client
          .from('student_group_enrollments')
          .select('id')
          .eq('group_id', groupId)
          .eq('status', 'active');

      final totalStudents = (studentsResponse as List).length;

      final attendanceResponse = await client
          .from('attendance')
          .select('attendance_date, status')
          .eq('group_id', groupId)
          .gte('attendance_date', fromDateString)
          .lte('attendance_date', toDateString)
          .order('attendance_date', ascending: false);

      final records = List<Map<String, dynamic>>.from(
        attendanceResponse as List,
      );

      final Map<String, Map<String, dynamic>> grouped = {};

      for (final record in records) {
        final rawDate = record['attendance_date'];
        String dateKey;
        if (rawDate is String) {
          dateKey = rawDate.split('T')[0];
        } else if (rawDate is DateTime) {
          dateKey = rawDate.toIso8601String().split('T')[0];
        } else {
          dateKey = rawDate.toString().split(' ')[0];
        }

        grouped.putIfAbsent(dateKey, () {
          return {
            'date': DateTime.parse(dateKey),
            'present': 0,
            'absent': 0,
            'late': 0,
            'total': totalStudents,
          };
        });

        final status = record['status'] as String?;
        if (status == 'present') {
          grouped[dateKey]!['present'] =
              (grouped[dateKey]!['present'] as int) + 1;
        } else if (status == 'late') {
          grouped[dateKey]!['late'] = (grouped[dateKey]!['late'] as int) + 1;
        } else if (status == 'absent') {
          grouped[dateKey]!['absent'] =
              (grouped[dateKey]!['absent'] as int) + 1;
        }
      }

      final list = grouped.values.toList()
        ..sort((a, b) {
          final ad = a['date'] as DateTime;
          final bd = b['date'] as DateTime;
          return bd.compareTo(ad);
        });

      return list;
    } catch (e) {
      debugPrint('Error fetching attendance history: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SCHEDULE
  // ═══════════════════════════════════════════════════════════════════════

  /// Get teacher's schedule
  Future<List<ScheduleItem>> getTeacherSchedule({
    required String teacherId,
    required String centerId,
    String? dayOfWeek,
  }) async {
    debugPrint(
      '🔎 [Repo] getTeacherSchedule: Teacher=$teacherId, Center=$centerId',
    );
    try {
      var query = client
          .from('schedules')
          .select('''
            *,
            classrooms(name),
            groups!inner(id, group_name, courses(id, name))
          ''')
          .eq('center_id', centerId)
          .eq('teacher_id', teacherId);

      if (dayOfWeek != null) {
        final dayInt = DayOfWeek.fromString(dayOfWeek).value;
        query = query.eq('day_of_week', dayInt);
      }

      final response = await query.order('day_of_week').order('start_time');
      debugPrint(
        '✅ [Repo] getTeacherSchedule: Found ${(response as List).length} items',
      );

      return (response as List).map((e) {
        final group = e['groups'] as Map<String, dynamic>? ?? {};
        final course =
            group['courses'] as Map<String, dynamic>? ??
            {'id': '', 'name': 'غير محدد'};
        final roomName = e['classrooms']?['name'] as String?;

        return ScheduleItem(
          id: e['id'],
          groupId:
              e['group_id'] ?? group['id'], // Prefer direct FK or group join
          courseId: course['id'] ?? '',
          courseName: course['name'] ?? 'غير محدد',
          groupName: group['group_name'] ?? 'مجموعة',
          teacherName: '', // Teacher is current user usually
          dayOfWeek: DayOfWeek.fromInt(e['day_of_week']).englishName,
          startTime: e['start_time'] ?? '',
          endTime: e['end_time'] ?? '',
          roomName: roomName,
          centerId: e['center_id'],
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ [Repo] getTeacherSchedule Error: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DASHBOARD & STATS
  // ═══════════════════════════════════════════════════════════════════════

  /// Get teacher dashboard stats for a center
  Future<Map<String, dynamic>> getTeacherDashboardStats({
    required String teacherId,
    required String teacherUserId,
    required String centerId,
  }) async {
    debugPrint(
      '📊 [Repo] getTeacherDashboardStats: START for Teacher: $teacherId',
    );

    // 1. Active Groups
    final groupsResponse = await client
        .from('groups')
        .select('id')
        .eq('teacher_id', teacherId)
        .eq('center_id', centerId)
        .eq('is_active', true);
    final groupsCount = (groupsResponse as List).length;
    debugPrint('   🔹 Active Groups: $groupsCount');

    // 2. Active Students
    int studentsCount = 0;
    if (groupsCount > 0) {
      final groupIds = (groupsResponse).map((g) => g['id'] as String).toList();
      final studentsResponse = await client
          .from('student_group_enrollments')
          .select('id')
          .inFilter('group_id', groupIds)
          .eq('status', 'active');
      studentsCount = (studentsResponse as List).length;
    }
    debugPrint('   🔹 Active Students: $studentsCount');

    // 3. Today's Classes (Based on Schedules)
    final today = DateTime.now();
    final dayOfWeek =
        today.weekday % 7; // 0=Sunday, ... 6=Saturday? Check DB conv.
    // Note: Project uses specific day mapping. Let's assume standard 1=Mon...7=Sun mapping logic from Utils
    // Actually DB usually stores 0-6. Let's rely on filter.
    final todaySchedule = await client
        .from('schedules')
        .select('id')
        .eq('center_id', centerId)
        .eq('day_of_week', dayOfWeek);
    final todayClassesCount = (todaySchedule as List).length;
    debugPrint('   🔹 Today\'s Classes (Day=$dayOfWeek): $todayClassesCount');

    // 4. Pending Assignments
    final pendingAssignments = await client
        .from('assignment_submissions')
        .select('id, assignments!inner(teacher_user_id)')
        .eq('assignments.teacher_user_id', teacherUserId)
        .isFilter('score', null);
    final pendingCount = (pendingAssignments as List).length;
    debugPrint('   🔹 Pending Assignments: $pendingCount');

    // 5. Unread Messages
    int unreadMessagesCount = 0;
    // ... filtering logic ...
    final conversationsResponse = await client
        .from('conversations')
        .select('id')
        .eq('teacher_id', teacherId)
        .eq('center_id', centerId);

    if ((conversationsResponse as List).isNotEmpty) {
      final conversationIds = (conversationsResponse)
          .map((c) => c['id'] as String)
          .toList();

      final unreadResponse = await client
          .from('messages')
          .select('id')
          .inFilter('conversation_id', conversationIds)
          .neq('sender_id', teacherId)
          .eq('is_read', false);

      unreadMessagesCount = (unreadResponse as List).length;
    }
    debugPrint('   🔹 Unread Messages: $unreadMessagesCount');

    return {
      'groups_count': groupsCount,
      'students_count': studentsCount,
      'today_classes_count': todayClassesCount,
      'pending_assignments_count': pendingCount,
      'unread_messages_count': unreadMessagesCount,
    };
  }

  /// Get teacher salary breakdown
  Future<Map<String, dynamic>> getTeacherSalaryBreakdown({
    required String teacherId,
    required String centerId,
    required int month,
    required int year,
  }) async {
    final response = await client.rpc(
      'get_teacher_salary_breakdown',
      params: {
        'p_teacher_id': teacherId,
        'p_center_id': centerId,
        'p_month': month,
        'p_year': year,
      },
    );
    return response as Map<String, dynamic>;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TEACHER REPORTS
  // ═══════════════════════════════════════════════════════════════════════

  /// Get students performance for teacher
  Future<List<Map<String, dynamic>>> getStudentsPerformance({
    required String centerId,
    String? groupId,
    String? teacherId,
  }) async {
    debugPrint('📊 [Reports] getStudentsPerformance - START');
    final userId = currentUserId;
    if (userId == null) return [];

    var effectiveTeacherId = teacherId;
    if (effectiveTeacherId == null) {
      final teacherResult = await client
          .from('teachers')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();
      effectiveTeacherId = teacherResult?['id'] as String?;
    }

    debugPrint(
      '📊 [Reports] userId: $userId, teacherId: $effectiveTeacherId, centerId: $centerId',
    );

    if (effectiveTeacherId == null) {
      debugPrint('📊 [Reports] No teacher record found');
      return [];
    }

    try {
      var query = client
          .from('student_group_enrollments')
          .select('''
            student_id,
            students!inner(
              id,
              user_id,
              users:user_id(full_name, avatar_url)
            ),
            groups!student_group_enrollments_group_id_fkey(
              id,
              teacher_id,
              center_id,
              group_name
            )
          ''')
          .eq('groups.teacher_id', effectiveTeacherId)
          .eq('groups.center_id', centerId)
          .eq('status', 'active');

      if (groupId != null) {
        query = query.eq('group_id', groupId);
      }

      debugPrint('📊 [Reports] Fetching enrollments...');
      final enrollments = await query;
      debugPrint(
        '📊 [Reports] Enrollments found: ${(enrollments as List).length}',
      );

      List<Map<String, dynamic>> studentsPerformance = [];
      Set<String> processedStudents = {};

      for (var enrollment in (enrollments as List)) {
        final student = enrollment['students'] as Map<String, dynamic>?;
        if (student == null) continue;

        final studentId = student['id'] as String?;
        if (studentId == null) continue;
        if (processedStudents.contains(studentId)) continue;
        processedStudents.add(studentId);

        final user = student['users'] as Map<String, dynamic>?;
        final studentUserId = student['user_id'] as String?;

        final attendanceResponse = await client
            .from('attendance')
            .select('status')
            .eq('student_id', studentId);

        final attendanceList = attendanceResponse as List;
        int presentCount = attendanceList
            .where((a) => a['status'] == 'present')
            .length;
        int totalAttendance = attendanceList.length;
        double attendanceRate = totalAttendance > 0
            ? (presentCount / totalAttendance * 100)
            : 0;

        double assignmentAvg = 0;
        if (studentUserId != null) {
          final submissionsResponse = await client
              .from('assignment_submissions')
              .select('score, assignments!inner(teacher_user_id, max_score)')
              .eq('student_user_id', studentUserId)
              .eq('assignments.teacher_user_id', userId);

          final submissions = submissionsResponse as List;
          if (submissions.isNotEmpty) {
            double totalScore = 0;
            int scoredCount = 0;
            for (var sub in submissions) {
              if (sub['score'] != null) {
                final maxScore =
                    (sub['assignments']['max_score'] ?? 100) as num;
                totalScore += ((sub['score'] as num) / maxScore * 100);
                scoredCount++;
              }
            }
            if (scoredCount > 0) {
              assignmentAvg = totalScore / scoredCount;
            }
          }
        }

        double overall = (attendanceRate * 0.3 + assignmentAvg * 0.7);

        studentsPerformance.add({
          'id': studentId,
          'user_id': studentUserId,
          'name': user?['full_name'] ?? 'طالب',
          'avatar': user?['avatar_url'],
          'attendance': attendanceRate.round(),
          'assignments': assignmentAvg.round(),
          'overall': overall.round(),
        });
      }

      studentsPerformance.sort(
        (a, b) => (b['overall'] as int).compareTo(a['overall'] as int),
      );

      for (int i = 0; i < studentsPerformance.length; i++) {
        studentsPerformance[i]['rank'] = i + 1;
        final overall = studentsPerformance[i]['overall'] as int;
        if (overall >= 80) {
          studentsPerformance[i]['trend'] = 'up';
        } else if (overall >= 60) {
          studentsPerformance[i]['trend'] = 'stable';
        } else {
          studentsPerformance[i]['trend'] = 'down';
        }
      }

      debugPrint(
        '📊 [Reports] getStudentsPerformance - SUCCESS: ${studentsPerformance.length} students',
      );
      return studentsPerformance;
    } catch (e, stack) {
      debugPrint('📊 [Reports] getStudentsPerformance ERROR: $e');
      debugPrint('📊 [Reports] Stack: $stack');
      rethrow;
    }
  }

  /// Get overview stats for teacher reports
  Future<Map<String, dynamic>> getTeacherOverviewStats(
    String centerId, {
    String? teacherId,
  }) async {
    debugPrint('📊 [Reports] getTeacherOverviewStats - START');
    debugPrint('📊 [Reports] centerId: $centerId, teacherId: $teacherId');

    final userId = currentUserId;
    if (userId == null) return {};

    var effectiveTeacherId = teacherId;
    if (effectiveTeacherId == null) {
      final teacherResult = await client
          .from('teachers')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();
      effectiveTeacherId = teacherResult?['id'] as String?;
    }

    debugPrint(
      '📊 [Reports] userId: $userId, effectiveTeacherId: $effectiveTeacherId',
    );

    if (effectiveTeacherId == null) {
      debugPrint('📊 [Reports] No teacher record found for this user');
      return {
        'total_students': 0,
        'attendance_rate': 0,
        'total_assignments': 0,
      };
    }

    try {
      debugPrint('📊 [Reports] Fetching students...');
      final studentsResponse = await client
          .from('student_group_enrollments')
          .select(
            'student_id, groups!student_group_enrollments_group_id_fkey(teacher_id, center_id)',
          )
          .eq('groups.teacher_id', effectiveTeacherId)
          .eq('groups.center_id', centerId)
          .eq('status', 'active');

      debugPrint(
        '📊 [Reports] Students response: ${(studentsResponse as List).length} records',
      );

      final uniqueStudents = <String>{};
      for (var e in (studentsResponse as List)) {
        uniqueStudents.add(e['student_id'] as String);
      }
      debugPrint('📊 [Reports] Unique students: ${uniqueStudents.length}');

      debugPrint('📊 [Reports] Fetching attendance...');

      final groupsResponse = await client
          .from('groups')
          .select('id')
          .eq('teacher_id', effectiveTeacherId)
          .eq('center_id', centerId);

      final groupIds = (groupsResponse as List)
          .map((g) => g['id'] as String)
          .toList();
      debugPrint('📊 [Reports] Teacher groups: ${groupIds.length}');

      List attendanceList = [];
      if (groupIds.isNotEmpty) {
        final attendanceResponse = await client
            .from('attendance')
            .select('status')
            .inFilter('group_id', groupIds);
        attendanceList = attendanceResponse as List;
      }

      debugPrint(
        '📊 [Reports] Attendance response: ${attendanceList.length} records',
      );

      int presentCount = attendanceList
          .where((a) => a['status'] == 'present')
          .length;
      double attendanceRate = attendanceList.isNotEmpty
          ? (presentCount / attendanceList.length * 100)
          : 0;
      debugPrint('📊 [Reports] Attendance rate: $attendanceRate%');

      debugPrint('📊 [Reports] Fetching assignments...');
      final assignmentsResponse = await client
          .from('assignments')
          .select('id')
          .eq('center_id', centerId)
          .eq('teacher_user_id', userId)
          .isFilter('deleted_at', null);

      int totalAssignments = (assignmentsResponse as List).length;
      debugPrint('📊 [Reports] Total assignments: $totalAssignments');

      debugPrint('📊 [Reports] getTeacherOverviewStats - SUCCESS');
      return {
        'total_students': uniqueStudents.length,
        'attendance_rate': attendanceRate.round(),
        'total_assignments': totalAssignments,
      };
    } catch (e, stack) {
      debugPrint('📊 [Reports] ERROR: $e');
      debugPrint('📊 [Reports] Stack: $stack');
      rethrow;
    }
  }

  /// Get teacher attendance trends (last 30 days)
  Future<List<Map<String, dynamic>>> getTeacherAttendanceTrends(
    String centerId, {
    String? teacherId,
  }) async {
    debugPrint('📊 [Reports] getTeacherAttendanceTrends - START');
    final userId = currentUserId;
    if (userId == null) return [];

    var effectiveTeacherId = teacherId;
    if (effectiveTeacherId == null) {
      final teacherResult = await client
          .from('teachers')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();
      effectiveTeacherId = teacherResult?['id'] as String?;
    }

    debugPrint(
      '📊 [Reports] userId: $userId, teacherId: $effectiveTeacherId, centerId: $centerId',
    );

    if (effectiveTeacherId == null) {
      debugPrint('📊 [Reports] No teacher record found');
      return [];
    }

    try {
      final startDate = DateTime.now().subtract(const Duration(days: 30));

      debugPrint('📊 [Reports] Fetching teacher groups...');
      final groupsResponse = await client
          .from('groups')
          .select('id')
          .eq('teacher_id', effectiveTeacherId)
          .eq('center_id', centerId);

      final groupIds = (groupsResponse as List)
          .map((g) => g['id'] as String)
          .toList();
      debugPrint('📊 [Reports] Teacher groups: ${groupIds.length}');
      if (groupIds.isEmpty) return [];

      final response = await client
          .from('attendance')
          .select('attendance_date, status')
          .inFilter('group_id', groupIds)
          .gte('attendance_date', startDate.toIso8601String())
          .order('attendance_date');

      final Map<String, Map<String, int>> stats = {};

      for (var record in (response as List)) {
        final dateRaw = record['attendance_date'];
        if (dateRaw == null) continue;
        final date = (dateRaw as String).split('T')[0];
        final status = record['status'] as String? ?? 'absent';

        if (!stats.containsKey(date)) {
          stats[date] = {'present': 0, 'absent': 0, 'late': 0, 'total': 0};
        }

        stats[date]!['total'] = (stats[date]!['total'] ?? 0) + 1;

        if (status == 'present') {
          stats[date]!['present'] = (stats[date]!['present'] ?? 0) + 1;
        } else if (status == 'absent') {
          stats[date]!['absent'] = (stats[date]!['absent'] ?? 0) + 1;
        } else if (status == 'late') {
          stats[date]!['late'] = (stats[date]!['late'] ?? 0) + 1;
        }
      }

      debugPrint(
        '📊 [Reports] getTeacherAttendanceTrends - SUCCESS: ${stats.length} days',
      );
      return stats.entries.map((e) => {'date': e.key, ...e.value}).toList();
    } catch (e, stack) {
      debugPrint('📊 [Reports] getTeacherAttendanceTrends ERROR: $e');
      debugPrint('📊 [Reports] Stack: $stack');
      rethrow;
    }
  }

  /// Get teacher assignment creation trends
  Future<List<Map<String, dynamic>>> getTeacherAssignmentTrends(
    String centerId, {
    String? teacherId,
  }) async {
    debugPrint('📊 [Reports] getTeacherAssignmentTrends - START');
    final userId = currentUserId;
    debugPrint('📊 [Reports] userId: $userId, centerId: $centerId');
    if (userId == null) return [];

    try {
      final startDate = DateTime.now().subtract(const Duration(days: 30));

      final response = await client
          .from('assignments')
          .select('created_at, type')
          .eq('center_id', centerId)
          .eq('teacher_user_id', userId)
          .gte('created_at', startDate.toIso8601String())
          .order('created_at');

      debugPrint(
        '📊 [Reports] Assignments found: ${(response as List).length}',
      );

      final Map<String, int> dailyCounts = {};

      for (var record in (response as List)) {
        final date = DateTime.parse(
          record['created_at'],
        ).toIso8601String().split('T')[0];
        dailyCounts[date] = (dailyCounts[date] ?? 0) + 1;
      }

      debugPrint(
        '📊 [Reports] getTeacherAssignmentTrends - SUCCESS: ${dailyCounts.length} days',
      );
      return dailyCounts.entries
          .map((e) => {'date': e.key, 'count': e.value})
          .toList();
    } catch (e, stack) {
      debugPrint('📊 [Reports] getTeacherAssignmentTrends ERROR: $e');
      debugPrint('📊 [Reports] Stack: $stack');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BURNOUT DETECTOR (AI INSIGHTS)
  // ═══════════════════════════════════════════════════════════════════════

  /// Determine if a student is at risk of burnout based on recent drops in attendance and grades
  Future<bool> getStudentBurnoutRisk({
    required String studentId,
    required String centerId,
  }) async {
    try {
      final response = await client.rpc(
        'get_student_burnout_risk',
        params: {'p_student_id': studentId, 'p_center_id': centerId},
      );

      // The RPC returns a boolean directly
      return response == true;
    } catch (e) {
      debugPrint('❌ [Repo] getStudentBurnoutRisk Error: $e');
      return false;
    }
  }
}
