import 'package:flutter/foundation.dart';

class AppState extends ChangeNotifier {
  String? _currentPdfPath;
  List<String> _recentFiles = [];
  bool _isDarkMode = false;

  String? get currentPdfPath => _currentPdfPath;
  List<String> get recentFiles => _recentFiles;
  bool get isDarkMode => _isDarkMode;

  void setCurrentPdf(String path) {
    _currentPdfPath = path;
    if (!_recentFiles.contains(path)) {
      _recentFiles.insert(0, path);
      if (_recentFiles.length > 10) {
        _recentFiles = _recentFiles.sublist(0, 10);
      }
    }
    notifyListeners();
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void clearCurrentPdf() {
    _currentPdfPath = null;
    notifyListeners();
  }
}
