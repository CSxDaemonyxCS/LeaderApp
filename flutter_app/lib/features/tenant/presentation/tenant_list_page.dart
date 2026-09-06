import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/access/capability.dart';
import '../../../core/access/capability_guard.dart';
import '../../../core/motion/animated_counter.dart';
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
import '../data/tenant_providers.dart';
import '../domain/tenant_models.dart';

/// The top of the hierarchy: the tenants a user works across.
///
/// A tenant is the umbrella; the detachments are inside it. Opening one lands
/// on its detachments, which is the only reason this screen exists — nothing
/// operational happens at the tenant level.
class TenantListPage extends ConsumerStatefulWidget {
  const TenantListPage({super.key});

  @override
  ConsumerState<TenantListPage> createState() => _TenantListPageState();
}

class _TenantListPageState extends ConsumerState<TenantListPage> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    // Creating a tenant is an organisation-level act, so it resolves against
    // the same key that creates a detachment: whoever may stand a detachment
    // up may stand up the umbrella it belongs to.
    final onCreate = ref.whenCan(
      Cap.detachmentCreate,
      () => context.push('/tenant/new'),
    );

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: const Text(S.tenantsTitle),
        actions: [
          if (onCreate != null)
            IconButton(
              tooltip: S.newTenant,
              icon: const Icon(Icons.add_rounded),
              onPressed: onCreate,
            ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
          child: TextField(
            controller: _search,
            onChanged: (v) => setState(() => _query = v),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              hintText: S.searchTenants,
            ),
          ),
        ),
        Expanded(
          child: AppRefreshIndicator(
            onRefresh: () => ref.refresh(tenantListProvider(_query).future),
            child: AsyncResultView<List<Tenant>>(
              value: ref.watch(tenantListProvider(_query)),
              onRetry: () => ref.invalidate(tenantListProvider),
              builder: (context, tenants, stale) =>
                  _list(context, tenants, onCreate),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _list(
      BuildContext context, List<Tenant> tenants, VoidCallback? onCreate) {
    if (tenants.isEmpty) {
      return EmptyState(
        icon: Icons.account_balance_outlined,
        title: S.emptyTenants,
        body: S.emptyTenantsSub,
        actionLabel: onCreate == null ? null : S.createTenant,
        onAction: onCreate,
      );
    }
    return FloatingNavPadding(
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        itemCount: tenants.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, i) {
          if (i == tenants.length) return const _TenantHint();
          return Stagger(
            index: i,
            child: _TenantCard(
              tenant: tenants[i],
              onOpen: () => context.push('/tenant/${tenants[i].id}'),
              onEdit: ref.whenCan(
                Cap.detachmentCreate,
                () => context.push('/tenant/${tenants[i].id}/edit'),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// One line under the list saying what a tenant *is*. Someone opening this
/// screen for the first time otherwise has to infer the hierarchy from two
/// nouns that sound alike in Arabic.
class _TenantHint extends StatelessWidget {
  const _TenantHint();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(children: [
        Icon(Icons.info_outline_rounded, size: 15, color: c.ink3),
        const SizedBox(width: 8),
        Expanded(
          child: Text(S.tenantHint,
              style: TextStyle(color: c.ink3, fontSize: 12, height: 1.5)),
        ),
      ]),
    );
  }
}

class _TenantCard extends StatelessWidget {
  const _TenantCard({
    required this.tenant,
    required this.onOpen,
    required this.onEdit,
  });

  final Tenant tenant;
  final VoidCallback onOpen;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = Theme.of(context).textTheme;
    final coverageTone = tenant.coveragePercent >= 85
        ? StatusKind.ok
        : tenant.coveragePercent >= 70
            ? StatusKind.warn
            : StatusKind.crit;

    return Hero(
      tag: 'tenant_${tenant.id}',
      child: Material(
        color: Colors.transparent,
        child: PressScale(
          onTap: onOpen,
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
                    child: Icon(Icons.account_balance_rounded, color: c.info),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tenant.name,
                            style: t.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        if (tenant.notes != null)
                          Text(tenant.notes!,
                              style: TextStyle(color: c.ink3, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  if (tenant.detachmentCount > 0)
                    StatusChip(
                      kind: coverageTone,
                      label: '${toArabicIndic('${tenant.coveragePercent}')}٪',
                    ),
                  if (onEdit != null)
                    IconButton(
                      tooltip: S.edit,
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.more_horiz_rounded, color: c.ink3),
                      onPressed: onEdit,
                    ),
                ]),
                const SizedBox(height: AppSpacing.md),
                Row(children: [
                  _Mini(
                    label: S.tenantDetachments,
                    value: toArabicIndic('${tenant.detachmentCount}'),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  _Mini(
                    label: S.tenantMembers,
                    value: toArabicIndic('${tenant.memberCount}'),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_left_rounded, color: c.ink3, size: 20),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Row(children: [
      Text(label, style: TextStyle(color: c.ink3, fontSize: 12)),
      const SizedBox(width: 6),
      Text(value, style: AppTypography.digits(c.ink, size: 14)),
    ]);
  }
}
