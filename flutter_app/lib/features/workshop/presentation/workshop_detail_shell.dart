import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/access/capability.dart';
import '../../../core/access/capability_guard.dart';
import '../../../core/motion/transitions.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/animated_tab_bar.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../l10n/strings.dart';
import '../data/workshop_providers.dart';

/// Shell around a single workshop: title, the three tabs, and the active tab
/// body. Mirrors `DetachmentDetailShell` deliberately — the two detail
/// surfaces must feel identical.
class WorkshopDetailShell extends ConsumerWidget {
  const WorkshopDetailShell({
    super.key,
    required this.workshopId,
    required this.location,
    required this.child,
  });

  final String workshopId;
  final String location;
  final Widget child;

  static const _tabs = [
    (path: 'team', label: S.workshopTeam),
    (path: 'members', label: S.workshopMembers),
    (path: 'stats', label: S.workshopStats),
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
    final async = ref.watch(workshopByIdProvider(workshopId));
    final idx = _currentIndexFromLocation();
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: async.when(
          loading: () => const Text('...'),
          error: (_, __) => const Text(S.errTitle),
          data: (r) => r.when(
            success: (w, {stale = false}) => Text(w.name),
            failure: (_, __) => const Text(S.errTitle),
            offline: (cached) => Text(cached?.name ?? '...'),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: ref.whenCan(
              Cap.workshopEdit,
              () => context.push('/workshop/$workshopId/edit'),
            ),
          ),
        ],
      ),
      body: Column(children: [
        const OfflineBanner(visible: false, lastRefreshedAgoMinutes: 4),
        AnimatedTabBar(
          tabs: _tabs.map((t) => t.label).toList(),
          currentIndex: idx,
          onChanged: (i) =>
              context.go('/workshop/$workshopId/${_tabs[i].path}'),
        ),
        Expanded(child: TabCrossFade(child: child)),
      ]),
    );
  }
}
