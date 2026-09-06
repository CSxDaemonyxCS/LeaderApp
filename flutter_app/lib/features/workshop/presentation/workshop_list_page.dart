import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/access/capability.dart';
import '../../../core/access/capability_guard.dart';
import '../../../core/format/app_date.dart';
import '../../../core/motion/animated_counter.dart';
import '../../../core/motion/motion_tokens.dart';
import '../../../core/motion/press_scale.dart';
import '../../../core/motion/stagger.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/async_result.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/refresh_indicator.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../l10n/strings.dart';
import '../../shell/main_shell.dart';
import '../data/workshop_providers.dart';
import '../domain/workshop_models.dart';

/// Workshops are organisation-level: they carry no detachment id, so nothing
/// on this screen is scoped and `workshop.create` is checked globally.
enum _Bucket { all, upcoming, past }

class WorkshopListPage extends ConsumerStatefulWidget {
  const WorkshopListPage({super.key});

  @override
  ConsumerState<WorkshopListPage> createState() => _WorkshopListPageState();
}

class _WorkshopListPageState extends ConsumerState<WorkshopListPage> {
  final _search = TextEditingController();
  String _query = '';
  _Bucket _bucket = _Bucket.upcoming;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: const Text(S.workshopsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: ref.whenCan(
              Cap.workshopCreate,
              () => context.push('/workshop/new'),
            ),
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
          child: Column(children: [
            TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: S.searchWorkshops,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(children: [
              _Filter(
                label: S.filterAll,
                active: _bucket == _Bucket.all,
                onTap: () => setState(() => _bucket = _Bucket.all),
              ),
              const SizedBox(width: 8),
              _Filter(
                label: S.filterUpcoming,
                active: _bucket == _Bucket.upcoming,
                onTap: () => setState(() => _bucket = _Bucket.upcoming),
              ),
              const SizedBox(width: 8),
              _Filter(
                label: S.filterPast,
                active: _bucket == _Bucket.past,
                onTap: () => setState(() => _bucket = _Bucket.past),
              ),
            ]),
          ]),
        ),
        Expanded(
          child: AppRefreshIndicator(
            onRefresh: () => ref.refresh(workshopListProvider.future),
            child: AsyncResultView<List<Workshop>>(
              value: ref.watch(workshopListProvider),
              onRetry: () => ref.invalidate(workshopListProvider),
              builder: (context, all, stale) => _list(_apply(all)),
            ),
          ),
        ),
      ]),
    );
  }

  /// Search and bucket filtering happen on the client because the whole list
  /// is small; the repository takes no query parameters.
  List<Workshop> _apply(List<Workshop> all) {
    final now = DateTime.now();
    Iterable<Workshop> out = all;
    out = switch (_bucket) {
      _Bucket.all => out,
      _Bucket.upcoming => out.where((w) => w.at.isAfter(now)),
      _Bucket.past => out.where((w) => !w.at.isAfter(now)),
    };
    final q = _query.trim();
    if (q.isNotEmpty) {
      out = out.where((w) => w.name.contains(q) || w.location.contains(q));
    }
    return out.toList();
  }

  Widget _list(List<Workshop> items) {
    if (items.isEmpty) {
      return EmptyState(
        icon: Icons.school_outlined,
        title: S.emptyWorkshops,
        body: S.emptyWorkshopsSub,
        actionLabel: S.createWorkshop,
        onAction: ref.whenCan(
          Cap.workshopCreate,
          () => context.push('/workshop/new'),
        ),
      );
    }
    return FloatingNavPadding(
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, i) => Stagger(
          index: i,
          child: WorkshopCard(workshop: items[i]),
        ),
      ),
    );
  }
}

class _Filter extends StatelessWidget {
  const _Filter({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return PressScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: effectiveDuration(context, MotionTokens.short),
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
        decoration: BoxDecoration(
          color: active ? c.primary : c.surface,
          border: Border.all(color: active ? c.primary : c.line2),
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? c.primaryInk : c.ink2,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Shared with the workshop detail header so the two never drift.
StatusKind workshopStatusKind(WorkshopStatus s) => switch (s) {
      WorkshopStatus.scheduled => StatusKind.info,
      WorkshopStatus.ongoing => StatusKind.ok,
      WorkshopStatus.done => StatusKind.muted,
    };

String workshopStatusLabel(WorkshopStatus s) => switch (s) {
      WorkshopStatus.scheduled => S.workshopScheduled,
      WorkshopStatus.ongoing => S.workshopOngoing,
      WorkshopStatus.done => S.workshopDone,
    };

class WorkshopCard extends StatelessWidget {
  const WorkshopCard({super.key, required this.workshop});

  final Workshop workshop;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = Theme.of(context).textTheme;
    final w = workshop;
    final seatsLeft = (w.capacity - w.registered).clamp(0, w.capacity);
    return Hero(
      tag: 'workshop_${w.id}',
      child: Material(
        color: Colors.transparent,
        child: PressScale(
          onTap: () => GoRouter.of(context).push('/workshop/${w.id}/team'),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: c.surface,
              border: Border.all(color: c.line),
              borderRadius: BorderRadius.circular(AppRadii.lg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: c.infoTint,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: Icon(Icons.school_rounded, color: c.info),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(w.name,
                            style: t.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text('${AppDate.dayMonthTime(w.at)} · ${w.location}',
                            style: TextStyle(color: c.ink3, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  StatusChip(
                    kind: workshopStatusKind(w.status),
                    label: workshopStatusLabel(w.status),
                  ),
                ]),
                const SizedBox(height: AppSpacing.md),
                Row(children: [
                  _mini(
                      context,
                      S.registeredMembers,
                      '${toArabicIndic(w.registered.toString())}'
                      '/${toArabicIndic(w.capacity.toString())}'),
                  const SizedBox(width: AppSpacing.lg),
                  _mini(context, S.guests, toArabicIndic(w.guests.toString())),
                  const Spacer(),
                  if (w.isFull)
                    const StatusChip(kind: StatusKind.warn, label: S.full)
                  else
                    Text(
                      '${toArabicIndic(seatsLeft.toString())} '
                      '${S.workshopSeatsLeft}',
                      style: TextStyle(color: c.ink3, fontSize: 12),
                    ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _mini(BuildContext context, String label, String value) {
    final c = context.c;
    return Row(children: [
      Text(label, style: TextStyle(color: c.ink3, fontSize: 12)),
      const SizedBox(width: 6),
      Text(value, style: AppTypography.digits(c.ink, size: 14)),
    ]);
  }
}
