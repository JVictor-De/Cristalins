import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Tokens da sessão (SEG07: guardados no flutter_secure_storage).
abstract class ArmazenamentoTokens {
  Future<String?> lerAcesso();
  Future<String?> lerRefresh();
  Future<void> salvar({required String acesso, required String refresh});
  Future<void> limpar();
}

/// Persistência + fallback em memória.
///
/// No Safari (modo privado / ITP) o `localStorage`/WebCrypto do plugin pode
/// lançar: mantemos a sessão na memória da aba para o login continuar válido.
class ArmazenamentoSeguro implements ArmazenamentoTokens {
  ArmazenamentoSeguro([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _acesso = 'accessToken';
  static const _refresh = 'refreshToken';

  String? _acessoMem;
  String? _refreshMem;

  @override
  Future<String?> lerAcesso() async {
    try {
      return await _storage.read(key: _acesso) ?? _acessoMem;
    } catch (_) {
      return _acessoMem;
    }
  }

  @override
  Future<String?> lerRefresh() async {
    try {
      return await _storage.read(key: _refresh) ?? _refreshMem;
    } catch (_) {
      return _refreshMem;
    }
  }

  @override
  Future<void> salvar({required String acesso, required String refresh}) async {
    _acessoMem = acesso;
    _refreshMem = refresh;
    try {
      await _storage.write(key: _acesso, value: acesso);
      await _storage.write(key: _refresh, value: refresh);
    } catch (_) {
      // Sessão segue válida nesta aba via memória (comum no Safari privado).
      if (kDebugMode) {
        debugPrint('ArmazenamentoSeguro: persistência indisponível; tokens só em memória.');
      }
    }
  }

  @override
  Future<void> limpar() async {
    _acessoMem = null;
    _refreshMem = null;
    try {
      await _storage.delete(key: _acesso);
      await _storage.delete(key: _refresh);
    } catch (_) {}
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
