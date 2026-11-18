import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../models/opcoes.dart';
import '../models/usuario.dart';
import '../services/api_exception.dart';
import '../state/providers.dart';
import '../widgets/common.dart';

class PerfilScreen extends ConsumerWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(authProvider).valueOrNull;

    if (usuario == null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.account_circle_outlined, size: 72, color: AppColors.text3),
                const SizedBox(height: 12),
                const Text('Entre para cadastrar itens, reivindicar e editar seu perfil.',
                    textAlign: TextAlign.center, style: TextStyle(color: AppColors.text2)),
                const SizedBox(height: 20),
                FilledButton(onPressed: () => context.push('/login'), child: const Text('Entrar')),
                TextButton(
                    onPressed: () => context.push('/cadastro'), child: const Text('Criar conta')),
              ]),
            ),
          ),
        ),
      );
    }
    // a key recria o formulário se trocar de usuário
    return _PerfilForm(key: ValueKey(usuario.id), usuario: usuario);
  }
}

class _PerfilForm extends ConsumerStatefulWidget {
  const _PerfilForm({super.key, required this.usuario});
  final Usuario usuario;

  @override
  ConsumerState<_PerfilForm> createState() => _PerfilFormState();
}

class _PerfilFormState extends ConsumerState<_PerfilForm> {
  late final TextEditingController _nome;
  late final TextEditingController _email;
  late final TextEditingController _telefone;
  late final TextEditingController _matricula;
  late final TextEditingController _bio;
  String? _curso;
  late String _avatar;
  bool _escolhendoAvatar = false;
  bool _salvando = false;
  Map<String, String> _erros = {};
  String? _erroGeral;

  @override
  void initState() {
    super.initState();
    final u = widget.usuario;
    _nome = TextEditingController(text: u.nome);
    _email = TextEditingController(text: u.email);
    _telefone = TextEditingController(text: u.telefone);
    _matricula = TextEditingController(text: u.matricula?.toString() ?? '');
    _bio = TextEditingController(text: u.bio);
    _curso = u.curso.isEmpty ? null : u.curso;
    _avatar = u.avatar;
  }

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _telefone.dispose();
    _matricula.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final erros = <String, String>{};
    if (_nome.text.trim().isEmpty) erros['nome'] = 'Nome obrigatório.';
    if (!_email.text.contains('@')) erros['email'] = 'E-mail inválido.';
    if (_telefone.text.trim().isEmpty) erros['telefone'] = 'Telefone obrigatório.';
    final mat = int.tryParse(_matricula.text.trim());
    if (mat == null) erros['matricula'] = 'Informe a matrícula (somente números).';
    if (_curso == null) erros['curso'] = 'Selecione seu curso.';
    if (erros.isNotEmpty) {
      setState(() => _erros = erros);
      return;
    }

    setState(() {
      _salvando = true;
      _erros = {};
      _erroGeral = null;
    });
    try {
      await ref.read(authProvider.notifier).atualizarPerfil({
        'nome': _nome.text.trim(),
        'email': _email.text.trim(),
        'telefone': _telefone.text.trim(),
        'matricula': mat,
        'curso': _curso,
        'avatar': _avatar,
        'bio': _bio.text.trim(),
      });
      if (mounted) mostrarSnack(context, 'Perfil atualizado com sucesso!');
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _erros = e.fieldErrors;
          _erroGeral = e.fieldErrors.isEmpty ? e.message : null;
        });
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _sair() async {
    final ok = await confirmar(context, 'Sair', 'Deseja sair da sua conta?',
        confirmarLabel: 'Sair');
    if (ok) await ref.read(authProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    final Opcoes? opcoes = ref.watch(opcoesProvider).valueOrNull;
    final cursos = opcoes?.cursos ?? const <String>[];
    // garante que o valor atual exista na lista do dropdown
    final itensCurso = {...cursos, if (_curso != null) _curso!}.toList();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: GestureDetector(
                onTap: () => setState(() => _escolhendoAvatar = !_escolhendoAvatar),
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.purpleBg,
                  child: Text(_avatar, style: const TextStyle(fontSize: 40)),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: TextButton(
                onPressed: () => setState(() => _escolhendoAvatar = !_escolhendoAvatar),
                child: const Text('Escolher avatar'),
              ),
            ),
            if (_escolhendoAvatar)
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: avatares
                    .map((a) => InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () => setState(() {
                            _avatar = a;
                            _escolhendoAvatar = false;
                          }),
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor:
                                a == _avatar ? AppColors.purpleBg : AppColors.surface,
                            child: Text(a, style: const TextStyle(fontSize: 24)),
                          ),
                        ))
                    .toList(),
              ),
            const SizedBox(height: 12),
            if (!widget.usuario.perfilCompleto)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.yellowBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Complete telefone e matrícula para que quem encontrar (ou perder) um item possa falar com você.',
                  style: TextStyle(color: AppColors.yellow),
                ),
              ),
            TextField(
              controller: _nome,
              textCapitalization: TextCapitalization.words,
              decoration: campoDeco('Nome', erro: _erros['nome']),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: campoDeco('E-mail', erro: _erros['email']),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _telefone,
              keyboardType: TextInputType.phone,
              maxLength: 15,
              decoration: campoDeco('Telefone', erro: _erros['telefone']),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _matricula,
              keyboardType: TextInputType.number,
              decoration: campoDeco('Matrícula', erro: _erros['matricula']),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _curso,
              decoration: campoDeco('Curso', erro: _erros['curso']),
              items: itensCurso.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _curso = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bio,
              maxLines: 3,
              decoration: campoDeco('Bio (opcional)'),
            ),
            if (_erroGeral != null) ...[
              const SizedBox(height: 10),
              Text(_erroGeral!, style: const TextStyle(color: AppColors.red)),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _salvando ? null : _salvar,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              child: _salvando
                  ? const SizedBox(
                      width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Salvar perfil'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.push('/meus-itens'),
              icon: const Icon(Icons.inventory_2_outlined),
              label: const Text('Meus itens e reivindicações'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _sair,
              icon: const Icon(Icons.logout, color: AppColors.red),
              label: const Text('Sair', style: TextStyle(color: AppColors.red)),
            ),
          ],
        ),
      ),
    );
  }
}
