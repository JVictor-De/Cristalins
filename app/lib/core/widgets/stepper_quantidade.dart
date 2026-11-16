import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Stepper em caixas (≥ 48 dp) para PDP / sacola. Passo = embalagem.
class StepperQuantidade extends StatelessWidget {
  const StepperQuantidade({
    super.key,
    required this.quantidade,
    required this.passo,
    required this.onAlterar,
    required this.rotulo,
  });

  final int quantidade;
  final int passo;
  final ValueChanged<int> onAlterar;
  final String rotulo;

  @override
  Widget build(BuildContext context) {
    final podeDiminuir = quantidade - passo >= 0 && quantidade > 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Caixa(
          icone: CupertinoIcons.minus,
          label: 'Diminuir $rotulo',
          enabled: podeDiminuir,
          onTap: podeDiminuir
              ? () {
                  HapticFeedback.selectionClick();
                  onAlterar(quantidade - passo);
                }
              : null,
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: AppSpacing.toqueMinimo),
          child: Semantics(
            label: '$quantidade unidades de $rotulo',
            excludeSemantics: true,
            child: Text(
              '$quantidade',
              textAlign: TextAlign.center,
              style: AppTypography.headline.copyWith(
                color: AppColors.tinta,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
        _Caixa(
          icone: CupertinoIcons.plus,
          label: 'Aumentar $rotulo',
          enabled: true,
          onTap: () {
            HapticFeedback.selectionClick();
            onAlterar(quantidade + passo);
          },
        ),
      ],
    );
  }
}

class _Caixa extends StatelessWidget {
  const _Caixa({
    required this.icone,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final IconData icone;
  final String label;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: AppColors.gelo,
        borderRadius: BorderRadius.circular(AppSpacing.raioBotao),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.raioBotao),
          onTap: onTap,
          child: SizedBox(
            width: AppSpacing.toqueMinimo,
            height: AppSpacing.toqueMinimo,
            child: Center(
              child: Icon(
                icone,
                size: 18,
                color: enabled ? AppColors.navy : AppColors.textoSuave,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
