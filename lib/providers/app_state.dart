import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState extends ChangeNotifier {
  String? _currentPdfPath;
  List<String> _recentFiles = [];
  bool _isDarkMode = false;
  double _defaultZoom = 1.0;
  bool _rememberLastPage = true;
  Map<String, int> _lastPages = {};

  // Getters
  String? get currentPdfPath => _currentPdfPath;
  List<String> get recentFiles => List.unmodifiable(_recentFiles);
  bool get isDarkMode => _isDarkMode;
  double get defaultZoom => _defaultZoom;
  bool get rememberLastPage => _rememberLastPage;

  AppState() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      _defaultZoom = prefs.getDouble('defaultZoom') ?? 1.0;
      _rememberLastPage = prefs.getBool('rememberLastPage') ?? true;
      _recentFiles = prefs.getStringList('recentFiles') ?? [];
      
      // 加载每个文件的最后阅读页码
      for (final file in _recentFiles) {
        final page = prefs.getInt('lastPage_$file');
        if (page != null) {
          _lastPages[file] = page;
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('加载设置失败: $e');
    }
  }

  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', _isDarkMode);
      await prefs.setDouble('defaultZoom', _defaultZoom);
      await prefs.setBool('rememberLastPage', _rememberLastPage);
      await prefs.setStringList('recentFiles', _recentFiles);
    } catch (e) {
      debugPrint('保存设置失败: $e');
    }
  }

  void setCurrentPdf(String path) {
    _currentPdfPath = path;
    
    // 更新最近文件列表
    _recentFiles.remove(path);
    _recentFiles.insert(0, path);
    if (_recentFiles.length > 20) {
      _recentFiles = _recentFiles.sublist(0, 20);
    }
    
    _savePreferences();
    notifyListeners();
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    _savePreferences();
    notifyListeners();
  }

  void setDefaultZoom(double zoom) {
    _defaultZoom = zoom.clamp(0.5, 3.0);
    _savePreferences();
    notifyListeners();
  }

  void setRememberLastPage(bool value) {
    _rememberLastPage = value;
    _savePreferences();
    notifyListeners();
  }

  int? getLastPage(String filePath) {
    return _lastPages[filePath];
  }

  Future<void> setLastPage(String filePath, int page) async {
    if (_rememberLastPage) {
      _lastPages[filePath] = page;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('lastPage_$filePath', page);
      } catch (e) {
        debugPrint('保存页码失败: $e');
      }
    }
  }

  void removeFromRecent(String path) {
    _recentFiles.remove(path);
    _lastPages.remove(path);
    _savePreferences();
    notifyListeners();
  }

  void clearRecentFiles() {
    _recentFiles.clear();
    _lastPages.clear();
    _savePreferences();
    notifyListeners();
  }

  void clearCurrentPdf() {
    _currentPdfPath = null;
    notifyListeners();
  }
}
