import 'package:flutter/material.dart';

import '../marca_assets.dart';
import '../theme/app_colors.dart';

/// Logo Cristalins (PNG com fundo transparente).
///
/// Em fundo claro: sem ColorFilter (DECISOES marketplace). Em fundo escuro
/// (onboarding P4): [sobreFundoEscuro] aplica tint branco.
class LogoMarca extends StatelessWidget {
  const LogoMarca({
    super.key,
    this.altura = 32,
    this.largura,
    this.sobreFundoEscuro = false,
  });

  final double altura;

  /// Se definido, limita a largura (P4: ~120 no onboarding).
  final double? largura;

  /// Tint branco para painéis navy / fotos escuras.
  final bool sobreFundoEscuro;

  @override
  Widget build(BuildContext context) {
    Widget imagem = Image.asset(
      assetLogoMarca,
      height: altura,
      width: largura,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      color: sobreFundoEscuro ? Colors.white : null,
      colorBlendMode: sobreFundoEscuro ? BlendMode.srcIn : null,
      errorBuilder: (_, _, _) => Text(
        'cristalins',
        style: TextStyle(
          color: sobreFundoEscuro ? Colors.white : AppColors.azulMarca,
          fontWeight: FontWeight.w700,
          fontSize: (largura ?? altura) * 0.22,
          letterSpacing: -0.3,
        ),
      ),
    );

    if (largura != null) {
      imagem = SizedBox(width: largura, child: imagem);
    }

    return Semantics(
      label: 'Cristalins',
      image: true,
      child: imagem,
    );
  }
}
