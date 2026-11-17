import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Contratos dos prints canônicos AP2 (repo: `docs/prints/`, relativo a `app/`).
void main() {
  final dir = Directory('../docs/prints');

  test('pasta docs/prints existe', () {
    expect(dir.existsSync(), isTrue, reason: 'rodar flutter test a partir de app/');
  });

  test('canônicos 01, 02 e 05 existem como PNG', () {
    for (final nome in [
      '01-boas-vindas.png',
      '02-cadastro-login.png',
      '05-catalogo-cesta.png',
    ]) {
      final f = File('${dir.path}/$nome');
      expect(f.existsSync(), isTrue, reason: 'falta $nome');
      expect(f.lengthSync(), greaterThan(10_000), reason: '$nome muito pequeno');
    }
  });

  test('placeholders só para os que ainda faltam', () {
    for (final nome in [
      '03-quiz.md',
      '04-resultado.md',
      '06-endereco.md',
      '07-plano-pagamento.md',
      '08-minha-assinatura.md',
    ]) {
      expect(File('${dir.path}/$nome').existsSync(), isTrue, reason: 'esperado placeholder $nome');
      expect(File('${dir.path}/${nome.replaceAll('.md', '.png')}').existsSync(), isFalse);
    }
    // Já capturados: sem .md residual
    for (final nome in ['01-boas-vindas.md', '02-cadastro-login.md', '05-catalogo-cesta.md']) {
      expect(File('${dir.path}/$nome').existsSync(), isFalse, reason: 'remover placeholder $nome');
    }
  });
}
