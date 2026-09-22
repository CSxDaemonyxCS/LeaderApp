import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/motion/motion_tokens.dart';

/// The Login screen's own green + glass surface, and nothing else's.
///
/// **Why Login has its own colours at all.** Every other screen paints from
/// `AppColors` and must, because the user picked that palette. Login is the
/// screen before there is a user: it is the product's front door, it carries
/// the Clean Layer mark, and the design takes its palette straight out of
/// that mark's own glass — an ink-teal ground with a single frosted panel on
/// it. These values are therefore scoped to this file and this file only;
/// they are not an `AppColors` palette, they never leak into one, and no
/// other screen may read them.
///
/// **The numbers come from the design, converted once.** Each was authored
/// in oklch and is written here as the sRGB it resolves to, with the source
/// value in the comment so the two can be checked against each other.
///
/// **Appearance and Eye Protection still apply.** Light and dark are two full
/// token sets, and the reading-comfort wash is the same transform the palette
/// engine uses (`AppColors.warmed`): the same warm target, the same strength,
/// and — the point of it — the **ground only**. Ink, the accent and the
/// danger colour come back untouched, because warming a foreground is what
/// costs contrast where text is read.
@immutable
class LoginGlass {
  const LoginGlass({
    required this.baseTop,
    required this.baseMid,
    required this.baseBottom,
    required this.wash1,
    required this.wash2,
    required this.wash3,
    required this.fg,
    required this.muted,
    required this.faint,
    required this.accent,
    required this.onAccent,
    required this.danger,
    required this.dangerWash,
    required this.glassTop,
    required this.glassMid,
    required this.glassBottom,
    required this.glassBorder,
    required this.sheen,
    required this.fieldFill,
    required this.fieldBorder,
    required this.hairline,
    required this.panelShadow,
    required this.markGlow,
  });

  /// The three stops of the 168° ground gradient.
  final Color baseTop;
  final Color baseMid;
  final Color baseBottom;

  /// Ambient light behind the panel — three soft washes, never under text.
  final Color wash1;
  final Color wash2;
  final Color wash3;

  /// Text roles. [fg] for headings and input, [muted] for labels and links,
  /// [faint] for the divider word and the footer.
  final Color fg;
  final Color muted;
  final Color faint;

  /// The mark's own mint (dark) / deep teal (light), and the ink on it.
  final Color accent;
  final Color onAccent;

  /// Error text/border, and the 10% field wash that replaces the fill when a
  /// field is in error — inside a glass panel, stripping a field's surface
  /// would make it disappear.
  final Color danger;
  final Color dangerWash;

  /// The frosted panel's fill gradient, its border, and the 1px light across
  /// its top edge.
  final Color glassTop;
  final Color glassMid;
  final Color glassBottom;
  final Color glassBorder;
  final Color sheen;

  /// Fields and the Google surface sit *inside* the panel, so they use flat
  /// translucency rather than a second blur — nested blur is what makes
  /// glass UIs look muddy.
  final Color fieldFill;
  final Color fieldBorder;

  /// The divider rules.
  final Color hairline;

  /// Cast under the panel, and under the brand mark.
  final Color panelShadow;
  final Color markGlow;

  /// Resolves the set for [brightness], warmed when reading comfort is on.
  static LoginGlass resolve(Brightness brightness, {bool eyeProtect = false}) {
    final base = brightness == Brightness.dark ? _dark : _light;
    return eyeProtect ? base.warmed() : base;
  }

  /// The ring drawn around a focused field: 4dp of the accent at 26% (dark)
  /// / 18% (light), exactly as the design redlines it.
  List<BoxShadow> focusRing(double opacity) => [
        BoxShadow(
          color: accent.withValues(alpha: opacity),
          blurRadius: 0,
          spreadRadius: 4,
        ),
      ];

  /// Warms the ground and leaves every foreground alone.
  ///
  /// Deliberately the same transform as `AppColors.warmed()` — same target,
  /// same strength, same asymmetry. Eye Protection has to feel like one
  /// setting across the app, and it cannot be allowed to cost contrast on
  /// the one screen that is nothing but a form.
  LoginGlass warmed() {
    final dark = baseMid.computeLuminance() < 0.5;
    final target = dark ? const Color(0xFF2A1C08) : const Color(0xFFFFE7C2);
    final amount = dark ? 0.28 : 0.40;
    Color w(Color c) => Color.lerp(c, target, amount) ?? c;
    return LoginGlass(
      baseTop: w(baseTop),
      baseMid: w(baseMid),
      baseBottom: w(baseBottom),
      wash1: w(wash1),
      wash2: w(wash2),
      wash3: w(wash3),
      fg: fg,
      muted: muted,
      faint: faint,
      accent: accent,
      onAccent: onAccent,
      danger: danger,
      dangerWash: w(dangerWash),
      // The glass fill and border are white-alpha, so warming them would
      // only tint the light passing through. The ground under them already
      // carries the wash.
      glassTop: glassTop,
      glassMid: glassMid,
      glassBottom: glassBottom,
      glassBorder: glassBorder,
      sheen: sheen,
      fieldFill: fieldFill,
      fieldBorder: fieldBorder,
      hairline: hairline,
      panelShadow: panelShadow,
      markGlow: markGlow,
    );
  }

  /// Dark is the primary appearance: the mark was built for it.
  static const LoginGlass _dark = LoginGlass(
    baseTop: Color(0xFF061E1E), //  oklch(0.215 0.030 196)
    baseMid: Color(0xFF021213), //  oklch(0.168 0.024 200)
    baseBottom: Color(0xFF02090B), //  oklch(0.132 0.018 210)
    wash1: Color(0x573E9180), //  oklch(0.60 0.085 178 / .34)
    wash2: Color(0x66225C62), //  oklch(0.44 0.060 205 / .40)
    wash3: Color(0x2970AD99), //  oklch(0.70 0.070 172 / .16)
    fg: Color(0xFFF0F8F7), //  oklch(0.972 0.008 190)
    muted: Color(0xFFB0C0BF), //  oklch(0.795 0.018 190)
    faint: Color(0xFF899A98), //  oklch(0.672 0.020 190)
    accent: Color(0xFF73D1B7), //  oklch(0.795 0.098 174)
    onAccent: Color(0xFF041B1C), //  oklch(0.205 0.030 196)
    danger: Color(0xFFFD8379), //  oklch(0.745 0.150 26)
    dangerWash: Color(0x1ACE514B), //  oklch(0.60 0.16 26 / .10)
    glassTop: Color(0x18FFFFFF), //  white 9.5%
    glassMid: Color(0x0AFFFFFF), //  white 3.8%
    glassBottom: Color(0x10FFFFFF), //  white 6.2%
    glassBorder: Color(0x28FFFFFF), //  white 15.5%
    sheen: Color(0x6BFFFFFF), //  white 42%
    fieldFill: Color(0x10FFFFFF), //  white 6.2%
    fieldBorder: Color(0x25FFFFFF), //  white 14.5%
    hairline: Color(0x21FFFFFF), //  white 13%
    panelShadow: Color(0xD9000406), //  oklch(0.10 0.02 205 / .85)
    markGlow: Color(0x6B449786), //  oklch(0.62 0.085 178 / .42)
  );

  static const LoginGlass _light = LoginGlass(
    baseTop: Color(0xFFF2FBFB), //  oklch(0.982 0.010 196)
    baseMid: Color(0xFFE7F4F3), //  oklch(0.958 0.014 190)
    baseBottom: Color(0xFFDDEEEF), //  oklch(0.938 0.018 200)
    wash1: Color(0x7587CEBE), //  oklch(0.80 0.075 178 / .46)
    wash2: Color(0x85A7DCE2), //  oklch(0.86 0.055 205 / .52)
    wash3: Color(0x57C7EFE1), //  oklch(0.92 0.045 172 / .34)
    fg: Color(0xFF0F292C), //  oklch(0.262 0.032 205)
    muted: Color(0xFF4B6263), //  oklch(0.478 0.028 200)
    faint: Color(0xFF506869), //  oklch(0.498 0.028 200)
    accent: Color(0xFF096865), //  oklch(0.468 0.078 192)
    onAccent: Color(0xFFFBFEFE), //  oklch(0.995 0.004 190)
    danger: Color(0xFFB92B2E), //  oklch(0.518 0.178 25)
    dangerWash: Color(0x12D55851), //  oklch(0.62 0.16 26 / .07)
    glassTop: Color(0xCCFFFFFF), //  white 80%
    glassMid: Color(0x8FFFFFFF), //  white 56%
    glassBottom: Color(0xB3FFFFFF), //  white 70%
    glassBorder: Color(0xD1FFFFFF), //  white 82%
    sheen: Color(0xF2FFFFFF), //  white 95%
    fieldFill: Color(0xA8FFFFFF), //  white 66%
    fieldBorder: Color(0xFFBED0D0), //  oklch(0.845 0.020 196)
    hairline: Color(0xFFC5D4D4), //  oklch(0.858 0.016 196)
    panelShadow: Color(0x57325457), //  oklch(0.42 0.040 205 / .34)
    markGlow: Color(0x4D407375), //  oklch(0.52 0.055 200 / .30)
  );
}

/// The screen's ground: one gradient and three ambient washes.
///
/// The washes are painted as radial gradients rather than blurred layers.
/// A `BackdropFilter` behind the whole screen would be the single most
/// expensive thing in the app, for an effect a gradient reproduces exactly —
/// and this way the ambience costs the same on every device tier, leaving the
/// blur budget for the one surface that needs it: the panel.
class LoginBackdrop extends StatelessWidget {
  const LoginBackdrop({super.key, required this.glass, required this.child});

  final LoginGlass glass;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          // 168° in CSS ≈ top-ish to bottom-ish with a slight lean.
          begin: const Alignment(-0.35, -1),
          end: const Alignment(0.35, 1),
          stops: const [0, 0.46, 1],
          colors: [glass.baseTop, glass.baseMid, glass.baseBottom],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _Wash(color: glass.wash1, alignment: const Alignment(0.75, -0.85)),
          _Wash(color: glass.wash2, alignment: const Alignment(-0.8, 0.85)),
          _Wash(
            color: glass.wash3,
            alignment: const Alignment(-0.1, 0.05),
            scale: 0.72,
          ),
          child,
        ],
      ),
    );
  }
}

class _Wash extends StatelessWidget {
  const _Wash({
    required this.color,
    required this.alignment,
    this.scale = 1,
  });

  final Color color;
  final Alignment alignment;
  final double scale;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: alignment,
              radius: 0.9 * scale,
              colors: [color, color.withValues(alpha: 0)],
              stops: const [0, 1],
            ),
          ),
        ),
      );
}

/// The one frosted surface on the screen.
///
/// Heading, fields, CTA, divider and Google all live inside it, because
/// depth that comes from one surface reads as an object and depth that comes
/// from six reads as noise.
///
/// **Blur is budgeted, not assumed.** The sigma comes from the user's own
/// quality setting (`MotionSpec.blurSigma`), capped at the point where more
/// blur stops being visible. At the cheapest level there is no
/// `BackdropFilter` at all and the fill steps up to stay opaque enough to
/// read on — the screen loses an effect, never its legibility.
class LoginGlassPanel extends StatelessWidget {
  const LoginGlassPanel({
    super.key,
    required this.glass,
    required this.padding,
    required this.child,
  });

  /// CSS `blur(30px)` is roughly this much Gaussian sigma; past it the
  /// frost stops changing and only the GPU notices.
  static const double maxSigma = 15;

  final LoginGlass glass;
  final EdgeInsetsGeometry padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final sigma = math.min(motionSpec(context).blurSigma, maxSigma);
    final radius = BorderRadius.circular(30);
    // With no blur behind it the fill has to do the whole job, so it is
    // pulled toward opaque rather than left transparent over a gradient.
    final opaqueFallback = sigma <= 0;
    Color fill(Color c) => opaqueFallback
        ? Color.alphaBlend(c, glass.baseMid).withValues(alpha: 0.97)
        : c;

    final surface = Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: const Alignment(-0.6, -1),
          end: const Alignment(0.6, 1),
          stops: const [0, 0.52, 1],
          colors: [
            fill(glass.glassTop),
            fill(glass.glassMid),
            fill(glass.glassBottom),
          ],
        ),
        border: Border.all(color: glass.glassBorder),
      ),
      child: Stack(
        children: [
          Padding(padding: padding, child: child),
          // A 1px light across the top edge — the highlight a real pane of
          // glass catches. Inset at both ends so it fades rather than
          // butting into the corners.
          PositionedDirectional(
            top: 0,
            start: 0,
            end: 0,
            child: IgnorePointer(
              child: Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 30),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      glass.sheen.withValues(alpha: 0),
                      glass.sheen,
                      glass.sheen.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: glass.panelShadow,
              blurRadius: 52,
              spreadRadius: -26,
              offset: const Offset(0, 22),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: sigma <= 0
              ? surface
              : BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                  child: surface,
                ),
        ),
      ),
    );
  }
}
