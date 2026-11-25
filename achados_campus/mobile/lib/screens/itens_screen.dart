import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../models/item.dart';
import '../services/api_exception.dart';
import '../state/providers.dart';
import '../widgets/common.dart';

/// Lista de itens com busca, filtros e rolagem infinita.
/// Com [meus] = true mostra só os itens do usuário (de qualquer status).
class ItensScreen extends ConsumerStatefulWidget {
  const ItensScreen({super.key, this.meus = false});
  final bool meus;

  @override
  ConsumerState<ItensScreen> createState() => _ItensScreenState();
}

class _ItensScreenState extends ConsumerState<ItensScreen> {
  final _scroll = ScrollController();
  final _busca = TextEditingController();
  Timer? _debounce;

  final List<Item> _itens = [];
  int _pagina = 1;
  bool _temMais = true;
  bool _carregando = false;
  String? _erro;
  int _geracao = 0; // descarta respostas antigas

  String _situacao = '';
  String _local = '';

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300) _carregarMais();
    });
    _recarregar();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    _busca.dispose();
    super.dispose();
  }

  Future<void> _recarregar() async {
    _geracao++;
    setState(() {
      _itens.clear();
      _pagina = 1;
      _temMais = true;
      _erro = null;
      _carregando = false;
    });
    await _carregarMais();
  }

  Future<void> _carregarMais() async {
    if (_carregando || !_temMais) return;
    final geracao = _geracao;
    setState(() => _carregando = true);
    try {
      final r = await ref.read(apiProvider).listarItens(
            q: _busca.text.trim(),
            situacao: _situacao,
            local: _local,
            meus: widget.meus,
            pagina: _pagina,
          );
      if (!mounted || geracao != _geracao) return;
      setState(() {
        _itens.addAll(r.itens);
        _temMais = r.temMais;
        _pagina++;
      });
    } on ApiException catch (e) {
      if (mounted && geracao == _geracao) setState(() => _erro = e.message);
    } finally {
      if (mounted && geracao == _geracao) setState(() => _carregando = false);
    }
  }

  void _aoDigitar(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _recarregar);
  }

  /// Recarrega as páginas já carregadas e troca a lista de uma vez,
  /// sem limpar a tela, para manter a posição da rolagem.
  Future<void> _sincronizar() async {
    final paginas = _pagina - 1;
    if (_carregando || paginas < 1) return _recarregar();

    final geracao = ++_geracao;
    try {
      final novos = <Item>[];
      var temMais = true;
      var ultima = 0;
      for (var p = 1; p <= paginas && temMais; p++) {
        final r = await ref.read(apiProvider).listarItens(
              q: _busca.text.trim(),
              situacao: _situacao,
              local: _local,
              meus: widget.meus,
              pagina: p,
            );
        novos.addAll(r.itens);
        temMais = r.temMais;
        ultima = p;
      }
      if (!mounted || geracao != _geracao) return;
      setState(() {
        _itens
          ..clear()
          ..addAll(novos);
        _temMais = temMais;
        _pagina = ultima + 1;
        _carregando = false;
      });
    } on ApiException {
      // mantém a lista que já estava na tela
    }
  }

  Future<void> _abrir(String rota) async {
    await context.push(rota);
    if (mounted) _sincronizar(); // pode ter criado/editado/excluído algo
  }

  @override
  Widget build(BuildContext context) {
    final opcoes = ref.watch(opcoesProvider).valueOrNull;
    final logado = ref.watch(authProvider).valueOrNull != null;

    return Scaffold(
      appBar: widget.meus ? AppBar(title: const Text('Meus itens')) : null,
      floatingActionButton: widget.meus
          ? null
          : FloatingActionButton.extended(
              onPressed: () => logado ? _abrir('/itens/novo') : context.push('/login'),
              icon: const Icon(Icons.add),
              label: const Text('Cadastrar'),
            ),
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, widget.meus ? 8 : 16, 16, 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (!widget.meus) ...[
                const Text('Itens no campus',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _busca,
                onChanged: _aoDigitar,
                decoration: campoDeco('Buscar por nome').copyWith(
                  prefixIcon: const Icon(Icons.search),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  _chipSituacao('Todos', ''),
                  const SizedBox(width: 8),
                  _chipSituacao('Perdidos', 'perdido'),
                  const SizedBox(width: 8),
                  _chipSituacao('Encontrados', 'encontrado'),
                  const SizedBox(width: 8),
                  if (opcoes != null)
                    PopupMenuButton<String>(
                      onSelected: (v) {
                        _local = v;
                        _recarregar();
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: '', child: Text('Todos os locais')),
                        ...opcoes.locais
                            .map((o) => PopupMenuItem(value: o.valor, child: Text(o.nome))),
                      ],
                      child: Chip(
                        avatar: const Icon(Icons.place_outlined, size: 16),
                        label: Text(_local.isEmpty
                            ? 'Local'
                            : opcoes.locais.firstWhere((o) => o.valor == _local).nome),
                      ),
                    ),
                ]),
              ),
            ]),
          ),
          Expanded(child: _corpo()),
        ]),
      ),
    );
  }

  Widget _chipSituacao(String label, String valor) => ChoiceChip(
        label: Text(label),
        selected: _situacao == valor,
        onSelected: (_) {
          _situacao = valor;
          _recarregar();
        },
      );

  Widget _corpo() {
    if (_erro != null && _itens.isEmpty) {
      return ErroView(mensagem: _erro!, onTentar: _recarregar);
    }
    if (_itens.isEmpty && _carregando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_itens.isEmpty) {
      return ListView(children: const [
        SizedBox(height: 80),
        Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.text3),
        SizedBox(height: 12),
        Center(child: Text('Nenhum item encontrado', style: TextStyle(color: AppColors.text2))),
      ]);
    }
    return RefreshIndicator(
      onRefresh: _recarregar,
      child: ListView.separated(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        itemCount: _itens.length + (_temMais ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          if (i >= _itens.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final item = _itens[i];
          return ItemCard(
            item: item,
            mostrarStatus: widget.meus,
            onTap: () => _abrir('/itens/${item.id}'),
          );
        },
      ),
    );
  }
}
