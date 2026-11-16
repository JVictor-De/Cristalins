import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Carregando: indicador centralizado.
class Carregando extends StatelessWidget {
  const Carregando({super.key, this.mensagem});

  final String? mensagem;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.secaoGrande),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CupertinoActivityIndicator(radius: AppSpacing.sm),
            if (mensagem != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                mensagem!,
                textAlign: TextAlign.center,
                style: AppTypography.subheadline.copyWith(color: AppColors.textoSecundario),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Erro: ícone, mensagem e "Tentar de novo" (voz do Anexo).
class EstadoErro extends StatelessWidget {
  const EstadoErro({super.key, required this.mensagem, required this.onTentarDeNovo});

  final String mensagem;
  final VoidCallback onTentarDeNovo;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.secaoGrande),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_circle,
              size: AppSpacing.iconeEstadoVazio,
              color: AppColors.erro,
            ),
            const SizedBox(height: AppSpacing.margem),
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(color: AppColors.texto),
            ),
            const SizedBox(height: AppSpacing.margem),
            TextButton(
              onPressed: onTentarDeNovo,
              child: Text(
                'Tentar de novo',
                style: AppTypography.headline.copyWith(color: AppColors.azulMarca),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// SnackBar flutuante (tema: cantos 14 dp, subheadline, 4 s).
void mostrarAviso(BuildContext context, String mensagem, {bool erro = false}) {
  if (erro) {
    HapticFeedback.lightImpact();
  }
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(mensagem), duration: const Duration(seconds: 4)));
}
