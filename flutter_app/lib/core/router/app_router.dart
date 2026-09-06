import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/app_version/data/app_version_providers.dart';
import '../../features/app_version/domain/app_version_models.dart';
import '../../features/app_version/presentation/upgrade_required_page.dart';
import '../../features/auth/data/auth_providers.dart';
import '../../features/auth/presentation/forgot_password_page.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/mfa_challenge_page.dart';
import '../../features/auth/presentation/mfa_setup_page.dart';
import '../../features/auth/presentation/new_device_page.dart';
import '../../features/auth/presentation/new_password_page.dart';
import '../../features/auth/presentation/otp_page.dart';
import '../../features/auth/presentation/session_expired_page.dart';
import '../../features/conflict/domain/conflict_models.dart';
import '../../features/conflict/presentation/conflict_resolution_page.dart';
import '../../features/conflict/presentation/conflict_resolution_route.dart';
import '../../features/conflict/presentation/needs_review_page.dart';
import '../../features/detachment/presentation/detachment_detail_shell.dart';
import '../../features/detachment/presentation/detachment_edit_page.dart';
import '../../features/detachment/presentation/detachment_list_page.dart';
import '../../features/detachment/presentation/detachment_member_edit_page.dart';
import '../../features/detachment/presentation/detachment_member_status_page.dart';
import '../../features/detachment/presentation/tabs/detachment_shifts_tab.dart';
import '../../features/detachment/presentation/tabs/detachment_stats_tab.dart';
import '../../features/detachment/presentation/tabs/detachment_storage_tab.dart';
import '../../features/detachment/presentation/tabs/detachment_team_tab.dart';
import '../../features/detachment/domain/report_models.dart';
import '../../features/detachment/presentation/report_export_page.dart';
import '../../features/detachment/presentation/report_preview_page.dart';
import '../../features/inventory/presentation/inventory_item_edit_page.dart';
import '../../features/notification/presentation/notifications_center_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/settings/presentation/notifications_page.dart';
import '../../features/settings/presentation/org_info_page.dart';
import '../../features/settings/presentation/performance_page.dart';
import '../../features/settings/presentation/profile_page.dart';
import '../../features/settings/presentation/security_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../features/settings/presentation/sync_page.dart';
import '../../features/settings/presentation/themes_page.dart';
import '../../features/shell/main_shell.dart';
import '../../features/tenant/presentation/tenant_edit_page.dart';
import '../../features/tenant/presentation/tenant_list_page.dart';
import '../../features/workshop/presentation/tabs/workshop_members_tab.dart';
import '../../features/workshop/presentation/tabs/workshop_stats_tab.dart';
import '../../features/workshop/presentation/tabs/workshop_team_tab.dart';
import '../../features/workshop/presentation/workshop_detail_shell.dart';
import '../../features/workshop/presentation/workshop_edit_page.dart';
import '../../features/workshop/presentation/workshop_list_page.dart';
import '../motion/transitions.dart';

// -----------------------------------------------------------------------------
// Navigator hierarchy
//
// The app runs three levels of Navigator. Every route below belongs to exactly
// one of them, and which one it belongs to is what decides whether a page
// covers the floating bottom nav or lives underneath it.
//
//   root           Auth screens, and every page that must COVER the bottom
//                  nav — the create and edit forms.
//   branch         One per bottom-nav tab. Keeps each tab's own back stack
//                  alive while the user switches tabs.
//   detail shell   One per detail surface (a detachment, a workshop). Keeps
//                  the title and the tab bar in place while the tab body swaps.
//
// The rule that keeps this file correct:
//
//   A route may set `parentNavigatorKey` as an immediate child of a plain
//   GoRoute, but never as an immediate child of a ShellRoute. go_router
//   asserts that a shell's direct children stay on that shell's own navigator,
//   and the assert runs while GoRouter is being constructed — so breaking it
//   does not misplace a single page, it throws before the app renders its
//   first frame.
//
//   Full-screen forms therefore sit BESIDE a detail shell, never inside it.
// -----------------------------------------------------------------------------

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

// One navigator per bottom-nav branch.
final _homeKey = GlobalKey<NavigatorState>(debugLabel: 'branch-home');
final _detachmentKey =
    GlobalKey<NavigatorState>(debugLabel: 'branch-detachment');
final _workshopKey = GlobalKey<NavigatorState>(debugLabel: 'branch-workshop');
final _moreKey = GlobalKey<NavigatorState>(debugLabel: 'branch-more');

// One navigator per detail shell. Naming these is not cosmetic: a ShellRoute
// without an explicit key mints an anonymous one, and then the rule above
// cannot be checked by reading the code.
final _detachmentDetailKey =
    GlobalKey<NavigatorState>(debugLabel: 'detachment-detail');
final _workshopDetailKey =
    GlobalKey<NavigatorState>(debugLabel: 'workshop-detail');

/// Every page in the app enters with the same shared-axis transition, so the
/// app has one movement vocabulary rather than a per-route grab bag.
CustomTransitionPage<T> _sharedAxisPage<T>({
  required LocalKey key,
  required Widget child,
}) =>
    CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionsBuilder: (context, animation, secondary, page) =>
          SharedAxisPageTransition(
        animation: animation,
        secondaryAnimation: secondary,
        child: page,
      ),
    );

/// Pre-session screens, and the whole of the app that a signed-out session is
/// allowed to reach.
///
/// One const map rather than eight hand-written routes, because the auth gate
/// in `redirect` needs exactly this set of locations and a second, separately
/// maintained copy of it is how a redirect loop gets shipped: forget `/otp`
/// here and a signed-out user reaching the OTP step is bounced back to
/// `/login` forever. The routes and the public set are now the same list.
///
/// They live on the root navigator, so none of them ever shows the bottom nav.
const _publicPages = <String, Widget>{
  '/login': LoginPage(),
  '/mfa-setup': MfaSetupPage(),
  '/mfa-challenge': MfaChallengePage(),
  '/forgot': ForgotPasswordPage(),
  '/otp': OtpPage(),
  '/new-password': NewPasswordPage(),
  '/session-expired': SessionExpiredPage(),
  '/new-device': NewDevicePage(),
};

List<RouteBase> get _authRoutes => [
      for (final entry in _publicPages.entries)
        GoRoute(
          path: entry.key,
          pageBuilder: (context, state) =>
              _sharedAxisPage(key: state.pageKey, child: entry.value),
        ),
    ];

/// Tab 1 — the operational summary.
StatefulShellBranch get _homeBranch => StatefulShellBranch(
      navigatorKey: _homeKey,
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) =>
              _sharedAxisPage(key: state.pageKey, child: const HomePage()),
        ),
      ],
    );

/// Tab 2 — the container hierarchy: tenants, then the detachments inside
/// one, then a detachment's own tabbed detail.
///
/// The branch has two top-level routes rather than one. `/tenant` is where
/// the tab opens; `/detachment/:id/...` is where a detachment's own surfaces
/// live. A detachment id is unique across tenants, so its detail routes do
/// not repeat the tenant in the path — but nothing detachment-*owned* gets a
/// top-level route, which is the rule `DETACHMENT-SCOPING.md` §3 actually
/// sets: there is no `/inventory` and no `/schedule`.
StatefulShellBranch get _detachmentBranch => StatefulShellBranch(
      navigatorKey: _detachmentKey,
      routes: [
        GoRoute(
          path: '/tenant',
          pageBuilder: (context, state) => _sharedAxisPage(
            key: state.pageKey,
            child: const TenantListPage(),
          ),
          routes: [
            // Full-screen forms go on the root navigator so they cover the
            // bottom nav — see the navigator rule at the top of this file.
            GoRoute(
              path: 'new',
              parentNavigatorKey: _rootKey,
              pageBuilder: (context, state) => _sharedAxisPage(
                key: state.pageKey,
                child: const TenantEditPage(id: null),
              ),
            ),
            GoRoute(
              path: ':tid/edit',
              parentNavigatorKey: _rootKey,
              pageBuilder: (context, state) => _sharedAxisPage(
                key: state.pageKey,
                child: TenantEditPage(id: state.pathParameters['tid']),
              ),
            ),
            // One tenant's detachments.
            GoRoute(
              path: ':tid',
              pageBuilder: (context, state) => _sharedAxisPage(
                key: state.pageKey,
                child: DetachmentListPage(
                  tenantId: state.pathParameters['tid'],
                ),
              ),
              routes: [
                // Creating a detachment happens *inside* a tenant, so the
                // route carries the tenant it is created into.
                GoRoute(
                  path: 'detachment/new',
                  parentNavigatorKey: _rootKey,
                  pageBuilder: (context, state) => _sharedAxisPage(
                    key: state.pageKey,
                    child: DetachmentEditPage(
                      id: null,
                      tenantId: state.pathParameters['tid'],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/detachment',
          pageBuilder: (context, state) => _sharedAxisPage(
            key: state.pageKey,
            child: const DetachmentListPage(),
          ),
          routes: [
            GoRoute(
              path: ':id/edit',
              parentNavigatorKey: _rootKey,
              pageBuilder: (context, state) => _sharedAxisPage(
                key: state.pageKey,
                child: DetachmentEditPage(id: state.pathParameters['id']),
              ),
            ),

            // The member form, for the same reason: it is a full-screen page
            // with its own app bar, so it covers the bottom nav and stays a
            // sibling of the detail shell rather than a child of it.
            GoRoute(
              path: ':id/member/new',
              parentNavigatorKey: _rootKey,
              pageBuilder: (context, state) => _sharedAxisPage(
                key: state.pageKey,
                child: DetachmentMemberEditPage(
                  detachmentId: state.pathParameters['id']!,
                  memberId: null,
                ),
              ),
            ),
            GoRoute(
              path: ':id/member/:memberId/edit',
              parentNavigatorKey: _rootKey,
              pageBuilder: (context, state) => _sharedAxisPage(
                key: state.pageKey,
                child: DetachmentMemberEditPage(
                  detachmentId: state.pathParameters['id']!,
                  memberId: state.pathParameters['memberId'],
                ),
              ),
            ),

            // The member's attendance history — opened from the roster card.
            // A full-screen page with its own app bar, so a sibling of the
            // detail shell rather than a child of it.
            GoRoute(
              path: ':id/member/:memberId/status',
              parentNavigatorKey: _rootKey,
              pageBuilder: (context, state) => _sharedAxisPage(
                key: state.pageKey,
                child: DetachmentMemberStatusPage(
                  detachmentId: state.pathParameters['id']!,
                  memberId: state.pathParameters['memberId']!,
                ),
              ),
            ),

            // Stock items are detachment-owned, so their form extends the
            // detachment path rather than taking one of its own.
            GoRoute(
              path: ':id/storage/new',
              parentNavigatorKey: _rootKey,
              pageBuilder: (context, state) => _sharedAxisPage(
                key: state.pageKey,
                child: InventoryItemEditPage(
                  detachmentId: state.pathParameters['id']!,
                  itemId: null,
                ),
              ),
            ),
            GoRoute(
              path: ':id/storage/:itemId/edit',
              parentNavigatorKey: _rootKey,
              pageBuilder: (context, state) => _sharedAxisPage(
                key: state.pageKey,
                child: InventoryItemEditPage(
                  detachmentId: state.pathParameters['id']!,
                  itemId: state.pathParameters['itemId'],
                ),
              ),
            ),

            // The report composer: pick what goes in the file, preview it,
            // export it.
            GoRoute(
              path: ':id/report',
              parentNavigatorKey: _rootKey,
              pageBuilder: (context, state) => _sharedAxisPage(
                key: state.pageKey,
                child: ReportExportPage(
                  detachmentId: state.pathParameters['id']!,
                ),
              ),
              routes: [
                // The spec travels in `extra` rather than the query string:
                // it is a set of eight flags plus two enums, and a URL that
                // encodes it is neither shareable nor readable.
                GoRoute(
                  path: 'preview',
                  parentNavigatorKey: _rootKey,
                  pageBuilder: (context, state) => _sharedAxisPage(
                    key: state.pageKey,
                    child: ReportPreviewPage(
                      detachmentId: state.pathParameters['id']!,
                      spec: state.extra as ReportSpec? ?? ReportSpec.initial,
                    ),
                  ),
                ),
              ],
            ),

            // One detachment, four tabs. The shell holds the title and the
            // tab bar; only `child` swaps as the tab changes.
            ShellRoute(
              navigatorKey: _detachmentDetailKey,
              pageBuilder: (context, state, child) => _sharedAxisPage(
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
                  builder: (context, state) => DetachmentTeamTab(
                    detachmentId: state.pathParameters['id']!,
                  ),
                ),
                GoRoute(
                  path: ':id/shifts',
                  builder: (context, state) => DetachmentShiftsTab(
                    detachmentId: state.pathParameters['id']!,
                  ),
                ),
                GoRoute(
                  path: ':id/storage',
                  builder: (context, state) => DetachmentStorageTab(
                    detachmentId: state.pathParameters['id']!,
                  ),
                ),
                GoRoute(
                  path: ':id/stats',
                  builder: (context, state) => DetachmentStatsTab(
                    detachmentId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );

/// Tab 3 — workshops. Deliberately the same shape as the detachment branch;
/// the two detail surfaces must feel identical.
StatefulShellBranch get _workshopBranch => StatefulShellBranch(
      navigatorKey: _workshopKey,
      routes: [
        GoRoute(
          path: '/workshop',
          pageBuilder: (context, state) => _sharedAxisPage(
            key: state.pageKey,
            child: const WorkshopListPage(),
          ),
          routes: [
            GoRoute(
              path: 'new',
              parentNavigatorKey: _rootKey,
              pageBuilder: (context, state) => _sharedAxisPage(
                key: state.pageKey,
                child: const WorkshopEditPage(id: null),
              ),
            ),
            GoRoute(
              path: ':id/edit',
              parentNavigatorKey: _rootKey,
              pageBuilder: (context, state) => _sharedAxisPage(
                key: state.pageKey,
                child: WorkshopEditPage(id: state.pathParameters['id']),
              ),
            ),
            ShellRoute(
              navigatorKey: _workshopDetailKey,
              pageBuilder: (context, state, child) => _sharedAxisPage(
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
                  builder: (context, state) => WorkshopTeamTab(
                    workshopId: state.pathParameters['id']!,
                  ),
                ),
                GoRoute(
                  path: ':id/members',
                  builder: (context, state) => WorkshopMembersTab(
                    workshopId: state.pathParameters['id']!,
                  ),
                ),
                GoRoute(
                  path: ':id/stats',
                  builder: (context, state) => WorkshopStatsTab(
                    workshopId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );

/// Tab 4 — settings and the account pages behind it. These stay inside the
/// branch, so the bottom nav remains visible while the user drills in.
StatefulShellBranch get _moreBranch => StatefulShellBranch(
      navigatorKey: _moreKey,
      routes: [
        GoRoute(
          path: '/more',
          pageBuilder: (context, state) =>
              _sharedAxisPage(key: state.pageKey, child: const SettingsPage()),
          routes: [
            GoRoute(
              path: 'themes',
              pageBuilder: (context, state) => _sharedAxisPage(
                key: state.pageKey,
                child: const ThemesPage(),
              ),
            ),
            GoRoute(
              path: 'performance',
              pageBuilder: (context, state) => _sharedAxisPage(
                key: state.pageKey,
                child: const PerformancePage(),
              ),
            ),
            GoRoute(
              path: 'sync',
              pageBuilder: (context, state) => _sharedAxisPage(
                key: state.pageKey,
                child: const SyncPage(),
              ),
            ),
            GoRoute(
              path: 'profile',
              pageBuilder: (context, state) => _sharedAxisPage(
                key: state.pageKey,
                child: const ProfilePage(),
              ),
            ),
            GoRoute(
              path: 'security',
              pageBuilder: (context, state) => _sharedAxisPage(
                key: state.pageKey,
                child: const SecurityPage(),
              ),
            ),
            GoRoute(
              path: 'notifications',
              pageBuilder: (context, state) => _sharedAxisPage(
                key: state.pageKey,
                child: const NotificationsPage(),
              ),
            ),
            GoRoute(
              path: 'org',
              pageBuilder: (context, state) => _sharedAxisPage(
                key: state.pageKey,
                child: const OrgInfoPage(),
              ),
            ),
          ],
        ),
      ],
    );

final appRouterProvider = Provider<GoRouter>((ref) {
  // The forced-upgrade gate, handed to GoRouter as a listenable rather than
  // read through `ref.watch`: watching would rebuild the whole GoRouter on
  // every change and throw away the navigation stack with it. This way the
  // router is built once and a change only re-runs `redirect`.
  final gate = ValueNotifier<AppVersionState>(ref.read(appVersionProvider));
  ref.listen<AppVersionState>(
    appVersionProvider,
    (_, next) => gate.value = next,
  );
  ref.onDispose(gate.dispose);

  // The auth gate, held the same way and for the same reason: a signed-out
  // session must not be able to reach a protected screen through navigation
  // history, a preserved bottom-nav branch stack, or a deep link. Sign-out
  // itself only clears the session — this is what makes the clearing stick.
  final auth = ValueNotifier<AuthGate>(ref.read(authGateProvider));
  ref.listen<AuthGate>(authGateProvider, (_, next) => auth.value = next);
  ref.onDispose(auth.dispose);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/home',
    debugLogDiagnostics: false,
    refreshListenable: Listenable.merge([gate, auth]),
    // The one place the app can be shut. `redirect` runs on every
    // navigation — a tab, a deep link, a `context.go` from anywhere — so
    // while the gate is closed there is no route into the app to find, and
    // nothing to pop back to when it opens again.
    redirect: (context, state) {
      final atGate = state.matchedLocation == UpgradeRequiredPage.location;
      if (gate.value.blocksApp) {
        return atGate ? null : UpgradeRequiredPage.location;
      }
      if (atGate) return '/home';

      // The auth gate runs second: being signed in is no help while the app
      // is shut, and the upgrade screen is reachable without a session.
      //
      // `unknown` deliberately redirects nowhere. The session read is async,
      // so every cold start passes through it, and an offline device with no
      // cached account is not evidence that anyone signed out — bouncing
      // either case to the login screen would break the app for exactly the
      // conditions it is built for. `capabilitiesProvider` still resolves to
      // `Capabilities.none` throughout, so nothing gated is offered.
      //
      // TODO(security): a UX gate. The backend rejects an unauthenticated
      // request whatever the client chose to render.
      final destination = switch (auth.value) {
        AuthGate.signedOut => '/login',
        AuthGate.expired => '/session-expired',
        AuthGate.signedIn || AuthGate.unknown => null,
      };
      if (destination == null) return null;
      // Already somewhere a signed-out session belongs.
      if (_publicPages.containsKey(state.matchedLocation)) return null;
      return destination;
    },
    routes: [
      // Root navigator, so it covers the bottom nav and every other surface.
      GoRoute(
        path: UpgradeRequiredPage.location,
        pageBuilder: (context, state) => _sharedAxisPage(
          key: state.pageKey,
          child: const UpgradeRequiredPage(),
        ),
      ),
      // A substantial decision surface that must cover the bottom nav. Auto
      // Sync must never push this route; Manual Sync, a future review list,
      // and direct feature flows may open it with typed route arguments.
      GoRoute(
        path: ConflictResolutionPage.routePath,
        pageBuilder: (context, state) {
          final args = state.extra;
          return _sharedAxisPage(
            key: state.pageKey,
            // Entered without its typed arguments — a restored deep link, a
            // relaunch — the route rebuilds the conflict from the stored
            // review metadata rather than dead-ending. See
            // `ConflictResolutionRoute`.
            child: ConflictResolutionRoute(
              conflictId: state.pathParameters['conflictId'],
              args: args is ConflictResolutionRouteArgs ? args : null,
            ),
          );
        },
      ),
      // The Notifications Center. A root route beside the Needs Review inbox
      // and for the same reason: a full surface the user opens deliberately,
      // which therefore covers the bottom nav. Reached from the bell in the
      // dashboard's app bar — the app's single entry point into it.
      GoRoute(
        path: NotificationsCenterPage.routePath,
        pageBuilder: (context, state) => _sharedAxisPage(
          key: state.pageKey,
          child: const NotificationsCenterPage(),
        ),
      ),
      // The Needs Review inbox. A root route for the same reason the screen
      // it leads to is one — a substantial decision surface that covers the
      // bottom nav — and reachable only from an explicit human action (the
      // Settings attention row). Auto Sync still cannot navigate anywhere.
      GoRoute(
        path: NeedsReviewPage.routePath,
        pageBuilder: (context, state) => _sharedAxisPage(
          key: state.pageKey,
          child: const NeedsReviewPage(),
        ),
      ),
      ..._authRoutes,
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          _homeBranch,
          _detachmentBranch,
          _workshopBranch,
          _moreBranch,
        ],
      ),
    ],
  );
});
