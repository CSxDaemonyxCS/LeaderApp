import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/result/result.dart';
import '../domain/settings_models.dart';
import '../domain/settings_repository.dart';
import 'mock_settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return MockSettingsRepository();
});

final notificationPrefsProvider =
    FutureProvider<Result<NotificationPrefs>>((ref) async {
  return ref.read(settingsRepositoryProvider).notificationPrefs();
});

final orgInfoProvider = FutureProvider<Result<OrgInfo>>((ref) async {
  return ref.read(settingsRepositoryProvider).orgInfo();
});
