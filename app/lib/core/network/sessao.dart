import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Tokens da sessão (SEG07: guardados no flutter_secure_storage).
abstract class ArmazenamentoTokens {
  Future<String?> lerAcesso();
  Future<String?> lerRefresh();
  Future<void> salvar({required String acesso, required String refresh});
  Future<void> limpar();
}

class ArmazenamentoSeguro implements ArmazenamentoTokens {
  ArmazenamentoSeguro([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _acesso = 'accessToken';
  static const _refresh = 'refreshToken';

  @override
  Future<String?> lerAcesso() => _storage.read(key: _acesso);

  @override
  Future<String?> lerRefresh() => _storage.read(key: _refresh);

  @override
  Future<void> salvar({required String acesso, required String refresh}) async {
    await _storage.write(key: _acesso, value: acesso);
    await _storage.write(key: _refresh, value: refresh);
  }

  @override
  Future<void> limpar() async {
    await _storage.delete(key: _acesso);
    await _storage.delete(key: _refresh);
  }
}

/// Em memória: testes de widget.
class ArmazenamentoEmMemoria implements ArmazenamentoTokens {
  String? acesso;
  String? refresh;

  @override
  Future<String?> lerAcesso() async => acesso;

  @override
  Future<String?> lerRefresh() async => refresh;

  @override
  Future<void> salvar({required String acesso, required String refresh}) async {
    this.acesso = acesso;
    this.refresh = refresh;
  }

  @override
  Future<void> limpar() async {
    acesso = null;
    refresh = null;
  }
}
