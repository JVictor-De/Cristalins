import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_sombras.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Card de kit **sem preço** (subtotalBase não é exibido — preço só via simulação).
class CardKit extends StatelessWidget {
  const CardKit({
    super.key,
    required this.nome,
    required this.resumoItens,
    required this.onTap,
    required this.onAdicionar,
  });

  final String nome;
  final String resumoItens;
  final VoidCallback onTap;
  final VoidCallback onAdicionar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.superficie,
      borderRadius: BorderRadius.circular(AppSpacing.raioCard),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.raioCard),
        onTap: onTap,
        child: Container(
          width: 220,
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.raioCard),
            boxShadow: AppSombras.card,
            color: AppColors.superficie,
            border: Border.all(color: AppColors.linha),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nome,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.headline.copyWith(color: AppColors.navy),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                resumoItens,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption1.copyWith(color: AppColors.textoSuave),
              ),
              const Spacer(),
              Align(
                alignment: Alignment.centerRight,
                child: Semantics(
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
                    constraints: const BoxConstraints(
                      minWidth: AppSpacing.toqueMinimo,
                      minHeight: AppSpacing.toqueMinimo,
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
