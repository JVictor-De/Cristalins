import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../features/catalog/domain/produto_assets.dart';
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
    this.codigosItens = const [],
  });

  final String nome;
  final String resumoItens;
  final VoidCallback onTap;
  final VoidCallback onAdicionar;

  /// Códigos dos produtos do kit (miniaturas PNG).
  final List<String> codigosItens;

  @override
  Widget build(BuildContext context) {
    final minis = <String>[
      for (final c in codigosItens)
        if (assetDoProduto(c) case final path?) path,
    ].take(4).toList();

    return Material(
      color: AppColors.superficie,
      borderRadius: BorderRadius.circular(AppSpacing.raioCard),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.raioCard),
        onTap: onTap,
        child: Container(
          width: 220,
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.raioCard),
            boxShadow: AppSombras.cardGrade,
            color: AppColors.superficie,
            border: Border.all(color: AppColors.linha),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (minis.isNotEmpty) ...[
                SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      for (var i = 0; i < minis.length; i++) ...[
                        if (i > 0) const SizedBox(width: 4),
                        Expanded(
                          child: ColoredBox(
                            color: AppColors.gelo,
                            child: Image.asset(
                              minis[i],
                              fit: BoxFit.contain,
                              cacheWidth: 160,
                              semanticLabel: 'Item do kit $nome',
                              errorBuilder: (_, _, _) => const ColoredBox(color: AppColors.aqua),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
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
              const SizedBox(height: AppSpacing.xs),
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
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
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
