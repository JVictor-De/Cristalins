import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Variantes do CTA marketplace (raio 16). Primária = [AppColors.azulMarca].
enum VarianteBotaoPrincipal { primaria, navy, contorno }

/// Botão principal full-width (ou intrínseco). Contraste: branco peso ≥ 600 sobre
/// [AppColors.azulMarca] ≈ 4,51 AA (docs/DECISOES.md).
class BotaoPrincipal extends StatelessWidget {
  const BotaoPrincipal({
    super.key,
    required this.rotulo,
    required this.onPressed,
    this.carregando = false,
    this.variante = VarianteBotaoPrincipal.primaria,
    this.expandido = true,
  });

  final String rotulo;
  final VoidCallback? onPressed;
  final bool carregando;
  final VarianteBotaoPrincipal variante;
  final bool expandido;

  @override
  Widget build(BuildContext context) {
    final habilitado = onPressed != null && !carregando;
    final (fundo, frente, borda) = switch (variante) {
      VarianteBotaoPrincipal.primaria => (
        AppColors.azulMarca,
        AppColors.sobrePrimaria,
        null as Color?,
      ),
      VarianteBotaoPrincipal.navy => (AppColors.navy, AppColors.sobrePrimaria, null),
      VarianteBotaoPrincipal.contorno => (AppColors.superficie, AppColors.tinta, AppColors.linha),
    };

    final filho = carregando
        ? CupertinoActivityIndicator(color: frente)
        : Text(
            rotulo,
            textAlign: TextAlign.center,
            style: AppTypography.headline.copyWith(color: frente, fontWeight: FontWeight.w600),
          );

    return Semantics(
      button: true,
      enabled: habilitado,
      label: rotulo,
      excludeSemantics: true,
      child: SizedBox(
        width: expandido ? double.infinity : null,
        height: AppSpacing.alturaBotao,
        child: Material(
          color: habilitado ? fundo : fundo.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.raioBotao),
            side: borda == null ? BorderSide.none : BorderSide(color: borda),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.raioBotao),
            onTap: habilitado ? onPressed : null,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margem),
                child: filho,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
