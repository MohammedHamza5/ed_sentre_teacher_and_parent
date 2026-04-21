import 'dart:convert';

class AssignmentHelper {
  static Map<String, dynamic> extractSettingsMap(Map<String, dynamic> assignment) {
    final settings = assignment['settings'];
    if (settings is Map) {
      return Map<String, dynamic>.from(settings);
    }
    if (settings is String) {
      try {
        return Map<String, dynamic>.from(jsonDecode(settings) as Map);
      } catch (_) {}
    }
    return {};
  }

  static DateTime? getPublishDate(Map<String, dynamic> assignment) {
    final settings = extractSettingsMap(assignment);
    final publishAt = settings['publish_at'];
    if (publishAt is String) {
      return DateTime.tryParse(publishAt);
    }
    return null;
  }

  static bool isArchived(Map<String, dynamic> assignment) {
    final settings = extractSettingsMap(assignment);
    return settings['archived'] == true;
  }

  static Object buildSettingsPayload(
    Map<String, dynamic> assignment,
    Map<String, dynamic> settings,
  ) {
    final original = assignment['settings'];
    if (original is String) {
      return jsonEncode(settings);
    }
    return settings;
  }
}
