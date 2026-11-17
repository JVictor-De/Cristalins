import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// ThemeData do app: marketplace (gelo, azulMarca) + transição Cupertino, sem ripple.
///
/// Contraste do botão primário: branco peso ≥ 600 sobre [AppColors.azulMarca] (~4,51 AA).
ThemeData buildAppTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.azulMarca,
    onPrimary: AppColors.sobrePrimaria,
    primaryContainer: AppColors.menta,
    onPrimaryContainer: AppColors.navy,
    secondary: AppColors.navy,
    onSecondary: AppColors.sobrePrimaria,
    tertiary: AppColors.amareloFlow,
    onTertiary: AppColors.navy,
    error: AppColors.erro,
    onError: AppColors.sobrePrimaria,
    surface: AppColors.superficie,
    onSurface: AppColors.tinta,
    onSurfaceVariant: AppColors.textoSuave,
    outline: AppColors.linha,
  );

  return ThemeData(
    useMaterial3: true,
    platform: TargetPlatform.iOS,
    fontFamily: AppTypography.familia,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.fundo,
    textTheme: AppTypography.textTheme,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    cupertinoOverrideTheme: CupertinoThemeData(
      primaryColor: AppColors.azulMarca,
      primaryContrastingColor: AppColors.sobrePrimaria,
      scaffoldBackgroundColor: AppColors.fundo,
      barBackgroundColor: AppColors.fundo, // opaco: sem blur
      textTheme: CupertinoTextThemeData(
        primaryColor: AppColors.azulMarca,
        textStyle: AppTypography.body.copyWith(color: AppColors.tinta, inherit: false),
        actionTextStyle: AppTypography.body.copyWith(
          color: AppColors.linkSobreSuperficie,
          inherit: false,
        ),
        navActionTextStyle: AppTypography.body.copyWith(color: AppColors.navy, inherit: false),
        navTitleTextStyle: AppTypography.headline.copyWith(color: AppColors.tinta, inherit: false),
        navLargeTitleTextStyle: AppTypography.largeTitle.copyWith(
          color: AppColors.tinta,
          inherit: false,
        ),
      ),
    ),
    dividerTheme: const DividerThemeData(
      thickness: AppSpacing.divisoria,
      space: AppSpacing.divisoria,
      color: AppColors.linha,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.tinta,
      contentTextStyle: AppTypography.subheadline.copyWith(color: AppColors.sobrePrimaria),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.raioCard)),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.azulMarca,
      linearTrackColor: AppColors.menta,
      linearMinHeight: 4,
    ),
  );
}

/// Rolagem elástica no Android + arraste com mouse/trackpad na web (carrosséis).
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.unknown,
      };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) =>
      child;
}
