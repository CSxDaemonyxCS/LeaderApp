import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/access/capability.dart';
import '../../../core/access/capability_guard.dart';
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
import '../../tenant/data/tenant_providers.dart';
import '../../tenant/domain/tenant_models.dart';
import '../data/detachment_providers.dart';
import '../domain/detachment_models.dart';

/// The detachments of one tenant.
///
/// [tenantId] is null only on the unscoped list — every detachment the
/// session can see, regardless of tenant. Creating from that screen has no
/// tenant to create *into*, so the create action only appears when scoped.
class DetachmentListPage extends ConsumerStatefulWidget {
  const DetachmentListPage({super.key, this.tenantId});

  final String? tenantId;

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

  String? get _tenantId => widget.tenantId;

  void _openNew() => context.push('/tenant/$_tenantId/detachment/new');

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final q = DetachmentListQuery(
      tenantId: _tenantId,
      filter: _filter,
      query: _query,
    );
    final onCreate =
        _tenantId == null ? null : ref.whenCan(Cap.detachmentCreate, _openNew);

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: _tenantId == null
            ? const Text(S.detachmentListTitle)
            : _TenantTitle(tenantId: _tenantId!),
        actions: [
          if (_tenantId != null)
            IconButton(
              tooltip: S.editTenant,
              icon: const Icon(Icons.tune_rounded),
              onPressed: () => context.push('/tenant/$_tenantId/edit'),
            ),
          if (onCreate != null)
            IconButton(
              tooltip: S.createDetachment,
              icon: const Icon(Icons.add_rounded),
              onPressed: onCreate,
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
                hintText: S.searchDetachments,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(children: [
              _Filter(
                  label: S.filterAll,
                  active: _filter == null,
                  onTap: () => setState(() => _filter = null)),
              const SizedBox(width: 8),
              _Filter(
                  label: S.filterActive,
                  active: _filter == DetachmentStatus.active,
                  onTap: () =>
                      setState(() => _filter = DetachmentStatus.active)),
              const SizedBox(width: 8),
              _Filter(
                  label: S.filterArchived,
                  active: _filter == DetachmentStatus.archived,
                  onTap: () =>
                      setState(() => _filter = DetachmentStatus.archived)),
            ]),
          ]),
        ),
        Expanded(
          child: AppRefreshIndicator(
            onRefresh: () => ref.refresh(detachmentListProvider(q).future),
            child: AsyncResultView<List<Detachment>>(
              value: ref.watch(detachmentListProvider(q)),
              onRetry: () => ref.invalidate(detachmentListProvider),
              builder: (context, items, stale) => _list(items, onCreate),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _list(List<Detachment> items, VoidCallback? onCreate) {
    if (items.isEmpty) {
      final scoped = _tenantId != null;
      return EmptyState(
        icon: Icons.flag_outlined,
        title: scoped ? S.tenantEmptyDetachments : S.emptyDetachments,
        body: scoped ? S.tenantEmptyDetachmentsSub : S.emptyDetachmentsSub,
        actionLabel: onCreate == null ? null : S.createDetachment,
        onAction: onCreate,
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

/// The tenant's name as the screen title, so the container the list belongs
/// to is never in doubt. Falls back to the generic title while it loads
/// rather than to an empty app bar.
class _TenantTitle extends ConsumerWidget {
  const _TenantTitle({required this.tenantId});

  final String tenantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final name = ref.watch(tenantByIdProvider(tenantId)).whenOrNull(
              data: (r) => r.when(
                success: (Tenant t, {bool stale = false}) => t.name,
                failure: (_, __) => null,
                offline: (cached) => cached?.name,
              ),
            ) ??
        S.tenantsTitle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(name,
            style: Theme.of(context).appBarTheme.titleTextStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        Text(S.detachments, style: TextStyle(color: c.ink3, fontSize: 12)),
      ],
    );
  }
}

class _Filter extends StatelessWidget {
  const _Filter(
      {required this.label, required this.active, required this.onTap});
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

class _DetachmentCard extends StatelessWidget {
  const _DetachmentCard({required this.d});
  final Detachment d;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = Theme.of(context).textTheme;
    final archived = d.status == DetachmentStatus.archived;
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
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: archived ? c.mutedTint : c.primaryTint,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: Icon(Icons.flag_rounded,
                        color: archived ? c.ink3 : c.primary),
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
                            style: TextStyle(color: c.ink3, fontSize: 12)),
                      ],
                    ),
                  ),
                  StatusChip(
                    kind: archived ? StatusKind.muted : coverageTone,
                    label: archived
                        ? S.statusArchived
                        : '${toArabicIndic(d.coveragePercent.toString())}٪',
                  ),
                ]),
                const SizedBox(height: AppSpacing.md),
                // Wrap, not Row: "الشفتات هذا الأسبوع" plus a member count
                // does not fit one line on a narrow phone, and a clipped
                // figure is worse than a second line.
                Wrap(
                  spacing: AppSpacing.lg,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _mini(context, S.memberCount,
                        toArabicIndic(d.memberCount.toString())),
                    _mini(context, S.shiftCount,
                        toArabicIndic(d.weeklyShiftCount.toString())),
                  ],
                ),
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
