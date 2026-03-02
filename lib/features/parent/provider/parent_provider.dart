import 'package:flutter/material.dart';
import '../../../shared/models/models.dart';
import '../../../shared/data/supabase_repository.dart';

/// ParentProvider - Manages parent-specific functionality
/// Handles child selection and center management for parent users
class ParentProvider extends ChangeNotifier {
  final SupabaseRepository _repository;

  List<StudentModel> _children = [];
  StudentModel? _selectedChild;
  List<ChildCenterInfo> _childCenters = [];
  ChildCenterInfo? _selectedCenter;
  bool _isLoading = false;
  String? _error;

  ParentProvider(this._repository);

  // Getters
  List<StudentModel> get children => _children;
  StudentModel? get selectedChild => _selectedChild;
  List<ChildCenterInfo> get childCenters => _childCenters;
  ChildCenterInfo? get selectedCenter => _selectedCenter;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMultipleChildren => _children.length > 1;
  bool get hasMultipleCenters => _childCenters.length > 1;
  String? get selectedChildId => _selectedChild?.id;
  String? get selectedCenterId => _selectedCenter?.centerId;

  /// Load parent's children
  Future<void> loadChildren(String parentUserId) async {
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('👨‍👩‍👧 [ParentProvider] loadChildren START');
    debugPrint('   📥 parentUserId: $parentUserId');
    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      _children = await _repository.getParentChildren(parentUserId);
      debugPrint('   ✅ Children loaded: ${_children.length}');
      for (var child in _children) {
        debugPrint(
          '      👧 ${child.fullName} (id: ${child.id}, userId: ${child.userId})',
        );
      }

      if (_children.isNotEmpty) {
        debugPrint('   📌 Selecting first child: ${_children.first.fullName}');
        await selectChild(_children.first.id);
      } else {
        debugPrint('   ⚠️ No children found!');
      }
    } catch (e, stack) {
      _error = e.toString();
      debugPrint('   ❌ ERROR: $e');
      debugPrint('   📍 Stack: $stack');
    }

    _isLoading = false;
    debugPrint('👨‍👩‍👧 [ParentProvider] loadChildren END');
    debugPrint('═══════════════════════════════════════════════════════════');
    _safeNotifyListeners();
  }

  /// Safe notify listeners - defers if called during build phase
  void _safeNotifyListeners() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  /// Select a child and load their centers
  Future<void> selectChild(String childId) async {
    debugPrint('───────────────────────────────────────────────────────────');
    debugPrint('👧 [ParentProvider] selectChild: $childId');
    _selectedChild = _children.firstWhere(
      (c) => c.id == childId,
      orElse: () => _children.first,
    );
    debugPrint('   ✅ Selected: ${_selectedChild?.fullName}');

    // Load child's centers
    await _loadChildCenters();

    _safeNotifyListeners();
  }

  /// Load centers for selected child
  Future<void> _loadChildCenters() async {
    debugPrint('🏫 [ParentProvider] _loadChildCenters START');
    if (_selectedChild == null) {
      debugPrint('   ⚠️ No selected child - skipping');
      return;
    }

    try {
      final childUserId = _selectedChild!.userId ?? _selectedChild!.id;
      debugPrint('   📥 childUserId: $childUserId');
      _childCenters = await _repository.getChildCenters(childUserId);
      debugPrint('   ✅ Centers loaded: ${_childCenters.length}');
      for (var center in _childCenters) {
        debugPrint('      🏫 ${center.centerName} (id: ${center.centerId})');
      }

      if (_childCenters.isNotEmpty) {
        _selectedCenter = _childCenters.first;
        debugPrint('   📌 Selected center: ${_selectedCenter?.centerName}');
      } else {
        debugPrint('   ⚠️ No centers found!');
      }
    } catch (e, stack) {
      _error = e.toString();
      debugPrint('   ❌ ERROR loading centers: $e');
      debugPrint('   📍 Stack: $stack');
    }
    debugPrint('🏫 [ParentProvider] _loadChildCenters END');
  }

  /// Select a center for the current child
  void selectCenter(String centerId) {
    debugPrint('🏫 [ParentProvider] selectCenter: $centerId');
    _selectedCenter = _childCenters.firstWhere(
      (c) => c.centerId == centerId,
      orElse: () => _childCenters.first,
    );
    debugPrint('   ✅ Selected: ${_selectedCenter?.centerName}');
    notifyListeners();
  }

  /// Get dashboard summary for selected child and center
  Future<Map<String, dynamic>> getChildDashboard() async {
    debugPrint('📊 [ParentProvider] getChildDashboard START');
    debugPrint(
      '   👧 selectedChild: ${_selectedChild?.fullName} (${_selectedChild?.id})',
    );
    debugPrint(
      '   🏫 selectedCenter: ${_selectedCenter?.centerName} (${_selectedCenter?.centerId})',
    );

    if (_selectedChild == null || _selectedCenter == null) {
      debugPrint('   ⚠️ Missing child or center - returning empty');
      return {};
    }

    try {
      final result = await _repository.getStudentDashboardSummary(
        studentId: _selectedChild!.userId ?? _selectedChild!.id,
        centerId: _selectedCenter!.centerId,
      );
      debugPrint('   ✅ Dashboard data: $result');
      return result;
    } catch (e, stack) {
      _error = e.toString();
      debugPrint('   ❌ ERROR: $e');
      debugPrint('   📍 Stack: $stack');
      return {};
    }
  }

  /// Get attendance for selected child
  Future<List<AttendanceModel>> getChildAttendance() async {
    debugPrint('📅 [ParentProvider] getChildAttendance START');
    debugPrint('   🏫 centerId: ${_selectedCenter?.centerId}');

    if (_selectedChild == null || _selectedCenter == null) {
      debugPrint('   ⚠️ Missing child or center - returning empty');
      return [];
    }

    try {
      final result = await _repository.getStudentAttendance(
        centerId: _selectedCenter!.centerId,
        studentUserId:
            _selectedChild?.userId ??
            _selectedChild?.id, // Pass student user ID
      );
      debugPrint('   ✅ Attendance records: ${result.length}');
      return result;
    } catch (e, stack) {
      _error = e.toString();
      debugPrint('   ❌ ERROR: $e');
      debugPrint('   📍 Stack: $stack');
      return [];
    }
  }

  /// Get grades for selected child
  Future<List<StudentGradeView>> getChildGrades() async {
    debugPrint('📝 [ParentProvider] getChildGrades START');
    debugPrint('   🏫 centerId: ${_selectedCenter?.centerId}');

    if (_selectedChild == null || _selectedCenter == null) {
      debugPrint('   ⚠️ Missing child or center - returning empty');
      return [];
    }

    try {
      final result = await _repository.getStudentGrades(
        centerId: _selectedCenter!.centerId,
        studentUserId:
            _selectedChild?.userId ??
            _selectedChild?.id, // Pass student user ID
      );
      debugPrint('   ✅ Grades: ${result.length}');
      return result;
    } catch (e, stack) {
      _error = e.toString();
      debugPrint('   ❌ ERROR: $e');
      debugPrint('   📍 Stack: $stack');
      return [];
    }
  }

  /// Get payments for selected child
  Future<List<PaymentModel>> getChildPayments() async {
    debugPrint('💰 [ParentProvider] getChildPayments START');
    debugPrint('   🏫 centerId: ${_selectedCenter?.centerId}');

    if (_selectedCenter == null) {
      debugPrint('   ⚠️ No center selected - returning empty');
      return [];
    }

    try {
      final result = await _repository.getStudentPayments(
        centerId: _selectedCenter!.centerId,
        studentUserId:
            _selectedChild?.userId ??
            _selectedChild?.id, // Pass student user ID
      );
      debugPrint('   ✅ Payments: ${result.length}');
      return result;
    } catch (e, stack) {
      _error = e.toString();
      debugPrint('   ❌ ERROR: $e');
      debugPrint('   📍 Stack: $stack');
      return [];
    }
  }

  /// Get schedule for selected child and center
  Future<List<Map<String, dynamic>>> getChildSchedule() async {
    debugPrint('📅 [ParentProvider] getChildSchedule START');
    if (_selectedChild == null || _selectedCenter == null) {
      debugPrint('   ⚠️ Missing child or center - returning empty');
      return [];
    }

    try {
      final result = await _repository.getStudentSchedule(
        centerId: _selectedCenter!.centerId,
        studentUserId: _selectedChild!.userId ?? _selectedChild!.id,
      );
      debugPrint('   ✅ Schedule items: ${result.length}');
      return result;
    } catch (e, stack) {
      _error = e.toString();
      debugPrint('   ❌ ERROR: $e');
      debugPrint('   📍 Stack: $stack');
      return [];
    }
  }

  /// Get recent activity (aggregated)
  Future<List<Map<String, dynamic>>> getRecentActivity() async {
    debugPrint('📋 [ParentProvider] getRecentActivity START');
    if (_selectedChild == null || _selectedCenter == null) {
      debugPrint('   ⚠️ Missing child or center - returning empty');
      return [];
    }

    try {
      final centerId = _selectedCenter!.centerId;
      debugPrint('   📥 Fetching attendance and grades for center: $centerId');

      // Fetch in parallel
      final results = await Future.wait([
        _repository.getStudentAttendance(
          centerId: centerId,
          limit: 5,
          studentUserId: _selectedChild?.userId ?? _selectedChild?.id,
        ),
        _repository.getStudentGrades(
          centerId: centerId,
          limit: 5,
          studentUserId: _selectedChild?.userId ?? _selectedChild?.id,
        ),
      ]);

      final attendance = results[0] as List<AttendanceModel>;
      final grades = results[1] as List<StudentGradeView>;
      debugPrint(
        '   📅 Attendance: ${attendance.length}, 📝 Grades: ${grades.length}',
      );

      List<Map<String, dynamic>> activities = [];

      // Add Attendance
      for (var a in attendance) {
        activities.add({
          'type': 'attendance',
          'date': a.attendanceDate,
          'title': 'تسجيل حضور',
          'subtitle':
              'الحالة: ${a.status.name == 'present'
                  ? 'حاضر'
                  : a.status.name == 'absent'
                  ? 'غائب'
                  : 'متأخر'}',
          'status': a.status.name,
        });
      }

      // Add Grades
      for (var g in grades) {
        activities.add({
          'type': 'grade',
          'date': g.createdAt,
          'title': 'درجة جديدة: ${g.courseName}',
          'subtitle': '${g.examType}: ${g.score}/${g.maxScore}',
          'score': g.score,
        });
      }

      // Sort by date descending
      activities.sort(
        (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
      );

      debugPrint('   ✅ Total activities: ${activities.length}');
      return activities.take(10).toList();
    } catch (e, stack) {
      _error = e.toString();
      debugPrint('   ❌ ERROR: $e');
      debugPrint('   📍 Stack: $stack');
      return [];
    }
  }

  /// Clear selection (on logout)
  void clearSelection() {
    debugPrint('🧹 [ParentProvider] clearSelection');
    _children = [];
    _selectedChild = null;
    _childCenters = [];
    _selectedCenter = null;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
