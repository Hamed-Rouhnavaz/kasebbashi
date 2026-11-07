import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'settings_store.dart';

class ThemeController extends ChangeNotifier {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  AppPalette palette = AppPalette.luxury;
  ThemeMode mode = ThemeMode.system;

  Future<void> load() async {
    final p = await SettingsStore.get('theme_palette');
    final m = await SettingsStore.get('theme_mode');
    palette = AppPalette.values.firstWhere(
      (e) => e.name == p,
      orElse: () => AppPalette.luxury,
    );
    mode = ThemeMode.values.firstWhere(
      (e) => e.name == m,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> setPalette(AppPalette value) async {
    palette = value;
    notifyListeners();
    await SettingsStore.set('theme_palette', value.name);
  }

  Future<void> setMode(ThemeMode value) async {
    mode = value;
    notifyListeners();
    await SettingsStore.set('theme_mode', value.name);
  }
}
