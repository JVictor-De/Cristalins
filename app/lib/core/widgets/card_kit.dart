import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../features/catalog/domain/produto_assets.dart';
import '../formatacao.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Card de kit com âncora de preço (P6): `subtotalBase` da API = Σ `precoBase` × qty
/// por entrega, **antes** dos descontos. Mostrado com “≈” e nota “preço base” — a
/// simulação aplica VOLUME/COMPROMISSO e também `DEMANDA` (até +8%), então
/// “a partir de” sobre o total do kit não seria honesto.
class CardKit extends StatelessWidget {
  const CardKit({
    super.key,
    required this.nome,
    required this.resumoItens,
    required this.onTap,
    required this.onAdicionar,
    this.codigosItens = const [],
    this.precoBase,
  });

  final String nome;
  final String resumoItens;
  final VoidCallback onTap;
  final VoidCallback onAdicionar;

  /// Códigos dos produtos do kit (miniaturas PNG).
  final List<String> codigosItens;

  /// `Kit.subtotalBase` (API). Nulo → card sem preço.
  final Dinheiro? precoBase;

  static const larguraBase = 220.0;
  static const _alturaMinis = 48.0;

  /// Largura cresce com a fonte (até 1,6×) para a nota de preço caber em 2 linhas.
  static double larguraPara(TextScaler escala) =>
      larguraBase * (escala.scale(16) / 16).clamp(1.0, 1.6);

  /// Altura do card para a escala de fonte (lista horizontal de kits na aba Produtos).
  static double alturaPara(TextScaler escala) {
    final textos = escala.scale(22) * 2 + escala.scale(16);
    final rodape = [
      AppSpacing.toqueMinimo,
      escala.scale(21) + escala.scale(16) * 2,
    ].reduce((a, b) => a > b ? a : b);
    return AppSpacing.sm * 2 +
        _alturaMinis +
        AppSpacing.xs +
        textos +
        AppSpacing.xxs +
        AppSpacing.xs +
        rodape +
        2;
  }

  @override
  Widget build(BuildContext context) {
    final minis = <String>[for (final c in codigosItens) ?assetDoProduto(c)].take(4).toList();
    final preco = precoBase?.formatado;
    final raio = BorderRadius.circular(AppSpacing.raioCard);
    final escala = MediaQuery.textScalerOf(context);

    return Semantics(
      container: true,
      button: true,
      label: [
        nome,
        resumoItens,
        if (preco != null) 'cerca de $preco por entrega, preço base antes dos descontos',
      ].join(', '),
      hint: 'Usar este kit na sacola',
      onTap: onTap,
      child: SizedBox(
        width: larguraPara(escala),
        height: alturaPara(escala),
        child: Material(
          color: AppColors.superficie,
          shape: RoundedRectangleBorder(
            borderRadius: raio,
            side: const BorderSide(color: AppColors.linha),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            excludeFromSemantics: true,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: SizedBox(
                      height: _alturaMinis,
                      child: Row(
                        children: [
                          for (var i = 0; i < minis.length; i++) ...[
                            if (i > 0) const SizedBox(width: AppSpacing.xxs),
                            Expanded(
                              child: ColoredBox(
                                color: AppColors.gelo,
                                child: Image.asset(
                                  minis[i],
                                  fit: BoxFit.contain,
                                  cacheWidth: 160,
                                  errorBuilder: (_, _, _) =>
                                      const ColoredBox(color: AppColors.aqua),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ExcludeSemantics(
                    child: Text(
                      nome,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.headline.copyWith(color: AppColors.navy),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  ExcludeSemantics(
                    child: Text(
                      resumoItens,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption1.copyWith(color: AppColors.textoSuave),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: preco == null
                            ? const SizedBox.shrink()
                            : ExcludeSemantics(child: _AncoraPreco(preco: preco)),
                      ),
                      Semantics(
                        button: true,
                        label: 'Adicionar kit $nome à assinatura',
                        excludeSemantics: true,
                        child: IconButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            onAdicionar();
                          },
                          icon: const Icon(Icons.add_circle, color: AppColors.azulMarca),
                          iconSize: 28,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          constraints: const BoxConstraints(
                            minWidth: AppSpacing.toqueMinimo,
                            minHeight: AppSpacing.toqueMinimo,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// “≈ R$ x/entrega” + “Preço base, antes dos descontos” (até 2 linhas com fonte grande).
class _AncoraPreco extends StatelessWidget {
  const _AncoraPreco({required this.preco});

  final String preco;

  @override
  Widget build(BuildContext context) {
    final detalhe = AppTypography.caption1.copyWith(color: AppColors.textoSuave);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '≈ ', style: detalhe),
                TextSpan(
                  text: preco,
                  style: AppTypography.cardPreco.copyWith(
                    color: AppColors.heroInk,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                TextSpan(text: '/entrega', style: detalhe),
              ],
            ),
            maxLines: 1,
          ),
        ),
        Text(
          'Preço base, antes dos descontos',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: detalhe,
        ),
      ],
    );
  }
}
