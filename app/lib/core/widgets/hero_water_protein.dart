import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../marca_assets.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'botao_principal.dart';

/// Hero único da home visitante (≤ ~32% da altura).
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
        height: h.clamp(180, 280),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.lima, AppColors.verdeProtein],
                ),
              ),
            ),
            Positioned(
              right: -20,
              bottom: -10,
              top: 8,
              width: MediaQuery.sizeOf(context).width * 0.48,
              child: Image.asset(
                assetHeroFlowProtein,
                fit: BoxFit.contain,
                alignment: Alignment.bottomCenter,
                cacheWidth: 800,
                semanticLabel: 'Water Protein com colágeno',
                errorBuilder: (_, _, _) => Image.asset(
                  'assets/images/produtos/protein.webp',
                  fit: BoxFit.contain,
                  semanticLabel: 'Water Protein',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.margem, AppSpacing.sm, AppSpacing.margem, AppSpacing.xs),
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
                      style: AppTypography.caption2.copyWith(color: AppColors.sobrePrimaria),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Water Protein',
                    style: AppTypography.heroTitle.copyWith(color: AppColors.navy, fontSize: 28, height: 1.1),
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
          ],
        ),
      ),
    );
  }
}
