import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/marca_assets.dart';
import '../../../core/routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../catalog/domain/catalogo.dart';
import '../../shell/presentation/shell_screen.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/botao_principal.dart';
import '../data/onboarding_prefs.dart';

/// 1ª abertura: 3 CTAs + Pular.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  Future<void> _marcarEIr(BuildContext context, String rota, {Object? args}) async {
    HapticFeedback.lightImpact();
    await OnboardingPrefs.marcarVisto();
    if (!context.mounted) return;
    Navigator.of(context).pushReplacementNamed(rota, arguments: args);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(assetHeroAguaBokeh, fit: BoxFit.cover, semanticLabel: 'Água Cristalins'),
          Container(color: Colors.black.withValues(alpha: 0.25)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.margem),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: TextButton(
                      onPressed: () => _marcarEIr(context, AppRoutes.shell),
                      child: Text('Pular', style: AppTypography.headline.copyWith(color: Colors.white)),
                    ),
                  ),
                  const Spacer(),
                  Image.asset(assetLogoMarca, height: 36, semanticLabel: 'Cristalins'),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Água Cristalins na sua porta',
                    style: AppTypography.title1.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: AppSpacing.secao),
                  BotaoPrincipal(
                    rotulo: 'Assinar Water Protein',
                    onPressed: () async {
                      await OnboardingPrefs.marcarVisto();
                      if (!context.mounted) return;
                      Navigator.of(context).pushReplacementNamed(AppRoutes.shell);
                      Navigator.of(context).pushNamed(AppRoutes.produto, arguments: 'WP500');
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  BotaoPrincipal(
                    rotulo: 'Ver todas as águas',
                    variante: VarianteBotaoPrincipal.navy,
                    onPressed: () => _marcarEIr(
                      context,
                      AppRoutes.shell,
                      args: const ShellArgs(abaInicial: 1, categoriaInicial: Categoria.aguas),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  BotaoPrincipal(
                    rotulo: 'Descobrir meu kit',
                    variante: VarianteBotaoPrincipal.contorno,
                    onPressed: () => _marcarEIr(context, AppRoutes.quiz),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
