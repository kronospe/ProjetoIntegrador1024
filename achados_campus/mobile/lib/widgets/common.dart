import 'package:material_ui/material_ui.dart';

import '../core/theme.dart';
import '../models/item.dart';

/// Ícones do site (FontAwesome) → Material Icons.
IconData iconeDoItem(String chave) {
  switch (chave) {
    case 'fa-laptop':
      return Icons.laptop_mac;
    case 'fa-key':
      return Icons.vpn_key;
    case 'fa-wallet':
      return Icons.account_balance_wallet;
    case 'fa-book':
      return Icons.menu_book;
    case 'fa-mobile-screen-button':
      return Icons.smartphone;
    case 'fa-shirt':
      return Icons.checkroom;
    case 'fa-glasses':
      return Icons.visibility;
    case 'fa-backpack':
      return Icons.backpack;
    default:
      return Icons.inventory_2;
  }
}

const avatares = [
  '🧑‍💻', '👩‍🎓', '👨‍🎓', '🦊', '🐱', '🐶', '🦉', '🐼',
  '🚀', '🎧', '📚', '⚡', '🌵', '🎮', '☕', '🌙',
];

/// Cartão com o visual do site (fundo translúcido + borda fina).
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap});
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class Tag extends StatelessWidget {
  const Tag(this.texto, {super.key, required this.cor, required this.fundo, this.icone});
  final String texto;
  final Color cor;
  final Color fundo;
  final IconData? icone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cor.withAlpha(70)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icone != null) ...[Icon(icone, size: 12, color: cor), const SizedBox(width: 4)],
        Text(texto, style: TextStyle(color: cor, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

Tag tagSituacao(String situacao) => situacao == 'perdido'
    ? const Tag('Perdido', cor: AppColors.red, fundo: AppColors.redBg)
    : const Tag('Encontrado', cor: AppColors.purple, fundo: AppColors.purpleBg);

Tag tagStatus(String status) {
  switch (status) {
    case 'reivindicado':
      return const Tag('Reivindicado', cor: AppColors.yellow, fundo: AppColors.yellowBg);
    case 'entregue':
      return const Tag('Entregue', cor: AppColors.gray, fundo: AppColors.grayBg);
    default:
      return const Tag('Ativo', cor: AppColors.green, fundo: AppColors.greenBg);
  }
}

/// Miniatura do item: foto ou ícone da categoria.
class ItemThumb extends StatelessWidget {
  const ItemThumb(this.item, {super.key, this.tamanho = 64});
  final Item item;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: tamanho,
      height: tamanho,
      color: AppColors.purpleBg,
      child: Icon(iconeDoItem(item.icone), color: AppColors.purple, size: tamanho * 0.45),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: item.foto == null
          ? fallback
          : Image.network(
              item.foto!,
              width: tamanho,
              height: tamanho,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => fallback,
            ),
    );
  }
}

class ItemCard extends StatelessWidget {
  const ItemCard({super.key, required this.item, required this.onTap, this.mostrarStatus = false});
  final Item item;
  final VoidCallback onTap;
  final bool mostrarStatus;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        ItemThumb(item),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.nome,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.place_outlined, size: 14, color: AppColors.text2),
              const SizedBox(width: 3),
              Flexible(
                child: Text(item.localDisplay,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.text2, fontSize: 13)),
              ),
            ]),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 4, children: [
              tagSituacao(item.situacao),
              if (mostrarStatus || item.status != 'ativo') tagStatus(item.status),
            ]),
          ]),
        ),
        const Icon(Icons.chevron_right, color: AppColors.text3),
      ]),
    );
  }
}

/// Estilo único para campos de formulário.
InputDecoration campoDeco(String label, {String? erro, Widget? sufixo, String? dica}) {
  OutlineInputBorder borda(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c),
      );
  return InputDecoration(
    labelText: label,
    hintText: dica,
    errorText: erro,
    suffixIcon: sufixo,
    filled: true,
    fillColor: AppColors.surface,
    enabledBorder: borda(AppColors.border),
    focusedBorder: borda(AppColors.purple),
    errorBorder: borda(AppColors.red),
    focusedErrorBorder: borda(AppColors.red),
  );
}

class ErroView extends StatelessWidget {
  const ErroView({super.key, required this.mensagem, this.onTentar});
  final String mensagem;
  final VoidCallback? onTentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off, size: 48, color: AppColors.text3),
          const SizedBox(height: 12),
          Text(mensagem, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.text2)),
          if (onTentar != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onTentar, child: const Text('Tentar novamente')),
          ],
        ]),
      ),
    );
  }
}

void mostrarSnack(BuildContext context, String msg, {bool erro = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: erro ? AppColors.red : AppColors.surface2,
    ));
}

Future<bool> confirmar(BuildContext context, String titulo, String texto,
    {String confirmarLabel = 'Confirmar'}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titulo),
      content: Text(texto),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(confirmarLabel)),
      ],
    ),
  );
  return r ?? false;
}
