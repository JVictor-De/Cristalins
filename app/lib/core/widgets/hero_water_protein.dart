import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../formatacao.dart';
import '../marca_assets.dart';

/// Hero da home visitante — Water Protein (layout em código + PNG da garrafa).
class HeroWaterProtein extends StatefulWidget {
  const HeroWaterProtein({
    super.key,
    required this.onAssinar,
    required this.onAbrirProduto,
    this.precoAPartirDe,
  });

  final VoidCallback onAssinar;
  final VoidCallback onAbrirProduto;

  /// Mesma fonte da sacola: `precoBase` do WP500 (não hardcode).
  final Dinheiro? precoAPartirDe;

  static const breakpoint = 720.0;
  static const raio = 28.0;

  static const gradienteInicio = Color(0xFFEEF8E0);
  static const gradienteFim = Color(0xFFC6E77A);
  static const navyEscuro = Color(0xFF063A52);
  static const ink = Color(0xFF0B2E3F);
  static const verdeTexto = Color(0xFF34503F);

  @override
  State<HeroWaterProtein> createState() => _HeroWaterProteinState();
}

class _HeroWaterProteinState extends State<HeroWaterProtein>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrada;
  late final Animation<double> _fade;
  late final Animation<double> _deslocamento;
  bool _animacaoDecidida = false;

  @override
  void initState() {
    super.initState();
    _entrada = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    final curva = CurvedAnimation(parent: _entrada, curve: Curves.easeOutCubic);
    _fade = curva;
    _deslocamento = Tween<double>(begin: 12, end: 0).animate(curva);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_animacaoDecidida) return;
    _animacaoDecidida = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _entrada.value = 1;
    } else {
      _entrada.forward();
    }
  }

  @override
  void dispose() {
    _entrada.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth >= HeroWaterProtein.breakpoint;
        final overflowTop = horizontal ? 30.0 : 16.0;
        final minAltura = horizontal ? 340.0 : 300.0;
        final padding = horizontal
            ? const EdgeInsets.fromLTRB(44, 48, 44, 48)
            : const EdgeInsets.fromLTRB(22, 24, 16, 24);
        final textoFrac = horizontal ? 0.55 : 0.60;
        final garrafaCentroFrac = horizontal ? 0.67 : 0.81;
        final garrafaLarguraFrac = horizontal ? 0.30 : 0.34;
        final luzDiametro = horizontal ? 380.0 : 230.0;
        final sombraLargura = horizontal ? 110.0 : 68.0;
        final w = constraints.maxWidth;

        return Padding(
          padding: EdgeInsets.only(top: overflowTop),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onAbrirProduto();
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(HeroWaterProtein.raio),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: minAltura, minWidth: w),
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              HeroWaterProtein.gradienteInicio,
                              HeroWaterProtein.gradienteFim,
                            ],
                          ),
                        ),
                        child: Stack(
                          children: [
                            const Positioned.fill(
                              child: CustomPaint(painter: _OndasHeroPainter()),
                            ),
                            Positioned(
                              left: w * garrafaCentroFrac - luzDiametro / 2,
                              top: 0,
                              bottom: 0,
                              width: luzDiametro,
                              child: Center(
                                child: SizedBox(
                                  width: luzDiametro,
                                  height: luzDiametro,
                                  child: const DecoratedBox(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          Color(0xC7FFFFFF), // branco 78%
                                          Color(0x00FFFFFF),
                                        ],
                                        stops: [0.35, 1.0],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: SizedBox(
                                width: w * textoFrac,
                                child: Padding(
                                  padding: padding,
                                  child: _TextoHero(
                                    horizontal: horizontal,
                                    preco: widget.precoAPartirDe,
                                    onAssinar: () {
                                      HapticFeedback.lightImpact();
                                      widget.onAssinar();
                                    },
                                    onConhecer: () {
                                      HapticFeedback.selectionClick();
                                      widget.onAbrirProduto();
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: w * garrafaCentroFrac - (w * garrafaLarguraFrac) / 2,
                    width: w * garrafaLarguraFrac,
                    top: -overflowTop,
                    bottom: 26,
                    child: AnimatedBuilder(
                      animation: _entrada,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _fade.value,
                          child: Transform.translate(
                            offset: Offset(0, _deslocamento.value),
                            child: child,
                          ),
                        );
                      },
                      child: _GarrafaHero(sombraLargura: sombraLargura),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TextoHero extends StatelessWidget {
  const _TextoHero({
    required this.horizontal,
    required this.preco,
    required this.onAssinar,
    required this.onConhecer,
  });

  final bool horizontal;
  final Dinheiro? preco;
  final VoidCallback onAssinar;
  final VoidCallback onConhecer;

  @override
  Widget build(BuildContext context) {
    final tituloSize = horizontal ? 44.0 : 30.0;
    final linhaSize = horizontal ? 18.0 : 15.0;
    final precoSize = horizontal ? 30.0 : 26.0;
    final gapAntesPreco = horizontal ? 22.0 : 18.0;
    final gapAntesBotoes = horizontal ? 22.0 : 16.0;
    final alturaAssinar = horizontal ? 52.0 : 48.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: HeroWaterProtein.navyEscuro,
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            'Mais vendido',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            'Water Protein',
            maxLines: 1,
            softWrap: false,
            style: TextStyle(
              fontSize: tituloSize,
              fontWeight: FontWeight.w700,
              height: 1.05,
              letterSpacing: tituloSize * -0.02,
              color: HeroWaterProtein.ink,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Água com proteína e colágeno · 500 ml',
          style: TextStyle(
            fontSize: linhaSize,
            height: 1.35,
            color: HeroWaterProtein.verdeTexto,
          ),
        ),
        const SizedBox(height: 14),
        const Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _ChipHero(rotulo: '5 g de proteína'),
            _ChipHero(rotulo: '0 açúcar'),
          ],
        ),
        SizedBox(height: gapAntesPreco),
        if (preco != null) ...[
          const Text(
            'Na assinatura, a partir de',
            style: TextStyle(
              fontSize: 13,
              height: 1.3,
              color: HeroWaterProtein.verdeTexto,
            ),
          ),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: preco!.formatado,
                  style: TextStyle(
                    fontSize: precoSize,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    color: HeroWaterProtein.ink,
                  ),
                ),
                const TextSpan(
                  text: ' /garrafa',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.3,
                    color: HeroWaterProtein.verdeTexto,
                  ),
                ),
              ],
            ),
          ),
        ],
        SizedBox(height: gapAntesBotoes),
        if (horizontal)
          Row(
            children: [
              _BotaoAssinar(
                altura: alturaAssinar,
                expandido: false,
                onPressed: onAssinar,
              ),
              const SizedBox(width: 12),
              Flexible(child: _BotaoConhecer(onPressed: onConhecer)),
            ],
          )
        else
          SizedBox(
            width: double.infinity,
            child: _BotaoAssinar(
              altura: alturaAssinar,
              expandido: true,
              onPressed: onAssinar,
            ),
          ),
      ],
    );
  }
}

class _ChipHero extends StatelessWidget {
  const _ChipHero({required this.rotulo});

  final String rotulo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        rotulo,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
          height: 1.2,
          color: HeroWaterProtein.ink,
        ),
      ),
    );
  }
}

class _BotaoAssinar extends StatelessWidget {
  const _BotaoAssinar({
    required this.altura,
    required this.expandido,
    required this.onPressed,
  });

  final double altura;
  final bool expandido;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final botao = FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: HeroWaterProtein.navyEscuro,
        foregroundColor: Colors.white,
        minimumSize: Size(expandido ? double.infinity : 0, altura),
        padding: const EdgeInsets.symmetric(horizontal: 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        elevation: 0,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: const Text('Assinar agora'),
    );
    return botao;
  }
}

class _BotaoConhecer extends StatelessWidget {
  const _BotaoConhecer({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.50),
        foregroundColor: HeroWaterProtein.ink,
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 28),
        side: BorderSide(color: HeroWaterProtein.navyEscuro.withValues(alpha: 0.35)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: const Text('Conhecer o produto'),
    );
  }
}

class _GarrafaHero extends StatelessWidget {
  const _GarrafaHero({required this.sombraLargura});

  final double sombraLargura;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Positioned(
          bottom: 0,
          child: Container(
            width: sombraLargura,
            height: 10,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: HeroWaterProtein.ink.withValues(alpha: 0.18),
              boxShadow: [
                BoxShadow(
                  color: HeroWaterProtein.ink.withValues(alpha: 0.28),
                  blurRadius: 12,
                ),
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Image.asset(
              assetProdutoWaterProtein,
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
              cacheWidth: 700,
              semanticLabel: 'Garrafa de Water Protein 500 ml',
              errorBuilder: (_, _, _) => const Icon(
                Icons.water_drop_outlined,
                size: 72,
                color: HeroWaterProtein.ink,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Duas ondas brancas a 12% na base do card (curvas quadráticas).
class _OndasHeroPainter extends CustomPainter {
  const _OndasHeroPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.12);

    final onda1 = Path()
      ..moveTo(0, size.height * 0.78)
      ..quadraticBezierTo(
        size.width * 0.28,
        size.height * 0.70,
        size.width * 0.55,
        size.height * 0.78,
      )
      ..quadraticBezierTo(
        size.width * 0.82,
        size.height * 0.86,
        size.width,
        size.height * 0.74,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final onda2 = Path()
      ..moveTo(0, size.height * 0.86)
      ..quadraticBezierTo(
        size.width * 0.22,
        size.height * 0.80,
        size.width * 0.48,
        size.height * 0.87,
      )
      ..quadraticBezierTo(
        size.width * 0.78,
        size.height * 0.94,
        size.width,
        size.height * 0.84,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(onda1, paint);
    canvas.drawPath(onda2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
