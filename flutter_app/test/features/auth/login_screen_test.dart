import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mtm/core/brand/brand_logo.dart';
import 'package:mtm/core/display/frame_rate.dart';
import 'package:mtm/core/motion/motion_level.dart';
import 'package:mtm/core/result/result.dart';
import 'package:mtm/core/router/app_router.dart';
import 'package:mtm/core/theme/app_palette.dart';
import 'package:mtm/core/theme/app_theme.dart';
import 'package:mtm/core/theme/theme_controller.dart';
import 'package:mtm/core/widgets/made_in_iraq.dart';
import 'package:mtm/features/auth/data/auth_providers.dart';
import 'package:mtm/features/auth/data/mock_auth_repository.dart';
import 'package:mtm/features/auth/presentation/google_sign_in_button.dart';
import 'package:mtm/features/auth/presentation/login_page.dart';
import 'package:mtm/features/settings/data/settings_providers.dart';
import 'package:mtm/features/settings/domain/settings_models.dart';
import 'package:mtm/features/settings/domain/settings_repository.dart';
import 'package:mtm/l10n/strings.dart';

/// The green/glass Login screen.
///
/// Two things are being pinned. **What is on it** — the Leader mark the user
/// picked, the wordmark, the welcome, two fields, forgot, the CTA, أو,
/// Google, sign-up and «صنع بفخر في العراق» — and, just as deliberately,
/// **what is not**: no demo entry, no persona card, no credential hint.
///
/// And **that it holds up**: 320 / 360 / 390 / 430dp, 1.6× text, an open
/// keyboard, and all four appearances, with no overflow in any of them. The
/// harness deliberately does not swallow overflow reports, so every pump
/// here is also a fit check.
class _ThemeOnlyRepository implements SettingsRepository {
  _ThemeOnlyRepository(this.stored);

  ThemeState? stored;

  @override
  Future<Result<ThemeState?>> themePrefs() async => Success(stored);
  @override
  Future<Result<ThemeState>> updateThemePrefs(ThemeState prefs) async {
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

void main() {
  Future<(ProviderContainer, GoRouter)> boot(
    WidgetTester tester, {
    double width = 390,
    double height = 844,
    double textScale = 1,
    double keyboard = 0,
    BrandLogo? logo,
    ThemeMode mode = ThemeMode.light,
    bool eyeProtect = false,
  }) async {
    tester.view.physicalSize = Size(width * 3, height * 3);
    tester.view.devicePixelRatio = 3;
    tester.view.viewInsets = FakeViewPadding(bottom: keyboard * 3);
    addTearDown(tester.view.reset);
    final container = ProviderContainer(overrides: [
      authRepositoryProvider
          .overrideWithValue(MockAuthRepository(demoAccountsEnabled: false)),
      settingsRepositoryProvider.overrideWithValue(
        _ThemeOnlyRepository(
          logo == null && mode == ThemeMode.light && !eyeProtect
              ? null
              : ThemeState(
                  palette: PaletteId.medical,
                  mode: mode,
                  eyeProtect: eyeProtect,
                  logo: logo ?? BrandLogo.fallback,
                ),
        ),
      ),
    ]);
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.light(PaletteId.medical, eyeProtect: eyeProtect),
        darkTheme: AppTheme.dark(PaletteId.medical, eyeProtect: eyeProtect),
        themeMode: mode,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
    return (container, router);
  }

  String markAsset(WidgetTester tester) => (tester
          .widget<Image>(find.byKey(const Key('login-brand-mark')))
          .image as AssetImage)
      .assetName;

  group('what the screen says', () {
    testWidgets('carries the brand, the welcome and every way in',
        (tester) async {
      await boot(tester);

      // Brand: the mark, then the Arabic wordmark.
      expect(find.byKey(const Key('login-brand-mark')), findsOneWidget);
      expect(find.text(S.productNameAr), findsOneWidget);
      expect(S.productNameAr, 'ليدر');

      // Heading, and the one supporting line under it.
      expect(find.text(S.loginTitle), findsOneWidget);
      expect(S.loginTitle, 'مرحباً بك في ليدر');
      expect(find.text(S.loginSub), findsOneWidget);

      // The form.
      expect(find.text(S.emailLabel), findsOneWidget);
      expect(S.emailLabel, 'البريد الإلكتروني');
      expect(find.text(S.passwordLabel), findsOneWidget);
      expect(S.passwordLabel, 'كلمة المرور');
      expect(find.byKey(LoginField.keyFor(S.emailLabel)), findsOneWidget);
      expect(find.byKey(LoginField.keyFor(S.passwordLabel)), findsOneWidget);
      expect(find.text(S.forgotPassword), findsOneWidget);
      expect(S.forgotPassword, 'نسيت كلمة المرور؟');

      // The CTA, the rule, Google, sign-up.
      expect(find.widgetWithText(FilledButton, S.signIn), findsOneWidget);
      expect(S.signIn, 'تسجيل الدخول');
      expect(find.text(S.authMethodsDivider), findsOneWidget);
      expect(S.authMethodsDivider, 'أو');
      expect(find.byKey(const Key('google-sign-in')), findsOneWidget);
      expect(find.text(S.continueWithGoogle), findsOneWidget);
      expect(S.continueWithGoogle, 'المتابعة باستخدام Google');
      expect(find.byType(GoogleGMark), findsOneWidget,
          reason: "Google's own mark, never a generic account icon");
      expect(find.text(S.noAccount), findsOneWidget);
      expect(find.text(S.createAccount), findsOneWidget);

      // And it closes with the product's line, from the shared widget.
      final footer = find.byKey(MadeInIraqFooter.widgetKey);
      expect(footer, findsOneWidget);
      expect(find.text(S.madeInIraq), findsOneWidget);
      expect(S.madeInIraq, 'صنع بفخر في العراق');
      expect(
        tester.getTopLeft(footer).dy,
        greaterThan(tester.getTopLeft(find.text(S.createAccount)).dy),
        reason: 'the line closes the screen, below sign-up',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('offers no shortcut past the front door', (tester) async {
      await boot(tester);

      for (final forbidden in [
        S.demoAccountsTitle,
        S.demoSuperAdmin,
        S.demoMainAdmin,
        S.demoSimpleAdmin,
        S.customerDemoAction,
        S.onboardingChoiceDemo,
      ]) {
        expect(find.text(forbidden), findsNothing, reason: forbidden);
      }
      // No credential hint anywhere on the screen.
      expect(find.textContaining('@'), findsNothing);
    });

    testWidgets('the password is hidden, and the eye says which way it goes',
        (tester) async {
      await boot(tester);
      final field = find.byKey(LoginField.keyFor(S.passwordLabel));
      final toggle = find.byKey(const Key('login-password-toggle'));

      expect(tester.widget<TextField>(field).obscureText, isTrue);
      expect(find.bySemanticsLabel(S.showPassword), findsOneWidget);

      await tester.ensureVisible(toggle);
      await tester.pumpAndSettle();
      await tester.tap(toggle);
      await tester.pumpAndSettle();

      expect(tester.widget<TextField>(field).obscureText, isFalse);
      expect(find.bySemanticsLabel(S.hidePassword), findsOneWidget);
      expect(tester.getRect(toggle).shortestSide, greaterThanOrEqualTo(48));
    });

    testWidgets('the CTA will not submit an empty form', (tester) async {
      await boot(tester);
      final cta = find.widgetWithText(FilledButton, S.signIn);

      expect(tester.widget<FilledButton>(cta).onPressed, isNull);

      await tester.enterText(
          find.byKey(LoginField.keyFor(S.emailLabel)), 'a@b.co');
      await tester.pump();
      expect(tester.widget<FilledButton>(cta).onPressed, isNull,
          reason: 'a password is still missing');

      await tester.enterText(
          find.byKey(LoginField.keyFor(S.passwordLabel)), 'a-good-password');
      await tester.pump();
      expect(tester.widget<FilledButton>(cta).onPressed, isNotNull);
    });
  });

  group('the mark it draws', () {
    testWidgets('is Clean Layer on an untouched install', (tester) async {
      await boot(tester);
      expect(markAsset(tester), BrandLogo.cleanLayer.asset);
    });

    for (final logo in BrandLogo.values) {
      testWidgets('follows the stored choice — ${logo.name}', (tester) async {
        await boot(tester, logo: logo);
        expect(markAsset(tester), logo.asset);
      });
    }

    testWidgets('changes with the preference, without a reload',
        (tester) async {
      final (container, _) = await boot(tester);
      expect(markAsset(tester), BrandLogo.cleanLayer.asset);

      await container
          .read(themeControllerProvider.notifier)
          .setLogo(BrandLogo.elegantCurve);
      await tester.pump();

      expect(markAsset(tester), BrandLogo.elegantCurve.asset);
    });
  });

  group('it fits', () {
    for (final width in [320.0, 360.0, 390.0, 430.0]) {
      testWidgets('at ${width.toInt()}dp', (tester) async {
        await boot(tester, width: width);
        expect(tester.takeException(), isNull);
        // Nothing is clipped horizontally, and the fields keep their width.
        final field = tester.getRect(find.byKey(const Key('login-email')));
        expect(field.left, greaterThanOrEqualTo(0));
        expect(field.right, lessThanOrEqualTo(width));
        expect(field.width, greaterThan(width * 0.6));
      });
    }

    testWidgets('at 320dp with 1.6x text — the worst case', (tester) async {
      await boot(tester, width: 320, textScale: 1.6);
      expect(tester.takeException(), isNull);
      // It lengthens and scrolls rather than clipping.
      expect(find.byType(Scrollable), findsWidgets);
      await tester.ensureVisible(find.byKey(MadeInIraqFooter.widgetKey));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('with the keyboard open', (tester) async {
      await boot(tester, keyboard: 291);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(LoginField.keyFor(S.passwordLabel)));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.widgetWithText(FilledButton, S.signIn));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('the tap targets clear 48dp', (tester) async {
      await boot(tester);
      for (final (name, target) in <(String, Finder)>[
        ('the CTA', find.widgetWithText(FilledButton, S.signIn)),
        ('Google', find.byKey(const Key('google-sign-in'))),
        ('the password eye', find.byKey(const Key('login-password-toggle'))),
      ]) {
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
        expect(tester.getRect(target).height, greaterThanOrEqualTo(48),
            reason: name);
      }
    });
  });

  group('every appearance', () {
    final appearances = <(String, ThemeMode, bool)>[
      ('light', ThemeMode.light, false),
      ('dark', ThemeMode.dark, false),
      ('light + eye protection', ThemeMode.light, true),
      ('dark + eye protection', ThemeMode.dark, true),
    ];

    for (final (name, mode, eye) in appearances) {
      testWidgets('renders in $name', (tester) async {
        await boot(tester, mode: mode, eyeProtect: eye);

        expect(find.text(S.loginTitle), findsOneWidget);
        expect(find.widgetWithText(FilledButton, S.signIn), findsOneWidget);
        expect(find.text(S.madeInIraq), findsOneWidget);
        // The footer never takes the colour of the ground it sits on.
        final footer = tester.widget<Text>(
          find.byKey(MadeInIraqFooter.widgetKey),
        );
        expect(footer.style?.color, isNotNull);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
