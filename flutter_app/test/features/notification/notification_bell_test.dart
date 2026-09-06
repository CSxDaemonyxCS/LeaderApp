import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mtm/core/access/capability.dart';
import 'package:mtm/core/access/capability_guard.dart';
import 'package:mtm/core/motion/animated_counter.dart';
import 'package:mtm/core/result/result.dart';
import 'package:mtm/core/theme/app_palette.dart';
import 'package:mtm/core/theme/app_theme.dart';
import 'package:mtm/features/detachment/domain/detachment_models.dart';
import 'package:mtm/features/detachment/domain/storage_status.dart';
import 'package:mtm/features/home/data/home_providers.dart';
import 'package:mtm/features/home/domain/home_models.dart';
import 'package:mtm/features/home/presentation/home_page.dart';
import 'package:mtm/features/notification/data/notification_providers.dart';
import 'package:mtm/features/notification/domain/notification_models.dart';
import 'package:mtm/features/notification/domain/notification_repository.dart';

/// The dashboard's bell: the app's one entry point into the Notifications
/// Center, and the badge that must agree with the list behind it.

const _det = 'd1';
const _operator = Capabilities(scoped: {_det: Cap.scoped});

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

class _FakeRepository implements NotificationRepository {
  _FakeRepository(this.rows);
  final List<AppNotification> rows;

  @override
  Future<Result<List<AppNotification>>> feed(String detachmentId) async =>
      Success(rows);
}

List<AppNotification> _rows(int count) => [
      for (var i = 0; i < count; i++)
        AppNotification(
          id: 'stockLow:i_$i',
          kind: NotificationKind.stockLow,
          occurredAt: DateTime.now(),
          count: 1,
          recordLabel: 'صنف $i',
          target: const StorageTarget(detachmentId: _det, itemId: 'i_0'),
        ),
    ];

Future<void> _pump(WidgetTester tester, {required int unread}) async {
  tester.view.physicalSize = const Size(1080, 2200);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        capabilitiesProvider.overrideWithValue(_operator),
        dashboardDetachmentsProvider
            .overrideWith((ref) async => const Success([_detachment])),
        homeSummaryProvider.overrideWith(
          (ref, id) async => const Success(HomeSummary(
            detachmentId: _det,
            detachmentName: 'مفرزة دمشق المركزية',
            region: 'دمشق',
            mainCenter: 'مركز الشعلان',
            shifts: [],
            rosterCount: 10,
            storageStatus: StorageStatus.healthy,
            lowStockCount: 0,
            expiringSoonCount: 0,
          )),
        ),
        notificationRepositoryProvider
            .overrideWithValue(_FakeRepository(_rows(unread))),
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
  testWidgets('the dashboard carries one bell, and it counts the real feed',
      (tester) async {
    await _pump(tester, unread: 3);

    expect(find.byKey(const Key('notifications-bell')), findsOneWidget);
    expect(find.text(toArabicIndic('3')), findsOneWidget);
  });

  testWidgets('nothing unread means no badge at all', (tester) async {
    await _pump(tester, unread: 0);

    expect(find.byKey(const Key('notifications-bell')), findsOneWidget);
    expect(find.text(toArabicIndic('0')), findsNothing);
  });

  testWidgets('past nine the badge stops trying to be exact', (tester) async {
    await _pump(tester, unread: 12);

    expect(find.text('${toArabicIndic('9')}+'), findsOneWidget);
  });
}
