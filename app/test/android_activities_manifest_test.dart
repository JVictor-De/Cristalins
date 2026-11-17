import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Teste mínimo AP2: Manifest declara ≥5 Activities nativas (SPEC).
void main() {
  test('AndroidManifest declara ≥5 Activities AP2', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml');
    expect(manifest.existsSync(), isTrue, reason: 'rodar testes a partir de app/');

    final texto = manifest.readAsStringSync();
    final activities = RegExp(r'<activity\b').allMatches(texto);
    expect(activities.length, greaterThanOrEqualTo(5));

    const esperadas = [
      'MainActivity',
      'BoasVindasActivity',
      'CadastroLoginActivity',
      'QuizActivity',
      'ResultadoActivity',
      'CatalogoActivity',
      'EnderecoActivity',
      'PlanoPagamentoActivity',
      'MinhaAssinaturaActivity',
    ];
    for (final nome in esperadas) {
      expect(texto, contains(nome), reason: 'falta $nome no Manifest');
    }

    // Um único launcher.
    expect(RegExp(r'android.intent.action.MAIN').allMatches(texto).length, 1);

    // Label via manifestPlaceholders (AGP 9 / newDsl=false — sem resValue nos flavors).
    expect(texto, contains('android:label="\${appName}"'));
  });

  test('CristalinsEngine.kt: channel e whitelist alinhados ao Dart', () {
    final engine = File(
      'android/app/src/main/kotlin/br/com/cristalins/assinatura/CristalinsEngine.kt',
    );
    expect(engine.existsSync(), isTrue);
    final kt = engine.readAsStringSync();
    expect(kt, contains('br.com.cristalins.assinatura/navegacao'));
    expect(kt, contains('anexarHost'));
    expect(kt, contains('limparHost'));
    for (final nome in [
      'BoasVindasActivity',
      'CadastroLoginActivity',
      'QuizActivity',
      'ResultadoActivity',
      'CatalogoActivity',
      'EnderecoActivity',
      'PlanoPagamentoActivity',
      'MinhaAssinaturaActivity',
    ]) {
      expect(kt, contains('"$nome"'), reason: 'whitelist sem $nome');
    }
  });
}
