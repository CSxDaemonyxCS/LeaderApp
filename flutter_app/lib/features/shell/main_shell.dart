import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/glass_bottom_nav.dart';
import '../../l10n/strings.dart';

/// Hosts the four bottom-nav branches. The glass bar floats above content.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    const destinations = [
      GlassNavDestination(icon: Icons.home_rounded, label: S.navHome),
      GlassNavDestination(icon: Icons.flag_rounded, label: S.navDetachment),
      GlassNavDestination(icon: Icons.school_rounded, label: S.navWorkshop),
      GlassNavDestination(icon: Icons.more_horiz_rounded, label: S.navMore),
    ];

    return Scaffold(
      // The nav floats above the body via a Stack, not the classic
      // bottomNavigationBar slot, so it doesn't push content up.
      body: Stack(
        children: [
          Positioned.fill(child: navigationShell),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: GlassBottomNav(
              destinations: destinations,
              currentIndex: navigationShell.currentIndex,
              onDestinationSelected: (i) => navigationShell.goBranch(
                i,
                initialLocation: i == navigationShell.currentIndex,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Media query bottom padding to add inside scrolling screens so the
/// floating bar never covers content.
class FloatingNavPadding extends StatelessWidget {
  const FloatingNavPadding({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(
          bottom: 96 + MediaQuery.of(context).padding.bottom,
        ),
        child: child,
      );
}
