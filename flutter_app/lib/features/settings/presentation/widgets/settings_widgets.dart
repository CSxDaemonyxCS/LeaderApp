import 'package:flutter/material.dart';

import '../../../../core/motion/motion_tokens.dart';
import '../../../../core/motion/press_scale.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/strings.dart';

/// Shared building blocks for the Settings hub and its nested category
/// screens (Themes, Performance, Sync). Extracted from the original single
/// `settings_page.dart` so every screen in the hub speaks the same visual
/// language — grouped card, section label, navigation row, picker row — and
/// so none of it exists twice.

/// The six palettes, in the fixed display order used everywhere they are
/// offered.
const paletteChoices = <(PaletteId, String)>[
  (PaletteId.medical, S.settingsPaletteMedical),
  (PaletteId.slate, S.settingsPaletteSlate),
  (PaletteId.copper, S.settingsPaletteCopper),
  (PaletteId.clay, S.settingsPaletteClay),
  (PaletteId.indigo, S.settingsPaletteIndigo),
  (PaletteId.teal, S.settingsPaletteTeal),
];

String paletteLabel(PaletteId id) =>
    paletteChoices.firstWhere((p) => p.$1 == id).$2;

String themeModeLabel(ThemeMode mode) => switch (mode) {
      ThemeMode.light => S.settingsModeLight,
      ThemeMode.dark => S.settingsModeDark,
      ThemeMode.system => S.settingsModeSystem,
    };

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.xs,
        top: AppSpacing.lg,
        bottom: AppSpacing.sm,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: c.ink3,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        for (int i = 0; i < children.length; i++) ...[
          children[i],
          if (i != children.length - 1)
            Divider(height: 1, color: c.line, indent: 52),
        ],
      ]),
    );
  }
}

/// A navigable row on the hub — a category (Themes, Performance, Sync,
/// Organization) or an account destination (Profile, Security,
/// Notifications). [subtitle] is the only place a small live summary (the
/// active palette, the selected performance level, the sync state) may
/// appear on the hub — never the controls themselves.
class NavigationRow extends StatelessWidget {
  const NavigationRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.subtitleColor,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final Color? subtitleColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: c.ink2),
      title: Text(label),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: TextStyle(color: subtitleColor ?? c.ink3, fontSize: 12),
            ),
      // The chevron is a directional indicator, not a hard-coded arrow:
      // `_rounded` "left" here reads as "forward, into the row" once
      // Directionality mirrors it for RTL — the same convention every
      // other navigation row in this app already uses.
      trailing: Icon(Icons.chevron_left_rounded, color: c.ink3),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      minVerticalPadding: AppSpacing.md,
    );
  }
}

class PickerRow extends StatelessWidget {
  const PickerRow({
    super.key,
    required this.icon,
    required this.label,
    required this.options,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget options;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: c.ink2),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.titleSmall),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle!,
                      style: TextStyle(color: c.ink3, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ]),
          const SizedBox(height: AppSpacing.md),
          options,
        ],
      ),
    );
  }
}

class ChoicePill extends StatelessWidget {
  const ChoicePill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.swatch,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Optional colour preview shown before the label. The palette row uses it
  /// so a name like "Teal" is not the only thing telling you what you are
  /// about to apply.
  final Color? swatch;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final fg = selected ? c.primaryInk : c.ink2;
    // Announce the pill as a selectable option rather than as loose text, so
    // a screen reader says "selected" instead of leaving the state invisible.
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      // Registered on the node itself: TalkBack's double-tap dispatches a
      // semantics action, which never reaches the gesture detector once the
      // subtree below is excluded.
      onTap: onTap,
      child: ExcludeSemantics(
        child: PressScale(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: AnimatedContainer(
            duration: effectiveDuration(context, MotionTokens.short),
            curve: effectiveCurve(context, MotionTokens.standard),
            padding: EdgeInsetsDirectional.only(
              start: swatch == null ? AppSpacing.md : AppSpacing.sm,
              end: AppSpacing.md,
              top: 6,
              bottom: 6,
            ),
            decoration: BoxDecoration(
              color: selected ? c.primary : c.surface2,
              border: Border.all(color: selected ? c.primary : c.line),
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (swatch != null) ...[
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: swatch,
                      shape: BoxShape.circle,
                      // A hairline in the pill's own foreground, so a swatch
                      // close to the pill ground still reads as a disc.
                      border: Border.all(
                        color: fg.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: fg,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
