import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../l10n/strings.dart';
import '../../auth/data/auth_providers.dart';
import '../../auth/domain/auth_models.dart';
import '../../shell/main_shell.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final user = ref.watch(currentUserProvider);
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(title: const Text(S.settingsProfile)),
      body: user.when(
        loading: () => const SkeletonList(count: 3),
        error: (_, __) => ErrorStateView(
          onRetry: () => ref.invalidate(currentUserProvider),
        ),
        data: (value) => value == null
            ? const EmptyState(
                icon: Icons.person_off_outlined,
                title: S.profileNoSession,
                body: S.profileNoSessionSub,
              )
            : _ProfileContent(user: value),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return FloatingNavPadding(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Center(
            child: Container(
              width: 76,
              height: 76,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.primaryTint,
                shape: BoxShape.circle,
                border: Border.all(color: c.primary),
              ),
              child: Text(
                user.avatarInitials ?? S.appName,
                style: TextStyle(
                  color: c.primary,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            decoration: BoxDecoration(
              color: c.surface,
              border: Border.all(color: c.line),
              borderRadius: BorderRadius.circular(AppRadii.lg),
            ),
            child: Column(children: [
              _ProfileRow(
                icon: Icons.badge_outlined,
                label: S.profileName,
                value: Text(user.name),
              ),
              Divider(height: 1, color: c.line),
              _ProfileRow(
                icon: Icons.alternate_email_rounded,
                label: S.profileEmail,
                value: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(user.email, textAlign: TextAlign.end),
                ),
              ),
              Divider(height: 1, color: c.line),
              _ProfileRow(
                icon: Icons.apartment_rounded,
                label: S.profileOrg,
                value: Text(user.orgName, textAlign: TextAlign.end),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(children: [
        Icon(icon, color: c.ink3, size: 20),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: c.ink3, fontSize: 12)),
              const SizedBox(height: AppSpacing.xs),
              DefaultTextStyle(
                style: TextStyle(
                  color: c.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                child: value,
              ),
            ],
          ),
        ),
      ]),
    );
  }
}
