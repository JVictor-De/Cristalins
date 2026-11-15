import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'sessao.dart';

/// Cliente HTTP único (dio). Só a camada `data` das features usa esta classe.
///
/// - Envia `Authorization: Bearer <accessToken>` do [ArmazenamentoTokens].
/// - No 401, tenta `POST /auth/refresh` uma vez e repete a chamada.
///   Se a renovação falhar, limpa a sessão e chama [aoExpirarSessao] (a app volta ao login).
class ApiClient {
  ApiClient(AppConfig config, {required this.tokens, this.aoExpirarSessao, Dio? dio})
    : dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: config.urlBaseApi,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
              contentType: Headers.jsonContentType,
            ),
          ) {
    this.dio.interceptors.add(
      QueuedInterceptorsWrapper(onRequest: _anexarToken, onError: _renovarNo401),
    );
  }

  final Dio dio;
  final ArmazenamentoTokens tokens;
  void Function()? aoExpirarSessao;

  static const _rotasSemToken = ['/auth/login', '/auth/refresh', '/clientes'];
  static const _jaRepetida = 'repetidaAposRefresh';

  Future<void> _anexarToken(RequestOptions options, RequestInterceptorHandler handler) async {
    final publica = options.method == 'POST' && _rotasSemToken.contains(options.path);
    if (!publica) {
      final token = await tokens.lerAcesso();
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  Future<void> _renovarNo401(DioException erro, ErrorInterceptorHandler handler) async {
    final options = erro.requestOptions;
    final podeRenovar =
        erro.response?.statusCode == 401 &&
        options.extra[_jaRepetida] != true &&
        !_rotasSemToken.contains(options.path);
    if (!podeRenovar) return handler.next(erro);

    final refresh = await tokens.lerRefresh();
    if (refresh == null) return _expirar(erro, handler);
    try {
      final r = await Dio(
        BaseOptions(baseUrl: dio.options.baseUrl, contentType: Headers.jsonContentType),
      ).post<Map<String, dynamic>>('/auth/refresh', data: {'refreshToken': refresh});
      await tokens.salvar(
        acesso: r.data!['accessToken'] as String,
        refresh: r.data!['refreshToken'] as String,
      );
      options.extra[_jaRepetida] = true;
      options.headers['Authorization'] = 'Bearer ${r.data!['accessToken']}';
      handler.resolve(await dio.fetch<dynamic>(options));
    } on DioException {
      await _expirar(erro, handler);
    }
  }

  Future<void> _expirar(DioException erro, ErrorInterceptorHandler handler) async {
    await tokens.limpar();
    aoExpirarSessao?.call();
    handler.next(erro);
  }
}
