import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../models/item.dart';
import '../services/api_exception.dart';
import '../state/providers.dart';
import '../widgets/common.dart';

class ReivindicarScreen extends ConsumerStatefulWidget {
  const ReivindicarScreen({super.key, required this.itemId});
  final int itemId;

  @override
  ConsumerState<ReivindicarScreen> createState() => _ReivindicarScreenState();
}

class _ReivindicarScreenState extends ConsumerState<ReivindicarScreen> {
  final _prova = TextEditingController();
  Item? _item;
  String? _erro;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    ref.read(apiProvider).obterItem(widget.itemId).then((i) {
      if (mounted) setState(() => _item = i);
    }).catchError((Object e) {
      if (mounted) setState(() => _erro = ApiException.from(e).message);
    });
  }

  @override
  void dispose() {
    _prova.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (_prova.text.trim().length < 10) {
      setState(() => _erro = 'Descreva melhor a prova (mínimo de 10 caracteres).');
      return;
    }
    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      await ref.read(apiProvider).reivindicar(widget.itemId, _prova.text.trim());
      if (!mounted) return;
      mostrarSnack(context, 'Reivindicação enviada! Aguarde a confirmação.');
      context.pop();
    } on ApiException catch (e) {
      if (mounted) setState(() => _erro = e.fieldErrors['descricao_prova'] ?? e.message);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reivindicar item')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_item != null)
              ItemCard(item: _item!, onTap: () {}),
            const SizedBox(height: 20),
            const Text('Como provar que o item é seu?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text(
              'Descreva detalhes que só o dono saberia: marcas, conteúdo, '
              'adesivos, o que há dentro, etc. Quem cadastrou o item vai analisar.',
              style: TextStyle(color: AppColors.text2, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _prova,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: campoDeco('Descrição da prova'),
            ),
            if (_erro != null) ...[
              const SizedBox(height: 10),
              Text(_erro!, style: const TextStyle(color: AppColors.red)),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _enviando ? null : _enviar,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              child: _enviando
                  ? const SizedBox(
                      width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Enviar reivindicação'),
            ),
          ],
        ),
      ),
    );
  }
}
