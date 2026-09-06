import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/access/capability.dart';
import '../../../../core/access/capability_guard.dart';
import '../../../../core/format/app_date.dart';
import '../../../../core/motion/animated_counter.dart';
import '../../../../core/result/result.dart';
import '../../../../core/motion/motion_tokens.dart';
import '../../../../core/motion/press_scale.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/async_result.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/refresh_indicator.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../l10n/strings.dart';
import '../../../inventory/data/inventory_providers.dart';
import '../../../inventory/domain/inventory_models.dart';
import '../../../shell/main_shell.dart';
import '../../../shift/data/shift_providers.dart';
import '../../../shift/domain/shift_models.dart';
import '../../../team/data/team_providers.dart';
import '../../../team/domain/team_models.dart';
import '../../data/detachment_providers.dart';
import '../../domain/detachment_models.dart';

/// The detachment's numbers, and the door to the report builder.
///
/// It covers all four tabs rather than only its own: a lead asking "how are
/// we doing" means the roster, the week, and the stock together. The tiles at
/// the top are live reads of the same providers those tabs use, so this
/// screen can never quote a number the tab beside it contradicts.
///
/// Gated whole: without `stats.view` there is nothing on it a session may
/// see, so it renders a denied state rather than an empty chart.
class DetachmentStatsTab extends ConsumerWidget {
  const DetachmentStatsTab({super.key, required this.detachmentId});

  final String detachmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CapabilityGate(
      capability: Cap.statsView,
      detachmentId: detachmentId,
      denied: const EmptyState(
        icon: Icons.lock_outline_rounded,
        title: S.noStats,
        body: S.noStatsSub,
      ),
      child: AppRefreshIndicator(
        onRefresh: () =>
            ref.refresh(detachmentStatsProvider(detachmentId).future),
        child: AsyncResultView<DetachmentStats>(
          value: ref.watch(detachmentStatsProvider(detachmentId)),
          onRetry: () => ref.invalidate(detachmentStatsProvider),
          builder: (context, stats, stale) => FloatingNavPadding(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
              children: [
                const SectionHeader(title: S.statsOverview),
                _LiveTiles(detachmentId: detachmentId),
                const SizedBox(height: AppSpacing.md),
                _ExportCard(
                  onTap: () => context.push('/detachment/$detachmentId/report'),
                ),
                _AttendanceSection(detachmentId: detachmentId),
                _Series(
                  title: S.statsCoverage,
                  values: stats.coverageSeries,
                  suffix: '٪',
                  toneOk: false,
                ),
                _Series(
                  title: S.statsStock,
                  values: stats.stockSeries,
                  suffix: '',
                  toneOk: false,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _StatsRange {
  week(7, S.rangeWeek),
  month(30, S.rangeMonth),
  quarter(90, S.rangeQuarter);

  const _StatsRange(this.days, this.label);
  final int days;
  final String label;
}

class _AttendanceSection extends ConsumerStatefulWidget {
  const _AttendanceSection({required this.detachmentId});

  final String detachmentId;

  @override
  ConsumerState<_AttendanceSection> createState() => _AttendanceSectionState();
}

class _AttendanceSectionState extends ConsumerState<_AttendanceSection> {
  _StatsRange _range = _StatsRange.month;
  String? _memberId;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final today = dateOnly(DateTime.now());
    final query = AttendanceStatsQuery(
      detachmentId: widget.detachmentId,
      from: today.subtract(Duration(days: _range.days - 1)),
      to: today,
      memberId: _memberId,
    );
    final roster = _dataOf(
      ref.watch(teamListProvider(widget.detachmentId)).valueOrNull,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: S.attendanceDetails),
        Row(children: [
          for (final range in _StatsRange.values) ...[
            Expanded(
              child: _ChoiceFilter(
                label: range.label,
                selected: _range == range,
                onTap: () => setState(() => _range = range),
              ),
            ),
            if (range != _StatsRange.values.last)
              const SizedBox(width: AppSpacing.xs),
          ],
        ]),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<String?>(
          key: const Key('attendance-member-filter'),
          initialValue: _memberId,
          isExpanded: true,
          decoration: const InputDecoration(labelText: S.memberFilter),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text(S.allMembers),
            ),
            for (final member in roster ?? const <TeamMember>[])
              DropdownMenuItem<String?>(
                value: member.id,
                child: Text(member.name, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (value) => setState(() => _memberId = value),
        ),
        const SizedBox(height: AppSpacing.md),
        AsyncResultView<AttendanceStatistics>(
          value: ref.watch(attendanceStatisticsProvider(query)),
          onRetry: () => ref.invalidate(attendanceStatisticsProvider(query)),
          loading: const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Center(child: CircularProgressIndicator()),
          ),
          builder: (context, statistics, stale) {
            if (statistics.members.isEmpty) {
              return Text(S.noStats,
                  style: TextStyle(color: c.ink3, fontSize: 13));
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _AttendanceMetric(S.presentTotal, statistics.presentCount),
                    _AttendanceMetric(S.absentTotal, statistics.absentCount),
                    _AttendanceMetric(
                      S.completedTotal,
                      statistics.completedCount,
                    ),
                    _AttendanceMetric(
                      S.attendancePercent,
                      statistics.attendancePercent,
                      suffix: '٪',
                    ),
                  ],
                ),
                for (final role in TeamRole.values) ...[
                  if (statistics.members.any((member) => member.role == role))
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: Text(
                        _statsRoleLabel(role),
                        style: TextStyle(
                          color: c.ink2,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  for (final member in statistics.members
                      .where((member) => member.role == role))
                    _MemberAttendanceCard(member: member),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  static T? _dataOf<T>(Result<T>? result) => result?.when(
        success: (data, {stale = false}) => data,
        failure: (_, __) => null,
        offline: (cached) => cached,
      );
}

class _ChoiceFilter extends StatelessWidget {
  const _ChoiceFilter({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return PressScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? c.primaryTint : c.surface,
          border: Border.all(color: selected ? c.primary : c.line),
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Text(
          label,
          style: TextStyle(color: selected ? c.primary : c.ink2, fontSize: 12),
        ),
      ),
    );
  }
}

class _AttendanceMetric extends StatelessWidget {
  const _AttendanceMetric(this.label, this.value, {this.suffix = ''});

  final String label;
  final int value;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      width: 148,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Text(
        '$label · ${toArabicIndic('$value')}$suffix',
        style: TextStyle(color: c.ink2, fontSize: 12),
      ),
    );
  }
}

class _MemberAttendanceCard extends StatelessWidget {
  const _MemberAttendanceCard({required this.member});

  final MemberAttendanceSummary member;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(member.memberName,
              style: TextStyle(
                  color: c.ink, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            '${S.presentTotal} ${toArabicIndic('${member.presentCount}')} · '
            '${S.absentTotal} ${toArabicIndic('${member.absentCount}')} · '
            '${S.completedTotal} ${toArabicIndic('${member.completedCount}')}',
            style: TextStyle(color: c.ink3, fontSize: 11),
          ),
          for (final record in member.records)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '${AppDate.dayMonth(record.shiftDate)} · '
                '${_statsAttendanceLabel(record.status)}'
                '${record.checkInAt == null ? '' : ' · ${AppDate.time(record.checkInAt!)}'}'
                '${record.checkOutAt == null ? '' : ' – ${AppDate.time(record.checkOutAt!)}'}',
                style: TextStyle(color: c.ink2, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }
}

String _statsRoleLabel(TeamRole role) => switch (role) {
      TeamRole.shiftSupervisor => S.roleShiftSupervisor,
      TeamRole.administrator => S.roleAdministrator,
      TeamRole.followUp => S.roleFollowUp,
      TeamRole.member => S.roleMember,
    };

String _statsAttendanceLabel(AttendanceState state) => switch (state) {
      AttendanceState.notCheckedIn => S.notCheckedIn,
      AttendanceState.checkedIn => S.checkedIn,
      AttendanceState.checkedOut => S.checkedOut,
      AttendanceState.absent => S.absent,
    };

/// Four counts read straight from the other tabs' providers.
///
/// Each tile renders its own value the moment its provider resolves, rather
/// than the whole row waiting on the slowest of them — three of these are
/// separate mock round-trips.
class _LiveTiles extends ConsumerWidget {
  const _LiveTiles({required this.detachmentId});

  final String detachmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roster = ref.watch(teamListProvider(detachmentId)).valueOrNull;
    final week = ref
        .watch(weekShiftsProvider(WeekQuery(
          detachmentId: detachmentId,
          weekStart: startOfWeek(DateTime.now()),
        )))
        .valueOrNull;
    final stock = ref.watch(inventoryListProvider(detachmentId)).valueOrNull;

    final members = _dataOf(roster);
    final shifts = _dataOf(week);
    final items = _dataOf(stock);
    final summary = shifts == null ? null : WeekSummary.of(shifts);

    return Row(children: [
      Expanded(
        child: _Tile(
          icon: Icons.groups_rounded,
          label: S.statsMembers,
          value: members == null ? null : '${members.length}',
        ),
      ),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: _Tile(
          icon: Icons.event_note_rounded,
          label: S.statsShifts,
          value: summary == null ? null : '${summary.shiftCount}',
        ),
      ),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: _Tile(
          icon: Icons.percent_rounded,
          label: S.weekCoverage,
          value: summary == null ? null : '${summary.coveragePercent}',
          suffix: '٪',
        ),
      ),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: _Tile(
          icon: Icons.inventory_2_rounded,
          label: S.stockLow,
          value: items == null
              ? null
              : '${items.where((i) => i.level != StockLevel.ok).length}',
          warn: items != null && items.any((i) => i.level != StockLevel.ok),
        ),
      ),
    ]);
  }

  static T? _dataOf<T>(Result<T>? result) => result?.when(
        success: (data, {stale = false}) => data,
        failure: (_, __) => null,
        offline: (cached) => cached,
      );
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.label,
    required this.value,
    this.suffix = '',
    this.warn = false,
  });

  final IconData icon;
  final String label;

  /// Null while the underlying provider is still resolving.
  final String? value;
  final String suffix;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md, horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Column(children: [
        Icon(icon, size: 17, color: warn ? c.warn : c.ink3),
        const SizedBox(height: 6),
        SizedBox(
          height: 24,
          child: value == null
              ? Center(
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: c.ink3),
                  ),
                )
              : Center(
                  child: TabularDigits(
                    '${toArabicIndic(value!)}$suffix',
                    style:
                        AppTypography.digits(warn ? c.warn : c.ink, size: 19),
                  ),
                ),
        ),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(color: c.ink3, fontSize: 11),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}

class _ExportCard extends StatelessWidget {
  const _ExportCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return PressScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: c.infoTint,
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        child: Row(children: [
          Icon(Icons.description_outlined, color: c.info),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(S.exportReport,
                    style: TextStyle(
                        color: c.info,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(S.exportSub,
                    style: TextStyle(color: c.ink2, fontSize: 12, height: 1.4)),
              ],
            ),
          ),
          Icon(Icons.chevron_left_rounded, color: c.info),
        ]),
      ),
    );
  }
}

class _Series extends StatelessWidget {
  const _Series({
    required this.title,
    required this.values,
    required this.suffix,
    required this.toneOk,
  });

  final String title;
  final List<int> values;
  final String suffix;
  final bool toneOk;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final max = values.isEmpty ? 0 : values.reduce((a, b) => a > b ? a : b);
    final avg = values.isEmpty
        ? 0
        : (values.reduce((a, b) => a + b) / values.length).round();
    final bar = toneOk ? c.ok : c.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: '$title · ${S.last7Days}'),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: c.surface,
            border: Border.all(color: c.line),
            borderRadius: BorderRadius.circular(AppRadii.lg),
          ),
          child: Column(children: [
            SizedBox(
              height: 96,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (int i = 0; i < values.length; i++) ...[
                    Expanded(
                      child: _Bar(
                        // Guard against a flat all-zero series.
                        fraction: max == 0 ? 0 : values[i] / max,
                        color: bar,
                      ),
                    ),
                    if (i != values.length - 1) const SizedBox(width: 6),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(children: [
              _Metric(
                label: S.highest,
                value: '${toArabicIndic(max.toString())}$suffix',
              ),
              const SizedBox(width: AppSpacing.lg),
              _Metric(
                label: S.average,
                value: '${toArabicIndic(avg.toString())}$suffix',
              ),
            ]),
          ]),
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.fraction, required this.color});

  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: fraction.clamp(0, 1)),
      duration: effectiveValueDuration(context, MotionTokens.progressFill),
      curve: effectiveCurve(context, MotionTokens.enter),
      builder: (context, v, _) => Align(
        alignment: Alignment.bottomCenter,
        child: FractionallySizedBox(
          heightFactor: v == 0 ? 0.02 : v,
          child: Container(
            decoration: BoxDecoration(
              color: v == 0 ? c.surface3 : color,
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Row(children: [
      Text(label, style: TextStyle(color: c.ink3, fontSize: 12)),
      const SizedBox(width: 6),
      Text(value, style: AppTypography.digits(c.ink, size: 14)),
    ]);
  }
}
