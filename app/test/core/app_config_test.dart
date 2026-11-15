import 'package:cristalins_assinatura/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('flavor desconhecido ou nulo cai em dev com a URL do emulador', () {
    final config = AppConfig.doFlavor(null);
    expect(config.ambiente, Ambiente.dev);
    expect(config.urlBaseApi, 'http://10.0.2.2:3000/api/v1');
    expect(config.suporteWhatsapp, isEmpty);
  });

  test('flavor hml e prod sem API_URL não inventam endereço', () {
    expect(AppConfig.doFlavor('hml').ambiente, Ambiente.hml);
    expect(AppConfig.doFlavor('prod').apiUrl, isEmpty);
  });
}
