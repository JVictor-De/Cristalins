import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/catalog/presentation/sacola_controller.dart';
import '../routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'sugestao_minimo_cesta.dart';

/// Barra fina acima da tab bar. Lê [SacolaController]; preço só da simulação API.
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
        child: SafeArea(
          top: false,
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
                      child: Text(
                        sim == null
                            ? '${sacola.totalItens} ${sacola.totalItens == 1 ? 'item' : 'itens'}'
                            : '${sim.total.formatado}/entrega · ${sacola.totalItens} ${sacola.totalItens == 1 ? 'item' : 'itens'}',
                        style: AppTypography.subheadline.copyWith(
                          color: AppColors.tinta,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pushNamed(AppRoutes.sacola),
                      child: Text(
                        'Ver sacola',
                        style: AppTypography.subheadline.copyWith(
                          color: AppColors.azulMarca,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
