import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/motion/transitions.dart';
import '../../core/widgets/glass_bottom_nav.dart';
import '../../core/widgets/swipe_tabs.dart';
import '../../l10n/strings.dart';

/// Hosts the four bottom-nav branches. The glass bar floats above content.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  /// The four branch root locations, in branch order.
  ///
  /// Swiping between branches is only offered while one of these is the
  /// current page. Drilled in — a tenant's detachments, a member form, the
  /// profile page — a horizontal swipe would jump the user out of the stack
  /// they are working in, which is not what the gesture means anywhere else
  /// in the app.
  static const _branchRoots = ['/home', '/tenant', '/workshop', '/more'];

  @override
  Widget build(BuildContext context) {
    const destinations = [
      GlassNavDestination(icon: Icons.home_rounded, label: S.navHome),
      GlassNavDestination(icon: Icons.flag_rounded, label: S.navTenants),
      GlassNavDestination(icon: Icons.school_rounded, label: S.navWorkshop),
      GlassNavDestination(icon: Icons.more_horiz_rounded, label: S.navMore),
    ];

    final index = navigationShell.currentIndex;
    final atBranchRoot =
        _branchRoots.contains(GoRouterState.of(context).uri.path);

    return Scaffold(
      // The nav floats above the body via a Stack, not the classic
      // bottomNavigationBar slot, so it doesn't push content up.
      body: Stack(
        children: [
          Positioned.fill(
            // Same gesture and the same direction rule as the detail-shell
            // tabs. A detail shell nested inside a branch has its own
            // SwipeTabs, and being deeper in the tree it wins the gesture
            // arena — so swiping a detachment's tabs never also moves the
            // bottom nav.
            child: SwipeTabs(
              currentIndex: index,
              tabCount: destinations.length,
              enabled: atBranchRoot,
              onSwitch: (i) => navigationShell.goBranch(i),
              child: TabSwitchTransition(
                index: index,
                child: navigationShell,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: GlassBottomNav(
              destinations: destinations,
              currentIndex: index,
              onDestinationSelected: (i) => navigationShell.goBranch(
                i,
                initialLocation: i == index,
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
