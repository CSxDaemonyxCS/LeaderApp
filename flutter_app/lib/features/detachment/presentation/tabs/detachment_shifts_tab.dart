import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/access/capability.dart';
import '../../../../core/access/capability_guard.dart';
import '../../../../core/format/app_date.dart';
import '../../../../core/motion/animated_counter.dart';
import '../../../../core/motion/motion_tokens.dart';
import '../../../../core/motion/press_scale.dart';
import '../../../../core/motion/stagger.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/async_result.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/refresh_indicator.dart';
import '../../../../core/widgets/sheet_scaffold.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../l10n/strings.dart';
import '../../../shell/main_shell.dart';
import '../../../shift/data/shift_providers.dart';
import '../../../shift/domain/shift_models.dart';
import '../../../shift/presentation/shift_assign_sheet.dart';
import '../../../shift/presentation/shift_edit_sheet.dart';
import '../../../team/domain/team_models.dart';
import '../../data/detachment_providers.dart';
import '../../domain/detachment_models.dart';

/// One detachment's schedule, a week at a time.
///
/// The old screen showed today and nothing else, which meant the only way to
/// see next Tuesday was to wait for it. A week is the unit people actually
/// plan in, so the screen is: a week you can step through, a day strip that
/// shows at a glance which days are short, and the chosen day's shifts.
///
/// Three affordances exist specifically because scheduling by hand was the
/// part of the legacy program people found hard:
///
/// * **Copy last week** — most weeks repeat. One tap instead of eight forms.
/// * **Apply the weekly repeats** — the standing schedule, materialised.
/// * **Quick fill** — closes a coverage gap with members who are actually
///   free at that hour, instead of leaving someone to cross-check by eye.
class DetachmentShiftsTab extends ConsumerWidget {
  const DetachmentShiftsTab({super.key, required this.detachmentId});

  final String detachmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekStart = ref.watch(selectedWeekProvider(detachmentId));
    final dayOffset = ref.watch(selectedDayOffsetProvider(detachmentId));
    final query =
        WeekQuery(detachmentId: detachmentId, weekStart: weekStart);

    final canManage =
        ref.capabilities.canIn(detachmentId, Cap.shiftManage);
    final canAssign =
        ref.capabilities.canIn(detachmentId, Cap.shiftAssign);
    final canRecord =
        ref.capabilities.canIn(detachmentId, Cap.shiftAttendanceRecord);
    final canDelete =
        ref.capabilities.canIn(detachmentId, Cap.shiftDelete);

    return AppRefreshIndicator(
      onRefresh: () => ref.refresh(weekShiftsProvider(query).future),
      child: AsyncResultView<List<Shift>>(
        value: ref.watch(weekShiftsProvider(query)),
        onRetry: () => ref.invalidate(weekShiftsProvider),
        builder: (context, shifts, stale) => _Week(
          detachmentId: detachmentId,
          weekStart: weekStart,
          dayOffset: dayOffset,
          shifts: shifts,
          canManage: canManage,
          canAssign: canAssign,
          canRecord: canRecord,
          canDelete: canDelete,
        ),
      ),
    );
  }
}

class _Week extends ConsumerWidget {
  const _Week({
    required this.detachmentId,
    required this.weekStart,
    required this.dayOffset,
    required this.shifts,
    required this.canManage,
    required this.canAssign,
    required this.canRecord,
    required this.canDelete,
  });

  final String detachmentId;
  final DateTime weekStart;
  final int dayOffset;
  final List<Shift> shifts;
  final bool canManage;
  final bool canAssign;
  final bool canRecord;
  final bool canDelete;

  DateTime get _selectedDay => weekStart.add(Duration(days: dayOffset));

  List<Shift> _shiftsOn(int offset) {
    final day = weekStart.add(Duration(days: offset));
    return shifts.where((s) => s.date == day).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = _shiftsOn(dayOffset);
    final summary = WeekSummary.of(shifts);

    return FloatingNavPadding(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
        children: [
          _WeekHeader(
            detachmentId: detachmentId,
            weekStart: weekStart,
            summary: summary,
          ),
          const SizedBox(height: AppSpacing.md),
          _DayStrip(
            weekStart: weekStart,
            selected: dayOffset,
            countsFor: (i) {
              final list = _shiftsOn(i);
              return (list.length, list.where((s) => s.hasCoverageGap).length);
            },
            onPick: (i) => ref
                .read(selectedDayOffsetProvider(detachmentId).notifier)
                .state = i,
          ),
          const SizedBox(height: AppSpacing.md),
          if (canManage)
            _BulkActions(
              detachmentId: detachmentId,
              weekStart: weekStart,
              day: _selectedDay,
            ),
          const SizedBox(height: AppSpacing.md),
          _DayHeader(
            day: _selectedDay,
            count: today.length,
            onAdd: canManage
                ? () => _addShift(context, ref, _selectedDay)
                : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (today.isEmpty)
            _EmptyDay(
              onAdd: canManage
                  ? () => _addShift(context, ref, _selectedDay)
                  : null,
            )
          else
            for (int i = 0; i < today.length; i++) ...[
              Stagger(
                index: i,
                child: _ShiftCard(
                  shift: today[i],
                  canAssign: canAssign,
                  canRecord: canRecord,
                  canManage: canManage,
                  canDelete: canDelete,
                  detachmentId: detachmentId,
                ),
              ),
              if (i != today.length - 1)
                const SizedBox(height: AppSpacing.md),
            ],
        ],
      ),
    );
  }

  Future<void> _addShift(
      BuildContext context, WidgetRef ref, DateTime day) async {
    // The centre field is pre-filled with the detachment's main centre,
    // which is right for most shifts and editable for the rest.
    final detachment = ref.read(detachmentByIdProvider(detachmentId)).valueOrNull;
    final center = detachment?.when(
          success: (Detachment d, {bool stale = false}) => d.mainCenter,
          failure: (_, __) => '',
          offline: (cached) => cached?.mainCenter ?? '',
        ) ??
        '';
    await showShiftEditor(
      context: context,
      detachmentId: detachmentId,
      date: day,
      defaultCenter: center,
    );
  }
}

// ---------------------------------------------------------------------------
// Week header
// ---------------------------------------------------------------------------

class _WeekHeader extends ConsumerWidget {
  const _WeekHeader({
    required this.detachmentId,
    required this.weekStart,
    required this.summary,
  });

  final String detachmentId;
  final DateTime weekStart;
  final WeekSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final isThisWeek = weekStart == startOfWeek(DateTime.now());
    void step(int weeks) {
      ref.read(selectedWeekProvider(detachmentId).notifier).state =
          weekStart.add(Duration(days: 7 * weeks));
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Column(children: [
        Row(children: [
          // In RTL the "previous" arrow points right, which is what
          // `chevron_right` renders as after the layout mirrors it.
          _Nav(icon: Icons.chevron_right_rounded, onTap: () => step(-1)),
          Expanded(
            child: Column(children: [
              Text(
                isThisWeek ? S.thisWeek : S.weekOf,
                style: TextStyle(color: c.ink3, fontSize: 11),
              ),
              const SizedBox(height: 2),
              Text(
                AppDate.weekRange(weekStart),
                style: AppTypography.digits(c.ink, size: 14),
              ),
            ]),
          ),
          _Nav(icon: Icons.chevron_left_rounded, onTap: () => step(1)),
        ]),
        const SizedBox(height: AppSpacing.md),
        Row(children: [
          Expanded(
            child: _Stat(
              label: S.weekCoverage,
              value: '${toArabicIndic('${summary.coveragePercent}')}٪',
              tone: summary.coveragePercent >= 85
                  ? StatusKind.ok
                  : summary.coveragePercent >= 70
                      ? StatusKind.warn
                      : StatusKind.crit,
            ),
          ),
          Expanded(
            child: _Stat(
              label: S.weekShifts,
              value: toArabicIndic('${summary.shiftCount}'),
              tone: StatusKind.muted,
            ),
          ),
          Expanded(
            child: _Stat(
              label: S.weekGaps,
              value: toArabicIndic('${summary.gapShiftCount}'),
              tone: summary.gapShiftCount == 0
                  ? StatusKind.ok
                  : StatusKind.warn,
            ),
          ),
        ]),
        if (!isThisWeek) ...[
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () => ref
                .read(selectedWeekProvider(detachmentId).notifier)
                .state = startOfWeek(DateTime.now()),
            style: TextButton.styleFrom(
                minimumSize: const Size(0, 32), padding: EdgeInsets.zero),
            child: const Text(S.thisWeek),
          ),
        ],
      ]),
    );
  }
}

class _Nav extends StatelessWidget {
  const _Nav({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return PressScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: c.surface2, shape: BoxShape.circle),
        child: Icon(icon, size: 20, color: c.ink2),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.tone});

  final String label;
  final String value;
  final StatusKind tone;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final color = switch (tone) {
      StatusKind.ok => c.ok,
      StatusKind.warn => c.warn,
      StatusKind.crit => c.crit,
      StatusKind.info => c.info,
      StatusKind.muted => c.ink,
    };
    return Column(children: [
      TabularDigits(value, style: AppTypography.digits(color, size: 20)),
      const SizedBox(height: 2),
      Text(label,
          style: TextStyle(color: c.ink3, fontSize: 11),
          textAlign: TextAlign.center),
    ]);
  }
}

// ---------------------------------------------------------------------------
// Day strip
// ---------------------------------------------------------------------------

/// Seven days, each carrying its own shift count and a warning dot when any
/// of that day's shifts is short. The point is that a lead can see where the
/// week is thin without opening a single day.
class _DayStrip extends StatelessWidget {
  const _DayStrip({
    required this.weekStart,
    required this.selected,
    required this.countsFor,
    required this.onPick,
  });

  final DateTime weekStart;
  final int selected;
  final (int total, int gaps) Function(int offset) countsFor;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final today = dateOnly(DateTime.now());
    return SizedBox(
      height: 74,
      child: Row(children: [
        for (int i = 0; i < 7; i++) ...[
          Expanded(
            child: _DayChip(
              day: weekStart.add(Duration(days: i)),
              isToday: weekStart.add(Duration(days: i)) == today,
              selected: i == selected,
              counts: countsFor(i),
              onTap: () => onPick(i),
            ),
          ),
          if (i != 6) const SizedBox(width: 5),
        ],
      ]),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.day,
    required this.isToday,
    required this.selected,
    required this.counts,
    required this.onTap,
  });

  final DateTime day;
  final bool isToday;
  final bool selected;
  final (int total, int gaps) counts;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final (total, gaps) = counts;
    return PressScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: AnimatedContainer(
        duration: effectiveDuration(context, MotionTokens.short),
        curve: effectiveCurve(context, MotionTokens.standard),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? c.primary : c.surface,
          border: Border.all(
            color: selected
                ? c.primary
                : isToday
                    ? c.primary.withValues(alpha: 0.45)
                    : c.line,
          ),
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              // Two letters keep all seven columns readable at this width.
              AppDate.weekdayOf(day).substring(0, 2),
              style: TextStyle(
                color: selected ? c.primaryInk : c.ink2,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              toArabicIndic('${day.day}'),
              style: AppTypography.digits(
                selected ? c.primaryInk : c.ink,
                size: 15,
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 6,
              child: total == 0
                  ? null
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: gaps > 0
                                ? (selected ? c.warnTint : c.warn)
                                : (selected ? c.primaryInk : c.ok),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bulk actions
// ---------------------------------------------------------------------------

class _BulkActions extends ConsumerStatefulWidget {
  const _BulkActions({
    required this.detachmentId,
    required this.weekStart,
    required this.day,
  });

  final String detachmentId;
  final DateTime weekStart;
  final DateTime day;

  @override
  ConsumerState<_BulkActions> createState() => _BulkActionsState();
}

class _BulkActionsState extends ConsumerState<_BulkActions> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: _Action(
          icon: Icons.content_copy_rounded,
          label: S.copyLastWeek,
          onTap: _busy ? null : _copyLastWeek,
        ),
      ),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: _Action(
          icon: Icons.repeat_rounded,
          label: S.applyTemplates,
          onTap: _busy ? null : _applyTemplates,
        ),
      ),
      const SizedBox(width: AppSpacing.sm),
      _Action(
        icon: Icons.list_alt_rounded,
        label: null,
        onTap: _busy ? null : _openTemplates,
      ),
    ]);
  }

  void _refresh() {
    ref.invalidate(weekShiftsProvider);
    ref.invalidate(todaysShiftsProvider);
    ref.invalidate(shiftTemplatesProvider);
  }

  Future<void> _copyLastWeek() async {
    setState(() => _busy = true);
    final result = await ref.read(shiftRepositoryProvider).copyWeek(
          detachmentId: widget.detachmentId,
          fromWeekStart:
              widget.weekStart.subtract(const Duration(days: 7)),
          toWeekStart: widget.weekStart,
        );
    _refresh();
    if (!mounted) return;
    setState(() => _busy = false);
    result.when(
      success: (added, {stale = false}) => _say(
          added == 0 ? S.copyLastWeekEmpty : S.copyLastWeekDone),
      failure: (message, _) => _say(message),
      offline: (_) => _say(S.offlineTitle),
    );
  }

  Future<void> _applyTemplates() async {
    setState(() => _busy = true);
    final result = await ref.read(shiftRepositoryProvider).applyTemplates(
          detachmentId: widget.detachmentId,
          weekStart: widget.weekStart,
        );
    _refresh();
    if (!mounted) return;
    setState(() => _busy = false);
    result.when(
      success: (added, {stale = false}) => _say(
          added == 0 ? S.applyTemplatesEmpty : S.applyTemplatesDone),
      failure: (message, _) => _say(message),
      offline: (_) => _say(S.offlineTitle),
    );
  }

  Future<void> _openTemplates() async {
    await showAppSheet<void>(
      context: context,
      title: S.templatesTitle,
      child: _TemplatesBody(detachmentId: widget.detachmentId),
    );
    _refresh();
  }

  void _say(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String? label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final enabled = onTap != null;
    return PressScale(
      onTap: onTap,
      enabled: enabled,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: label == null ? AppSpacing.md : AppSpacing.sm,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: c.surface,
            border: Border.all(color: c.line),
            borderRadius: BorderRadius.circular(AppRadii.lg),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: c.primary),
              if (label != null) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(label!,
                      style: TextStyle(
                          color: c.ink2,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TemplatesBody extends ConsumerWidget {
  const _TemplatesBody({required this.detachmentId});

  final String detachmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.55,
      ),
      child: AsyncResultView<List<ShiftTemplate>>(
        value: ref.watch(shiftTemplatesProvider(detachmentId)),
        onRetry: () => ref.invalidate(shiftTemplatesProvider),
        loading: const Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Center(child: CircularProgressIndicator()),
        ),
        builder: (context, templates, stale) => templates.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Text(S.applyTemplatesEmpty,
                    textAlign: TextAlign.center),
              )
            : ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Text(S.templatesSub,
                      style: TextStyle(
                          color: c.ink3, fontSize: 12, height: 1.5)),
                  const SizedBox(height: AppSpacing.md),
                  for (final t in templates) ...[
                    _TemplateRow(template: t),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
      ),
    );
  }
}

class _TemplateRow extends ConsumerWidget {
  const _TemplateRow({required this.template});

  final ShiftTemplate template;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${AppDate.weekdayName(template.weekday)} · '
                '${template.centerName}',
                style: TextStyle(
                    color: c.ink, fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  AppDate.minuteRange(
                      template.startMinutes, template.endMinutes),
                  style: AppTypography.digits(c.ink3, size: 12),
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () async {
            await ref
                .read(shiftRepositoryProvider)
                .stopTemplate(template.id);
            ref.invalidate(shiftTemplatesProvider);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text(S.templateStopped)));
            }
          },
          style: TextButton.styleFrom(foregroundColor: c.crit),
          child: const Text(S.templateStop),
        ),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Day body
// ---------------------------------------------------------------------------

class _DayHeader extends StatelessWidget {
  const _DayHeader({
    required this.day,
    required this.count,
    required this.onAdd,
  });

  final DateTime day;
  final int count;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Row(children: [
      Expanded(
        child: Text(
          '${AppDate.weekdayOf(day)} · ${AppDate.dayMonth(day)}',
          style: TextStyle(
            color: c.ink3,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
      ),
      if (onAdd != null)
        PressScale(
          onTap: onAdd,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: Container(
            padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
            decoration: BoxDecoration(
              color: c.primaryTint,
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.add_rounded, size: 18, color: c.primary),
              const SizedBox(width: 6),
              Text(S.addShift,
                  style: TextStyle(
                      color: c.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
    ]);
  }
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay({required this.onAdd});

  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: EmptyState(
        icon: Icons.event_available_outlined,
        title: S.noShiftsToday,
        body: S.noShiftsTodaySub,
        actionLabel: onAdd == null ? null : S.addShift,
        onAction: onAdd,
      ),
    );
  }
}

class _ShiftCard extends ConsumerStatefulWidget {
  const _ShiftCard({
    required this.shift,
    required this.detachmentId,
    required this.canAssign,
    required this.canRecord,
    required this.canManage,
    required this.canDelete,
  });

  final Shift shift;
  final String detachmentId;
  final bool canAssign;
  final bool canRecord;
  final bool canManage;
  final bool canDelete;

  @override
  ConsumerState<_ShiftCard> createState() => _ShiftCardState();
}

class _ShiftCardState extends ConsumerState<_ShiftCard> {
  bool _busy = false;

  Shift get shift => widget.shift;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = Theme.of(context).textTheme;
    final running = shift.isRunningNow;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: running ? c.primary : c.line),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Flexible(
                      child: Text(shift.centerName,
                          style: t.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (shift.templateId != null) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.repeat_rounded, size: 14, color: c.ink3),
                    ],
                  ]),
                  const SizedBox(height: 2),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      AppDate.minuteRange(
                          shift.startMinutes, shift.endMinutes),
                      style: AppTypography.digits(c.ink2, size: 14),
                    ),
                  ),
                ],
              ),
            ),
            StatusChip(
              kind: running
                  ? StatusKind.info
                  : shift.hasCoverageGap
                      ? StatusKind.warn
                      : StatusKind.ok,
              label: running
                  ? S.now
                  : shift.hasCoverageGap
                      ? '${S.coverageGap} · ${toArabicIndic('${shift.gap}')}'
                      : S.shiftCoverageOk,
            ),
          ]),

          const SizedBox(height: AppSpacing.md),
          _CoverageBar(shift: shift),
          const SizedBox(height: AppSpacing.md),

          if (shift.attendees.isEmpty)
            Text(S.shiftNoAttendees,
                style: TextStyle(color: c.ink3, fontSize: 12))
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final a in shift.attendees)
                  _AttendeeChip(
                    member: a,
                    onTap: widget.canRecord
                        ? () => showAttendanceSheet(
                              context: context,
                              ref: ref,
                              shift: shift,
                              member: a,
                              canUnassign: widget.canAssign,
                            )
                        : null,
                  ),
              ],
            ),

          const SizedBox(height: AppSpacing.md),
          Row(children: [
            if (widget.canAssign) ...[
              Expanded(
                child: FilledButton.tonal(
                  onPressed: _busy
                      ? null
                      : () => showAssignSheet(
                            context: context,
                            ref: ref,
                            shift: shift,
                          ),
                  child: const Text(S.assignVolunteer),
                ),
              ),
              if (shift.hasCoverageGap) ...[
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : _quickFill,
                    child: const Text(S.quickFill),
                  ),
                ),
              ],
            ],
            if (widget.canManage) ...[
              const SizedBox(width: AppSpacing.sm),
              _Icon(
                icon: Icons.edit_outlined,
                onTap: _busy ? null : _edit,
              ),
            ],
            if (widget.canDelete) ...[
              const SizedBox(width: 6),
              _Icon(
                icon: Icons.delete_outline_rounded,
                tone: c.crit,
                onTap: _busy ? null : _confirmDelete,
              ),
            ],
          ]),
        ],
      ),
    );
  }

  void _refresh() {
    ref.invalidate(weekShiftsProvider);
    ref.invalidate(todaysShiftsProvider);
    ref.invalidate(shiftCandidatesProvider);
  }

  Future<void> _quickFill() async {
    setState(() => _busy = true);
    final result =
        await ref.read(shiftRepositoryProvider).quickFill(shift.id);
    _refresh();
    if (!mounted) return;
    setState(() => _busy = false);
    result.when(
      success: (added, {stale = false}) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(
              content: Text(added == 0 ? S.quickFillNone : S.quickFillDone))),
      failure: (message, _) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message))),
      offline: (_) => ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text(S.offlineTitle))),
    );
  }

  Future<void> _edit() async {
    await showShiftEditor(
      context: context,
      detachmentId: widget.detachmentId,
      date: shift.date,
      defaultCenter: shift.centerName,
      existing: shift,
    );
  }

  Future<void> _confirmDelete() async {
    final c = context.c;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(S.deleteShift),
        content: Text(
          '${shift.centerName} · '
          '${AppDate.minuteRange(shift.startMinutes, shift.endMinutes)}'
          '\n\n${S.deleteShiftBody}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(S.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: c.crit),
            child: const Text(S.delete),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _busy = true);
    await ref.read(shiftRepositoryProvider).delete(shift.id);
    _refresh();
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text(S.shiftDeleted)));
  }
}

/// Assigned against needed, as a bar rather than a fraction alone. A number
/// says how short the shift is; the bar says it at a glance across a list.
class _CoverageBar extends StatelessWidget {
  const _CoverageBar({required this.shift});

  final Shift shift;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final fill = shift.needed == 0 ? 1.0 : shift.assigned / shift.needed;
    final color = fill >= 1
        ? c.ok
        : fill >= 0.7
            ? c.warn
            : c.crit;
    return Column(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: SizedBox(
          height: 6,
          child: Stack(children: [
            Container(color: c.surface3),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: fill.clamp(0, 1)),
              duration: effectiveDuration(context, MotionTokens.progressFill),
              curve: effectiveCurve(context, MotionTokens.enter),
              builder: (context, v, _) => FractionallySizedBox(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: v,
                child: Container(color: color),
              ),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 6),
      Row(children: [
        Text(S.shiftAssignedOfNeeded,
            style: TextStyle(color: c.ink3, fontSize: 12)),
        const SizedBox(width: 6),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            '${toArabicIndic('${shift.assigned}')}'
            ' / ${toArabicIndic('${shift.needed}')}',
            style: AppTypography.digits(c.ink, size: 14),
          ),
        ),
      ]),
    ]);
  }
}

class _AttendeeChip extends StatelessWidget {
  const _AttendeeChip({required this.member, required this.onTap});

  final TeamMember member;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final (bg, fg) = switch (member.attendance) {
      AttendanceState.present => (c.okTint, c.ok),
      AttendanceState.late => (c.warnTint, c.warn),
      AttendanceState.absent => (c.critTint, c.crit),
      AttendanceState.notInvited => (c.mutedTint, c.ink2),
    };
    return PressScale(
      onTap: onTap,
      enabled: onTap != null,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(member.initials,
              style: TextStyle(
                  color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          Text(member.name, style: TextStyle(color: c.ink2, fontSize: 12)),
        ]),
      ),
    );
  }
}

class _Icon extends StatelessWidget {
  const _Icon({required this.icon, required this.onTap, this.tone});

  final IconData icon;
  final VoidCallback? onTap;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return PressScale(
      onTap: onTap,
      enabled: onTap != null,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.surface2,
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Icon(icon, size: 19, color: tone ?? c.ink2),
      ),
    );
  }
}
