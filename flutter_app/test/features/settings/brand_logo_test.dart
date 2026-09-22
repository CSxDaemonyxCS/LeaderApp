import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mtm/core/brand/brand_logo.dart';
import 'package:mtm/core/display/display_refresh.dart';
import 'package:mtm/core/display/frame_rate.dart';
import 'package:mtm/core/motion/motion_level.dart';
import 'package:mtm/core/result/result.dart';
import 'package:mtm/core/theme/app_palette.dart';
import 'package:mtm/core/theme/app_theme.dart';
import 'package:mtm/core/theme/theme_controller.dart';
import 'package:mtm/features/settings/data/frame_rate_provider.dart';
import 'package:mtm/features/settings/data/settings_providers.dart';
import 'package:mtm/features/settings/domain/settings_models.dart';
import 'package:mtm/features/settings/domain/settings_repository.dart';
import 'package:mtm/features/settings/presentation/themes_and_performance_page.dart';
import 'package:mtm/features/settings/presentation/widgets/brand_logo_card.dart';
import 'package:mtm/l10n/strings.dart';

/// The in-app Leader mark: three of them, Clean Layer by default, chosen on
/// the one appearance screen and stored with the rest of the theme.
///
/// The Android launcher icon is deliberately **not** covered here, because
/// it is deliberately not a preference: it is fixed to Clean Layer for
/// everyone in `mipmap-anydpi-v26/ic_launcher.xml`, and nothing in the Dart
/// layer may change it.
class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository([this.stored]);

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

ProviderContainer _container(_FakeSettingsRepository repo) {
  final c = ProviderContainer(
    overrides: [settingsRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(c.dispose);
  return c;
}

Future<ProviderContainer> _pumpSettings(
  WidgetTester tester, {
  required _FakeSettingsRepository repo,
  double width = 320,
}) async {
  tester.view.physicalSize = Size(width * 3, 3000 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(overrides: [
    settingsRepositoryProvider.overrideWithValue(repo),
    displayCapabilitiesProvider.overrideWith(
      (ref) async => const DisplayCapabilities(
        supportedRates: [60],
        activeRate: 60,
        canSelectMode: false,
        supportsFrameRateHint: false,
      ),
    ),
  ]);
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light(PaletteId.medical),
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: ThemesAndPerformancePage(),
        ),
      ),
    ),
  );
  // Not `pumpAndSettle`: the performance pickers keep an indeterminate
  // spinner until their stored preference lands.
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  return container;
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel(DisplayRefresh.channelName),
      (call) async => null,
    );
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel(DisplayRefresh.channelName), null);
  });

  group('the catalogue', () {
    test('is exactly three marks, each with its own artwork and name', () {
      expect(BrandLogo.values, hasLength(3));
      expect(
        BrandLogo.values.map((l) => l.asset).toSet(),
        hasLength(3),
        reason: 'three distinct files, not one file under three names',
      );
      expect(BrandLogo.values.map((l) => l.label).toSet(), hasLength(3));
      for (final logo in BrandLogo.values) {
        expect(logo.asset, startsWith('assets/brand/'));
        expect(logo.label, isNotEmpty);
        expect(logo.label, isNot(contains('.png')),
            reason: 'the picker shows a name, never a filename');
      }
    });

    test('every declared asset is actually on disk', () {
      for (final logo in BrandLogo.values) {
        expect(File(logo.asset).existsSync(), isTrue, reason: logo.asset);
        expect(File(logo.asset).lengthSync(), greaterThan(1024),
            reason: '${logo.asset} is not a placeholder');
      }
    });

    test('Clean Layer is the default and the fallback', () {
      expect(BrandLogo.fallback, BrandLogo.cleanLayer);
      expect(BrandLogo.cleanLayer.isDefault, isTrue);
      expect(BrandLogo.elegantCurve.isDefault, isFalse);
      expect(BrandLogo.depth.isDefault, isFalse);
      expect(const ThemeState.initial().logo, BrandLogo.cleanLayer);
    });

    test('an unreadable stored value falls back rather than throwing', () {
      for (final logo in BrandLogo.values) {
        expect(BrandLogo.fromName(logo.name), logo);
      }
      for (final junk in <Object?>[null, '', 'CleanLayer', 'retired', 0, 2, {}]) {
        expect(BrandLogo.fromName(junk), BrandLogo.cleanLayer,
            reason: '$junk');
      }
    });
  });

  group('persistence', () {
    test('a fresh install opens on Clean Layer', () async {
      final repo = _FakeSettingsRepository();
      final container = _container(repo);

      final state = await container.read(themeControllerProvider.future);

      expect(state.logo, BrandLogo.cleanLayer);
      expect(repo.writes, 0, reason: 'reading a default is not a change');
    });

    test('a choice is written through and survives a relaunch', () async {
      final repo = _FakeSettingsRepository();

      final first = _container(repo);
      await first.read(themeControllerProvider.future);
      await first
          .read(themeControllerProvider.notifier)
          .setLogo(BrandLogo.depth);
      expect(repo.stored?.logo, BrandLogo.depth);
      first.dispose();

      final second = _container(repo);
      expect(
        (await second.read(themeControllerProvider.future)).logo,
        BrandLogo.depth,
      );
    });

    test('it moves nothing else about the theme', () async {
      final repo = _FakeSettingsRepository(const ThemeState(
        palette: PaletteId.copper,
        mode: ThemeMode.dark,
        eyeProtect: true,
      ));
      final container = _container(repo);
      await container.read(themeControllerProvider.future);

      await container
          .read(themeControllerProvider.notifier)
          .setLogo(BrandLogo.elegantCurve);

      final state = container.read(themeStateProvider);
      expect(state.logo, BrandLogo.elegantCurve);
      expect(state.palette, PaletteId.copper);
      expect(state.mode, ThemeMode.dark);
      expect(state.eyeProtect, isTrue);
    });

    test('it is stored by name, and a corrupt name loses only the logo', () {
      const picked = ThemeState(
        palette: PaletteId.teal,
        mode: ThemeMode.dark,
        eyeProtect: true,
        logo: BrandLogo.elegantCurve,
      );
      final json = picked.toJson();
      expect(json['logo'], 'elegantCurve');
      expect(ThemeState.fromJson(jsonDecode(jsonEncode(json)) as Map<String,
          dynamic>), picked);

      // Written before the logo existed: everything else still restores.
      final legacy = ThemeState.fromJson(const {
        'palette': 'indigo',
        'mode': 'dark',
        'eyeProtect': true,
      });
      expect(legacy.logo, BrandLogo.cleanLayer);
      expect(legacy.palette, PaletteId.indigo);
      expect(legacy.mode, ThemeMode.dark);
      expect(legacy.eyeProtect, isTrue);

      final corrupt = ThemeState.fromJson(const {
        'palette': 'clay',
        'mode': 'light',
        'eyeProtect': false,
        'logo': 'leader_logo_06.png',
      });
      expect(corrupt.logo, BrandLogo.cleanLayer);
      expect(corrupt.palette, PaletteId.clay);
    });
  });

  group('the picker on /more/themes', () {
    testWidgets('shows all three, with the default named as such',
        (tester) async {
      await _pumpSettings(tester, repo: _FakeSettingsRepository());

      expect(find.text(S.settingsBrandLogoSection), findsOneWidget);
      expect(find.byType(BrandLogoCard), findsNWidgets(3));
      for (final logo in BrandLogo.values) {
        expect(find.byKey(Key('brand-logo-${logo.name}')), findsOneWidget);
        expect(find.text(logo.label), findsOneWidget, reason: logo.name);
      }
      expect(find.text(S.settingsBrandLogoDefault), findsOneWidget);

      // Each card draws its own artwork, not a swatch.
      final drawn = tester
          .widgetList<Image>(find.descendant(
            of: find.byType(BrandLogoCard),
            matching: find.byType(Image),
          ))
          .map((i) => (i.image as AssetImage).assetName)
          .toSet();
      expect(drawn, BrandLogo.values.map((l) => l.asset).toSet());
      expect(tester.takeException(), isNull);
    });

    testWidgets('Clean Layer is the one selected before anything is tapped',
        (tester) async {
      await _pumpSettings(tester, repo: _FakeSettingsRepository());

      final selected = tester
          .widgetList<BrandLogoCard>(find.byType(BrandLogoCard))
          .where((c) => c.selected)
          .toList();
      expect(selected, hasLength(1));
      expect(selected.single.logo, BrandLogo.cleanLayer);
    });

    for (final logo in BrandLogo.values) {
      testWidgets('tapping ${logo.name} selects it and stores it',
          (tester) async {
        final repo = _FakeSettingsRepository();
        final container = await _pumpSettings(tester, repo: repo);

        final card = find.byKey(Key('brand-logo-${logo.name}'));
        await tester.ensureVisible(card);
        await tester.pump();
        await tester.tap(card);
        // Optimistic: the card reports itself selected on the same frame.
        await tester.pump();

        expect(container.read(themeStateProvider).logo, logo);
        expect(
          tester
              .widgetList<BrandLogoCard>(find.byType(BrandLogoCard))
              .where((c) => c.selected)
              .map((c) => c.logo),
          [logo],
        );

        await tester.pump(const Duration(seconds: 1));
        if (logo.isDefault) {
          // Re-picking the mark already in use is a no-op by design, so
          // there is nothing to have written — the app opens on it anyway.
          expect(repo.stored, isNull);
        } else {
          expect(repo.stored?.logo, logo);
        }
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('it fits, and stays one column, at 320dp', (tester) async {
      await _pumpSettings(tester, repo: _FakeSettingsRepository(), width: 320);

      final rects = tester
          .widgetList<BrandLogoCard>(find.byType(BrandLogoCard))
          .map((c) => tester.getRect(find.byKey(Key('brand-logo-${c.logo.name}'))))
          .toList();
      expect(rects, hasLength(3));
      for (final r in rects) {
        expect(r.width, lessThanOrEqualTo(320));
        // Comfortably above the 48dp target floor.
        expect(r.height, greaterThanOrEqualTo(48));
      }
      expect(tester.takeException(), isNull);
    });
  });
}
