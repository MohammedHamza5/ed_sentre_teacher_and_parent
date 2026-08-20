import 'package:supabase_flutter/supabase_flutter.dart';
import '../shared/data/supabase_repository.dart';
import '../shared/models/models.dart';
import 'mock_database.dart';

class MockSupabaseRepository extends SupabaseRepository {
  MockSupabaseRepository() : super(Supabase.instance.client);

  final _db = MockDatabase.instance;

  @override
  SupabaseClient get client => Supabase.instance.client;

  @override
  String? get currentUserId => _db.teachers.first.userId; // Mock active user ID

  // ═══════════════════════════════════════════════════════════════════════
  // SHARED / GENERAL
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<CenterModel?> getCenterById(String centerId) async {
    await Future.delayed(const Duration(milliseconds: 100));
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
  Future<void> ensureIndependentTeacherProfile(String userId) async {
    // No-op for mock repository in demo mode
    await Future.delayed(const Duration(milliseconds: 50));
  }

  @override
  Future<TeacherModel?> getTeacherByUserId(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // Try to find mock teacher or return default
    final t = _db.teachers.firstWhere(
      (x) => x.userId == userId || userId.contains(x.id),
      orElse: () => _db.teachers.first,
    );
    return t;
  }

  @override
  Future<List<CenterModel>> getTeacherCenters(String teacherId) async {
    await Future.delayed(const Duration(milliseconds: 150));
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
    await Future.delayed(const Duration(milliseconds: 150));
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
    await Future.delayed(const Duration(milliseconds: 300));
    return {
      'students_count': _db.students.length,
      'attendance_rate': 87,
      'today_classes_count': 3,
    };
  }

  // @override
  // Future<List<GroupModel>> getTeacherGroups(
  //   String teacherId,
  //   String centerId,
  // ) async {
  //   await Future.delayed(const Duration(milliseconds: 200));
  //   return _db.groups;
  // }

  // @override
  // Future<List<Map<String, dynamic>>> getTeacherStudents({
  //   required String teacherId,
  //   required String centerId,
  //   int? limit,
  //   int? offset,
  //   List<GroupModel>? preloadedGroups,
  // }) async {
  //   await Future.delayed(const Duration(milliseconds: 300));
  //   return _db.students
  //       .map(
  //         (s) => {
  //           'id': 'link_${s.id}',
  //           'student_id': s.id,
  //           'group_id': _db.groups[s.id.hashCode % _db.groups.length].id,
  //           'group_name':
  //               _db.groups[s.id.hashCode % _db.groups.length].groupName,
  //           'students': s.toJson(),
  //         },
  //       )
  //       .toList();
  // }

  // ═══════════════════════════════════════════════════════════════════════
  // TEACHER ATTENDANCE & SCHEDULE
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Map<String, dynamic>> startAttendanceSession({
    required String groupId,
    required String centerId,
    bool force = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return {'session_id': 'session_demo_$groupId', 'status': 'started'};
  }

  @override
  Future<void> saveAttendanceBulk({
    required String centerId,
    required String groupId,
    required String sessionId,
    required List<Map<String, dynamic>> attendanceList,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    for (final item in attendanceList) {
      _db.addAttendanceRecord(
        AttendanceModel(
          id: 'att_bulk_${DateTime.now().millisecondsSinceEpoch}_${item['student_id']}',
          centerId: centerId,
          groupId: groupId,
          sessionId: sessionId,
          studentId: item['student_id'],
          status: AttendanceStatus.fromString(
            item['status'] as String? ?? 'present',
          ),
          attendanceDate: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    }
  }

  // @override
  // Future<List<Map<String, dynamic>>> getGroupAttendanceForToday(
  //   String groupId, {
  //   DateTime? date,
  // }) async {
  //   await Future.delayed(const Duration(milliseconds: 200));
  //   return _db.attendance
  //       .where((a) => a.groupId == groupId)
  //       .map(
  //         (a) => {
  //           'student_id': a.studentId,
  //           'status': a.status.name,
  //           'notes': a.notes,
  //         },
  //       )
  //       .toList();
  // }

  @override
  Future<List<Map<String, dynamic>>> getGroupAttendanceHistory({
    int days = 30,
    required String groupId,
    int offsetDays = 0,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _db.attendance
        .where((a) => a.groupId == groupId)
        .map(
          (a) => {
            'student_id': a.studentId,
            'status': a.status.name,
            'notes': a.notes,
            'attendance_date': a.attendanceDate.toIso8601String(),
          },
        )
        .toList();
  }

  @override
  Future<List<ScheduleItem>> getTeacherSchedule({
    required String centerId,
    String? dayOfWeek,
    required String teacherId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));
    // Map groups to schedule items
    return _db.groups
        .map(
          (g) => ScheduleItem(
            id: 'session_${g.id}',
            centerId: g.centerId,
            groupId: g.id,
            groupName: g.groupName,
            courseId: g.courseId,
            courseName: g.courseName ?? 'مادة',
            teacherName: g.teacherName ?? 'مدرس',
            dayOfWeek: (g.dayOfWeek ?? 1).toString(),
            startTime: g.startTime ?? '16:00:00',
            endTime: g.endTime ?? '18:00:00',
            roomName: 'قاعة ابن سينا',
          ),
        )
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PARENT & CHILDREN
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Map<String, dynamic>?> getParentByUserId(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
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
    await Future.delayed(const Duration(milliseconds: 250));
    // Return first 2 students as children of this parent
    return _db.students.take(2).toList();
  }

  @override
  Future<List<ChildCenterInfo>> getChildCenters(String studentUserId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return [
      const ChildCenterInfo(
        centerId: 'center_demo',
        centerName: 'سنتر التميز (تجريبي)',
        status: EnrollmentStatus.active,
        attendanceRate: 92.5,
        totalDue: 500.0,
        totalPaid: 250.0,
      ),
    ];
  }

  @override
  Future<Map<String, dynamic>> getStudentDashboardSummary({
    required String studentId,
    String? centerId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return {
      'attendance_rate': 92.5,
      'average_grade': 89.2,
      'next_class_time': '16:00',
      'next_class_name': 'الفيزياء',
      'total_due': 250.0,
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
    await Future.delayed(const Duration(milliseconds: 200));
    final targetStudentId = (studentUserId ?? 'stu_0').replaceAll('user_', '');
    return _db.attendance.where((a) => a.studentId == targetStudentId).toList();
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
    await Future.delayed(const Duration(milliseconds: 250));
    final targetUserId = studentUserId ?? 'user_stu_0';
    final studentSubmissions = _db.submissions.where(
      (s) => s.studentUserId == targetUserId && s.status == 'graded',
    );
    return studentSubmissions.map((s) {
      final assignment = _db.assignments.firstWhere(
        (a) => a.id == s.assignmentId,
      );
      final scoreVal = s.score ?? 0;
      final maxVal = assignment.maxScore;
      final percentVal = maxVal > 0 ? (scoreVal / maxVal) * 100 : 0.0;
      return StudentGradeView(
        gradeId: s.id,
        courseId: assignment.courseId ?? '',
        courseName: assignment.courseName ?? 'مادة',
        examType: 'quiz',
        score: scoreVal,
        maxScore: maxVal,
        percentage: percentVal,
        comments: s.feedback,
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
    await Future.delayed(const Duration(milliseconds: 200));
    final targetStudentId = (studentUserId ?? 'stu_0').replaceAll('user_', '');
    return _db.payments.where((p) => p.studentId == targetStudentId).toList();
  }

  @override
  Future<Map<String, dynamic>> getStudentInvoiceSummary({
    required String centerId,
    required int month,
    required String studentId,
    required int year,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return {'total_paid': 250.0, 'total_due': 250.0, 'currency': 'EGP'};
  }

  @override
  Future<List<Map<String, dynamic>>> getStudentSchedule({
    required String centerId,
    required String studentUserId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // Return schedule items for groups the student is enrolled in
    return _db.groups
        .map(
          (g) => {
            'schedule_id': 'session_${g.id}',
            'center_id': centerId,
            'group_id': g.id,
            'group_name': g.groupName,
            'course_id': g.courseId,
            'course_name': g.courseName ?? 'مادة',
            'teacher_name': g.teacherName ?? 'مدرس',
            'day_of_week': g.dayOfWeek ?? 1,
            'start_time': g.startTime ?? '16:00:00',
            'end_time': g.endTime ?? '18:00:00',
            'room_name': 'قاعة ابن سينا',
          },
        )
        .toList();
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
    await Future.delayed(const Duration(milliseconds: 300));
    // Return all assignments with mock submission statuses
    return _db.assignments.map((a) {
      final sub = _db.submissions.firstWhere(
        (s) => s.assignmentId == a.id,
        orElse: () => SubmissionModel(
          id: '',
          assignmentId: '',
          studentUserId: '',
          submittedAt: DateTime.now(),
          status: 'pending',
        ),
      );

      final assignStatus = sub.id.isEmpty
          ? AssignmentStatus.pending
          : (sub.status == 'graded'
                ? AssignmentStatus.graded
                : AssignmentStatus.submitted);

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
    await Future.delayed(const Duration(milliseconds: 300));
    return _db.assignments
        .map(
          (a) => {
            'id': a.id,
            'title': a.title,
            'description': a.description,
            'due_date': a.dueDate?.toIso8601String(),
            'max_score': a.maxScore,
            'course_id': a.courseId,
            'course_name': a.courseName,
            'created_at': a.createdAt.toIso8601String(),
            'submissions_count': _db.submissions
                .where((s) => s.assignmentId == a.id)
                .length,
            'graded_count': _db.submissions
                .where((s) => s.assignmentId == a.id && s.status == 'graded')
                .length,
          },
        )
        .toList();
  }

  @override
  Future<List<SubmissionModel>> getAssignmentSubmissions(
    String assignmentId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return _db.submissions
        .where((s) => s.assignmentId == assignmentId)
        .toList();
  }

  @override
  Future<Map<String, dynamic>> getTeacherAssignmentStats(
    String centerId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return {
      'total_assignments': _db.assignments.length,
      'total_submissions': _db.submissions.length,
      'pending_grading': _db.submissions
          .where((s) => s.status == 'submitted')
          .length,
    };
  }

  @override
  Future<String> createAssignment(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final id = 'assign_new_${DateTime.now().millisecondsSinceEpoch}';
    final assignment = AssignmentModel(
      id: id,
      centerId: data['center_id'] ?? 'center_demo',
      courseId: data['course_id'],
      title: data['title'] ?? 'واجب جديد',
      description: data['description'],
      dueDate: data['due_date'] != null
          ? DateTime.parse(data['due_date'])
          : null,
      maxScore: (data['max_score'] as num?)?.toDouble() ?? 100.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      courseName: 'الفيزياء', // Mock course name
      teacherName: 'أ. أحمد السيد',
      questions: data['questions'],
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
    await Future.delayed(const Duration(milliseconds: 300));
    _db.gradeSubmissionRecord(submissionId, score, feedback ?? '', 'teacher_0');
  }
}
