import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../config/app_private_config.dart';

class AppCustomizationNotifier extends ChangeNotifier {
  static const String _settingsFileName = 'app_customization.json';
  static const String _bgPrefix = 'home_background';
  static const String _launchLogoPrefix = 'launch_logo';
  static const Color _joshiAoThemeSeed = Color(0xFF2F3240);
  static const Color _keThemeSeed = Color(0xFF2F7FD1);
  static const Color _forestThemeSeed = Color(0xFF0F766E);
  static const Color _sunsetThemeSeed = Color(0xFFB45309);
  static const Color _roseThemeSeed = Color(0xFF9D174D);
  static const Color _slateThemeSeed = Color(0xFF374151);

  ThemeMode _themeMode = ThemeMode.dark;
  Color _seedColor = _joshiAoThemeSeed;
  String _themeName = 'JoshiAO Theme';
  String? _homeBackgroundPath;
  Uint8List? _homeBackgroundBytes;
  String? _launchLogoPath;
  Uint8List? _launchLogoBytes;
  String _launchTitle = AppPrivateConfig.launchTitle;
  bool _isReady = false;

  ThemeMode get themeMode => _themeMode;
  Color get seedColor => _seedColor;
  String get themeName => _themeName;
  bool get isJoshiAOTheme => _themeName == 'JoshiAO Theme';
  bool get isReady => _isReady;
  String? get homeBackgroundPath => _homeBackgroundPath;
  String get launchTitle => _launchTitle;

  List<String> get availableThemeNames => const [
    'JoshiAO Theme',
    'KE Theme',
    'Forest Theme',
    'Sunset Theme',
    'Rose Theme',
    'Slate Theme',
    'Custom',
  ];

  ImageProvider<Object>? get homeBackgroundImageProvider {
    if (_homeBackgroundBytes != null) {
      return MemoryImage(_homeBackgroundBytes!);
    }

    final path = _homeBackgroundPath;
    if (path == null || path.isEmpty) return null;
    return FileImage(File(path));
  }

  ImageProvider<Object>? get launchLogoImageProvider {
    if (_launchLogoBytes != null) {
      return MemoryImage(_launchLogoBytes!);
    }

    final path = _launchLogoPath;
    if (path == null || path.isEmpty) return null;
    return FileImage(File(path));
  }

  Future<void> initialize() async {
    if (_isReady) return;

    if (kIsWeb) {
      _isReady = true;
      notifyListeners();
      return;
    }

    try {
      final file = await _settingsFile();
      if (await file.exists()) {
        final raw = await file.readAsString();
        final jsonMap = json.decode(raw) as Map<String, dynamic>;

        final mode = (jsonMap['themeMode'] as String?) ?? 'light';
        _themeMode = _themeModeFromString(mode);

        final savedThemeName = (jsonMap['themeName'] as String?)?.trim();
        if (savedThemeName != null && savedThemeName.isNotEmpty) {
          _themeName = savedThemeName;
        }

        final seed = jsonMap['seedColor'] as int?;
        if (seed != null) {
          _seedColor = Color(seed);
        } else {
          _seedColor = _seedForThemeName(_themeName);
        }

        // JoshiAO theme is intentionally presented in dark mode.
        if (_themeName == 'JoshiAO Theme') {
          _themeMode = ThemeMode.dark;
          _seedColor = _joshiAoThemeSeed;
        }

        final launchTitle = (jsonMap['launchTitle'] as String?)?.trim();
        if (launchTitle != null && launchTitle.isNotEmpty) {
          _launchTitle = launchTitle;
        }

        final backgroundPath = jsonMap['homeBackgroundPath'] as String?;
        if (backgroundPath != null && backgroundPath.isNotEmpty) {
          final bgFile = File(backgroundPath);
          if (await bgFile.exists()) {
            _homeBackgroundPath = backgroundPath;
          }
        }

        final launchLogoPath = jsonMap['launchLogoPath'] as String?;
        if (launchLogoPath != null && launchLogoPath.isNotEmpty) {
          final launchFile = File(launchLogoPath);
          if (await launchFile.exists()) {
            _launchLogoPath = launchLogoPath;
          }
        }
      }
    } catch (_) {
      // Ignore malformed or missing settings and continue with defaults.
    }

    _isReady = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode nextMode) async {
    if (isJoshiAOTheme) {
      if (_themeMode != ThemeMode.dark) {
        _themeMode = ThemeMode.dark;
        notifyListeners();
        await _persist();
      }
      return;
    }

    if (_themeMode == nextMode) return;
    _themeMode = nextMode;
    notifyListeners();
    await _persist();
  }

  Future<void> setSeedColor(Color nextColor) async {
    if (isJoshiAOTheme) {
      if (_seedColor.toARGB32() != _joshiAoThemeSeed.toARGB32()) {
        _seedColor = _joshiAoThemeSeed;
        notifyListeners();
        await _persist();
      }
      return;
    }

    if (_seedColor.toARGB32() == nextColor.toARGB32()) return;
    _seedColor = nextColor;
    _themeName = _themeNameForSeed(nextColor) ?? 'Custom';
    notifyListeners();
    await _persist();
  }

  Future<void> setThemeName(String nextThemeName) async {
    if (_themeName == nextThemeName) return;

    final nextSeed = _seedForThemeName(nextThemeName);
    final seedChanged = _seedColor.toARGB32() != nextSeed.toARGB32();

    _themeName = nextThemeName;
    if (seedChanged) {
      _seedColor = nextSeed;
    }

    if (nextThemeName == 'JoshiAO Theme') {
      _themeMode = ThemeMode.dark;
      _seedColor = _joshiAoThemeSeed;
    }

    notifyListeners();
    await _persist();
  }

  Color _seedForThemeName(String name) {
    switch (name) {
      case 'JoshiAO Theme':
        return _joshiAoThemeSeed;
      case 'KE Theme':
        return _keThemeSeed;
      case 'Forest Theme':
        return _forestThemeSeed;
      case 'Sunset Theme':
        return _sunsetThemeSeed;
      case 'Rose Theme':
        return _roseThemeSeed;
      case 'Slate Theme':
        return _slateThemeSeed;
      default:
        return _seedColor;
    }
  }

  String? _themeNameForSeed(Color color) {
    final argb = color.toARGB32();
    if (argb == _joshiAoThemeSeed.toARGB32()) return 'JoshiAO Theme';
    if (argb == _keThemeSeed.toARGB32()) return 'KE Theme';
    if (argb == _forestThemeSeed.toARGB32()) return 'Forest Theme';
    if (argb == _sunsetThemeSeed.toARGB32()) return 'Sunset Theme';
    if (argb == _roseThemeSeed.toARGB32()) return 'Rose Theme';
    if (argb == _slateThemeSeed.toARGB32()) return 'Slate Theme';
    return null;
  }

  Future<void> setHomeBackgroundImage({
    required Uint8List bytes,
    required String extension,
  }) async {
    if (kIsWeb) {
      _homeBackgroundBytes = bytes;
      _homeBackgroundPath = null;
      notifyListeners();
      return;
    }

    final safeExt = extension.isEmpty ? '.png' : extension;
    final dir = await getApplicationDocumentsDirectory();
    final target = File(p.join(dir.path, '$_bgPrefix$safeExt'));
    await target.writeAsBytes(bytes, flush: true);

    _homeBackgroundBytes = null;
    _homeBackgroundPath = target.path;
    notifyListeners();
    await _persist();
  }

  Future<void> setLaunchLogoImage({
    required Uint8List bytes,
    required String extension,
  }) async {
    if (kIsWeb) {
      _launchLogoBytes = bytes;
      _launchLogoPath = null;
      notifyListeners();
      return;
    }

    final safeExt = extension.isEmpty ? '.png' : extension;
    final dir = await getApplicationDocumentsDirectory();
    final target = File(p.join(dir.path, '$_launchLogoPrefix$safeExt'));
    await target.writeAsBytes(bytes, flush: true);

    _launchLogoBytes = null;
    _launchLogoPath = target.path;
    notifyListeners();
    await _persist();
  }

  Future<void> clearLaunchLogoImage() async {
    if (!kIsWeb) {
      final existing = _launchLogoPath;
      if (existing != null && existing.isNotEmpty) {
        final file = File(existing);
        if (await file.exists()) {
          await file.delete();
        }
      }
    }

    _launchLogoPath = null;
    _launchLogoBytes = null;
    notifyListeners();
    await _persist();
  }

  Future<void> setLaunchTitle(String value) async {
    final trimmed = value.trim();
    final next = trimmed.isEmpty ? AppPrivateConfig.launchTitle : trimmed;
    if (_launchTitle == next) return;
    _launchTitle = next;
    notifyListeners();
    await _persist();
  }

  Future<void> clearHomeBackgroundImage() async {
    if (!kIsWeb) {
      final existing = _homeBackgroundPath;
      if (existing != null && existing.isNotEmpty) {
        final file = File(existing);
        if (await file.exists()) {
          await file.delete();
        }
      }
    }

    _homeBackgroundPath = null;
    _homeBackgroundBytes = null;
    notifyListeners();
    await _persist();
  }

  Future<File> _settingsFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, _settingsFileName));
  }

  ThemeMode _themeModeFromString(String raw) {
    switch (raw) {
      case 'system':
        return ThemeMode.system;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.light;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'system';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.light:
        return 'light';
    }
  }

  Future<void> _persist() async {
    if (kIsWeb) return;

    final file = await _settingsFile();
    final payload = <String, dynamic>{
      'themeMode': _themeModeToString(_themeMode),
      'themeName': _themeName,
      'seedColor': _seedColor.toARGB32(),
      'homeBackgroundPath': _homeBackgroundPath,
      'launchLogoPath': _launchLogoPath,
      'launchTitle': _launchTitle,
    };

    await file.writeAsString(json.encode(payload), flush: true);
  }
}
