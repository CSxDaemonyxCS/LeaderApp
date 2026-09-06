import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/motion/transitions.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animated_tab_bar.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/swipe_tabs.dart';
import '../../../l10n/strings.dart';
import '../../inventory/data/inventory_providers.dart';
import '../../inventory/domain/inventory_models.dart';
import '../../tenant/data/tenant_providers.dart';
import '../../tenant/domain/tenant_models.dart';
import '../data/detachment_providers.dart';
import '../domain/detachment_models.dart';
import '../domain/storage_status.dart';

/// Shell around a single detachment: the detachment name with the tenant it
/// belongs to underneath it, a persistent tab bar, and the active tab body.
///
/// The tenant line is not decoration. Two detachments in different tenants
/// can share a name, and the person looking at the screen has to be able to
/// tell which container they are working inside before they change anything.
class DetachmentDetailShell extends ConsumerWidget {
  const DetachmentDetailShell({
    super.key,
    required this.detachmentId,
    required this.location,
    required this.child,
  });

  final String detachmentId;
  final String location;
  final Widget child;

  static const _tabs = [
    (path: 'team', label: S.detachmentTeam),
    (path: 'shifts', label: S.detachmentShifts),
    (path: 'storage', label: S.detachmentStorage),
    (path: 'stats', label: S.detachmentStats),
  ];

  int _currentIndexFromLocation() {
    for (int i = 0; i < _tabs.length; i++) {
      if (location.endsWith('/${_tabs[i].path}')) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final detachment =
        ref.watch(detachmentByIdProvider(detachmentId)).whenOrNull(
              data: (r) => r.when(
                success: (Detachment d, {bool stale = false}) => d,
                failure: (_, __) => null,
                offline: (cached) => cached,
              ),
            );
    final tenantName = detachment == null
        ? null
        : ref.watch(tenantByIdProvider(detachment.tenantId)).whenOrNull(
              data: (r) => r.when(
                success: (Tenant t, {bool stale = false}) => t.name,
                failure: (_, __) => null,
                offline: (cached) => cached?.name,
              ),
            );

    final idx = _currentIndexFromLocation();
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(detachment?.name ?? '...',
                maxLines: 1, overflow: TextOverflow.ellipsis),
            if (tenantName != null)
              Text('${S.belongsTo} $tenantName',
                  style: TextStyle(color: c.ink3, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
          ],
        ),
        actions: [
          IconButton(
            tooltip: S.editDetachment,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/detachment/$detachmentId/edit'),
          ),
        ],
      ),
      body: Column(children: [
        _StatusStrip(detachmentId: detachmentId, detachment: detachment),
        AnimatedTabBar(
          tabs: _tabs.map((t) => t.label).toList(),
          currentIndex: idx,
          onChanged: (i) => context.go(
            '/detachment/$detachmentId/${_tabs[i].path}',
          ),
        ),
        Expanded(
          child: SwipeTabs(
            currentIndex: idx,
            tabCount: _tabs.length,
            onSwitch: (i) =>
                context.go('/detachment/$detachmentId/${_tabs[i].path}'),
            child: TabSwitchTransition(index: idx, child: child),
          ),
        ),
      ]),
    );
  }
}

/// The thin line under the app bar, on every tab: where this detachment
/// stands right now.
///
/// Two facts, because they answer two different questions a lead opens the
/// screen with. The lifecycle chip (نشطة / مؤرشفة) is the one the legacy
/// details header carried. The storage chip is new — a worst-wins rollup of
/// the stock the detachment holds, so "something is wrong in the store" is
/// visible without opening the storage tab.
class _StatusStrip extends ConsumerWidget {
  const _StatusStrip({required this.detachmentId, required this.detachment});

  final String detachmentId;
  final Detachment? detachment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;

    // Null while the detachment itself is still loading — the strip stays
    // empty rather than guessing a lifecycle state.
    if (detachment == null) return const SizedBox.shrink();

    final archived = detachment!.status == DetachmentStatus.archived;

    final stock = ref.watch(inventoryListProvider(detachmentId)).whenOrNull(
          data: (r) => r.when(
            success: (List<InventoryItem> items, {bool stale = false}) => items,
            failure: (_, __) => null,
            offline: (cached) => cached,
          ),
        );
    final storage = stock == null ? null : storageStatusOf(stock);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          StatusChip(
            kind: archived ? StatusKind.muted : StatusKind.ok,
            label: archived ? S.statusArchived : S.statusActive,
          ),
          if (storage != null)
            StatusChip(
              kind: _storageKind(storage),
              label: _storageLabel(storage),
            ),
        ],
      ),
    );
  }

  StatusKind _storageKind(StorageStatus s) => switch (s) {
        StorageStatus.healthy => StatusKind.ok,
        StorageStatus.expiring => StatusKind.warn,
        StorageStatus.low => StatusKind.warn,
        StorageStatus.depleted => StatusKind.crit,
        StorageStatus.empty => StatusKind.muted,
      };

  String _storageLabel(StorageStatus s) => switch (s) {
        StorageStatus.healthy => S.storageStatusHealthy,
        StorageStatus.expiring => S.storageStatusExpiring,
        StorageStatus.low => S.storageStatusLow,
        StorageStatus.depleted => S.storageStatusDepleted,
        StorageStatus.empty => S.storageStatusEmpty,
      };
}
