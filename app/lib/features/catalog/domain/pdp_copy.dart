import '../../../core/formatacao.dart';
import '../../../core/marca_assets.dart';
import 'catalogo.dart';
import 'produto_assets.dart';

/// Copy da PDP (P2 design_ux_ui). Sem regra de preço: só exibição do que já existe
/// (`precoBase` / unitário da simulação × quantidade local).
abstract final class PdpCopy {
  /// Teto do stepper (unidades) — `Simulacao.ueMaxima` padrão; a API revalida.
  static const tetoPadrao = 120;

  /// Título: nome curto em WP/FF (“Water Protein”); completo da API nas águas.
  static String titulo(Produto p) =>
      (p.codigo == 'WP500' || p.codigo == 'FF500') ? nomeCardProduto(p) : p.nome;

  /// Linha sob o título: “Garrafa de 500 ml · caixa com 6”; galão “Galão de 5 L”.
  static String embalagem(Produto p) {
    if (p.embalagemQtd <= 1) {
      return p.volumeMl >= 5000 ? 'Galão de ${p.volume}' : 'Unidade de ${p.volume}';
    }
    return 'Garrafa de ${p.volume} · caixa com ${p.embalagemQtd}';
  }

  /// Rótulo do stepper honesto com a meia-caixa (passo 3 em caixa de 6):
  /// 3 → “½ caixa · 3 garrafas”; 6 → “1 caixa · 6 garrafas”; 9 → “1 caixa e meia · 9 garrafas”.
  static String quantidade(Produto p, int qtd) {
    if (p.embalagemQtd <= 1) return '$qtd ${qtd == 1 ? 'unidade' : 'unidades'}';
    final garrafas = '$qtd ${qtd == 1 ? 'garrafa' : 'garrafas'}';
    final cheias = qtd ~/ p.embalagemQtd;
    final resto = qtd % p.embalagemQtd;
    final String caixas;
    if (resto == 0) {
      caixas = '$cheias ${cheias == 1 ? 'caixa' : 'caixas'}';
    } else if (resto * 2 == p.embalagemQtd) {
      caixas = cheias == 0 ? '½ caixa' : '$cheias ${cheias == 1 ? 'caixa' : 'caixas'} e meia';
    } else {
      // Fora do passo conhecido: não inventa fração, mostra só garrafas.
      return garrafas;
    }
    return '$caixas · $garrafas';
  }

  /// Unitário de referência: o da simulação (se o SKU já está na sacola) ou `precoBase`.
  static Dinheiro unitario(Produto p, Simulacao? sim) {
    final item = sim?.itens.where((i) => i.produto == p.codigo).firstOrNull;
    return item?.precoUnitario ?? p.precoBase;
  }

  /// Valor do item para a quantidade local (unitário × qtd). Não é o total da assinatura.
  static Dinheiro valorItem(Produto p, int qtd, Simulacao? sim) =>
      Dinheiro(unitario(p, sim).centavos * qtd);

  /// Linha de compra avulsa (valor da API, sem conta no app). Nulo sem canal avulso.
  static String? avulso(Produto p) => p.precoAvulso == null
      ? null
      : 'Avulso: ${p.precoAvulso!.formatado}${p.embalagemQtd > 1 ? ' /garrafa' : ' /un.'}';

  /// CTA: “Adicionar · R$ X por entrega” ou “Atualizar quantidade · R$ X por entrega”.
  static String cta({required bool naSacola, required Dinheiro valor}) =>
      '${naSacola ? 'Atualizar quantidade' : 'Adicionar'} · ${valor.formatado} por entrega';

  /// Chips (P2.3): `claims` da API quando vierem; sem eles, só o que o rótulo já sustenta
  /// (“Zero açúcar/gordura” só chegam pela API — demo AP2, ver DECISOES).
  static List<String> chips(Produto p) => p.claims.isNotEmpty
      ? p.claims
      : switch (p.codigo) {
          'WP500' => const ['5 g de proteína', 'Com colágeno'],
          'FF500' => const ['5 g de fibras prebióticas'],
          _ when usaCopyImpactoMineral(p.codigo) => const ['Água mineral natural'],
          _ => const [],
        };

  /// Alt da foto (P2.1).
  static String altFoto(Produto p) => switch (p.codigo) {
    'WP500' => 'Garrafa de Water Protein Cristalins 500 ml',
    'FF500' => 'Garrafa de Flow Fiber Cristalins 500 ml',
    _ when usaCopyImpactoMineral(p.codigo) => '${p.nome}. Garrafa toca a água com um respingo.',
    _ => '${p.nome}. Cena Cristalins com respingo.',
  };
}
