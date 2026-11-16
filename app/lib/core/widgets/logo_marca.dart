import 'package:flutter/material.dart';

import '../marca_assets.dart';
import '../theme/app_colors.dart';

/// Logo Cristalins (PNG com fundo transparente).
class LogoMarca extends StatelessWidget {
  const LogoMarca({super.key, this.altura = 32});

  final double altura;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Cristalins',
      image: true,
      child: Image.asset(
        assetLogoMarca,
        height: altura,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, _, _) => Text(
          'cristalins',
          style: TextStyle(
            color: AppColors.azulMarca,
            fontWeight: FontWeight.w700,
            fontSize: altura * 0.55,
            letterSpacing: -0.3,
          ),
        ),
      ),
    );
  }
}
