import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../marca_assets.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Cena garrafa + respingo do site (CSS `cr-*-impact`, ~1,8 s).
///
/// Uso: camada da foto na PDP de água mineral. Sem autoplay em home/onboarding.
class CenaImpactoAgua extends StatefulWidget {
  const CenaImpactoAgua({
    super.key,
    this.autoPlay = true,
    this.mostrarReplay = true,
  });

  final bool autoPlay;
  final bool mostrarReplay;

  @override
  State<CenaImpactoAgua> createState() => _CenaImpactoAguaState();
}

class _CenaImpactoAguaState extends State<CenaImpactoAgua>
    with SingleTickerProviderStateMixin {
  static const _duracao = Duration(milliseconds: 1800);

  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _duracao);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final reduzir = MediaQuery.disableAnimationsOf(context);
      if (reduzir) {
        _ctrl.value = 1;
      } else if (widget.autoPlay) {
        _ctrl.forward(from: 0);
      } else {
        _ctrl.value = 1;
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _replay() {
    HapticFeedback.selectionClick();
    if (MediaQuery.disableAnimationsOf(context)) {
      _ctrl.value = 1;
      return;
    }
    _ctrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final reduzir = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      label:
          'Água mineral tem nome: Cristalins. Garrafa de água mineral sem gás toca a água com um respingo.',
      image: true,
      child: ColoredBox(
        color: const Color(0xFF43BDE6),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: 580 / 708,
                child: AnimatedBuilder(
                  animation: _ctrl,
                  builder: (context, _) {
                    final t = reduzir ? 1.0 : _ctrl.value;
                    return _CenaLayers(t: t);
                  },
                ),
              ),
            ),
            if (widget.mostrarReplay && !reduzir)
              Positioned(
                right: AppSpacing.xs,
                bottom: AppSpacing.xs,
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.navy,
                    backgroundColor: AppColors.superficie.withValues(alpha: 0.82),
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: _replay,
                  child: Text(
                    'Ver de novo',
                    style: AppTypography.caption1.copyWith(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CenaLayers extends StatelessWidget {
  const _CenaLayers({required this.t});

  final double t;

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
  Widget build(BuildContext context) {
    // cr-bottle-impact
    final bottleOpacity = _lerpKeyframes(const [(0, 0), (0.15, 1), (1, 1)], t);
    final bottleY = _lerpKeyframes(const [
      (0, -0.12),
      (0.51, 0),
      (0.59, 0.01),
      (0.74, -0.008),
      (1, 0),
    ], t);

    // cr-splash-impact
    final splashOpacity = _lerpKeyframes(const [(0, 0), (0.49, 0), (0.60, 1), (1, 1)], t);
    final splashTy = _lerpKeyframes(const [(0, 0.04), (0.49, 0.04), (0.60, 0), (1, 0)], t);
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

    // cr-impact-wave
    final ringOpacity = _lerpKeyframes(const [(0, 0), (0.50, 0), (0.60, 0.8), (1, 0.1)], t);
    final ringScale = _lerpKeyframes(const [(0, 0.3), (0.50, 0.3), (1, 1.6)], t);

    // phrase delay 0.98s / dur 0.5s of 1.8s
    final phraseT = ((t - 0.544) / 0.278).clamp(0.0, 1.0);
    final phraseOpacity = phraseT;
    final phraseTy = (1 - phraseT) * 6;

    // brand delay 1.22s / dur 1.0s of 1.8s
    final brandT = ((t - 0.678) / 0.556).clamp(0.0, 1.0);
    final brandOpacity = brandT <= 0 ? 0.0 : (brandT < 0.12 ? brandT / 0.12 : 1.0);
    final brandReveal = brandT <= 0 ? 0.0 : brandT.clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.raioCard),
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          final h = c.maxHeight;
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                assetImpactoFundo,
                fit: BoxFit.cover,
                width: w,
                height: h,
                excludeFromSemantics: true,
              ),
              // Frase + marca (top ~1.7%, left 13%, width 74%)
              Positioned(
                top: h * 0.017,
                left: w * 0.13,
                width: w * 0.74,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Opacity(
                      opacity: phraseOpacity,
                      child: Transform.translate(
                        offset: Offset(0, phraseTy),
                        child: Image.asset(
                          assetImpactoFrase,
                          fit: BoxFit.contain,
                          excludeFromSemantics: true,
                        ),
                      ),
                    ),
                    SizedBox(height: h * 0.014),
                    ClipRect(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        widthFactor: brandReveal <= 0 ? 0.001 : brandReveal,
                        child: Opacity(
                          opacity: brandOpacity,
                          child: Image.asset(
                            assetImpactoMarca,
                            fit: BoxFit.contain,
                            excludeFromSemantics: true,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Ring — left 20%, bottom 7.5%, width 60%, height 5%
              Positioned(
                left: w * 0.20,
                bottom: h * 0.075,
                width: w * 0.60,
                height: h * 0.05,
                child: Opacity(
                  opacity: ringOpacity,
                  child: Transform.scale(
                    scale: ringScale,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xC7FFFFFF), width: 2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ),
              // Bottle — left 32%, bottom 8.7%, width 36%, height 68%
              Positioned(
                left: w * 0.32,
                bottom: h * 0.087,
                width: w * 0.36,
                height: h * 0.68,
                child: Opacity(
                  opacity: bottleOpacity,
                  child: Transform.translate(
                    offset: Offset(0, bottleY * h),
                    child: Image.asset(
                      assetImpactoGarrafa,
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomCenter,
                      excludeFromSemantics: true,
                    ),
                  ),
                ),
              ),
              // Splash — left 0, bottom 5.5%, width 100%, height 44%
              Positioned(
                left: 0,
                bottom: h * 0.055,
                width: w,
                height: h * 0.44,
                child: Opacity(
                  opacity: splashOpacity,
                  child: Transform.translate(
                    offset: Offset(0, splashTy * h),
                    child: Transform(
                      alignment: const Alignment(0, 0.9),
                      transform: Matrix4.diagonal3Values(splashSx, splashSy, 1),
                      child: Image.asset(
                        assetImpactoRespingo,
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomCenter,
                        excludeFromSemantics: true,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
