import 'package:flutter/cupertino.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Estado vazio: ícone, uma frase e (opcional) uma ação de texto.
class EstadoVazio extends StatelessWidget {
  const EstadoVazio({
    super.key,
    required this.icone,
    required this.mensagem,
    this.rotuloAcao,
    this.onAcao,
  });

  final IconData icone;
  final String mensagem;
  final String? rotuloAcao;
  final VoidCallback? onAcao;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.secaoGrande),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: AppSpacing.iconeEstadoVazio, color: AppColors.textoSecundario),
            const SizedBox(height: AppSpacing.margem),
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(color: AppColors.textoSecundario),
            ),
            if (rotuloAcao != null && onAcao != null) ...[
              const SizedBox(height: AppSpacing.xs),
              CupertinoButton(
                minimumSize: const Size(AppSpacing.toqueMinimo, AppSpacing.toqueMinimo),
                onPressed: onAcao,
                child: Text(
                  rotuloAcao!,
                  style: AppTypography.headline.copyWith(color: AppColors.linkSobreFundoAgrupado),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
