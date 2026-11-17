import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Garante que o nginx da web HML não cacheia a entrada do Flutter (build antigo no celular).
void main() {
  late String conf;

  setUpAll(() {
    // `flutter test` roda com cwd = pasta `app/`.
    conf = File('nginx.conf').readAsStringSync();
  });

  test('raiz e index.html pedem revalidação (no-cache)', () {
    expect(conf, contains('location = / {'));
    expect(conf, contains('location = /index.html {'));
    expect(conf, contains('Cache-Control "no-cache, must-revalidate"'));
  });

  test('bootstrap e main.dart.js não ficam com max-age longo', () {
    expect(conf, contains('location = /flutter_bootstrap.js'));
    expect(conf, contains('location = /main.dart.js'));
    expect(conf, contains('location = /flutter_service_worker.js'));
    // Regra antiga que cacheava todo .js por 7d não pode voltar.
    expect(conf.contains(r'.(js|wasm|css|png'), isFalse);
  });

  test('assets e canvaskit usam prefixo ^~ com cache longo', () {
    expect(conf, contains('location ^~ /assets/'));
    expect(conf, contains('location ^~ /canvaskit/'));
    expect(conf, contains('max-age=604800'));
  });
}
