import 'package:cristalins_assinatura/core/theme/app_colors.dart';
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
    test('mapeia os 8 códigos do seed para WebP locais', () {
      const esperados = {
        'WP500': 'assets/images/produtos/wp500.webp',
        'FF500': 'assets/images/produtos/ff500.webp',
        'AMS500': 'assets/images/produtos/ams500.webp',
        'AMC510': 'assets/images/produtos/amc510.webp',
        'AMN1500': 'assets/images/produtos/amn1500.webp',
        'AMN5000': 'assets/images/produtos/amn5000.webp',
        'AMC200': 'assets/images/produtos/amc200.webp',
        'GUA2000': 'assets/images/produtos/gua2000.webp',
      };

      for (final e in esperados.entries) {
        expect(assetDoProduto(e.key), e.value, reason: e.key);
      }
    });

    test('código desconhecido retorna null (fallback de UI)', () {
      expect(assetDoProduto('CERVEJA'), isNull);
      expect(assetDoProduto(''), isNull);
      expect(assetDoProduto('wp500'), isNull);
    });
  });
}
