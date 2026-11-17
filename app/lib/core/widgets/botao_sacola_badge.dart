import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Ícone de sacola 48 dp com contador (Home e Produtos). Contador = `SacolaController.totalItens`.
class BotaoSacolaBadge extends StatelessWidget {
  const BotaoSacolaBadge({super.key, required this.totalItens, required this.onTap});

  final int totalItens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: totalItens == 0
          ? 'Abrir sacola'
          : 'Abrir sacola, $totalItens ${totalItens == 1 ? 'item' : 'itens'}',
      excludeSemantics: true,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(AppSpacing.raioChip),
        child: SizedBox(
          width: AppSpacing.toqueMinimo,
          height: AppSpacing.toqueMinimo,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              const Icon(Icons.shopping_bag_outlined, color: AppColors.navy),
              if (totalItens > 0)
                Positioned(
                  right: 2,
                  top: 2,
                  // P0.3: “pop” do badge a cada mudança de contador (reduzir movimento = sem anim).
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey('badge-sacola-$totalItens'),
                    tween: Tween(begin: 1.3, end: 1),
                    duration: (MediaQuery.maybeDisableAnimationsOf(context) ?? false)
                        ? Duration.zero
                        : AppDurations.etapa,
                    curve: Curves.easeOutBack,
                    builder: (_, s, child) => Transform.scale(scale: s, child: child),
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: AppColors.promo,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        totalItens > 99 ? '99+' : '$totalItens',
                        textAlign: TextAlign.center,
                        style: AppTypography.caption2.copyWith(
                          color: AppColors.sobrePrimaria,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
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
