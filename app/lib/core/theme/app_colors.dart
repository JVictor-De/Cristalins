import 'package:flutter/painting.dart';

/// Cores da marca Cristalins (CONTEXTO.md, seção Cores).
///
/// Contraste: texto branco sobre [azul800] e [azul500]; [azul900] sobre
/// [amareloFlow]; link [azul500] só sobre branco; sobre [fundoAgrupado], [azul700].
/// No máximo um amarelo por tela. Sem sombra, sem gradiente.
abstract final class AppColors {
  static const azul900 = Color(0xFF04263A);
  static const azul800 = Color(0xFF073B53); // primária
  static const azul700 = Color(0xFF0B4F6E);
  static const azul500 = Color(0xFF1A7BA3);
  static const azul300 = Color(0xFF7FB8D1);
  static const azul100 = Color(0xFFD9ECF4);
  static const azul50 = Color(0xFFF2F8FB);
  static const fundoAgrupado = Color(0xFFF2F5F7);
  static const superficie = Color(0xFFFFFFFF);
  static const amareloFlow = Color(0xFFF5C518);
  static const texto = Color(0xFF1A1A1A);
  static const textoSecundario = Color(0xFF4A5A63);
  static const borda = Color(0xFFD5DDE2);
  static const sucesso = Color(0xFF2E7D32);
  static const alerta = Color(0xFFB54708);
  static const erro = Color(0xFFC62828);

  /// Texto sobre fundos escuros da marca ([azul800], [azul500]).
  static const sobrePrimaria = Color(0xFFFFFFFF);

  /// Link/ação de texto conforme o fundo (regra de contraste acima).
  static const linkSobreSuperficie = azul500;
  static const linkSobreFundoAgrupado = azul700;
}
