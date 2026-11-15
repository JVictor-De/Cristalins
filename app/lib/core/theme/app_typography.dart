import 'package:flutter/material.dart';

/// Escala tipográfica da HIG em Inter (skill apple-style-flutter, seção 4).
abstract final class AppTypography {
  static const familia = 'Inter';

  static TextStyle _estilo(double tamanho, double altura, FontWeight peso, double espacamento) {
    return TextStyle(
      fontFamily: familia,
      fontSize: tamanho,
      height: altura / tamanho,
      fontWeight: peso,
      letterSpacing: espacamento,
    );
  }

  static final largeTitle = _estilo(34, 41, FontWeight.w700, -0.6);
  static final title1 = _estilo(28, 34, FontWeight.w700, -0.4);
  static final title2 = _estilo(22, 28, FontWeight.w700, -0.3);
  static final title3 = _estilo(20, 25, FontWeight.w600, -0.2);
  static final headline = _estilo(17, 22, FontWeight.w600, -0.2);
  static final body = _estilo(17, 22, FontWeight.w400, -0.2);
  static final callout = _estilo(16, 21, FontWeight.w400, -0.1);
  static final subheadline = _estilo(15, 20, FontWeight.w400, -0.1);
  static final footnote = _estilo(13, 18, FontWeight.w400, 0);
  static final caption1 = _estilo(12, 16, FontWeight.w400, 0);
  static final caption2 = _estilo(11, 13, FontWeight.w500, 0.1);

  /// Mapeia a escala da Apple para os papéis do Material.
  /// `bodyMedium` é o estilo padrão de `Text`, por isso recebe `body`.
  static TextTheme get textTheme => TextTheme(
    displaySmall: largeTitle,
    headlineMedium: title1,
    headlineSmall: title2,
    titleLarge: title3,
    titleMedium: headline,
    titleSmall: subheadline,
    bodyLarge: body,
    bodyMedium: body,
    bodySmall: footnote,
    labelLarge: headline,
    labelMedium: caption1,
    labelSmall: caption2,
  );
}
