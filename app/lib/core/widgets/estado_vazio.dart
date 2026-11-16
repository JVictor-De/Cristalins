import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'botao_principal.dart';

/// Estado vazio: ícone + mensagem (legado) ou título/subtítulo + CTA (marketplace).
/// Empty de catálogo: CTA sempre link ([TextButton]); nunca filled salvo [ctaPrimario].
class EstadoVazio extends StatelessWidget {
  const EstadoVazio({
    super.key,
    this.icone = Icons.inventory_2_outlined,
    this.mensagem,
    this.titulo,
    this.subtitulo,
    this.rotuloAcao,
    this.onAcao,
    this.ctaPrimario = false,
  }) : assert(
         mensagem != null || titulo != null,
         'Informe mensagem (legado) ou titulo (marketplace).',
       );

  final IconData icone;

  /// API legada (faturas / minha assinatura).
  final String? mensagem;

  /// API marketplace (catálogo / filtro / assinatura tab).
  final String? titulo;
  final String? subtitulo;

  final String? rotuloAcao;
  final VoidCallback? onAcao;

  /// Se true, usa [BotaoPrincipal]; senão, TextButton / Cupertino (sem filled).
  final bool ctaPrimario;

  @override
  Widget build(BuildContext context) {
    final rich = titulo != null;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.secao),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icone,
            size: AppSpacing.iconeEstadoVazio,
            color: rich ? AppColors.azulMarca : AppColors.textoSecundario,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (rich) ...[
            Text(
              titulo!,
              textAlign: TextAlign.center,
              style: AppTypography.title3.copyWith(color: AppColors.navy),
            ),
            if (subtitulo != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitulo!,
                textAlign: TextAlign.center,
                style: AppTypography.subheadline.copyWith(color: AppColors.textoSuave),
              ),
            ],
          ] else
            Text(
              mensagem!,
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(color: AppColors.textoSecundario),
            ),
          if (rotuloAcao != null && onAcao != null) ...[
            const SizedBox(height: AppSpacing.sm),
            if (ctaPrimario)
              BotaoPrincipal(rotulo: rotuloAcao!, onPressed: onAcao)
            else if (rich)
              TextButton(
                onPressed: onAcao,
                child: Text(
                  rotuloAcao!,
                  style: AppTypography.headline.copyWith(color: AppColors.azulMarca),
                ),
              )
            else
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
    );
  }
}
