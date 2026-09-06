import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/display/frame_rate.dart';
import '../../../core/motion/animated_counter.dart';
import '../../../core/motion/motion_level.dart';
import '../../../core/sync/outbox_controller.dart';
import '../../../core/sync/sync_coordinator.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../l10n/strings.dart';
import '../../auth/data/auth_providers.dart';
import '../../auth/data/sign_out_controller.dart';
import '../../auth/presentation/sign_out_action.dart';
import '../../shell/main_shell.dart';
import '../data/frame_rate_provider.dart';
import '../data/motion_level_provider.dart';
import 'widgets/settings_widgets.dart';

/// The Settings hub (`/more`): navigation only.
///
/// Point 1 turned this from a single long page mixing appearance, device
/// performance, sync, and account controls into a pure information-
/// architecture surface — every control it used to hold directly now lives
/// on its own nested screen (`/more/themes`, `/more/performance`,
/// `/more/sync`), reading and writing the exact same providers it always
/// did. This page only routes to them and shows a short, plain-language
/// summary of the active choice on each row.
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    // Only for the Account row's subtitle: which account is signed in. The
    // collapsed view is the right one here — a hub row has nothing useful to
    // say about *why* there is no session, and the account screen it leads to
    // explains that properly.
    final signedInName = ref.watch(currentUserProvider).valueOrNull?.name;
    final signingOut =
        ref.watch(signOutControllerProvider) == SignOutPhase.inProgress;
    final theme = ref.watch(themeStateProvider);
    final motion = ref.watch(motionLevelProvider);
    final frameRate = ref.watch(frameRateProvider);
    final pending = ref.watch(pendingOperationsCountProvider);
    final needingReview = ref.watch(conflictOperationsCountProvider);
    final syncStatus = ref.watch(syncCoordinatorProvider);

    final themesSubtitle =
        '${paletteLabel(theme.palette)} · ${themeModeLabel(theme.mode)}';

    final performanceParts = <String>[
      if (motion.valueOrNull != null) _motionLevelLabel(motion.valueOrNull!),
      if (frameRate.valueOrNull != null)
        _frameRateLabel(frameRate.valueOrNull!)
      else
        S.settingsFrameRateAuto,
    ];
    final performanceSubtitle =
        performanceParts.isEmpty ? null : performanceParts.join(' · ');

    final String syncSubtitle;
    Color? syncSubtitleColor;
    if (syncStatus.isSyncing) {
      syncSubtitle = S.syncInProgress;
    } else if (needingReview > 0) {
      syncSubtitle = needingReview == 1
          ? S.syncReviewOne
          : S.syncReviewMany
              .replaceFirst('%d', toArabicIndic('$needingReview'));
      syncSubtitleColor = c.warn;
    } else if (pending == 0) {
      syncSubtitle = S.syncAllSynced;
    } else if (pending == 1) {
      syncSubtitle = S.syncPendingOne;
    } else {
      syncSubtitle = S.syncPendingMany
          .replaceFirst('%d', toArabicIndic(pending.toString()));
    }

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(title: const Text(S.settingsTitle)),
      body: FloatingNavPadding(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // Appearance and device: how the app looks, and how much work a
            // frame costs on this device.
            const SectionLabel(S.sectionThemesPerformance),
            SettingsSection(children: [
              NavigationRow(
                icon: Icons.palette_outlined,
                label: S.settingsAppearance,
                subtitle: themesSubtitle,
                onTap: () => context.push('/more/themes'),
              ),
              NavigationRow(
                icon: Icons.speed_rounded,
                label: S.settingsPerformanceTitle,
                subtitle: performanceSubtitle,
                onTap: () => context.push('/more/performance'),
              ),
            ]),
            // Data and synchronization.
            const SectionLabel(S.sectionSync),
            SettingsSection(children: [
              NavigationRow(
                icon:
                    needingReview == 0 && pending == 0 && !syncStatus.isSyncing
                        ? Icons.cloud_done_outlined
                        : Icons.sync_rounded,
                label: S.sectionSync,
                subtitle: syncSubtitle,
                subtitleColor: syncSubtitleColor,
                onTap: () => context.push('/more/sync'),
              ),
            ]),
            // Account.
            const SectionLabel(S.sectionAccount),
            SettingsSection(children: [
              NavigationRow(
                icon: Icons.person_outline_rounded,
                label: S.settingsProfile,
                subtitle: signedInName,
                onTap: () => context.push('/more/profile'),
              ),
              NavigationRow(
                icon: Icons.shield_outlined,
                label: S.settingsSecurity,
                onTap: () => context.push('/more/security'),
              ),
              NavigationRow(
                icon: Icons.notifications_none_rounded,
                label: S.settingsNotifications,
                onTap: () => context.push('/more/notifications'),
              ),
            ]),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: signingOut ? null : _confirmSignOut,
              style: OutlinedButton.styleFrom(
                foregroundColor: c.crit,
                side: BorderSide(color: c.crit),
              ),
              icon: const Icon(Icons.logout_rounded),
              label: const Text(S.signOut),
            ),
            // Organization.
            const SectionLabel(S.sectionOrg),
            SettingsSection(children: [
              NavigationRow(
                icon: Icons.apartment_rounded,
                label: S.settingsOrg,
                onTap: () => context.push('/more/org'),
              ),
            ]),
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
    // One implementation, shared with the account screen: the request, the
    // duplicate-tap guard, the clearing of the session providers and the
    // departure all live in `signOutAndLeave`.
    await signOutAndLeave(context, ref);
  }
}

const _motionLevelLabels = <MotionLevel, String>{
  MotionLevel.performance: S.settingsMotionPerformance,
  MotionLevel.low: S.settingsMotionLow,
  MotionLevel.balanced: S.settingsMotionBalanced,
  MotionLevel.high: S.settingsMotionHigh,
  MotionLevel.maximum: S.settingsMotionMaximum,
};

String _motionLevelLabel(MotionLevel level) => _motionLevelLabels[level]!;

const _frameRateLabels = <FrameRatePreference, String>{
  FrameRatePreference.auto: S.settingsFrameRateAuto,
  FrameRatePreference.fps30: S.settingsFrameRate30,
  FrameRatePreference.fps60: S.settingsFrameRate60,
  FrameRatePreference.fps90: S.settingsFrameRate90,
  FrameRatePreference.fps120: S.settingsFrameRate120,
};

String _frameRateLabel(FrameRatePreference rate) => _frameRateLabels[rate]!;
