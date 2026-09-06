import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../l10n/strings.dart';
import '../../shell/main_shell.dart';
import 'widgets/settings_widgets.dart';

/// Nested Settings screen (`/more/themes`): palette, Light/Dark/System mode,
/// and eye-protect — the appearance controls previously on the Settings hub.
///
/// Moved, not rebuilt: every row here reads and writes the same
/// `themeStateProvider` / `themeControllerProvider` the hub used, so the
/// persistence, palette identities, and Light/Dark/System behavior are
/// unchanged.
class ThemesPage extends ConsumerWidget {
  const ThemesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final theme = ref.watch(themeStateProvider);

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(title: const Text(S.settingsAppearance)),
      body: FloatingNavPadding(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            SettingsSection(children: [
              PickerRow(
                icon: Icons.palette_outlined,
                label: S.settingsPalette,
                options: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final (id, label) in paletteChoices)
                      ChoicePill(
                        label: label,
                        // The palette's own primary, resolved for the
                        // brightness actually on screen: the dot has to
                        // preview the theme you would get, not a light-mode
                        // swatch on a dark device.
                        swatch: AppColors.resolve(
                          id,
                          Theme.of(context).brightness,
                        ).primary,
                        selected: theme.palette == id,
                        onTap: () => ref
                            .read(themeControllerProvider.notifier)
                            .setPalette(id),
                      ),
                  ],
                ),
              ),
              PickerRow(
                icon: Icons.contrast_rounded,
                label: S.settingsMode,
                options: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final (mode, label) in const [
                      (ThemeMode.light, S.settingsModeLight),
                      (ThemeMode.dark, S.settingsModeDark),
                      (ThemeMode.system, S.settingsModeSystem),
                    ])
                      ChoicePill(
                        label: label,
                        selected: theme.mode == mode,
                        onTap: () => ref
                            .read(themeControllerProvider.notifier)
                            .setMode(mode),
                      ),
                  ],
                ),
              ),
              PickerRow(
                icon: Icons.visibility_outlined,
                label: S.settingsEyeProtect,
                subtitle: S.settingsEyeProtectSub,
                options: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    ChoicePill(
                      label: S.settingsEyeProtectOn,
                      selected: theme.eyeProtect,
                      onTap: () => ref
                          .read(themeControllerProvider.notifier)
                          .setEyeProtect(true),
                    ),
                    ChoicePill(
                      label: S.settingsEyeProtectOff,
                      selected: !theme.eyeProtect,
                      onTap: () => ref
                          .read(themeControllerProvider.notifier)
                          .setEyeProtect(false),
                    ),
                  ],
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
