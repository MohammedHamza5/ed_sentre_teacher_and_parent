import 'dart:math';
import '../shared/models/models.dart';

class MockDatabase {
  static final MockDatabase instance = MockDatabase._internal();

  MockDatabase._internal() {
    _generateData();
  }

  final Random _rnd = Random(42);

  final List<StudentModel> students = [];
  final List<TeacherModel> teachers = [];
  final List<CourseModel> courses = []; // Subjects
  final List<GroupModel> groups = [];
  final List<PaymentModel> payments = [];
  final List<AttendanceModel> attendance = [];
  final List<NotificationModel> notifications = []; // Or NotificationModel
  final List<AssignmentModel> assignments = [];
  final List<SubmissionModel> submissions = [];
  final List<Map<String, dynamic>> aiConversations = [];
  final List<Map<String, dynamic>> aiMessages = [];
  final List<Map<String, dynamic>> aiKnowledgeBase = [];

  final List<String> _firstNames = [
    'محمد',
    'أحمد',
    'محمود',
    'عمر',
    'علي',
    'كريم',
    'يوسف',
    'مريم',
    'نور',
    'فاطمة',
    'سارة',
    'هدى',
    'شهد',
    'ياسين',
    'آية',
  ];
  final List<String> _lastNames = [
    'السيد',
    'إبراهيم',
    'حسن',
    'عبدالله',
    'منصور',
    'عادل',
    'فاروق',
    'توفيق',
    'مجدي',
    'سامي',
  ];
  final List<String> _stages = ['الابتدائية', 'الإعدادية', 'الثانوية'];

  void _generateData() {
    _generateSubjects();
    _generateTeachers();
    _generateGroups();
    _generateStudents();
    _generatePayments();
    _generateAttendance();
    _generateNotifications();
    _generateAssignmentsAndSubmissions();
    _generateAIConversations();
  }

  String _randomName() {
    return '${_firstNames[_rnd.nextInt(_firstNames.length)]} ${_lastNames[_rnd.nextInt(_lastNames.length)]}';
  }

  void _generateSubjects() {
    final baseSubjects = [
      'اللغة العربية',
      'الرياضيات',
      'الفيزياء',
      'الكيمياء',
      'اللغة الإنجليزية',
    ];
    int id = 1;
    for (String subName in baseSubjects) {
      courses.add(
        CourseModel(
          id: 'sub_${id++}',
          centerId: 'center_demo',
          name: subName,
          code: 'SUB-${subName.hashCode % 100}',
          description: 'شرح وتدريبات مادة $subName',
          createdAt: DateTime.now().subtract(const Duration(days: 180)),
          updatedAt: DateTime.now(),
        ),
      );
    }
  }

  void _generateTeachers() {
    // Generate 5 teachers
    for (int i = 0; i < 5; i++) {
      final course = courses[i % courses.length];
      final id = 'teacher_$i';
      teachers.add(
        TeacherModel(
          id: id,
          userId: 'user_teacher_$i',
          fullName: 'أ. ${_randomName()}',
          phone: '010${_rnd.nextInt(99999999).toString().padLeft(8, '0')}',
          email: 'teacher_$i@edsentre.demo',
          rating: 4.5 + (_rnd.nextDouble() * 0.5),
          specializations: [course.name],
          createdAt: DateTime.now().subtract(const Duration(days: 180)),
          updatedAt: DateTime.now(),
        ),
      );
    }
  }

  void _generateGroups() {
    int grpId = 1;
    for (int i = 0; i < 6; i++) {
      final teacher = teachers[i % teachers.length];
      final course = courses[i % courses.length];
      final stage = _stages[i % _stages.length];
      groups.add(
        GroupModel(
          id: 'grp_$grpId',
          centerId: 'center_demo',
          courseId: course.id,
          teacherId: teacher.id,
          groupName: 'مجموعة $grpId - ${course.name} ($stage)',
          groupCode: 'GRP-$grpId',
          gradeLevel: stage,
          maxStudents: 100,
          currentStudents: 45 + _rnd.nextInt(20),
          dayOfWeek: (i % 6) + 1, // 1 to 6
          startTime: '16:00:00',
          endTime: '18:00:00',
          monthlyFee: 250.0 + _rnd.nextInt(10) * 10,
          sessionPrice: 65.0,
          isActive: true,
          courseName: course.name,
          teacherName: teacher.fullName,
          createdAt: DateTime.now().subtract(const Duration(days: 100)),
          updatedAt: DateTime.now(),
        ),
      );
      grpId++;
    }
  }

  void _generateStudents() {
    // Generate 50 students
    for (int i = 0; i < 50; i++) {
      final stage = _stages[_rnd.nextInt(_stages.length)];
      final name = _randomName();
      final phone = '011${_rnd.nextInt(99999999).toString().padLeft(8, '0')}';
      students.add(
        StudentModel(
          id: 'stu_$i',
          userId: 'user_student_$i',
          fullName: name,
          phone: phone,
          email: 'student_$i@edsentre.demo',
          studentCode: 'STU-${1000 + i}',
          parentPhone:
              '012${_rnd.nextInt(99999999).toString().padLeft(8, '0')}',
          schoolName: 'مدرسة التفوق الحديثة',
          academicYear: stage,
          address: 'القاهرة، مصر الجديدة',
          createdAt: DateTime.now().subtract(const Duration(days: 90)),
          updatedAt: DateTime.now(),
        ),
      );
    }
  }

  void _generatePayments() {
    int payId = 1;
    for (int i = 0; i < 30; i++) {
      final student = students[i % students.length];
      final amount = 300.0;
      payments.add(
        PaymentModel(
          id: 'pay_$payId',
          centerId: 'center_demo',
          studentId: student.id,
          amount: amount,
          paymentMethod: 'cash',
          status: PaymentStatus.paid,
          notes: 'دفع مصروفات شهر يوليو',
          paymentDate: DateTime.now().subtract(
            Duration(days: _rnd.nextInt(20)),
          ),
          createdAt: DateTime.now().subtract(const Duration(days: 20)),
          updatedAt: DateTime.now(),
        ),
      );
      payId++;
    }
  }

  void _generateAttendance() {
    int attId = 1;
    // Generate some attendance records for past 7 days
    final now = DateTime.now();
    for (int day = 1; day <= 7; day++) {
      final date = now.subtract(Duration(days: day));
      // For each group
      for (final grp in groups) {
        // Select 5 random students to have attendance records
        for (int s = 0; s < 5; s++) {
          final student = students[_rnd.nextInt(students.length)];
          final statuses = ['present', 'absent', 'late', 'excused'];
          final status = statuses[_rnd.nextInt(statuses.length)];
          attendance.add(
            AttendanceModel(
              id: 'att_$attId',
              centerId: 'center_demo',
              groupId: grp.id,
              studentId: student.id,
              studentUserId: student.userId,
              attendanceDate: date,
              status: AttendanceStatus.fromString(status),
              notes: status == 'late' ? 'تأخير 10 دقائق' : '',
              createdAt: date,
              updatedAt: date,
              studentName: student.fullName,
            ),
          );
          attId++;
        }
      }
    }
  }

  void _generateNotifications() {
    for (int i = 0; i < 10; i++) {
      notifications.add(
        NotificationModel(
          id: 'notif_$i',
          userId: 'demo_teacher_id',
          title: ['تذكير بالواجب', 'تم تسجيل غياب', 'فاتورة جديدة'][i % 3],
          body: 'هذا إشعار تجريبي لاختبار التنبيهات في النظام رقم $i',
          type: ['assignment', 'attendance', 'payment'][i % 3],
          createdAt: DateTime.now().subtract(Duration(hours: i * 4)),
          isRead: i > 4,
        ),
      );
    }
  }

  void _generateAssignmentsAndSubmissions() {
    int assignId = 1;
    int subId = 1;

    for (final grp in groups) {
      // 2 assignments per group
      for (int i = 1; i <= 2; i++) {
        final date = DateTime.now().subtract(Duration(days: i * 5));
        final dueDate = DateTime.now().add(Duration(days: 3 - i * 3));

        final assignment = AssignmentModel(
          id: 'assign_$assignId',
          centerId: 'center_demo',
          courseId: grp.courseId,
          title: 'واجب ${grp.courseName} - الدرس $i',
          description:
              'يرجى حل الأسئلة المرفقة وقراءة الصفحات المحددة في الكتاب المدرسي.',
          dueDate: dueDate,
          maxScore: 100.0,
          createdAt: date,
          updatedAt: date,
          courseName: grp.courseName,
          teacherName: grp.teacherName,
          questions: [
            {
              'id': 'q1',
              'text': 'السؤال الأول: اختر الإجابة الصحيحة',
              'type': 'multiple_choice',
              'options': ['أ', 'ب', 'ج', 'د'],
              'correct_answer': 'أ',
              'marks': 50.0,
            },
            {
              'id': 'q2',
              'text': 'السؤال الثاني: اكتب مقالاً تلخيصياً للدرس',
              'type': 'essay',
              'correct_answer': 'إجابة حرة للتقييم اليدوي',
              'marks': 50.0,
            },
          ],
        );
        assignments.add(assignment);

        // Submissions for some students
        for (int s = 0; s < 4; s++) {
          final student = students[_rnd.nextInt(students.length)];
          final isGraded = _rnd.nextBool();
          submissions.add(
            SubmissionModel(
              id: 'sub_${subId++}',
              assignmentId: assignment.id,
              studentUserId: student.userId ?? 'user_${student.id}',
              submissionText: 'هذا هو الحل المقترح للواجب الخاص بالدرس الأول.',
              submittedAt: date.add(const Duration(days: 1)),
              score: isGraded ? (80.0 + _rnd.nextInt(20)) : null,
              feedback: isGraded ? 'أحسنت، إجابة ممتازة ومكتملة.' : null,
              status: isGraded ? 'graded' : 'submitted',
              studentName: student.fullName,
            ),
          );
        }

        assignId++;
      }
    }
  }

  void _generateAIConversations() {
    aiConversations.add({
      'id': 'conv_demo_1',
      'teacher_id': 'demo_teacher_id',
      'title': 'مراجعة أداء فصل الفيزياء',
      'created_at': DateTime.now()
          .subtract(const Duration(days: 1))
          .toIso8601String(),
      'last_message_at': DateTime.now()
          .subtract(const Duration(hours: 2))
          .toIso8601String(),
    });

    aiMessages.add({
      'id': 'msg_demo_1',
      'session_id': 'conv_demo_1',
      'sender': 'user',
      'message': 'كيف يمكنني تحسين أداء الطلاب في مادة الفيزياء؟',
      'created_at': DateTime.now()
          .subtract(const Duration(hours: 2, minutes: 10))
          .toIso8601String(),
    });

    aiMessages.add({
      'id': 'msg_demo_2',
      'session_id': 'conv_demo_1',
      'sender': 'ai',
      'message':
          'أهلاً بك يا أستاذ. بتحليل درجات الطلاب في مجموعة الفيزياء (الثانوية)، نلاحظ أن حوالي 30% من الطلاب لديهم درجات منخفضة في فصل "الكهرباء التيارىة". أقترح تنظيم حصة مراجعة مخصصة لحل المسائل الصعبة وتوليد واجب قصير يركز على قوانين كيرشوف لتقييم فهمهم الحالي.',
      'created_at': DateTime.now()
          .subtract(const Duration(hours: 2))
          .toIso8601String(),
    });

    aiKnowledgeBase.add({
      'id': 'kb_demo_1',
      'center_id': 'center_demo',
      'title': 'مذكرة شرح الميكانيكا - الصف الثالث الثانوي',
      'file_url': 'https://example.com/mechanics_notes.pdf',
      'file_size': 1024 * 1024 * 5, // 5MB
      'created_at': DateTime.now()
          .subtract(const Duration(days: 10))
          .toIso8601String(),
    });
  }

  // Operations
  void addAttendanceRecord(AttendanceModel record) {
    attendance.removeWhere(
      (a) =>
          a.groupId == record.groupId &&
          a.studentId == record.studentId &&
          a.attendanceDate.year == record.attendanceDate.year &&
          a.attendanceDate.month == record.attendanceDate.month &&
          a.attendanceDate.day == record.attendanceDate.day,
    );
    attendance.add(record);
  }

  void addAssignmentRecord(AssignmentModel record) {
    assignments.insert(0, record);
  }

  void addSubmissionRecord(SubmissionModel record) {
    submissions.add(record);
  }

  void gradeSubmissionRecord(
    String id,
    double score,
    String feedback,
    String teacherId,
  ) {
    final idx = submissions.indexWhere((s) => s.id == id);
    if (idx != -1) {
      final s = submissions[idx];
      submissions[idx] = SubmissionModel(
        id: s.id,
        assignmentId: s.assignmentId,
        studentUserId: s.studentUserId,
        submissionText: s.submissionText,
        fileUrls: s.fileUrls,
        submittedAt: s.submittedAt,
        score: score,
        feedback: feedback,
        gradedBy: teacherId,
        gradedAt: DateTime.now(),
        status: 'graded',
        studentName: s.studentName,
        studentAvatar: s.studentAvatar,
      );
    }
  }
}
