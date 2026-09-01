import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/motion/animated_counter.dart';
import '../../../core/motion/motion_tokens.dart';
import '../../../core/motion/press_scale.dart';
import '../../../core/motion/stagger.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/refresh_indicator.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../l10n/strings.dart';
import '../../shell/main_shell.dart';
import '../data/detachment_providers.dart';
import '../domain/detachment_models.dart';
import '../../../core/theme/app_typography.dart';

class DetachmentListPage extends ConsumerStatefulWidget {
  const DetachmentListPage({super.key});

  @override
  ConsumerState<DetachmentListPage> createState() => _S();
}

class _S extends ConsumerState<DetachmentListPage> {
  DetachmentStatus? _filter = DetachmentStatus.active;
  String _query = '';
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final q = DetachmentListQuery(filter: _filter, query: _query);
    final async = ref.watch(detachmentListProvider(q));
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: const Text(S.detachmentListTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.push('/detachment/new'),
          ),
        ],
      ),
      body: Column(children: [
        // Search + filter chips
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
          child: Column(children: [
            TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: S.searchDetachments,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(children: [
              _Filter(label: S.filterAll,
                  active: _filter == null,
                  onTap: () => setState(() => _filter = null)),
              const SizedBox(width: 8),
              _Filter(label: S.filterActive,
                  active: _filter == DetachmentStatus.active,
                  onTap: () =>
                      setState(() => _filter = DetachmentStatus.active)),
              const SizedBox(width: 8),
              _Filter(label: S.filterArchived,
                  active: _filter == DetachmentStatus.archived,
                  onTap: () =>
                      setState(() => _filter = DetachmentStatus.archived)),
            ]),
          ]),
        ),
        Expanded(
          child: AppRefreshIndicator(
            onRefresh: () async =>
                ref.refresh(detachmentListProvider(q).future),
            child: async.when(
              loading: () => const SkeletonList(),
              error: (e, _) => ErrorStateView(
                onRetry: () => ref.invalidate(detachmentListProvider),
              ),
              data: (r) => r.when(
                success: (data, {stale = false}) => _list(data),
                failure: (m, _) => ErrorStateView(
                  body: m,
                  onRetry: () => ref.invalidate(detachmentListProvider),
                ),
                offline: (cached) => cached == null
                    ? const EmptyState(
                        icon: Icons.cloud_off_rounded,
                        title: S.offlineTitle,
                        body: 'لا نسخة محفوظة.',
                      )
                    : _list(cached),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _list(List<Detachment> items) {
    if (items.isEmpty) {
      return EmptyState(
        icon: Icons.flag_outlined,
        title: S.emptyDetachments,
        body: S.emptyDetachmentsSub,
        actionLabel: S.createDetachment,
        onAction: () => context.push('/detachment/new'),
      );
    }
    return FloatingNavPadding(
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, i) => Stagger(
          index: i,
          child: _DetachmentCard(d: items[i]),
        ),
      ),
    );
  }
}

class _Filter extends StatelessWidget {
  const _Filter({required this.label, required this.active, required this.onTap});
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
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 6),
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

class _DetachmentCard extends StatelessWidget {
  const _DetachmentCard({required this.d});
  final Detachment d;
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = Theme.of(context).textTheme;
    final coverageTone = d.coveragePercent >= 85
        ? StatusKind.ok
        : d.coveragePercent >= 70
            ? StatusKind.warn
            : StatusKind.crit;
    return Hero(
      tag: 'detachment_${d.id}',
      child: Material(
        color: Colors.transparent,
        child: PressScale(
          onTap: () => GoRouter.of(context).push('/detachment/${d.id}/team'),
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
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: c.primaryTint,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: Icon(Icons.flag_rounded, color: c.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.name,
                            style: t.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text('${d.region} · ${d.mainCenter}',
                            style: TextStyle(
                                color: c.ink3, fontSize: 12)),
                      ],
                    ),
                  ),
                  StatusChip(
                    kind: coverageTone,
                    label: '${toArabicIndic(d.coveragePercent.toString())}٪',
                  ),
                ]),
                const SizedBox(height: AppSpacing.md),
                Row(children: [
                  _mini(context, S.memberCount,
                      toArabicIndic(d.memberCount.toString())),
                  const SizedBox(width: AppSpacing.lg),
                  _mini(context, S.shiftCount,
                      toArabicIndic(d.weeklyShiftCount.toString())),
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
      Text(value,
          style: AppTypography.digits(c.ink, size: 14)),
    ]);
  }
}
