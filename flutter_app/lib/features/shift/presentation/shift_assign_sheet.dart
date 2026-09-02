import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/app_date.dart';
import '../../../core/motion/press_scale.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_result.dart';
import '../../../core/widgets/sheet_scaffold.dart';
import '../../../l10n/strings.dart';
import '../../team/domain/team_models.dart';
import '../data/shift_providers.dart';
import '../domain/shift_models.dart';

/// Who to put on a shift.
///
/// Members already working an overlapping shift are **shown, not hidden**,
/// greyed with the shift they clash with. Hiding them makes the list look
/// broken to whoever is looking for a name they know is on the roster; naming
/// the clash answers the question the omission would raise.
Future<void> showAssignSheet({
  required BuildContext context,
  required WidgetRef ref,
  required Shift shift,
}) async {
  await showAppSheet<void>(
    context: context,
    title: '${S.assignSheetTitle} · ${AppDate.minuteRange(
      shift.startMinutes,
      shift.endMinutes,
    )}',
    child: _AssignBody(shift: shift),
  );
}

class _AssignBody extends ConsumerWidget {
  const _AssignBody({required this.shift});

  final Shift shift;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: AsyncResultView<List<ShiftCandidate>>(
        value: ref.watch(shiftCandidatesProvider(shift.id)),
        onRetry: () => ref.invalidate(shiftCandidatesProvider),
        loading: const Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Center(child: CircularProgressIndicator()),
        ),
        builder: (context, candidates, stale) {
          if (candidates.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child:
                  Text(S.allMembersAssigned, textAlign: TextAlign.center),
            );
          }
          final free = candidates.where((x) => !x.busy).length;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                    AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
                child: Row(children: [
                  Icon(Icons.check_circle_outline_rounded,
                      size: 15, color: c.ok),
                  const SizedBox(width: 6),
                  Text('${S.availableNow} · ${_ar(free)}',
                      style: TextStyle(color: c.ink3, fontSize: 12)),
                  const Spacer(),
                  Text('${S.shiftNeeded} ${_ar(shift.gap)}',
                      style: TextStyle(color: c.ink3, fontSize: 12)),
                ]),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0,
                      AppSpacing.lg, AppSpacing.lg),
                  itemCount: candidates.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _CandidateRow(
                    candidate: candidates[i],
                    onPick: () => _assign(context, ref, candidates[i]),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _ar(int n) =>
      n.toString().split('').map((d) => '٠١٢٣٤٥٦٧٨٩'[int.parse(d)]).join();

  Future<void> _assign(
      BuildContext context, WidgetRef ref, ShiftCandidate candidate) async {
    final result = await ref
        .read(shiftRepositoryProvider)
        .assignVolunteer(shift.id, candidate.member.id);
    ref.invalidate(weekShiftsProvider);
    ref.invalidate(todaysShiftsProvider);
    ref.invalidate(shiftCandidatesProvider);
    if (!context.mounted) return;
    result.when(
      // The sheet stays open on success: staffing a shift means adding
      // several people, and closing after each one turns one task into four.
      success: (_, {stale = false}) {},
      failure: (message, _) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message))),
      offline: (_) => ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text(S.offlineTitle))),
    );
  }
}

class _CandidateRow extends StatelessWidget {
  const _CandidateRow({required this.candidate, required this.onPick});

  final ShiftCandidate candidate;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final m = candidate.member;
    final busy = candidate.busy;
    return PressScale(
      onTap: onPick,
      enabled: !busy,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Opacity(
        opacity: busy ? 0.55 : 1,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: c.surface,
            border: Border.all(color: c.line),
            borderRadius: BorderRadius.circular(AppRadii.lg),
          ),
          child: Row(children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration:
                  BoxDecoration(color: c.mutedTint, shape: BoxShape.circle),
              child: Text(m.initials,
                  style: TextStyle(
                      color: c.ink2,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.name,
                      style: TextStyle(
                          color: c.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(
                    busy
                        ? '${S.busyNow} · ${candidate.busyWith == null ? '' : AppDate.minuteRange(candidate.busyWith!.startMinutes, candidate.busyWith!.endMinutes)}'
                        : _roleLabel(m.role),
                    style: TextStyle(
                      color: busy ? c.warn : c.ink3,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(busy ? Icons.block_rounded : Icons.add_rounded,
                color: busy ? c.ink3 : c.primary),
          ]),
        ),
      ),
    );
  }

  static String _roleLabel(TeamRole role) => switch (role) {
        TeamRole.lead => S.roleLead,
        TeamRole.medic => S.roleMedic,
        TeamRole.trainee => S.roleTrainee,
        TeamRole.volunteer => S.roleVolunteer,
      };
}

/// Attendance for one person on one shift, plus the way off the shift.
Future<void> showAttendanceSheet({
  required BuildContext context,
  required WidgetRef ref,
  required Shift shift,
  required TeamMember member,
  required bool canUnassign,
}) async {
  await showAppSheet<void>(
    context: context,
    title: '${S.attendanceSheetTitle} · ${member.name}',
    child: _AttendanceBody(
      shift: shift,
      member: member,
      canUnassign: canUnassign,
    ),
  );
}

class _AttendanceBody extends ConsumerWidget {
  const _AttendanceBody({
    required this.shift,
    required this.member,
    required this.canUnassign,
  });

  final Shift shift;
  final TeamMember member;
  final bool canUnassign;

  static const _options = [
    (AttendanceState.present, S.present, Icons.check_circle_rounded),
    (AttendanceState.late, S.late, Icons.schedule_rounded),
    (AttendanceState.absent, S.absent, Icons.cancel_rounded),
    (AttendanceState.notInvited, S.notInvited, Icons.remove_circle_outline),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(children: [
        for (final (state, label, icon) in _options) ...[
          _Option(
            label: label,
            icon: icon,
            selected: state == member.attendance,
            onTap: () => _mark(context, ref, state),
          ),
          const SizedBox(height: 8),
        ],
        if (canUnassign) ...[
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _unassign(context, ref),
              icon: Icon(Icons.person_remove_outlined,
                  size: 18, color: c.crit),
              label: Text(S.removeFromShift,
                  style: TextStyle(color: c.crit)),
              style: OutlinedButton.styleFrom(
                  side: BorderSide(color: c.crit.withValues(alpha: 0.5))),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
      ]),
    );
  }

  Future<void> _mark(
      BuildContext context, WidgetRef ref, AttendanceState state) async {
    await ref
        .read(shiftRepositoryProvider)
        .markAttendance(shift.id, member.id, state);
    ref.invalidate(weekShiftsProvider);
    ref.invalidate(todaysShiftsProvider);
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _unassign(BuildContext context, WidgetRef ref) async {
    await ref
        .read(shiftRepositoryProvider)
        .unassignVolunteer(shift.id, member.id);
    ref.invalidate(weekShiftsProvider);
    ref.invalidate(todaysShiftsProvider);
    ref.invalidate(shiftCandidatesProvider);
    if (context.mounted) Navigator.of(context).pop();
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
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
          color: selected ? c.primaryTint : c.surface,
          border: Border.all(color: selected ? c.primary : c.line),
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        child: Row(children: [
          Icon(icon, color: selected ? c.primary : c.ink2),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    color: selected ? c.primary : c.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w500)),
          ),
          if (selected) Icon(Icons.check_rounded, color: c.primary),
        ]),
      ),
    );
  }
}
