import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/strings.dart';
import '_auth_scaffold.dart';

class SessionExpiredPage extends StatelessWidget {
  const SessionExpiredPage({super.key});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return AuthScaffold(
      title: S.sessionExpiredTitle,
      subtitle: S.sessionExpiredSub,
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: c.warnTint,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: c.warn),
          ),
          child: Row(children: [
            Icon(Icons.lock_reset_rounded, color: c.warn),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('نحتاج التحقق من هويتك مرة أخرى قبل المتابعة.'),
            ),
          ]),
        ),
        const SizedBox(height: AppSpacing.xl),
        FilledButton(
          onPressed: () => context.go('/login'),
          child: const Text(S.signIn),
        ),
      ]),
    );
  }
}
