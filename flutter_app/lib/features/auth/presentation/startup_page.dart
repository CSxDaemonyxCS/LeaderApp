import 'package:flutter/material.dart';

import '../../../core/app_info.dart';
import '../../../core/motion/motion_tokens.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/strings.dart';

/// What the app shows while it is still deciding where this launch belongs.
///
/// **The problem it solves.** `initialLocation` used to be `/home`, and the
/// session read is asynchronous, so a cold start rendered the tenant dashboard
/// — its app bar, its bottom nav, its repository reads — for as long as the
/// restore took, and then redirected. For a signed-out person that was a flash
/// of an authenticated screen; for a Super Admin it was a flash of the wrong
/// product. This is the neutral surface the router holds on instead, and it is
/// the app's `initialLocation` now.
///
/// **What it deliberately is not.** Not a cinematic splash. It carries the
/// mark, one line of copy and a thin progress bar, because the restore it
/// covers is a **local** read that usually finishes in a frame or two — a
/// staged animation would turn "already done" into "please wait", which is the
/// opposite of the point. Nothing here delays routing: the redirect fires the
/// instant the classifier changes its mind, whatever this screen is drawing.
///
/// **It says nothing about the network**, because the restore does not use
/// one, and it shows no account, organisation or last-opened screen, because a
/// launch that has not established a session must not be able to leak the
/// previous one's.
class StartupPage extends StatelessWidget {
  const StartupPage({super.key});

  /// The app's `initialLocation`.
  ///
  /// Duplicated from `StartupDestination.restoring.location` because a `const`
  /// field cannot read an enum member, and the router needs a const path.
  /// `startup_classifier_test.dart` fails if the two ever disagree — the same
  /// treatment `UpgradeRequiredPage.location` gets.
  static const String location = '/startup';

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = Theme.of(context).textTheme;
    // An indeterminate bar is **looping ambience** — a controller that runs
    // for as long as the screen is up — so it answers to the same flag the
    // skeleton shimmer and the lock-window halo do, rather than to a bespoke
    // check. `motionSpec` folds in `MediaQuery.disableAnimations` on top of
    // the user's level, so a reduce-motion device and the lowest performance
    // preset both land here with a static track.
    final loops = motionSpec(context).ambientLoops;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  AppInfo.logoAsset,
                  height: 96,
                  fit: BoxFit.contain,
                  // The mark is decoration here: the sentence below it is what
                  // a screen reader should announce.
                  excludeFromSemantics: true,
                ),
                const SizedBox(height: AppSpacing.xxl),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    S.startupRestoring,
                    style: t.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  S.startupRestoringSub,
                  style: t.bodySmall?.copyWith(color: c.ink3),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxl),
                SizedBox(
                  width: 160,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    child: LinearProgressIndicator(
                      minHeight: 4,
                      // A determinate bar at zero is a static track: the same
                      // widget, the same size, no controller.
                      value: loops ? null : 0,
                      backgroundColor: c.surface2,
                      color: c.primary,
                    ),
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
