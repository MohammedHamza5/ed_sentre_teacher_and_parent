import 'package:flutter/material.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/data/supabase_repository.dart';

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
    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    log.debug('loadChildren: parentUserId=$parentUserId', tag: 'ParentProvider');

    try {
      _children = await _repository.getParentChildren(parentUserId);
      log.debug('Children loaded: ${_children.length}', tag: 'ParentProvider');

      if (_children.isNotEmpty) {
        await selectChild(_children.first.id);
      } else {
        log.warning('No children found', tag: 'ParentProvider');
      }
    } catch (e, stack) {
      _error = e.toString();
      log.error(
        'loadChildren failed',
        tag: 'ParentProvider',
        error: e,
        stackTrace: stack,
      );
    }

    _isLoading = false;
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
    _selectedChild = _children.firstWhere(
      (c) => c.id == childId,
      orElse: () => _children.first,
    );
    log.debug(
      'Selected child: ${_selectedChild?.fullName}',
      tag: 'ParentProvider',
    );

    await _loadChildCenters();
    _safeNotifyListeners();
  }

  /// Load centers for selected child
  Future<void> _loadChildCenters() async {
    if (_selectedChild == null) return;

    try {
      final childUserId = _selectedChild!.userId ?? _selectedChild!.id;
      _childCenters = await _repository.getChildCenters(childUserId);
      log.debug(
        'Child centers loaded: ${_childCenters.length}',
        tag: 'ParentProvider',
      );

      if (_childCenters.isNotEmpty) {
        _selectedCenter = _childCenters.first;
      }
    } catch (e, stack) {
      _error = e.toString();
      log.error(
        'Loading child centers failed',
        tag: 'ParentProvider',
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// Select a center for the current child
  void selectCenter(String centerId) {
    _selectedCenter = _childCenters.firstWhere(
      (c) => c.centerId == centerId,
      orElse: () => _childCenters.first,
    );
    notifyListeners();
  }

  /// Get dashboard summary for selected child and center
  Future<Map<String, dynamic>> getChildDashboard() async {
    if (_selectedChild == null || _selectedCenter == null) return {};

    try {
      return await _repository.getStudentDashboardSummary(
        studentId: _selectedChild!.userId ?? _selectedChild!.id,
        centerId: _selectedCenter!.centerId,
      );
    } catch (e, stack) {
      _error = e.toString();
      log.error(
        'getChildDashboard failed',
        tag: 'ParentProvider',
        error: e,
        stackTrace: stack,
      );
      return {};
    }
  }

  /// Get attendance for selected child
  Future<List<AttendanceModel>> getChildAttendance() async {
    if (_selectedChild == null || _selectedCenter == null) return [];

    try {
      return await _repository.getStudentAttendance(
        centerId: _selectedCenter!.centerId,
        studentUserId: _selectedChild?.userId ?? _selectedChild?.id,
      );
    } catch (e, stack) {
      _error = e.toString();
      log.error(
        'getChildAttendance failed',
        tag: 'ParentProvider',
        error: e,
        stackTrace: stack,
      );
      return [];
    }
  }

  /// Get grades for selected child
  Future<List<StudentGradeView>> getChildGrades() async {
    if (_selectedChild == null || _selectedCenter == null) return [];

    try {
      return await _repository.getStudentGrades(
        centerId: _selectedCenter!.centerId,
        studentUserId: _selectedChild?.userId ?? _selectedChild?.id,
      );
    } catch (e, stack) {
      _error = e.toString();
      log.error(
        'getChildGrades failed',
        tag: 'ParentProvider',
        error: e,
        stackTrace: stack,
      );
      return [];
    }
  }

  /// Get payments for selected child
  Future<List<PaymentModel>> getChildPayments() async {
    if (_selectedCenter == null) return [];

    try {
      return await _repository.getStudentPayments(
        centerId: _selectedCenter!.centerId,
        studentUserId: _selectedChild?.userId ?? _selectedChild?.id,
      );
    } catch (e, stack) {
      _error = e.toString();
      log.error(
        'getChildPayments failed',
        tag: 'ParentProvider',
        error: e,
        stackTrace: stack,
      );
      return [];
    }
  }

  /// Get schedule for selected child and center
  Future<List<Map<String, dynamic>>> getChildSchedule() async {
    if (_selectedChild == null || _selectedCenter == null) return [];

    try {
      return await _repository.getStudentSchedule(
        centerId: _selectedCenter!.centerId,
        studentUserId: _selectedChild!.userId ?? _selectedChild!.id,
      );
    } catch (e, stack) {
      _error = e.toString();
      log.error(
        'getChildSchedule failed',
        tag: 'ParentProvider',
        error: e,
        stackTrace: stack,
      );
      return [];
    }
  }

  /// Get recent activity (aggregated)
  Future<List<Map<String, dynamic>>> getRecentActivity() async {
    if (_selectedChild == null || _selectedCenter == null) return [];

    try {
      final centerId = _selectedCenter!.centerId;

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

      List<Map<String, dynamic>> activities = [];

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

      for (var g in grades) {
        activities.add({
          'type': 'grade',
          'date': g.createdAt,
          'title': 'درجة جديدة: ${g.courseName}',
          'subtitle': '${g.examType}: ${g.score}/${g.maxScore}',
          'score': g.score,
        });
      }

      activities.sort(
        (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
      );

      return activities.take(10).toList();
    } catch (e, stack) {
      _error = e.toString();
      log.error(
        'getRecentActivity failed',
        tag: 'ParentProvider',
        error: e,
        stackTrace: stack,
      );
      return [];
    }
  }

  /// Clear selection (on logout)
  void clearSelection() {
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
