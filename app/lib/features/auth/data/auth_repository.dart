import '../../../core/network/api_client.dart';
import '../../../core/network/api_erro.dart';

class DadosCadastro {
  const DadosCadastro({
    required this.nome,
    required this.cpfCnpj,
    required this.email,
    required this.dataNascimento,
    required this.senha,
    required this.aceiteTermos,
    this.celular,
    this.marketingOk = false,
  });

  final String nome;
  final String cpfCnpj;
  final String email;

  /// AAAA-MM-DD
  final String dataNascimento;
  final String senha;
  final bool aceiteTermos;
  final String? celular;
  final bool marketingOk;

  Map<String, dynamic> toJson() => {
    'nome': nome,
    'cpfCnpj': cpfCnpj,
    'email': email,
    'dataNascimento': dataNascimento,
    'senha': senha,
    'aceiteTermos': aceiteTermos,
    if (celular != null && celular!.isNotEmpty) 'celular': celular,
    'marketingOk': marketingOk,
  };
}

/// `POST /clientes`, `POST /auth/login`. Os tokens vão para o armazenamento seguro.
class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;

  Future<void> cadastrar(DadosCadastro dados) async {
    try {
      final r = await _api.dio.post<Map<String, dynamic>>('/clientes', data: dados.toJson());
      final tokens = r.data!['tokens'] as Map<String, dynamic>;
      await _salvar(tokens);
    } catch (e) {
      throw ApiErro.de(e);
    }
  }

  Future<void> entrar(String email, String senha) async {
    try {
      final r = await _api.dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email, 'senha': senha},
      );
      await _salvar(r.data!);
    } catch (e) {
      throw ApiErro.de(e);
    }
  }

  Future<void> sair() => _api.tokens.limpar();

  /// RF52: sempre 200 na API (não revela se o e-mail existe).
  Future<String> esqueciSenha(String email) async {
    try {
      final r = await _api.dio.post<Map<String, dynamic>>(
        '/auth/esqueci-senha',
        data: {'email': email},
      );
      return r.data!['mensagem'] as String;
    } catch (e) {
      throw ApiErro.de(e);
    }
  }

  Future<String> redefinirSenha({
    required String email,
    required String codigo,
    required String novaSenha,
  }) async {
    try {
      final r = await _api.dio.post<Map<String, dynamic>>(
        '/auth/redefinir-senha',
        data: {'email': email, 'codigo': codigo, 'novaSenha': novaSenha},
      );
      return r.data!['mensagem'] as String;
    } catch (e) {
      throw ApiErro.de(e);
    }
  }

  Future<void> _salvar(Map<String, dynamic> tokens) => _api.tokens.salvar(
    acesso: tokens['accessToken'] as String,
    refresh: tokens['refreshToken'] as String,
  );
}
