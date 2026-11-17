import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/catalog/domain/sacola_copy.dart';
import '../../features/catalog/presentation/sacola_controller.dart';
import '../routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'botao_principal.dart';
import 'sugestao_minimo_cesta.dart';

/// Barra fina acima da tab bar. Lê [SacolaController]; preço só da simulação API.
/// Total = mesma fonte da Sacola: [Simulacao.total] / [Dinheiro.formatado] via [SacolaCopy].
class BarraSacola extends StatelessWidget {
  const BarraSacola({super.key});

  @override
  Widget build(BuildContext context) {
    final sacola = context.watch<SacolaController>();
    if (!sacola.temItens) return const SizedBox.shrink();

    final sim = sacola.simulacao;
    final abaixo = sim?.abaixoDoMinimo ?? false;
    final progresso = sim == null || sim.ueMinima <= 0
        ? null
        : (sim.ue / sim.ueMinima).clamp(0.0, 1.0).toDouble();
    final n = sacola.totalItens;
    final itensLabel = SacolaCopy.itens(n);
    final freteHint = sim == null ? null : SacolaCopy.faltaFreteGratis(sim);

    return Material(
      color: AppColors.superficie,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.superficie,
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(7, 59, 83, 0.12),
              offset: Offset(0, -4),
              blurRadius: 16,
            ),
          ],
          border: Border(top: BorderSide(color: AppColors.linha)),
        ),
        // bottom: false — a barra fica acima da NavigationBar; o inset do
        // home indicator já vem da tab bar (Safari iOS / notch).
        child: SafeArea(
          top: false,
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.margem,
              AppSpacing.xs,
              AppSpacing.margem,
              AppSpacing.xs,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (abaixo) ...[
                  Text(
                    'Falta um pouco para o mínimo da assinatura',
                    style: AppTypography.caption1.copyWith(color: AppColors.textoSuave),
                  ),
                  if (progresso != null) ...[
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.raioChip),
                      child: LinearProgressIndicator(
                        value: progresso,
                        minHeight: 4,
                        backgroundColor: AppColors.gelo,
                        color: AppColors.azulMarca,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  const SugestaoMinimoCesta(),
                  const SizedBox(height: AppSpacing.xs),
                ],
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (sim == null)
                            Text(
                              itensLabel,
                              style: AppTypography.subheadline.copyWith(
                                color: AppColors.tinta,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          else
                            Text.rich(
                              TextSpan(
                                style: AppTypography.subheadline.copyWith(color: AppColors.tinta),
                                children: [
                                  TextSpan(text: '${SacolaCopy.itens(n)} · '),
                                  TextSpan(
                                    text: sim.total.formatado,
                                    style: const TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                  const TextSpan(text: ' por entrega'),
                                ],
                              ),
                            ),
                          // P1.4: falta para frete grátis (valor da simulação, RN18).
                          if (freteHint != null && !abaixo)
                            Text(
                              freteHint,
                              key: const ValueKey('barra-sacola-frete'),
                              style: AppTypography.footnote.copyWith(color: AppColors.textoSuave),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    BotaoPrincipal(
                      rotulo: 'Ver sacola',
                      expandido: false,
                      variante: VarianteBotaoPrincipal.navy,
                      onPressed: () => Navigator.of(context).pushNamed(AppRoutes.sacola),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
