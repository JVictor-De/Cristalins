import 'package:cristalins_assinatura/core/network/api_erro.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiErro.de', () {
    test('repassa ApiErro existente', () {
      const original = ApiErro(codigo: 'X', mensagem: 'Já era');
      expect(ApiErro.de(original), same(original));
    });

    test('lê codigo/mensagem/detalhe do corpo da API', () {
      final e = DioException(
        requestOptions: RequestOptions(path: '/assinaturas'),
        response: Response(
          requestOptions: RequestOptions(path: '/assinaturas'),
          statusCode: 500,
          data: {
            'codigo': 'ERRO_INTERNO',
            'mensagem': 'Erro inesperado. Tente de novo.',
            'detalhe': 'Asaas timeout',
          },
        ),
        type: DioExceptionType.badResponse,
      );
      final a = ApiErro.de(e);
      expect(a.codigo, 'ERRO_INTERNO');
      expect(a.mensagem, 'Erro inesperado. Tente de novo.');
      expect(a.detalhe, 'Asaas timeout');
      expect(a.status, 500);
      expect(a.mensagemParaUsuario, contains('Asaas timeout'));
      expect(a.mensagemParaUsuario, contains('[ERRO_INTERNO]'));
      expect(a.mensagemParaUsuario, contains('HTTP 500'));
    });

    test('timeouts viram SEM_CONEXAO', () {
      for (final tipo in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.connectionError,
      ]) {
        final a = ApiErro.de(
          DioException(requestOptions: RequestOptions(path: '/x'), type: tipo),
        );
        expect(a.codigo, 'SEM_CONEXAO', reason: '$tipo');
        expect(a.mensagem, ApiErro.semConexao);
      }
    });

    test('unknown sem response (CORS/Safari web) vira SEM_CONEXAO', () {
      final a = ApiErro.de(
        DioException(
          requestOptions: RequestOptions(path: '/assinaturas'),
          type: DioExceptionType.unknown,
        ),
      );
      expect(a.codigo, 'SEM_CONEXAO');
      expect(a.mensagem, ApiErro.semConexao);
    });

    test('TypeError de parse vira RESPOSTA_INVALIDA com detalhe', () {
      final a = ApiErro.de(TypeError());
      expect(a.codigo, 'RESPOSTA_INVALIDA');
      expect(a.detalhe, isNotNull);
    });
  });
}
