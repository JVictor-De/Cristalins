import 'package:cristalins_assinatura/core/formatacao.dart';
import 'package:cristalins_assinatura/core/theme/app_colors.dart';
import 'package:flutter/painting.dart';
import 'package:cristalins_assinatura/core/marca_assets.dart';
import 'package:cristalins_assinatura/features/catalog/domain/catalogo.dart';
import 'package:cristalins_assinatura/features/catalog/domain/produto_assets.dart';
import 'package:cristalins_assinatura/features/quiz/domain/quiz.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('P5.2: nomeDoProduto delega a nomeCurtoPorCodigo', () {
    expect(nomeDoProduto('WP500'), nomeCurtoPorCodigo('WP500'));
    expect(nomeDoProduto('AMS500'), 'Sem gás');
    expect(nomeDoProduto('AMC510'), 'Com gás');
  });

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
    expect(nomeCardProduto(agua), 'Sem gás');
  });

  Produto sku(String codigo, int volumeMl, int qtd) => Produto(
    codigo: codigo,
    nome: 'Nome API $codigo',
    tipo: 'COMPLEMENTO',
    volumeMl: volumeMl,
    embalagemQtd: qtd,
    precoBase: const Dinheiro(100),
  );

  test('P0.5: nomes curtos + pack real do seed', () {
    final casos = {
      sku('AMS500', 500, 12): ('Sem gás', '12 × 500 ml'),
      sku('AMC510', 510, 12): ('Com gás', '12 × 510 ml'),
      sku('AMN1500', 1500, 6): ('Sem gás', '6 × 1,5 L'),
      sku('AMN5000', 5000, 1): ('Galão', '5 L'),
      sku('WP500', 500, 6): ('Water Protein', '6 × 500 ml'),
      sku('FF500', 500, 6): ('Flow Fiber', '6 × 500 ml'),
    };
    casos.forEach((p, esperado) {
      expect(nomeCardProduto(p), esperado.$1, reason: p.codigo);
      expect(p.pack, esperado.$2, reason: p.codigo);
    });
    // SKU fora da tabela mantém o nome da API.
    expect(nomeCardProduto(sku('GUA2000', 2000, 1)), 'Nome API GUA2000');
  });

  test('P0.2: fundos soft do bloco por linha', () {
    expect(fundoBlocoProduto('AMS500'), AppColors.blocoAgua);
    expect(fundoBlocoProduto('AMN5000'), AppColors.blocoAgua);
    expect(fundoBlocoProduto('WP500'), AppColors.blocoWaterProtein);
    expect(fundoBlocoProduto('FF500'), AppColors.blocoFlowFiber);
    expect(AppColors.blocoAgua, const Color(0xFFE8F3F8));
    expect(AppColors.blocoWaterProtein, const Color(0xFFE6F3D8));
    expect(AppColors.blocoFlowFiber, const Color(0xFFFBEFD9));
  });

  test('P0.2: escala relativa da garrafa', () {
    expect(escalaGarrafaCard(sku('AMN1500', 1500, 6)).altura, 0.90);
    expect(escalaGarrafaCard(sku('AMS500', 500, 12)).altura, 0.75);
    expect(escalaGarrafaCard(sku('AMN5000', 5000, 1)).largura, 0.90);
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
