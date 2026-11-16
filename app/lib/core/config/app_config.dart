import 'package:flutter/foundation.dart';

/// Ambiente do build (flavor Android `dev`, `hml`, `prod`; web usa `-t lib/main_*.dart`).
enum Ambiente { dev, hml, prod }

/// Configuração lida de `--dart-define`. Nada de segredo aqui.
///
/// - `API_URL`: base da API sem o prefixo (emulador Android: `http://10.0.2.2:3000`;
///   Chrome local: `http://localhost:3000`; hml web: `https://apicristalins.peladeiro.cloud`).
/// - `SUPORTE_WHATSAPP`: número do suporte; vazio = não exibir (não inventar número).
class AppConfig {
  const AppConfig({required this.ambiente, required this.apiUrl, required this.suporteWhatsapp});

  factory AppConfig.doAmbiente(Ambiente ambiente) {
    const apiUrl = String.fromEnvironment('API_URL');
    final fallbackDev = kIsWeb ? 'http://localhost:3000' : 'http://10.0.2.2:3000';
    return AppConfig(
      ambiente: ambiente,
      apiUrl: apiUrl.isNotEmpty ? apiUrl : (ambiente == Ambiente.dev ? fallbackDev : ''),
      suporteWhatsapp: const String.fromEnvironment('SUPORTE_WHATSAPP'),
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

  /// URLs legais — vazias = “em breve” na UI (não inventar).
  static const urlTermos = String.fromEnvironment('URL_TERMOS');
  static const urlPrivacidade = String.fromEnvironment('URL_PRIVACIDADE');

  final Ambiente ambiente;
  final String apiUrl;
  final String suporteWhatsapp;

  String get urlBaseApi => '$apiUrl$prefixoApi';
}
