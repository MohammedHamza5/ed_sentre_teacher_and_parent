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
      final id = s['student_id'] ?? s['id'] ?? s['user_id'] ?? s['student_user_id'];
      if (id != null) uniqueIds.add(id.toString());
    }
    if (uniqueIds.isNotEmpty) return uniqueIds.length;
    return statsTotalStudents;
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
  Future<void> loadTeacherData([String? userId]) async {
    final effectiveUserId =
        userId ?? _teacherProfile?.userId ?? _repository.client.auth.currentUser?.id;

    if (effectiveUserId == null) {
      debugPrint('⚠️ [TeacherProvider] loadTeacherData: No user ID and no active auth session');
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    debugPrint('🚀 [TeacherProvider] loadTeacherData started for userId: $effectiveUserId');

    try {
      _teacherProfile = await _repository.getTeacherByUserId(effectiveUserId);
      debugPrint('   👉 Teacher Profile: id=${_teacherProfile?.id}, name=${_teacherProfile?.fullName}');

      if (_teacherProfile == null) {
        debugPrint('   ❌ Teacher profile NOT FOUND in DB for userId: $effectiveUserId');
        _error = 'لم يتم العثور على بيانات المعلم';
        _isLoading = false;
        notifyListeners();
        return;
      }

      _centers = await _repository.getTeacherCentersEnrolled(
        effectiveUserId,
        teacherTableId: _teacherProfile?.id,
      );
      debugPrint('   👉 Centers Loaded (${_centers.length}): ${_centers.map((c) => "${c.name} (${c.id})").toList()}');

      if (_centers.isNotEmpty) {
        await selectCenter(_centers.first.id);
      } else {
        debugPrint('   ⚠️ No centers found for this teacher');
      }
    } catch (e, st) {
      debugPrint('❌ [TeacherProvider] loadTeacherData failed: $e\n$st');
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
    debugPrint('🏢 [TeacherProvider] Center selected: ${_selectedCenter?.name} (${_selectedCenter?.id})');

    await _loadCenterData(forceRefresh: true);
    notifyListeners();
  }

  /// تحميل بيانات السنتر (المجموعات، الطلاب، الإحصائيات)
  Future<void> _loadCenterData({bool forceRefresh = false}) async {
    if (_selectedCenter == null || _teacherProfile == null) {
      debugPrint('⚠️ [TeacherProvider] _loadCenterData aborted: selectedCenter=$_selectedCenter, teacherProfile=$_teacherProfile');
      return;
    }

    if (!forceRefresh && _lastFetchTime != null && _groups.isNotEmpty) {
      final diff = DateTime.now().difference(_lastFetchTime!);
      if (diff.inMinutes < 3) {
        debugPrint('⏱️ [TeacherProvider] Data is fresh (${diff.inSeconds}s old). Bypassing fetch.');
        return;
      }
    }

    try {
      final teacherId = _teacherProfile!.id;
      final centerId = _selectedCenter!.id;
      final teacherUserId = _teacherProfile!.userId;

      debugPrint('🔄 [TeacherProvider] _loadCenterData fetching for teacherId: $teacherId, centerId: $centerId');

      // 1. Load Groups first (needed by students query)
      try {
        _groups = await _repository.getTeacherGroups(teacherId, centerId);
        debugPrint('   👉 Groups in Provider: ${_groups.length}');
        notifyListeners();
      } catch (e, st) {
        debugPrint('❌ [TeacherProvider] Groups load failed: $e\n$st');
        _error = 'failed_to_load_data';
        return;
      }

      // 2. Load Students + Enrollment + Stats ALL in parallel
      // NOTE: Students uses preloaded groups to avoid duplicate getTeacherGroups call
      try {
        final now = DateTime.now();
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
          _repository.getTeacherSalaryBreakdown(
            teacherId: teacherId,
            centerId: centerId,
            month: now.month,
            year: now.year,
          ),
        ]);

        _students = results[0] as List<Map<String, dynamic>>;
        _currentEnrollment = results[1] as TeacherEnrollmentModel?;
        _dashboardStats = results[2] as Map<String, dynamic>;
        _salaryData = results[3] as Map<String, dynamic>;
        
        _actualCollectedPerGroup.clear();
        final salaryType = _salaryData!['salary_type'] ?? 'fixed';
        final items = (salaryType == 'percentage' || salaryType == 'independent')
            ? (_salaryData!['percentage_items'] as List? ?? [])
            : salaryType == 'per_session'
                ? (_salaryData!['sessions'] as List? ?? [])
                : [];
                
        for (var item in items) {
          final groupId = item['group_id'] as String?;
          final groupName = item['group'] as String?;
          final collected = (item['collected'] as num?)?.toDouble() ?? 0.0;
          
          if (groupId != null) {
            _actualCollectedPerGroup[groupId] = collected;
          } else if (groupName != null) {
            final matchedGroup = _groups.where((g) => g.groupName == groupName).firstOrNull;
            if (matchedGroup != null) {
              _actualCollectedPerGroup[matchedGroup.id] = collected;
            }
          }
        }

        // Synchronize each group's student count with the actual active student enrollments
        if (_groups.isNotEmpty && _students.isNotEmpty) {
          _groups = _groups.map((group) {
            final actualCount = _students.where((s) => s['group_id'] == group.id).length;
            return group.copyWith(currentStudents: actualCount);
          }).toList();
        }

        _lastFetchTime = DateTime.now();

        log.debug(
          'All data loaded: Students=${_students.length}, Stats=$_dashboardStats',
          tag: 'TeacherProvider',
        );
        notifyListeners();
      } catch (e, st) {
        log.error('Data load failed: $e', tag: 'TeacherProvider', error: e, stackTrace: st);
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
  
  Map<String, dynamic>? _salaryData;
  Map<String, dynamic>? get salaryData => _salaryData;
  
  Map<String, double> _actualCollectedPerGroup = {};
  Map<String, double> get actualCollectedPerGroup => _actualCollectedPerGroup;

  /// Calculate Financials for a Group (Projected vs Actual)
  Map<String, double> calculateGroupFinancials(GroupModel group, {bool isIndependent = false}) {
    // Dynamic student count fallback: check provider's students list if group.currentStudents is 0
    final dynamicStudentCount = group.currentStudents > 0 
        ? group.currentStudents 
        : getStudentCountForGroup(group.id);
    final monthlyFee = group.monthlyFee ?? 0;
    
    // Projected
    final projectedTotalIncome = dynamicStudentCount * monthlyFee;
    double projectedTeacherShare = 0;
    double projectedCenterShare = 0;
    
    // Actual
    final actualTotalIncome = _actualCollectedPerGroup[group.id] ?? 0.0;
    double actualTeacherShare = 0;
    double actualCenterShare = 0;

    if (isIndependent || _currentEnrollment == null || _currentEnrollment!.salaryType == 'independent') {
      projectedTeacherShare = projectedTotalIncome;
      projectedCenterShare = 0;
      
      actualTeacherShare = actualTotalIncome;
      actualCenterShare = 0;
    } else if (_currentEnrollment!.salaryType == 'percentage') {
      final percentage = _currentEnrollment!.salaryAmount ?? 0;
      projectedTeacherShare = projectedTotalIncome * (percentage / 100);
      projectedCenterShare = projectedTotalIncome - projectedTeacherShare;
      
      actualTeacherShare = actualTotalIncome * (percentage / 100);
      actualCenterShare = actualTotalIncome - actualTeacherShare;
    } else if (_currentEnrollment!.salaryType == 'fixed') {
      projectedTeacherShare = 0;
      projectedCenterShare = projectedTotalIncome;
      
      actualTeacherShare = 0;
      actualCenterShare = actualTotalIncome;
    }

    final result = {
      // Projected
      'total_income': projectedTotalIncome,
      'center_share': projectedCenterShare,
      'teacher_share': projectedTeacherShare,
      // Actual
      'actual_total': actualTotalIncome,
      'actual_teacher_share': actualTeacherShare,
      'actual_center_share': actualCenterShare,
    };
    
    debugPrint('💰 [Financials] Group ${group.groupName}: '
        'Students=$dynamicStudentCount, Fee=$monthlyFee, '
        'ProjectedTeacherShare=$projectedTeacherShare, '
        'ActualTeacherShare=$actualTeacherShare');

    return result;
  }

  /// إجمالي الدخل المتوقع من جميع المجموعات
  double totalProjectedIncome({bool isIndependent = false}) {
    double total = 0;
    if (_groups.isNotEmpty) {
      for (final group in _groups) {
        total += calculateGroupFinancials(group, isIndependent: isIndependent)['teacher_share'] ?? 0;
      }
    }
    // NOTE: If fixed salary, add it once (the looped calculation returns 0)
    if (_currentEnrollment?.salaryType == 'fixed' && !isIndependent) {
      total += _currentEnrollment!.salaryAmount ?? 0;
    }
    
    return total;
  }
  
  /// إجمالي الدخل المحصل فعلياً
  double totalActualIncome({bool isIndependent = false}) {
    double total = 0;
    if (_groups.isNotEmpty) {
      for (final group in _groups) {
        total += calculateGroupFinancials(group, isIndependent: isIndependent)['actual_teacher_share'] ?? 0;
      }
    }
    // NOTE: For fixed salary, the actual collected doesn't affect the fixed salary amount directly,
    // but the center usually pays it at the end of the month. We can return 0 or the fixed amount.
    // For a teacher, their "actual" fixed salary is determined by payment transfers, not student payments.
    if (_currentEnrollment?.salaryType == 'fixed' && !isIndependent) {
      // Here we might just return the fixed salary as projected, but "actual" means what's in their pocket.
      // For now, we will return 0 since we track student payments, not teacher salaries.
      total += 0;
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
