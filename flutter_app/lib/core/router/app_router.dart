import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/forgot_password_page.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/mfa_challenge_page.dart';
import '../../features/auth/presentation/mfa_setup_page.dart';
import '../../features/auth/presentation/new_device_page.dart';
import '../../features/auth/presentation/new_password_page.dart';
import '../../features/auth/presentation/otp_page.dart';
import '../../features/auth/presentation/session_expired_page.dart';
import '../../features/detachment/presentation/detachment_detail_shell.dart';
import '../../features/detachment/presentation/detachment_edit_page.dart';
import '../../features/detachment/presentation/detachment_list_page.dart';
import '../../features/detachment/presentation/tabs/detachment_shifts_tab.dart';
import '../../features/detachment/presentation/tabs/detachment_stats_tab.dart';
import '../../features/detachment/presentation/tabs/detachment_storage_tab.dart';
import '../../features/detachment/presentation/tabs/detachment_team_tab.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/settings/presentation/notifications_page.dart';
import '../../features/settings/presentation/org_info_page.dart';
import '../../features/settings/presentation/profile_page.dart';
import '../../features/settings/presentation/security_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../features/workshop/presentation/tabs/workshop_members_tab.dart';
import '../../features/workshop/presentation/tabs/workshop_stats_tab.dart';
import '../../features/workshop/presentation/tabs/workshop_team_tab.dart';
import '../../features/workshop/presentation/workshop_detail_shell.dart';
import '../../features/workshop/presentation/workshop_edit_page.dart';
import '../../features/workshop/presentation/workshop_list_page.dart';
import '../motion/transitions.dart';
import '../../features/shell/main_shell.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _homeKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _detachKey = GlobalKey<NavigatorState>(debugLabel: 'detach');
final _workKey = GlobalKey<NavigatorState>(debugLabel: 'work');
final _moreKey = GlobalKey<NavigatorState>(debugLabel: 'more');

/// Shared-axis transition builder used by every top-level route.
CustomTransitionPage<T> _sharedAxis<T>({
  required Widget child,
  required LocalKey key,
}) =>
    CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionsBuilder: (context, animation, secondary, ch) =>
          SharedAxisPageTransition(
        animation: animation,
        secondaryAnimation: secondary,
        child: ch,
      ),
    );

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/home',
    debugLogDiagnostics: false,
    routes: [
      // ------- Auth (outside the shell) -------
      GoRoute(
        path: '/login',
        pageBuilder: (c, s) =>
            _sharedAxis(key: s.pageKey, child: const LoginPage()),
      ),
      GoRoute(
        path: '/mfa-setup',
        pageBuilder: (c, s) =>
            _sharedAxis(key: s.pageKey, child: const MfaSetupPage()),
      ),
      GoRoute(
        path: '/mfa-challenge',
        pageBuilder: (c, s) =>
            _sharedAxis(key: s.pageKey, child: const MfaChallengePage()),
      ),
      GoRoute(
        path: '/forgot',
        pageBuilder: (c, s) =>
            _sharedAxis(key: s.pageKey, child: const ForgotPasswordPage()),
      ),
      GoRoute(
        path: '/otp',
        pageBuilder: (c, s) =>
            _sharedAxis(key: s.pageKey, child: const OtpPage()),
      ),
      GoRoute(
        path: '/new-password',
        pageBuilder: (c, s) =>
            _sharedAxis(key: s.pageKey, child: const NewPasswordPage()),
      ),
      GoRoute(
        path: '/session-expired',
        pageBuilder: (c, s) =>
            _sharedAxis(key: s.pageKey, child: const SessionExpiredPage()),
      ),
      GoRoute(
        path: '/new-device',
        pageBuilder: (c, s) =>
            _sharedAxis(key: s.pageKey, child: const NewDevicePage()),
      ),

      // ------- Main shell with bottom nav -------
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          // Home
          StatefulShellBranch(
            navigatorKey: _homeKey,
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (c, s) =>
                    _sharedAxis(key: s.pageKey, child: const HomePage()),
              ),
            ],
          ),
          // Detachment: list -> detail (with 4 tabs, each own path)
          StatefulShellBranch(
            navigatorKey: _detachKey,
            routes: [
              GoRoute(
                path: '/detachment',
                pageBuilder: (c, s) => _sharedAxis(
                  key: s.pageKey,
                  child: const DetachmentListPage(),
                ),
                routes: [
                  GoRoute(
                    path: 'new',
                    parentNavigatorKey: _rootKey,
                    pageBuilder: (c, s) => _sharedAxis(
                      key: s.pageKey,
                      child: const DetachmentEditPage(id: null),
                    ),
                  ),
                  ShellRoute(
                    pageBuilder: (context, state, child) => _sharedAxis(
                      key: state.pageKey,
                      child: DetachmentDetailShell(
                        detachmentId: state.pathParameters['id']!,
                        location: state.uri.toString(),
                        child: child,
                      ),
                    ),
                    routes: [
                      GoRoute(
                        path: ':id/team',
                        builder: (c, s) => DetachmentTeamTab(
                          detachmentId: s.pathParameters['id']!,
                        ),
                      ),
                      GoRoute(
                        path: ':id/shifts',
                        builder: (c, s) => DetachmentShiftsTab(
                          detachmentId: s.pathParameters['id']!,
                        ),
                      ),
                      GoRoute(
                        path: ':id/storage',
                        builder: (c, s) => DetachmentStorageTab(
                          detachmentId: s.pathParameters['id']!,
                        ),
                      ),
                      GoRoute(
                        path: ':id/stats',
                        builder: (c, s) => DetachmentStatsTab(
                          detachmentId: s.pathParameters['id']!,
                        ),
                      ),
                      GoRoute(
                        path: ':id/edit',
                        parentNavigatorKey: _rootKey,
                        pageBuilder: (c, s) => _sharedAxis(
                          key: s.pageKey,
                          child: DetachmentEditPage(
                              id: s.pathParameters['id']),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // Workshop: list -> detail (with 3 tabs)
          StatefulShellBranch(
            navigatorKey: _workKey,
            routes: [
              GoRoute(
                path: '/workshop',
                pageBuilder: (c, s) => _sharedAxis(
                  key: s.pageKey,
                  child: const WorkshopListPage(),
                ),
                routes: [
                  GoRoute(
                    path: 'new',
                    parentNavigatorKey: _rootKey,
                    pageBuilder: (c, s) => _sharedAxis(
                      key: s.pageKey,
                      child: const WorkshopEditPage(id: null),
                    ),
                  ),
                  ShellRoute(
                    pageBuilder: (context, state, child) => _sharedAxis(
                      key: state.pageKey,
                      child: WorkshopDetailShell(
                        workshopId: state.pathParameters['id']!,
                        location: state.uri.toString(),
                        child: child,
                      ),
                    ),
                    routes: [
                      GoRoute(
                        path: ':id/team',
                        builder: (c, s) => WorkshopTeamTab(
                          workshopId: s.pathParameters['id']!,
                        ),
                      ),
                      GoRoute(
                        path: ':id/members',
                        builder: (c, s) => WorkshopMembersTab(
                          workshopId: s.pathParameters['id']!,
                        ),
                      ),
                      GoRoute(
                        path: ':id/stats',
                        builder: (c, s) => WorkshopStatsTab(
                          workshopId: s.pathParameters['id']!,
                        ),
                      ),
                      GoRoute(
                        path: ':id/edit',
                        parentNavigatorKey: _rootKey,
                        pageBuilder: (c, s) => _sharedAxis(
                          key: s.pageKey,
                          child: WorkshopEditPage(id: s.pathParameters['id']),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // More
          StatefulShellBranch(
            navigatorKey: _moreKey,
            routes: [
              GoRoute(
                path: '/more',
                pageBuilder: (c, s) =>
                    _sharedAxis(key: s.pageKey, child: const SettingsPage()),
                routes: [
                  GoRoute(
                    path: 'profile',
                    pageBuilder: (c, s) => _sharedAxis(
                        key: s.pageKey, child: const ProfilePage()),
                  ),
                  GoRoute(
                    path: 'security',
                    pageBuilder: (c, s) => _sharedAxis(
                        key: s.pageKey, child: const SecurityPage()),
                  ),
                  GoRoute(
                    path: 'notifications',
                    pageBuilder: (c, s) => _sharedAxis(
                        key: s.pageKey, child: const NotificationsPage()),
                  ),
                  GoRoute(
                    path: 'org',
                    pageBuilder: (c, s) => _sharedAxis(
                        key: s.pageKey, child: const OrgInfoPage()),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
