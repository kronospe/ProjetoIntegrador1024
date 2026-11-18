import 'dart:async';

import 'package:dio/dio.dart';

import '../core/config.dart';
import 'token_storage.dart';

/// Dio configurado com JWT: envia o access token e, ao receber 401,
/// tenta renovar com o refresh token e repete a requisição uma vez.
class ApiClient {
  ApiClient(this._storage, {this.onSessionExpired}) {
    dio = Dio(BaseOptions(
      baseUrl: '${AppConfig.apiBaseUrl}/api',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Accept': 'application/json'},
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.access();
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
      onError: (err, handler) async {
        final opts = err.requestOptions;
        final ehAuth = opts.path.contains('auth/');
        final jaTentou = opts.extra['retried'] == true;

        if (err.response?.statusCode == 401 && !ehAuth && !jaTentou) {
          final novo = await _renovar();
          if (novo != null) {
            try {
              opts.headers['Authorization'] = 'Bearer $novo';
              opts.extra['retried'] = true;
              if (opts.data is FormData) {
                // um FormData só pode ser enviado uma vez
                opts.data = (opts.data as FormData).clone();
              }
              final res = await dio.fetch(opts);
              return handler.resolve(res);
            } on DioException catch (e) {
              return handler.next(e);
            }
          }
          if (await _storage.temToken()) {
            await _storage.limpar();
            onSessionExpired?.call();
          }
        }
        handler.next(err);
      },
    ));
  }

  final TokenStorage _storage;
  final void Function()? onSessionExpired;
  late final Dio dio;
  Future<String?>? _renovando;

  Future<String?> _renovar() {
    return _renovando ??= _fazerRenovacao().whenComplete(() => _renovando = null);
  }

  Future<String?> _fazerRenovacao() async {
    final refresh = await _storage.refresh();
    if (refresh == null) return null;
    try {
      // Dio "limpo", sem o interceptor, para não entrar em loop
      final limpo = Dio(BaseOptions(baseUrl: dio.options.baseUrl));
      final res = await limpo.post('/auth/refresh/', data: {'refresh': refresh});
      final access = res.data['access'] as String;
      final novoRefresh = res.data['refresh'] as String?;
      await _storage.salvar(access: access, refresh: novoRefresh);
      return access;
    } catch (_) {
      return null;
    }
  }
}
