import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../features/catalog/domain/catalogo.dart';
import '../../features/catalog/domain/produto_assets.dart';
import '../../features/catalog/presentation/sacola_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// CTA concreto para fechar o mínimo (sem expor UE). Nunca força só Water Protein.
class SugestaoMinimoCesta extends StatelessWidget {
  const SugestaoMinimoCesta({super.key, this.produto});

  /// Override opcional; senão usa [SacolaController.sugerirParaMinimo].
  final Produto? produto;

  @override
  Widget build(BuildContext context) {
    final sacola = context.watch<SacolaController>();
    final p = produto ?? sacola.sugerirParaMinimo();
    if (p == null) {
      return Text(
        'Adicione mais itens em Produtos',
        style: AppTypography.footnote.copyWith(color: AppColors.textoSuave),
      );
    }

    final curto = nomeCardProduto(p);
    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        button: true,
        label: 'Adicionar ${p.nome}, ${p.pack}, à assinatura',
        excludeSemantics: true,
        child: TextButton.icon(
          style: TextButton.styleFrom(
            minimumSize: const Size(0, AppSpacing.toqueMinimo),
            foregroundColor: AppColors.azulMarca,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            sacola.adicionarPasso(p);
          },
          icon: const Icon(Icons.add_circle_outline, color: AppColors.azulMarca),
          label: Text(
            'Adicionar $curto (${p.pack})',
            style: AppTypography.subheadline.copyWith(
              color: AppColors.azulMarca,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
