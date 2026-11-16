import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Placeholder gelo (sem spinner solto). Estático para goldens estáveis.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({
    super.key,
    this.altura = 120,
    this.largura,
  });

  final double altura;
  final double? largura;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Carregando',
      child: Container(
        width: largura,
        height: altura,
        decoration: BoxDecoration(
          color: AppColors.gelo,
          borderRadius: BorderRadius.circular(AppSpacing.raioCard),
          border: Border.all(color: AppColors.linha),
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: 36,
            margin: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.menta,
              borderRadius: BorderRadius.circular(AppSpacing.raioBotao),
            ),
          ),
        ),
      ),
    );
  }
}
