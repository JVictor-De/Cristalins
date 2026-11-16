import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../marca_assets.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'botao_principal.dart';

/// Hero único da home visitante (≤ ~32% da altura).
/// Tipografia só no widget; imagem = foto de produto (sem print de landing).
class HeroWaterProtein extends StatelessWidget {
  const HeroWaterProtein({
    super.key,
    required this.onAssinar,
    required this.onVerAguas,
  });

  final VoidCallback onAssinar;
  final VoidCallback onVerAguas;

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height * 0.32;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.raioCard),
      child: SizedBox(
        height: h.clamp(200, 300),
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
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: c.maxHeight),
                          child: IntrinsicHeight(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.navy,
                                    borderRadius: BorderRadius.circular(AppSpacing.raioChip),
                                  ),
                                  child: Text(
                                    'Carro-chefe',
                                    style: AppTypography.caption2.copyWith(
                                      color: AppColors.sobrePrimaria,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xxs),
                                Text(
                                  'Water Protein',
                                  style: AppTypography.heroTitle.copyWith(
                                    color: AppColors.navy,
                                    fontSize: 26,
                                    height: 1.1,
                                  ),
                                ),
                                Text(
                                  '5 g · 0 açúcares e gorduras',
                                  style: AppTypography.caption1.copyWith(color: AppColors.navy),
                                ),
                                const Spacer(),
                                BotaoPrincipal(
                                  rotulo: 'Assinar Water Protein',
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    onAssinar();
                                  },
                                  variante: VarianteBotaoPrincipal.navy,
                                ),
                                Align(
                                  alignment: Alignment.center,
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                      minimumSize: const Size(0, 40),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      padding: const EdgeInsets.symmetric(vertical: 4),
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
                        ),
                      );
                    },
                  ),
                ),
              ),
              Expanded(
                flex: 9,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
                  child: Image.asset(
                    assetProdutoWaterProtein,
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomCenter,
                    cacheWidth: 600,
                    semanticLabel: 'Garrafa Water Protein',
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.water_drop_outlined,
                      size: 72,
                      color: AppColors.navy,
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
