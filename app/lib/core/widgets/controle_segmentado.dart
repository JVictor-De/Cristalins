import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// `CupertinoSlidingSegmentedControl` com segmentos de pelo menos 48 dp (Android) e háptica.
class ControleSegmentado<T extends Object> extends StatelessWidget {
  const ControleSegmentado({
    super.key,
    required this.opcoes,
    required this.valor,
    required this.onEscolher,
  });

  /// valor → rótulo, na ordem de exibição.
  final Map<T, String> opcoes;
  final T valor;
  final ValueChanged<T> onEscolher;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: CupertinoSlidingSegmentedControl<T>(
        groupValue: valor,
        children: {
          for (final e in opcoes.entries)
            e.key: ConstrainedBox(
              // Área de toque de 48 dp (Android), maior que os 44 pt do iOS.
              constraints: const BoxConstraints(minHeight: AppSpacing.toqueMinimo),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.xxs,
                    horizontal: AppSpacing.xxs,
                  ),
                  child: Text(
                    e.value,
                    textAlign: TextAlign.center,
                    style: AppTypography.subheadline.copyWith(color: AppColors.texto),
                  ),
                ),
              ),
            ),
        },
        onValueChanged: (v) {
          if (v == null) return;
          HapticFeedback.selectionClick();
          onEscolher(v);
        },
      ),
    );
  }
}
