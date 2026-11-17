import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Regressão do build Coolify: `kIsWeb` sem `foundation.dart` quebra o dart2js
/// mesmo quando o analyzer local “engole” o símbolo via exports transitivos.
void main() {
  test('todo .dart em lib que usa kIsWeb importa flutter/foundation.dart', () {
    final lib = Directory('lib');
    expect(lib.existsSync(), isTrue, reason: 'rode flutter test a partir de app/');

    final faltando = <String>[];
    for (final f in lib.listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      final texto = f.readAsStringSync();
      if (!RegExp(r'\bkIsWeb\b').hasMatch(texto)) continue;
      if (!texto.contains("import 'package:flutter/foundation.dart'")) {
        faltando.add(f.path.replaceAll('\\', '/'));
      }
    }
    expect(faltando, isEmpty, reason: 'Arquivos sem import de foundation:\n${faltando.join('\n')}');
  });
}
