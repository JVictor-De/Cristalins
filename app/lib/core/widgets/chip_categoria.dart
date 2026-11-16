import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Chip de filtro de categoria (Todos · WP · Fiber · Águas · Kits).
class ChipCategoria extends StatelessWidget {
  const ChipCategoria({
    super.key,
    required this.rotulo,
    required this.selecionado,
    required this.onTap,
  });

  final String rotulo;
  final bool selecionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selecionado,
      label: rotulo,
      child: Material(
        color: selecionado ? AppColors.navy : AppColors.superficie,
        shape: StadiumBorder(
          side: BorderSide(
            color: selecionado ? AppColors.navy : AppColors.azulPetroleo.withValues(alpha: 0.55),
            width: selecionado ? 1 : 1.25,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSpacing.toqueMinimo),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              child: Center(
                child: Text(
                  rotulo,
                  style: AppTypography.subheadline.copyWith(
                    color: selecionado ? AppColors.sobrePrimaria : AppColors.navy,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
