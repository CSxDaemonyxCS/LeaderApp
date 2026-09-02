import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_result.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/widgets/refresh_indicator.dart';
import '../../../l10n/strings.dart';
import '../../shell/main_shell.dart';
import '../data/settings_providers.dart';
import '../domain/settings_models.dart';

enum _NotificationKind { shifts, stock, workshops, joins }

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  final Set<_NotificationKind> _updating = {};

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(title: const Text(S.settingsNotifications)),
      body: AppRefreshIndicator(
        onRefresh: () => ref.refresh(notificationPrefsProvider.future),
        child: AsyncResultView<NotificationPrefs>(
          value: ref.watch(notificationPrefsProvider),
          onRetry: () => ref.invalidate(notificationPrefsProvider),
          builder: (context, prefs, stale) => FloatingNavPadding(
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
                Container(
                  decoration: BoxDecoration(
                    color: c.surface,
                    border: Border.all(color: c.line),
                    borderRadius: BorderRadius.circular(AppRadii.lg),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(children: [
                    _NotificationRow(
                      title: S.notifShiftReminders,
                      subtitle: S.notifShiftRemindersSub,
                      value: prefs.shiftReminders,
                      enabled: _updating.isEmpty,
                      onChanged: (value) => _update(
                        prefs,
                        _NotificationKind.shifts,
                        value,
                      ),
                    ),
                    Divider(height: 1, color: c.line),
                    _NotificationRow(
                      title: S.notifStockAlerts,
                      subtitle: S.notifStockAlertsSub,
                      value: prefs.stockAlerts,
                      enabled: _updating.isEmpty,
                      onChanged: (value) => _update(
                        prefs,
                        _NotificationKind.stock,
                        value,
                      ),
                    ),
                    Divider(height: 1, color: c.line),
                    _NotificationRow(
                      title: S.notifWorkshopUpdates,
                      subtitle: S.notifWorkshopUpdatesSub,
                      value: prefs.workshopUpdates,
                      enabled: _updating.isEmpty,
                      onChanged: (value) => _update(
                        prefs,
                        _NotificationKind.workshops,
                        value,
                      ),
                    ),
                    Divider(height: 1, color: c.line),
                    _NotificationRow(
                      title: S.notifJoinRequests,
                      subtitle: S.notifJoinRequestsSub,
                      value: prefs.joinRequests,
                      enabled: _updating.isEmpty,
                      onChanged: (value) => _update(
                        prefs,
                        _NotificationKind.joins,
                        value,
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _update(
    NotificationPrefs current,
    _NotificationKind kind,
    bool value,
  ) async {
    setState(() => _updating.add(kind));
    final next = switch (kind) {
      _NotificationKind.shifts => current.copyWith(shiftReminders: value),
      _NotificationKind.stock => current.copyWith(stockAlerts: value),
      _NotificationKind.workshops => current.copyWith(workshopUpdates: value),
      _NotificationKind.joins => current.copyWith(joinRequests: value),
    };
    final result = await ref
        .read(settingsRepositoryProvider)
        .updateNotificationPrefs(next);
    ref.invalidate(notificationPrefsProvider);
    if (!mounted) return;
    setState(() => _updating.remove(kind));
    result.when(
      success: (_, {stale = false}) {},
      failure: (message, _) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message))),
      offline: (_) => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(S.offlineTitle)),
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: enabled ? onChanged : null,
      title: Text(title),
      subtitle: Text(subtitle),
      contentPadding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.md,
      ),
    );
  }
}
