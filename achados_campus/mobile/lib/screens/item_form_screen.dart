import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/item.dart';
import '../models/opcoes.dart';
import '../services/api_exception.dart';
import '../state/providers.dart';
import '../widgets/common.dart';

/// Cadastro (itemId == null) ou edição de um item.
class ItemFormScreen extends ConsumerStatefulWidget {
  const ItemFormScreen({super.key, this.itemId});
  final int? itemId;

  @override
  ConsumerState<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends ConsumerState<ItemFormScreen> {
  final _nome = TextEditingController();
  final _descricao = TextEditingController();
  String _situacao = 'encontrado';
  String? _local;
  String _icone = 'fa-laptop';
  DateTime _data = DateTime.now();

  Item? _original; // ao editar
  XFile? _foto;
  bool _removerFoto = false;

  bool _carregando = false;
  bool _enviando = false;
  String? _erroGeral;
  Map<String, String> _erros = {};

  bool get _editando => widget.itemId != null;

  @override
  void initState() {
    super.initState();
    if (_editando) _carregarOriginal();
  }

  @override
  void dispose() {
    _nome.dispose();
    _descricao.dispose();
    super.dispose();
  }

  Future<void> _carregarOriginal() async {
    setState(() => _carregando = true);
    try {
      final item = await ref.read(apiProvider).obterItem(widget.itemId!);
      if (!mounted) return;
      setState(() {
        _original = item;
        _nome.text = item.nome;
        _descricao.text = item.descricao;
        _situacao = item.situacao;
        _local = item.local;
        _icone = item.icone;
        _data = item.dataEncontro;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _erroGeral = e.message);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _escolherFoto() async {
    final origem = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_camera),
            title: const Text('Tirar foto'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Escolher da galeria'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
        ]),
      ),
    );
    if (origem == null) return;
    try {
      final f = await ImagePicker()
          .pickImage(source: origem, maxWidth: 1600, maxHeight: 1600, imageQuality: 85);
      if (f != null && mounted) {
        setState(() {
          _foto = f;
          _removerFoto = false;
        });
      }
    } catch (_) {
      if (mounted) mostrarSnack(context, 'Não foi possível acessar a foto.', erro: true);
    }
  }

  Future<void> _escolherData() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _data = d);
  }

  Future<void> _salvar(Opcoes opcoes) async {
    final erros = <String, String>{};
    if (_nome.text.trim().isEmpty) erros['nome'] = 'Informe o nome do item.';
    if (_descricao.text.trim().isEmpty) erros['descricao'] = 'Descreva o item.';
    if (_local == null) erros['local'] = 'Selecione o local.';
    if (erros.isNotEmpty) {
      setState(() => _erros = erros);
      return;
    }

    setState(() {
      _enviando = true;
      _erros = {};
      _erroGeral = null;
    });
    final api = ref.read(apiProvider);
    try {
      final Item salvo;
      if (_editando) {
        salvo = await api.atualizarItem(
          widget.itemId!,
          nome: _nome.text.trim(),
          descricao: _descricao.text.trim(),
          local: _local!,
          situacao: _situacao,
          icone: _icone,
          data: _data,
          foto: _foto,
          removerFoto: _removerFoto && _foto == null,
        );
      } else {
        salvo = await api.criarItem(
          nome: _nome.text.trim(),
          descricao: _descricao.text.trim(),
          local: _local!,
          situacao: _situacao,
          icone: _icone,
          data: _data,
          foto: _foto,
        );
      }
      if (!mounted) return;
      mostrarSnack(context, _editando ? 'Item atualizado' : 'Item cadastrado com sucesso');
      if (_editando) {
        context.pop();
      } else {
        // troca o formulário pela página do item recém-criado
        context.pushReplacement('/itens/${salvo.id}');
      }
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
    final opcoesAsync = ref.watch(opcoesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_editando ? 'Editar item' : 'Cadastrar item')),
      body: opcoesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErroView(
          mensagem: ApiException.from(e).message,
          onTentar: () => ref.invalidate(opcoesProvider),
        ),
        data: (opcoes) => _carregando
            ? const Center(child: CircularProgressIndicator())
            : _formulario(opcoes),
      ),
    );
  }

  Widget _formulario(Opcoes opcoes) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'encontrado', label: Text('Encontrei'), icon: Icon(Icons.check_circle_outline)),
              ButtonSegment(value: 'perdido', label: Text('Perdi'), icon: Icon(Icons.help_outline)),
            ],
            selected: {_situacao},
            onSelectionChanged: (s) => setState(() => _situacao = s.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nome,
            maxLength: 50,
            textCapitalization: TextCapitalization.sentences,
            decoration: campoDeco('Nome do item', erro: _erros['nome']),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _descricao,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: campoDeco('Descrição', erro: _erros['descricao']),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _local,
            decoration: campoDeco('Local', erro: _erros['local']),
            items: opcoes.locais
                .map((o) => DropdownMenuItem(value: o.valor, child: Text(o.nome)))
                .toList(),
            onChanged: (v) => setState(() => _local = v),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _escolherData,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: campoDeco('Data', erro: _erros['data_encontro'],
                  sufixo: const Icon(Icons.calendar_today, size: 18)),
              child: Text(fmtData(_data)),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Categoria', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: opcoes.icones
                .map((o) => ChoiceChip(
                      avatar: Icon(iconeDoItem(o.valor), size: 18),
                      label: Text(o.nome),
                      selected: _icone == o.valor,
                      onSelected: (_) => setState(() => _icone = o.valor),
                    ))
                .toList(),
          ),
          if (_erros['icone'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(_erros['icone']!, style: const TextStyle(color: AppColors.red)),
            ),
          const SizedBox(height: 20),
          const Text('Foto (opcional)', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _blocoFoto(),
          if (_erros['foto'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(_erros['foto']!, style: const TextStyle(color: AppColors.red)),
            ),
          if (_erroGeral != null) ...[
            const SizedBox(height: 12),
            Text(_erroGeral!, style: const TextStyle(color: AppColors.red)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _enviando ? null : () => _salvar(opcoes),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: _enviando
                ? const SizedBox(
                    width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(_editando ? 'Salvar alterações' : 'Cadastrar'),
          ),
        ],
      ),
    );
  }

  Widget _blocoFoto() {
    final fotoAtual = (_removerFoto || _foto != null) ? null : _original?.foto;
    Widget? preview;

    if (_foto != null) {
      preview = FutureBuilder(
        future: _foto!.readAsBytes(),
        builder: (_, snap) => snap.hasData
            ? Image.memory(snap.data!, height: 180, width: double.infinity, fit: BoxFit.cover)
            : const SizedBox(height: 180, child: Center(child: CircularProgressIndicator())),
      );
    } else if (fotoAtual != null) {
      preview = Image.network(fotoAtual,
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox(height: 180));
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (preview != null)
        ClipRRect(borderRadius: BorderRadius.circular(12), child: preview),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _escolherFoto,
            icon: const Icon(Icons.add_a_photo_outlined),
            label: Text(preview == null ? 'Adicionar foto' : 'Trocar foto'),
          ),
        ),
        if (preview != null) ...[
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => setState(() {
              _foto = null;
              _removerFoto = true;
            }),
            child: const Text('Remover'),
          ),
        ],
      ]),
    ]);
  }
}
