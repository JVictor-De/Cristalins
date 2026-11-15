import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// ThemeData único do app: plataforma iOS, Inter, transição Cupertino,
/// sem ripple, `cupertinoOverrideTheme` com a primária da marca.
ThemeData buildAppTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.azul800,
    onPrimary: AppColors.sobrePrimaria,
    primaryContainer: AppColors.azul100,
    onPrimaryContainer: AppColors.azul900,
    secondary: AppColors.azul500,
    onSecondary: AppColors.sobrePrimaria,
    tertiary: AppColors.amareloFlow,
    onTertiary: AppColors.azul900,
    error: AppColors.erro,
    onError: AppColors.sobrePrimaria,
    surface: AppColors.superficie,
    onSurface: AppColors.texto,
    onSurfaceVariant: AppColors.textoSecundario,
    outline: AppColors.borda,
  );

  return ThemeData(
    useMaterial3: true,
    platform: TargetPlatform.iOS, // comportamento iOS nos widgets Material
    fontFamily: AppTypography.familia, // cobre textos sem estilo explícito
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.fundoAgrupado,
    textTheme: AppTypography.textTheme,
    splashFactory: NoSplash.splashFactory, // sem ripple do Android
    highlightColor: Colors.transparent,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    cupertinoOverrideTheme: CupertinoThemeData(
      primaryColor: AppColors.azul800,
      primaryContrastingColor: AppColors.sobrePrimaria,
      scaffoldBackgroundColor: AppColors.fundoAgrupado,
      barBackgroundColor: AppColors.fundoAgrupado, // opaco: sem blur
      // inherit: false em todos, como os padrões do Cupertino: a transição da barra
      // interpola título grande → botão voltar e falha se os `inherit` diferirem.
      textTheme: CupertinoTextThemeData(
        primaryColor: AppColors.azul800,
        textStyle: AppTypography.body.copyWith(color: AppColors.texto, inherit: false),
        actionTextStyle: AppTypography.body.copyWith(
          color: AppColors.linkSobreSuperficie,
          inherit: false,
        ),
        navActionTextStyle: AppTypography.body.copyWith(color: AppColors.azul800, inherit: false),
        navTitleTextStyle: AppTypography.headline.copyWith(color: AppColors.texto, inherit: false),
        navLargeTitleTextStyle: AppTypography.largeTitle.copyWith(
          color: AppColors.texto,
          inherit: false,
        ),
      ),
    ),
    dividerTheme: const DividerThemeData(
      thickness: AppSpacing.divisoria,
      space: AppSpacing.divisoria,
      color: AppColors.borda,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.texto,
      contentTextStyle: AppTypography.subheadline.copyWith(color: AppColors.sobrePrimaria),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.raioAviso)),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.azul500,
      linearTrackColor: AppColors.azul100,
      linearMinHeight: 4,
    ),
  );
}

/// Rolagem elástica do iOS também no Android, sem o brilho de overscroll.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) =>
      child;
}
