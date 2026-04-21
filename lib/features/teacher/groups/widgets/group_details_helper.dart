import '../../../../shared/models/models.dart';

/// Shared helper utilities for group details screen.
class GroupDetailsHelper {
  static String translateDay(String dayEnglish) {
    const days = {
      'saturday': 'السبت',
      'sunday': 'الأحد',
      'monday': 'الاثنين',
      'tuesday': 'الثلاثاء',
      'wednesday': 'الأربعاء',
      'thursday': 'الخميس',
      'friday': 'الجمعة',
    };
    return days[dayEnglish.toLowerCase()] ?? dayEnglish;
  }

  static String getFieldDayName(int? dayIndex) {
    if (dayIndex == null) return '-';
    const days = [
      'السبت',
      'الأحد',
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
    ];
    if (dayIndex < 0 || dayIndex > 6) return '-';
    return days[dayIndex];
  }

  static String buildScheduleSummary(GroupModel group) {
    if (group.schedules.isEmpty) {
      if (group.dayOfWeek != null && (group.startTime?.isNotEmpty == true)) {
        return '${getFieldDayName(group.dayOfWeek)} • ${group.startTime}';
      }
      return 'لا توجد مواعيد';
    }

    final first = group.schedules.first;
    final day = translateDay(first.dayOfWeek);
    final time = first.startTime;
    return '$day • $time';
  }

  static bool isClassActive(GroupModel? group) {
    if (group == null || group.schedules.isEmpty) return false;

    final now = DateTime.now();
    int parseTimeToMinutes(String time) {
      if (time.isEmpty) return -1;
      final trimmed = time.trim();
      final parts = trimmed.split(' ');
      final hhmm = parts.first;
      final ampm = parts.length > 1 ? parts[1].toLowerCase() : null;
      final hhmmParts = hhmm.split(':');
      if (hhmmParts.length < 2) return -1;
      final hour = int.tryParse(hhmmParts[0]);
      final minute = int.tryParse(hhmmParts[1]);
      if (hour == null || minute == null) return -1;

      var h = hour;
      if (ampm == 'pm' && h < 12) h += 12;
      if (ampm == 'am' && h == 12) h = 0;
      return (h * 60) + minute;
    }

    final currentTimeMinutes = now.hour * 60 + now.minute;
    final dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final todayName = dayNames[now.weekday - 1];

    return group.schedules.any((s) {
      if (s.dayOfWeek.toLowerCase() != todayName.toLowerCase()) return false;

      final startMinutes = parseTimeToMinutes(s.startTime);
      if (startMinutes < 0) return false;
      final endMinutes = s.endTime.isNotEmpty
          ? parseTimeToMinutes(s.endTime)
          : startMinutes + 60;

      return currentTimeMinutes >= (startMinutes - 30) &&
          currentTimeMinutes <= (endMinutes + 30);
    });
  }
}
