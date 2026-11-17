import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../features/catalog/domain/catalogo.dart';
import '../../features/catalog/domain/produto_assets.dart';
import '../theme/app_colors.dart';
import '../theme/app_sombras.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'stepper_quantidade.dart';

/// Card da grade — sem preço (simulação só na barra/PDP/sacola).
class CardProduto extends StatelessWidget {
  const CardProduto({
    super.key,
    required this.produto,
    required this.onAbrir,
    required this.onAdicionar,
    required this.onAlterar,
    required this.passo,
    this.quantidade = 0,
  });

  final Produto produto;
  final VoidCallback onAbrir;
  final VoidCallback onAdicionar;
  final ValueChanged<int> onAlterar;
  final int passo;
  final int quantidade;

  @override
  Widget build(BuildContext context) {
    final asset = assetDoProduto(produto.codigo);
    final nomeCurto = nomeCardProduto(produto);
    final fundo = corDoProduto(produto.codigo).withValues(alpha: 0.22);
    final raio = BorderRadius.circular(AppSpacing.raioCard);

    return Material(
      color: AppColors.superficie,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: raio,
        side: const BorderSide(color: AppColors.linha),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: raio,
        excludeFromSemantics: true,
        onTap: () {
          HapticFeedback.selectionClick();
          onAbrir();
        },
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.superficie,
            borderRadius: raio,
            boxShadow: AppSombras.cardGrade,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ColoredBox(
                  color: fundo,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: asset == null
                        ? const ColoredBox(color: AppColors.aqua)
                        : Image.asset(
                            asset,
                            fit: BoxFit.contain,
                            alignment: Alignment.center,
                            cacheWidth: 400,
                            semanticLabel: nomeCurto,
                            errorBuilder: (_, _, _) => const ColoredBox(color: AppColors.aqua),
                          ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.xs, AppSpacing.sm, AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nomeCurto,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.headline.copyWith(color: AppColors.tinta),
                    ),
                    Text(
                      '${produto.volume} · ${produto.embalagem}',
                      style: AppTypography.caption1.copyWith(color: AppColors.textoSuave),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    if (quantidade > 0)
                      Align(
                        alignment: Alignment.centerRight,
                        child: StepperQuantidade(
                          quantidade: quantidade,
                          passo: passo,
                          rotulo: nomeCurto,
                          onAlterar: onAlterar,
                        ),
                      )
                    else
                      Align(
                        alignment: Alignment.centerRight,
                        child: Semantics(
                          button: true,
                          label: 'Adicionar $nomeCurto à assinatura',
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
                                final messenger = ScaffoldMessenger.maybeOf(context);
                                messenger
                                  ?..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    const SnackBar(
                                      content: Text('Adicionado à sacola'),
                                      behavior: SnackBarBehavior.floating,
                                      duration: Duration(milliseconds: 1600),
                                    ),
                                  );
                              },
                              child: const SizedBox(
                                width: AppSpacing.toqueMinimo,
                                height: AppSpacing.toqueMinimo,
                                child: Icon(Icons.add, color: AppColors.sobrePrimaria),
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
