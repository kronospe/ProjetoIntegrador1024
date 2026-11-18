import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _kAccess = 'access';
  static const _kRefresh = 'refresh';

  final FlutterSecureStorage _s = const FlutterSecureStorage();

  Future<String?> access() => _s.read(key: _kAccess);
  Future<String?> refresh() => _s.read(key: _kRefresh);

  Future<bool> temToken() async => (await refresh()) != null || (await access()) != null;

  Future<void> salvar({required String access, String? refresh}) async {
    await _s.write(key: _kAccess, value: access);
    if (refresh != null) await _s.write(key: _kRefresh, value: refresh);
  }

  Future<void> limpar() async {
    await _s.delete(key: _kAccess);
    await _s.delete(key: _kRefresh);
  }
}
