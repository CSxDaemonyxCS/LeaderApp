import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/motion/motion_level.dart';
import 'core/motion/motion_tokens.dart';
import 'core/router/app_router.dart';
import 'core/sync/sync_scheduler.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/conflict/data/conflict_review_recording.dart';
import 'features/settings/data/frame_rate_provider.dart';
import 'features/settings/data/motion_level_provider.dart';
import 'features/shift/data/shift_conflict_review.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));
  // The composition root installs the conflict feature's review recorder
  // over `core/sync`'s no-op hook, and the Shift feature's composer/applier
  // over `features/conflict`'s empty registries, so a conflict classified by
  // Auto Sync can store safe review metadata — and a later `useCurrent` can
  // apply it — for the Needs Review inbox without core sync or the generic
  // conflict feature ever importing a feature themselves.
  runApp(ProviderScope(
    overrides: [
      ...conflictReviewOverrides,
      ...shiftConflictReviewOverrides,
    ],
    child: const MtmApp(),
  ));
}

bool shouldUseImmersiveSystemUi({
  required bool isWeb,
  required TargetPlatform platform,
}) =>
    !isWeb && platform == TargetPlatform.android;

class MtmApp extends ConsumerStatefulWidget {
  const MtmApp({super.key});

  @override
  ConsumerState<MtmApp> createState() => _MtmAppState();
}

class _MtmAppState extends ConsumerState<MtmApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _applyAndroidSystemUi();
    // Auto Sync is the primary path: once the app is up, ask the
    // coordinator to drain anything left pending from a previous run. It is
    // a no-op when the outbox is empty.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(syncSchedulerProvider).onAppStart(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _applyAndroidSystemUi();
      ref.read(syncSchedulerProvider).onAppResumed();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _applyAndroidSystemUi() async {
    if (!shouldUseImmersiveSystemUi(
      isWeb: kIsWeb,
      platform: defaultTargetPlatform,
    )) {
      return;
    }
    // Android's supported sticky transient-reveal behavior is exposed by
    // immersiveSticky. Flutter applies it once here and again on resume,
    // never during build or while a text field/dialog is interacting. The
    // mode hides both system bars; an edge swipe reveals them temporarily.
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final theme = ref.watch(themeStateProvider);

    final motion = ref.watch(motionLevelProvider);
    // Watched, not read: the platform forgets the refresh-rate preference
    // between launches, and this provider's `build` is what restores it.
    // Nothing is rendered from the value — the display is the output.
    ref.watch(frameRateProvider);

    return MaterialApp.router(
      title: 'MTM',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      // Global RTL + MotionScope for the whole subtree.
      builder: (context, child) {
        // While the stored setting is still loading, follow the OS: a
        // reduce-motion device must not get a burst of animation on the
        // first frames. Once hydrated the user's own choice picks the
        // quality level — but it never overrides the accessibility flag
        // itself, which `motionSpec` applies on top of whatever is chosen.
        final level = motion.valueOrNull ??
            (osReduceMotion(context)
                ? MotionLevel.performance
                : MotionLevel.balanced);
        return Directionality(
          textDirection: TextDirection.rtl,
          child: MotionScope(
            level: level,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      theme: AppTheme.light(theme.palette, eyeProtect: theme.eyeProtect),
      darkTheme: AppTheme.dark(theme.palette, eyeProtect: theme.eyeProtect),
      themeMode: theme.mode,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
