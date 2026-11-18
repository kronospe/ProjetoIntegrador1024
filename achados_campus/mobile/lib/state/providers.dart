import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/opcoes.dart';
import '../models/usuario.dart';
import '../services/api.dart';
import '../services/api_client.dart';
import '../services/api_exception.dart';
import '../services/token_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    ref.read(tokenStorageProvider),
    // chamado quando o refresh token também expirou
    onSessionExpired: () => ref.read(authProvider.notifier).sessaoExpirada(),
  );
});

final apiProvider = Provider<Api>((ref) => Api(ref.read(apiClientProvider)));

/// Listas de cursos, locais, ícones etc. (vêm do backend).
final opcoesProvider = FutureProvider<Opcoes>((ref) => ref.read(apiProvider).opcoes());

/// Estado de autenticação: `null` = visitante.
final authProvider = AsyncNotifierProvider<AuthNotifier, Usuario?>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<Usuario?> {
  @override
  Future<Usuario?> build() async {
    final storage = ref.read(tokenStorageProvider);
    if (!await storage.temToken()) return null;
    try {
      return await ref.read(apiProvider).perfil();
    } on ApiException catch (e) {
      if (e.statusCode == 401) await storage.limpar();
      return null; // sem rede ou sessão inválida: entra como visitante
    }
  }

  Future<void> login(String email, String senha) async {
    final r = await ref.read(apiProvider).login(email.trim(), senha);
    await ref.read(tokenStorageProvider).salvar(access: r.access, refresh: r.refresh);
    state = AsyncData(r.usuario);
  }

  Future<void> cadastro({
    required String nome,
    required String email,
    required String senha,
    required String confirmar,
  }) async {
    final r = await ref.read(apiProvider).cadastro(
        nome: nome.trim(), email: email.trim(), senha: senha, confirmar: confirmar);
    await ref.read(tokenStorageProvider).salvar(access: r.access, refresh: r.refresh);
    state = AsyncData(r.usuario);
  }

  Future<void> atualizarPerfil(Map<String, dynamic> dados) async {
    final u = await ref.read(apiProvider).atualizarPerfil(dados);
    state = AsyncData(u);
  }

  Future<void> logout() async {
    await ref.read(tokenStorageProvider).limpar();
    state = const AsyncData(null);
  }

  void sessaoExpirada() => state = const AsyncData(null);
}
