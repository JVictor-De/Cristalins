import 'package:flutter/material.dart';

import '../formatacao.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_sombras.dart';
import '../theme/app_typography.dart';
import 'botao_principal.dart';

/// Card compacto da próxima entrega (assinante).
class CardProximaEntrega extends StatelessWidget {
  const CardProximaEntrega({
    super.key,
    required this.dataEntrega,
    this.janela,
    this.status,
    this.onEditarSacola,
  });

  final String dataEntrega;
  final String? janela;
  final String? status;
  final VoidCallback? onEditarSacola;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.margem),
      padding: const EdgeInsets.all(AppSpacing.margem),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(AppSpacing.raioCard),
        boxShadow: AppSombras.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Próxima entrega', style: AppTypography.headline.copyWith(color: AppColors.navy)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            Datas.comDiaDaSemana(dataEntrega),
            style: AppTypography.title3.copyWith(color: AppColors.tinta),
          ),
          if (janela != null)
            Text(
              'Janela: $janela',
              style: AppTypography.footnote.copyWith(color: AppColors.textoSuave),
            ),
          if (status != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(status!, style: AppTypography.caption1.copyWith(color: AppColors.azulMarca)),
          ],
          if (onEditarSacola != null) ...[
            const SizedBox(height: AppSpacing.sm),
            BotaoPrincipal(
              rotulo: 'Alterar sacola',
              onPressed: onEditarSacola,
              variante: VarianteBotaoPrincipal.contorno,
              expandido: false,
            ),
          ],
        ],
      ),
    );
  }
}