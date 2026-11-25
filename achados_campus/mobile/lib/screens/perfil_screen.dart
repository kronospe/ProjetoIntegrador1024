import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/telefone.dart';
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
    // a key recria a tela se trocar de usuário
    return _PerfilConteudo(key: ValueKey(usuario.id), usuario: usuario);
  }
}

class _PerfilConteudo extends ConsumerStatefulWidget {
  const _PerfilConteudo({super.key, required this.usuario});
  final Usuario usuario;

  @override
  ConsumerState<_PerfilConteudo> createState() => _PerfilConteudoState();
}

class _PerfilConteudoState extends ConsumerState<_PerfilConteudo> {
  late final TextEditingController _nome;
  late final TextEditingController _email;
  late final TextEditingController _telefone;
  late final TextEditingController _matricula;
  late final TextEditingController _bio;
  String? _curso;
  late String _avatar;

  
  late bool _editando;
  bool _escolhendoAvatar = false;
  bool _salvando = false;
  Map<String, String> _erros = {};
  String? _erroGeral;

  @override
  void initState() {
    super.initState();
    final u = widget.usuario;
    _nome = TextEditingController();
    _email = TextEditingController();
    _telefone = TextEditingController();
    _matricula = TextEditingController();
    _bio = TextEditingController();
    _preencher(u);
    _editando = !u.perfilCompleto;
  }

  
  void _preencher(Usuario u) {
    _nome.text = u.nome;
    _email.text = u.email;
    _telefone.text = formatarTelefone(u.telefone);
    _matricula.text = u.matricula?.toString() ?? '';
    _bio.text = u.bio;
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

  void _cancelar() {
    setState(() {
      _preencher(widget.usuario); // descarta o que foi digitado
      _erros = {};
      _erroGeral = null;
      _escolhendoAvatar = false;
      _editando = false;
    });
  }

  Future<void> _salvar() async {
    final erros = <String, String>{};
    if (_nome.text.trim().isEmpty) erros['nome'] = 'Nome obrigatório.';
    if (!_email.text.contains('@')) erros['email'] = 'E-mail inválido.';
    final tel = soDigitos(_telefone.text);
    if (tel.isEmpty) {
      erros['telefone'] = 'Telefone obrigatório.';
    } else if (tel.length < 10) {
      erros['telefone'] = 'Telefone incompleto. Use DDD + número.';
    }
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
      if (mounted) {
        setState(() {
          _editando = false;
          _escolhendoAvatar = false;
        });
        mostrarSnack(context, 'Perfil atualizado com sucesso!');
      }
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
    return Scaffold(
      body: SafeArea(
        child: _editando ? _formulario() : _visualizacao(),
      ),
    );
  }

  
  Widget _visualizacao() {
    final u = widget.usuario;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.purpleBg,
            child: Text(u.avatar, style: const TextStyle(fontSize: 44)),
          ),
        ),
        const SizedBox(height: 12),
        Text(u.nome,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(u.email,
            textAlign: TextAlign.center, style: const TextStyle(color: AppColors.text2)),
        if (u.bio.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(u.bio,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.text2, height: 1.4)),
        ],
        const SizedBox(height: 16),
        if (!u.perfilCompleto) _avisoIncompleto(),
        AppCard(
          child: Column(children: [
            _linha(Icons.phone_outlined, 'Telefone',
                u.telefone.isEmpty ? '—' : formatarTelefone(u.telefone)),
            _linha(Icons.badge_outlined, 'Matrícula', u.matricula?.toString() ?? '—'),
            _linha(Icons.school_outlined, 'Curso', u.curso.isEmpty ? '—' : u.curso),
          ]),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => setState(() => _editando = true),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Editar perfil'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
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
    );
  }

  Widget _linha(IconData icone, String rotulo, String valor) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Icon(icone, size: 18, color: AppColors.text2),
          const SizedBox(width: 10),
          Text('$rotulo: ', style: const TextStyle(color: AppColors.text2)),
          Expanded(child: Text(valor, style: const TextStyle(fontWeight: FontWeight.w600))),
        ]),
      );

  Widget _avisoIncompleto() => Container(
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
      );

  // ---------------------------------------------------------------- edição
  Widget _formulario() {
    final Opcoes? opcoes = ref.watch(opcoesProvider).valueOrNull;
    final cursos = opcoes?.cursos ?? const <String>[];
    // garante que o valor atual exista na lista do dropdown
    final itensCurso = {...cursos, if (_curso != null) _curso!}.toList();

    return ListView(
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
                        backgroundColor: a == _avatar ? AppColors.purpleBg : AppColors.surface,
                        child: Text(a, style: const TextStyle(fontSize: 24)),
                      ),
                    ))
                .toList(),
          ),
        const SizedBox(height: 12),
        if (!widget.usuario.perfilCompleto) _avisoIncompleto(),
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
          inputFormatters: [TelefoneFormatter()],
          maxLength: 15,
          decoration: campoDeco('Telefone', erro: _erros['telefone'], dica: '(81) 99999-9999'),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _matricula,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _salvando ? null : _cancelar,
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}
