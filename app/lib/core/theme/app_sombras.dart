import 'package:flutter/painting.dart';

/// Sombras do redesign marketplace (CSS `--shadow` do site).
abstract final class AppSombras {
  /// `0 18px 50px rgba(7,59,83,.12)` — folhas, entrega, barras elevadas.
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color.fromRGBO(7, 59, 83, 0.12),
      offset: Offset(0, 18),
      blurRadius: 50,
    ),
  ];

  /// Sombra elíptica de contato sob a garrafa (card foto-âncora): blur 12, α 0,12.
  static const List<BoxShadow> garrafaContato = [
    BoxShadow(
      color: Color.fromRGBO(11, 46, 63, 0.12),
      blurRadius: 12,
    ),
  ];

  /// Grade de produtos/kits — menos densidade visual na home e aba.
  static const List<BoxShadow> cardGrade = [
    BoxShadow(
      color: Color.fromRGBO(7, 59, 83, 0.06),
      offset: Offset(0, 8),
      blurRadius: 24,
    ),
  ];
}
