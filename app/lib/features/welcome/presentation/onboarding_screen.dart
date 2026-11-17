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
          // Scrim meio-termo (entre o navy P4 e o preto a 25%).
          ColoredBox(color: Colors.black.withValues(alpha: 0.40)),
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
                      // Fundo sólido: branco sobre o bokeh falhava contraste WCAG (~2,8:1).
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
                  const Expanded(child: _OnboardingHeroGarrafa()),
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

/// Hero: marca + garrafa + respingo com os mesmos keyframes da PDP (`CenaImpactoAgua`).
class _OnboardingHeroGarrafa extends StatefulWidget {
  const _OnboardingHeroGarrafa();

  @override
  State<_OnboardingHeroGarrafa> createState() => _OnboardingHeroGarrafaState();
}

class _OnboardingHeroGarrafaState extends State<_OnboardingHeroGarrafa>
    with SingleTickerProviderStateMixin {
  /// Mesma duração da PDP (`cr-*-impact`, ~1,8 s).
  static const _duracao = Duration(milliseconds: 1800);

  /// Frações da caixa do hero — só estas 3 imagens escalam entre si.
  static const _garrafaLarguraFrac = 0.40;
  static const _marcaSobreGarrafa = 1.35;
  static const _respingoSobreGarrafa = 2.2;
  static const _garrafaAlturaFrac = 0.78;

  late final AnimationController _ctrl;

  static double _lerpKeyframes(List<(double, double)> keys, double progress) {
    if (progress <= keys.first.$1) return keys.first.$2;
    for (var i = 1; i < keys.length; i++) {
      final (t0, v0) = keys[i - 1];
      final (t1, v1) = keys[i];
      if (progress <= t1) {
        final local = (progress - t0) / (t1 - t0);
        return v0 + (v1 - v0) * local;
      }
    }
    return keys.last.$2;
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _duracao);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _ctrl.value = 1;
      } else {
        _ctrl.forward(from: 0);
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduzir = MediaQuery.disableAnimationsOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final w = constraints.maxWidth;
        final garrafaW = w * _garrafaLarguraFrac;
        final marcaW = garrafaW * _marcaSobreGarrafa;
        final garrafaH = h * _garrafaAlturaFrac;
        final splashW = garrafaW * _respingoSobreGarrafa;
        final splashH = garrafaH * 0.55;

        return AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            final t = reduzir ? 1.0 : _ctrl.value;

            // cr-bottle-impact (PDP)
            final bottleOpacity = _lerpKeyframes(const [(0, 0), (0.15, 1), (1, 1)], t);
            final bottleY = _lerpKeyframes(const [
              (0, -0.12),
              (0.51, 0),
              (0.59, 0.01),
              (0.74, -0.008),
              (1, 0),
            ], t);

            // cr-splash-impact (PDP)
            final splashOpacity = _lerpKeyframes(const [
              (0, 0),
              (0.49, 0),
              (0.60, 1),
              (1, 1),
            ], t);
            final splashTy = _lerpKeyframes(const [
              (0, 0.04),
              (0.49, 0.04),
              (0.60, 0),
              (1, 0),
            ], t);
            final splashSx = _lerpKeyframes(const [
              (0, 0.4),
              (0.49, 0.4),
              (0.60, 0.94),
              (0.77, 1.025),
              (1, 1),
            ], t);
            final splashSy = _lerpKeyframes(const [
              (0, 0.12),
              (0.49, 0.12),
              (0.60, 0.9),
              (0.77, 1.04),
              (1, 1),
            ], t);

            // brand delay 1.22s / dur 1.0s of 1.8s (PDP)
            final brandT = ((t - 0.678) / 0.556).clamp(0.0, 1.0);
            final brandOpacity = brandT <= 0 ? 0.0 : (brandT < 0.12 ? brandT / 0.12 : 1.0);
            final brandReveal = brandT <= 0 ? 0.0 : brandT.clamp(0.0, 1.0);

            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Marca acima da garrafa — reveal lateral após o impacto.
                Positioned(
                  top: h * 0.02,
                  left: (w - marcaW) / 2,
                  width: marcaW,
                  child: ClipRect(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      widthFactor: brandReveal <= 0 ? 0.001 : brandReveal,
                      child: Opacity(
                        opacity: brandOpacity,
                        child: Image.asset(
                          assetImpactoMarca,
                          key: const ValueKey('onboarding-marca'),
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          excludeFromSemantics: true,
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ),
                ),
                // Garrafa — queda + fade (cr-bottle-impact).
                Positioned(
                  left: (w - garrafaW) / 2,
                  bottom: h * 0.06,
                  width: garrafaW,
                  height: garrafaH,
                  child: Opacity(
                    opacity: bottleOpacity,
                    child: Transform.translate(
                      offset: Offset(0, bottleY * h),
                      child: Image.asset(
                        assetOnboardingGarrafaWp,
                        key: const ValueKey('onboarding-garrafa-wp'),
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomCenter,
                        filterQuality: FilterQuality.high,
                        semanticLabel: 'Garrafa de Water Protein Cristalins 500 ml',
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
                // Respingo — escala/opacidade no impacto (cr-splash-impact).
                Positioned(
                  left: (w - splashW) / 2,
                  width: splashW,
                  bottom: h * 0.02,
                  height: splashH,
                  child: Opacity(
                    opacity: splashOpacity,
                    child: Transform.translate(
                      offset: Offset(0, splashTy * h),
                      child: Transform(
                        alignment: const Alignment(0, 0.9),
                        transform: Matrix4.diagonal3Values(splashSx, splashSy, 1),
                        child: Image.asset(
                          assetImpactoRespingo,
                          key: const ValueKey('onboarding-respingo'),
                          fit: BoxFit.contain,
                          alignment: Alignment.bottomCenter,
                          filterQuality: FilterQuality.high,
                          excludeFromSemantics: true,
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
