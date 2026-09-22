import 'package:flutter/material.dart';

import '../../../../core/brand/brand_logo.dart';
import '../../../../core/motion/motion_tokens.dart';
import '../../../../core/motion/press_scale.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/strings.dart';

/// One of the three Leader marks, as a row with the real artwork in it.
///
/// **The preview is the asset, not a swatch.** The choice is entirely about
/// how the mark looks, so a coloured rectangle would be useless — the card
/// draws the same PNG the app will draw.
///
/// **No filenames anywhere.** The card shows the artwork and the mark's
/// Arabic name; the default one also says so, because "which one am I on if
/// I have never touched this" is the question this screen gets asked.
///
/// Deliberately the same shape, radius, border, press behaviour and check
/// mark as `ThemeChoiceCard` directly above it: two pickers on one screen
/// that look like two different products is worse than either.
class BrandLogoCard extends StatelessWidget {
  const BrandLogoCard({
    super.key,
    required this.logo,
    required this.selected,
    required this.onTap,
  });

  final BrandLogo logo;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Semantics(
      button: true,
      selected: selected,
      label: logo.label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: PressScale(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: AnimatedContainer(
            duration: effectiveDuration(context, MotionTokens.short),
            curve: effectiveCurve(context, MotionTokens.standard),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: selected ? c.primaryTint : c.surface,
              border: Border.all(
                color: selected ? c.primary : c.line,
                width: selected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(AppRadii.lg),
            ),
            child: Row(
              children: [
                // A quiet plate behind the mark: all three marks are dark
                // tiles, and on a dark palette a bare one would sit on
                // almost its own colour.
                Container(
                  width: 56,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.surface2,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    border: Border.all(color: c.line),
                  ),
                  child: Image.asset(
                    logo.asset,
                    width: 38,
                    height: 36,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    isAntiAlias: true,
                    gaplessPlayback: true,
                    excludeFromSemantics: true,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        logo.label,
                        style: TextStyle(
                          color: c.ink,
                          fontSize: 15,
                          // Weight, the check mark and the border all carry
                          // the selected state, so it never rests on colour
                          // alone.
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      if (logo.isDefault) ...[
                        const SizedBox(height: 2),
                        Text(
                          S.settingsBrandLogoDefault,
                          style: TextStyle(
                            color: c.ink3,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  size: 22,
                  color: selected ? c.primary : c.line2,
                  semanticLabel: selected ? S.settingsThemeSelected : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
