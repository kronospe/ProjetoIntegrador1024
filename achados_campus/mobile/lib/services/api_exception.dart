import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final Map<String, String> fieldErrors;
  final int? statusCode;

  const ApiException(this.message, {this.fieldErrors = const {}, this.statusCode});

  @override
  String toString() => message;

  static String _flat(dynamic v) {
    if (v is List) return v.map(_flat).join(' ');
    if (v is Map) return v.values.map(_flat).join(' ');
    return v.toString();
  }

  /// Converte qualquer erro (Dio, timeout, etc.) em uma mensagem amigável.
  static ApiException from(Object e) {
    if (e is ApiException) return e;
    if (e is DioException) {
      final res = e.response;
      if (res == null) {
        return const ApiException(
            'Não foi possível conectar ao servidor. Verifique sua internet.');
      }
      final data = res.data;
      if (data is Map) {
        String? geral;
        final campos = <String, String>{};
        data.forEach((k, v) {
          final msg = _flat(v);
          if (k == 'detail' || k == 'non_field_errors') {
            geral = msg;
          } else if (k != 'code') {
            campos[k.toString()] = msg;
          }
        });
        return ApiException(
          geral ?? (campos.isNotEmpty ? campos.values.first : 'Erro ${res.statusCode}'),
          fieldErrors: campos,
          statusCode: res.statusCode,
        );
      }
      return ApiException('Erro ${res.statusCode} no servidor.', statusCode: res.statusCode);
    }
    return const ApiException('Algo deu errado. Tente novamente.');
  }
}
