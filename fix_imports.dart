import 'dart:io';

void main() async {
  final dir = Directory('lib');
  final files = await dir.list(recursive: true).where((e) => e is File && e.path.endsWith('.dart')).toList();

  final replacements = {
    'assignments/create_assignment_screen.dart': 'assignments/screens/create_assignment_screen.dart',
    'assignments/grading_review_screen.dart': 'assignments/screens/grading_review_screen.dart',
    'assignments/submissions_screen.dart': 'assignments/screens/submissions_screen.dart',
    'assignments/teacher_assignments_screen.dart': 'assignments/screens/teacher_assignments_screen.dart',
    
    'attendance/teacher_attendance_screen.dart': 'attendance/screens/teacher_attendance_screen.dart',
    'attendance/parent_attendance_screen.dart': 'attendance/screens/parent_attendance_screen.dart',
    
    'curriculum/curriculum_management_screen.dart': 'curriculum/screens/curriculum_management_screen.dart',
    'curriculum/subject_detail_management_screen.dart': 'curriculum/screens/subject_detail_management_screen.dart',
    
    'dashboard/parent_home_screen.dart': 'dashboard/screens/parent_home_screen.dart',
    'dashboard/teacher_home_screen.dart': 'dashboard/screens/teacher_home_screen.dart',
    
    'enrollment/smart_enrollment_screen.dart': 'enrollment/screens/smart_enrollment_screen.dart',
    
    'grades/parent_grades_screen.dart': 'grades/screens/parent_grades_screen.dart',
    
    'groups/teacher_group_details_screen.dart': 'groups/screens/teacher_group_details_screen.dart',
    'screens/groups/teacher_groups_screen.dart': 'groups/screens/teacher_groups_screen.dart',
    'groups/teacher_groups_screen.dart': 'groups/screens/teacher_groups_screen.dart',

    'materials/teacher_materials_screen.dart': 'materials/screens/teacher_materials_screen.dart',
    
    'messages/teacher_chat_screen.dart': 'messages/screens/teacher_chat_screen.dart',
    'messages/teacher_messages_screen.dart': 'messages/screens/teacher_messages_screen.dart',
    'messages/teacher_new_chat_screen.dart': 'messages/screens/teacher_new_chat_screen.dart',
    'messages/parent_chat_screen.dart': 'messages/screens/parent_chat_screen.dart',
    'messages/parent_messages_screen.dart': 'messages/screens/parent_messages_screen.dart',
    'messages/parent_new_chat_screen.dart': 'messages/screens/parent_new_chat_screen.dart',
    
    'payments/parent_payments_screen.dart': 'payments/screens/parent_payments_screen.dart',
    'payments/teacher_payments_screen.dart': 'payments/screens/teacher_payments_screen.dart',
    
    'profile/parent_profile_screen.dart': 'profile/screens/parent_profile_screen.dart',
    'profile/teacher_profile_screen.dart': 'profile/screens/teacher_profile_screen.dart',
    
    'reports/teacher_reports_screen.dart': 'reports/screens/teacher_reports_screen.dart',
    
    'schedule/parent_schedule_screen.dart': 'schedule/screens/parent_schedule_screen.dart',
    'schedule/teacher_schedule_screen.dart': 'schedule/screens/teacher_schedule_screen.dart',
    
    'students/add_student_screen.dart': 'students/screens/add_student_screen.dart',
    'students/teacher_students_screen.dart': 'students/screens/teacher_students_screen.dart',
  };

  print('Fixing imports...');
  int fixedCount = 0;

  for (final file in files) {
    if (file is! File) continue;
    String content = await file.readAsString();
    bool updated = false;

    replacements.forEach((key, value) {
      if (content.contains(key)) {
        content = content.replaceAll(key, value);
        updated = true;
      }
    });

    if (updated) {
      await file.writeAsString(content);
      print('Fixed imports in: ${file.path}');
      fixedCount++;
    }
  }

  print('Done fixing $fixedCount files.');
}
