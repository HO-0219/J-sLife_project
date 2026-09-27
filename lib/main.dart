import 'package:flutter/material.dart';

import 'app.dart';
import 'bootstrap.dart';
import 'features/customization/data/dashboard_preferences.dart';
import 'features/customization/domain/dashboard_config.dart';
import 'features/items/application/notification_service.dart';
import 'features/items/data/life_repository.dart';
import 'features/items/data/memory_life_repository.dart';
import 'features/items/data/persistent_life_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LifeRepository repository;
  String? startupWarning;
  try {
    repository = await runStartupTask(
      PersistentLifeRepository.create(SharedPreferencesStringStore()),
    );
  } catch (_) {
    repository = MemoryLifeRepository();
    startupWarning = '저장 데이터를 읽지 못해 안전 모드로 시작했습니다. 기존 데이터는 덮어쓰지 않았습니다.';
  }

  LifeNotificationService? notifications;
  try {
    final localNotifications = LocalLifeNotificationService();
    await runStartupTask(localNotifications.initialize());
    for (final item in repository.currentItems) {
      await runStartupTask(localNotifications.schedule(item));
    }
    notifications = localNotifications;
  } catch (_) {
    startupWarning ??= '알림을 준비하지 못했습니다. 항목 관리는 계속 사용할 수 있습니다.';
  }
  final dashboardPreferences = DashboardPreferences();
  final dashboardConfig = await runStartupTask(dashboardPreferences.load())
      .catchError((_) => DashboardConfig.fromPreset(DashboardPreset.basic));
  runApp(
    JLifeApp(
      repository: repository,
      notifications: notifications,
      initialDashboardConfig: dashboardConfig,
      onDashboardConfigChanged: dashboardPreferences.save,
      startupWarning: startupWarning,
    ),
  );
}
