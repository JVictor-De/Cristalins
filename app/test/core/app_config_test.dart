import 'package:cristalins_assinatura/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('flavor desconhecido ou nulo cai em dev com a URL do emulador', () {
    final config = AppConfig.doFlavor(null);
    expect(config.ambiente, Ambiente.dev);
    expect(config.urlBaseApi, 'http://10.0.2.2:3000/api/v1');
    expect(config.suporteWhatsapp, AppConfig.suporteWhatsappPadrao);
  });

  test('flavor hml sem API_URL usa o host HML público; prod não inventa', () {
    expect(AppConfig.doFlavor('hml').ambiente, Ambiente.hml);
    expect(AppConfig.doFlavor('hml').apiUrl, AppConfig.apiUrlHmlPadrao);
    expect(AppConfig.doFlavor('prod').apiUrl, isEmpty);
  });

  test('URLs legais têm default público no domínio do app', () {
    expect(AppConfig.urlTermos, 'https://cristalins.peladeiro.cloud/termos.html');
    expect(AppConfig.urlPrivacidade, 'https://cristalins.peladeiro.cloud/privacidade.html');
  });

  test('urlWhatsApp sanitiza dígitos e opcionalmente encode o texto', () {
    const config = AppConfig(
      ambiente: Ambiente.dev,
      apiUrl: '',
      suporteWhatsapp: '+55 (21) 99999-9999',
    );
    expect(config.suporteWhatsappDigitos, '5521999999999');
    expect(config.urlWhatsApp(), 'https://wa.me/5521999999999');
    expect(
      config.urlWhatsApp(texto: 'Olá!'),
      'https://wa.me/5521999999999?text=${Uri.encodeComponent('Olá!')}',
    );
  });

  test('urlWhatsApp devolve null sem dígitos', () {
    const config = AppConfig(ambiente: Ambiente.dev, apiUrl: '', suporteWhatsapp: '  ');
    expect(config.urlWhatsApp(), isNull);
  });
}
