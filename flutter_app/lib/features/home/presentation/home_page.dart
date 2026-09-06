import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/access/capability.dart';
import '../../../core/access/capability_guard.dart';
import '../../../core/motion/stagger.dart';
import '../../../core/sync/outbox_controller.dart';
import '../../../core/sync/sync_coordinator.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_result.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/widgets/refresh_indicator.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/sheet_scaffold.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../l10n/strings.dart';
import '../../conflict/presentation/needs_review_page.dart';
import '../../detachment/domain/detachment_models.dart';
import '../../shell/main_shell.dart';
import '../../shift/domain/shift_models.dart';
import '../../shift/domain/shift_selectors.dart';
import '../../notification/presentation/widgets/notification_bell.dart';
import '../../shift/presentation/shift_manage_sheet.dart';
import '../data/home_providers.dart';
import '../domain/home_models.dart';
import '../domain/today_selectors.dart';
import 'widgets/dashboard_cards.dart';

/// The Today dashboard — the app's operational landing screen.
///
/// It answers one question on open: *what is happening today, and what needs a
/// decision.* Everything on it is a projection of a record that exists
/// somewhere else in the app, and every card leads to the existing surface
/// that owns it — the schedule, the store, the roster, the review inbox. It
/// owns no business logic of its own: what is running now, what is next, how
/// attendance stands, and which alerts exist are all decided by the pure
/// functions in `today_selectors.dart`.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: const Text(S.navHome),
        // The app's one way into the Notifications Center. The alert rows
        // below still open the surface that fixes each condition directly —
        // the bell is for what has not been looked at, and for what is no
        // longer today's.
        actions: const [NotificationBellAction()],
      ),
      body: AsyncResultView<Detachment?>(
        value: ref.watch(activeDetachmentProvider),
        onRetry: () => ref.invalidate(dashboardDetachmentsProvider),
        loading: const _DashboardSkeleton(),
        builder: (context, detachment, stale) => detachment == null
            // Not an error: a session with no active detachment is a real
            // state, and it says what would fix it.
            ? const FloatingNavPadding(
                child: EmptyState(
                  key: Key('dashboard-no-detachment'),
                  icon: Icons.flag_outlined,
                  title: S.dashboardNoDetachmentTitle,
                  body: S.dashboardNoDetachmentBody,
                ),
              )
            : _Dashboard(detachment: detachment),
      ),
    );
  }
}

class _Dashboard extends ConsumerWidget {
  const _Dashboard({required this.detachment});

  final Detachment detachment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = detachment.id;
    return AppRefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dashboardDetachmentsProvider);
        await ref.read(homeSummaryProvider(id).future);
      },
      child: AsyncResultView<HomeSummary>(
        value: ref.watch(homeSummaryProvider(id)),
        onRetry: () => ref.invalidate(homeSummaryProvider(id)),
        loading: const _DashboardSkeleton(),
        builder: (context, summary, stale) =>
            _DashboardBody(summary: summary, stale: stale),
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.summary, required this.stale});

  final HomeSummary summary;
  final bool stale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = summary.detachmentId;
    final now = DateTime.now();
    final caps = ref.capabilities;

    final current = currentShiftOf(summary.shifts, now);
    final next = nextShiftOf(summary.shifts, now);
    final today = shiftsOnDay(summary.shifts, now);
    final attendance = attendanceOf(current);

    // Client-side facts the summary cannot carry: the user's own queued
    // writes. Read from the same providers the Settings sync screen reads,
    // so the two can never disagree.
    final syncStatus = ref.watch(syncCoordinatorProvider);
    final pending = ref.watch(pendingOperationsCountProvider);
    final needingReview = ref.watch(conflictOperationsCountProvider);

    final alerts = buildDashboardAlerts(
      summary: summary,
      now: now,
      capabilities: caps,
      pendingOperations: pending,
      operationsNeedingReview: needingReview,
      lastSyncFailed: syncStatus.lastOutcome == SyncRunOutcome.failed ||
          syncStatus.lastOutcome == SyncRunOutcome.partial,
    );

    final canOpenShift = caps.canAnyIn(id, const {
      Cap.shiftManage,
      Cap.shiftAssign,
      Cap.shiftDelete,
      Cap.shiftAttendanceRecord,
      Cap.shiftAttendanceOverride,
    });

    void openShift(Shift shift) => showShiftManageSheet(
          context: context,
          ref: ref,
          shift: shift,
          detachmentId: id,
          canAssign: caps.canIn(id, Cap.shiftAssign),
          canRecord: caps.canIn(id, Cap.shiftAttendanceRecord),
          canOverride: caps.canIn(id, Cap.shiftAttendanceOverride),
          canManage: caps.canIn(id, Cap.shiftManage),
          canDelete: caps.canIn(id, Cap.shiftDelete),
        );

    void openTab(String tab) => context.go('/detachment/$id/$tab');

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
          _ContextHeader(summary: summary, now: now),
          const SizedBox(height: AppSpacing.md),
          Stagger(
            index: 0,
            child: current == null
                ? NoCurrentShiftCard(
                    hasShiftsToday: today.isNotEmpty,
                    onViewSchedule: () => openTab('shifts'),
                  )
                : CurrentShiftCard(
                    shift: current,
                    attendance: attendance,
                    now: now,
                    onOpen: canOpenShift ? () => openShift(current) : null,
                  ),
          ),
          const SizedBox(height: AppSpacing.md),
          Stagger(
            index: 1,
            child: NextShiftCard(
              shift: next,
              now: now,
              onOpen:
                  next != null && canOpenShift ? () => openShift(next) : null,
            ),
          ),
          const SectionHeader(title: S.needsYourDecision),
          _Alerts(
            alerts: alerts,
            summary: summary,
            canOpenShift: canOpenShift,
            onOpenShift: openShift,
            onOpenTab: openTab,
          ),
          const SectionHeader(title: S.dashboardQuickActions),
          _QuickActions(detachmentId: id, onOpenTab: openTab),
        ],
      ),
    );
  }
}

/// The detachment/day line, and the switcher when there is more than one
/// detachment to switch to.
class _ContextHeader extends ConsumerWidget {
  const _ContextHeader({required this.summary, required this.now});

  final HomeSummary summary;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final available = ref.watch(dashboardDetachmentsProvider).valueOrNull?.when(
              success: (data, {stale = false}) => data,
              failure: (_, __) => const <Detachment>[],
              offline: (cached) => cached ?? const <Detachment>[],
            ) ??
        const <Detachment>[];

    return DashboardContextHeader(
      detachmentName: summary.detachmentName,
      region: summary.region,
      now: now,
      onSwitch: available.length < 2
          ? null
          : () =>
              _pickDetachment(context, ref, available, summary.detachmentId),
    );
  }

  Future<void> _pickDetachment(
    BuildContext context,
    WidgetRef ref,
    List<Detachment> available,
    String currentId,
  ) async {
    final chosen = await showAppSheet<String>(
      context: context,
      title: S.dashboardPickDetachment,
      // A Builder so the rows pop the *sheet*: the closure would otherwise
      // capture this method's own context, which belongs to the page under
      // it — tapping a row would then pop the dashboard.
      child: Builder(
        builder: (sheetContext) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final detachment in available)
              // The sheet paints its own ground, so each row carries a
              // transparent Material for its ink to land on.
              Material(
                type: MaterialType.transparency,
                child: ListTile(
                  key: Key('dashboard-detachment-${detachment.id}'),
                  onTap: () => Navigator.of(sheetContext).pop(detachment.id),
                  leading: Icon(
                    detachment.id == currentId
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: detachment.id == currentId
                        ? sheetContext.c.primary
                        : sheetContext.c.ink3,
                  ),
                  title: Text(detachment.name),
                  subtitle: Text(detachment.region),
                ),
              ),
          ],
        ),
      ),
    );
    if (chosen == null) return;
    ref.read(activeDetachmentSelectionProvider.notifier).select(chosen);
  }
}

class _Alerts extends ConsumerWidget {
  const _Alerts({
    required this.alerts,
    required this.summary,
    required this.canOpenShift,
    required this.onOpenShift,
    required this.onOpenTab,
  });

  final List<DashboardAlert> alerts;
  final HomeSummary summary;
  final bool canOpenShift;
  final void Function(Shift shift) onOpenShift;
  final void Function(String tab) onOpenTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    if (alerts.isEmpty) {
      return Container(
        key: const Key('dashboard-alerts-clear'),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        child: Row(children: [
          Icon(Icons.check_circle_outline_rounded, size: 18, color: c.ok),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              S.dashboardAllClear,
              style: TextStyle(color: c.ink3, fontSize: 13),
            ),
          ),
        ]),
      );
    }

    return Container(
      key: const Key('dashboard-alerts'),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        for (int i = 0; i < alerts.length; i++)
          DashboardAlertRow(
            // Two shifts can raise the same kind on one day, so the key
            // carries the record it points at — sibling rows must not share
            // one.
            key: Key('dashboard-alert-${alerts[i].kind.name}'
                '${alerts[i].shiftId == null ? '' : '-${alerts[i].shiftId}'}'),
            alert: alerts[i],
            isLast: i == alerts.length - 1,
            onOpen: _openerFor(context, alerts[i]),
          ),
      ]),
    );
  }

  /// Where an alert leads. Every destination is an existing route or sheet —
  /// the dashboard opens no surface of its own, and an alert with nowhere
  /// meaningful to go gets no action rather than a dead button.
  VoidCallback? _openerFor(BuildContext context, DashboardAlert alert) {
    switch (alert.kind) {
      case DashboardAlertKind.needsReview:
        // Explicit human action, which is the only condition under which the
        // review surfaces may be opened at all.
        return () => context.push(NeedsReviewPage.routePath);
      case DashboardAlertKind.failedSync:
      case DashboardAlertKind.pendingSync:
        return () => context.go('/more/sync');
      case DashboardAlertKind.understaffedShift:
      case DashboardAlertKind.missingAttendance:
        final shift = _shiftById(alert.shiftId);
        if (shift == null) return () => onOpenTab('shifts');
        return canOpenShift
            ? () => onOpenShift(shift)
            : () => onOpenTab('shifts');
      case DashboardAlertKind.lowStock:
      case DashboardAlertKind.expiringStock:
        return () => onOpenTab('storage');
    }
  }

  Shift? _shiftById(String? id) {
    if (id == null) return null;
    for (final shift in summary.shifts) {
      if (shift.id == id) return shift;
    }
    return null;
  }
}

/// Shortcuts into the surfaces this session can actually open. A tile the
/// user's grants do not cover is not rendered at all.
class _QuickActions extends ConsumerWidget {
  const _QuickActions({required this.detachmentId, required this.onOpenTab});

  final String detachmentId;
  final void Function(String tab) onOpenTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caps = ref.capabilities;
    final tiles = <Widget>[
      DashboardQuickAction(
        key: const Key('dashboard-action-shifts'),
        icon: Icons.calendar_month_rounded,
        label: S.detachmentShifts,
        onTap: () => onOpenTab('shifts'),
      ),
      if (caps.canIn(detachmentId, Cap.memberView))
        DashboardQuickAction(
          key: const Key('dashboard-action-members'),
          icon: Icons.group_rounded,
          label: S.memberCount,
          onTap: () => onOpenTab('team'),
        ),
      DashboardQuickAction(
        key: const Key('dashboard-action-storage'),
        icon: Icons.inventory_2_rounded,
        label: S.detachmentStorage,
        onTap: () => onOpenTab('storage'),
      ),
      if (caps.canIn(detachmentId, Cap.statsView))
        DashboardQuickAction(
          key: const Key('dashboard-action-stats'),
          icon: Icons.insights_rounded,
          label: S.detachmentStats,
          onTap: () => onOpenTab('stats'),
        ),
    ];

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: tiles,
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return FloatingNavPadding(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: const [
          Skeleton(width: 160, height: 14),
          SizedBox(height: AppSpacing.lg),
          Skeleton(height: 180, radius: AppRadii.xl),
          SizedBox(height: AppSpacing.md),
          Skeleton(height: 72, radius: AppRadii.lg),
          SizedBox(height: AppSpacing.xl),
          SkeletonRow(),
          SizedBox(height: AppSpacing.md),
          SkeletonRow(),
        ],
      ),
    );
  }
}
