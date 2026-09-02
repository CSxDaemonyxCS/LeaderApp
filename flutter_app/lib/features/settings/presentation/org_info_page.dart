import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/animated_counter.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/async_result.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/widgets/refresh_indicator.dart';
import '../../../l10n/strings.dart';
import '../../shell/main_shell.dart';
import '../data/settings_providers.dart';
import '../domain/settings_models.dart';

class OrgInfoPage extends ConsumerWidget {
  const OrgInfoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(title: const Text(S.settingsOrg)),
      body: AppRefreshIndicator(
        onRefresh: () => ref.refresh(orgInfoProvider.future),
        child: AsyncResultView<OrgInfo>(
          value: ref.watch(orgInfoProvider),
          onRetry: () => ref.invalidate(orgInfoProvider),
          builder: (context, info, stale) => _OrgContent(
            info: info,
            stale: stale,
          ),
        ),
      ),
    );
  }
}

class _OrgContent extends StatelessWidget {
  const _OrgContent({required this.info, required this.stale});

  final OrgInfo info;
  final bool stale;

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
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: c.primaryTint,
              border: Border.all(color: c.primary),
              borderRadius: BorderRadius.circular(AppRadii.xl),
            ),
            child: Row(children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                ),
                child: Icon(Icons.apartment_rounded, color: c.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  info.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ]),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            decoration: BoxDecoration(
              color: c.surface,
              border: Border.all(color: c.line),
              borderRadius: BorderRadius.circular(AppRadii.lg),
            ),
            child: Column(children: [
              _InfoRow(label: S.orgLegalName, value: Text(info.legalName)),
              Divider(height: 1, color: c.line),
              _InfoRow(label: S.orgAddress, value: Text(info.address)),
              Divider(height: 1, color: c.line),
              _InfoRow(
                label: S.orgEmail,
                value: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(info.emailPublic, textAlign: TextAlign.end),
                ),
              ),
              Divider(height: 1, color: c.line),
              _InfoRow(
                label: S.orgDetachments,
                value: TabularDigits(
                  toArabicIndic(info.detachmentCount.toString()),
                  style: AppTypography.digits(c.ink, size: 14),
                ),
              ),
              Divider(height: 1, color: c.line),
              _InfoRow(
                label: S.orgMembers,
                value: TabularDigits(
                  toArabicIndic(info.memberCount.toString()),
                  style: AppTypography.digits(c.ink, size: 14),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: TextStyle(color: c.ink3, fontSize: 13)),
          ),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: DefaultTextStyle(
              style: TextStyle(
                color: c.ink,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
              child: value,
            ),
          ),
        ],
      ),
    );
  }
}
