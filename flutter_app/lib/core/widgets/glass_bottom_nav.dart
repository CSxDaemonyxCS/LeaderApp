import 'dart:ui';

import 'package:flutter/material.dart';

import '../motion/motion_tokens.dart';
import '../motion/press_scale.dart';
import '../theme/app_palette.dart';
import '../theme/app_theme.dart';

/// Under reduced motion the bottom nav renders as an opaque frosted card
/// so we can drop [BackdropFilter] — the single heaviest effect in the
/// app on low-end Android. The nudge in opacity keeps it readable
/// without the blur behind it.
double _fallbackOpacity(bool isDark) => isDark ? 0.92 : 0.96;

/// A destination on the floating glass bottom nav.
class GlassNavDestination {
  const GlassNavDestination({
    required this.icon,
    required this.label,
  });
  final IconData icon;
  final String label;
}

/// Apple-style liquid-glass floating pill bottom nav.
///
/// Sits above content (does not push it). Screens that host it must
/// leave ~96px of bottom padding for scrollable content.
class GlassBottomNav extends StatelessWidget {
  const GlassBottomNav({
    super.key,
    required this.destinations,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  final List<GlassNavDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    final glassBg = c.surface.withValues(alpha: isDark ? 0.55 : 0.62);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : c.ink.withValues(alpha: 0.08);
    final shadow = isDark
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.55),
              blurRadius: 40,
              offset: const Offset(0, 14),
              spreadRadius: -10,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
              spreadRadius: -6,
            ),
          ]
        : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 32,
              offset: const Offset(0, 12),
              spreadRadius: -8,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: -4,
            ),
          ];

    // Reduced motion drops the BackdropFilter — the heaviest paint in
    // the app on low-end Android. The pill still reads as "elevated
    // surface" via a bumped opacity + border + shadow.
    final reduced = reduceMotion(context);
    final surfaceColor = reduced
        ? c.surface.withValues(alpha: _fallbackOpacity(isDark))
        : glassBg;

    final pill = Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: borderColor),
        boxShadow: shadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (int i = 0; i < destinations.length; i++)
            Expanded(
              child: _GlassTab(
                destination: destinations[i],
                active: currentIndex == i,
                onTap: () => onDestinationSelected(i),
              ),
            ),
        ],
      ),
    );

    // RepaintBoundary in BOTH modes — isolates the nav's paint from the
    // scrolling body below it. Without it, every scroll frame repaints
    // the glass card too.
    return RepaintBoundary(
      child: SafeArea(
        minimum: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  child: reduced
                      ? pill
                      : BackdropFilter(
                          filter:
                              ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                          child: pill,
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 120,
                height: 4,
                decoration: BoxDecoration(
                  color: c.ink.withValues(alpha: isDark ? 0.5 : 0.28),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassTab extends StatelessWidget {
  const _GlassTab({
    required this.destination,
    required this.active,
    required this.onTap,
  });

  final GlassNavDestination destination;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return PressScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: AnimatedContainer(
        duration: effectiveDuration(context, MotionTokens.navPillMorph),
        curve: MotionTokens.spring,
        height: 42,
        padding: EdgeInsets.symmetric(
          horizontal: active ? 12 : 8,
          vertical: 0,
        ),
        decoration: BoxDecoration(
          color: active ? c.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          // The shadow stays in the decoration in BOTH states and only its
          // colour fades. `MotionTokens.spring` overshoots past its endpoint
          // by design, and a blur radius has a hard floor at 0 — animating
          // this list to `null` makes the deselecting tab lerp its blur
          // through a negative value, which `dart:ui` asserts on. A constant
          // blur with a transparent colour looks identical and cannot.
          boxShadow: [
            BoxShadow(
              color: active
                  ? c.primary.withValues(alpha: 0.55)
                  : c.primary.withValues(alpha: 0),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: -2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              destination.icon,
              size: 20,
              color: active ? c.primaryInk : c.ink2,
            ),
            ClipRect(
              child: AnimatedAlign(
                duration:
                    effectiveDuration(context, MotionTokens.navPillMorph),
                // Same floor problem as the shadow above: a width factor
                // cannot go below 0. The reveal keeps the spring, because
                // that overshoot is the pill's signature; the hide uses the
                // non-overshooting curve so it cannot land on a negative
                // width and assert.
                curve: active ? MotionTokens.spring : MotionTokens.emphasized,
                widthFactor: active ? 1.0 : 0.0,
                alignment: AlignmentDirectional.centerStart,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(start: 6),
                  child: AnimatedOpacity(
                    duration: effectiveDuration(context, MotionTokens.short),
                    opacity: active ? 1 : 0,
                    child: Text(
                      destination.label,
                      style: TextStyle(
                        color: c.primaryInk,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
