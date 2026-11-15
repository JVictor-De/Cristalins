import 'package:flutter/cupertino.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Botão principal em cápsula, largura total (uma ação principal por tela).
/// `onPressed` nulo = desabilitado (40% de opacidade); [carregando] troca o texto pelo indicador.
class BotaoPrincipal extends StatelessWidget {
  const BotaoPrincipal({
    super.key,
    required this.rotulo,
    required this.onPressed,
    this.carregando = false,
  });

  final String rotulo;
  final VoidCallback? onPressed;
  final bool carregando;

  @override
  Widget build(BuildContext context) {
    final habilitado = onPressed != null && !carregando;
    return Semantics(
      button: true,
      enabled: habilitado,
      label: rotulo,
      excludeSemantics: true,
      child: SizedBox(
        width: double.infinity,
        child: CupertinoButton.filled(
          minimumSize: const Size(AppSpacing.toqueMinimo, AppSpacing.alturaBotao),
          borderRadius: BorderRadius.circular(AppSpacing.raioBotao),
          disabledColor: AppColors.azul800.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.margem,
            vertical: AppSpacing.sm,
          ),
          onPressed: habilitado ? onPressed : null,
          child: carregando
              ? const CupertinoActivityIndicator(color: AppColors.sobrePrimaria)
              : Text(
                  rotulo,
                  textAlign: TextAlign.center,
                  style: AppTypography.headline.copyWith(color: AppColors.sobrePrimaria),
                ),
        ),
      ),
    );
  }
}
