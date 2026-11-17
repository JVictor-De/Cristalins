import 'package:cristalins_assinatura/core/theme/app_colors.dart';
import 'package:cristalins_assinatura/core/theme/app_sombras.dart';
import 'package:cristalins_assinatura/core/widgets/hero_water_protein.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('hero WP usa tokens AppColors (fonte única)', () {
    expect(HeroWaterProtein.gradienteInicio, AppColors.heroGradienteInicio);
    expect(HeroWaterProtein.gradienteMeio, AppColors.heroGradienteMeio);
    expect(HeroWaterProtein.gradienteFim, AppColors.heroGradienteFim);
    expect(HeroWaterProtein.navyEscuro, AppColors.heroNavy);
    expect(HeroWaterProtein.ink, AppColors.heroInk);
    expect(HeroWaterProtein.verdeTexto, AppColors.heroVerdeTexto);
  });

  test('impacto PDP e sombra de grade existem', () {
    expect(AppColors.impactoAgua, const Color(0xFF43BDE6));
    expect(AppSombras.cardGrade, isNotEmpty);
    expect(AppSombras.cardGrade.first.blurRadius, 24);
    expect(AppSombras.card.first.blurRadius, 50);
  });
}
