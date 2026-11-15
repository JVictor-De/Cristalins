/// Ambiente do build (flavor Android `dev`, `hml`, `prod`).
enum Ambiente { dev, hml, prod }

/// Configuração lida de `--dart-define`. Nada de segredo aqui.
///
/// - `API_URL`: base da API sem o prefixo (emulador: `http://10.0.2.2:3000`).
/// - `SUPORTE_WHATSAPP`: número do suporte; vazio = não exibir (não inventar número).
class AppConfig {
  const AppConfig({required this.ambiente, required this.apiUrl, required this.suporteWhatsapp});

  factory AppConfig.doAmbiente(Ambiente ambiente) {
    const apiUrl = String.fromEnvironment('API_URL');
    return AppConfig(
      ambiente: ambiente,
      apiUrl: apiUrl.isNotEmpty ? apiUrl : (ambiente == Ambiente.dev ? 'http://10.0.2.2:3000' : ''),
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

  final Ambiente ambiente;
  final String apiUrl;
  final String suporteWhatsapp;

  String get urlBaseApi => '$apiUrl$prefixoApi';
}
