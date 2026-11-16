import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/marca_assets.dart';
import '../../../core/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/botao_principal.dart';
import '../../../core/widgets/logo_marca.dart';
import '../../catalog/domain/catalogo.dart';
import '../../catalog/presentation/sacola_controller.dart';
import '../../shell/presentation/shell_screen.dart';
import '../data/onboarding_prefs.dart';

/// 1ª abertura: 1 CTA filled + links + Pular.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  Future<void> _marcarEIr(BuildContext context, String rota, {Object? args}) async {
    HapticFeedback.lightImpact();
    await OnboardingPrefs.marcarVisto();
    if (!context.mounted) return;
    Navigator.of(context).pushReplacementNamed(rota, arguments: args);
  }

  Future<void> _assinarWp(BuildContext context) async {
    final sacola = context.read<SacolaController>();
    final temWp = sacola.produtoDe('WP500') != null;
    if (temWp) {
      HapticFeedback.lightImpact();
      await OnboardingPrefs.marcarVisto();
      if (!context.mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.shell);
      if (!context.mounted) return;
      Navigator.of(context).pushNamed(AppRoutes.produto, arguments: 'WP500');
    } else {
      await _marcarEIr(
        context,
        AppRoutes.shell,
        args: const ShellArgs(abaInicial: 1),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sacola = context.watch<SacolaController>();
    final temAguas = sacola.produtos.any(Categoria.aguas.inclui);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(assetHeroAguaBokeh, fit: BoxFit.cover, semanticLabel: 'Água Cristalins'),
          Container(color: Colors.black.withValues(alpha: 0.25)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.margem,
                AppSpacing.margem,
                AppSpacing.margem,
                AppSpacing.secao,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(AppSpacing.raioBotao),
                      ),
                      child: TextButton(
                        onPressed: () => _marcarEIr(context, AppRoutes.shell),
                        child: Text(
                          'Pular',
                          style: AppTypography.headline.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  const LogoMarca(altura: 48),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Água Cristalins na sua porta',
                    style: AppTypography.title1.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: AppSpacing.secao),
                  BotaoPrincipal(
                    rotulo: 'Assinar Water Protein',
                    onPressed: () => _assinarWp(context),
                  ),
                  if (temAguas) ...[
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white70),
                        minimumSize: const Size.fromHeight(AppSpacing.alturaBotao),
                      ),
                      onPressed: () => _marcarEIr(
                        context,
                        AppRoutes.shell,
                        args: const ShellArgs(abaInicial: 1, categoriaInicial: Categoria.aguas),
                      ),
                      child: const Text('Ver todas as águas'),
                    ),
                  ],
                  TextButton(
                    onPressed: () => _marcarEIr(context, AppRoutes.quiz),
                    child: Text(
                      'Descobrir meu kit',
                      style: AppTypography.subheadline.copyWith(color: AppColors.ceu),
                    ),
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
