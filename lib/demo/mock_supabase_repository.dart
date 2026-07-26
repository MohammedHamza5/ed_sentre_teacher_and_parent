import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../shared/data/supabase_repository.dart';
import '../shared/models/models.dart';
import 'mock_database.dart';

/// MockSupabaseRepository - Smart Demo Mode Repository
/// محاكاة كاملة وذكية لكافة واجهات المنظومة (المدرس، ولي الأمر، المجموعات، المالي، التقارير، المذكرات، المحادثات)
class MockSupabaseRepository extends SupabaseRepository {
  MockSupabaseRepository() : super(Supabase.instance.client);

  final _db = MockDatabase.instance;

  @override
  SupabaseClient get client => Supabase.instance.client;

  @override
  String? get currentUserId => _db.teachers.first.userId;

  // ── Helper Resolvers for Intelligent ID Matching ──────────────────────────
  String _resolveStudentTableId(String? input) {
    if (input == null || input == 'demo_student_id' || input == 'user_student_0' || input == 'user_stu_0' || input == 'student_0' || input == 'stu_0') {
      return 'stu_0';
    }
    if (input == 'user_student_1' || input == 'user_stu_1' || input == 'student_1' || input == 'stu_1') {
      return 'stu_1';
    }
    if (input.startsWith('user_student_')) return input.replaceAll('user_student_', 'stu_');
    if (input.startsWith('user_stu_')) return input.replaceAll('user_stu_', 'stu_');
    if (input.startsWith('user_')) return 'stu_${input.replaceAll('user_', '')}';
    return input;
  }

  String _resolveStudentUserId(String? input) {
    if (input == null || input == 'demo_student_id' || input == 'stu_0' || input == 'student_0' || input == 'user_stu_0' || input == 'user_student_0') {
      return 'user_student_0';
    }
    if (input == 'stu_1' || input == 'student_1' || input == 'user_stu_1' || input == 'user_student_1') {
      return 'user_student_1';
    }
    if (!input.startsWith('user_')) return 'user_student_${input.replaceAll('stu_', '')}';
    return input;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SHARED / GENERAL
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<CenterModel?> getCenterById(String centerId) async {
    await Future.delayed(const Duration(milliseconds: 80));
    return CenterModel(
      id: centerId,
      name: 'سنتر التميز (تجريبي)',
      adminUserId: 'demo_admin_user_id',
      address: 'القاهرة، مدينة نصر',
      phone: '01012345678',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
      updatedAt: DateTime.now(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TEACHER PROFILE & CENTERS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<TeacherModel?> getTeacherByUserId(String userId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _db.teachers.firstWhere(
      (x) => x.userId == userId || userId.contains(x.id),
      orElse: () => _db.teachers.first, // الأستاذ أحمد السيد
    );
  }

  @override
  Future<List<CenterModel>> getTeacherCenters(String teacherId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return [await getCenterById('center_demo') as CenterModel];
  }

  @override
  Future<List<CenterModel>> getTeacherCentersEnrolled(
    String teacherUserId, {
    String? teacherTableId,
  }) async {
    return getTeacherCenters(teacherTableId ?? 'teacher_0');
  }

  @override
  Future<TeacherEnrollmentModel?> getTeacherEnrollment({
    required String centerId,
    required String teacherUserId,
    String? teacherTableId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return TeacherEnrollmentModel(
      id: 'enroll_demo_1',
      teacherUserId: teacherUserId,
      teacherId: teacherTableId ?? 'teacher_0',
      centerId: centerId,
      status: 'active',
      salaryType: 'percentage',
      salaryAmount: 60.0,
      createdAt: DateTime.now().subtract(const Duration(days: 100)),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TEACHER DASHBOARD, GROUPS & STUDENTS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Map<String, dynamic>> getTeacherDashboardStats({
    required String teacherId,
    required String teacherUserId,
    required String centerId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return {
      'students_count': 198, // مجموع طلاب المجموعات الثلاث
      'attendance_rate': 92,
      'today_classes_count': 2,
    };
  }

  @override
  Future<List<GroupModel>> getTeacherGroups(String teacherId, String centerId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _db.groups;
  }

  @override
  Future<List<Map<String, dynamic>>> getTeacherStudents({
    required String teacherId,
    required String centerId,
    int? limit,
    int? offset,
    List<GroupModel>? preloadedGroups,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _db.students.map((s) {
      final group = s.id == 'stu_0' ? _db.groups[0] : (s.id == 'stu_1' ? _db.groups[1] : _db.groups[s.id.hashCode % _db.groups.length]);
      return {
        'id': 'link_${s.id}',
        'student_id': s.id,
        'group_id': group.id,
        'group_name': group.groupName,
        'students': s.toJson(),
      };
    }).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TEACHER ATTENDANCE & SCHEDULE
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Map<String, dynamic>> startAttendanceSession({
    required String groupId,
    required String centerId,
    bool force = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return {'session_id': 'session_demo_$groupId', 'status': 'started'};
  }

  @override
  Future<void> saveAttendanceBulk({
    required String centerId,
    required String groupId,
    required String sessionId,
    required List<Map<String, dynamic>> attendanceList,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    for (final item in attendanceList) {
      _db.addAttendanceRecord(AttendanceModel(
        id: 'att_bulk_${DateTime.now().millisecondsSinceEpoch}_${item['student_id']}',
        centerId: centerId,
        groupId: groupId,
        sessionId: sessionId,
        studentId: item['student_id'],
        status: AttendanceStatus.fromString(item['status'] as String? ?? 'present'),
        attendanceDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getGroupAttendanceForToday(
    String groupId, {
    DateTime? date,
  }) async {
    await Future.delayed(const Duration(milliseconds: 120));
    return _db.attendance
        .where((a) => a.groupId == groupId)
        .map((a) => {
              'student_id': a.studentId,
              'status': a.status.name,
              'notes': a.notes,
            })
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getGroupAttendanceHistory({
    int days = 30,
    required String groupId,
    int offsetDays = 0,
  }) async {
    await Future.delayed(const Duration(milliseconds: 120));
    return _db.attendance
        .where((a) => a.groupId == groupId)
        .map((a) => {
              'student_id': a.studentId,
              'status': a.status.name,
              'notes': a.notes,
              'attendance_date': a.attendanceDate.toIso8601String(),
            })
        .toList();
  }

  @override
  Future<List<ScheduleItem>> getTeacherSchedule({
    required String centerId,
    String? dayOfWeek,
    required String teacherId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _db.groups.map((g) => ScheduleItem(
      id: 'session_${g.id}',
      centerId: g.centerId,
      groupId: g.id,
      groupName: g.groupName,
      courseId: g.courseId,
      courseName: g.courseName ?? 'مادة',
      teacherName: g.teacherName ?? 'أ. أحمد السيد',
      dayOfWeek: (g.dayOfWeek ?? 1).toString(),
      startTime: g.startTime ?? '16:00:00',
      endTime: g.endTime ?? '18:00:00',
      roomName: 'قاعة ابن سينا',
    )).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TEACHER SALARY & PAYMENTS (FINANCIAL BREAKDOWN)
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Map<String, dynamic>> getTeacherSalaryBreakdown({
    required String teacherId,
    required String centerId,
    required int month,
    required int year,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return {
      'salary_id': 'salary_${year}_$month',
      'teacher_name': 'أ. أحمد السيد (خبير الفيزياء والرياضيات)',
      'salary_type': 'percentage',
      'status': 'approved',
      'base_salary': 2500.0,
      'salary_percentage': 60.0,
      'gross_preview': 39411.0,
      'expected_gross_preview': 47790.0,
      'percentage_items': [
        {
          'group': 'مجموعة التميز - فيزياء (3 ثانوي)',
          'students': 65,
          'collected': 22750.0,
          'percentage': 60.0,
          'total': 13650.0,
          'center_share': 9100.0,
          'expected_total': 16800.0,
        },
        {
          'group': 'مجموعة التأسيس والشرح - رياضيات (1 ثانوي)',
          'students': 75,
          'collected': 22500.0,
          'percentage': 65.0,
          'total': 14625.0,
          'center_share': 7875.0,
          'expected_total': 17550.0,
        },
        {
          'group': 'مجموعة مراجعة القوانين والامتحانات (2 ثانوي)',
          'students': 58,
          'collected': 18560.0,
          'percentage': 60.0,
          'total': 11136.0,
          'center_share': 7424.0,
          'expected_total': 13440.0,
        },
      ],
      'sessions': [],
      'bonuses': [
        {'description': 'مكافأة التميز الأكاديمي وتقييم الطلاب الممتاز 4.9★', 'amount': 1500.0},
        {'description': 'حافز الالتزام بجودة المحتوى والمسابقات', 'amount': 500.0}
      ],
      'deductions': [
        {'description': 'مساهمة ضريبية وتأمينات المنظومة', 'amount': 400.0}
      ],
    };
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TEACHER REPORTS & ANALYTICS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<List<Map<String, dynamic>>> getStudentsPerformance({
    required String centerId,
    String? groupId,
    String? teacherId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _db.students.take(15).map((s) {
      final isTop = s.id == 'stu_0' || s.id == 'stu_1';
      return {
        'id': s.id,
        'name': s.fullName,
        'attendance': isTop ? 98 : (80 + s.id.hashCode % 18),
        'assignments': isTop ? 96 : (75 + s.id.hashCode % 20),
        'overall': isTop ? 97 : (78 + s.id.hashCode % 19),
      };
    }).toList();
  }

  @override
  Future<Map<String, dynamic>> getTeacherOverviewStats(
    String centerId, {
    String? teacherId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return {
      'total_students': 198,
      'attendance_rate': 92,
      'total_assignments': 12,
    };
  }

  @override
  Future<List<Map<String, dynamic>>> getTeacherAttendanceTrends(
    String centerId, {
    String? teacherId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final now = DateTime.now();
    return List.generate(7, (idx) {
      final date = now.subtract(Duration(days: (6 - idx) * 4));
      return {
        'present': 58 + (idx % 5),
        'total': 65,
        'date': date.toIso8601String().split('T')[0],
      };
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getTeacherAssignmentTrends(
    String centerId, {
    String? teacherId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final now = DateTime.now();
    return List.generate(5, (idx) {
      return {
        'count': 55 + (idx * 2),
        'date': now.subtract(Duration(days: (4 - idx) * 7)).toIso8601String().split('T')[0],
        'title': 'التدريب الأسبوعي ${idx + 1}',
      };
    });
  }

  @override
  Future<bool> getStudentBurnoutRisk({
    required String centerId,
    required String studentId,
  }) async {
    return false;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // STUDY MATERIALS & UPLOADS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<List<StudyMaterialModel>> getStudyMaterials(String centerId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _db.studyMaterials;
  }

  @override
  Future<List<Map<String, dynamic>>> getTeacherMaterials({
    required String centerId,
    String? courseId,
    String? fileType,
    int? limit,
    int? offset,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _db.studyMaterials.map((m) => {
      'id': m.id,
      'center_id': m.centerId,
      'course_id': m.courseId,
      'teacher_id': m.teacherId,
      'title': m.title,
      'description': m.description,
      'file_url': m.fileUrl,
      'file_type': m.fileType,
      'file_size': m.fileSize,
      'is_published': m.isPublished,
      'download_count': m.downloadCount,
      'created_at': m.createdAt.toIso8601String(),
      'updated_at': m.updatedAt.toIso8601String(),
      'course_name': m.courseName,
    }).toList();
  }

  @override
  Future<Map<String, dynamic>> getTeacherMaterialsStats(String centerId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    int totalDown = _db.studyMaterials.fold(0, (sum, m) => sum + m.downloadCount);
    return {
      'total_materials': _db.studyMaterials.length,
      'total_downloads': totalDown,
      'by_type': {'pdf': _db.studyMaterials.length},
    };
  }

  @override
  Future<String> uploadStudyMaterial(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final id = 'mat_new_${DateTime.now().millisecondsSinceEpoch}';
    final mat = StudyMaterialModel(
      id: id,
      centerId: data['center_id'] ?? 'center_demo',
      courseId: data['course_id'] ?? _db.courses.first.id,
      teacherId: data['teacher_id'] ?? 'teacher_0',
      title: data['title'] ?? 'مذكرة شرح جديدة',
      description: data['description'] ?? 'ملف تعليمي مساعد للطلاب',
      fileUrl: data['file_url'] ?? 'https://example.com/demo_material.pdf',
      fileType: data['file_type'] ?? 'pdf',
      fileSize: (data['file_size'] as num?)?.toInt() ?? 5000000,
      isPublished: data['is_published'] ?? true,
      downloadCount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      courseName: 'الفيزياء',
      teacherName: 'أ. أحمد السيد',
    );
    _db.addStudyMaterialRecord(mat);
    return id;
  }

  @override
  Future<String?> uploadStudyMaterialFile(File file, String path) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return 'https://example.com/uploaded_demo_material.pdf';
  }

  @override
  Future<void> addStudyMaterial(Map<String, dynamic> data) async {
    await uploadStudyMaterial(data);
  }

  @override
  Future<void> updateStudyMaterial(String id, Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<void> deleteStudyMaterial(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _db.removeStudyMaterialRecord(id);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // MESSAGING & CHAT
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<List<ConversationModel>> getConversations(String centerId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _db.conversations;
  }

  @override
  Future<List<ConversationModel>> getTeacherConversations({
    required String centerId,
    int? limit,
    int? offset,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _db.conversations;
  }

  @override
  Future<List<ConversationModel>> getParentConversations({
    required String centerId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _db.conversations;
  }

  @override
  Future<List<MessageModel>> getMessages(
    String conversationId, {
    bool ascending = false,
    int? limit,
    int? offset,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _db.chatMessages.where((m) => m.conversationId == conversationId || conversationId.contains('demo')).toList();
  }

  @override
  Future<void> sendMessage({
    required String conversationId,
    required String content,
    MessageType type = MessageType.text,
    String? fileUrl,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final msg = MessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: conversationId,
      senderId: currentUserId ?? 'demo_teacher_id',
      content: content,
      createdAt: DateTime.now(),
      senderName: 'أ. أحمد السيد',
      isRead: false,
    );
    _db.addMessageRecord(msg);
  }

  @override
  Future<void> markMessagesAsRead(String conversationId) async {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  @override
  Future<List<Map<String, dynamic>>> getParentChildrenTeachers({
    required String centerId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return [
      {
        'teacher_id': 'teacher_0',
        'teacher_name': 'أ. أحمد السيد (خبير الفيزياء والرياضيات)',
        'course_name': 'الفيزياء والرياضيات',
        'student_id': 'stu_0',
        'student_name': 'محمد محمود السيد',
      }
    ];
  }

  @override
  Future<String> getOrCreateConversation({
    required String centerId,
    required String studentId,
    required String teacherId,
  }) async {
    return _db.conversations.first.id;
  }

  @override
  Future<String> getOrCreateParentConversation({
    required String centerId,
    required String parentUserId,
    required String studentId,
    required String teacherId,
  }) async {
    return _db.conversations.first.id;
  }

  @override
  Future<String> createParentConversation({
    required String centerId,
    required String studentId,
    required String teacherId,
  }) async {
    return _db.conversations.first.id;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<List<NotificationModel>> getNotifications({
    int limit = 20,
    int offset = 0,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _db.notifications;
  }

  @override
  Future<void> markNotificationRead(String notificationId) async {
    final idx = _db.notifications.indexWhere((n) => n.id == notificationId);
    if (idx != -1) {
      final old = _db.notifications[idx];
      _db.notifications[idx] = NotificationModel(
        id: old.id,
        userId: old.userId,
        title: old.title,
        body: old.body,
        type: old.type,
        createdAt: old.createdAt,
        isRead: true,
      );
    }
  }

  @override
  Future<void> markAllNotificationsRead() async {
    for (int i = 0; i < _db.notifications.length; i++) {
      final old = _db.notifications[i];
      _db.notifications[i] = NotificationModel(
        id: old.id,
        userId: old.userId,
        title: old.title,
        body: old.body,
        type: old.type,
        createdAt: old.createdAt,
        isRead: true,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CURRICULUM (SUBJECTS, CHAPTERS, LESSONS)
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<List<Map<String, dynamic>>> getCurriculumSubjects(String centerId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _db.curriculumSubjects;
  }

  @override
  Future<List<Map<String, dynamic>>> getChaptersWithLessons(String subjectId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final chapters = _db.curriculumChapters.where((c) => c['subject_id'] == subjectId || subjectId.contains('1') || subjectId.contains('2')).toList();
    if (chapters.isEmpty) return _db.curriculumChapters;
    
    return chapters.map((ch) {
      final lessons = _db.curriculumLessons.where((l) => l['chapter_id'] == ch['id']).toList();
      return {
        ...ch,
        'lessons': lessons,
      };
    }).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PARENT & CHILDREN INTELLIGENT MATCHING
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Map<String, dynamic>?> getParentByUserId(String userId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return {
      'id': 'demo_parent_id',
      'user_id': userId,
      'name': 'أبو محمد (تجريبي)',
      'phone': '01112345678',
      'email': 'parent@edsentre.demo',
    };
  }

  @override
  Future<List<StudentModel>> getParentChildren(String parentUserId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return [_db.students[0], _db.students[1]];
  }

  @override
  Future<List<ChildCenterInfo>> getChildCenters(String studentUserId) async {
    await Future.delayed(const Duration(milliseconds: 120));
    return [
      const ChildCenterInfo(
        centerId: 'center_demo',
        centerName: 'سنتر التميز (تجريبي)',
        status: EnrollmentStatus.active,
        attendanceRate: 98.0,
        totalDue: 435.0,
        totalPaid: 435.0,
      )
    ];
  }

  @override
  Future<Map<String, dynamic>> getStudentDashboardSummary({
    required String studentId,
    String? centerId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final cleanId = _resolveStudentTableId(studentId);
    final isMaryam = cleanId == 'stu_1';
    return {
      'attendance_rate': isMaryam ? 100.0 : 96.5,
      'average_grade': isMaryam ? 96.0 : 95.3,
      'next_class_time': isMaryam ? '14:00 (الأربعاء)' : '16:00 (الإثنين)',
      'next_class_name': isMaryam ? 'الرياضيات - مجموعة التأسيس' : 'الفيزياء - مجموعة التميز',
      'total_due': 0.0,
    };
  }

  @override
  Future<Map<String, dynamic>> getStudentHomeStats() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return {
      'attendance_rate': 98.0,
      'average_grade': 96.5,
      'completed_assignments': 12,
      'total_due': 0.0,
    };
  }

  @override
  Future<List<AttendanceModel>> getStudentAttendance({
    String? centerId,
    int limit = 100,
    DateTime? startDate,
    DateTime? endDate,
    String? studentUserId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final tableId = _resolveStudentTableId(studentUserId);
    final userId = _resolveStudentUserId(studentUserId);
    return _db.attendance.where((a) => a.studentId == tableId || a.studentUserId == userId).toList();
  }

  @override
  Future<List<CourseAttendanceStats>> getAttendanceStatsByCourse({
    String? centerId,
    required String studentId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final tableId = _resolveStudentTableId(studentId);
    final isMaryam = tableId == 'stu_1';
    return [
      CourseAttendanceStats(
        courseId: isMaryam ? _db.courses[1].id : _db.courses[0].id,
        courseName: isMaryam ? 'الرياضيات (أولى ثانوي)' : 'الفيزياء (ثانوي عام)',
        teacherName: 'أ. أحمد السيد',
        totalSessions: isMaryam ? 6 : 8,
        presentCount: isMaryam ? 6 : 8,
        absentCount: 0,
        lateCount: 0,
        attendanceRate: isMaryam ? 100.0 : 100.0,
      )
    ];
  }

  @override
  Future<List<StudentGradeView>> getStudentGrades({
    String? centerId,
    String? courseId,
    String? examType,
    int limit = 100,
    int offset = 0,
    String? studentUserId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final uId = _resolveStudentUserId(studentUserId);
    final studentSubs = _db.submissions.where((s) => s.studentUserId == uId && s.status == 'graded');
    
    if (studentSubs.isEmpty) {
      final assign = _db.assignments.first;
      return [
        StudentGradeView(
          gradeId: 'demo_grd_1',
          courseId: assign.courseId ?? '',
          courseName: assign.courseName ?? 'الفيزياء',
          examType: 'quiz',
          score: 96.0,
          maxScore: 100.0,
          percentage: 96.0,
          comments: 'تفوق ملحوظ وحل نموذجي رائع.',
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        )
      ];
    }

    return studentSubs.map((s) {
      final assign = _db.assignments.firstWhere(
        (a) => a.id == s.assignmentId,
        orElse: () => _db.assignments.first,
      );
      final scoreVal = s.score ?? 95.0;
      final maxVal = assign.maxScore > 0 ? assign.maxScore : 100.0;
      return StudentGradeView(
        gradeId: s.id,
        courseId: assign.courseId ?? '',
        courseName: assign.courseName ?? 'مادة',
        examType: 'quiz',
        score: scoreVal,
        maxScore: maxVal,
        percentage: (scoreVal / maxVal) * 100,
        comments: s.feedback ?? 'أداء رائع في حل الواجب',
        createdAt: s.gradedAt ?? DateTime.now(),
      );
    }).toList();
  }

  @override
  Future<List<PaymentModel>> getStudentPayments({
    String? centerId,
    int? limit,
    String? status,
    String? studentUserId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final tableId = _resolveStudentTableId(studentUserId);
    return _db.payments.where((p) => p.studentId == tableId).toList();
  }

  @override
  Future<Map<String, dynamic>> getStudentInvoiceSummary({
    required String centerId,
    required int month,
    required String studentId,
    required int year,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return {
      'total_paid': 435.0,
      'total_due': 435.0,
      'currency': 'جنيه مصري',
    };
  }

  @override
  Future<List<Map<String, dynamic>>> getStudentSchedule({
    required String centerId,
    required String studentUserId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final tableId = _resolveStudentTableId(studentUserId);
    final group = tableId == 'stu_1' ? _db.groups[1] : _db.groups[0];
    
    return [
      {
        'schedule_id': 'session_${group.id}',
        'center_id': centerId,
        'group_id': group.id,
        'group_name': group.groupName,
        'course_id': group.courseId,
        'course_name': group.courseName ?? 'الفيزياء',
        'teacher_name': group.teacherName ?? 'أ. أحمد السيد',
        'day_of_week': group.dayOfWeek ?? 2,
        'start_time': group.startTime ?? '16:00:00',
        'end_time': group.endTime ?? '18:30:00',
        'room_name': 'قاعة ابن سينا',
      }
    ];
  }

  @override
  Future<List<ScheduleItem>> getSchedule({
    String? centerId,
    String? dayOfWeek,
    String? userId,
  }) async {
    final raw = await getStudentSchedule(centerId: centerId ?? 'center_demo', studentUserId: userId ?? 'user_student_0');
    return raw.map((g) => ScheduleItem(
      id: g['schedule_id'],
      centerId: g['center_id'],
      groupId: g['group_id'],
      groupName: g['group_name'],
      courseId: g['course_id'],
      courseName: g['course_name'],
      teacherName: g['teacher_name'],
      dayOfWeek: (g['day_of_week'] ?? 1).toString(),
      startTime: g['start_time'],
      endTime: g['end_time'],
      roomName: g['room_name'],
    )).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ASSIGNMENTS & HOMEWORK
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<List<AssignmentWithSubmission>> getStudentAssignments({
    String? centerId,
    String? subjectId,
    String? status,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _db.assignments.take(5).map((a) {
      final sub = _db.submissions.firstWhere(
        (s) => s.assignmentId == a.id,
        orElse: () => SubmissionModel(id: '', assignmentId: '', studentUserId: '', submittedAt: DateTime.now(), status: 'pending'),
      );
      final assignStatus = sub.id.isEmpty ? AssignmentStatus.pending : (sub.status == 'graded' ? AssignmentStatus.graded : AssignmentStatus.submitted);

      return AssignmentWithSubmission(
        assignmentId: a.id,
        title: a.title,
        description: a.description,
        courseId: a.courseId ?? '',
        courseName: a.courseName ?? 'مادة',
        dueDate: a.dueDate,
        maxScore: a.maxScore,
        submissionId: sub.id.isEmpty ? null : sub.id,
        submittedAt: sub.submittedAt,
        score: sub.score,
        feedback: sub.feedback,
        status: assignStatus,
        questions: a.questions,
      );
    }).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getTeacherAssignments({
    bool archivedOnly = false,
    required String centerId,
    String? courseId,
    String? groupId,
    int? limit,
    int? offset,
    String? searchQuery,
    String? statusFilter,
    String? typeFilter,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _db.assignments.map((a) => {
      'id': a.id,
      'title': a.title,
      'description': a.description,
      'due_date': a.dueDate?.toIso8601String(),
      'max_score': a.maxScore,
      'course_id': a.courseId,
      'course_name': a.courseName,
      'created_at': a.createdAt.toIso8601String(),
      'submissions_count': 65,
      'graded_count': 62,
    }).toList();
  }

  @override
  Future<List<SubmissionModel>> getAssignmentSubmissions(String assignmentId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final subs = _db.submissions.where((s) => s.assignmentId == assignmentId).toList();
    if (subs.isEmpty) return _db.submissions.take(5).toList();
    return subs;
  }

  @override
  Future<Map<String, dynamic>> getTeacherAssignmentStats(String centerId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return {
      'total_assignments': _db.assignments.length,
      'total_submissions': 142,
      'pending_grading': 3,
    };
  }

  @override
  Future<String> createAssignment(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final id = 'assign_new_${DateTime.now().millisecondsSinceEpoch}';
    final assignment = AssignmentModel(
      id: id,
      centerId: data['center_id'] ?? 'center_demo',
      courseId: data['course_id'] ?? _db.courses.first.id,
      title: data['title'] ?? 'واجب الأسبوع الجديد',
      description: data['description'],
      dueDate: data['due_date'] != null ? DateTime.parse(data['due_date']) : DateTime.now().add(const Duration(days: 3)),
      maxScore: (data['max_score'] as num?)?.toDouble() ?? 100.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      courseName: 'الفيزياء',
      teacherName: 'أ. أحمد السيد',
      questions: data['questions'] ?? [],
    );
    _db.addAssignmentRecord(assignment);
    return id;
  }

  @override
  Future<void> gradeSubmission({
    required String submissionId,
    required double score,
    String? feedback,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _db.gradeSubmissionRecord(submissionId, score, feedback ?? 'أحسنت في الحل', 'teacher_0');
  }
}
