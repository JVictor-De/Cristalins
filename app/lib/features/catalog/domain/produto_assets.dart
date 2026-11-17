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

/// Recorte rente ao alpha (~600 px de altura = 3× do bloco 200) só para o card
/// foto-âncora: base alinhada sem margem transparente. Hero/PDP seguem com
/// [assetDoProduto] (composição própria).
const _codigosComRecorteCard = {
  'AMS500',
  'AMC510',
  'AMN1500',
  'AMN5000',
  'WP500',
  'FF500',
  'AMC200',
  'GUA2000',
};

String? assetCardProduto(String codigo) => _codigosComRecorteCard.contains(codigo)
    ? 'assets/images/produtos/card/${codigo.toLowerCase()}.png'
    : assetDoProduto(codigo);

/// Fundo soft do bloco foto-âncora do card (P0): águas / WP / FF.
Color fundoBlocoProduto(String codigo) {
  switch (codigo) {
    case 'WP500':
      return AppColors.blocoWaterProtein;
    case 'FF500':
      return AppColors.blocoFlowFiber;
    default:
      return AppColors.blocoAgua;
  }
}

/// Escala da garrafa dentro do bloco (fração da altura/largura úteis).
/// 1,5 L ~90% altura; 500 ml ~75%; galão ~90% largura; demais ~85%.
({double altura, double largura}) escalaGarrafaCard(Produto produto) {
  if (produto.codigo == 'AMN5000' || produto.volumeMl >= 5000) {
    return (altura: 0.85, largura: 0.90);
  }
  if (produto.volumeMl >= 1500) return (altura: 0.90, largura: 0.80);
  if (produto.volumeMl >= 500 && produto.volumeMl <= 510) return (altura: 0.75, largura: 0.70);
  return (altura: 0.85, largura: 0.80);
}

/// Nome curto por código (P0.5 / P5.2) — listas: sacola, assinatura, recibo, quiz.
/// Desconhecido: [fallback] ou o próprio código.
String nomeCurtoPorCodigo(String codigo, {String? fallback}) {
  switch (codigo) {
    case 'WP500':
      return 'Water Protein';
    case 'FF500':
      return 'Flow Fiber';
    case 'AMS500':
    case 'AMN1500':
      return 'Sem gás';
    case 'AMC510':
      return 'Com gás';
    case 'AMN5000':
      return 'Galão';
    // Fora da tabela P0: preferir nome API ([fallback]); senão rótulo curto de recibo.
    case 'AMC200':
      return fallback ?? 'Água no copo';
    case 'GUA2000':
      return fallback ?? 'Guaraná Cristalins';
    default:
      return fallback ?? codigo;
  }
}

/// Nome curto no card (P0.5). Leitor de tela usa o nome completo da API.
String nomeCardProduto(Produto produto) =>
    nomeCurtoPorCodigo(produto.codigo, fallback: produto.nome);

/// Foto de rótulo WP (opcional; preferir em login/onboarding).
const assetProteinDetalhe = 'assets/images/produtos/protein.png';

/// Garrafa da cena de impacto na PDP: muda por SKU; fundo/respingo ficam fixos.
String garrafaDaCenaImpacto(String codigo) => assetDoProduto(codigo) ?? assetProteinDetalhe;
