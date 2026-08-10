import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LiveChatThemeController extends ChangeNotifier {
  static const _storage = FlutterSecureStorage();

  String themeKey = 'classic_blue';

  Future<void> load() async {
    themeKey = await _storage.read(key: 'theme_key') ?? 'classic_blue';
    notifyListeners();
  }

  Future<void> setTheme(String key) async {
    themeKey = key;
    await _storage.write(key: 'theme_key', value: key);
    notifyListeners();
  }

  ThemeData get theme {
    switch (themeKey) {
      case 'aqua_2000':
        return ThemeData(
          brightness: Brightness.light,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF42A5F5),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        );
      case 'night':
        return ThemeData(
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF607D8B),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        );
      case 'neon':
        return ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF030712),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF00A8FF),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        );
      default:
        return ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF071A33),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0878FF),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        );
    }
  }
}
