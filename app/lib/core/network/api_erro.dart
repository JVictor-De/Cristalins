import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Erro no formato da API: `{ codigo, mensagem, campo?, detalhe? }`. A tela mostra [mensagemParaUsuario].
class ApiErro implements Exception {
  const ApiErro({
    required this.codigo,
    required this.mensagem,
    this.campo,
    this.status,
    this.detalhe,
    this.caminho,
  });

  /// Converte qualquer erro do dio (ou TypeError de parse) em [ApiErro].
  factory ApiErro.de(Object erro) {
    if (erro is ApiErro) return erro;

    if (erro is DioException) {
      final corpo = erro.response?.data;
      final status = erro.response?.statusCode;
      final caminho = erro.requestOptions.uri.path;

      if (corpo is Map) {
        final codigo = corpo['codigo'];
        final mensagem = corpo['mensagem'];
        if (codigo is String && mensagem is String) {
          final detalheApi = corpo['detalhe'];
          return ApiErro(
            codigo: codigo,
            mensagem: mensagem,
            campo: corpo['campo'] as String?,
            status: status,
            detalhe: detalheApi is String && detalheApi.isNotEmpty ? detalheApi : null,
            caminho: caminho,
          );
        }
        // Corpo JSON sem contrato — ainda assim mostra o que veio.
        return ApiErro(
          codigo: 'RESPOSTA_INVALIDA',
          mensagem: 'A API respondeu sem o formato esperado.',
          status: status,
          detalhe: _resumoCorpo(corpo),
          caminho: caminho,
        );
      }

      if (corpo is String && corpo.trim().isNotEmpty) {
        return ApiErro(
          codigo: 'RESPOSTA_INVALIDA',
          mensagem: 'A API respondeu com texto inesperado.',
          status: status,
          detalhe: corpo.length > 180 ? '${corpo.substring(0, 180)}…' : corpo,
          caminho: caminho,
        );
      }

      if (erro.type == DioExceptionType.connectionError ||
          erro.type == DioExceptionType.connectionTimeout ||
          erro.type == DioExceptionType.receiveTimeout ||
          erro.type == DioExceptionType.sendTimeout) {
        return ApiErro(
          codigo: 'SEM_CONEXAO',
          mensagem: semConexao,
          caminho: caminho,
          detalhe: erro.message,
        );
      }

      // Flutter Web (Safari): CORS/rede falha sem status — Dio manda `unknown`.
      if (erro.response == null && erro.type == DioExceptionType.unknown) {
        return ApiErro(
          codigo: 'SEM_CONEXAO',
          mensagem: semConexao,
          caminho: caminho,
          detalhe: erro.message ?? erro.error?.toString(),
        );
      }

      return ApiErro(
        codigo: 'HTTP',
        mensagem: generico,
        status: status,
        caminho: caminho,
        detalhe: 'dio=${erro.type.name}${erro.message != null ? ' · ${erro.message}' : ''}',
      );
    }

    if (erro is TypeError || erro is FormatException) {
      return ApiErro(
        codigo: 'RESPOSTA_INVALIDA',
        mensagem: 'Não conseguimos interpretar a resposta da API.',
        detalhe: erro.toString(),
      );
    }

    return ApiErro(
      codigo: 'ERRO',
      mensagem: generico,
      detalhe: kDebugMode || kIsWeb ? erro.toString() : null,
    );
  }

  /// Voz do Anexo.
  static const generico = 'Não conseguimos carregar agora. Tente de novo.';
  static const semConexao = 'Sem conexão com a internet. Confira a rede e tente de novo.';

  final String codigo;
  final String mensagem;
  final String? campo;
  final int? status;

  /// Detalhe técnico (API HML `detalhe`, Dio, parse). Seguro para snackbar em demo/HML.
  final String? detalhe;
  final String? caminho;

  /// Mensagem curta (produção) ou com diagnóstico (web/HML/debug).
  String get mensagemParaUsuario {
    if (!_mostrarDiagnostico) return mensagem;
    final partes = <String>[mensagem, '[$codigo]'];
    if (status != null) partes.add('HTTP $status');
    if (caminho != null && caminho!.isNotEmpty) partes.add(caminho!);
    if (campo != null && campo!.isNotEmpty) partes.add('campo=$campo');
    if (detalhe != null && detalhe!.trim().isNotEmpty) partes.add(detalhe!.trim());
    return partes.join(' · ');
  }

  /// Em web, debug ou quando a API mandou `detalhe`, mostramos o diagnóstico.
  bool get _mostrarDiagnostico =>
      kIsWeb || kDebugMode || (detalhe != null && detalhe!.trim().isNotEmpty);

  static String _resumoCorpo(Map<dynamic, dynamic> corpo) {
    final texto = corpo.toString();
    return texto.length > 200 ? '${texto.substring(0, 200)}…' : texto;
  }

  @override
  String toString() => 'ApiErro($codigo, $mensagem, status=$status, detalhe=$detalhe)';
}
