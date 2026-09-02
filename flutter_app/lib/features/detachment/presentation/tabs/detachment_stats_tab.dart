import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/access/capability.dart';
import '../../../../core/access/capability_guard.dart';
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
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0,
                  AppSpacing.lg, AppSpacing.lg),
              children: [
                const SectionHeader(title: S.statsOverview),
                _LiveTiles(detachmentId: detachmentId),

                const SizedBox(height: AppSpacing.md),
                _ExportCard(
                  onTap: () =>
                      context.push('/detachment/$detachmentId/report'),
                ),

                _Series(
                  title: S.statsAttendance,
                  values: stats.attendanceSeries,
                  suffix: '٪',
                  toneOk: true,
                ),
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
          warn: items != null &&
              items.any((i) => i.level != StockLevel.ok),
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
                    style: AppTypography.digits(
                        warn ? c.warn : c.ink, size: 19),
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
                    style: TextStyle(
                        color: c.ink2, fontSize: 12, height: 1.4)),
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
      duration: effectiveDuration(context, MotionTokens.progressFill),
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
