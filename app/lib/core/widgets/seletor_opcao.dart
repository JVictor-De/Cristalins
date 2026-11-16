import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Segmento horizontal de opções (frequência / plano). Uma seleção.
class SeletorOpcao extends StatelessWidget {
  const SeletorOpcao({
    super.key,
    required this.opcoes,
    required this.selecionado,
    required this.onChanged,
  });

  final List<String> opcoes;
  final String selecionado;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final o in opcoes)
          Semantics(
            button: true,
            selected: o == selecionado,
            label: o,
            child: Material(
              color: o == selecionado ? AppColors.menta : AppColors.gelo,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.raioBotao),
                side: BorderSide(
                  color: o == selecionado ? AppColors.azulMarca : AppColors.linha,
                  width: o == selecionado ? 1.5 : 1,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppSpacing.raioBotao),
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(o);
                },
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: AppSpacing.toqueMinimo),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    child: Center(
                      child: Text(
                        o,
                        style: AppTypography.subheadline.copyWith(
                          color: AppColors.tinta,
                          fontWeight: o == selecionado ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
