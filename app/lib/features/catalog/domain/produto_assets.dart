import 'package:flutter/painting.dart';

import '../../../core/theme/app_colors.dart';
import 'catalogo.dart';

/// Paths locais dos assets de produto (espelho cristalins-v2 → `assets/images/produtos/`).
/// Alinhado aos códigos do seed da API (`WP500` … `GUA2000`).
/// Preferir PNG com fundo transparente (sem caixa opaca em hero lima / cards gelo).
String? assetDoProduto(String codigo) {
  switch (codigo) {
    case 'WP500':
      // Não existe wp500.png — recorte transparente compartilhado.
      return 'assets/images/produtos/protein.png';
    case 'FF500':
      // Não existe ff500.png — recorte transparente compartilhado.
      return 'assets/images/produtos/flow_fiber-fast.png';
    case 'AMS500':
      return 'assets/images/produtos/ams500.png';
    case 'AMC510':
      return 'assets/images/produtos/amc510.png';
    case 'AMN1500':
      return 'assets/images/produtos/amn1500.png';
    case 'AMN5000':
      return 'assets/images/produtos/amn5000.png';
    case 'AMC200':
      return 'assets/images/produtos/amc200.png';
    case 'GUA2000':
      return 'assets/images/produtos/gua2000.png';
    default:
      return null;
  }
}

/// Cor de acento da linha (chip / faixa / fundo suave do card).
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

/// Nome curto no card / a11y (WP/FF sem volume longo da API).
String nomeCardProduto(Produto produto) {
  switch (produto.codigo) {
    case 'WP500':
      return 'Water Protein';
    case 'FF500':
      return 'Flow Fiber';
    default:
      return produto.nome;
  }
}

/// Foto de rótulo WP (opcional; preferir em login/onboarding).
const assetProteinDetalhe = 'assets/images/produtos/protein.png';
