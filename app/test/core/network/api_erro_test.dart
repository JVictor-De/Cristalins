import 'package:cristalins_assinatura/core/network/api_erro.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiErro.de', () {
    test('repassa ApiErro existente', () {
      const original = ApiErro(codigo: 'X', mensagem: 'Já era');
      expect(ApiErro.de(original), same(original));
    });

    test('lê codigo/mensagem do corpo da API', () {
      final e = DioException(
        requestOptions: RequestOptions(path: '/x'),
        response: Response(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 400,
          data: {'codigo': 'CESTA_INVALIDA', 'mensagem': 'Ajuste a cesta.', 'campo': 'itens'},
        ),
        type: DioExceptionType.badResponse,
      );
      final a = ApiErro.de(e);
      expect(a.codigo, 'CESTA_INVALIDA');
      expect(a.mensagem, 'Ajuste a cesta.');
      expect(a.campo, 'itens');
      expect(a.status, 400);
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

    test('erro genérico quando não há formato conhecido', () {
      final a = ApiErro.de(Exception('boom'));
      expect(a.codigo, 'ERRO');
      expect(a.mensagem, ApiErro.generico);
    });
  });
}
