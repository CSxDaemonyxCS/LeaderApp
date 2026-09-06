import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/motion/animated_counter.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../l10n/strings.dart';
import '../data/auth_providers.dart';
import '../domain/auth_models.dart';
import '_auth_scaffold.dart';
import '../../../core/theme/app_typography.dart';

final _mfaSetupProvider = FutureProvider<MfaSetupData>((ref) async {
  final r = await ref.read(authRepositoryProvider).beginMfaSetup();
  return r.when(
    success: (d, {stale = false}) => d,
    failure: (m, _) => throw Exception(m),
    offline: (cached) => cached ?? (throw Exception('offline')),
  );
});

class MfaSetupPage extends ConsumerWidget {
  const MfaSetupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_mfaSetupProvider);
    final c = context.c;
    return AuthScaffold(
      title: S.mfaSetupTitle,
      subtitle: S.mfaSetupSub,
      showBack: true,
      child: async.when(
        loading: () => Column(children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(AppRadii.xl),
              border: Border.all(color: c.line),
            ),
            child: const SizedBox(
              height: 200,
              width: 200,
              child: Center(child: Skeleton(width: 200, height: 200)),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Skeleton(width: 200, height: 14),
        ]),
        error: (e, st) =>
            Text(e.toString(), style: TextStyle(color: c.crit, fontSize: 13)),
        data: (data) => _Setup(data: data),
      ),
    );
  }
}

class _Setup extends StatelessWidget {
  const _Setup({required this.data});
  final MfaSetupData data;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadii.xl),
            border: Border.all(color: c.line),
          ),
          child: Center(
            child: QrImageView(
              data: data.otpauthUrl,
              size: 220,
              backgroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _Field(
          label: S.mfaManualSecret,
          value: data.manualSecret,
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(S.mfaBackupCodesTitle, style: t.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(S.mfaBackupCodesSub, style: t.bodyMedium?.copyWith(color: c.ink3)),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: c.surface,
            border: Border.all(color: c.line),
            borderRadius: BorderRadius.circular(AppRadii.lg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 3.2,
                children: [
                  for (final code in data.backupCodes)
                    Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: c.surface2,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                      child: Text(
                        toArabicIndic(code),
                        style: AppTypography.digits(c.ink, letterSpacing: 1),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                icon: const Icon(Icons.copy_rounded, size: 18),
                onPressed: () async {
                  await Clipboard.setData(
                      ClipboardData(text: data.backupCodes.join('\n')));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text(S.copied)));
                  }
                },
                label: const Text(S.copy),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        FilledButton(
          onPressed: () => context.go('/mfa-challenge'),
          child: const Text('متابعة'),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: c.line),
      ),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: c.ink3, fontSize: 11)),
              const SizedBox(height: 4),
              Text(value,
                  style:
                      AppTypography.digits(c.ink, size: 15, letterSpacing: 1)),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy_rounded, size: 18),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: value));
            if (context.mounted) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text(S.copied)));
            }
          },
        ),
      ]),
    );
  }
}
