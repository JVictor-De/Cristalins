import 'package:cristalins_assinatura/core/intents/abridor_links.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AbridorLinks.uriParaAbrir', () {
    test('em web, geo com q vira Apple Maps HTTPS', () {
      final u = AbridorLinks.uriParaAbrir(
        'geo:0,0?q=${Uri.encodeComponent('Rua das Laranjeiras, Rio')}',
        forcarWeb: true,
      );
      expect(u.scheme, 'https');
      expect(u.host, 'maps.apple.com');
      expect(u.queryParameters['q'], 'Rua das Laranjeiras, Rio');
    });

    test('em web, geo com coordenadas vira ll', () {
      final u = AbridorLinks.uriParaAbrir('geo:-22.9,-43.1', forcarWeb: true);
      expect(u.host, 'maps.apple.com');
      expect(u.queryParameters['ll'], '-22.9,-43.1');
    });

    test('fora da web mantém geo', () {
      final u = AbridorLinks.uriParaAbrir('geo:0,0?q=Copacabana', forcarWeb: false);
      expect(u.scheme, 'geo');
      expect(u.queryParameters['q'], 'Copacabana');
    });

    test('https não é alterado', () {
      final u = AbridorLinks.uriParaAbrir('https://wa.me/5521999999999', forcarWeb: true);
      expect(u.toString(), 'https://wa.me/5521999999999');
    });
  });
}
