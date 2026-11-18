import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../core/format.dart';
import '../models/item.dart';
import '../models/opcoes.dart';
import '../models/usuario.dart';
import 'api_client.dart';
import 'api_exception.dart';

class AuthResult {
  final String access;
  final String refresh;
  final Usuario usuario;
  const AuthResult(this.access, this.refresh, this.usuario);
}

/// Todos os endpoints do backend. Qualquer erro vira [ApiException].
class Api {
  Api(this._client);
  final ApiClient _client;
  Dio get _dio => _client.dio;

  Future<T> _run<T>(Future<T> Function() f) async {
    try {
      return await f();
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  // --- auth / perfil -------------------------------------------------------
  AuthResult _auth(Map<String, dynamic> d) => AuthResult(
        d['access'] as String,
        d['refresh'] as String,
        Usuario.fromJson(d['usuario'] as Map<String, dynamic>),
      );

  Future<AuthResult> login(String email, String senha) => _run(() async {
        final r = await _dio.post('/auth/login/', data: {'email': email, 'senha': senha});
        return _auth(r.data as Map<String, dynamic>);
      });

  Future<AuthResult> cadastro({
    required String nome,
    required String email,
    required String senha,
    required String confirmar,
  }) =>
      _run(() async {
        final r = await _dio.post('/auth/cadastro/', data: {
          'nome': nome,
          'email': email,
          'senha': senha,
          'confirmar_senha': confirmar,
        });
        return _auth(r.data as Map<String, dynamic>);
      });

  Future<Usuario> perfil() => _run(() async {
        final r = await _dio.get('/perfil/');
        return Usuario.fromJson(r.data as Map<String, dynamic>);
      });

  Future<Usuario> atualizarPerfil(Map<String, dynamic> dados) => _run(() async {
        final r = await _dio.put('/perfil/', data: dados);
        return Usuario.fromJson(r.data as Map<String, dynamic>);
      });

  Future<Opcoes> opcoes() => _run(() async {
        final r = await _dio.get('/opcoes/');
        return Opcoes.fromJson(r.data as Map<String, dynamic>);
      });

  // --- itens ---------------------------------------------------------------
  Future<PaginaItens> listarItens({
    String? q,
    String? situacao,
    String? local,
    bool meus = false,
    int pagina = 1,
  }) =>
      _run(() async {
        final r = await _dio.get('/itens/', queryParameters: {
          'page': pagina,
          if (q != null && q.isNotEmpty) 'q': q,
          if (situacao != null && situacao.isNotEmpty) 'situacao': situacao,
          if (local != null && local.isNotEmpty) 'local': local,
          if (meus) 'meus': '1',
        });
        final d = r.data as Map<String, dynamic>;
        final itens = (d['results'] as List)
            .map((e) => Item.fromJson(e as Map<String, dynamic>))
            .toList();
        return PaginaItens(itens, d['next'] != null);
      });

  Future<Item> obterItem(int id) => _run(() async {
        final r = await _dio.get('/itens/$id/');
        return Item.fromJson(r.data as Map<String, dynamic>);
      });

  Future<FormData> _formItem({
    required String nome,
    required String descricao,
    required String local,
    required String situacao,
    required String icone,
    required DateTime data,
    XFile? foto,
    bool removerFoto = false,
  }) async {
    final map = <String, dynamic>{
      'nome': nome,
      'descricao': descricao,
      'local': local,
      'situacao_item': situacao,
      'icone': icone,
      'data_encontro': isoData(data),
      if (removerFoto) 'remover_foto': 'true',
    };
    if (foto != null) {
      map['foto'] = MultipartFile.fromBytes(await foto.readAsBytes(), filename: foto.name);
    }
    return FormData.fromMap(map);
  }

  Future<Item> criarItem({
    required String nome,
    required String descricao,
    required String local,
    required String situacao,
    required String icone,
    required DateTime data,
    XFile? foto,
  }) =>
      _run(() async {
        final form = await _formItem(
            nome: nome, descricao: descricao, local: local, situacao: situacao,
            icone: icone, data: data, foto: foto);
        final r = await _dio.post('/itens/', data: form);
        return Item.fromJson(r.data as Map<String, dynamic>);
      });

  Future<Item> atualizarItem(
    int id, {
    required String nome,
    required String descricao,
    required String local,
    required String situacao,
    required String icone,
    required DateTime data,
    XFile? foto,
    bool removerFoto = false,
  }) =>
      _run(() async {
        final form = await _formItem(
            nome: nome, descricao: descricao, local: local, situacao: situacao,
            icone: icone, data: data, foto: foto, removerFoto: removerFoto);
        final r = await _dio.patch('/itens/$id/', data: form);
        return Item.fromJson(r.data as Map<String, dynamic>);
      });

  Future<void> excluirItem(int id) => _run(() async {
        await _dio.delete('/itens/$id/');
      });

  Future<void> reivindicar(int id, String prova) => _run(() async {
        await _dio.post('/itens/$id/reivindicar/', data: {'descricao_prova': prova});
      });

  Future<Item> decidir(int id, String decisao) => _run(() async {
        final r = await _dio.post('/itens/$id/decidir/', data: {'decisao': decisao});
        return Item.fromJson(r.data as Map<String, dynamic>);
      });

  // --- chatbot -------------------------------------------------------------
  Future<String> chatbot(String mensagem) => _run(() async {
        final r = await _dio.post('/chatbot/', data: {'mensagem': mensagem});
        return (r.data as Map<String, dynamic>)['resposta'] as String;
      });
}
