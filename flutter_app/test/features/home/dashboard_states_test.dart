import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mtm/core/access/capability.dart';
import 'package:mtm/core/access/capability_guard.dart';
import 'package:mtm/core/result/result.dart';
import 'package:mtm/core/sync/outbox_controller.dart';
import 'package:mtm/core/sync/outbox_store.dart';
import 'package:mtm/core/sync/pending_operation.dart';
import 'package:mtm/core/sync/sync_state.dart';
import 'package:mtm/core/theme/app_palette.dart';
import 'package:mtm/core/theme/app_theme.dart';
import 'package:mtm/core/widgets/offline_banner.dart';
import 'package:mtm/features/detachment/domain/detachment_models.dart';
import 'package:mtm/features/detachment/domain/storage_status.dart';
import 'package:mtm/features/home/data/home_providers.dart';
import 'package:mtm/features/home/domain/home_models.dart';
import 'package:mtm/features/home/presentation/home_page.dart';
import 'package:mtm/features/notification/data/notification_providers.dart';
import 'package:mtm/features/notification/domain/notification_models.dart';
import 'package:mtm/features/shift/domain/shift_models.dart';
import 'package:mtm/features/team/domain/team_models.dart';
import 'package:mtm/l10n/strings.dart';

/// The dashboard states a person cannot reliably produce by hand: no
/// detachment at all, a day with no shift, a load that failed, an offline
/// device with nothing cached, queued work, a conflict waiting, and a
/// volunteer's restricted view.

const _det = 'd1';

const _detachment = Detachment(
  id: _det,
  tenantId: 't1',
  name: 'مفرزة دمشق المركزية',
  region: 'دمشق',
  mainCenter: 'مركز الشعلان',
  memberCount: 10,
  weeklyShiftCount: 7,
  coveragePercent: 80,
  status: DetachmentStatus.active,
);

const _second = Detachment(
  id: 'd2',
  tenantId: 't1',
  name: 'مفرزة ريف دمشق',
  region: 'ريف دمشق',
  mainCenter: 'مركز التل',
  memberCount: 6,
  weeklyShiftCount: 4,
  coveragePercent: 70,
  status: DetachmentStatus.active,
);

const _oneDetachment = Success<List<Detachment>>([_detachment]);

const _operator = Capabilities(scoped: {_det: Cap.scoped});
const _volunteer = Capabilities(
  scoped: {
    _det: {Cap.detachmentView, Cap.memberView}
  },
);

TeamMember _member(String id, AttendanceState state) => TeamMember(
      id: id,
      name: 'عضو $id',
      initials: 'ع',
      role: TeamRole.member,
      detachmentId: _det,
      attendance: state,
    );

/// A shift that is running "now", whenever the test happens to run.
Shift _runningNow({int needed = 2, List<TeamMember>? attendees}) {
  final now = DateTime.now();
  final start = now.subtract(const Duration(hours: 1));
  final end = now.add(const Duration(hours: 2));
  return Shift(
    id: 'sh_now',
    detachmentId: _det,
    date: dateOnly(start),
    centerName: 'مركز الشعلان',
    startMinutes: start.hour * 60 + start.minute,
    endMinutes: end.hour * 60 + end.minute,
    needed: needed,
    attendees: attendees ??
        [
          _member('a', AttendanceState.checkedIn),
          _member('b', AttendanceState.notCheckedIn),
        ],
  );
}

HomeSummary _summary({
  List<Shift> shifts = const [],
  Detachment detachment = _detachment,
}) =>
    HomeSummary(
      detachmentId: detachment.id,
      detachmentName: detachment.name,
      region: detachment.region,
      mainCenter: detachment.mainCenter,
      shifts: shifts,
      rosterCount: 10,
      storageStatus: StorageStatus.healthy,
      lowStockCount: 0,
      expiringSoonCount: 0,
    );

Future<void> _pump(
  WidgetTester tester, {
  Result<List<Detachment>> detachments = const Success([]),
  Result<HomeSummary>? summary,
  Capabilities capabilities = _operator,
  List<PendingOperation> outbox = const [],
}) async {
  // A tall surface so the whole dashboard is laid out: several assertions
  // below are about a tile being *absent*, which only means something when
  // the section it would sit in is on screen.
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        capabilitiesProvider.overrideWithValue(capabilities),
        outboxStoreProvider
            .overrideWithValue(InMemoryOutboxStore(seed: outbox)),
        dashboardDetachmentsProvider.overrideWith((ref) async => detachments),
        // The app bar's notification bell reads a feed of its own, composed
        // from the shift and inventory repositories. These tests are about
        // the dashboard, so the feed is stubbed empty rather than left to
        // fetch — the Notifications Center has its own tests.
        notificationSourceProvider.overrideWith(
          (ref, id) async => const Success<List<AppNotification>>([]),
        ),
        // Id-aware on purpose: switching detachment must actually re-point
        // the screen, which a fixed answer would hide.
        homeSummaryProvider.overrideWith(
          (ref, id) async =>
              summary ??
              Success(_summary(
                detachment: id == _second.id ? _second : _detachment,
              )),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(PaletteId.medical),
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: HomePage(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'a session with no detachment gets a designed state, not an '
      'empty screen or an error', (tester) async {
    await _pump(tester);

    expect(find.byKey(const Key('dashboard-no-detachment')), findsOneWidget);
    expect(find.text(S.dashboardNoDetachmentTitle), findsOneWidget);
    // Nothing pretends to be operational data.
    expect(find.text(S.activeShift), findsNothing);
  });

  testWidgets(
      'a detachment with no shifts today says so and offers the '
      'schedule', (tester) async {
    await _pump(tester, detachments: _oneDetachment);

    expect(find.text(S.dashboardNoShiftsToday), findsOneWidget);
    expect(find.byKey(const Key('dashboard-view-schedule')), findsOneWidget);
    expect(find.text(S.dashboardNoNextShift), findsOneWidget);
    // Nothing is wrong, and the screen says that rather than leaving a blank.
    expect(find.byKey(const Key('dashboard-alerts-clear')), findsOneWidget);
  });

  testWidgets('a running shift leads the screen with real counts',
      (tester) async {
    await _pump(
      tester,
      detachments: _oneDetachment,
      summary: Success(_summary(shifts: [_runningNow()])),
    );

    expect(find.text(S.activeShift), findsOneWidget);
    expect(find.text('مركز الشعلان'), findsWidgets);
    // One of two assigned has checked in; the other is still open.
    expect(find.textContaining('١'), findsWidgets);
    expect(
        find.byKey(const Key('dashboard-open-current-shift')), findsOneWidget);
  });

  testWidgets('a summary that fails offers a retry instead of a half screen',
      (tester) async {
    await _pump(
      tester,
      detachments: _oneDetachment,
      summary: const Failure('boom', code: 'server_error'),
    );

    expect(find.text(S.retry), findsOneWidget);
    expect(find.text(S.activeShift), findsNothing);
  });

  testWidgets('offline with nothing cached is a state, not a crash',
      (tester) async {
    await _pump(
      tester,
      detachments: _oneDetachment,
      summary: const Offline(),
    );

    expect(find.text(S.offlineTitle), findsOneWidget);
    expect(find.text(S.retry), findsOneWidget);
  });

  testWidgets('offline with a cached copy still shows the day, marked stale',
      (tester) async {
    await _pump(
      tester,
      detachments: _oneDetachment,
      summary: Offline(cached: _summary(shifts: [_runningNow()])),
    );

    expect(find.text(S.activeShift), findsOneWidget);
    expect(find.byType(StaleBadge), findsOneWidget);
  });

  testWidgets(
      'queued work and a conflict are raised as the user\'s own, '
      'whatever their grants', (tester) async {
    await _pump(
      tester,
      detachments: _oneDetachment,
      capabilities: _volunteer,
      outbox: [
        PendingOperation.create(kind: 'shift.assign', idFactory: () => 'c1')
            .copyWith(state: SyncState.conflict),
        PendingOperation.create(
            kind: 'inventory.movement.add', idFactory: () => 'p1'),
      ],
    );

    expect(
      find.byKey(const Key('dashboard-alert-needsReview')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('dashboard-alert-pendingSync')),
      findsOneWidget,
    );
  });

  testWidgets('a volunteer sees no management shortcuts and no shift action',
      (tester) async {
    await _pump(
      tester,
      detachments: _oneDetachment,
      capabilities: _volunteer,
      summary: Success(_summary(shifts: [_runningNow(needed: 5)])),
    );

    // The shift is reported…
    expect(find.text(S.activeShift), findsOneWidget);
    // …but nothing offers an action their grants would not carry.
    expect(
      find.byKey(const Key('dashboard-open-current-shift')),
      findsNothing,
    );
    expect(find.byKey(const Key('dashboard-action-stats')), findsNothing);
    // A gap they cannot staff is not raised at them either.
    expect(
      find.byKey(const Key('dashboard-alert-understaffedShift')),
      findsNothing,
    );
    // The roster is theirs to see, so that shortcut stays.
    expect(find.byKey(const Key('dashboard-action-members')), findsOneWidget);
  });

  testWidgets('two shifts short on the same day both get their own row',
      (tester) async {
    final now = DateTime.now();
    Shift short(String id, int hoursAhead) {
      final start = now.add(Duration(hours: hoursAhead));
      final end = start.add(const Duration(hours: 2));
      return Shift(
        id: id,
        detachmentId: _det,
        date: dateOnly(now),
        centerName: 'مركز $id',
        startMinutes: start.hour * 60 + start.minute,
        endMinutes: end.hour * 60 + end.minute,
        needed: 4,
        attendees: [_member('a', AttendanceState.checkedIn)],
      );
    }

    // Both rows are the same *kind*; keyed by kind alone they would collide
    // as siblings and take the screen down.
    await _pump(
      tester,
      detachments: _oneDetachment,
      summary: Success(_summary(shifts: [short('sh1', 1), short('sh2', 4)])),
    );

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const Key('dashboard-alert-understaffedShift-sh1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('dashboard-alert-understaffedShift-sh2')),
      findsOneWidget,
    );
  });

  testWidgets('one detachment offers no switcher at all', (tester) async {
    await _pump(tester, detachments: _oneDetachment);
    expect(find.byIcon(Icons.unfold_more_rounded), findsNothing);
  });

  testWidgets(
      'switching detachment re-points the dashboard at the one '
      'chosen, and the sheet closes rather than the page', (tester) async {
    await _pump(tester, detachments: const Success([_detachment, _second]));
    expect(find.text(_detachment.name), findsOneWidget);

    await tester.tap(find.byIcon(Icons.unfold_more_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dashboard-detachment-d2')));
    await tester.pumpAndSettle();

    // The dashboard is still on screen and now names the chosen detachment.
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.text(_second.name), findsOneWidget);
    expect(find.text(_detachment.name), findsNothing);
  });

  testWidgets('several detachments offer the switcher', (tester) async {
    await _pump(tester, detachments: const Success([_detachment, _second]));
    expect(find.byIcon(Icons.unfold_more_rounded), findsOneWidget);
  });
}
