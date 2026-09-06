import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/access/capability.dart';
import '../../../../core/access/capability_guard.dart';
import '../../../../core/motion/motion_tokens.dart';
import '../../../../core/motion/press_scale.dart';
import '../../../../core/motion/stagger.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/async_result.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../../core/widgets/refresh_indicator.dart';
import '../../../../core/widgets/sheet_scaffold.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../l10n/strings.dart';
import '../../../shell/main_shell.dart';
import '../../../team/domain/team_models.dart';
import '../../data/workshop_providers.dart';
import '../../domain/workshop_models.dart';

enum _ParticipantFilter { all, members, guests }

class WorkshopMembersTab extends ConsumerStatefulWidget {
  const WorkshopMembersTab({super.key, required this.workshopId});

  final String workshopId;

  @override
  ConsumerState<WorkshopMembersTab> createState() => _WorkshopMembersTabState();
}

class _WorkshopMembersTabState extends ConsumerState<WorkshopMembersTab> {
  _ParticipantFilter _filter = _ParticipantFilter.all;

  @override
  Widget build(BuildContext context) {
    return AppRefreshIndicator(
      onRefresh: () =>
          ref.refresh(workshopParticipantsProvider(widget.workshopId).future),
      child: AsyncResultView<List<WorkshopParticipant>>(
        value: ref.watch(workshopParticipantsProvider(widget.workshopId)),
        onRetry: () => ref.invalidate(workshopParticipantsProvider),
        builder: (context, participants, stale) =>
            _content(context, participants, stale),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    List<WorkshopParticipant> participants,
    bool stale,
  ) {
    final filtered = switch (_filter) {
      _ParticipantFilter.all => participants,
      _ParticipantFilter.members =>
        participants.where((p) => p.kind == ParticipantKind.member).toList(),
      _ParticipantFilter.guests =>
        participants.where((p) => p.kind == ParticipantKind.guest).toList(),
    };

    return FloatingNavPadding(
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
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
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _FilterChip(
                label: S.filterAll,
                selected: _filter == _ParticipantFilter.all,
                onTap: () => setState(() => _filter = _ParticipantFilter.all),
              ),
              _FilterChip(
                label: S.filterMembers,
                selected: _filter == _ParticipantFilter.members,
                onTap: () =>
                    setState(() => _filter = _ParticipantFilter.members),
              ),
              _FilterChip(
                label: S.filterGuests,
                selected: _filter == _ParticipantFilter.guests,
                onTap: () =>
                    setState(() => _filter = _ParticipantFilter.guests),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (filtered.isEmpty)
            const EmptyState(
              icon: Icons.people_outline_rounded,
              title: S.emptyParticipants,
              body: S.emptyParticipantsSub,
            )
          else ...[
            for (int i = 0; i < filtered.length; i++) ...[
              Stagger(
                index: i,
                child: _ParticipantCard(
                  participant: filtered[i],
                  onTap: ref.whenCan(
                    Cap.workshopAttendanceRecord,
                    () => _attendanceSheet(context, filtered[i]),
                  ),
                ),
              ),
              if (i != filtered.length - 1)
                const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _attendanceSheet(
    BuildContext context,
    WorkshopParticipant participant,
  ) async {
    await showAppSheet<void>(
      context: context,
      title: '${S.attendanceSheetTitle} · ${participant.name}',
      child: _AttendancePicker(
        current: participant.attendance,
        onPick: (state) async {
          final result = await ref
              .read(workshopRepositoryProvider)
              .setParticipantAttendance(participant.id, state);
          ref.invalidate(workshopParticipantsProvider);
          if (!context.mounted) return;
          result.when(
            success: (_, {stale = false}) => Navigator.of(context).pop(),
            failure: (message, _) => ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(message))),
            offline: (_) => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(S.offlineTitle)),
            ),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: AnimatedContainer(
        duration: effectiveDuration(context, MotionTokens.short),
        curve: effectiveCurve(context, MotionTokens.standard),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: selected ? c.primary : c.surface,
          border: Border.all(color: selected ? c.primary : c.line2),
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? c.primaryInk : c.ink2,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _ParticipantCard extends StatelessWidget {
  const _ParticipantCard({required this.participant, required this.onTap});

  final WorkshopParticipant participant;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final (attendanceKind, attendanceLabel) = switch (participant.attendance) {
      AttendanceState.checkedIn => (StatusKind.ok, S.checkedIn),
      AttendanceState.checkedOut => (StatusKind.info, S.checkedOut),
      AttendanceState.absent => (StatusKind.crit, S.absent),
      AttendanceState.notCheckedIn => (StatusKind.muted, S.notCheckedIn),
    };
    final kindLabel =
        participant.kind == ParticipantKind.member ? S.kindMember : S.kindGuest;

    return PressScale(
      onTap: onTap,
      enabled: onTap != null,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: participant.kind == ParticipantKind.member
                  ? c.primaryTint
                  : c.infoTint,
              shape: BoxShape.circle,
            ),
            child: Text(
              participant.initials,
              style: TextStyle(
                color: participant.kind == ParticipantKind.member
                    ? c.primary
                    : c.info,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant.name,
                  style: TextStyle(
                    color: c.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(kindLabel, style: TextStyle(color: c.ink3, fontSize: 12)),
              ],
            ),
          ),
          StatusChip(kind: attendanceKind, label: attendanceLabel),
        ]),
      ),
    );
  }
}

class _AttendancePicker extends StatelessWidget {
  const _AttendancePicker({required this.current, required this.onPick});

  final AttendanceState current;
  final ValueChanged<AttendanceState> onPick;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    const options = [
      (AttendanceState.checkedIn, S.checkedIn, Icons.check_circle_rounded),
      (AttendanceState.checkedOut, S.checkedOut, Icons.logout_rounded),
      (AttendanceState.absent, S.absent, Icons.cancel_rounded),
      (
        AttendanceState.notCheckedIn,
        S.notCheckedIn,
        Icons.remove_circle_outline
      ),
    ];
    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: options.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) {
        final (state, label, icon) = options[i];
        final selected = state == current;
        return PressScale(
          onTap: () => onPick(state),
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
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? c.primary : c.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (selected) Icon(Icons.check_rounded, color: c.primary),
            ]),
          ),
        );
      },
    );
  }
}
