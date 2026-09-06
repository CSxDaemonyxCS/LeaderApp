import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/motion/press_scale.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/strings.dart';
import '../data/auth_providers.dart';
import '_auth_scaffold.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final r = await ref.read(authRepositoryProvider).signIn(
          emailOrUsername: _email.text,
          password: _password.text,
        );
    if (!mounted) return;
    r.when(
      success: (_, {stale = false}) {
        setState(() => _busy = false);
        context.go('/home');
      },
      failure: (m, _) {
        setState(() {
          _busy = false;
          _error = m;
        });
      },
      offline: (_) {
        setState(() {
          _busy = false;
          _error = S.offlineTitle;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return AuthScaffold(
      title: S.loginTitle,
      subtitle: S.loginSub,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _email,
            decoration: const InputDecoration(labelText: S.emailLabel),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: S.passwordLabel),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: PressScale(
              onTap: () => context.push('/forgot'),
              child: Text(
                S.forgotPassword,
                style: TextStyle(
                  color: c.primary,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: c.critTint,
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(color: c.crit),
              ),
              child: Row(children: [
                Icon(Icons.error_outline_rounded, color: c.crit, size: 18),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(_error!,
                        style: TextStyle(color: c.crit, fontSize: 13))),
              ]),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: c.primaryInk),
                  )
                : const Text(S.signIn),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(
            onPressed: () => context.push('/mfa-challenge'),
            child: const Text('لديّ رمز تحقق ثنائي — متابعة'),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(S.noAccount, style: TextStyle(color: c.ink3, fontSize: 13)),
            const SizedBox(width: 6),
            PressScale(
              onTap: () {},
              child: Text(S.requestAccess,
                  style: TextStyle(
                      color: c.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ),
          ]),
        ],
      ),
    );
  }
}
