import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/motion/press_scale.dart';
import '../../../../core/motion/stagger.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/refresh_indicator.dart';
import '../../../../core/widgets/sheet_scaffold.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../l10n/strings.dart';
import '../../../shell/main_shell.dart';
import '../../../team/data/team_providers.dart';
import '../../../team/domain/team_models.dart';

class DetachmentTeamTab extends ConsumerWidget {
  const DetachmentTeamTab({super.key, required this.detachmentId});
  final String detachmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(teamListProvider(detachmentId));
    return AppRefreshIndicator(
      onRefresh: () async =>
          ref.refresh(teamListProvider(detachmentId).future),
      child: async.when(
        loading: () => const SkeletonList(),
        error: (_, __) => ErrorStateView(
            onRetry: () => ref.invalidate(teamListProvider)),
        data: (r) => r.when(
          success: (data, {stale = false}) => _body(context, ref, data),
          failure: (m, _) => ErrorStateView(
              body: m,
              onRetry: () => ref.invalidate(teamListProvider)),
          offline: (cached) => cached == null
              ? const EmptyState(
                  icon: Icons.cloud_off_rounded,
                  title: S.offlineTitle,
                  body: 'لا نسخة محفوظة.')
              : _body(context, ref, cached),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, List<TeamMember> members) {
    if (members.isEmpty) {
      return EmptyState(
        icon: Icons.group_outlined,
        title: S.emptyTeam,
        body: S.emptyTeamSub,
        actionLabel: S.addMember,
        onAction: () {},
      );
    }
    return FloatingNavPadding(
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: members.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) => Stagger(
          index: i,
          child: _MemberCard(
            member: members[i],
            onChangeRole: () => _changeRoleSheet(context, ref, members[i]),
          ),
        ),
      ),
    );
  }

  Future<void> _changeRoleSheet(
      BuildContext context, WidgetRef ref, TeamMember m) async {
    await showAppSheet<void>(
      context: context,
      title: S.changeRole,
      child: _RolePicker(
        current: m.role,
        onPick: (role) async {
          await ref
              .read(teamRepositoryProvider)
              .assignRole(m.id, role);
          ref.invalidate(teamListProvider);
          if (context.mounted) Navigator.of(context).pop();
        },
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member, required this.onChangeRole});
  final TeamMember member;
  final VoidCallback onChangeRole;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return PressScale(
      onTap: onChangeRole,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        child: Row(children: [
          _Avatar(initials: member.initials, kind: _kindFor(member.attendance)),
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
                _RoleChip(role: member.role),
              ],
            ),
          ),
          StatusChip(
              kind: _kindFor(member.attendance),
              label: _labelFor(member.attendance)),
        ]),
      ),
    );
  }

  StatusKind _kindFor(AttendanceState s) => switch (s) {
        AttendanceState.present => StatusKind.ok,
        AttendanceState.late => StatusKind.warn,
        AttendanceState.absent => StatusKind.crit,
        AttendanceState.notInvited => StatusKind.muted,
      };

  String _labelFor(AttendanceState s) => switch (s) {
        AttendanceState.present => S.present,
        AttendanceState.late => S.late,
        AttendanceState.absent => S.absent,
        AttendanceState.notInvited => S.notInvited,
      };
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.role});
  final TeamRole role;
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final label = switch (role) {
      TeamRole.lead => S.roleLead,
      TeamRole.medic => S.roleMedic,
      TeamRole.trainee => S.roleTrainee,
      TeamRole.volunteer => S.roleVolunteer,
    };
    final (bg, fg) = switch (role) {
      TeamRole.lead => (c.primaryTint, c.primary),
      TeamRole.medic => (c.infoTint, c.info),
      TeamRole.trainee => (c.warnTint, c.warn),
      TeamRole.volunteer => (c.mutedTint, c.ink2),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(AppRadii.pill)),
      child: Text(label,
          style: TextStyle(
              color: fg, fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials, required this.kind});
  final String initials;
  final StatusKind kind;
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final (bg, fg) = switch (kind) {
      StatusKind.ok => (c.okTint, c.ok),
      StatusKind.warn => (c.warnTint, c.warn),
      StatusKind.crit => (c.critTint, c.crit),
      StatusKind.info => (c.infoTint, c.info),
      StatusKind.muted => (c.mutedTint, c.ink2),
    };
    return Container(
      width: 40, height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Text(initials,
          style: TextStyle(
              color: fg, fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }
}

class _RolePicker extends StatelessWidget {
  const _RolePicker({required this.current, required this.onPick});
  final TeamRole current;
  final ValueChanged<TeamRole> onPick;
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final roles = [
      (TeamRole.lead, S.roleLead, Icons.workspace_premium_rounded),
      (TeamRole.medic, S.roleMedic, Icons.medical_services_rounded),
      (TeamRole.trainee, S.roleTrainee, Icons.school_rounded),
      (TeamRole.volunteer, S.roleVolunteer, Icons.volunteer_activism_rounded),
    ];
    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: roles.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final (r, label, icon) = roles[i];
        final selected = r == current;
        return PressScale(
          onTap: () => onPick(r),
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
      },
    );
  }
}
