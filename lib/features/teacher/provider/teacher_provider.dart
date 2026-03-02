import 'package:flutter/material.dart';
import '../../../shared/models/models.dart';
import '../../../shared/data/supabase_repository.dart';

/// TeacherProvider - يدير حالة المعلم وبياناته
/// يربط المعلم بمجموعاته وطلابه في كل سنتر
class TeacherProvider extends ChangeNotifier {
  final SupabaseRepository _repository;

  // بيانات المعلم
  TeacherModel? _teacherProfile;
  List<CenterModel> _centers = [];
  CenterModel? _selectedCenter;

  // بيانات المجموعات والطلاب
  List<GroupModel> _groups = [];
  List<Map<String, dynamic>> _students = [];
  Map<String, dynamic> _dashboardStats = {};

  // حالة التحميل
  bool _isLoading = false;
  String? _error;

  TeacherProvider(this._repository);

  // ═══════════════════════════════════════════════════════════════════════
  // GETTERS
  // ═══════════════════════════════════════════════════════════════════════

  TeacherModel? get teacherProfile => _teacherProfile;
  List<CenterModel> get centers => _centers;
  CenterModel? get selectedCenter => _selectedCenter;
  List<GroupModel> get groups => _groups;
  List<Map<String, dynamic>> get students => _students;
  Map<String, dynamic> get dashboardStats => _dashboardStats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get hasMultipleCenters => _centers.length > 1;
  String? get selectedCenterId => _selectedCenter?.id;
  String? get teacherId => _teacherProfile?.id;
  String? get teacherUserId => _teacherProfile?.userId;

  // Unified Data Getters (Single Source of Truth)
  int get totalUniqueStudents {
    // Calculate unique students across all loaded groups
    final uniqueIds = <String>{};
    for (var s in _students) {
      if (s['student_id'] != null) uniqueIds.add(s['student_id']);
    }
    return uniqueIds.length;
  }

  int get totalActiveGroups => _groups.length;

  // Stats from dashboard query (cached)
  int get statsTotalStudents =>
      (_dashboardStats['students_count'] as num?)?.toInt() ?? 0;
  int get statsAttendanceRate =>
      (_dashboardStats['attendance_rate'] as num?)?.toInt() ??
      0; // Not in repo?
  int get statsTotalSessions =>
      (_dashboardStats['today_classes_count'] as num?)?.toInt() ?? 0;

  // ═══════════════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════════════

  /// تحميل بيانات المعلم الكاملة
  Future<void> loadTeacherData(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    debugPrint('🔄 [Provider] loadTeacherData: Starting for $userId'); // DEBUG

    try {
      // 1. جلب بيانات المعلم
      _teacherProfile = await _repository.getTeacherByUserId(userId);

      if (_teacherProfile == null) {
        debugPrint('❌ [Provider] Teacher Profile NOT FOUND'); // DEBUG
        _error = 'لم يتم العثور على بيانات المعلم';
        _isLoading = false;
        notifyListeners();
        return;
      }
      debugPrint(
        '✅ [Provider] Profile Loaded: ${_teacherProfile?.id}',
      ); // DEBUG

      // 2. جلب السناتر المسجل فيها
      // ✅ Repository يتولى تجربة الاحتمالات الأربعة تلقائياً:
      //    teacher_user_id=userId → teacher_id=userId
      //    → teacher_id=teacherProfile.id → teacher_user_id=teacherProfile.id
      // راجع teacher_repository_mixin.dart للتفاصيل.
      _centers = await _repository.getTeacherCentersEnrolled(
        userId,
        teacherTableId: _teacherProfile?.id,
      );
      debugPrint('✅ [Provider] Centers Loaded: ${_centers.length}'); // DEBUG

      // 3. اختيار السنتر الأول افتراضياً
      if (_centers.isNotEmpty) {
        debugPrint(
          'ℹ️ [Provider] Auto-selecting first center: ${_centers.first.id}',
        ); // DEBUG
        await selectCenter(_centers.first.id);
      } else {
        debugPrint('⚠️ [Provider] NO CENTERS FOUND to select.'); // DEBUG
      }
    } catch (e) {
      debugPrint('❌ [Provider] loadTeacherData Error: $e'); // DEBUG
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    debugPrint('✅ [Provider] loadTeacherData COMPLETE'); // DEBUG
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CENTER SELECTION
  // ═══════════════════════════════════════════════════════════════════════

  /// اختيار سنتر وتحميل بياناته
  Future<void> selectCenter(String centerId) async {
    debugPrint('🔄 [Provider] selectCenter: $centerId'); // DEBUG
    if (_centers.isEmpty) {
      _selectedCenter = null;
      notifyListeners();
      return;
    }

    _selectedCenter = _centers.firstWhere(
      (c) => c.id == centerId,
      orElse: () => _centers.first,
    );
    debugPrint(
      '✅ [Provider] Center Selected: ${_selectedCenter?.name}',
    ); // DEBUG

    // تحميل بيانات السنتر المحدد
    await _loadCenterData();

    notifyListeners();
  }

  /// تحميل بيانات السنتر (المجموعات، الطلاب، الإحصائيات)
  Future<void> _loadCenterData() async {
    debugPrint('🔄 [Provider] _loadCenterData: START'); // DEBUG
    if (_selectedCenter == null || _teacherProfile == null) {
      debugPrint('⚠️ [Provider] Abort: Center or Profile is null'); // DEBUG
      return;
    }

    try {
      // 🔧 FIX: groups.teacher_id = teachers.id (NOT user_id)
      final teacherId = _teacherProfile!.id;
      final centerId = _selectedCenter!.id;

      debugPrint(
        'ℹ️ [Provider] Fetching data for Teacher=$teacherId, Center=$centerId',
      ); // DEBUG

      // 1. Load Critical Data (Groups & Students)
      try {
        final results = await Future.wait([
          _repository.getTeacherGroups(teacherId, centerId),
          _repository.getTeacherStudents(
            teacherId: teacherId,
            centerId: centerId,
          ),
          // Load Enrollment Data (Financials)
          _repository.getTeacherEnrollment(
            centerId: centerId,
            teacherUserId: _teacherProfile!.userId,
          ),
        ]);

        _groups = results[0] as List<GroupModel>;
        _students = results[1] as List<Map<String, dynamic>>;
        _currentEnrollment = results[2] as TeacherEnrollmentModel?;

        debugPrint(
          '✅ [Provider] Critical Data Loaded: Groups=${_groups.length}, Students=${_students.length}, Enrollment=${_currentEnrollment?.id}',
        );
        notifyListeners(); // Notify immediately so UI shows data
      } catch (e) {
        debugPrint('❌ [Provider] Critical Data Load Failed: $e');
        _error = 'failed_to_load_data';
        return; // Stop if critical data fails
      }

      // 2. Load Non-Critical Data (Stats)
      try {
        debugPrint('ℹ️ [Provider] Loading usage stats...');
        final statsUserId = _teacherProfile?.userId ?? _teacherProfile?.id;

        if (statsUserId != null) {
          _dashboardStats = await _repository.getTeacherDashboardStats(
            teacherId: teacherId,
            teacherUserId: statsUserId,
            centerId: centerId,
          );
          debugPrint('✅ [Provider] Stats Loaded');
        } else {
          debugPrint('⚠️ [Provider] Skipped stats: No User ID found');
        }
      } catch (e) {
        debugPrint('⚠️ [Provider] Stats Load Failed (Non-fatal): $e');
        // Do not fail the whole process
      }
    } catch (e) {
      debugPrint('❌ [Provider] _loadCenterData General Error: $e'); // DEBUG
      _error = e.toString();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DATA ACCESS
  // ═══════════════════════════════════════════════════════════════════════

  /// Current Enrollment Data (Financials)
  TeacherEnrollmentModel? _currentEnrollment;
  TeacherEnrollmentModel? get currentEnrollment => _currentEnrollment;

  /// Calculate Financials for a Group
  Map<String, double> calculateGroupFinancials(GroupModel group) {
    if (_currentEnrollment == null) {
      return {'total_income': 0, 'center_share': 0, 'teacher_share': 0};
    }

    final studentCount = group.currentStudents;
    final monthlyFee = group.monthlyFee ?? 0;
    final totalIncome = studentCount * monthlyFee;

    double teacherShare = 0;
    double centerShare = 0;

    if (_currentEnrollment!.salaryType == 'percentage') {
      final percentage = _currentEnrollment!.salaryAmount ?? 0;
      teacherShare = totalIncome * (percentage / 100);
      centerShare = totalIncome - teacherShare;
    } else if (_currentEnrollment!.salaryType == 'fixed') {
      // Fixed salary is usually per month total, not per group.
      // But if we want to attribute a portion to this group, we could divide by total groups.
      // For now, let's assume fixed salary means we can't calculate per-group share easily
      // unless we know the 'total' fixed amount.
      // Alternatively, maybe 'fixed' here means fixed amount per student?
      // Let's assume standard 'percentage' mostly.
      // If fixed, we just return 0 share for now or treat as 100% center?
      // Let's assume standard behavior:
      teacherShare = 0; // It's a fixed monthly salary, not per group revenue
      centerShare = totalIncome;
    }

    return {
      'total_income': totalIncome,
      'center_share': centerShare,
      'teacher_share': teacherShare,
    };
  }

  /// إجمالي الدخل المتوقع من جميع المجموعات
  double get totalProjectedIncome {
    double total = 0;
    if (_groups.isNotEmpty) {
      for (final group in _groups) {
        total += calculateGroupFinancials(group)['teacher_share'] ?? 0;
      }
    }
    // If fixed salary, add it once (simplified logic)
    if (_currentEnrollment?.salaryType == 'fixed') {
      total += _currentEnrollment!.salaryAmount ?? 0;
    }
    return total;
  }

  /// جلب طلاب مجموعة معينة
  List<Map<String, dynamic>> getStudentsForGroup(String groupId) {
    return _students.where((s) => s['group_id'] == groupId).toList();
  }

  /// عدد الطلاب في مجموعة
  int getStudentCountForGroup(String groupId) {
    return _students.where((s) => s['group_id'] == groupId).length;
  }

  /// جلب جدول اليوم
  Future<List<ScheduleItem>> getTodaySchedule() async {
    if (_selectedCenter == null || _teacherProfile == null) return [];

    final today = DateTime.now();
    final dayNames = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    final dayOfWeek = dayNames[today.weekday % 7];

    // 🔧 FIX: Use teachers.id for schedule query
    return await _repository.getTeacherSchedule(
      teacherId: _teacherProfile!.id,
      centerId: _selectedCenter!.id,
      dayOfWeek: dayOfWeek,
    );
  }

  /// جلب الجدول الأسبوعي
  Future<List<ScheduleItem>> getWeeklySchedule() async {
    if (_selectedCenter == null || _teacherProfile == null) return [];

    // 🔧 FIX: Use teachers.id for schedule query
    return await _repository.getTeacherSchedule(
      teacherId: _teacherProfile!.id,
      centerId: _selectedCenter!.id,
    );
  }

  /// بدء جلسة حضور
  Future<Map<String, dynamic>> startAttendanceSession(String groupId) async {
    if (_selectedCenter == null) {
      return {'success': false, 'message': 'لم يتم اختيار سنتر'};
    }

    try {
      return await _repository.startAttendanceSession(
        groupId: groupId,
        centerId: _selectedCenter!.id,
      );
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// حفظ الحضور
  Future<bool> saveAttendance({
    required String groupId,
    required String sessionId,
    required List<Map<String, dynamic>> attendanceList,
  }) async {
    if (_selectedCenter == null) return false;

    try {
      await _repository.saveAttendanceBulk(
        centerId: _selectedCenter!.id,
        groupId: groupId,
        sessionId: sessionId,
        attendanceList: attendanceList,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  /// جلب الراتب
  Future<Map<String, dynamic>> getSalaryBreakdown({
    required int month,
    required int year,
  }) async {
    if (_selectedCenter == null || _teacherProfile == null) return {};

    try {
      return await _repository.getTeacherSalaryBreakdown(
        teacherId: _teacherProfile!.id,
        centerId: _selectedCenter!.id,
        month: month,
        year: year,
      );
    } catch (e) {
      _error = e.toString();
      return {};
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // REFRESH & CLEAR
  // ═══════════════════════════════════════════════════════════════════════

  /// تحديث البيانات
  /// يقوم بتحديث بيانات السنتر الحالي إذا كان محدداً، وإلا يعيد تحميل كل شيء
  Future<void> refreshData() async {
    if (_selectedCenter != null) {
      debugPrint(
        '🔄 [Provider] refreshData: Refreshing current center data...',
      );
      await _loadCenterData();
    } else {
      debugPrint('🔄 [Provider] refreshData: Full reload...');
      await refresh();
    }
  }

  Future<void> refresh() async {
    if (_teacherProfile?.userId != null) {
      await loadTeacherData(_teacherProfile!.userId);
    }
  }

  /// مسح البيانات (عند تسجيل الخروج)
  void clear() {
    _teacherProfile = null;
    _centers = [];
    _selectedCenter = null;
    _groups = [];
    _students = [];
    _dashboardStats = {};
    _error = null;
    notifyListeners();
  }

  /// مسح الخطأ
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
