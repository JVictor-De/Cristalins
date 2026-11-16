import 'package:flutter/material.dart';

import '../marca_assets.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'botao_principal.dart';

/// Aba Assinatura sem plano ativo — centrada, ≤2 CTAs primários + quiz terciário.
class EmptyAssinatura extends StatelessWidget {
  const EmptyAssinatura({
    super.key,
    required this.onMontarSacola,
    required this.onVerAguas,
    this.onQuiz,
  });

  final VoidCallback onMontarSacola;
  final VoidCallback onVerAguas;
  final VoidCallback? onQuiz;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.margem),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - AppSpacing.margem * 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.raioCard),
                    child: ColoredBox(
                      color: AppColors.aqua.withValues(alpha: 0.45),
                      child: SizedBox(
                        height: 120,
                        width: double.infinity,
                        child: Image.asset(
                          assetProdutoAguaMineral,
                          fit: BoxFit.contain,
                          semanticLabel: 'Água mineral Cristalins',
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.water_drop_outlined,
                            size: 64,
                            color: AppColors.azulMarca,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.margem),
                  Text(
                    'Você ainda não tem assinatura',
                    style: AppTypography.title3.copyWith(color: AppColors.navy),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Receba águas e Water Protein na frequência que escolher — pagamento com Pix.',
                    style: AppTypography.subheadline.copyWith(color: AppColors.textoSuave),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.secao),
                  BotaoPrincipal(rotulo: 'Montar sacola', onPressed: onMontarSacola),
                  const SizedBox(height: AppSpacing.sm),
                  BotaoPrincipal(
                    rotulo: 'Ver águas',
                    onPressed: onVerAguas,
                    variante: VarianteBotaoPrincipal.contorno,
                  ),
                  if (onQuiz != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed: onQuiz,
                      child: Text(
                        'Descobrir meu kit',
                        style: AppTypography.subheadline.copyWith(color: AppColors.azulMarca),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
