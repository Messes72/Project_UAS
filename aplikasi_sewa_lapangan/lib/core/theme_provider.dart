import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((
  ref,
) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeModeNotifier(prefs);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final SharedPreferences _prefs;

  ThemeModeNotifier(this._prefs) : super(_initialTheme(_prefs));

  static ThemeMode _initialTheme(SharedPreferences prefs) {
    final saved = prefs.getString('themeMode');
    if (saved == 'light') return ThemeMode.light;
    if (saved == 'dark') return ThemeMode.dark;
    return ThemeMode.system;
  }

  void setMode(ThemeMode mode) {
    state = mode;
    if (mode == ThemeMode.light) {
      _prefs.setString('themeMode', 'light');
    } else if (mode == ThemeMode.dark) {
      _prefs.setString('themeMode', 'dark');
    } else {
      _prefs.remove('themeMode');
    }
  }
}
