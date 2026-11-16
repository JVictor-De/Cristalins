import 'package:cristalins_assinatura/core/marca_assets.dart';
import 'package:cristalins_assinatura/core/theme/app_colors.dart';
import 'package:cristalins_assinatura/features/catalog/domain/catalogo.dart';
import 'package:cristalins_assinatura/features/catalog/domain/produto_assets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('corDoProduto', () {
    test('acento por linha (não fundo de card)', () {
      expect(corDoProduto('WP500'), AppColors.lima);
      expect(corDoProduto('FF500'), AppColors.amareloFlow);
      expect(corDoProduto('GUA2000'), AppColors.menta);
      expect(corDoProduto('AMS500'), AppColors.aqua);
    });
  });

  group('assetDoProduto', () {
    test('mapeia os 8 códigos do seed para PNG transparentes', () {
      const esperados = {
        'WP500': 'assets/images/produtos/protein.png',
        'FF500': 'assets/images/produtos/flow_fiber-fast.png',
        'AMS500': 'assets/images/produtos/ams500.png',
        'AMC510': 'assets/images/produtos/amc510.png',
        'AMN1500': 'assets/images/produtos/amn1500.png',
        'AMN5000': 'assets/images/produtos/amn5000.png',
        'AMC200': 'assets/images/produtos/amc200.png',
        'GUA2000': 'assets/images/produtos/gua2000.png',
      };

      for (final e in esperados.entries) {
        expect(assetDoProduto(e.key), e.value, reason: e.key);
      }
      expect(assetProteinDetalhe, 'assets/images/produtos/protein.png');
      expect(assetProdutoWaterProtein, 'assets/images/produtos/protein.png');
      expect(assetHeroFlowFiber, 'assets/images/produtos/flow_fiber-fast.png');
      expect(assetProdutoAguaMineral, 'assets/images/produtos/ams500.png');
      expect(assetHeroColocarSite, 'assets/images/produtos/ams500.png');
    });

    test('código desconhecido retorna null (fallback de UI)', () {
      expect(assetDoProduto('CERVEJA'), isNull);
      expect(assetDoProduto(''), isNull);
      expect(assetDoProduto('wp500'), isNull);
    });
  });

  group('Categoria.chipsPara', () {
    test('vazio → sem chips', () {
      expect(Categoria.chipsPara(totalProdutos: 0, temKits: true), isEmpty);
    });

    test('curto ≤ kLimiteCatalogoCurto → Funcionais; Kits só se houver', () {
      expect(kLimiteCatalogoCurto, 12);
      expect(
        Categoria.chipsPara(totalProdutos: 8, temKits: false),
        [Categoria.todos, Categoria.aguas, Categoria.funcionais],
      );
      expect(
        Categoria.chipsPara(totalProdutos: 12, temKits: true),
        [Categoria.todos, Categoria.aguas, Categoria.funcionais, Categoria.kits],
      );
    });

    test('longo > 12 → WP/Fiber separados + Kits', () {
      expect(
        Categoria.chipsPara(totalProdutos: 13, temKits: false),
        [
          Categoria.todos,
          Categoria.waterProtein,
          Categoria.flowFiber,
          Categoria.aguas,
          Categoria.kits,
        ],
      );
    });
  });
}
