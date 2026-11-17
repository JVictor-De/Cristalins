import 'package:flutter/foundation.dart';

/// Ambiente do build (flavor Android `dev`, `hml`, `prod`; web usa `-t lib/main_*.dart`).
enum Ambiente { dev, hml, prod }

/// Configuração lida de `--dart-define`. Nada de segredo aqui.
///
/// - `API_URL`: base da API sem o prefixo (emulador Android: `http://10.0.2.2:3000`;
///   Chrome local: `http://localhost:3000`; hml: `https://apicristalins.peladeiro.cloud`).
/// - `SUPORTE_WHATSAPP`: número do suporte (default fictício `5521999999999` para HML/dev).
class AppConfig {
  const AppConfig({required this.ambiente, required this.apiUrl, required this.suporteWhatsapp});

  /// Número fictício (RJ) para demos/HML até haver contato real da marca.
  static const suporteWhatsappPadrao = '5521999999999';

  /// Host HML público da API (sem `/api/v1`).
  static const apiUrlHmlPadrao = 'https://apicristalins.peladeiro.cloud';

  factory AppConfig.doAmbiente(Ambiente ambiente) {
    const apiUrl = String.fromEnvironment('API_URL');
    final fallbackDev = kIsWeb ? 'http://localhost:3000' : 'http://10.0.2.2:3000';
    final resolvida = apiUrl.isNotEmpty
        ? apiUrl
        : switch (ambiente) {
            Ambiente.dev => fallbackDev,
            Ambiente.hml => apiUrlHmlPadrao,
            Ambiente.prod => '',
          };
    return AppConfig(
      ambiente: ambiente,
      apiUrl: resolvida,
      suporteWhatsapp: const String.fromEnvironment(
        'SUPORTE_WHATSAPP',
        defaultValue: suporteWhatsappPadrao,
      ),
    );
  }

  /// Escolhe o ambiente pelo nome do flavor (`appFlavor`); sem flavor, `dev`.
  factory AppConfig.doFlavor(String? flavor) {
    final ambiente = Ambiente.values.firstWhere(
      (a) => a.name == flavor,
      orElse: () => Ambiente.dev,
    );
    return AppConfig.doAmbiente(ambiente);
  }

  static const prefixoApi = '/api/v1';
  static const siteMarca = 'https://www.cristalins.com.br/';

  /// Espelha `pubspec.yaml` `version:` (sem `package_info_plus`). Override: `--dart-define=APP_VERSION=`.
  static const versaoApp = String.fromEnvironment('APP_VERSION', defaultValue: '0.1.0+1');

  /// Páginas legais no site do app (Flutter Web / nginx). Override via `--dart-define`.
  static const urlTermos = String.fromEnvironment(
    'URL_TERMOS',
    defaultValue: 'https://cristalins.peladeiro.cloud/termos.html',
  );
  static const urlPrivacidade = String.fromEnvironment(
    'URL_PRIVACIDADE',
    defaultValue: 'https://cristalins.peladeiro.cloud/privacidade.html',
  );

  final Ambiente ambiente;
  final String apiUrl;
  final String suporteWhatsapp;

  String get urlBaseApi => '$apiUrl$prefixoApi';

  /// Dígitos E.164-ish para `wa.me` (remove `+`, espaços, parênteses).
  String get suporteWhatsappDigitos => suporteWhatsapp.replaceAll(RegExp(r'\D'), '');

  /// URL `https://wa.me/...` pronta, ou `null` se não houver número.
  String? urlWhatsApp({String? texto}) {
    final digitos = suporteWhatsappDigitos;
    if (digitos.isEmpty) return null;
    if (texto == null || texto.isEmpty) return 'https://wa.me/$digitos';
    return 'https://wa.me/$digitos?text=${Uri.encodeComponent(texto)}';
  }
}
