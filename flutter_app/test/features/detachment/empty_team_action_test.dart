import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mtm/core/access/capability.dart';
import 'package:mtm/core/access/capability_guard.dart';
import 'package:mtm/core/theme/app_palette.dart';
import 'package:mtm/core/theme/app_theme.dart';
import 'package:mtm/features/detachment/presentation/tabs/detachment_team_tab.dart';
import 'package:mtm/l10n/strings.dart';

/// A detachment created at runtime gets an id that appears in no seeded
/// capability grant. That is what used to hide "Add member": the roster was
/// empty *and* the gate resolved to false, so the empty state offered nothing.
const _runtimeDetachment = 'runtime_detachment';

Future<void> _pumpTab(
  WidgetTester tester, {
  required Capabilities capabilities,
}) async {
  final router = GoRouter(
    initialLocation: '/detachment/$_runtimeDetachment',
    routes: [
      GoRoute(
        path: '/detachment/:id',
        builder: (context, state) => const Scaffold(
          body: DetachmentTeamTab(detachmentId: _runtimeDetachment),
        ),
        routes: [
          GoRoute(
            path: 'member/new',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('member form'))),
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        capabilitiesProvider.overrideWithValue(capabilities),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light(PaletteId.slate),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'a newly created empty detachment explains itself and offers '
      'a working Add Member action', (tester) async {
    await _pumpTab(tester, capabilities: const Capabilities(global: Cap.all));

    // The empty state says what is missing and why the screen is blank.
    expect(find.text(S.emptyTeam), findsOneWidget);
    expect(find.text(S.emptyTeamSub), findsOneWidget);

    // The action is present, hit-testable, and actually opens the form.
    final add = find.text(S.addMember);
    expect(add, findsOneWidget);
    expect(add.hitTestable(), findsOneWidget);
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(find.text('member form'), findsOneWidget);
  });

  testWidgets('the organisation-wide grant is what keeps the action alive',
      (tester) async {
    // The old mock granted the scoped keys over the seeded detachment ids
    // only. Reproduced here: a real grant that simply does not mention this
    // detachment leaves the empty state with no action at all.
    await _pumpTab(
      tester,
      capabilities: const Capabilities(
        scoped: {'d_dam_central': Cap.scoped},
      ),
    );
    expect(find.text(S.emptyTeam), findsOneWidget);
    expect(find.text(S.addMember), findsNothing);
  });
}
