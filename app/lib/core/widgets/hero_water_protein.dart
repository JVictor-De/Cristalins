import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../formatacao.dart';
import '../marca_assets.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'botao_principal.dart';

/// Hero único da home visitante (compacto).
/// Tipografia Inter no título; imagem = foto de produto (sem print de landing).
class HeroWaterProtein extends StatelessWidget {
  const HeroWaterProtein({
    super.key,
    required this.onAssinar,
    required this.onVerAguas,
    this.mostrarVerAguas = true,
    this.precoAPartirDe,
  });

  final VoidCallback onAssinar;
  final VoidCallback onVerAguas;

  /// Só exibe o link se houver ≥1 produto em [Categoria.aguas].
  final bool mostrarVerAguas;

  /// Exceção vs cards sem preço: `precoBase` do WP500 da API.
  final Dinheiro? precoAPartirDe;

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height * 0.30;
    final altura = h.clamp(210.0, 280.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.raioCard),
      child: SizedBox(
        height: altura,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.lima, AppColors.verdeProtein],
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 11,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.margem,
                    AppSpacing.sm,
                    AppSpacing.xs,
                    AppSpacing.sm,
                  ),
                  child: LayoutBuilder(
                    builder: (context, c) {
                      return SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: c.maxHeight),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.navy,
                                  borderRadius: BorderRadius.circular(AppSpacing.raioChip),
                                ),
                                child: Text(
                                  'Mais vendido',
                                  style: AppTypography.caption2.copyWith(
                                    color: AppColors.sobrePrimaria,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                'Water Protein',
                                style: AppTypography.title2.copyWith(
                                  color: AppColors.navy,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                '5 g de proteína por garrafa · 0 açúcar · 0 gordura',
                                style: AppTypography.caption1.copyWith(
                                  color: AppColors.navy,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (precoAPartirDe != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'a partir de ${precoAPartirDe!.formatado}/un.',
                                  style: AppTypography.subheadline.copyWith(
                                    color: AppColors.navy,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                              const SizedBox(height: AppSpacing.sm),
                              BotaoPrincipal(
                                rotulo: 'Assinar Water Protein',
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  onAssinar();
                                },
                                variante: VarianteBotaoPrincipal.navy,
                              ),
                              if (mostrarVerAguas)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                      minimumSize: const Size(0, 40),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      alignment: Alignment.centerLeft,
                                    ),
                                    onPressed: () {
                                      HapticFeedback.selectionClick();
                                      onVerAguas();
                                    },
                                    child: Text(
                                      'Ver todas as águas',
                                      style: AppTypography.subheadline.copyWith(
                                        color: AppColors.navy,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Expanded(
                flex: 9,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, AppSpacing.xs, AppSpacing.sm, 0),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Transform.translate(
                      offset: const Offset(0, 8),
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Color.fromRGBO(7, 59, 83, 0.28),
                              blurRadius: 28,
                              offset: Offset(0, 14),
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          assetProdutoWaterProtein,
                          height: altura * 0.95,
                          fit: BoxFit.contain,
                          alignment: Alignment.bottomCenter,
                          cacheWidth: 700,
                          semanticLabel: 'Garrafa Water Protein',
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.water_drop_outlined,
                            size: 72,
                            color: AppColors.navy,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
