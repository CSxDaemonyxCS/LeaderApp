import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/motion/transitions.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/animated_tab_bar.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../l10n/strings.dart';
import '../data/detachment_providers.dart';

/// Shell around a single detachment: app bar with the detachment name,
/// persistent animated tab bar, and the currently active inner tab body.
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
    final async = ref.watch(detachmentByIdProvider(detachmentId));
    final idx = _currentIndexFromLocation();
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: async.when(
          loading: () => const Text('...'),
          error: (_, __) => const Text(S.errTitle),
          data: (r) => r.when(
            success: (d, {stale = false}) => Text(d.name),
            failure: (_, __) => const Text(S.errTitle),
            offline: (cached) => Text(cached?.name ?? '...'),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () =>
                context.push('/detachment/$detachmentId/edit'),
          ),
        ],
      ),
      body: Column(children: [
        const OfflineBanner(visible: false, lastRefreshedAgoMinutes: 4),
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
