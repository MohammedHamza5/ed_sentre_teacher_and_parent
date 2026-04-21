import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/data/supabase_repository.dart';

/// CenterProvider - Manages multi-center functionality
/// Handles center selection and switching for Teacher/Parent apps
class CenterProvider extends ChangeNotifier {
  final SupabaseRepository _repository;

  CenterModel? _currentCenter;
  List<CenterModel> _availableCenters = [];
  bool _isLoading = false;
  String? _error;

  static const String _selectedCenterKey = 'selected_center_id';

  CenterProvider(this._repository);

  // Getters
  CenterModel? get currentCenter => _currentCenter;
  List<CenterModel> get availableCenters => _availableCenters;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentCenterId => _currentCenter?.id;
  bool get hasMultipleCenters => _availableCenters.length > 1;

  /// Load available centers for teacher
  Future<void> loadTeacherCenters(String teacherId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _availableCenters = await _repository.getTeacherCenters(teacherId);

      // Try to restore last selected center
      final prefs = await SharedPreferences.getInstance();
      final savedCenterId = prefs.getString(_selectedCenterKey);

      if (savedCenterId != null) {
        _currentCenter = _availableCenters.firstWhere(
          (c) => c.id == savedCenterId,
          orElse: () => _availableCenters.isNotEmpty
              ? _availableCenters.first
              : throw Exception('No centers available'),
        );
      } else if (_availableCenters.isNotEmpty) {
        _currentCenter = _availableCenters.first;
      }
    } catch (e) {
      _error = e.toString();
      if (_availableCenters.isEmpty) {
        _currentCenter = null;
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load available centers for parent's child
  Future<void> loadChildCenters(String childUserId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final centerInfos = await _repository.getChildCenters(childUserId);

      // Load full center details
      _availableCenters = [];
      for (final info in centerInfos) {
        final center = await _repository.getCenterById(info.centerId);
        if (center != null) {
          _availableCenters.add(center);
        }
      }

      // Try to restore last selected center
      final prefs = await SharedPreferences.getInstance();
      final savedCenterId = prefs.getString(_selectedCenterKey);

      if (savedCenterId != null) {
        _currentCenter = _availableCenters.firstWhere(
          (c) => c.id == savedCenterId,
          orElse: () => _availableCenters.isNotEmpty
              ? _availableCenters.first
              : throw Exception('No centers available'),
        );
      } else if (_availableCenters.isNotEmpty) {
        _currentCenter = _availableCenters.first;
      }
    } catch (e) {
      _error = e.toString();
      if (_availableCenters.isEmpty) {
        _currentCenter = null;
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Switch to a different center
  Future<void> selectCenter(String centerId) async {
    final center = _availableCenters.firstWhere(
      (c) => c.id == centerId,
      orElse: () => _currentCenter!,
    );

    _currentCenter = center;

    // Save selection
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedCenterKey, centerId);

    notifyListeners();
  }

  /// Clear center selection (on logout)
  Future<void> clearSelection() async {
    _currentCenter = null;
    _availableCenters = [];

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_selectedCenterKey);

    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
