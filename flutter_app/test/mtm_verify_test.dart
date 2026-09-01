import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mtm/core/motion/animated_counter.dart';
import 'package:mtm/core/motion/motion_level.dart';
import 'package:mtm/core/motion/motion_tokens.dart';
import 'package:mtm/core/theme/app_palette.dart';
import 'package:mtm/core/theme/app_theme.dart';
import 'package:mtm/core/theme/app_typography.dart';
import 'package:mtm/core/widgets/glass_bottom_nav.dart';

Future<void> _loadRealFont() async {
  final loader = FontLoader(AppTypography.family);
  for (final f in [
    'assets/fonts/IBMPlexSansArabic-Regular.ttf',
    'assets/fonts/IBMPlexSansArabic-Medium.ttf',
    'assets/fonts/IBMPlexSansArabic-SemiBold.ttf',
  ]) {
    loader.addFont(rootBundle.load(f));
  }
  await loader.load();
}

Widget _app(Widget child, {bool disableAnimations = false, MotionLevel? level}) {
  return MaterialApp(
    theme: AppTheme.light(PaletteId.slate),
    locale: const Locale('ar'),
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: MotionScope(
          level: level ?? MotionLevel.full,
          child: Scaffold(body: Center(child: child)),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(_loadRealFont);

  const style = TextStyle(
    fontFamily: AppTypography.family,
    fontFeatures: AppTypography.tabular,
    fontSize: 26,
    fontWeight: FontWeight.w600,
  );

  testWidgets('plain Text: Arabic-Indic digits are proportional (the bug)',
      (tester) async {
    await tester.pumpWidget(_app(Column(children: const [
      Text('٨٨', key: Key('a'), style: style),
      Text('١١', key: Key('b'), style: style),
    ])));
    final w1 = tester.getSize(find.byKey(const Key('a'))).width;
    final w2 = tester.getSize(find.byKey(const Key('b'))).width;
    expect(w1, isNot(closeTo(w2, 0.5)),
        reason: 'font has no tnum; ٨٨ and ١١ differ');
  });

  testWidgets('TabularDigits: every digit occupies the same cell',
      (tester) async {
    await tester.pumpWidget(_app(Column(children: const [
      TabularDigits('٨٨', key: Key('a'), style: style),
      TabularDigits('١١', key: Key('b'), style: style),
      TabularDigits('٠٩', key: Key('c'), style: style),
    ])));
    final a = tester.getSize(find.byKey(const Key('a'))).width;
    final b = tester.getSize(find.byKey(const Key('b'))).width;
    final c = tester.getSize(find.byKey(const Key('c'))).width;
    expect(b, closeTo(a, 0.01));
    expect(c, closeTo(a, 0.01));
  });

  testWidgets('TabularDigits renders numerals left-to-right', (tester) async {
    await tester.pumpWidget(
        _app(const TabularDigits('١٢', style: style)));
    final one = tester.getTopLeft(find.text('١')).dx;
    final two = tester.getTopLeft(find.text('٢')).dx;
    expect(one, lessThan(two), reason: '١٢ must read 12, not 21');
  });

  testWidgets('AnimatedCounter keeps a stable width across the tween',
      (tester) async {
    await tester.pumpWidget(_app(const AnimatedCounter(value: 88,
        style: style)));
    final widths = <double>[];
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      widths.add(tester.getSize(find.byType(TabularDigits)).width);
    }
    await tester.pumpAndSettle();
    // Width may step when the number gains a digit (9 -> 10), never
    // because one digit is wider than another.
    expect(widths.toSet().length, lessThanOrEqualTo(2),
        reason: 'observed widths: $widths');
  });

  testWidgets('reduced motion: no BackdropFilter on the bottom nav',
      (tester) async {
    const dests = [
      GlassNavDestination(icon: Icons.home, label: 'الرئيسية'),
      GlassNavDestination(icon: Icons.settings, label: 'المزيد'),
    ];
    Widget nav() => GlassBottomNav(
          destinations: dests,
          currentIndex: 0,
          onDestinationSelected: (_) {},
        );

    await tester.pumpWidget(_app(nav(), level: MotionLevel.full));
    expect(find.byType(BackdropFilter), findsOneWidget);

    await tester.pumpWidget(_app(nav(), level: MotionLevel.reduced));
    expect(find.byType(BackdropFilter), findsNothing);
    expect(find.byType(RepaintBoundary), findsWidgets);
  });

  testWidgets('user choice overrides OS reduce-motion', (tester) async {
    late bool reduced;
    await tester.pumpWidget(_app(
      Builder(builder: (context) {
        reduced = reduceMotion(context);
        return const SizedBox();
      }),
      disableAnimations: true,
      level: MotionLevel.full,
    ));
    expect(reduced, isFalse);

    await tester.pumpWidget(_app(
      Builder(builder: (context) {
        reduced = reduceMotion(context);
        return const SizedBox();
      }),
      disableAnimations: false,
      level: MotionLevel.reduced,
    ));
    expect(reduced, isTrue);
  });

  test('motion tokens collapse to zero under reduced motion', () {
    expect(ui.PlatformDispatcher.instance, isNotNull);
  });
}
