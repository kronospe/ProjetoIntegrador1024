import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'screens/cadastro_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/item_detail_screen.dart';
import 'screens/item_form_screen.dart';
import 'screens/itens_screen.dart';
import 'screens/login_screen.dart';
import 'screens/perfil_screen.dart';
import 'screens/reivindicar_screen.dart';
import 'screens/shell_screen.dart';
import 'state/providers.dart';

/// Faz o GoRouter reavaliar os redirecionamentos quando o login muda.
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen(authProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;

  String? redirect(BuildContext context, GoRouterState state) {
    final auth = _ref.read(authProvider);
    final loc = state.matchedLocation;

    if (auth.isLoading) return loc == '/splash' ? null : '/splash';

    final logado = auth.valueOrNull != null;
    if (loc == '/splash') return '/itens';
    if (logado && (loc == '/login' || loc == '/cadastro')) return '/itens';

    final protegida = loc == '/itens/novo' ||
        loc == '/meus-itens' ||
        loc.endsWith('/editar') ||
        loc.endsWith('/reivindicar');
    if (!logado && protegida) return '/login';
    return null;
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/cadastro', builder: (_, __) => const CadastroScreen()),

      // abas com a barra de navegação inferior
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => ShellScreen(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/itens', builder: (_, __) => const ItensScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/assistente', builder: (_, __) => const ChatScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/perfil', builder: (_, __) => const PerfilScreen()),
          ]),
        ],
      ),

      // telas em tela cheia (a ordem importa: /itens/novo antes de /itens/:id)
      GoRoute(path: '/itens/novo', builder: (_, __) => const ItemFormScreen()),
      GoRoute(path: '/meus-itens', builder: (_, __) => const ItensScreen(meus: true)),
      GoRoute(
        path: '/itens/:id',
        builder: (_, s) => ItemDetailScreen(id: int.parse(s.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/itens/:id/editar',
        builder: (_, s) => ItemFormScreen(itemId: int.parse(s.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/itens/:id/reivindicar',
        builder: (_, s) => ReivindicarScreen(itemId: int.parse(s.pathParameters['id']!)),
      ),
    ],
  );
});
