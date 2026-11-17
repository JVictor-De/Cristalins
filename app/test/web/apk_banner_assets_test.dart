import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Garante o contrato do banner de download no Flutter Web (APK + index + nginx).
void main() {
  test('index.html tem banner APK e checagem HEAD', () {
    final index = File('web/index.html');
    expect(index.existsSync(), isTrue, reason: 'rodar a partir de app/');
    final html = index.readAsStringSync();
    expect(html, contains('cristalins-apk-banner'));
    expect(html, contains('downloads/cristalins-hml.apk'));
    expect(html, contains("method: 'HEAD'"));
    expect(html, contains('flutter-first-frame'));
  });

  test('nginx conf serve /downloads/ com MIME de APK', () {
    final nginx = File('nginx.conf');
    expect(nginx.existsSync(), isTrue);
    final conf = nginx.readAsStringSync();
    expect(conf, contains('location ^~ /downloads/'));
    expect(conf, contains('application/vnd.android.package-archive'));
  });

  test('pasta downloads existe (APK opcional no CI)', () {
    final dir = Directory('web/downloads');
    expect(dir.existsSync(), isTrue);
    // APK é gitignored; localmente deve existir após build hml.
    final apk = File('web/downloads/cristalins-hml.apk');
    if (apk.existsSync()) {
      expect(apk.lengthSync(), greaterThan(1_000_000), reason: 'APK vazio/corrupto');
    }
  });
}
