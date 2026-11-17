import 'package:cristalins_assinatura/core/formatacao.dart';
import 'package:cristalins_assinatura/core/marca_assets.dart';
import 'package:cristalins_assinatura/features/catalog/domain/catalogo.dart';
import 'package:cristalins_assinatura/features/catalog/domain/produto_assets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('nomeCardProduto encurta WP e FF', () {
    const wp = Produto(
      codigo: 'WP500',
      nome: 'Water Protein 500 ml — caixa',
      tipo: 'PRINCIPAL',
      volumeMl: 500,
      embalagemQtd: 6,
      precoBase: Dinheiro(990),
    );
    const ff = Produto(
      codigo: 'FF500',
      nome: 'Flow Fiber 500 ml',
      tipo: 'PRINCIPAL',
      volumeMl: 500,
      embalagemQtd: 6,
      precoBase: Dinheiro(890),
    );
    const agua = Produto(
      codigo: 'AMS500',
      nome: 'Água mineral 500 ml',
      tipo: 'COMPLEMENTO',
      volumeMl: 500,
      embalagemQtd: 12,
      precoBase: Dinheiro(220),
    );
    expect(nomeCardProduto(wp), 'Water Protein');
    expect(nomeCardProduto(ff), 'Flow Fiber');
    expect(nomeCardProduto(agua), 'Água mineral 500 ml');
  });

  test('asset FF é PNG flow_fiber-fast', () {
    expect(assetDoProduto('FF500'), 'assets/images/produtos/flow_fiber-fast.png');
  });

  test('cada água mineral da cena de impacto tem garrafa própria', () {
    final porSku = {
      for (final codigo in codigosAguaMineralImpacto) codigo: garrafaDaCenaImpacto(codigo),
    };

    expect(porSku['AMS500'], 'assets/images/produtos/ams500.png');
    expect(porSku['AMC510'], 'assets/images/produtos/amc510.png');
    expect(porSku['AMN1500'], 'assets/images/produtos/amn1500.png');
    expect(porSku['AMN5000'], 'assets/images/produtos/amn5000.png');
    expect(porSku['AMC200'], 'assets/images/produtos/amc200.png');

    final caminhos = porSku.values.toSet();
    expect(
      caminhos.length,
      porSku.length,
      reason: 'SKUs minerais não podem compartilhar a mesma foto de garrafa',
    );
    expect(caminhos.contains(assetImpactoGarrafa), isFalse);
  });

  test('WP, Fiber e guaraná também têm garrafa distinta na cena', () {
    expect(garrafaDaCenaImpacto('WP500'), 'assets/images/produtos/protein.png');
    expect(garrafaDaCenaImpacto('FF500'), 'assets/images/produtos/flow_fiber-fast.png');
    expect(garrafaDaCenaImpacto('GUA2000'), 'assets/images/produtos/gua2000.png');
    expect(usaCopyImpactoMineral('WP500'), isFalse);
    expect(usaCopyImpactoMineral('AMS500'), isTrue);
  });
}
