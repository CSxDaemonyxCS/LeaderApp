import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/access/capability.dart';
import '../../../../core/access/capability_guard.dart';
import '../../../../core/motion/animated_counter.dart';
import '../../../../core/motion/press_scale.dart';
import '../../../../core/motion/stagger.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/refresh_indicator.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../l10n/strings.dart';
import '../../../shell/main_shell.dart';
import '../../../team/data/team_providers.dart';
import '../../../team/domain/team_models.dart';

/// The detachment's roster: who is on it, and what each of them is.
///
/// A row carries the two things that identify a member on a roster — their
/// name and their role. Their department and their own number are part of
/// the record rather than part of the scan, so they live on the member's
/// form, one tap away.
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

  void _openNew(BuildContext context) =>
      context.push('/detachment/$detachmentId/member/new');

  void _openMember(BuildContext context, TeamMember m) =>
      context.push('/detachment/$detachmentId/member/${m.id}/edit');

  Widget _body(BuildContext context, WidgetRef ref, List<TeamMember> members) {
    // Adding is gated, and the gate is the same one the form resolves
    // against — an "add" that opens a page whose save button is dead is
    // worse than no "add" at all.
    final onAdd = ref.whenCan(
      Cap.memberInvite,
      () => _openNew(context),
      detachmentId: detachmentId,
    );

    if (members.isEmpty) {
      return EmptyState(
        icon: Icons.group_outlined,
        title: S.emptyTeam,
        body: S.emptyTeamSub,
        actionLabel: onAdd == null ? null : S.addMember,
        onAction: onAdd,
      );
    }

    return FloatingNavPadding(
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
        // One extra row for the header, which carries the roster count and
        // the add action.
        itemCount: members.length + 1,
        separatorBuilder: (_, i) =>
            SizedBox(height: i == 0 ? AppSpacing.md : 10),
        itemBuilder: (context, i) {
          if (i == 0) {
            return _RosterHeader(count: members.length, onAdd: onAdd);
          }
          final m = members[i - 1];
          return Stagger(
            index: i - 1,
            child: _MemberCard(
              member: m,
              onTap: () => _openMember(context, m),
            ),
          );
        },
      ),
    );
  }
}

/// Roster count on one side, the add action on the other. The count is real
/// information — how big this detachment is — rather than a decorative title.
class _RosterHeader extends StatelessWidget {
  const _RosterHeader({required this.count, required this.onAdd});

  final int count;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Row(children: [
      Expanded(
        child: Text(
          '${S.memberCount} · ${toArabicIndic(count.toString())}',
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
              Text(
                S.addMember,
                style: TextStyle(
                  color: c.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ]),
          ),
        ),
    ]);
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member, required this.onTap});

  final TeamMember member;
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
                const SizedBox(height: 3),
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
