import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Variantes do CTA marketplace (raio 16). Primária = [AppColors.azulMarca].
/// [cta] = CTA principal de compra do redesign P2 (`heroNavy` `#063A52`, raio 14).
enum VarianteBotaoPrincipal { primaria, navy, contorno, cta }

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
    final desabilitado = onPressed == null && !carregando && variante != VarianteBotaoPrincipal.contorno;
    final (fundoBase, frenteBase, borda) = switch (variante) {
      VarianteBotaoPrincipal.primaria => (
        AppColors.azulMarca,
        AppColors.sobrePrimaria,
        null as Color?,
      ),
      VarianteBotaoPrincipal.navy => (AppColors.navy, AppColors.sobrePrimaria, null),
      VarianteBotaoPrincipal.contorno => (AppColors.superficie, AppColors.navy, AppColors.navy),
      VarianteBotaoPrincipal.cta => (AppColors.heroNavy, AppColors.sobrePrimaria, null),
    };
    // P3.1: desabilitado legível (heroInk sobre `linha` ≈ 11:1) em vez de branco a 40%.
    final fundo = desabilitado ? AppColors.linha : fundoBase;
    final frente = desabilitado ? AppColors.heroInk : frenteBase;
    final raio = BorderRadius.circular(
      variante == VarianteBotaoPrincipal.cta ? AppSpacing.raioCta : AppSpacing.raioBotao,
    );

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
      // Altura mínima (não fixa): com fonte a 200% o rótulo quebra sem cortar.
      child: SizedBox(
        width: expandido ? double.infinity : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSpacing.alturaBotao),
          child: Material(
            color: habilitado || desabilitado ? fundo : fundo.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(
              borderRadius: raio,
              side: borda == null ? BorderSide.none : BorderSide(color: borda),
            ),
            child: InkWell(
              borderRadius: raio,
              onTap: habilitado ? onPressed : null,
              child: Center(
                heightFactor: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.margem,
                    vertical: AppSpacing.xs,
                  ),
                  child: filho,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
