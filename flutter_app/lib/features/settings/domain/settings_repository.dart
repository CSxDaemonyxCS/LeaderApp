import '../../../core/motion/motion_level.dart';
import '../../../core/result/result.dart';
import 'settings_models.dart';

abstract class SettingsRepository {
  Future<Result<NotificationPrefs>> notificationPrefs();
  Future<Result<NotificationPrefs>> updateNotificationPrefs(
      NotificationPrefs p);
  Future<Result<OrgInfo>> orgInfo();

  /// Persisted motion level. Returns `null` on first run — the app then
  /// initialises from `MediaQuery.disableAnimations`.
  Future<Result<MotionLevel?>> motionLevel();
  Future<Result<MotionLevel>> updateMotionLevel(MotionLevel level);
}
