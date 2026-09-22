@Tags(['render'])
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mtm/core/access/saas_tenant_status.dart';
import 'package:mtm/core/motion/motion_level.dart';
import 'package:mtm/core/router/app_router.dart';
import 'package:mtm/core/theme/app_palette.dart';
import 'package:mtm/core/theme/app_theme.dart';
import 'package:mtm/core/time/clock.dart';
import 'package:mtm/features/auth/data/auth_providers.dart';
import 'package:mtm/features/auth/data/customer_demo_controller.dart';
import 'package:mtm/features/auth/data/google_identity_gateway.dart';
import 'package:mtm/features/auth/data/mock_auth_repository.dart';
import 'package:mtm/features/auth/data/mock_onboarding_repository.dart';
import 'package:mtm/features/auth/data/onboarding_controller.dart';
import 'package:mtm/features/auth/domain/customer_demo.dart';
import 'package:mtm/features/auth/presentation/login_page.dart';
import 'package:mtm/l10n/strings.dart';

/// Deliberate Point 17C visual-review harness. PNGs stay outside the
/// repository, and — unlike `onboarding_screens_test.dart`'s `boot` — no
/// overflow report is swallowed, so every shot is also a fit check.
///
/// MTM_RENDER_DIR=/tmp/mtm-onboarding flutter test
/// test/features/auth/onboarding_render.dart --tags render --update-goldens
void main() {
  final outDir = Platform.environment['MTM_RENDER_DIR'];
  const longEmail = 'abdulrahman.al-mutairi.volunteer@riyadh-emergency.org';

  setUpAll(() async {
    final arabic = FontLoader('IBMPlexSansArabic');
    for (final weight in ['Regular', 'Medium', 'SemiBold']) {
      arabic.addFont(
        File('assets/fonts/IBMPlexSansArabic-$weight.ttf')
            .readAsBytes()
            .then(ByteData.sublistView),
      );
    }
    await arabic.load();
    var cache = File(Platform.resolvedExecutable).parent;
    while (!cache.path.endsWith('/cache') && cache.parent.path != cache.path) {
      cache = cache.parent;
    }
    await (FontLoader('MaterialIcons')
          ..addFont(
            File(
              '${cache.path}/artifacts/material_fonts/'
              'MaterialIcons-Regular.otf',
            ).readAsBytes().then(ByteData.sublistView),
          ))
        .load();
  });

  late DateTime now;
  late bool online;
  late MockOnboardingRepository onboarding;

  Future<GoRouter> boot(
    WidgetTester tester, {
    PaletteId palette = PaletteId.medical,
    ThemeMode mode = ThemeMode.light,
    double width = 390,
    double height = 844,
    double textScale = 1,
    double keyboard = 0,
    bool eyeProtect = false,
    bool reduceMotion = false,
    GoogleSignInAttempt? google,
    bool pendingGoogle = false,
    bool demoAvailable = true,
  }) async {
    now = DateTime.utc(2026, 9, 13, 9);
    online = true;
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = Size(width * 2, height * 2);
    tester.view.viewInsets = FakeViewPadding(bottom: keyboard * 2);
    addTearDown(tester.view.reset);

    final auth = MockAuthRepository(demoAccountsEnabled: false);
    final container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      // Production appearance: no persona section, the real Google gateway.
      demoAccountsEnabledProvider.overrideWithValue(false),
      clockProvider.overrideWithValue(() => now),
      onboardingRepositoryProvider.overrideWith(
        (ref) => onboarding = MockOnboardingRepository(
          clock: () => now,
          online: () => online,
          sessionIssued: auth.installOnboardedSession,
        ),
      ),
      if (google != null)
        googleIdentityGatewayProvider.overrideWithValue(_Fixed(google)),
      if (pendingGoogle)
        googleIdentityGatewayProvider.overrideWithValue(const _Pending()),
      if (!demoAvailable)
        customerDemoPolicyProvider
            .overrideWithValue(const CustomerDemoPolicy(available: false)),
    ]);
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(palette, eyeProtect: eyeProtect),
        darkTheme: AppTheme.dark(palette, eyeProtect: eyeProtect),
        themeMode: mode,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: reduceMotion,
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: MotionScope(
              level:
                  reduceMotion ? MotionLevel.performance : MotionLevel.balanced,
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    ));
    // Let the auth restore's simulated latency land before navigating; with
    // reduced motion nothing animates to keep pumpAndSettle waiting for it.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    return router;
  }

  Future<void> shot(WidgetTester tester, String name) async {
    // Drain the mock repositories' simulated latency: with reduced motion a
    // route change is instant, so pumpAndSettle alone can finish before it.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: '$name must fit');
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('$outDir/$name.png'),
    );
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final target = find.text(text).last;
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  Future<void> type(WidgetTester tester, Finder field, String value) async {
    await tester.ensureVisible(field);
    await tester.enterText(field, value);
    await tester.pumpAndSettle();
  }

  // `AuthScaffold` screens label through the decoration; Login labels above
  // the field and carries [LoginField.keyFor] instead.
  Finder labelled(String label) => find.byWidgetPredicate((w) =>
      w is TextField &&
      (w.decoration?.labelText == label || w.key == LoginField.keyFor(label)));

  Future<void> signUp(WidgetTester tester, GoRouter router, String email,
      {String password = 'a-good-password'}) async {
    router.go('/signup');
    await tester.pumpAndSettle();
    await type(tester, find.byKey(const Key('signup-email')), email);
    await type(tester, find.byKey(const Key('signup-password')), password);
    await tapText(tester, S.signUpAction);
  }

  Future<void> verify(WidgetTester tester, String code) async {
    await type(tester, find.byKey(const Key('verification-code')), code);
    await tapText(tester, S.verifyEmailAction);
  }

  /// Point 18B — past the Team/Demo chooser onto the Team Code form.
  Future<void> chooseTeam(WidgetTester tester) async {
    final team = find.byKey(const Key('onboarding-choice-team'));
    await tester.ensureVisible(team);
    await tester.pumpAndSettle();
    await tester.tap(team);
    await tester.pumpAndSettle();
  }

  testWidgets('01 login 390 light', (tester) async {
    await boot(tester);
    await shot(tester, '01-login-390-light');
  }, skip: outDir == null);

  testWidgets('02 login 390 dark, long email', (tester) async {
    await boot(tester, mode: ThemeMode.dark);
    await type(tester, labelled(S.emailLabel), longEmail);
    await shot(tester, '02-login-390-dark');
  }, skip: outDir == null);

  testWidgets('19 signup 320 x1.6 field error', (tester) async {
    final router = await boot(tester, width: 320, height: 1100, textScale: 1.6);
    await signUp(tester, router, 'not-an-email');
    await shot(tester, '19-signup-320-1.6x-field-error');
  }, skip: outDir == null);

  testWidgets('03 signup 320 x1.6 validation', (tester) async {
    final router = await boot(tester, width: 320, height: 1100, textScale: 1.6);
    await signUp(tester, router, longEmail, password: 'short');
    await shot(tester, '03-signup-320-1.6x-long-email-short-password');
  }, skip: outDir == null);

  testWidgets('04 verify email 390', (tester) async {
    final router = await boot(tester);
    await signUp(tester, router, OnboardingFixtures.nabdMainAdminEmail);
    await shot(tester, '04-verify-390');
  }, skip: outDir == null);

  testWidgets('05 verify wrong code 320 x1.6', (tester) async {
    final router = await boot(tester, width: 320, height: 1300, textScale: 1.6);
    await signUp(tester, router, OnboardingFixtures.nabdMainAdminEmail);
    await verify(tester, '111111');
    await shot(tester, '05-verify-wrong-code-320-1.6x');
  }, skip: outDir == null);

  testWidgets('06 verify expired', (tester) async {
    final router = await boot(tester);
    await signUp(tester, router, OnboardingFixtures.nabdMainAdminEmail);
    now = now.add(const Duration(minutes: 11));
    await verify(tester, kMockVerificationCode);
    await shot(tester, '06-verify-expired');
  }, skip: outDir == null);

  testWidgets('07 verify keyboard open 320', (tester) async {
    final router = await boot(tester, width: 320, height: 640, keyboard: 280);
    await signUp(tester, router, OnboardingFixtures.nabdMainAdminEmail);
    await type(tester, find.byKey(const Key('verification-code')), '٢٤٦');
    await shot(tester, '07-verify-keyboard-320');
  }, skip: outDir == null);

  testWidgets('08 team link 390, code typed', (tester) async {
    final router = await boot(tester);
    await signUp(tester, router, OnboardingFixtures.nabdMainAdminEmail);
    await verify(tester, kMockVerificationCode);
    await chooseTeam(tester);
    await type(tester, find.byKey(const Key('team-code')),
        OnboardingFixtures.nabdCode);
    await shot(tester, '08-team-link-390');
  }, skip: outDir == null);

  testWidgets('09 team link refused 320 x1.6', (tester) async {
    final router = await boot(tester, width: 320, height: 1300, textScale: 1.6);
    await signUp(tester, router, OnboardingFixtures.nabdMainAdminEmail);
    await verify(tester, kMockVerificationCode);
    await chooseTeam(tester);
    await type(tester, find.byKey(const Key('team-code')),
        OnboardingFixtures.unknownCode);
    await tapText(tester, S.linkTeamAction);
    await shot(tester, '09-team-link-refused-320-1.6x');
  }, skip: outDir == null);

  testWidgets('10 invitation-bound Simple Admin setup 390', (tester) async {
    final router = await boot(tester);
    await signUp(tester, router, OnboardingFixtures.hilalInviteeEmail);
    await verify(tester, kMockVerificationCode);
    await shot(tester, '10-setup-simple-admin-invitation-390');
  }, skip: outDir == null);

  testWidgets('11 Main Admin setup 320 x1.6 copper dark', (tester) async {
    final router = await boot(tester,
        width: 320,
        height: 1300,
        textScale: 1.6,
        palette: PaletteId.copper,
        mode: ThemeMode.dark);
    await signUp(tester, router, OnboardingFixtures.nabdMainAdminEmail);
    await verify(tester, kMockVerificationCode);
    await chooseTeam(tester);
    await type(tester, find.byKey(const Key('team-code')),
        OnboardingFixtures.nabdCode);
    await tapText(tester, S.linkTeamAction);
    await shot(tester, '11-setup-main-admin-320-1.6x-copper-dark');
  }, skip: outDir == null);

  testWidgets('12 Google unavailable (configuration needed)', (tester) async {
    await boot(tester, google: const GoogleSignInUnavailable());
    await tester.ensureVisible(find.byKey(const Key('google-sign-in')));
    await tester.tap(find.byKey(const Key('google-sign-in')));
    await shot(tester, '12-login-google-unavailable');
  }, skip: outDir == null);

  testWidgets('13 Google provider failure, indigo dark', (tester) async {
    await boot(tester,
        google: const GoogleSignInFailed(),
        palette: PaletteId.indigo,
        mode: ThemeMode.dark);
    await tester.ensureVisible(find.byKey(const Key('google-sign-in')));
    await tester.tap(find.byKey(const Key('google-sign-in')));
    await shot(tester, '13-login-google-failed-indigo-dark');
  }, skip: outDir == null);

  testWidgets('14 offline onboarding', (tester) async {
    final router = await boot(tester);
    await signUp(tester, router, OnboardingFixtures.nabdMainAdminEmail);
    online = false;
    await verify(tester, kMockVerificationCode);
    await shot(tester, '14-verify-offline');
  }, skip: outDir == null);

  testWidgets('15 blocked account', (tester) async {
    await boot(tester);
    await type(
        tester, labelled(S.emailLabel), OnboardingFixtures.suspendedEmail);
    await type(tester, labelled(S.passwordLabel), kMockFixturePassword);
    await tapText(tester, S.signIn);
    await shot(tester, '15-blocked-account');
  }, skip: outDir == null);

  testWidgets('16 blocked tenant', (tester) async {
    final router = await boot(tester);
    await signUp(tester, router, OnboardingFixtures.hilalInviteeEmail);
    await verify(tester, kMockVerificationCode);
    onboarding.setTenantStatus(
        OnboardingFixtures.hilalTenantId, SaasTenantStatus.suspended);
    await tapText(tester, S.completeSetupAction);
    await shot(tester, '16-blocked-tenant');
  }, skip: outDir == null);

  testWidgets('17 signup eye protection, reduced motion', (tester) async {
    final router = await boot(tester, eyeProtect: true, reduceMotion: true);
    router.go('/signup');
    await tester.pumpAndSettle();
    await shot(tester, '17-signup-eye-protect');
  }, skip: outDir == null);

  testWidgets('20 invitee stranded on team link 320 x1.6', (tester) async {
    final router = await boot(tester, width: 320, height: 1400, textScale: 1.6);
    await signUp(tester, router, OnboardingFixtures.hilalInviteeEmail);
    // Paused before verification, so the invitation cannot auto-link.
    onboarding.setTenantStatus(
        OnboardingFixtures.hilalTenantId, SaasTenantStatus.suspended);
    await verify(tester, kMockVerificationCode);
    await tapText(tester, S.checkInvitationAction);
    await shot(tester, '20-team-link-invitee-no-invitation-320-1.6x');
  }, skip: outDir == null);

  testWidgets('21 Team/Demo chooser 390 light', (tester) async {
    final router = await boot(tester);
    await signUp(tester, router, OnboardingFixtures.nabdMainAdminEmail);
    await verify(tester, kMockVerificationCode);
    await shot(tester, '21-choice-390-light');
  }, skip: outDir == null);

  testWidgets('22 chooser 320 x1.6 dark, long email', (tester) async {
    final router = await boot(tester,
        width: 320, height: 1500, textScale: 1.6, mode: ThemeMode.dark);
    await signUp(tester, router, longEmail);
    await verify(tester, kMockVerificationCode);
    await shot(tester, '22-choice-320-1.6x-dark-long-email');
  }, skip: outDir == null);

  testWidgets('23 chooser, demo closed, eye protection', (tester) async {
    final router =
        await boot(tester, eyeProtect: true, demoAvailable: false, width: 320);
    await signUp(tester, router, OnboardingFixtures.nabdMainAdminEmail);
    await verify(tester, kMockVerificationCode);
    await shot(tester, '23-choice-demo-closed-eye-protect-320');
  }, skip: outDir == null);

  testWidgets('24 Google in progress, 390 dark slate', (tester) async {
    await boot(tester,
        pendingGoogle: true, palette: PaletteId.slate, mode: ThemeMode.dark);
    await tester.ensureVisible(find.byKey(const Key('google-sign-in')));
    await tester.tap(find.byKey(const Key('google-sign-in')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('$outDir/24-login-google-in-progress-dark.png'));
  }, skip: outDir == null);

  testWidgets('18 login 320 x1.6 teal', (tester) async {
    await boot(tester,
        width: 320, height: 1400, textScale: 1.6, palette: PaletteId.teal);
    await shot(tester, '18-login-320-1.6x-teal');
  }, skip: outDir == null);
}

class _Fixed implements GoogleIdentityGateway {
  const _Fixed(this.attempt);
  final GoogleSignInAttempt attempt;

  @override
  Future<GoogleSignInAttempt> signIn() async => attempt;
}

/// A Google sheet that never answers — the in-progress state, held.
class _Pending implements GoogleIdentityGateway {
  const _Pending();

  @override
  Future<GoogleSignInAttempt> signIn() =>
      Completer<GoogleSignInAttempt>().future;
}
