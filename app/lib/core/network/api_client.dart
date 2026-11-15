import 'package:dio/dio.dart';

import '../config/app_config.dart';

/// Cliente HTTP único (dio). Só a camada `data` das features usa esta classe.
/// Token, refresh e conversão de erro `{ codigo, mensagem, campo? }` chegam em `cr-1-auth`/`cr-2-telas`.
class ApiClient {
  ApiClient(AppConfig config)
    : dio = Dio(
        BaseOptions(
          baseUrl: config.urlBaseApi,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          contentType: Headers.jsonContentType,
        ),
      );

  final Dio dio;
}
