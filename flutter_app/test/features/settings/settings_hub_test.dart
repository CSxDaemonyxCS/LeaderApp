import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mtm/core/router/app_router.dart';
import 'package:mtm/core/theme/app_palette.dart';
import 'package:mtm/core/theme/app_theme.dart';
import 'package:mtm/features/settings/presentation/notifications_page.dart';
import 'package:mtm/features/settings/presentation/org_info_page.dart';
import 'package:mtm/features/settings/presentation/performance_page.dart';
import 'package:mtm/features/settings/presentation/profile_page.dart';
import 'package:mtm/features/settings/presentation/security_page.dart';
import 'package:mtm/features/settings/presentation/settings_page.dart';
import 'package:mtm/features/settings/presentation/sync_page.dart';
import 'package:mtm/features/settings/presentation/themes_page.dart';
import 'package:mtm/features/settings/presentation/widgets/settings_widgets.dart';
import 'package:mtm/l10n/strings.dart';
import 'package:mtm/main.dart';

/// Point 1 — the Settings hub (`/more`) is navigation only; every control it
/// used to hold directly now lives on its own nested screen.
///
/// These tests boot the real app (`MtmApp`) rather than the bare
/// `SettingsPage`, so navigation genuinely exercises the router — a route
/// that resolves to a stale/duplicate page, or a back button that lands
/// somewhere other than `/more`, would fail here even though it looks fine
/// in isolation.
void main() {
  /// Swallows the same pre-existing, narrowly-matched debug complaint
  /// `needs_review_page_test.dart` already tolerates for this exact
  /// `ListTile`-inside-a-decorated-card layout — present before Point 1
  /// (the hub's rows were built the same way) and out of scope to fix here.
  void ignoreKnownPreexistingComplaints() {
    final inherited = FlutterError.onError;
    FlutterError.onError = (details) {
      final report = details.toString();
      if (report.contains('overflowed') &&
          report.contains('glass_bottom_nav.dart')) {
        return;
      }
      if (report.contains('ListTile background color or ink splashes')) {
        return;
      }
      inherited?.call(details);
    };
    addTearDown(() => FlutterError.onError = inherited);
  }

  Future<GoRouter> boot(WidgetTester tester, {String at = '/more'}) async {
    ignoreKnownPreexistingComplaints();
    // A tall phone size: the default test surface is small enough that the
    // floating bottom nav overlaps the last hub rows (intercepting their
    // taps) and the Organization section falls outside the viewport
    // entirely (a plain `ListView(children:)` only lays out what's within
    // the viewport + cache extent, same as any other sliver list).
    tester.view.physicalSize = const Size(1080, 3600);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MtmApp()),
    );
    await tester.pumpAndSettle();
    final router = container.read(appRouterProvider);
    router.go(at);
    await tester.pumpAndSettle();
    return router;
  }

  /// Performance's quality/frame-rate pickers show an indeterminate
  /// `CircularProgressIndicator` until their stored preference loads, which
  /// keeps scheduling frames forever — `pumpAndSettle` never returns while
  /// one is on screen. Bounded pumps are enough: the mock repository's
  /// simulated latency is under a second.
  Future<void> settleAroundSpinners(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('renders as an Arabic RTL hub with every category reachable',
      (tester) async {
    await boot(tester);

    expect(find.byType(SettingsPage), findsOneWidget);
    expect(
      tester
          .widget<Directionality>(find
              .ancestor(
                of: find.byType(SettingsPage),
                matching: find.byType(Directionality),
              )
              .first)
          .textDirection,
      TextDirection.rtl,
    );

    // Every category and account destination is reachable from the hub.
    for (final label in [
      S.settingsAppearance,
      S.settingsPerformanceTitle,
      S.settingsProfile,
      S.settingsSecurity,
      S.settingsNotifications,
      S.signOut,
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    // "المزامنة" labels both the Sync section and its one row, and
    // "المؤسسة" labels both the Organization section and its one row — the
    // existing Organization group already used this pattern before Point 1.
    expect(find.text(S.sectionSync), findsNWidgets(2));
    expect(find.text(S.settingsOrg), findsNWidgets(2));
  });

  testWidgets(
      'no detailed theme, performance, or sync controls render on the hub',
      (tester) async {
    await boot(tester);

    expect(find.byType(PickerRow), findsNothing);
    expect(find.byType(ChoicePill), findsNothing);
    expect(find.byKey(const Key('sync-now-button')), findsNothing);
    expect(find.text(S.settingsPalette), findsNothing);
    expect(find.text(S.settingsQuality), findsNothing);
    expect(find.text(S.settingsFrameRate), findsNothing);
    // No raw backend/sync terminology anywhere on the hub.
    expect(find.textContaining('outbox', findRichText: true), findsNothing);
    expect(
        find.textContaining('operationId', findRichText: true), findsNothing);
  });

  testWidgets(
      'tapping Themes opens the nested Themes screen and back '
      'returns to the hub', (tester) async {
    await boot(tester);

    await tester.tap(find.text(S.settingsAppearance));
    await tester.pumpAndSettle();
    expect(find.byType(ThemesPage), findsOneWidget);
    expect(find.byType(SettingsPage), findsNothing);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);
  });

  testWidgets('tapping Performance opens the nested Performance screen',
      (tester) async {
    await boot(tester);

    await tester.tap(find.text(S.settingsPerformanceTitle));
    await settleAroundSpinners(tester);
    expect(find.byType(PerformancePage), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);
  });

  testWidgets('tapping Sync opens the nested Sync screen', (tester) async {
    await boot(tester);

    // The row labelled "المزامنة" that is a ListTile-style navigation row
    // (not the section label above it).
    await tester.tap(find.widgetWithText(NavigationRow, S.sectionSync));
    await tester.pumpAndSettle();
    expect(find.byType(SyncPage), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);
  });

  testWidgets(
      'Profile, Security, Notifications and Organization links still open '
      'their existing routes', (tester) async {
    await boot(tester);

    await tester.tap(find.text(S.settingsProfile));
    await tester.pumpAndSettle();
    expect(find.byType(ProfilePage), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text(S.settingsSecurity));
    await tester.pumpAndSettle();
    expect(find.byType(SecurityPage), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text(S.settingsNotifications));
    await tester.pumpAndSettle();
    expect(find.byType(NotificationsPage), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(NavigationRow, S.settingsOrg));
    await tester.pumpAndSettle();
    expect(find.byType(OrgInfoPage), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsPage), findsOneWidget);
  });

  testWidgets('sign-out asks for confirmation exactly as before',
      (tester) async {
    await boot(tester);

    await tester.tap(find.widgetWithText(OutlinedButton, S.signOut));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text(S.signOutConfirm), findsOneWidget);

    // Cancel leaves the hub exactly where it was.
    await tester.tap(find.text(S.cancel));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);
  });

  testWidgets('a narrow phone with large text does not overflow',
      (tester) async {
    ignoreKnownPreexistingComplaints();
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    // The hub in isolation, not the full app — this checks the hub's own
    // layout under a narrow width and a large accessibility text scale,
    // without also exercising unrelated screens kept alive behind it.
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(PaletteId.medical),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.6),
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: child!,
            ),
          ),
          home: const SettingsPage(),
        ),
      ),
    );
    // Not `pumpAndSettle`: the hub's motion/frame-rate summaries watch
    // providers with a simulated load delay, and nothing upstream has
    // resolved them yet the way `MtmApp`'s own top-level watch does before
    // Settings is ever reached. Bounded pumps are enough for a layout check.
    await settleAroundSpinners(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(SettingsPage), findsOneWidget);
  });
}
