import 'package:cristalins_assinatura/core/formatacao.dart';
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
}
