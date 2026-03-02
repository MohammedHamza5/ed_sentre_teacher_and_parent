/// User roles in the EdSentre system
enum UserRole {
  owner,
  manager,
  secretary,
  teacher,
  student,
  parent,
  centerAdmin,
  reception,
  accountant,
  supervisor,
  superAdmin;

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return UserRole.owner;
      case 'manager':
        return UserRole.manager;
      case 'secretary':
        return UserRole.secretary;
      case 'teacher':
        return UserRole.teacher;
      case 'student':
        return UserRole.student;
      case 'parent':
        return UserRole.parent;
      case 'center_admin':
        return UserRole.centerAdmin;
      case 'reception':
        return UserRole.reception;
      case 'accountant':
        return UserRole.accountant;
      case 'supervisor':
        return UserRole.supervisor;
      case 'super_admin':
        return UserRole.superAdmin;
      default:
        return UserRole.student;
    }
  }

  String toJson() {
    switch (this) {
      case UserRole.centerAdmin:
        return 'center_admin';
      case UserRole.superAdmin:
        return 'super_admin';
      default:
        return name;
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.owner:
        return 'المالك';
      case UserRole.manager:
        return 'المدير';
      case UserRole.secretary:
        return 'السكرتارية';
      case UserRole.teacher:
        return 'المعلم';
      case UserRole.student:
        return 'الطالب';
      case UserRole.parent:
        return 'ولي الأمر';
      case UserRole.centerAdmin:
        return 'مدير السنتر';
      case UserRole.reception:
        return 'الاستقبال';
      case UserRole.accountant:
        return 'المحاسب';
      case UserRole.supervisor:
        return 'المشرف';
      case UserRole.superAdmin:
        return 'سوبر أدمن';
    }
  }
}

/// Attendance status enum
enum AttendanceStatus {
  present,
  absent,
  late,
  excused;

  static AttendanceStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return AttendanceStatus.present;
      case 'absent':
        return AttendanceStatus.absent;
      case 'late':
        return AttendanceStatus.late;
      case 'excused':
        return AttendanceStatus.excused;
      default:
        return AttendanceStatus.absent;
    }
  }

  String get displayName {
    switch (this) {
      case AttendanceStatus.present:
        return 'حاضر';
      case AttendanceStatus.absent:
        return 'غائب';
      case AttendanceStatus.late:
        return 'متأخر';
      case AttendanceStatus.excused:
        return 'معذور';
    }
  }
}

/// Payment status enum
enum PaymentStatus {
  pending,
  partial,
  paid,
  overdue,
  cancelled;

  static PaymentStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return PaymentStatus.pending;
      case 'partial':
        return PaymentStatus.partial;
      case 'paid':
        return PaymentStatus.paid;
      case 'overdue':
        return PaymentStatus.overdue;
      case 'cancelled':
        return PaymentStatus.cancelled;
      default:
        return PaymentStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'معلق';
      case PaymentStatus.partial:
        return 'مدفوع جزئياً';
      case PaymentStatus.paid:
        return 'مدفوع';
      case PaymentStatus.overdue:
        return 'متأخر';
      case PaymentStatus.cancelled:
        return 'ملغي';
    }
  }
}

/// Enrollment status enum
enum EnrollmentStatus {
  active,
  withdrawn,
  transferred,
  suspended,
  pending,
  accepted,
  rejected;

  static EnrollmentStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return EnrollmentStatus.active;
      case 'withdrawn':
        return EnrollmentStatus.withdrawn;
      case 'transferred':
        return EnrollmentStatus.transferred;
      case 'suspended':
        return EnrollmentStatus.suspended;
      case 'pending':
        return EnrollmentStatus.pending;
      case 'accepted':
        return EnrollmentStatus.accepted;
      case 'rejected':
        return EnrollmentStatus.rejected;
      default:
        return EnrollmentStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case EnrollmentStatus.active:
        return 'نشط';
      case EnrollmentStatus.withdrawn:
        return 'منسحب';
      case EnrollmentStatus.transferred:
        return 'محول';
      case EnrollmentStatus.suspended:
        return 'موقوف';
      case EnrollmentStatus.pending:
        return 'معلق';
      case EnrollmentStatus.accepted:
        return 'مقبول';
      case EnrollmentStatus.rejected:
        return 'مرفوض';
    }
  }
}

/// Assignment submission status
enum AssignmentStatus {
  pending,
  submitted,
  graded;

  String get displayName {
    switch (this) {
      case AssignmentStatus.pending:
        return 'معلق';
      case AssignmentStatus.submitted:
        return 'مسلّم';
      case AssignmentStatus.graded:
        return 'مُصحح';
    }
  }
}

/// Exam type enum
enum ExamType {
  midterm,
  final_,
  quiz,
  assignment,
  project,
  participation;

  static ExamType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'midterm':
        return ExamType.midterm;
      case 'final':
        return ExamType.final_;
      case 'quiz':
        return ExamType.quiz;
      case 'assignment':
        return ExamType.assignment;
      case 'project':
        return ExamType.project;
      case 'participation':
        return ExamType.participation;
      default:
        return ExamType.quiz;
    }
  }

  String get displayName {
    switch (this) {
      case ExamType.midterm:
        return 'نصف السنة';
      case ExamType.final_:
        return 'نهائي';
      case ExamType.quiz:
        return 'كويز';
      case ExamType.assignment:
        return 'واجب';
      case ExamType.project:
        return 'مشروع';
      case ExamType.participation:
        return 'مشاركة';
    }
  }
}

/// Day of week enum
enum DayOfWeek {
  saturday(0, 'السبت', 'Saturday'),
  sunday(1, 'الأحد', 'Sunday'),
  monday(2, 'الاثنين', 'Monday'),
  tuesday(3, 'الثلاثاء', 'Tuesday'),
  wednesday(4, 'الأربعاء', 'Wednesday'),
  thursday(5, 'الخميس', 'Thursday'),
  friday(6, 'الجمعة', 'Friday');

  final int value;
  final String arabicName;
  final String englishName;

  const DayOfWeek(this.value, this.arabicName, this.englishName);

  static DayOfWeek fromInt(int day) {
    return DayOfWeek.values.firstWhere(
      (d) => d.value == day,
      orElse: () => DayOfWeek.saturday,
    );
  }

  static DayOfWeek fromString(String day) {
    return DayOfWeek.values.firstWhere(
      (d) => d.englishName.toLowerCase() == day.toLowerCase(),
      orElse: () => DayOfWeek.saturday,
    );
  }
}

/// Message type enum
enum MessageType {
  text,
  image,
  file;

  static MessageType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'image':
        return MessageType.image;
      case 'file':
        return MessageType.file;
      default:
        return MessageType.text;
    }
  }
}

/// Parent relationship type
enum ParentRelationship {
  father,
  mother,
  guardian,
  other;

  static ParentRelationship fromString(String relationship) {
    switch (relationship.toLowerCase()) {
      case 'father':
        return ParentRelationship.father;
      case 'mother':
        return ParentRelationship.mother;
      case 'guardian':
        return ParentRelationship.guardian;
      default:
        return ParentRelationship.other;
    }
  }

  String get displayName {
    switch (this) {
      case ParentRelationship.father:
        return 'الأب';
      case ParentRelationship.mother:
        return 'الأم';
      case ParentRelationship.guardian:
        return 'الوصي';
      case ParentRelationship.other:
        return 'آخر';
    }
  }
}
