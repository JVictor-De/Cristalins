import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Badge pontual (Novo / Carro-chefe / contador). Fundo [AppColors.promo] ou lima.
class SeloPromo extends StatelessWidget {
  const SeloPromo({
    super.key,
    required this.texto,
    this.fundo = AppColors.promo,
    this.frente = AppColors.sobrePrimaria,
  });

  final String texto;
  final Color fundo;
  final Color frente;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(AppSpacing.raioChip),
      ),
      child: Text(
        texto,
        semanticsLabel: texto,
        style: AppTypography.caption2.copyWith(color: frente, fontWeight: FontWeight.w700),
      ),
    );
  }
}
