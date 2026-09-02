import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/app_date.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_result.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/widgets/refresh_indicator.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../l10n/strings.dart';
import '../../auth/data/auth_providers.dart';
import '../../auth/domain/auth_models.dart';
import '../../shell/main_shell.dart';

class SecurityPage extends ConsumerWidget {
  const SecurityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(title: const Text(S.settingsSecurity)),
      body: AppRefreshIndicator(
        onRefresh: () => ref.refresh(sessionsProvider.future),
        child: AsyncResultView<List<Session>>(
          value: ref.watch(sessionsProvider),
          onRetry: () => ref.invalidate(sessionsProvider),
          builder: (context, sessions, stale) => _SecurityContent(
            sessions: sessions,
            stale: stale,
            onRevoke: (session) => _confirmRevoke(context, ref, session),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmRevoke(
    BuildContext context,
    WidgetRef ref,
    Session session,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: const Text(S.securityRevokeConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(S.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(S.settingsRevoke),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result =
        await ref.read(authRepositoryProvider).revokeSession(session.id);
    ref.invalidate(sessionsProvider);
    if (!context.mounted) return;
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

class _SecurityContent extends StatelessWidget {
  const _SecurityContent({
    required this.sessions,
    required this.stale,
    required this.onRevoke,
  });

  final List<Session> sessions;
  final bool stale;
  final ValueChanged<Session> onRevoke;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
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
          Container(
            decoration: BoxDecoration(
              color: c.surface,
              border: Border.all(color: c.line),
              borderRadius: BorderRadius.circular(AppRadii.lg),
            ),
            child: ListTile(
              leading: Icon(Icons.verified_user_outlined, color: c.ok),
              title: const Text(S.securityMfa),
              subtitle: Text(S.securityMfaOn,
                  style: TextStyle(color: c.ok, fontSize: 12)),
              trailing: const Text(S.securityMfaManage),
              onTap: () => context.push('/mfa-setup'),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            S.settingsSessions,
            style: TextStyle(
              color: c.ink3,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (sessions.isEmpty)
            const EmptyState(
              icon: Icons.devices_other_outlined,
              title: S.emptySessions,
              body: S.emptySessionsSub,
            )
          else ...[
            for (int i = 0; i < sessions.length; i++) ...[
              _SessionCard(
                session: sessions[i],
                onRevoke:
                    sessions[i].current ? null : () => onRevoke(sessions[i]),
              ),
              if (i != sessions.length - 1)
                const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, required this.onRevoke});

  final Session session;
  final VoidCallback? onRevoke;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
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
          Row(children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: session.current ? c.okTint : c.mutedTint,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Icon(
                Icons.devices_rounded,
                color: session.current ? c.ok : c.ink2,
                size: 19,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                session.device,
                style: TextStyle(
                  color: c.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (session.current)
              const StatusChip(
                kind: StatusKind.ok,
                label: S.securityCurrentSession,
              )
            else
              TextButton(
                onPressed: onRevoke,
                child: const Text(S.settingsRevoke),
              ),
          ]),
          const SizedBox(height: AppSpacing.sm),
          Row(children: [
            Expanded(
              child: Text(
                session.locationLabel,
                style: TextStyle(color: c.ink3, fontSize: 12),
              ),
            ),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                session.ipMasked,
                style: TextStyle(color: c.ink3, fontSize: 12),
              ),
            ),
          ]),
          const SizedBox(height: AppSpacing.xs),
          Row(children: [
            Text(S.startedAt, style: TextStyle(color: c.ink3, fontSize: 12)),
            const SizedBox(width: AppSpacing.xs),
            Text(
              AppDate.dayMonth(session.startedAt),
              style: TextStyle(color: c.ink3, fontSize: 12),
            ),
            Text(' · ', style: TextStyle(color: c.ink3, fontSize: 12)),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                AppDate.time(session.startedAt),
                style: TextStyle(color: c.ink3, fontSize: 12),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}
