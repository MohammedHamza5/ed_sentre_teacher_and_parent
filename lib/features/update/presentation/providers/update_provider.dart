import 'package:flutter/foundation.dart';
import '../../data/models/update_info_model.dart';
import '../../data/repositories/update_repository.dart';

enum UpdateStatus {
  initial,
  checking,
  available,
  notAvailable,
  downloading,
  readyToInstall,
  installing,
  failure,
}

class UpdateProvider extends ChangeNotifier {
  final UpdateRepository _repository;

  UpdateStatus _status = UpdateStatus.initial;
  UpdateInfoModel? _updateInfo;
  double _progress = 0.0;
  String? _filePath;
  String? _errorMessage;

  UpdateProvider(this._repository);

  UpdateStatus get status => _status;
  UpdateInfoModel? get updateInfo => _updateInfo;
  double get progress => _progress;
  String? get filePath => _filePath;
  String? get errorMessage => _errorMessage;

  Future<void> checkForUpdates() async {
    if (_status == UpdateStatus.checking || _status == UpdateStatus.downloading || _status == UpdateStatus.installing) {
      return;
    }

    _status = UpdateStatus.checking;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.checkUpdate();
    result.when(
      success: (info) {
        if (info != null) {
          _updateInfo = info;
          _status = UpdateStatus.available;
        } else {
          _status = UpdateStatus.notAvailable;
        }
      },
      failure: (exception) {
        _errorMessage = exception.userMessage;
        _status = UpdateStatus.failure;
      },
    );
    notifyListeners();
  }

  Future<void> downloadUpdate() async {
    if (_updateInfo == null || _status == UpdateStatus.downloading || _status == UpdateStatus.installing) {
      return;
    }

    _status = UpdateStatus.downloading;
    _progress = 0.0;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.downloadUpdate(
      _updateInfo!,
      onProgress: (val) {
        _progress = val;
        notifyListeners();
      },
    );

    result.when(
      success: (path) {
        _filePath = path;
        _status = UpdateStatus.readyToInstall;
      },
      failure: (exception) {
        _errorMessage = exception.userMessage;
        _status = UpdateStatus.failure;
      },
    );
    notifyListeners();
  }

  Future<void> installUpdate() async {
    if (_updateInfo == null || _filePath == null || _status == UpdateStatus.installing) {
      return;
    }

    _status = UpdateStatus.installing;
    notifyListeners();

    final result = await _repository.applyUpdate(_filePath!, _updateInfo!);
    result.when(
      success: (success) {
        if (!success) {
          _errorMessage = 'تعذر فتح ملف التثبيت';
          _status = UpdateStatus.failure;
        }
      },
      failure: (exception) {
        _errorMessage = exception.userMessage;
        _status = UpdateStatus.failure;
      },
    );
    notifyListeners();
  }

  void reset() {
    _status = UpdateStatus.initial;
    _errorMessage = null;
    notifyListeners();
  }
}
