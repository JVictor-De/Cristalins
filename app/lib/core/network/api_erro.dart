import 'package:dio/dio.dart';

/// Erro no formato da API: `{ codigo, mensagem, campo? }`. A tela mostra [mensagem].
class ApiErro implements Exception {
  const ApiErro({required this.codigo, required this.mensagem, this.campo, this.status});

  /// Converte qualquer erro do dio em [ApiErro] com texto em português.
  factory ApiErro.de(Object erro) {
    if (erro is ApiErro) return erro;
    if (erro is DioException) {
      final corpo = erro.response?.data;
      if (corpo is Map && corpo['codigo'] is String && corpo['mensagem'] is String) {
        return ApiErro(
          codigo: corpo['codigo'] as String,
          mensagem: corpo['mensagem'] as String,
          campo: corpo['campo'] as String?,
          status: erro.response?.statusCode,
        );
      }
      if (erro.type == DioExceptionType.connectionError ||
          erro.type == DioExceptionType.connectionTimeout ||
          erro.type == DioExceptionType.receiveTimeout ||
          erro.type == DioExceptionType.sendTimeout) {
        return const ApiErro(codigo: 'SEM_CONEXAO', mensagem: semConexao);
      }
    }
    return const ApiErro(codigo: 'ERRO', mensagem: generico);
  }

  /// Voz do Anexo.
  static const generico = 'Não conseguimos carregar agora. Tente de novo.';
  static const semConexao = 'Sem conexão com a internet. Confira a rede e tente de novo.';

  final String codigo;
  final String mensagem;
  final String? campo;
  final int? status;

  @override
  String toString() => 'ApiErro($codigo, $mensagem)';
}
