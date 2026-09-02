import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/motion/transitions.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/animated_tab_bar.dart';
import '../../../l10n/strings.dart';
import '../../tenant/data/tenant_providers.dart';
import '../../tenant/domain/tenant_models.dart';
import '../data/detachment_providers.dart';
import '../domain/detachment_models.dart';

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
    final detachment = ref.watch(detachmentByIdProvider(detachmentId)).whenOrNull(
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
        AnimatedTabBar(
          tabs: _tabs.map((t) => t.label).toList(),
          currentIndex: idx,
          onChanged: (i) => context.go(
            '/detachment/$detachmentId/${_tabs[i].path}',
          ),
        ),
        Expanded(child: TabCrossFade(child: child)),
      ]),
    );
  }
}
