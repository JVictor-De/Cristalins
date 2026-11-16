import 'package:flutter/painting.dart';

import '../../../core/theme/app_colors.dart';

/// Paths locais dos assets de produto (espelho cristalins-v2 → `assets/images/produtos/`).
/// Alinhado aos códigos do seed da API (`WP500` … `GUA2000`).
String? assetDoProduto(String codigo) {
  switch (codigo) {
    case 'WP500':
      return 'assets/images/produtos/wp500.webp';
    case 'FF500':
      return 'assets/images/produtos/ff500.webp';
    case 'AMS500':
      return 'assets/images/produtos/ams500.webp';
    case 'AMC510':
      return 'assets/images/produtos/amc510.webp';
    case 'AMN1500':
      return 'assets/images/produtos/amn1500.webp';
    case 'AMN5000':
      return 'assets/images/produtos/amn5000.webp';
    case 'AMC200':
      return 'assets/images/produtos/amc200.webp';
    case 'GUA2000':
      return 'assets/images/produtos/gua2000.webp';
    default:
      return null;
  }
}

/// Cor de acento da linha (chip / faixa / PDP). Na grade o fundo do card é [AppColors.gelo].
Color corDoProduto(String codigo) {
  switch (codigo) {
    case 'WP500':
      return AppColors.lima;
    case 'FF500':
      return AppColors.amareloFlow;
    case 'GUA2000':
      return AppColors.menta;
    default:
      return AppColors.aqua;
  }
}

/// Foto de rótulo WP (opcional; preferir em login/onboarding).
const assetProteinDetalhe = 'assets/images/produtos/protein.webp';
