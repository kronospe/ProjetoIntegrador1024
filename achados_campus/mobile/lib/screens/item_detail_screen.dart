import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/item.dart';
import '../services/api_exception.dart';
import '../state/providers.dart';
import '../widgets/common.dart';

class ItemDetailScreen extends ConsumerStatefulWidget {
  const ItemDetailScreen({super.key, required this.id});
  final int id;

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  Item? _item;
  String? _erro;
  bool _ocupado = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _erro = null);
    try {
      final item = await ref.read(apiProvider).obterItem(widget.id);
      if (mounted) setState(() => _item = item);
    } on ApiException catch (e) {
      if (mounted) setState(() => _erro = e.message);
    }
  }

  Future<void> _excluir() async {
    final ok = await confirmar(context, 'Excluir item',
        'Essa ação não pode ser desfeita. Deseja excluir "${_item!.nome}"?',
        confirmarLabel: 'Excluir');
    if (!ok) return;
    setState(() => _ocupado = true);
    try {
      await ref.read(apiProvider).excluirItem(widget.id);
      if (!mounted) return;
      mostrarSnack(context, 'Item excluído com sucesso');
      context.pop();
    } on ApiException catch (e) {
      if (mounted) mostrarSnack(context, e.message, erro: true);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _decidir(String decisao) async {
    final aprovar = decisao == 'aprovada';
    final ok = await confirmar(
      context,
      aprovar ? 'Aprovar reivindicação' : 'Recusar reivindicação',
      aprovar
          ? 'O item será marcado como entregue e os contatos serão liberados.'
          : 'O item voltará a ficar disponível para outras pessoas.',
      confirmarLabel: aprovar ? 'Aprovar' : 'Recusar',
    );
    if (!ok) return;
    setState(() => _ocupado = true);
    try {
      final item = await ref.read(apiProvider).decidir(widget.id, decisao);
      if (mounted) {
        setState(() => _item = item);
        mostrarSnack(context, aprovar ? 'Reivindicação aprovada' : 'Reivindicação recusada');
      }
    } on ApiException catch (e) {
      if (mounted) mostrarSnack(context, e.message, erro: true);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _ir(String rota) async {
    await context.push(rota);
    if (mounted) _carregar();
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    final logado = ref.watch(authProvider).valueOrNull != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes'),
        actions: [
          if (item != null && item.podeEditar) ...[
            IconButton(
              tooltip: 'Editar',
              icon: const Icon(Icons.edit_outlined),
              onPressed: _ocupado ? null : () => _ir('/itens/${item.id}/editar'),
            ),
            IconButton(
              tooltip: 'Excluir',
              icon: const Icon(Icons.delete_outline, color: AppColors.red),
              onPressed: _ocupado ? null : _excluir,
            ),
          ],
        ],
      ),
      body: item == null
          ? (_erro != null
              ? ErroView(mensagem: _erro!, onTentar: _carregar)
              : const Center(child: CircularProgressIndicator()))
          : RefreshIndicator(
              onRefresh: _carregar,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _foto(item),
                  const SizedBox(height: 16),
                  Wrap(spacing: 8, runSpacing: 6, children: [
                    tagSituacao(item.situacao),
                    tagStatus(item.status),
                  ]),
                  const SizedBox(height: 12),
                  Text(item.nome,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(item.descricao,
                      style: const TextStyle(color: AppColors.text2, height: 1.4)),
                  const SizedBox(height: 16),
                  AppCard(
                    child: Column(children: [
                      _info(Icons.place_outlined, 'Local', item.localDisplay),
                      _info(Icons.event, 'Data', fmtData(item.dataEncontro)),
                      _info(Icons.person_outline, 'Cadastrado por', item.donoNome),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  if (item.reivindicacao != null) _blocoReivindicacao(item),
                  _acoes(item, logado),
                ],
              ),
            ),
    );
  }

  Widget _foto(Item item) {
    if (item.foto == null) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.purpleBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(iconeDoItem(item.icone), size: 72, color: AppColors.purple),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        item.foto!,
        height: 240,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: 180,
          color: AppColors.purpleBg,
          child: Icon(iconeDoItem(item.icone), size: 72, color: AppColors.purple),
        ),
      ),
    );
  }

  Widget _info(IconData icone, String rotulo, String valor) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Icon(icone, size: 18, color: AppColors.text2),
          const SizedBox(width: 10),
          Text('$rotulo: ', style: const TextStyle(color: AppColors.text2)),
          Expanded(child: Text(valor, style: const TextStyle(fontWeight: FontWeight.w600))),
        ]),
      );

  Widget _blocoReivindicacao(Item item) {
    final r = item.reivindicacao!;
    final (titulo, cor, fundo) = switch (r.status) {
      'aprovada' => ('Reivindicação aprovada', AppColors.green, AppColors.greenBg),
      'recusada' => ('Reivindicação recusada', AppColors.red, AppColors.redBg),
      _ => ('Reivindicação pendente', AppColors.yellow, AppColors.yellowBg),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: fundo,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cor.withAlpha(70)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(titulo, style: TextStyle(color: cor, fontWeight: FontWeight.w700, fontSize: 16)),
          if (r.detalhada) ...[
            const SizedBox(height: 10),
            if (r.requerenteNome != null)
              Text('Requerente: ${r.requerenteNome}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            const Text('Prova apresentada:', style: TextStyle(color: AppColors.text2)),
            const SizedBox(height: 2),
            Text(r.descricaoProva!),
          ],
          if (r.contato != null && r.contato!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.phone, size: 16),
              const SizedBox(width: 6),
              SelectableText('Contato: ${r.contato}',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ]),
          ],
        ]),
      ),
    );
  }

  Widget _acoes(Item item, bool logado) {
    final botoes = <Widget>[];

    if (item.podeReivindicar) {
      botoes.add(FilledButton.icon(
        onPressed: _ocupado ? null : () => _ir('/itens/${item.id}/reivindicar'),
        icon: const Icon(Icons.pan_tool_alt_outlined),
        label: const Text('Reivindicar este item'),
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      ));
    } else if (!logado && item.status == 'ativo') {
      botoes.add(OutlinedButton.icon(
        onPressed: () => context.push('/login'),
        icon: const Icon(Icons.login),
        label: const Text('Entrar para reivindicar'),
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      ));
    }

    if (item.podeDecidir) {
      botoes.add(Row(children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _ocupado ? null : () => _decidir('recusada'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor: AppColors.red,
            ),
            child: const Text('Recusar'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: _ocupado ? null : () => _decidir('aprovada'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: AppColors.green,
            ),
            child: const Text('Aprovar'),
          ),
        ),
      ]));
    }

    return Column(children: botoes);
  }
}
