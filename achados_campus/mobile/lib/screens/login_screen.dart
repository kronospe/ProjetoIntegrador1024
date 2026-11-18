import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../services/api_exception.dart';
import '../state/providers.dart';
import '../widgets/common.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _ocultar = true;
  bool _enviando = false;
  String? _erro;

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (_email.text.trim().isEmpty || _senha.text.isEmpty) {
      setState(() => _erro = 'Informe e-mail e senha.');
      return;
    }
    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      await ref.read(authProvider.notifier).login(_email.text, _senha.text);
      // o redirect do router leva para /itens
    } on ApiException catch (e) {
      if (mounted) setState(() => _erro = e.message);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Icon(Icons.travel_explore, size: 56, color: AppColors.purple),
                const SizedBox(height: 12),
                const Text('CampusAchados',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text('Achados e perdidos do campus',
                    textAlign: TextAlign.center, style: TextStyle(color: AppColors.text2)),
                const SizedBox(height: 32),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: campoDeco('E-mail'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _senha,
                  obscureText: _ocultar,
                  onSubmitted: (_) => _entrar(),
                  decoration: campoDeco(
                    'Senha',
                    sufixo: IconButton(
                      icon: Icon(_ocultar ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _ocultar = !_ocultar),
                    ),
                  ),
                ),
                if (_erro != null) ...[
                  const SizedBox(height: 12),
                  Text(_erro!, style: const TextStyle(color: AppColors.red)),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _enviando ? null : _entrar,
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  child: _enviando
                      ? const SizedBox(
                          width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Entrar'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.push('/cadastro'),
                  child: const Text('Não tem conta? Criar conta'),
                ),
                TextButton(
                  onPressed: () => context.go('/itens'),
                  child: const Text('Continuar sem entrar'),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
