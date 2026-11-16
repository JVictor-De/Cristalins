import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../features/catalog/domain/catalogo.dart';
import '../../features/catalog/domain/produto_assets.dart';
import '../theme/app_colors.dart';
import '../theme/app_sombras.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Card da grade — sem preço (simulação só na barra/PDP/sacola).
class CardProduto extends StatelessWidget {
  const CardProduto({
    super.key,
    required this.produto,
    required this.onAbrir,
    required this.onAdicionar,
    this.quantidade = 0,
  });

  final Produto produto;
  final VoidCallback onAbrir;
  final VoidCallback onAdicionar;
  final int quantidade;

  @override
  Widget build(BuildContext context) {
    final asset = assetDoProduto(produto.codigo);
    return Material(
      color: AppColors.gelo,
      borderRadius: BorderRadius.circular(AppSpacing.raioCard),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.raioCard),
        excludeFromSemantics: true,
        onTap: () {
          HapticFeedback.selectionClick();
          onAbrir();
        },
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.gelo,
            borderRadius: BorderRadius.circular(AppSpacing.raioCard),
            boxShadow: AppSombras.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: asset == null
                      ? const ColoredBox(color: AppColors.aqua)
                      : Image.asset(
                          asset,
                          fit: BoxFit.contain,
                          cacheWidth: 400,
                          semanticLabel: produto.nome,
                          errorBuilder: (_, _, _) => const ColoredBox(color: AppColors.aqua),
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.sm, 0, AppSpacing.sm, AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      produto.nome,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.headline.copyWith(color: AppColors.tinta),
                    ),
                    Text(
                      '${produto.volume} · ${produto.embalagem}',
                      style: AppTypography.caption1.copyWith(color: AppColors.textoSuave),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Semantics(
                        button: true,
                        label: 'Adicionar ${produto.nome} à assinatura',
                        excludeSemantics: true,
                        child: Material(
                          color: AppColors.azulMarca,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            excludeFromSemantics: true,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              onAdicionar();
                            },
                            child: SizedBox(
                              width: AppSpacing.toqueMinimo,
                              height: AppSpacing.toqueMinimo,
                              child: Center(
                                child: quantidade > 0
                                    ? Text(
                                        '$quantidade',
                                        style: AppTypography.caption1.copyWith(
                                          color: AppColors.sobrePrimaria,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      )
                                    : const Icon(Icons.add, color: AppColors.sobrePrimaria),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
