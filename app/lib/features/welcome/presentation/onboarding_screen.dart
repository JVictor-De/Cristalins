import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/intents/navegacao_nativa.dart';
import '../../../core/marca_assets.dart';
import '../../../core/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/botao_principal.dart';
import '../../../core/widgets/logo_marca.dart';
import '../../catalog/domain/catalogo.dart';
import '../../catalog/domain/sacola_copy.dart';
import '../../catalog/presentation/sacola_controller.dart';
import '../../shell/presentation/shell_screen.dart';
import '../data/onboarding_prefs.dart';

/// 1ª abertura (e alias `/boas-vindas`): hero WP + 1 CTA + 1 secundário + Entrar.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  static const _logoLargura = 120.0;

  Future<void> _marcarEIr(BuildContext context, String rota, {Object? args}) async {
    HapticFeedback.lightImpact();
    await OnboardingPrefs.marcarVisto();
    if (!context.mounted) return;
    Navigator.of(context).pushReplacementNamed(rota, arguments: args);
  }

  /// P4.2: montar assinatura — WP na PDP se houver catálogo; senão aba Produtos.
  Future<void> _montarAssinatura(BuildContext context) async {
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

  Future<void> _entrar(BuildContext context) async {
    HapticFeedback.selectionClick();
    await OnboardingPrefs.marcarVisto();
    if (!context.mounted) return;
    await NavegacaoNativa.instancia.abrir(
      context,
      activity: NavegacaoNativa.cadastroLogin,
      rota: AppRoutes.cadastroLogin,
      limparPilha: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sacola = context.watch<SacolaController>();
    final wp = sacola.produtoDe('WP500');
    final preco = wp?.precoBase;
    final freteLimite = sacola.simulacao?.freteGratisAcima ?? kFreteGratisAcimaPadrao;
    final hintFrete = SacolaCopy.freteGratisAcima(freteLimite);

    return Scaffold(
      backgroundColor: AppColors.heroNavy,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // P4.1: fallback sólido #063A52 se a foto falhar.
          const ColoredBox(color: AppColors.heroNavy),
          Image.asset(
            assetHeroAguaBokeh,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            semanticLabel: 'Fundo decorativo Cristalins',
            errorBuilder: (_, _, _) => const ColoredBox(color: AppColors.heroNavy),
          ),
          // Scrim/degradê navy para o texto/painel.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x66063A52),
                  Color(0xCC063A52),
                  AppColors.heroNavy,
                ],
                stops: [0.0, 0.45, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.margem,
                AppSpacing.sm,
                AppSpacing.margem,
                AppSpacing.secao,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: DecoratedBox(
                      // Fundo sólido: branco sobre o degradê falhava contraste WCAG (~2,8:1).
                      decoration: BoxDecoration(
                        color: AppColors.azul900,
                        borderRadius: BorderRadius.circular(AppSpacing.raioBotao),
                      ),
                      child: TextButton(
                        key: const ValueKey('onboarding-entrar'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          minimumSize: const Size(AppSpacing.toqueMinimo, AppSpacing.toqueMinimo),
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                        ),
                        onPressed: () => _entrar(context),
                        child: Text(
                          'Já sou assinante? Entrar',
                          style: AppTypography.footnote.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Image.asset(
                        assetProdutoWaterProtein,
                        key: const ValueKey('onboarding-garrafa-wp'),
                        height: MediaQuery.sizeOf(context).height * 0.32,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        semanticLabel: 'Garrafa de Water Protein Cristalins 500 ml',
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.azul900,
                      borderRadius: BorderRadius.circular(AppSpacing.raioCard),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.margem),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: LogoMarca(
                              largura: _logoLargura,
                              altura: 40,
                              sobreFundoEscuro: true,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Water Protein no Rio',
                            key: const ValueKey('onboarding-titulo'),
                            style: AppTypography.title1.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Assinatura com entrega no Rio — escolha a frequência na sacola. $hintFrete.',
                            key: const ValueKey('onboarding-subtitulo'),
                            style: AppTypography.subheadline.copyWith(color: Colors.white),
                          ),
                          if (preco != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'A partir de ${preco.formatado}/garrafa',
                              key: const ValueKey('onboarding-preco'),
                              style: AppTypography.headline.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.secao),
                          BotaoPrincipal(
                            key: const ValueKey('onboarding-cta'),
                            rotulo: 'Montar minha assinatura',
                            variante: VarianteBotaoPrincipal.cta,
                            onPressed: () => _montarAssinatura(context),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          TextButton(
                            key: const ValueKey('onboarding-ver-produtos'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, AppSpacing.toqueMinimo),
                            ),
                            onPressed: () => _marcarEIr(
                              context,
                              AppRoutes.shell,
                              args: const ShellArgs(abaInicial: 1),
                            ),
                            child: Text(
                              'Ver todos os produtos',
                              style: AppTypography.subheadline.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
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
