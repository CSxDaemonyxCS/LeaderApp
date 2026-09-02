import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/app_date.dart';
import '../../../core/motion/animated_counter.dart';
import '../../../core/result/result.dart';
import '../../../l10n/strings.dart';
import '../../inventory/data/inventory_providers.dart';
import '../../inventory/domain/inventory_models.dart';
import '../../shift/data/shift_providers.dart';
import '../../shift/domain/shift_models.dart';
import '../../team/data/team_providers.dart';
import '../../team/domain/team_models.dart';
import '../../tenant/data/tenant_providers.dart';
import '../../tenant/domain/tenant_models.dart';
import '../domain/detachment_models.dart';
import '../domain/report_models.dart';
import 'detachment_providers.dart';

/// Cache key for a built report: which detachment, and exactly which choices.
class ReportQuery {
  const ReportQuery({required this.detachmentId, required this.spec});

  final String detachmentId;
  final ReportSpec spec;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReportQuery &&
          other.detachmentId == detachmentId &&
          other.spec == spec;

  @override
  int get hashCode => Object.hash(detachmentId, spec);
}

/// Builds the document from the same repositories the screens read.
///
/// Nothing here computes a figure of its own: a report that disagrees with
/// the screen it came from is worse than no report, so every number is the
/// one already on a tab, re-laid-out.
final reportProvider = FutureProvider.autoDispose
    .family<Result<ReportDocument>, ReportQuery>((ref, q) async {
  final id = q.detachmentId;
  final spec = q.spec;

  final detachmentResult =
      await ref.read(detachmentRepositoryProvider).byId(id);
  final detachment = _dataOf<Detachment>(detachmentResult);
  if (detachment == null) {
    return const Failure('لم يُعثر على المفرزة.', code: 'not_found');
  }

  final tenantResult =
      await ref.read(tenantRepositoryProvider).byId(detachment.tenantId);
  final tenantName = _dataOf<Tenant>(tenantResult)?.name ?? '';

  final blocks = <ReportBlock>[];

  // ---- Summary -----------------------------------------------------------
  if (spec.has(ReportSection.summary)) {
    blocks.add(ReportFacts(S.secSummary, [
      (S.detachmentName, detachment.name),
      (S.tenant, tenantName),
      (S.detachmentRegion, detachment.region),
      (S.detachmentCenter, detachment.mainCenter),
      (S.memberCount, toArabicIndic('${detachment.memberCount}')),
      (S.coverage, '${toArabicIndic('${detachment.coveragePercent}')}٪'),
      (
        S.status,
        detachment.status == DetachmentStatus.active
            ? S.statusActive
            : S.statusArchived
      ),
      (S.exportRange, spec.range.label),
    ]));
  }

  // ---- Members -----------------------------------------------------------
  if (spec.has(ReportSection.members)) {
    final roster =
        _dataOf<List<TeamMember>>(await ref.read(teamRepositoryProvider)
                .listForDetachment(id)) ??
            const <TeamMember>[];
    blocks.add(ReportTable(
      S.secMembers,
      [S.memberName, S.memberDepartment, S.memberNumber, S.memberRole,
        S.attendanceProgress],
      [
        for (final m in roster)
          [
            m.name,
            m.department,
            toArabicIndic(m.personalNumber),
            _roleLabel(m.role),
            _attendanceLabel(m.attendance),
          ],
      ],
    ));
  }

  // ---- Shifts ------------------------------------------------------------
  // The range decides how many weeks are walked. Whole weeks, because the
  // schedule is stored and read a week at a time.
  if (spec.has(ReportSection.shifts)) {
    final weeks = (spec.range.days / 7).ceil();
    final thisWeek = startOfWeek(DateTime.now());
    final rows = <List<String>>[];
    for (int w = weeks - 1; w >= 0; w--) {
      final weekStart = thisWeek.subtract(Duration(days: 7 * w));
      final shifts = _dataOf<List<Shift>>(
              await ref.read(shiftRepositoryProvider)
                  .listForWeek(id, weekStart)) ??
          const <Shift>[];
      for (final s in shifts) {
        rows.add([
          AppDate.weekdayOf(s.date),
          AppDate.dayMonth(s.date),
          AppDate.minuteRange(s.startMinutes, s.endMinutes),
          s.centerName,
          toArabicIndic('${s.assigned}'),
          toArabicIndic('${s.needed}'),
          toArabicIndic('${s.gap}'),
        ]);
      }
    }
    blocks.add(ReportTable(
      S.secShifts,
      [
        S.weekOf,
        S.workshopDate,
        S.shiftPeriod,
        S.shiftCenter,
        S.assignedLabel,
        S.shiftNeeded,
        S.coverageGap,
      ],
      rows,
    ));
  }

  // ---- Storage -----------------------------------------------------------
  final wantsStock =
      spec.has(ReportSection.storage) || spec.has(ReportSection.storageLow);
  if (wantsStock) {
    final items = _dataOf<List<InventoryItem>>(
            await ref.read(inventoryRepositoryProvider)
                .listForDetachment(id)) ??
        const <InventoryItem>[];

    List<List<String>> tableOf(Iterable<InventoryItem> source) => [
          for (final i in source)
            [
              i.name,
              i.unit,
              toArabicIndic('${i.currentStock}'),
              toArabicIndic('${i.minimum}'),
              i.expiresOn == null ? S.noExpiry : AppDate.dayMonth(i.expiresOn!),
              _levelLabel(i.level),
            ],
        ];
    const columns = [
      S.itemName,
      S.itemUnit,
      S.currentStock,
      S.minimumLevel,
      S.expiresOn,
      S.status,
    ];

    if (spec.has(ReportSection.storage)) {
      blocks.add(ReportTable(S.secStorage, columns, tableOf(items)));
    }
    if (spec.has(ReportSection.storageLow)) {
      blocks.add(ReportTable(
        S.secStorageLow,
        columns,
        tableOf(items.where((i) => i.level != StockLevel.ok)),
      ));
    }
  }

  // ---- Series ------------------------------------------------------------
  final wantsSeries = spec.has(ReportSection.attendance) ||
      spec.has(ReportSection.coverage) ||
      spec.has(ReportSection.consumption);
  if (wantsSeries) {
    final stats = _dataOf<DetachmentStats>(
        await ref.read(detachmentRepositoryProvider).stats(id));
    if (stats != null) {
      // The mock keeps seven days of history. A longer range is honoured by
      // labelling what is actually there rather than by inventing the rest —
      // a report that pads itself is a report nobody can trust.
      final labels = _dayLabels(stats.attendanceSeries.length);
      if (spec.has(ReportSection.attendance)) {
        blocks.add(ReportSeries(
            S.secAttendance, labels, stats.attendanceSeries, suffix: '٪'));
      }
      if (spec.has(ReportSection.coverage)) {
        blocks.add(ReportSeries(
            S.secCoverage, labels, stats.coverageSeries, suffix: '٪'));
      }
      if (spec.has(ReportSection.consumption)) {
        blocks.add(
            ReportSeries(S.secConsumption, labels, stats.stockSeries));
      }
    }
  }

  return Success(ReportDocument(
    detachmentName: detachment.name,
    tenantName: tenantName,
    generatedAt: DateTime.now(),
    range: spec.range,
    blocks: blocks,
  ));
});

/// The last [count] days ending today, oldest first.
List<String> _dayLabels(int count) {
  final today = dateOnly(DateTime.now());
  return [
    for (int i = count - 1; i >= 0; i--)
      AppDate.dayMonth(today.subtract(Duration(days: i))),
  ];
}

T? _dataOf<T>(Result<T> result) => result.when(
      success: (data, {stale = false}) => data,
      failure: (_, __) => null,
      offline: (cached) => cached,
    );

String _roleLabel(TeamRole role) => switch (role) {
      TeamRole.lead => S.roleLead,
      TeamRole.medic => S.roleMedic,
      TeamRole.trainee => S.roleTrainee,
      TeamRole.volunteer => S.roleVolunteer,
    };

String _attendanceLabel(AttendanceState state) => switch (state) {
      AttendanceState.present => S.present,
      AttendanceState.late => S.late,
      AttendanceState.absent => S.absent,
      AttendanceState.notInvited => S.notInvited,
    };

String _levelLabel(StockLevel level) => switch (level) {
      StockLevel.ok => S.stockOk,
      StockLevel.low => S.stockLowLabel,
      StockLevel.empty => S.stockEmpty,
    };
