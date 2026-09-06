import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mtm/core/display/frame_rate.dart';
import 'package:mtm/core/motion/motion_level.dart';
import 'package:mtm/core/result/result.dart';
import 'package:mtm/core/theme/app_palette.dart';
import 'package:mtm/core/theme/app_theme.dart';
import 'package:mtm/core/theme/theme_controller.dart';
import 'package:mtm/features/settings/data/settings_providers.dart';
import 'package:mtm/features/settings/domain/settings_models.dart';
import 'package:mtm/features/settings/domain/settings_repository.dart';
import 'package:mtm/features/settings/presentation/themes_page.dart';
import 'package:mtm/l10n/strings.dart';

/// Point 1 — the nested Themes screen (`/more/themes`) hosts exactly the
/// appearance controls the old single Settings page held: palette, mode,
/// eye-protect. It must read/write the exact same providers, so these tests
/// assert against [themeStateProvider]/[themeControllerProvider] directly,
/// the same seam `theme_persistence_test.dart` already pins.
class _FakeSettingsRepository implements SettingsRepository {
  ThemeState? stored;
  int writes = 0;

  @override
  Future<Result<ThemeState?>> themePrefs() async => Success(stored);

  @override
  Future<Result<ThemeState>> updateThemePrefs(ThemeState prefs) async {
    writes++;
    stored = prefs;
    return Success(prefs);
  }

  @override
  Future<Result<MotionLevel?>> motionLevel() async => const Success(null);
  @override
  Future<Result<MotionLevel>> updateMotionLevel(MotionLevel level) async =>
      Success(level);
  @override
  Future<Result<FrameRatePreference?>> frameRate() async => const Success(null);
  @override
  Future<Result<FrameRatePreference>> updateFrameRate(
          FrameRatePreference p) async =>
      Success(p);
  @override
  Future<Result<NotificationPrefs>> notificationPrefs() async =>
      throw UnimplementedError();
  @override
  Future<Result<NotificationPrefs>> updateNotificationPrefs(
          NotificationPrefs p) async =>
      throw UnimplementedError();
  @override
  Future<Result<OrgInfo>> orgInfo() async => throw UnimplementedError();
}

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  required _FakeSettingsRepository repo,
}) async {
  final container = ProviderContainer(
    overrides: [settingsRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light(PaletteId.medical),
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: ThemesPage(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('shows every existing palette, mode, and eye-protect choice',
      (tester) async {
    await _pump(tester, repo: _FakeSettingsRepository());

    expect(find.text(S.settingsAppearance), findsOneWidget); // AppBar title
    for (final label in [
      S.settingsPaletteMedical,
      S.settingsPaletteSlate,
      S.settingsPaletteCopper,
      S.settingsPaletteClay,
      S.settingsPaletteIndigo,
      S.settingsPaletteTeal,
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.text(S.settingsModeLight), findsOneWidget);
    expect(find.text(S.settingsModeDark), findsOneWidget);
    expect(find.text(S.settingsModeSystem), findsOneWidget);
    expect(find.text(S.settingsEyeProtectOn), findsOneWidget);
    expect(find.text(S.settingsEyeProtectOff), findsOneWidget);
  });

  testWidgets('picking a palette writes through the existing controller',
      (tester) async {
    final repo = _FakeSettingsRepository();
    final container = await _pump(tester, repo: repo);
    await container.read(themeControllerProvider.future);

    await tester.tap(find.text(S.settingsPaletteTeal));
    await tester.pumpAndSettle();

    expect(container.read(themeStateProvider).palette, PaletteId.teal);
    expect(repo.stored?.palette, PaletteId.teal);
    expect(repo.writes, 1);
  });

  testWidgets('picking a mode writes through the existing controller',
      (tester) async {
    final repo = _FakeSettingsRepository();
    final container = await _pump(tester, repo: repo);
    await container.read(themeControllerProvider.future);

    await tester.tap(find.text(S.settingsModeDark));
    await tester.pumpAndSettle();

    expect(container.read(themeStateProvider).mode, ThemeMode.dark);
    expect(repo.stored?.mode, ThemeMode.dark);
  });

  testWidgets('eye-protect toggles independently of palette and mode',
      (tester) async {
    final repo = _FakeSettingsRepository();
    final container = await _pump(tester, repo: repo);
    await container.read(themeControllerProvider.future);

    expect(container.read(themeStateProvider).eyeProtect, isFalse);

    await tester.tap(find.text(S.settingsEyeProtectOn));
    await tester.pumpAndSettle();

    final state = container.read(themeStateProvider);
    expect(state.eyeProtect, isTrue);
    // Untouched by the eye-protect write.
    expect(state.palette, PaletteId.medical);
    expect(state.mode, ThemeMode.light);
    expect(repo.stored?.eyeProtect, isTrue);
  });

  testWidgets('a relaunch restores the palette chosen here', (tester) async {
    final repo = _FakeSettingsRepository();
    final first = await _pump(tester, repo: repo);
    await first.read(themeControllerProvider.future);
    await tester.tap(find.text(S.settingsPaletteIndigo));
    await tester.pumpAndSettle();
    first.dispose();

    final second = ProviderContainer(
      overrides: [settingsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(second.dispose);
    final restored = await second.read(themeControllerProvider.future);
    expect(restored.palette, PaletteId.indigo);
  });
}
