import 'package:cristalins_assinatura/core/formatacao.dart';
import 'package:cristalins_assinatura/features/catalog/domain/carrossel_home.dart';
import 'package:cristalins_assinatura/features/catalog/domain/catalogo.dart';
import 'package:flutter_test/flutter_test.dart';

Produto _p(String codigo, {String? nome, int volumeMl = 500}) => Produto(
      codigo: codigo,
      nome: nome ?? codigo,
      tipo: codigo == 'WP500' || codigo == 'FF500' ? 'PRINCIPAL' : 'COMPLEMENTO',
      volumeMl: volumeMl,
      embalagemQtd: 6,
      precoBase: const Dinheiro(100),
    );

void main() {
  test('carrossel Home não começa por WP e inclui galão', () {
    final lista = produtosCarrosselHome([
      _p('WP500'),
      _p('FF500'),
      _p('AMS500', nome: 'Água mineral sem gás'),
      _p('AMN5000', nome: 'Água mineral natural (galão)', volumeMl: 5000),
    ]);
    expect(lista.first.codigo, isNot('WP500'));
    expect(lista.any((p) => p.codigo == 'AMN5000'), isTrue);
    expect(lista.last.codigo, 'WP500');
  });

  test('filtros Sem gás / Galão / Funcionais', () {
    final origem = [
      _p('AMS500', nome: 'Água mineral sem gás'),
      _p('AMC510', nome: 'Água mineral com gás'),
      _p('AMN5000', volumeMl: 5000),
      _p('WP500'),
      _p('FF500'),
    ];
    expect(
      produtosCarrosselHome(origem, filtro: FiltroHomeCarrossel.semGas).map((e) => e.codigo),
      containsAll(['AMS500', 'AMN5000']),
    );
    expect(
      produtosCarrosselHome(origem, filtro: FiltroHomeCarrossel.galao).single.codigo,
      'AMN5000',
    );
    expect(
      produtosCarrosselHome(origem, filtro: FiltroHomeCarrossel.funcionais).map((e) => e.codigo),
      unorderedEquals(['WP500', 'FF500']),
    );
  });
}
