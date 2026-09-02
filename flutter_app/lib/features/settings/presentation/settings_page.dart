import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/motion/motion_level.dart';
import '../../../core/motion/motion_tokens.dart';
import '../../../core/motion/press_scale.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../l10n/strings.dart';
import '../../auth/data/auth_providers.dart';
import '../../shell/main_shell.dart';
import '../data/motion_level_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _signingOut = false;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final theme = ref.watch(themeControllerProvider);
    final motion = ref.watch(motionLevelProvider);

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(title: const Text(S.settingsTitle)),
      body: FloatingNavPadding(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            const _SectionLabel(S.sectionAccount),
            _SettingsSection(children: [
              _NavigationRow(
                icon: Icons.person_outline_rounded,
                label: S.settingsProfile,
                onTap: () => context.push('/more/profile'),
              ),
              _NavigationRow(
                icon: Icons.shield_outlined,
                label: S.settingsSecurity,
                onTap: () => context.push('/more/security'),
              ),
              _NavigationRow(
                icon: Icons.notifications_none_rounded,
                label: S.settingsNotifications,
                onTap: () => context.push('/more/notifications'),
              ),
            ]),
            const _SectionLabel(S.sectionApp),
            _SettingsSection(children: [
              _PickerRow(
                icon: Icons.palette_outlined,
                label: S.settingsPalette,
                options: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _ChoicePill(
                      label: S.settingsPaletteSlate,
                      selected: theme.palette == PaletteId.slate,
                      onTap: () => ref
                          .read(themeControllerProvider.notifier)
                          .setPalette(PaletteId.slate),
                    ),
                    _ChoicePill(
                      label: S.settingsPaletteCopper,
                      selected: theme.palette == PaletteId.copper,
                      onTap: () => ref
                          .read(themeControllerProvider.notifier)
                          .setPalette(PaletteId.copper),
                    ),
                    _ChoicePill(
                      label: S.settingsPaletteClay,
                      selected: theme.palette == PaletteId.clay,
                      onTap: () => ref
                          .read(themeControllerProvider.notifier)
                          .setPalette(PaletteId.clay),
                    ),
                  ],
                ),
              ),
              _PickerRow(
                icon: Icons.contrast_rounded,
                label: S.settingsMode,
                options: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _ChoicePill(
                      label: S.settingsModeLight,
                      selected: theme.mode == ThemeMode.light,
                      onTap: () => ref
                          .read(themeControllerProvider.notifier)
                          .setMode(ThemeMode.light),
                    ),
                    _ChoicePill(
                      label: S.settingsModeDark,
                      selected: theme.mode == ThemeMode.dark,
                      onTap: () => ref
                          .read(themeControllerProvider.notifier)
                          .setMode(ThemeMode.dark),
                    ),
                  ],
                ),
              ),
              _PickerRow(
                icon: Icons.animation_rounded,
                label: S.settingsMotion,
                subtitle: S.settingsMotionSub,
                options: motion.when(
                  loading: () => const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (_, __) => TextButton(
                    onPressed: () => ref.invalidate(motionLevelProvider),
                    child: const Text(S.retry),
                  ),
                  data: (level) => Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _ChoicePill(
                        label: S.settingsMotionFull,
                        selected: level == MotionLevel.full,
                        onTap: () => ref
                            .read(motionLevelProvider.notifier)
                            .set(MotionLevel.full),
                      ),
                      _ChoicePill(
                        label: S.settingsMotionReduced,
                        selected: level == MotionLevel.reduced,
                        onTap: () => ref
                            .read(motionLevelProvider.notifier)
                            .set(MotionLevel.reduced),
                      ),
                    ],
                  ),
                ),
              ),
            ]),
            const _SectionLabel(S.sectionOrg),
            _SettingsSection(children: [
              _NavigationRow(
                icon: Icons.apartment_rounded,
                label: S.settingsOrg,
                onTap: () => context.push('/more/org'),
              ),
            ]),
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton.icon(
              onPressed: _signingOut ? null : _confirmSignOut,
              style: OutlinedButton.styleFrom(
                foregroundColor: c.crit,
                side: BorderSide(color: c.crit),
              ),
              icon: const Icon(Icons.logout_rounded),
              label: const Text(S.signOut),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: const Text(S.signOutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(S.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(S.signOut),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _signingOut = true);
    final result = await ref.read(authRepositoryProvider).signOut();
    if (!mounted) return;
    setState(() => _signingOut = false);

    result.when(
      success: (_, {stale = false}) {
        ref.invalidate(currentUserProvider);
        context.go('/login');
      },
      failure: (message, _) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message))),
      offline: (_) => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(S.offlineTitle)),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

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

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.children});

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

class _NavigationRow extends StatelessWidget {
  const _NavigationRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: c.ink2),
      title: Text(label),
      trailing: Icon(Icons.chevron_left_rounded, color: c.ink3),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
    );
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({
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

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return PressScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: AnimatedContainer(
        duration: effectiveDuration(context, MotionTokens.short),
        curve: effectiveCurve(context, MotionTokens.standard),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: selected ? c.primary : c.surface2,
          border: Border.all(color: selected ? c.primary : c.line),
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? c.primaryInk : c.ink2,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
