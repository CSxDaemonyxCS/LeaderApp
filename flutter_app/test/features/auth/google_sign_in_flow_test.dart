import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mtm/core/router/app_router.dart';
import 'package:mtm/core/theme/app_palette.dart';
import 'package:mtm/core/theme/app_theme.dart';
import 'package:mtm/features/auth/data/auth_providers.dart';
import 'package:mtm/features/auth/data/mock_auth_repository.dart';
import 'package:mtm/features/auth/data/mock_onboarding_repository.dart';
import 'package:mtm/features/auth/presentation/email_verification_page.dart';
import 'package:mtm/features/auth/presentation/link_team_page.dart';
import 'package:mtm/l10n/strings.dart';

/// Point 17B — the Google entry point on `/login`, through the development
/// chooser dialog (`google_sign_in_button.dart`) that stands in for the
/// (not-yet-added) `google_sign_in` package. It drives
/// `MockOnboardingRepository`'s own `mock-google:<email>` /
/// `mock-google-unverified:<email>` convention, so this exercises the same
/// `signInWithGoogle` path a real SDK integration would.
void main() {
  Future<(ProviderContainer, GoRouter)> boot(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 3600);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(overrides: [
      authRepositoryProvider
          .overrideWithValue(MockAuthRepository(demoAccountsEnabled: false)),
    ]);
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.light(PaletteId.medical),
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    return (container, router);
  }

  Future<void> chooseGoogle(
    WidgetTester tester, {
    required String email,
    required bool verified,
  }) async {
    await tester.tap(find.text(S.continueWithGoogle));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      email,
    );
    if (!verified) {
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text(S.confirm));
    await tester.pumpAndSettle();
  }

  testWidgets('a new verified Google identity skips MTM verification',
      (tester) async {
    await boot(tester);
    await chooseGoogle(tester, email: 'g.new@gmail.com', verified: true);
    // Verified and unlinked: straight to Team Link, never a code screen.
    expect(find.byType(EmailVerificationPage), findsNothing);
    expect(find.byType(LinkTeamPage), findsOneWidget);
  });

  testWidgets('an unverified Google address still needs the MTM code',
      (tester) async {
    await boot(tester);
    await chooseGoogle(tester,
        email: 'g.unverified@gmail.com', verified: false);
    expect(find.byType(EmailVerificationPage), findsOneWidget);

    await tester.enterText(
        find.byKey(const Key('verification-code')), kMockVerificationCode);
    await tester.tap(find.text(S.verifyEmailAction));
    await tester.pumpAndSettle();
    expect(find.byType(LinkTeamPage), findsOneWidget);
  });

  testWidgets(
      'a verified Google address on a password account is guided, never merged',
      (tester) async {
    await boot(tester);
    // `readyEmail` already has a verified password credential.
    await chooseGoogle(tester,
        email: OnboardingFixtures.readyEmail, verified: true);
    expect(find.textContaining(S.onboardingMethodLinkRequired), findsOneWidget);
    // Still on /login — no session, no onboarding screen opened.
    expect(find.byType(LinkTeamPage), findsNothing);
    expect(find.byType(EmailVerificationPage), findsNothing);
  });
}
