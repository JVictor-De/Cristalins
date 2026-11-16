import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'botao_principal.dart';

/// Aba Assinatura sem plano ativo — seco, dois botões.
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
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.margem),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.secao),
          Text(
            'Você ainda não tem assinatura',
            style: AppTypography.title3.copyWith(color: AppColors.navy),
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
            const SizedBox(height: AppSpacing.margem),
            Center(
              child: TextButton(
                onPressed: onQuiz,
                child: Text(
                  'Descobrir meu kit',
                  style: AppTypography.subheadline.copyWith(color: AppColors.azulMarca),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}