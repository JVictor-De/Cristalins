import 'package:flutter/material.dart';

import '../marca_assets.dart';
import '../theme/app_colors.dart';

/// Logo Cristalins sem “caixinha branca” do JPG.
///
/// Matriz aproxima chroma-key do fundo branco; documentado em DECISOES.
class LogoMarca extends StatelessWidget {
  const LogoMarca({super.key, this.altura = 32});

  final double altura;

  /// Alpha ≈ soma RGB invertida: pixels claros somem, azul/navy permanece.
  static const _semFundoBranco = ColorFilter.matrix(<double>[
    1, 0, 0, 0, 0,
    0, 1, 0, 0, 0,
    0, 0, 1, 0, 0,
    -0.8, -0.8, -0.8, 0, 255 * 2.2,
  ]);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Cristalins',
      image: true,
      child: ColorFiltered(
        colorFilter: _semFundoBranco,
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
      ),
    );
  }
}
