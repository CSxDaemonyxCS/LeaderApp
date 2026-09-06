import 'dart:math';

import '../../../core/display/frame_rate.dart';
import '../../../core/motion/motion_level.dart';
import '../../../core/result/result.dart';
import '../../../core/theme/theme_state.dart';
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
  FrameRatePreference? _frameRate;
  ThemeState? _themePrefs;

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
  Future<Result<FrameRatePreference?>> frameRate() async {
    await _latency();
    return Success(_frameRate);
  }

  @override
  Future<Result<FrameRatePreference>> updateFrameRate(
      FrameRatePreference p) async {
    await _latency();
    _frameRate = p;
    return Success(p);
  }

  /// Deliberately **not** behind [_latency].
  ///
  /// This one read sits on the launch path: the first frames paint with
  /// `ThemeState.initial()` until it returns, so half a second of simulated
  /// network would show every user the default theme and then visibly swap
  /// it. The other settings here model a server round-trip; a theme
  /// preference is a local read in any real implementation, and pretending
  /// otherwise only manufactures a flash that the shipped app will not have.
  @override
  Future<Result<ThemeState?>> themePrefs() async => Success(_themePrefs);

  @override
  Future<Result<ThemeState>> updateThemePrefs(ThemeState prefs) async {
    await _latency();
    _themePrefs = prefs;
    return Success(prefs);
  }

  @override
  Future<Result<OrgInfo>> orgInfo() async {
    await _latency();
    return const Success(OrgInfo(
      name: 'فريق الإسعاف التطوعي',
      legalName: 'جمعية الإسعاف الأهلي التطوعية',
      address: 'دمشق, سوريا',
      emailPublic: 'contact@mtm.org',
      detachmentCount: 5,
      memberCount: 25,
    ));
  }
}
