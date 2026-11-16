import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Bloco com título + ação opcional (“Ver todos”) + conteúdo.
class SecaoComTitulo extends StatelessWidget {
  const SecaoComTitulo({
    super.key,
    required this.titulo,
    required this.child,
    this.acaoRotulo,
    this.onAcao,
    this.subtitulo,
  });

  final String titulo;
  final String? subtitulo;
  final Widget child;
  final String? acaoRotulo;
  final VoidCallback? onAcao;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margem),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: AppTypography.title3.copyWith(color: AppColors.navy)),
                    if (subtitulo != null) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(subtitulo!, style: AppTypography.footnote.copyWith(color: AppColors.textoSuave)),
                    ],
                  ],
                ),
              ),
              if (acaoRotulo != null && onAcao != null)
                TextButton(
                  onPressed: onAcao,
                  child: Text(
                    acaoRotulo!,
                    style: AppTypography.subheadline.copyWith(
                      color: AppColors.azulMarca,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    );
  }
}
