import 'package:flutter/painting.dart';

/// Sombras do redesign marketplace (CSS `--shadow` do site).
abstract final class AppSombras {
  /// `0 18px 50px rgba(7,59,83,.12)` — cards e folhas.
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color.fromRGBO(7, 59, 83, 0.12),
      offset: Offset(0, 18),
      blurRadius: 50,
    ),
  ];
}
