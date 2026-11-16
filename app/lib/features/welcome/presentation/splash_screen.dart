import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // SystemChrome não sai de material.dart neste SDK.

import '../../../core/routes.dart';
import '../../../core/theme/app_colors.dart';
import 'boas_vindas_screen.dart';

/// Abertura: água em tela cheia que vira a garrafa e segue para boas-vindas.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _loopController;
  late final AnimationController _morphController;

  @override
  void initState() {
    super.initState();
    // A água cobre a tela: ícones claros na barra de status.
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    _loopController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))
      ..repeat();

    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
    );

    _iniciarSequenciaSplash();
  }

  Future<void> _iniciarSequenciaSplash() async {
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    try {
      // forward() sozinho não completa se o ticker for descartado no meio;
      // orCancel entrega TickerCanceled e solta o State.
      await _morphController.forward().orCancel;
    } on TickerCanceled {
      return;
    }
    if (!mounted) return;

    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        settings: const RouteSettings(name: AppRoutes.boasVindas),
        transitionDuration: const Duration(milliseconds: 550),
        pageBuilder: (_, _, _) => const BoasVindasScreen(),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
    _loopController.dispose();
    _morphController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.azul50,
      body: Semantics(
        label: 'Cristalins',
        child: AnimatedBuilder(
          animation: Listenable.merge([_loopController, _morphController]),
          builder: (context, _) {
            return SizedBox.expand(
              child: CustomPaint(
                painter: _WaterBottleSplashPainter(
                  loopProgress: _loopController.value,
                  morphProgress: _morphController.value,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WaterBottleSplashPainter extends CustomPainter {
  _WaterBottleSplashPainter({required this.loopProgress, required this.morphProgress})
    : assert(_fullScreenPoints.length == _bottlePoints.length),
      assert((_fullScreenPoints.length - 1) % 3 == 0);

  final double loopProgress;
  final double morphProgress;

  static const List<Offset> _fullScreenPoints = [
    Offset(180, -8),
    Offset(220, -8),
    Offset(250, -8),
    Offset(280, -8),
    Offset(320, -8),
    Offset(355, -8),
    Offset(368, -8),
    Offset(368, 60),
    Offset(368, 140),
    Offset(368, 220),
    Offset(368, 310),
    Offset(368, 400),
    Offset(368, 480),
    Offset(368, 560),
    Offset(368, 640),
    Offset(368, 710),
    Offset(368, 745),
    Offset(368, 768),
    Offset(335, 768),
    Offset(280, 768),
    Offset(230, 768),
    Offset(180, 768),
    Offset(130, 768),
    Offset(80, 768),
    Offset(25, 768),
    Offset(-8, 768),
    Offset(-8, 745),
    Offset(-8, 710),
    Offset(-8, 640),
    Offset(-8, 560),
    Offset(-8, 480),
    Offset(-8, 400),
    Offset(-8, 310),
    Offset(-8, 220),
    Offset(-8, 140),
    Offset(-8, 60),
    Offset(-8, -8),
    Offset(5, -8),
    Offset(40, -8),
    Offset(80, -8),
    Offset(110, -8),
    Offset(140, -8),
    Offset(180, -8),
  ];

  static const List<Offset> _bottlePoints = [
    Offset(180, 212),
    Offset(192, 212),
    Offset(202, 212),
    Offset(202, 216),
    Offset(202, 226),
    Offset(202, 238),
    Offset(204, 248),
    Offset(208, 270),
    Offset(252, 282),
    Offset(252, 316),
    Offset(252, 355),
    Offset(252, 395),
    Offset(252, 435),
    Offset(252, 475),
    Offset(252, 515),
    Offset(252, 536),
    Offset(252, 554),
    Offset(240, 566),
    Offset(220, 566),
    Offset(206, 566),
    Offset(193, 566),
    Offset(180, 566),
    Offset(167, 566),
    Offset(154, 566),
    Offset(140, 566),
    Offset(120, 566),
    Offset(108, 554),
    Offset(108, 536),
    Offset(108, 515),
    Offset(108, 475),
    Offset(108, 435),
    Offset(108, 395),
    Offset(108, 355),
    Offset(108, 316),
    Offset(108, 282),
    Offset(152, 270),
    Offset(156, 248),
    Offset(158, 238),
    Offset(158, 226),
    Offset(158, 216),
    Offset(158, 212),
    Offset(168, 212),
    Offset(180, 212),
  ];

  static const _bubbles =
      <({double x, double y, double r, double phase, double sway, Color color})>[
        (x: 135, y: 240, r: 3.4, phase: 0.05, sway: 7, color: AppColors.azul50),
        (x: 172, y: 285, r: 2.4, phase: 0.28, sway: -6, color: AppColors.superficie),
        (x: 208, y: 260, r: 4, phase: 0.14, sway: 8, color: AppColors.azul100),
        (x: 154, y: 330, r: 2.8, phase: 0.45, sway: -5, color: AppColors.superficie),
        (x: 225, y: 315, r: 2.2, phase: 0.62, sway: 6, color: AppColors.azul50),
        (x: 186, y: 355, r: 3.6, phase: 0.78, sway: -7, color: AppColors.azul100),
        (x: 65, y: 420, r: 3.5, phase: 0.10, sway: 8, color: AppColors.azul50),
        (x: 295, y: 390, r: 3.2, phase: 0.35, sway: -8, color: AppColors.superficie),
      ];

  double _easeInOutCubic(double x) {
    if (x < 0.5) return 4 * x * x * x;
    return (1 - math.pow(-2 * x + 2, 3) / 2).toDouble();
  }

  double _easeOutSoftBack(double x) {
    const c1 = 1.15;
    const c3 = c1 + 1.0;
    return (1.0 + c3 * math.pow(x - 1.0, 3) + c1 * math.pow(x - 1.0, 2)).toDouble();
  }

  Path _buildInterpolatedPath(double t) {
    final pts = List<Offset>.generate(_fullScreenPoints.length, (i) {
      return Offset.lerp(_fullScreenPoints[i], _bottlePoints[i], t)!;
    });

    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (var i = 1; i < pts.length; i += 3) {
      path.cubicTo(
        pts[i].dx,
        pts[i].dy,
        pts[i + 1].dx,
        pts[i + 1].dy,
        pts[i + 2].dx,
        pts[i + 2].dy,
      );
    }
    return path..close();
  }

  Path _buildWavePath({
    required double startX,
    required double baseY,
    required double amplitude,
    required bool closeBottom,
  }) {
    final path = Path()..moveTo(startX, baseY);
    for (var x = startX; x < 720; x += 180) {
      path
        ..quadraticBezierTo(x + 45, baseY + amplitude, x + 90, baseY)
        ..quadraticBezierTo(x + 135, baseY - amplitude, x + 180, baseY);
    }
    if (closeBottom) {
      path
        ..lineTo(720, 860)
        ..lineTo(startX, 860)
        ..close();
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: [0.0, 0.55, 1.0],
        colors: [AppColors.azul50, AppColors.superficie, AppColors.azul100],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bgPaint);

    const virtualW = 360.0;
    const virtualH = 760.0;
    final scale = math.max(size.width / virtualW, size.height / virtualH);
    final offsetX = (size.width - virtualW * scale) / 2.0;
    final offsetY = (size.height - virtualH * scale) / 2.0;

    canvas.save();
    canvas.translate(offsetX, offsetY);
    canvas.scale(scale);

    final morphT = morphProgress > 0 ? _easeOutSoftBack(morphProgress) : 0.0;
    final morphPath = _buildInterpolatedPath(morphT);

    if (morphProgress > 0.55) {
      final alpha = _easeInOutCubic((morphProgress - 0.55) / 0.45);
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(180, 586), width: 128, height: 18),
        Paint()..color = AppColors.azul500.withValues(alpha: alpha * 0.16),
      );
    }

    canvas.drawPath(morphPath, Paint()..color = AppColors.azul100.withValues(alpha: 0.45));

    canvas.save();
    canvas.clipPath(morphPath);

    final waterY = -24.0 + (285.0 - (-24.0)) * _easeInOutCubic(morphProgress);
    canvas.translate(0, waterY);

    final backShift = -180.0 + (loopProgress * 180.0);
    final backWave = _buildWavePath(startX: backShift, baseY: 0, amplitude: -14, closeBottom: true);
    canvas.drawPath(
      backWave,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.azul300.withValues(alpha: 0xCC / 255),
            AppColors.azul800.withValues(alpha: 0xEB / 255),
          ],
        ).createShader(const Rect.fromLTWH(0, -20, 360, 860)),
    );

    final frontShift = -(loopProgress * 180.0);
    final frontWave = _buildWavePath(
      startX: frontShift,
      baseY: 4,
      amplitude: 12,
      closeBottom: true,
    );
    canvas.drawPath(
      frontWave,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.5, 1.0],
          colors: [AppColors.azul300, AppColors.azul500, AppColors.azul800],
        ).createShader(const Rect.fromLTWH(0, -20, 360, 860)),
    );

    final crestPath = _buildWavePath(
      startX: frontShift,
      baseY: 4,
      amplitude: 12,
      closeBottom: false,
    );
    canvas.drawPath(
      crestPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = AppColors.azul100.withValues(alpha: 0.75),
    );

    final underWave = _buildWavePath(
      startX: frontShift,
      baseY: 180,
      amplitude: -16,
      closeBottom: true,
    );
    canvas.drawPath(underWave, Paint()..color = AppColors.azul100.withValues(alpha: 0.22));

    _drawBubbles(canvas);
    canvas.restore();

    if (morphProgress > 0.55) {
      final alpha = _easeInOutCubic((morphProgress - 0.55) / 0.45);
      final bottleShape = _buildInterpolatedPath(1.0);

      canvas.drawPath(
        bottleShape,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeJoin = StrokeJoin.round
          ..color = AppColors.textoSecundario.withValues(alpha: alpha * 0.65),
      );

      canvas.drawLine(
        const Offset(122, 314),
        const Offset(122, 526),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round
          ..color = AppColors.sobrePrimaria.withValues(alpha: alpha * 0.55),
      );

      final shoulderShine = Path()
        ..moveTo(126, 288)
        ..quadraticBezierTo(138, 274, 154, 264);
      canvas.drawPath(
        shoulderShine,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..color = AppColors.sobrePrimaria.withValues(alpha: alpha * 0.55),
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(154, 212, 52, 5), const Radius.circular(2.5)),
        Paint()..color = AppColors.borda.withValues(alpha: alpha),
      );

      canvas.save();
      canvas.translate(0, -16.0 * (1.0 - alpha));
      final capRect = const Rect.fromLTWH(154, 182, 52, 30);
      canvas.drawRRect(
        RRect.fromRectAndRadius(capRect, const Radius.circular(7)),
        Paint()
          ..shader = LinearGradient(
            colors: [
              AppColors.azul700.withValues(alpha: alpha),
              AppColors.azul500.withValues(alpha: alpha),
              AppColors.azul900.withValues(alpha: alpha),
            ],
          ).createShader(capRect),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(159, 186, 42, 4), const Radius.circular(2)),
        Paint()..color = AppColors.azul100.withValues(alpha: alpha * 0.55),
      );
      canvas.restore();
    }

    canvas.restore();
  }

  void _drawBubbles(Canvas canvas) {
    for (final b in _bubbles) {
      final t = (loopProgress + b.phase) % 1.0;
      final opacity = t < 0.2 ? (t / 0.2) * 0.75 : (1.0 - ((t - 0.2) / 0.8)) * 0.75;
      final dy = -210.0 * t;
      final dx = math.sin(t * math.pi * 2) * b.sway;
      final scale = 0.5 + 0.6 * t;

      canvas.drawCircle(
        Offset(b.x + dx, b.y + dy),
        b.r * scale,
        Paint()..color = b.color.withValues(alpha: opacity.clamp(0.0, 1.0).toDouble()),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaterBottleSplashPainter oldDelegate) {
    return oldDelegate.loopProgress != loopProgress || oldDelegate.morphProgress != morphProgress;
  }
}
