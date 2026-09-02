import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/motion/animated_counter.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/async_result.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../../core/widgets/refresh_indicator.dart';
import '../../../../l10n/strings.dart';
import '../../../shell/main_shell.dart';
import '../../../team/domain/team_models.dart';
import '../../data/workshop_providers.dart';
import '../../domain/workshop_models.dart';

// ASSUMPTION: this tab is not capability-gated. `stats.view` is scoped to a
// detachment, while workshops are organisation-level and have no scoped key.
class WorkshopStatsTab extends ConsumerWidget {
  const WorkshopStatsTab({super.key, required this.workshopId});

  final String workshopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppRefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          ref.refresh(workshopByIdProvider(workshopId).future),
          ref.refresh(workshopParticipantsProvider(workshopId).future),
        ]);
      },
      child: AsyncResultView<Workshop>(
        value: ref.watch(workshopByIdProvider(workshopId)),
        onRetry: () => ref.invalidate(workshopByIdProvider),
        builder: (context, workshop, workshopStale) =>
            AsyncResultView<List<WorkshopParticipant>>(
          value: ref.watch(workshopParticipantsProvider(workshopId)),
          onRetry: () => ref.invalidate(workshopParticipantsProvider),
          builder: (context, participants, participantsStale) => _StatsContent(
            workshop: workshop,
            participants: participants,
            stale: workshopStale || participantsStale,
          ),
        ),
      ),
    );
  }
}

class _StatsContent extends StatelessWidget {
  const _StatsContent({
    required this.workshop,
    required this.participants,
    required this.stale,
  });

  final Workshop workshop;
  final List<WorkshopParticipant> participants;
  final bool stale;

  @override
  Widget build(BuildContext context) {
    final present = participants
        .where((p) => p.attendance == AttendanceState.present)
        .length;
    // ASSUMPTION: a late participant is not included in the present count or
    // attendance percentage; both figures use the exact `present` state.
    final attendancePercent = participants.isEmpty
        ? 0
        : (present * 100 / participants.length).round();
    final capacityPercent = workshop.capacity == 0
        ? 0
        : (workshop.registered * 100 / workshop.capacity).round();

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
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.35,
            children: [
              _StatTile(
                icon: Icons.groups_rounded,
                label: S.totalParticipants,
                value: toArabicIndic(participants.length.toString()),
                tone: _StatTone.info,
              ),
              _StatTile(
                icon: Icons.how_to_reg_rounded,
                label: S.presentCount,
                value: toArabicIndic(present.toString()),
                tone: _StatTone.ok,
              ),
              _StatTile(
                icon: Icons.percent_rounded,
                label: S.attendancePercent,
                value:
                    '${toArabicIndic(attendancePercent.toString())}${S.percentSign}',
                tone: _StatTone.ok,
              ),
              _StatTile(
                icon: Icons.event_seat_rounded,
                label: S.capacityUsage,
                value:
                    '${toArabicIndic(capacityPercent.toString())}${S.percentSign}',
                tone: _StatTone.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _StatTone { primary, ok, info }

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.tone,
  });

  final IconData icon;
  final String label;
  final String value;
  final _StatTone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final (foreground, background) = switch (tone) {
      _StatTone.primary => (c.primary, c.primaryTint),
      _StatTone.ok => (c.ok, c.okTint),
      _StatTone.info => (c.info, c.infoTint),
    };
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Icon(icon, color: foreground, size: 18),
          ),
          const Spacer(),
          TabularDigits(
            value,
            style: AppTypography.number(c, size: 24),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: TextStyle(color: c.ink3, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
