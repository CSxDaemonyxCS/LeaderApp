import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/motion/stagger.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/async_result.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/refresh_indicator.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../l10n/strings.dart';
import '../../../shell/main_shell.dart';
import '../../../team/domain/team_models.dart';
import '../../data/workshop_providers.dart';
import '../../domain/workshop_models.dart';

/// The workshop's organising team.
///
/// ASSUMPTION: read-only. `WorkshopRepository` exposes no method that mutates
/// `organizingTeam` — the only participant mutation it offers is
/// `setParticipantAttendance`, which belongs to the Members tab. When the
/// backend contract adds a team endpoint this tab gains the same role and
/// attendance sheets the detachment Members tab already has.
class WorkshopTeamTab extends ConsumerWidget {
  const WorkshopTeamTab({super.key, required this.workshopId});

  final String workshopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppRefreshIndicator(
      onRefresh: () => ref.refresh(workshopByIdProvider(workshopId).future),
      child: AsyncResultView<Workshop>(
        value: ref.watch(workshopByIdProvider(workshopId)),
        onRetry: () => ref.invalidate(workshopByIdProvider),
        builder: (context, w, stale) {
          if (w.organizingTeam.isEmpty) {
            return const EmptyState(
              icon: Icons.groups_outlined,
              title: S.emptyWorkshopTeam,
              body: S.emptyWorkshopTeamSub,
            );
          }
          return FloatingNavPadding(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: w.organizingTeam.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => Stagger(
                index: i,
                child: _OrganiserCard(member: w.organizingTeam[i]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OrganiserCard extends StatelessWidget {
  const _OrganiserCard({required this.member});

  final TeamMember member;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final roleLabel = switch (member.role) {
      TeamRole.lead => S.roleLead,
      TeamRole.medic => S.roleMedic,
      TeamRole.trainee => S.roleTrainee,
      TeamRole.volunteer => S.roleVolunteer,
    };
    final (kind, label) = switch (member.attendance) {
      AttendanceState.present => (StatusKind.ok, S.present),
      AttendanceState.late => (StatusKind.warn, S.late),
      AttendanceState.absent => (StatusKind.crit, S.absent),
      AttendanceState.notInvited => (StatusKind.muted, S.notInvited),
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
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration:
              BoxDecoration(color: c.primaryTint, shape: BoxShape.circle),
          child: Text(member.initials,
              style: TextStyle(
                  color: c.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(member.name,
                  style: TextStyle(
                      color: c.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(roleLabel,
                  style: TextStyle(color: c.ink3, fontSize: 12)),
            ],
          ),
        ),
        StatusChip(kind: kind, label: label),
      ]),
    );
  }
}
