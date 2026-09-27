import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/dashboard_config.dart';

class DashboardPreferences {
  DashboardPreferences([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _key = 'j_life_dashboard_v1';
  final SharedPreferencesAsync _preferences;

  Future<DashboardConfig> load() async {
    final value = await _preferences.getString(_key);
    if (value == null) return DashboardConfig.fromPreset(DashboardPreset.basic);
    try {
      return DashboardConfig.fromJson(
        (jsonDecode(value) as Map).cast<String, Object?>(),
      );
    } on FormatException {
      return DashboardConfig.fromPreset(DashboardPreset.basic);
    } on ArgumentError {
      return DashboardConfig.fromPreset(DashboardPreset.basic);
    }
  }

  Future<void> save(DashboardConfig config) =>
      _preferences.setString(_key, jsonEncode(config.toJson()));
}
