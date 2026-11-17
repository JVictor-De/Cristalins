import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show FontWeight, InkWell, Material;
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Controle de escolha única (frequência, plano, login/cadastro).
///
/// No app nativo usa `CupertinoSlidingSegmentedControl`. No Flutter Web (Safari iOS
/// em especial) o gesto de arrastar do Cupertino perde para o scroll pai — então
/// usamos segmentos com toque simples (`InkWell`).
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

  void _escolher(T v) {
    if (v == valor) return;
    HapticFeedback.selectionClick();
    onEscolher(v);
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return _SegmentosWeb<T>(opcoes: opcoes, valor: valor, onEscolher: _escolher);
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
          _escolher(v);
        },
      ),
    );
  }
}

/// Segmentos tocáveis para web: sem gesto de slide, só tap — confiável no Safari iOS.
class _SegmentosWeb<T extends Object> extends StatelessWidget {
  const _SegmentosWeb({required this.opcoes, required this.valor, required this.onEscolher});

  final Map<T, String> opcoes;
  final T valor;
  final ValueChanged<T> onEscolher;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.indicadorAba,
        borderRadius: BorderRadius.circular(AppSpacing.raioCelula),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxs),
        child: Row(
          children: [
            for (final e in opcoes.entries)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: e.key == valor,
                  inMutuallyExclusiveGroup: true,
                  label: e.value,
                  child: Material(
                    color: e.key == valor ? AppColors.superficie : const Color(0x00000000),
                    elevation: 0,
                    borderRadius: BorderRadius.circular(AppSpacing.raioCelula - 2),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppSpacing.raioCelula - 2),
                      onTap: () => onEscolher(e.key),
                      child: ConstrainedBox(
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
                              style: AppTypography.subheadline.copyWith(
                                color: AppColors.texto,
                                fontWeight: e.key == valor ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
