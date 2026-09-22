import '../../../core/widgets/reading_column.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/brand/brand_logo.dart';
import '../../../core/motion/motion_tokens.dart';
import '../../../core/result/result.dart';
import '../../../core/startup/startup_destination.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/made_in_iraq.dart';
import '../../../l10n/strings.dart';
import '../data/auth_providers.dart';
import '../data/google_identity_gateway.dart';
import '../data/onboarding_controller.dart';
import '../domain/onboarding_models.dart';
import '../domain/onboarding_repository.dart';
import 'google_sign_in_button.dart';
import 'login_glass.dart';
import 'onboarding_ui.dart';

/// The product's front door.
///
/// **The design is the green/glass Login.** Its ground, its accent and its
/// one frosted panel all come out of the Clean Layer mark's own glass, so the
/// first screen and the icon the user tapped to get here are visibly the same
/// object. Every colour on it lives in [LoginGlass]; this file spells none.
///
/// **The mark is the one the user picked.** Login draws
/// `themeStateProvider.logo` — the default until they change it in
/// Settings → المظهر والأداء. The home-screen icon is fixed to Clean Layer
/// for everyone and is not derived from this; see [BrandLogo].
///
/// **Nothing about entry changed.** Same controller, same password call, same
/// Google gateway, same three outcomes handed to [_enter]. This screen is a
/// surface: it collects two fields and reports what came back. It carries no
/// demo entry, no persona shortcut, no credential hint and no MFA bypass —
/// Team/Demo is a post-verification decision for an unlinked identity, and
/// this screen is before that.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  /// Below this the screen padding and the panel padding both step down, so
  /// the fields keep their width rather than the layout keeping its margins.
  static const double compactWidth = 360;

  /// The form never gets wider than a phone's worth of line length, however
  /// wide the window is.
  ///
  /// This measure was the one value on this screen with obvious value
  /// everywhere else — a column of inputs has the same right width in a
  /// sign-up flow, a settings form or an edit sheet — so Phase 1 of the UI
  /// quality programme promoted it to [kFormMaxWidth] rather than leaving it
  /// spelled here. The number and this screen's layout are unchanged; the
  /// rest of the app can now inherit it. The screen's own *rhythm* (its 25 sp
  /// title, its −0.4 tracking, its 13 and 18 px gaps) stays local: that is
  /// composition for one panel, not a token.
  static const double maxFormWidth = kFormMaxWidth;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _busy = false;

  /// A Google assertion is being exchanged. Kept apart from [_busy] so only
  /// the Google surface shows progress; both lock the whole form.
  bool _googleBusy = false;
  String? _error;
  bool _offline = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    // The two fields draw their own focus ring and accent border, so the
    // screen has to rebuild when focus moves between them.
    _emailFocus.addListener(_onFocusChanged);
    _passwordFocus.addListener(_onFocusChanged);
    // The CTA is disabled until both fields have something in them, which
    // means it has to follow what is typed.
    _email.addListener(_onTyped);
    _password.addListener(_onTyped);
  }

  void _onFocusChanged() => setState(() {});

  void _onTyped() => setState(() {});

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  /// The one place a successful entry outcome is turned into navigation, for
  /// both the password path and Google.
  Future<void> _enter(Result<AuthEntryOutcome> result) async {
    switch (result) {
      case Success(:final data):
        switch (data) {
          case EntryReady():
            // The session providers are the app's authenticated state; the
            // controller only changed the repository. Awaited, not merely
            // invalidated: the gate is still `signedOut` until the re-read
            // lands, and a `context.go` fired before then is redirected
            // straight back here.
            await awaitFullSessionReady(ref);
            ref.invalidate(sessionsProvider);
            if (!mounted) return;
            context.go('/home');
          case EntryVerificationRequired():
            context.go('/verify-email');
          case EntryContinueOnboarding(:final snapshot):
            context.go(onboardingDestination(snapshot).location!);
        }
      case Failure():
        setState(() =>
            _error = onboardingErrorMessage(onboardingErrorKindOf(result)!));
      case Offline():
        setState(() => _offline = true);
    }
  }

  bool get _locked => _busy || _googleBusy;

  /// Whether the CTA can be pressed. Empty fields are the only thing this
  /// screen refuses on its own — everything else is the repository's answer
  /// to give, and a button that submits nothing is not a question worth
  /// asking a server.
  bool get _submittable =>
      !_locked && _email.text.trim().isNotEmpty && _password.text.isNotEmpty;

  Future<void> _submit() async {
    if (!_submittable) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
      _offline = false;
    });
    final result = await ref
        .read(onboardingControllerProvider.notifier)
        .signInWithPassword(email: _email.text, password: _password.text);
    if (!mounted) return;
    setState(() => _busy = false);
    await _enter(result);
  }

  Future<void> _onGoogleAttempt(GoogleSignInAttempt attempt) async {
    switch (attempt) {
      case GoogleSignInCancelled():
        return;
      case GoogleSignInUnavailable():
        setState(() =>
            _error = onboardingErrorMessage(OnboardingErrorKind.googleRetry));
        return;
      case GoogleSignInNetworkFailure():
        setState(() => _offline = true);
        return;
      case GoogleSignInFailed():
        setState(() =>
            _error = onboardingErrorMessage(OnboardingErrorKind.googleRetry));
        return;
      case GoogleSignInObtained(:final assertion):
        setState(() {
          _googleBusy = true;
          _error = null;
          _offline = false;
        });
        final result = await ref
            .read(onboardingControllerProvider.notifier)
            .signInWithGoogle(assertion);
        if (!mounted) return;
        setState(() => _googleBusy = false);
        await _enter(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final theme = ref.watch(themeStateProvider);
    final brightness = switch (theme.mode) {
      ThemeMode.light => Brightness.light,
      ThemeMode.dark => Brightness.dark,
      ThemeMode.system => media.platformBrightness,
    };
    final glass = LoginGlass.resolve(brightness, eyeProtect: theme.eyeProtect);

    final compact = media.size.width < LoginPage.compactWidth;
    final pad = compact ? 16.0 : 20.0;
    final panelPad = compact ? 16.0 : 19.0;

    final notice = switch (ref.watch(authEntryStateProvider)) {
      EntryNone(notice: EntryNotice.verificationEnded) =>
        S.onboardingVerificationEnded,
      EntryNone(notice: EntryNotice.sessionEnded) => S.onboardingSessionEnded,
      EntryNone(notice: EntryNotice.setupCompletedElsewhere) =>
        S.onboardingSetupAlreadyCompleted,
      _ => null,
    };

    return Scaffold(
      // The ground is the gradient below, not a flat colour; the scaffold's
      // own fill would only show for one frame behind it.
      backgroundColor: glass.baseMid,
      body: LoginBackdrop(
        glass: glass,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, box) {
              // The form is centred and capped through the scroll view's own
              // padding rather than an inner `Center`: a centring box would
              // hand the column loose height constraints and the `Spacer`
              // that holds the footer down would collapse to nothing.
              final side = math.max(
                pad,
                (box.maxWidth - LoginPage.maxFormWidth) / 2,
              );
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.symmetric(horizontal: side),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: box.maxHeight),
                  // The footer sits at the bottom of the screen when the
                  // content is shorter than it, and directly under the
                  // content when large text or an open keyboard makes the
                  // content taller than the viewport.
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 14),
                        _BrandBlock(logo: theme.logo, glass: glass),
                        const SizedBox(height: 16),
                        Text(
                          S.loginTitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: glass.fg,
                            fontSize: 25,
                            height: 1.34,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        LoginGlassPanel(
                          glass: glass,
                          padding: EdgeInsets.all(panelPad),
                          child: _form(glass, notice),
                        ),
                        const SizedBox(height: 12),
                        _signupRow(glass),
                        const Spacer(),
                        MadeInIraqFooter(
                          color: glass.faint,
                          padding: const EdgeInsets.only(top: 14, bottom: 26),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _form(LoginGlass glass, String? notice) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          S.loginSub,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: glass.muted,
            fontSize: 14,
            height: 1.6,
          ),
        ),
        if (notice != null) ...[
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Text(
              notice,
              textAlign: TextAlign.center,
              style: TextStyle(color: glass.muted, fontSize: 13, height: 1.55),
            ),
          ),
        ],
        const SizedBox(height: 18),
        LoginField(
          key: const Key('login-email'),  // the labelled group

          glass: glass,
          label: S.emailLabel,
          controller: _email,
          focusNode: _emailFocus,
          icon: Icons.mail_outline_rounded,
          enabled: !_locked,
          // The address is Latin whatever the interface language is, but it
          // still starts at the field's leading edge.
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.end,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.username, AutofillHints.email],
          onSubmitted: (_) => _passwordFocus.requestFocus(),
        ),
        const SizedBox(height: 13),
        LoginField(
          key: const Key('login-password'),
          glass: glass,
          label: S.passwordLabel,
          controller: _password,
          focusNode: _passwordFocus,
          icon: Icons.lock_outline_rounded,
          enabled: !_locked,
          obscure: _obscure,
          keyboardType: TextInputType.visiblePassword,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          onSubmitted: (_) => _submit(),
          trailing: _PasswordToggle(
            glass: glass,
            obscured: _obscure,
            onChanged: () => setState(() => _obscure = !_obscure),
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(
            onPressed: _locked ? null : () => context.push('/forgot'),
            style: TextButton.styleFrom(
              foregroundColor: glass.muted,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              minimumSize: const Size(48, 44),
              tapTargetSize: MaterialTapTargetSize.padded,
            ),
            child: const Text(
              S.forgotPassword,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        if (_offline) ...[
          const SizedBox(height: 4),
          _Notice(
            glass: glass,
            icon: Icons.wifi_off_rounded,
            message: S.onboardingOfflineNotice,
            tone: _NoticeTone.quiet,
          ),
        ] else if (_error != null) ...[
          const SizedBox(height: 4),
          _Notice(
            glass: glass,
            icon: Icons.error_outline_rounded,
            message: _error!,
            tone: _NoticeTone.danger,
          ),
        ],
        const SizedBox(height: 14),
        _PrimaryCta(
          glass: glass,
          busy: _busy,
          onPressed: _submittable ? _submit : null,
        ),
        const SizedBox(height: 18),
        _Divider(glass: glass),
        const SizedBox(height: 18),
        GoogleSignInButton(
          busy: _busy,
          loading: _googleBusy,
          onAttempt: _onGoogleAttempt,
          skin: GoogleButtonSkin(
            fill: glass.fieldFill,
            border: glass.fieldBorder,
            label: glass.fg,
            labelDisabled: glass.faint,
            progress: glass.accent,
            // Google's mark keeps its own four colours, so it gets a solid
            // tile rather than sitting straight on translucent glass.
            plate: const Color(0xFFFFFFFF),
          ),
        ),
      ],
    );
  }

  Widget _signupRow(LoginGlass glass) => Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            S.noAccount,
            style: TextStyle(color: glass.muted, fontSize: 13.5),
          ),
          TextButton(
            onPressed: _locked ? null : () => context.push('/signup'),
            style: TextButton.styleFrom(
              foregroundColor: glass.accent,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(48, 44),
            ),
            child: const Text(
              S.createAccount,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      );
}

/// The mark and the wordmark, centred.
///
/// The artwork is already a rounded glass tile, so it sits bare with only a
/// coloured glow beneath it — no plate, no ring, no tile inside a tile.
class _BrandBlock extends StatelessWidget {
  const _BrandBlock({required this.logo, required this.glass});

  final BrandLogo logo;
  final LoginGlass glass;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              boxShadow: [
                BoxShadow(
                  color: glass.markGlow,
                  blurRadius: 30,
                  spreadRadius: -8,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Image.asset(
              logo.asset,
              key: const Key('login-brand-mark'),
              width: 72,
              height: 68,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              isAntiAlias: true,
              gaplessPlayback: true,
              // The artwork carries the name; announcing it twice with the
              // wordmark below would read it twice.
              excludeFromSemantics: true,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            S.productNameAr,
            style: TextStyle(
              color: glass.fg,
              fontSize: 24,
              height: 1.25,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        ],
      );
}

/// One field: a persistent label, then a 54dp translucent well holding a
/// leading glyph, the input and an optional trailing control.
///
/// **Flat, not blurred.** It sits inside the panel's blur already; a second
/// `BackdropFilter` here is what makes a glass UI look muddy.
///
/// **The label is real.** It is above the field rather than floating inside
/// it — Arabic labels at 13.5sp do not survive being shrunk into a border —
/// and it is merged into the field's semantics node so a screen reader
/// announces the two as one control.
class LoginField extends StatelessWidget {
  const LoginField({
    super.key,
    required this.glass,
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.icon,
    this.enabled = true,
    this.obscure = false,
    this.textDirection,
    this.textAlign = TextAlign.start,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.onSubmitted,
    this.trailing,
  });

  final LoginGlass glass;
  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final IconData icon;
  final bool enabled;
  final bool obscure;
  final TextDirection? textDirection;

  /// The Latin address is written left to right but still sits against the
  /// field's leading edge, which in an Arabic layout is the right one.
  final TextAlign textAlign;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;
  final Widget? trailing;

  /// The handle a test or an automation tool reaches the input by.
  ///
  /// Login's labels sit *above* the field rather than in its
  /// `InputDecoration`, so the label-based finder the `AuthScaffold` screens
  /// use has nothing to match on here. Derived from the same `S` constant
  /// both sides read, so the two cannot drift.
  static Key keyFor(String label) => Key('login-field-$label');

  @override
  Widget build(BuildContext context) {
    final focused = focusNode.hasFocus;
    final dark = glass.baseMid.computeLuminance() < 0.5;
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: TextStyle(
              color: glass.fg,
              fontSize: 13.5,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 7),
          AnimatedContainer(
            duration: effectiveDuration(context, MotionTokens.short),
            curve: effectiveCurve(context, MotionTokens.standard),
            constraints: const BoxConstraints(minHeight: 54),
            padding: EdgeInsetsDirectional.only(
              start: 15,
              end: trailing == null ? 15 : 5,
            ),
            decoration: BoxDecoration(
              color: glass.fieldFill,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: focused ? glass.accent : glass.fieldBorder,
                width: 1.5,
              ),
              boxShadow:
                  focused ? glass.focusRing(dark ? 0.26 : 0.18) : const [],
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 19,
                  color: focused ? glass.accent : glass.muted,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: TextField(
                    key: keyFor(label),
                    controller: controller,
                    focusNode: focusNode,
                    enabled: enabled,
                    obscureText: obscure,
                    textDirection: textDirection,
                    textAlign: textAlign,
                    keyboardType: keyboardType,
                    textInputAction: textInputAction,
                    autofillHints: autofillHints,
                    onSubmitted: onSubmitted,
                    cursorColor: glass.accent,
                    style: TextStyle(
                      color: glass.fg,
                      fontSize: 15.5,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      filled: false,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The hide/show control. A 48dp target, and it says which way it goes —
/// the eye alone is ambiguous in every language.
class _PasswordToggle extends StatelessWidget {
  const _PasswordToggle({
    required this.glass,
    required this.obscured,
    required this.onChanged,
  });

  final LoginGlass glass;
  final bool obscured;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => IconButton(
        key: const Key('login-password-toggle'),
        onPressed: onChanged,
        iconSize: 20,
        constraints: const BoxConstraints.tightFor(width: 48, height: 48),
        padding: EdgeInsets.zero,
        color: glass.muted,
        tooltip: obscured ? S.showPassword : S.hidePassword,
        icon: Icon(
          obscured
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          semanticLabel: obscured ? S.showPassword : S.hidePassword,
        ),
      );
}

/// «تسجيل الدخول». A `FilledButton` so it keeps the app's button semantics,
/// with the glass palette painted over the theme's.
class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({
    required this.glass,
    required this.busy,
    required this.onPressed,
  });

  final LoginGlass glass;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: glass.accent,
        foregroundColor: glass.onAccent,
        // Disabled is carried by fill *and* by the button reporting itself
        // disabled, never by colour alone.
        disabledBackgroundColor: glass.accent.withValues(alpha: 0.42),
        disabledForegroundColor: glass.onAccent.withValues(alpha: 0.72),
        minimumSize: const Size.fromHeight(54),
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        // Size and weight only — the family comes from the button theme's
        // own label style. Spelling a bare `TextStyle` here would drop
        // `fontFamily` and render Arabic in the platform fallback.
        textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontSize: 16.5,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
      ),
      child: busy
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 17,
                  height: 17,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: glass.onAccent,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(S.signIn),
              ],
            )
          : const Text(S.signIn),
    );
  }
}

/// «أو» between the two independent ways in.
class _Divider extends StatelessWidget {
  const _Divider({required this.glass});

  final LoginGlass glass;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(child: Container(height: 1, color: glass.hairline)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              S.authMethodsDivider,
              style: TextStyle(
                color: glass.faint,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Container(height: 1, color: glass.hairline)),
        ],
      );
}

enum _NoticeTone { danger, quiet }

/// A refusal or an offline hold, said inside the panel.
///
/// Tinted rather than given a surface of its own: inside glass, a second
/// opaque card is one card too many, and the wash plus the glyph carry the
/// state without relying on colour alone. A live region, so a screen reader
/// announces it the moment it appears.
class _Notice extends StatelessWidget {
  const _Notice({
    required this.glass,
    required this.icon,
    required this.message,
    required this.tone,
  });

  final LoginGlass glass;
  final IconData icon;
  final String message;
  final _NoticeTone tone;

  @override
  Widget build(BuildContext context) {
    final danger = tone == _NoticeTone.danger;
    final ink = danger ? glass.danger : glass.muted;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: danger ? glass.dangerWash : glass.fieldFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: danger
                ? glass.danger.withValues(alpha: 0.45)
                : glass.fieldBorder,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(icon, color: ink, size: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: ink, fontSize: 13, height: 1.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
