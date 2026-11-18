import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../services/api_exception.dart';
import '../state/providers.dart';
import '../widgets/common.dart';

class CadastroScreen extends ConsumerStatefulWidget {
  const CadastroScreen({super.key});

  @override
  ConsumerState<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends ConsumerState<CadastroScreen> {
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _confirmar = TextEditingController();
  bool _enviando = false;
  String? _erroGeral;
  Map<String, String> _erros = {};

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _senha.dispose();
    _confirmar.dispose();
    super.dispose();
  }

  Future<void> _criar() async {
    // validação local (o servidor valida de novo)
    final erros = <String, String>{};
    if (_nome.text.trim().isEmpty) erros['nome'] = 'Informe seu nome.';
    if (!_email.text.contains('@')) erros['email'] = 'E-mail inválido.';
    if (_senha.text.length < 8) erros['senha'] = 'Mínimo de 8 caracteres.';
    if (_senha.text != _confirmar.text) erros['confirmar_senha'] = 'As senhas não coincidem.';
    if (erros.isNotEmpty) {
      setState(() {
        _erros = erros;
        _erroGeral = null;
      });
      return;
    }

    setState(() {
      _enviando = true;
      _erros = {};
      _erroGeral = null;
    });
    try {
      await ref.read(authProvider.notifier).cadastro(
            nome: _nome.text,
            email: _email.text,
            senha: _senha.text,
            confirmar: _confirmar.text,
          );
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _erros = e.fieldErrors;
          _erroGeral = e.fieldErrors.isEmpty ? e.message : null;
        });
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                TextField(
                  controller: _nome,
                  textCapitalization: TextCapitalization.words,
                  decoration: campoDeco('Nome completo', erro: _erros['nome']),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: campoDeco('E-mail', erro: _erros['email']),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _senha,
                  obscureText: true,
                  decoration: campoDeco('Senha (mín. 8 caracteres)', erro: _erros['senha']),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _confirmar,
                  obscureText: true,
                  onSubmitted: (_) => _criar(),
                  decoration: campoDeco('Confirmar senha', erro: _erros['confirmar_senha']),
                ),
                if (_erroGeral != null) ...[
                  const SizedBox(height: 12),
                  Text(_erroGeral!, style: const TextStyle(color: AppColors.red)),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _enviando ? null : _criar,
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  child: _enviando
                      ? const SizedBox(
                          width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Criar conta'),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
