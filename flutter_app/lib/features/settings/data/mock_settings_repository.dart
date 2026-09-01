import 'dart:math';

import '../../../core/motion/motion_level.dart';
import '../../../core/result/result.dart';
import '../domain/settings_models.dart';
import '../domain/settings_repository.dart';

class MockSettingsRepository implements SettingsRepository {
  MockSettingsRepository();
  final _rand = Random(71);

  NotificationPrefs _prefs = const NotificationPrefs(
    shiftReminders: true,
    stockAlerts: true,
    workshopUpdates: true,
    joinRequests: false,
  );

  // In-memory persistence for the mock. A real repo would write to
  // shared_preferences / a keychain / the server.
  MotionLevel? _motionLevel;

  Future<void> _latency() => Future<void>.delayed(
        Duration(milliseconds: 400 + _rand.nextInt(400)),
      );

  @override
  Future<Result<NotificationPrefs>> notificationPrefs() async {
    await _latency();
    return Success(_prefs);
  }

  @override
  Future<Result<NotificationPrefs>> updateNotificationPrefs(
      NotificationPrefs p) async {
    await _latency();
    _prefs = p;
    return Success(p);
  }

  @override
  Future<Result<MotionLevel?>> motionLevel() async {
    await _latency();
    return Success(_motionLevel);
  }

  @override
  Future<Result<MotionLevel>> updateMotionLevel(MotionLevel level) async {
    await _latency();
    _motionLevel = level;
    return Success(level);
  }

  @override
  Future<Result<OrgInfo>> orgInfo() async {
    await _latency();
    return const Success(OrgInfo(
      name: 'فريق الإسعاف التطوعي',
      legalName: 'جمعية الإسعاف الأهلي التطوعية',
      address: 'دمشق, سوريا',
      emailPublic: 'contact@mtm.org',
      detachmentCount: 4,
      memberCount: 111,
    ));
  }
}
