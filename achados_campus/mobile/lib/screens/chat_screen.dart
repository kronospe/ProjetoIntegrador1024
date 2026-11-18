import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../services/api_exception.dart';
import '../state/providers.dart';

class _Msg {
  final String texto;
  final bool doUsuario;
  const _Msg(this.texto, this.doUsuario);
}

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _msgs = [
    const _Msg(
      '👋 Olá! Sou o assistente do CampusAchados. Pergunte sobre cadastrar itens, '
      'reivindicar, status, perfil ou como o app funciona.',
      false,
    ),
  ];
  bool _digitando = false;

  static const _sugestoesPadrao = [
    'Como cadastrar um item?',
    'Como reivindicar um item?',
    'Quais os status do item?',
    'Como editar meu perfil?',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _rolarParaFim() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _enviar(String texto) async {
    texto = texto.trim();
    if (texto.isEmpty || _digitando) return;
    _controller.clear();
    setState(() {
      _msgs.add(_Msg(texto, true));
      _digitando = true;
    });
    _rolarParaFim();

    String resposta;
    try {
      resposta = await ref.read(apiProvider).chatbot(texto);
    } on ApiException catch (e) {
      resposta = '⚠️ ${e.message}';
    }
    if (!mounted) return;
    setState(() {
      _msgs.add(_Msg(resposta, false));
      _digitando = false;
    });
    _rolarParaFim();
  }

  @override
  Widget build(BuildContext context) {
    final sugestoes = ref.watch(opcoesProvider).valueOrNull?.sugestoesChatbot ?? _sugestoesPadrao;

    return Scaffold(
      appBar: AppBar(title: const Text('Assistente')),
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              itemCount: _msgs.length + (_digitando ? 1 : 0),
              itemBuilder: (_, i) {
                if (i >= _msgs.length) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('digitando…', style: TextStyle(color: AppColors.text3)),
                    ),
                  );
                }
                return _bolha(_msgs[i]);
              },
            ),
          ),
          if (_msgs.length == 1)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: sugestoes
                    .map((s) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(label: Text(s), onPressed: () => _enviar(s)),
                        ))
                    .toList(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _enviar,
                  decoration: InputDecoration(
                    hintText: 'Digite sua dúvida…',
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _digitando ? null : () => _enviar(_controller.text),
                icon: const Icon(Icons.send),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _bolha(_Msg m) {
    return Align(
      alignment: m.doUsuario ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: m.doUsuario ? AppColors.purple : AppColors.surface2,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SelectableText(m.texto, style: const TextStyle(height: 1.35)),
      ),
    );
  }
}
