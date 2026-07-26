import 'dart:math';
import '../shared/models/models.dart';

/// MockDatabase - Smart Demo Database (الداتا الذكية والموحدة للمنظومة)
/// يضمن هذا المستودع ترابطاً ذكياً وكاملاً بين:
/// - المعلم الافتراضي (أ. أحمد السيد - مدرس الفيزياء والرياضيات)
/// - ولي الأمر الافتراضي (أبو محمد - ولي أمر الطالب محمد ومريم)
/// - الأبناء والمجموعات والحضور والدرجات والمستحقات والمذكرات والمحادثات
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
  final List<NotificationModel> notifications = [];
  final List<AssignmentModel> assignments = [];
  final List<SubmissionModel> submissions = [];
  final List<StudyMaterialModel> studyMaterials = [];
  final List<ConversationModel> conversations = [];
  final List<MessageModel> chatMessages = [];
  
  // Curriculum (Subjects, Chapters, Lessons)
  final List<Map<String, dynamic>> curriculumSubjects = [];
  final List<Map<String, dynamic>> curriculumChapters = [];
  final List<Map<String, dynamic>> curriculumLessons = [];

  // AI Data
  final List<Map<String, dynamic>> aiConversations = [];
  final List<Map<String, dynamic>> aiMessages = [];
  final List<Map<String, dynamic>> aiKnowledgeBase = [];

  final List<String> _firstNames = ['محمد', 'أحمد', 'محمود', 'عمر', 'علي', 'كريم', 'يوسف', 'مريم', 'نور', 'فاطمة', 'سارة', 'هدى', 'شهد', 'ياسين', 'آية'];
  final List<String> _lastNames = ['السيد', 'إبراهيم', 'حسن', 'عبدالله', 'منصور', 'عادل', 'فاروق', 'توفيق', 'مجدي', 'سامي'];
  final List<String> _stages = ['الابتدائية', 'الإعدادية', 'الثانوية'];

  void _generateData() {
    _generateSubjectsAndCurriculum();
    _generateTeachers();
    _generateGroups();
    _generateStudents();
    _generatePayments();
    _generateAttendance();
    _generateNotifications();
    _generateAssignmentsAndSubmissions();
    _generateStudyMaterials();
    _generateConversationsAndMessages();
    _generateAIConversations();
  }

  String _randomName() {
    return '${_firstNames[_rnd.nextInt(_firstNames.length)]} ${_lastNames[_rnd.nextInt(_lastNames.length)]}';
  }

  void _generateSubjectsAndCurriculum() {
    final baseSubjects = ['الفيزياء', 'الرياضيات', 'الكيمياء', 'اللغة العربية', 'اللغة الإنجليزية'];
    int id = 1;
    for (String subName in baseSubjects) {
      final subId = 'sub_${id++}';
      courses.add(CourseModel(
        id: subId,
        centerId: 'center_demo',
        name: subName,
        code: 'SUB-${subName.hashCode % 100}',
        description: 'شرح وتدريبات مادة $subName باحترافية وتطبيقات شاملة',
        createdAt: DateTime.now().subtract(const Duration(days: 180)),
        updatedAt: DateTime.now(),
      ));

      // Add to curriculum
      curriculumSubjects.add({
        'id': subId,
        'name': subName,
        'description': 'شرح وتدريبات مادة $subName باحترافية وتطبيقات شاملة',
        'center_id': 'center_demo',
        'lessons_count': 12,
        'chapters_count': 4,
        'created_at': DateTime.now().subtract(const Duration(days: 180)).toIso8601String(),
      });

      // Generate chapters and lessons for Physics & Math
      if (subId == 'sub_1' || subId == 'sub_2') {
        for (int ch = 1; ch <= 3; ch++) {
          final chId = 'ch_${subId}_$ch';
          curriculumChapters.add({
            'id': chId,
            'subject_id': subId,
            'title': subId == 'sub_1' ? 'الفصل $ch: قوانين وتطبيقات الميكانيكا والكهرباء' : 'الفصل $ch: الجبر والهندسة التحليلية',
            'order_index': ch,
            'lessons_count': 4,
          });

          for (int l = 1; l <= 3; l++) {
            curriculumLessons.add({
              'id': 'les_${chId}_$l',
              'chapter_id': chId,
              'subject_id': subId,
              'title': 'الدرس $l: الشرح الوافي وحل مسائل التميز',
              'content': 'ملخص أهم القوانين والنقاط الأساسية مع أسئلة اختيار من متعدد وتطبيقات مباشرة من امتحانات السنين السابقة.',
              'order_index': l,
              'duration_minutes': 45,
              'video_url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
              'attachment_url': 'https://example.com/lesson_note.pdf',
              'is_free': l == 1,
            });
          }
        }
      }
    }
  }

  void _generateTeachers() {
    // Flagship Teacher 0: أ. أحمد السيد (خبير الفيزياء والرياضيات)
    teachers.add(TeacherModel(
      id: 'teacher_0',
      userId: 'demo_teacher_id',
      fullName: 'أ. أحمد السيد',
      phone: '01012345678',
      email: 'teacher@edsentre.demo',
      rating: 4.9,
      specializations: ['الفيزياء', 'الرياضيات'],
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
      updatedAt: DateTime.now(),
    ));

    for (int i = 1; i < 5; i++) {
      final course = courses[i % courses.length];
      final id = 'teacher_$i';
      teachers.add(TeacherModel(
        id: id,
        userId: 'user_teacher_$i',
        fullName: 'أ. ${_randomName()}',
        phone: '010${_rnd.nextInt(99999999).toString().padLeft(8, '0')}',
        email: 'teacher_$i@edsentre.demo',
        rating: 4.5 + (_rnd.nextDouble() * 0.4),
        specializations: [course.name],
        createdAt: DateTime.now().subtract(const Duration(days: 180)),
        updatedAt: DateTime.now(),
      ));
    }
  }

  void _generateGroups() {
    final teacher = teachers[0]; // Teacher Ahmed
    final physics = courses[0];
    final math = courses[1];

    // Group 1: Physics for 3rd Secondary (Contains Mohamed)
    groups.add(GroupModel(
      id: 'grp_1',
      centerId: 'center_demo',
      courseId: physics.id,
      teacherId: teacher.id,
      groupName: 'مجموعة التميز - فيزياء (الثانوية العامة)',
      groupCode: 'PHY-3SEC',
      gradeLevel: 'الصف الثالث الثانوي',
      maxStudents: 80,
      currentStudents: 65,
      dayOfWeek: 2, // Monday
      startTime: '16:00:00',
      endTime: '18:30:00',
      monthlyFee: 350.0,
      sessionPrice: 85.0,
      isActive: true,
      courseName: physics.name,
      teacherName: teacher.fullName,
      createdAt: DateTime.now().subtract(const Duration(days: 120)),
      updatedAt: DateTime.now(),
    ));

    // Group 2: Math for 1st Secondary (Contains Maryam)
    groups.add(GroupModel(
      id: 'grp_2',
      centerId: 'center_demo',
      courseId: math.id,
      teacherId: teacher.id,
      groupName: 'مجموعة التأسيس والشرح - رياضيات (أولى ثانوي)',
      groupCode: 'MTH-1SEC',
      gradeLevel: 'الصف الأول الثانوي',
      maxStudents: 90,
      currentStudents: 75,
      dayOfWeek: 4, // Wednesday
      startTime: '14:00:00',
      endTime: '16:00:00',
      monthlyFee: 300.0,
      sessionPrice: 70.0,
      isActive: true,
      courseName: math.name,
      teacherName: teacher.fullName,
      createdAt: DateTime.now().subtract(const Duration(days: 120)),
      updatedAt: DateTime.now(),
    ));

    // Group 3: Physics Revision
    groups.add(GroupModel(
      id: 'grp_3',
      centerId: 'center_demo',
      courseId: physics.id,
      teacherId: teacher.id,
      groupName: 'مجموعة مراجعة القوانين والامتحانات (ثانية ثانوي)',
      groupCode: 'PHY-2SEC',
      gradeLevel: 'الصف الثاني الثانوي',
      maxStudents: 70,
      currentStudents: 58,
      dayOfWeek: 6, // Friday
      startTime: '10:00:00',
      endTime: '12:30:00',
      monthlyFee: 320.0,
      sessionPrice: 75.0,
      isActive: true,
      courseName: physics.name,
      teacherName: teacher.fullName,
      createdAt: DateTime.now().subtract(const Duration(days: 100)),
      updatedAt: DateTime.now(),
    ));

    int grpId = 4;
    for (int i = 2; i < courses.length; i++) {
      final t = teachers[i % teachers.length];
      final c = courses[i];
      groups.add(GroupModel(
        id: 'grp_$grpId',
        centerId: 'center_demo',
        courseId: c.id,
        teacherId: t.id,
        groupName: 'مجموعة $grpId - ${c.name}',
        groupCode: 'GRP-$grpId',
        gradeLevel: 'المرحلة الإعدادية',
        maxStudents: 60,
        currentStudents: 40 + _rnd.nextInt(15),
        dayOfWeek: (i % 6) + 1,
        startTime: '17:00:00',
        endTime: '19:00:00',
        monthlyFee: 250.0,
        sessionPrice: 60.0,
        isActive: true,
        courseName: c.name,
        teacherName: t.fullName,
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
        updatedAt: DateTime.now(),
      ));
      grpId++;
    }
  }

  void _generateStudents() {
    // Student 0: محمد محمود (ابن ولي الأمر التجريبي الأكبر - فيزياء)
    students.add(StudentModel(
      id: 'stu_0',
      userId: 'user_student_0',
      fullName: 'محمد محمود السيد',
      phone: '01123456789',
      email: 'mohamed@edsentre.demo',
      studentCode: 'STU-1001',
      parentPhone: '01112345678',
      schoolName: 'مدرسة المتفوقين الرسمية لغات',
      academicYear: 'الصف الثالث الثانوي',
      address: 'القاهرة، مدينة نصر',
      createdAt: DateTime.now().subtract(const Duration(days: 150)),
      updatedAt: DateTime.now(),
    ));

    // Student 1: مريم محمود (ابنة ولي الأمر التجريبي الصغرى - رياضيات)
    students.add(StudentModel(
      id: 'stu_1',
      userId: 'user_student_1',
      fullName: 'مريم محمود السيد',
      phone: '01123456780',
      email: 'maryam@edsentre.demo',
      studentCode: 'STU-1002',
      parentPhone: '01112345678',
      schoolName: 'مدرسة النور الخاصة',
      academicYear: 'الصف الأول الثانوي',
      address: 'القاهرة، مدينة نصر',
      createdAt: DateTime.now().subtract(const Duration(days: 150)),
      updatedAt: DateTime.now(),
    ));

    // Generate 38 more classmates
    for (int i = 2; i < 40; i++) {
      final stage = _stages[_rnd.nextInt(_stages.length)];
      students.add(StudentModel(
        id: 'stu_$i',
        userId: 'user_student_$i',
        fullName: _randomName(),
        phone: '011${_rnd.nextInt(99999999).toString().padLeft(8, '0')}',
        email: 'student_$i@edsentre.demo',
        studentCode: 'STU-${1001 + i}',
        parentPhone: '012${_rnd.nextInt(99999999).toString().padLeft(8, '0')}',
        schoolName: 'مدرسة المستقبل الثانوية',
        academicYear: stage,
        address: 'القاهرة، مصر الجديدة',
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
        updatedAt: DateTime.now(),
      ));
    }
  }

  void _generatePayments() {
    // Guaranteed rich payment history for Mohamed (stu_0)
    payments.add(PaymentModel(
      id: 'pay_m_1',
      centerId: 'center_demo',
      studentId: 'stu_0',
      amount: 350.0,
      paymentMethod: 'cash',
      status: PaymentStatus.paid,
      notes: 'اشتراك شهر أكتوبر - مجموعة التميز (فيزياء)',
      paymentDate: DateTime.now().subtract(const Duration(days: 35)),
      createdAt: DateTime.now().subtract(const Duration(days: 35)),
      updatedAt: DateTime.now().subtract(const Duration(days: 35)),
    ));
    payments.add(PaymentModel(
      id: 'pay_m_2',
      centerId: 'center_demo',
      studentId: 'stu_0',
      amount: 350.0,
      paymentMethod: 'online',
      status: PaymentStatus.paid,
      notes: 'اشتراك شهر نوفمبر - مجموعة التميز (فيزياء)',
      paymentDate: DateTime.now().subtract(const Duration(days: 5)),
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now().subtract(const Duration(days: 5)),
    ));
    payments.add(PaymentModel(
      id: 'pay_m_3',
      centerId: 'center_demo',
      studentId: 'stu_0',
      amount: 85.0,
      paymentMethod: 'cash',
      status: PaymentStatus.paid,
      notes: 'رسوم مذكرة التميز في الفيزياء (الفصل الأول)',
      paymentDate: DateTime.now().subtract(const Duration(days: 15)),
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      updatedAt: DateTime.now().subtract(const Duration(days: 15)),
    ));

    // Guaranteed rich payment history for Maryam (stu_1)
    payments.add(PaymentModel(
      id: 'pay_m_4',
      centerId: 'center_demo',
      studentId: 'stu_1',
      amount: 300.0,
      paymentMethod: 'cash',
      status: PaymentStatus.paid,
      notes: 'اشتراك شهر نوفمبر - مجموعة التأسيس (رياضيات)',
      paymentDate: DateTime.now().subtract(const Duration(days: 8)),
      createdAt: DateTime.now().subtract(const Duration(days: 8)),
      updatedAt: DateTime.now().subtract(const Duration(days: 8)),
    ));

    // Generate payments for classmates
    int payId = 10;
    for (int i = 2; i < 25; i++) {
      final student = students[i % students.length];
      payments.add(PaymentModel(
        id: 'pay_$payId',
        centerId: 'center_demo',
        studentId: student.id,
        amount: 300.0,
        paymentMethod: 'cash',
        status: PaymentStatus.paid,
        notes: 'دفع مصروفات الشهر الحالي',
        paymentDate: DateTime.now().subtract(Duration(days: _rnd.nextInt(20))),
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        updatedAt: DateTime.now(),
      ));
      payId++;
    }
  }

  void _generateAttendance() {
    int attId = 100;
    final now = DateTime.now();

    // Guaranteed rich attendance records for Mohamed (stu_0 in grp_1)
    for (int day = 1; day <= 8; day++) {
      final sessionDate = now.subtract(Duration(days: day * 3));
      final isLate = day == 3;
      attendance.add(AttendanceModel(
        id: 'att_m_$day',
        centerId: 'center_demo',
        groupId: 'grp_1',
        studentId: 'stu_0',
        studentUserId: 'user_student_0',
        attendanceDate: sessionDate,
        status: isLate ? AttendanceStatus.late : AttendanceStatus.present,
        notes: isLate ? 'تأخير 10 دقائق بسبب الازدحام المروري' : 'حضور ممتاز وفي الموعد',
        createdAt: sessionDate,
        updatedAt: sessionDate,
        studentName: 'محمد محمود السيد',
      ));
    }

    // Guaranteed rich attendance records for Maryam (stu_1 in grp_2)
    for (int day = 1; day <= 6; day++) {
      final sessionDate = now.subtract(Duration(days: day * 4));
      attendance.add(AttendanceModel(
        id: 'att_m2_$day',
        centerId: 'center_demo',
        groupId: 'grp_2',
        studentId: 'stu_1',
        studentUserId: 'user_student_1',
        attendanceDate: sessionDate,
        status: AttendanceStatus.present,
        notes: 'التزام تام وحوار فعال داخل الحصة',
        createdAt: sessionDate,
        updatedAt: sessionDate,
        studentName: 'مريم محمود السيد',
      ));
    }

    // Generate random attendance for the last 14 days across groups
    for (int day = 1; day <= 14; day += 2) {
      final date = now.subtract(Duration(days: day));
      for (final grp in groups) {
        for (int s = 2; s < 12; s++) {
          final student = students[s];
          final statuses = [AttendanceStatus.present, AttendanceStatus.present, AttendanceStatus.present, AttendanceStatus.late, AttendanceStatus.absent];
          final status = statuses[_rnd.nextInt(statuses.length)];
          attendance.add(AttendanceModel(
            id: 'att_${attId++}',
            centerId: 'center_demo',
            groupId: grp.id,
            studentId: student.id,
            studentUserId: student.userId ?? 'user_${student.id}',
            attendanceDate: date,
            status: status,
            notes: status == AttendanceStatus.late ? 'تأخير 5 دقائق' : '',
            createdAt: date,
            updatedAt: date,
            studentName: student.fullName,
          ));
        }
      }
    }
  }

  void _generateNotifications() {
    final titles = [
      '🎉 تم رصد درجة امتحان شهر نوفمبر',
      '✅ تم تسجيل حضور حصة اليوم',
      '📄 تم رفع مذكرة الفيزياء (الفصل الثاني) في قسم المذكرات',
      '💰 إشعار باستلام القسط الشهري بنجاح',
      '🔔 تذكير: حصة المراجعة الشاملة غداً الساعة 4 عصراً'
    ];
    final bodies = [
      'حصل محمد محمود على 94% (A+) في اختبار الفيزياء التحريري. أداء مشرفة ومجهود رائع!',
      'تم تسجيل حضور الطالب محمد في مجموعة التميز وفي الوقت المحدد للحصة.',
      'قام الأستاذ أحمد السيد برفقة ملف مذكرة الشرح الوافي مع أسئلة وإجابات نموذجية.',
      'تم تأكيد دفع رسوم اشتراك الشهر المحددة وإصدرا إيصال إلكتروني برقم #PAY-3502.',
      'يرجى التأكد من حل تدريبات الكتاب قبل القدوم لحصص المراجعة النهائية.'
    ];

    for (int i = 0; i < titles.length; i++) {
      notifications.add(NotificationModel(
        id: 'notif_$i',
        userId: 'demo_teacher_id', // Useful for both teacher and parent views
        title: titles[i],
        body: bodies[i],
        type: ['assignment', 'attendance', 'material', 'payment', 'schedule'][i],
        createdAt: DateTime.now().subtract(Duration(hours: i * 5 + 1)),
        isRead: i > 2,
      ));
    }
  }

  void _generateAssignmentsAndSubmissions() {
    int subId = 1;

    for (final grp in groups.take(3)) {
      for (int i = 1; i <= 3; i++) {
        final createdDate = DateTime.now().subtract(Duration(days: i * 7));
        final dueDate = DateTime.now().add(Duration(days: 4 - i * 2));
        
        final assignment = AssignmentModel(
          id: 'assign_${grp.id}_$i',
          centerId: 'center_demo',
          courseId: grp.courseId,
          title: 'واجب ${grp.courseName} — التدريب الأسبوعي $i',
          description: 'يرجى الإجابة على كافة المسائل والتدريبات التمهيدية المرفقة ومراجعة خطوات الحل النموذجية.',
          dueDate: dueDate,
          maxScore: 100.0,
          createdAt: createdDate,
          updatedAt: createdDate,
          courseName: grp.courseName,
          teacherName: grp.teacherName,
          questions: [
            {
              'id': 'q1',
              'text': 'السؤال الأول: اختر الإجابة الصحيحة بناءً على القوانين المدروسة',
              'type': 'multiple_choice',
              'options': ['الإجابة الأولى (A)', 'الإجابة الثانية (B)', 'الإجابة الثالثة (C)', 'الإجابة الرابعة (D)'],
              'correct_answer': 'الإجابة الأولى (A)',
              'marks': 50.0,
            },
            {
              'id': 'q2',
              'text': 'السؤال الثاني: اشرح بالتفصيل خطوات استنتاج المعادلة الرياضية للمسألة',
              'type': 'essay',
              'correct_answer': 'خطوات تفصيلية ومنطقية مع كتابة الوحدات القياسية بشكل سليم',
              'marks': 50.0,
            }
          ],
        );
        assignments.add(assignment);

        // Ensure Mohamed (user_student_0) has stellar submissions for Group 1 assignments
        if (grp.id == 'grp_1') {
          final scores = [94.0, 98.0, 90.0];
          final feedbacks = [
            'إجابة متميزة وتنظيم رائع للخطوات الرياضية. أحسنت!',
            'ممتاز جداً، تميز واضح في حل المسألة الثانية.',
            'أداء جيد جداً، انتبه فقط لوحدات القياس في الخطوة الأخيرة من المسألة الأولى.'
          ];
          submissions.add(SubmissionModel(
            id: 'sub_m_${grp.id}_$i',
            assignmentId: assignment.id,
            studentUserId: 'user_student_0',
            submissionText: 'تم إرفاق إجابة الواجب شاملة الحل المفصل للمسألة المقالية.',
            submittedAt: createdDate.add(const Duration(days: 1)),
            score: scores[(i - 1) % scores.length],
            feedback: feedbacks[(i - 1) % feedbacks.length],
            gradedBy: 'teacher_0',
            gradedAt: createdDate.add(const Duration(days: 2)),
            status: 'graded',
            studentName: 'محمد محمود السيد',
          ));
        }

        // Ensure Maryam (user_student_1) has stellar submissions for Group 2 assignments
        if (grp.id == 'grp_2') {
          final scores = [100.0, 95.0, 92.0];
          submissions.add(SubmissionModel(
            id: 'sub_m2_${grp.id}_$i',
            assignmentId: assignment.id,
            studentUserId: 'user_student_1',
            submissionText: 'حل تمارين الهندسة والجبر كاملة.',
            submittedAt: createdDate.add(const Duration(days: 1)),
            score: scores[(i - 1) % scores.length],
            feedback: 'عبقرية متفوقة ودقة عالية في الرسم البياني. تمنياتي بدوام التفوق.',
            gradedBy: 'teacher_0',
            gradedAt: createdDate.add(const Duration(days: 2)),
            status: 'graded',
            studentName: 'مريم محمود السيد',
          ));
        }

        // Submissions for classmates
        for (int s = 2; s < 7; s++) {
          final student = students[s];
          final isGraded = s % 2 == 0;
          submissions.add(SubmissionModel(
            id: 'sub_${subId++}',
            assignmentId: assignment.id,
            studentUserId: student.userId ?? 'user_${student.id}',
            submissionText: 'هذا هو الحل المقترح للتدريب الأسبوعي.',
            submittedAt: createdDate.add(const Duration(days: 1)),
            score: isGraded ? (75.0 + _rnd.nextInt(20)) : null,
            feedback: isGraded ? 'أحسنت، إجابة ممتازة ومكتملة.' : null,
            status: isGraded ? 'graded' : 'submitted',
            studentName: student.fullName,
          ));
        }
      }
    }
  }

  void _generateStudyMaterials() {
    studyMaterials.add(StudyMaterialModel(
      id: 'mat_1',
      centerId: 'center_demo',
      courseId: courses[0].id,
      teacherId: teachers[0].id,
      title: 'مذكرة التميز الشاملة في الفيزياء (الفصل الأول: الكهرباء)',
      description: 'شرح مبسط ومفصل لقوانين أوم وكيرشوف مع أكثر than 120 مسألة مجابة بخطوات نموذجية.',
      fileUrl: 'https://example.com/physics_chapter1.pdf',
      fileType: 'pdf',
      fileSize: 8500000, // 8.5 MB
      isPublished: true,
      downloadCount: 142,
      createdAt: DateTime.now().subtract(const Duration(days: 25)),
      updatedAt: DateTime.now().subtract(const Duration(days: 5)),
      courseName: 'الفيزياء',
      teacherName: 'أ. أحمد السيد',
    ));

    studyMaterials.add(StudyMaterialModel(
      id: 'mat_2',
      centerId: 'center_demo',
      courseId: courses[0].id,
      teacherId: teachers[0].id,
      title: 'بنك أسئلة امتحانات الثانوية العامة في الفيزياء (سنين سابقة)',
      description: 'تجميع لكل الأفكار والتكات التي وردت بالامتحانات من 2018 وحتى 2025 مع الإجابات.',
      fileUrl: 'https://example.com/physics_bank.pdf',
      fileType: 'pdf',
      fileSize: 12400000, // 12.4 MB
      isPublished: true,
      downloadCount: 215,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      updatedAt: DateTime.now(),
      courseName: 'الفيزياء',
      teacherName: 'أ. أحمد السيد',
    ));

    studyMaterials.add(StudyMaterialModel(
      id: 'mat_3',
      centerId: 'center_demo',
      courseId: courses[1].id,
      teacherId: teachers[0].id,
      title: 'مذكرة التأسيس الذهبية في الرياضيات (أولى ثانوي - جبر وهندسة)',
      description: 'شرح تأسيسي رائع وبسيط للمنطق الرياضي وحل المعادلات والمصفوفات مع رسوم بيانية توضيحية.',
      fileUrl: 'https://example.com/math_1sec.pdf',
      fileType: 'pdf',
      fileSize: 6200000, // 6.2 MB
      isPublished: true,
      downloadCount: 98,
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      courseName: 'الرياضيات',
      teacherName: 'أ. أحمد السيد',
    ));
  }

  void _generateConversationsAndMessages() {
    final convId = 'conv_demo_parent_teacher';
    conversations.add(ConversationModel(
      id: convId,
      studentId: 'stu_0',
      teacherId: 'teacher_0',
      centerId: 'center_demo',
      conversationType: ConversationType.parentTeacher,
      parentId: 'demo_parent_id',
      lastMessage: 'وعليكم السلام يا أستاذ، أشكرك جداً على متابعة محمد الدقيقة وتحفيزك المستمر له.',
      lastMessageAt: DateTime.now().subtract(const Duration(minutes: 45)),
      unreadCountStudent: 0,
      unreadCountTeacher: 0,
      unreadCountParent: 0,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 45)),
      teacherName: 'أ. أحمد السيد (خبير الفيزياء)',
      studentName: 'محمد محمود السيد',
      parentName: 'أبو محمد',
    ));

    // Chat Dialogues
    chatMessages.add(MessageModel(
      id: 'msg_1',
      conversationId: convId,
      senderId: 'demo_teacher_id',
      content: 'أهلاً بك يا أبو محمد. أحببت أن أبشرك بأن محمد حقق أعلى درجة (98%) في كويز الفيزياء التحريري هذا الأسبوع في مجموعة التميز.',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      senderName: 'أ. أحمد السيد',
      isRead: true,
    ));

    chatMessages.add(MessageModel(
      id: 'msg_2',
      conversationId: convId,
      senderId: 'demo_parent_id',
      content: 'ما شاء الله تبارك الله! هذا فضل من الله ثم بجهودك وحسن شرحك يا أستاذ أحمد. كيف حال مريم أيضاً في مجموعة الرياضيات؟',
      createdAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 30)),
      senderName: 'أبو محمد',
      isRead: true,
    ));

    chatMessages.add(MessageModel(
      id: 'msg_3',
      conversationId: convId,
      senderId: 'demo_teacher_id',
      content: 'مريم ممتازة ومنتظمة جداً وحضورها كامل 100%، وتم اختيارها ضمن الطلاب المميزين في حصة الأربعاء الماضية. مستواهم جميعاً يشرفني!',
      createdAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 15)),
      senderName: 'أ. أحمد السيد',
      isRead: true,
    ));

    chatMessages.add(MessageModel(
      id: 'msg_4',
      conversationId: convId,
      senderId: 'demo_parent_id',
      content: 'وعليكم السلام يا أستاذ، أشكرك جداً على متابعتك الدقيقة وتحفيزك المستمر لهم. سنتر التميز دائماً عند حسن الظن.',
      createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
      senderName: 'أبو محمد',
      isRead: true,
    ));
  }

  void _generateAIConversations() {
    aiConversations.add({
      'id': 'conv_demo_ai_1',
      'teacher_id': 'demo_teacher_id',
      'title': 'تحليل مستوى طلاب مجموعة الفيزياء والتوقعات الامتحانية',
      'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      'last_message_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
    });

    aiMessages.add({
      'id': 'msg_ai_1',
      'session_id': 'conv_demo_ai_1',
      'sender': 'user',
      'message': 'لدي اختبار تجريبي قادم لطلاب الثانوية العامة في الفيزياء، ما هي الأسئلة التي تنصحني بالتركيز عليها بناءً على أداء الطلاب الأسبوعي؟',
      'created_at': DateTime.now().subtract(const Duration(hours: 2, minutes: 10)).toIso8601String(),
    });

    aiMessages.add({
      'id': 'msg_ai_2',
      'session_id': 'conv_demo_ai_1',
      'sender': 'ai',
      'message': '🤖 أهلاً بك يا أستاذ أحمد! بقراءة سجلات الدرجات في مجموعة التميز (65 طالباً)، نلاحظ أن 82% من الطلاب يتقنون مسائل التوصيل على التوالي والتوازي بامتياز، ولكن حوالي 25% واجهوا استغراباً في حل مسائل "المقاومة الداخلية للبطارية عند غلق وفتح الدائرة".\n\n💡 نصيحتي للاختبار القادم:\n1. تضمين مسألتين بمهارات تفضيلية على قانون أوم للدوائر المغلقة.\n2. تصميم سؤال رسم بياني يربط بين فرق الجهد وشده التيار لتثبيت الفهم التفكيكي للمجموعة.\nيمكنني الآن توليد 5 أسئلة نموذجية بالمستوى المطلوب بالضغط على (توليد امتحان بالذكاء الاصطناعي).',
      'created_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
    });

    aiKnowledgeBase.add({
      'id': 'kb_demo_1',
      'center_id': 'center_demo',
      'title': 'موسوعة الفيزياء الحديثة والكلاسيكية للثانوية العامة',
      'file_url': 'https://example.com/physics_encyclopedia.pdf',
      'file_size': 1024 * 1024 * 15, // 15MB
      'created_at': DateTime.now().subtract(const Duration(days: 12)).toIso8601String(),
    });
  }

  // Operations
  void addAttendanceRecord(AttendanceModel record) {
    attendance.removeWhere((a) => a.groupId == record.groupId && a.studentId == record.studentId && 
      a.attendanceDate.year == record.attendanceDate.year && a.attendanceDate.month == record.attendanceDate.month && a.attendanceDate.day == record.attendanceDate.day);
    attendance.add(record);
  }

  void addAssignmentRecord(AssignmentModel record) {
    assignments.insert(0, record);
  }

  void addSubmissionRecord(SubmissionModel record) {
    submissions.add(record);
  }

  void addStudyMaterialRecord(StudyMaterialModel record) {
    studyMaterials.insert(0, record);
  }

  void removeStudyMaterialRecord(String id) {
    studyMaterials.removeWhere((m) => m.id == id);
  }

  void addMessageRecord(MessageModel message) {
    chatMessages.add(message);
  }

  void gradeSubmissionRecord(String id, double score, String feedback, String teacherId) {
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
