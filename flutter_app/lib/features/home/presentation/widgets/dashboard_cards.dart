import 'package:flutter/material.dart';

import '../../../../core/format/app_date.dart';
import '../../../../core/motion/animated_counter.dart';
import '../../../../core/motion/motion_tokens.dart';
import '../../../../core/motion/press_scale.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/lock_window.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../l10n/strings.dart';
import '../../../shift/domain/attendance_policy.dart';
import '../../../shift/domain/shift_models.dart';
import '../../../shift/domain/shift_selectors.dart';
import '../../../team/domain/team_models.dart';
import '../../domain/today_selectors.dart';

/// The cards the Today dashboard is built from.
///
/// Presentation only: every figure arrives already decided by
/// `today_selectors.dart`, so nothing here recomputes what is current, what is
/// next, or what counts as present.

/// Which detachment the screen is about, and what day it is.
///
/// Tappable only when there is more than one detachment to switch between —
/// `DETACHMENT-SCOPING.md` §4.5: no affordance for a choice that does not
/// exist.
class DashboardContextHeader extends StatelessWidget {
  const DashboardContextHeader({
    super.key,
    required this.detachmentName,
    required this.region,
    required this.now,
    this.onSwitch,
  });

  final String detachmentName;
  final String region;
  final DateTime now;
  final VoidCallback? onSwitch;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = Theme.of(context).textTheme;
    final subtitle = '${AppDate.weekdayOf(now)} · ${AppDate.dayMonth(now)}'
        '${region.isEmpty ? '' : ' · $region'}';

    final content = Row(children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              detachmentName,
              style: t.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(color: c.ink3, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      if (onSwitch != null) ...[
        const SizedBox(width: AppSpacing.sm),
        Icon(Icons.unfold_more_rounded, size: 18, color: c.ink3),
      ],
    ]);

    if (onSwitch == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: content,
      );
    }
    return Semantics(
      button: true,
      label: '$detachmentName، ${S.dashboardSwitchDetachment}',
      excludeSemantics: true,
      onTap: onSwitch,
      child: PressScale(
        onTap: onSwitch,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: content,
        ),
      ),
    );
  }
}

/// The shift running right now: where, when, who is answerable, and how
/// attendance stands. The card is the screen's one hero and its primary
/// action opens the existing shift-management flow.
class CurrentShiftCard extends StatelessWidget {
  const CurrentShiftCard({
    super.key,
    required this.shift,
    required this.attendance,
    required this.now,
    this.onOpen,
  });

  final Shift shift;
  final TodayAttendance attendance;
  final DateTime now;

  /// Null when the session holds none of the shift capabilities — the card
  /// still reports, it just does not offer an action that would fail.
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = Theme.of(context).textTheme;
    final window = AttendanceWindow.of(shift, now: now);
    final manager = shift.manager;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(AppRadii.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.activeShift,
                      style: TextStyle(
                        color: c.ink3,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      shift.centerName,
                      style: t.titleLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppDate.minuteRange(shift.startMinutes, shift.endMinutes),
                      style: AppTypography.digits(c.ink2, size: 15),
                    ),
                  ],
                ),
              ),
              if (window.isOpen)
                LockWindow(
                  state: LockWindowState.open,
                  remaining: window.remaining(now),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _ManagerLine(manager: manager),
          const SizedBox(height: AppSpacing.md),
          _AttendanceSummary(attendance: attendance),
          if (onOpen != null) ...[
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('dashboard-open-current-shift'),
                onPressed: onOpen,
                icon: const Icon(Icons.event_available_rounded, size: 18),
                label: const Text(S.dashboardOpenShift),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Nothing is running: say so plainly, and point at the day's schedule rather
/// than leaving an empty hero.
class NoCurrentShiftCard extends StatelessWidget {
  const NoCurrentShiftCard({
    super.key,
    required this.hasShiftsToday,
    this.onViewSchedule,
  });

  final bool hasShiftsToday;
  final VoidCallback? onViewSchedule;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(AppRadii.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(
              hasShiftsToday
                  ? Icons.schedule_rounded
                  : Icons.event_available_outlined,
              color: c.ink3,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                hasShiftsToday
                    ? S.dashboardNoShiftNow
                    : S.dashboardNoShiftsToday,
                style: TextStyle(color: c.ink2, fontSize: 14),
              ),
            ),
          ]),
          if (onViewSchedule != null) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const Key('dashboard-view-schedule'),
                onPressed: onViewSchedule,
                icon: const Icon(Icons.calendar_month_rounded, size: 18),
                label: const Text(S.dashboardViewSchedule),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The next shift ahead — compact on purpose, because it is context rather
/// than the thing being worked on.
class NextShiftCard extends StatelessWidget {
  const NextShiftCard({
    super.key,
    required this.shift,
    required this.now,
    this.onOpen,
  });

  final Shift? shift;
  final DateTime now;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final next = shift;

    if (next == null) {
      return _Card(
        child: Row(children: [
          Icon(Icons.hourglass_empty_rounded, size: 18, color: c.ink3),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              S.dashboardNoNextShift,
              style: TextStyle(color: c.ink3, fontSize: 13),
            ),
          ),
        ]),
      );
    }

    final isTomorrow = next.date.isAfter(dateOnly(now));
    final when = isTomorrow
        ? '${S.dashboardTomorrow} · '
            '${AppDate.minuteRange(next.startMinutes, next.endMinutes)}'
        : AppDate.minuteRange(next.startMinutes, next.endMinutes);

    return _Card(
      onTap: onOpen,
      child: Row(children: [
        Icon(Icons.upcoming_rounded, size: 18, color: c.ink2),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${S.dashboardNextShift} · ${next.centerName}',
                style: TextStyle(
                  color: c.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(when, style: AppTypography.digits(c.ink3, size: 12)),
              const SizedBox(height: 2),
              Text(
                next.manager?.name ?? S.shiftManagerUnset,
                style: TextStyle(
                  color: next.manager == null ? c.warn : c.ink3,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        StatusChip(
          kind: next.hasCoverageGap ? StatusKind.warn : StatusKind.ok,
          label: '${toArabicIndic('${next.assigned}')}'
              '/${toArabicIndic('${next.needed}')}',
        ),
      ]),
    );
  }
}

/// One raised condition. Quiet by construction — a row with a label, a count,
/// and one action that opens the surface where it is fixed.
class DashboardAlertRow extends StatelessWidget {
  const DashboardAlertRow({
    super.key,
    required this.alert,
    required this.isLast,
    this.onOpen,
  });

  final DashboardAlert alert;
  final bool isLast;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final (icon, color, tint) = switch (alert.kind) {
      DashboardAlertKind.needsReview => (
          Icons.compare_arrows_rounded,
          c.warn,
          c.warnTint
        ),
      DashboardAlertKind.failedSync => (
          Icons.sync_problem_rounded,
          c.crit,
          c.critTint
        ),
      DashboardAlertKind.understaffedShift => (
          Icons.group_off_outlined,
          c.warn,
          c.warnTint
        ),
      DashboardAlertKind.missingAttendance => (
          Icons.how_to_reg_outlined,
          c.warn,
          c.warnTint
        ),
      DashboardAlertKind.lowStock => (
          Icons.inventory_2_outlined,
          c.crit,
          c.critTint
        ),
      DashboardAlertKind.expiringStock => (
          Icons.timer_outlined,
          c.warn,
          c.warnTint
        ),
      DashboardAlertKind.pendingSync => (
          Icons.cloud_upload_outlined,
          c.info,
          c.infoTint
        ),
    };

    final title = switch (alert.kind) {
      DashboardAlertKind.needsReview => alert.count == 1
          ? S.syncReviewOne
          : S.syncReviewMany
              .replaceFirst('%d', toArabicIndic('${alert.count}')),
      DashboardAlertKind.failedSync => S.alertSyncFailedTitle,
      DashboardAlertKind.understaffedShift => S.alertUnderstaffedTitle,
      DashboardAlertKind.missingAttendance => S.alertMissingAttendanceTitle,
      DashboardAlertKind.lowStock => S.alertLowStockTitle,
      DashboardAlertKind.expiringStock => S.alertExpiringTitle,
      DashboardAlertKind.pendingSync => alert.count == 1
          ? S.syncPendingOne
          : S.syncPendingMany
              .replaceFirst('%d', toArabicIndic('${alert.count}')),
    };

    final body = switch (alert.kind) {
      DashboardAlertKind.needsReview => S.syncReviewOpenHint,
      DashboardAlertKind.failedSync => S.syncFailedNote,
      DashboardAlertKind.understaffedShift => alert.count == 1
          ? S.alertUnderstaffedBodyOne
          : S.alertUnderstaffedBody
              .replaceFirst('%d', toArabicIndic('${alert.count}')),
      DashboardAlertKind.missingAttendance => alert.count == 1
          ? S.alertMissingAttendanceBodyOne
          : S.alertMissingAttendanceBody
              .replaceFirst('%d', toArabicIndic('${alert.count}')),
      DashboardAlertKind.lowStock => alert.count == 1
          ? S.alertLowStockBodyOne
          : S.alertLowStockBody
              .replaceFirst('%d', toArabicIndic('${alert.count}')),
      DashboardAlertKind.expiringStock => alert.count == 1
          ? S.alertExpiringBodyOne
          : S.alertExpiringBody
              .replaceFirst('%d', toArabicIndic('${alert.count}')),
      DashboardAlertKind.pendingSync => S.syncOfflineNote,
    };

    final actionLabel = alert.kind == DashboardAlertKind.needsReview
        ? S.alertReviewAction
        : S.alertOpenAction;

    final row = Container(
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: c.line)),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: c.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: TextStyle(color: c.ink3, fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),
        if (onOpen != null) ...[
          const SizedBox(width: AppSpacing.sm),
          FilledButton.tonal(
            onPressed: onOpen,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: Text(actionLabel),
          ),
        ],
      ]),
    );

    if (onOpen == null) return row;
    // One announcement for the whole row, with the action on the same node —
    // the same pattern the sync attention row uses.
    return Semantics(
      container: true,
      button: true,
      excludeSemantics: true,
      label: '$title، $body',
      onTap: onOpen,
      child: row,
    );
  }
}

/// A role-aware shortcut. Rendered only when its destination is one this
/// session can actually open, so the grid never offers a dead tile.
class DashboardQuickAction extends StatelessWidget {
  const DashboardQuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return PressScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 18, color: c.primary),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: c.ink,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ]),
      ),
    );
  }
}

class _ManagerLine extends StatelessWidget {
  const _ManagerLine({required this.manager});

  final TeamMember? manager;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final name = manager?.name;
    return Row(children: [
      Icon(
        name == null ? Icons.person_off_outlined : Icons.badge_outlined,
        size: 15,
        color: name == null ? c.warn : c.ink3,
      ),
      const SizedBox(width: 6),
      Text('${S.shiftManager}:', style: TextStyle(color: c.ink3, fontSize: 12)),
      const SizedBox(width: 4),
      Expanded(
        child: Text(
          name ?? S.shiftManagerUnset,
          style: TextStyle(
            color: name == null ? c.warn : c.ink,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ]);
  }
}

/// Present over assigned, with what is still open beside it. Counts come from
/// [TodayAttendance] so this widget adds nothing up itself.
class _AttendanceSummary extends StatelessWidget {
  const _AttendanceSummary({required this.attendance});

  final TodayAttendance attendance;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(S.attendanceProgress,
              style: TextStyle(color: c.ink2, fontSize: 13)),
          const Spacer(),
          AnimatedCounter(
            value: attendance.present,
            style: AppTypography.digits(c.ink, size: 15),
          ),
          Text(
            ' / ${toArabicIndic('${attendance.assigned}')}',
            style: AppTypography.digits(c.ink3, size: 15),
          ),
        ]),
        const SizedBox(height: 6),
        _AttendanceBar(progress: attendance.progress),
        const SizedBox(height: AppSpacing.sm),
        Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, children: [
          _Pill(
            label: '${S.dashboardPresent} '
                '${toArabicIndic('${attendance.present}')}',
            kind: StatusKind.ok,
          ),
          if (attendance.awaiting > 0)
            _Pill(
              label: '${S.dashboardAwaiting} '
                  '${toArabicIndic('${attendance.awaiting}')}',
              kind: StatusKind.muted,
            ),
          if (attendance.absent > 0)
            _Pill(
              label: '${S.absent} '
                  '${toArabicIndic('${attendance.absent}')}',
              kind: StatusKind.crit,
            ),
          if (attendance.gap > 0)
            _Pill(
              label: '${S.shiftNeeded} '
                  '${toArabicIndic('${attendance.gap}')}',
              kind: StatusKind.warn,
            ),
        ]),
      ],
    );
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
      duration: effectiveValueDuration(context, MotionTokens.progressFill),
      curve: effectiveCurve(context, MotionTokens.enter),
      builder: (context, v, _) => ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: Stack(children: [
          Container(height: 8, color: c.surface3),
          FractionallySizedBox(
            widthFactor: v,
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: c.ok,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.kind});

  final String label;
  final StatusKind kind;

  @override
  Widget build(BuildContext context) => StatusChip(kind: kind, label: label);
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final card = Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return PressScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: card,
    );
  }
}
