import 'package:flutter/material.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/data/supabase_repository.dart';

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
  DateTime? _lastFetchTime;

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
      (_dashboardStats['attendance_rate'] as num?)?.toInt() ?? 0;
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

    log.debug('loadTeacherData: Starting for $userId', tag: 'TeacherProvider');

    try {
      _teacherProfile = await _repository.getTeacherByUserId(userId);

      if (_teacherProfile == null) {
        log.warning('Teacher profile NOT FOUND', tag: 'TeacherProvider');
        _error = 'لم يتم العثور على بيانات المعلم';
        _isLoading = false;
        notifyListeners();
        return;
      }
      log.debug(
        'Profile loaded: ${_teacherProfile?.id}',
        tag: 'TeacherProvider',
      );

      // NOTE: Repository يتولى تجربة الاحتمالات الأربعة تلقائياً
      // راجع teacher_repository_mixin.dart للتفاصيل.
      _centers = await _repository.getTeacherCentersEnrolled(
        userId,
        teacherTableId: _teacherProfile?.id,
      );
      log.debug('Centers loaded: ${_centers.length}', tag: 'TeacherProvider');

      if (_centers.isNotEmpty) {
        await selectCenter(_centers.first.id);
      } else {
        log.warning('No centers found', tag: 'TeacherProvider');
      }
    } catch (e) {
      log.error('loadTeacherData failed', tag: 'TeacherProvider', error: e);
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CENTER SELECTION
  // ═══════════════════════════════════════════════════════════════════════

  /// اختيار سنتر وتحميل بياناته
  Future<void> selectCenter(String centerId) async {
    if (_centers.isEmpty) {
      _selectedCenter = null;
      notifyListeners();
      return;
    }

    _selectedCenter = _centers.firstWhere(
      (c) => c.id == centerId,
      orElse: () => _centers.first,
    );
    log.debug(
      'Center selected: ${_selectedCenter?.name}',
      tag: 'TeacherProvider',
    );

    await _loadCenterData();
    notifyListeners();
  }

  /// تحميل بيانات السنتر (المجموعات، الطلاب، الإحصائيات)
  /// NOTE: Optimized load order — groups first, then everything else in parallel.
  Future<void> _loadCenterData({bool forceRefresh = false}) async {
    if (_selectedCenter == null || _teacherProfile == null) return;

    if (!forceRefresh && _lastFetchTime != null) {
      final diff = DateTime.now().difference(_lastFetchTime!);
      if (diff.inMinutes < 3) {
        log.debug('Data is fresh (${diff.inSeconds}s old). Bypassing network fetch.', tag: 'TeacherProvider');
        return;
      }
    }

    try {
      final teacherId = _teacherProfile!.id;
      final centerId = _selectedCenter!.id;
      final teacherUserId = _teacherProfile!.userId;

      // 1. Load Groups first (needed by students query)
      try {
        _groups = await _repository.getTeacherGroups(teacherId, centerId);
        log.debug(
          'Groups loaded: ${_groups.length}',
          tag: 'TeacherProvider',
        );
        notifyListeners();
      } catch (e) {
        log.error('Groups load failed', tag: 'TeacherProvider', error: e);
        _error = 'failed_to_load_data';
        return;
      }

      // 2. Load Students + Enrollment + Stats ALL in parallel
      // NOTE: Students uses preloaded groups to avoid duplicate getTeacherGroups call
      try {
        final results = await Future.wait([
          _repository.getTeacherStudents(
            teacherId: teacherId,
            centerId: centerId,
            preloadedGroups: _groups,
          ),
          _repository.getTeacherEnrollment(
            centerId: centerId,
            teacherUserId: teacherUserId,
            teacherTableId: teacherId,
          ),
          _repository.getTeacherDashboardStats(
            teacherId: teacherId,
            teacherUserId: teacherUserId,
            centerId: centerId,
          ),
        ]);

        _students = results[0] as List<Map<String, dynamic>>;
        _currentEnrollment = results[1] as TeacherEnrollmentModel?;
        _dashboardStats = results[2] as Map<String, dynamic>;

        _lastFetchTime = DateTime.now();

        log.debug(
          'All data loaded: Students=${_students.length}, Stats=$_dashboardStats',
          tag: 'TeacherProvider',
        );
        notifyListeners();
      } catch (e) {
        log.error('Data load failed', tag: 'TeacherProvider', error: e);
        // NOTE: Non-fatal — UI can still work with groups data
        log.warning('Partial data load, continuing...', tag: 'TeacherProvider');
      }
    } catch (e) {
      log.error('_loadCenterData failed', tag: 'TeacherProvider', error: e);
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
      teacherShare = 0;
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
    // NOTE: If fixed salary, add it once (the looped calculation returns 0)
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
      'Sunday', 'Monday', 'Tuesday', 'Wednesday',
      'Thursday', 'Friday', 'Saturday',
    ];
    final dayOfWeek = dayNames[today.weekday % 7];

    return await _repository.getTeacherSchedule(
      teacherId: _teacherProfile!.id,
      centerId: _selectedCenter!.id,
      dayOfWeek: dayOfWeek,
    );
  }

  /// جلب الجدول الأسبوعي
  Future<List<ScheduleItem>> getWeeklySchedule() async {
    if (_selectedCenter == null || _teacherProfile == null) return [];

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
  Future<void> refreshData({bool forceRefresh = true}) async {
    if (_selectedCenter != null) {
      await _loadCenterData(forceRefresh: forceRefresh);
    } else {
      await refresh();
    }
  }

  Future<void> refresh() async {
    _lastFetchTime = null; // Clear cache on manual hard refresh
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
    _lastFetchTime = null;
    notifyListeners();
  }

  /// مسح الخطأ
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
