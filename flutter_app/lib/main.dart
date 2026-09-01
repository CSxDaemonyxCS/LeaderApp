import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/motion/motion_level.dart';
import 'core/motion/motion_tokens.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/settings/data/motion_level_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));
  runApp(const ProviderScope(child: MtmApp()));
}

class MtmApp extends ConsumerWidget {
  const MtmApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final theme = ref.watch(themeControllerProvider);

    final motion = ref.watch(motionLevelProvider);

    return MaterialApp.router(
      title: 'MTM',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      // Global RTL + MotionScope for the whole subtree.
      builder: (context, child) {
        // While the stored setting is still loading, follow the OS: a
        // reduce-motion device must not get a burst of animation on the
        // first frames. Once hydrated, the user's own choice wins — this
        // is the only place the OS flag feeds the level.
        final level = motion.valueOrNull ??
            (osReduceMotion(context)
                ? MotionLevel.reduced
                : MotionLevel.full);
        return Directionality(
          textDirection: TextDirection.rtl,
          child: MotionScope(
            level: level,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      theme: AppTheme.light(theme.palette),
      darkTheme: AppTheme.dark(theme.palette),
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
