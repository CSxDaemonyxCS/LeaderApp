import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/animated_counter.dart';
import '../../../core/motion/motion_tokens.dart';
import '../../../core/motion/press_scale.dart';
import '../../../core/motion/stagger.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/lock_window.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/widgets/refresh_indicator.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../l10n/strings.dart';
import '../../shell/main_shell.dart';
import '../data/home_providers.dart';
import '../domain/home_models.dart';
import '../../../core/theme/app_typography.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(homeSummaryProvider);
    final c = context.c;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: const Text(S.navHome),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(children: [
        // Offline banner (stub — a real impl would watch connectivity).
        const OfflineBanner(visible: false, lastRefreshedAgoMinutes: 4),
        Expanded(
          child: AppRefreshIndicator(
            onRefresh: () async => ref.refresh(homeSummaryProvider.future),
            child: async.when(
              loading: () => const _HomeSkeleton(),
              error: (e, st) => ErrorStateView(
                onRetry: () => ref.invalidate(homeSummaryProvider),
              ),
              data: (result) => result.when(
                success: (data, {stale = false}) =>
                    _HomeContent(summary: data, stale: stale),
                failure: (m, _) => ErrorStateView(
                  body: m,
                  onRetry: () => ref.invalidate(homeSummaryProvider),
                ),
                offline: (cached) => cached == null
                    ? EmptyState(
                        icon: Icons.cloud_off_rounded,
                        title: S.offlineTitle,
                        body: 'لا بيانات محفوظة لهذه الجلسة.',
                        actionLabel: S.retry,
                        onAction: () => ref.invalidate(homeSummaryProvider),
                      )
                    : _HomeContent(summary: cached, stale: true),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.summary, this.stale = false});
  final HomeSummary summary;
  final bool stale;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return FloatingNavPadding(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (stale)
            const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.md),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: StaleBadge(),
              ),
            ),
          // ---- Hero: active shift ----
          Stagger(
            index: 0,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [c.primaryTint, c.surface],
                ),
                border: Border.all(color: c.line),
                borderRadius: BorderRadius.circular(AppRadii.xl),
              ),
              child: summary.activeShift == null
                  ? _NoActiveShift()
                  : _ActiveShift(summary: summary),
            ),
          ),
          // ---- Decisions ----
          const SectionHeader(title: S.needsYourDecision),
          if (summary.decisions.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: c.surface,
                border: Border.all(color: c.line),
                borderRadius: BorderRadius.circular(AppRadii.lg),
              ),
              child: Text(
                'كل شيء تحت السيطرة — لا قرارات معلّقة.',
                style: TextStyle(color: c.ink3, fontSize: 13),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: c.surface,
                border: Border.all(color: c.line),
                borderRadius: BorderRadius.circular(AppRadii.lg),
              ),
              child: Column(children: [
                for (int i = 0; i < summary.decisions.length; i++)
                  Stagger(
                    index: i + 1,
                    child: _DecisionRow(
                      item: summary.decisions[i],
                      isLast: i == summary.decisions.length - 1,
                    ),
                  ),
              ]),
            ),
          // ---- Compact secondary stats ----
          const SectionHeader(title: S.secondaryStats),
          Row(children: [
            Expanded(
              child: Stagger(
                index: 6,
                child: _SecondaryStat(
                  label: S.attendanceRate,
                  value: '${summary.attendanceRatePercent}%',
                  tone: StatusKind.ok,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Stagger(
                index: 7,
                child: _SecondaryStat(
                  label: S.stockLow,
                  value: summary.stockLowCount.toString(),
                  tone: StatusKind.warn,
                ),
              ),
            ),
          ]),
          const SizedBox(height: AppSpacing.md),
          _SecondaryStat(
            label: S.workshopsThisWeek,
            value: summary.workshopsThisWeek.toString(),
            tone: StatusKind.info,
            wide: true,
          ),
        ],
      ),
    );
  }
}

class _ActiveShift extends StatelessWidget {
  const _ActiveShift({required this.summary});
  final HomeSummary summary;
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = Theme.of(context).textTheme;
    final sh = summary.activeShift!;
    final progress = summary.attendanceTotal == 0
        ? 0.0
        : summary.attendancePresent / summary.attendanceTotal;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(S.activeShift,
                    style: TextStyle(
                        color: c.ink3, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(summary.centerName, style: t.headlineMedium),
                const SizedBox(height: 4),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    '${sh.startHour.toString().padLeft(2, '0')}:00 – ${sh.endHour.toString().padLeft(2, '0')}:00',
                    style: AppTypography.digits(c.ink2, size: 15),
                    textAlign: TextAlign.start,
                  ),
                ),
              ],
            ),
          ),
          if (summary.lockRemaining != null)
            LockWindow(
              state: LockWindowState.open,
              remaining: summary.lockRemaining,
            ),
        ],
      ),
      const SizedBox(height: AppSpacing.lg),
      // Attendance progress
      Row(children: [
        Text(S.attendanceProgress,
            style: TextStyle(color: c.ink2, fontSize: 13)),
        const Spacer(),
        AnimatedCounter(
          value: summary.attendancePresent,
          style: AppTypography.digits(c.ink, size: 15),
        ),
        Text(' / ${toArabicIndic(summary.attendanceTotal.toString())}',
            style: AppTypography.digits(c.ink3, size: 15)),
      ]),
      const SizedBox(height: 6),
      _AttendanceBar(progress: progress),
      const SizedBox(height: AppSpacing.lg),
      FilledButton(
        onPressed: () {},
        child: const Text(S.primaryAction),
      ),
    ]);
  }
}

class _AttendanceBar extends StatelessWidget {
  const _AttendanceBar({required this.progress});
  final double progress;
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress.clamp(0, 1)),
      duration: effectiveDuration(context, MotionTokens.progressFill),
      curve: effectiveCurve(context, MotionTokens.enter),
      builder: (context, v, _) => ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: Stack(children: [
          Container(height: 8, color: c.surface3),
          FractionallySizedBox(
            widthFactor: v,
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: c.ok,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _NoActiveShift extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Row(children: [
      Icon(Icons.hourglass_empty_rounded, color: c.ink3),
      const SizedBox(width: 10),
      Expanded(
        child: Text(S.noActiveShift,
            style: TextStyle(color: c.ink2, fontSize: 14)),
      ),
    ]);
  }
}

class _DecisionRow extends StatelessWidget {
  const _DecisionRow({required this.item, required this.isLast});
  final HomeDecisionItem item;
  final bool isLast;
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final (color, tint, icon) = switch (item.kind) {
      DecisionKind.unfilledShift => (c.warn, c.warnTint, Icons.event_busy_rounded),
      DecisionKind.expiringStock => (c.crit, c.critTint, Icons.timer_outlined),
      DecisionKind.joinRequest => (c.info, c.infoTint, Icons.person_add_alt_1_rounded),
    };
    return PressScale(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          border: isLast ? null : Border(bottom: BorderSide(color: c.line)),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: tint, borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: TextStyle(
                        color: c.ink, fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(item.subtitle,
                    style: TextStyle(color: c.ink3, fontSize: 12)),
              ],
            ),
          ),
          FilledButton.tonal(
            onPressed: () {},
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: Text(item.actionLabel),
          ),
        ]),
      ),
    );
  }
}

class _SecondaryStat extends StatelessWidget {
  const _SecondaryStat({
    required this.label, required this.value,
    required this.tone, this.wide = false,
  });
  final String label;
  final String value;
  final StatusKind tone;
  final bool wide;
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final (fg, bg) = switch (tone) {
      StatusKind.ok => (c.ok, c.okTint),
      StatusKind.warn => (c.warn, c.warnTint),
      StatusKind.crit => (c.crit, c.critTint),
      StatusKind.info => (c.info, c.infoTint),
      StatusKind.muted => (c.ink2, c.mutedTint),
    };
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
              color: bg, borderRadius: BorderRadius.circular(AppRadii.sm)),
          child: Icon(Icons.insights_rounded, color: fg, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(color: c.ink2, fontSize: 12)),
              const SizedBox(height: 2),
              Text(
                toArabicIndic(value.replaceAll('%', '٪')),
                style: AppTypography.digits(c.ink, size: 20),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();
  @override
  Widget build(BuildContext context) {
    return FloatingNavPadding(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: const [
          Skeleton(height: 160, radius: 16),
          SizedBox(height: 24),
          Skeleton(width: 100, height: 12),
          SizedBox(height: 12),
          SkeletonRow(), SizedBox(height: 12),
          SkeletonRow(), SizedBox(height: 12),
          SkeletonRow(),
        ],
      ),
    );
  }
}
