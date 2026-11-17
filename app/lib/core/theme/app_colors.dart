import 'package:flutter/painting.dart';

/// Cores da marca Cristalins — tokens marketplace (site + CONTEXTO).
///
/// Contraste AA: branco sobre [azulMarca]/~4,51) e [navy]; [tinta]/[navy] sobre
/// [lima]/[amareloFlow]/[aqua]. Nunca texto branco sobre lima ou amarelo.
/// Gradiente só em hero/banner; sombra via [AppSombras].
abstract final class AppColors {
  // --- Marketplace (CSS cristalins.com.br) ---
  /// Títulos, tab ativa, botão escuro (= [azul800]).
  static const navy = Color(0xFF073B53);
  static const azul800 = navy;

  /// CTA primária. Hex do site `#087FAE`; contraste branco ≈ 4,51 (AA).
  static const azulMarca = Color(0xFF087FAE);

  static const azulPetroleo = Color(0xFF087E9B);
  static const ceu = Color(0xFF9FE4FB);
  static const aqua = Color(0xFFBDE9E8);
  static const menta = Color(0xFFE9F7F3);

  /// Fundo de tela (home/shell) — off-white P1 `#F6F9FB`.
  static const fundo = Color(0xFFF6F9FB);

  /// Accent gelo (chips, progress, minis) — não usar como parede de tela.
  static const gelo = Color(0xFFEDF8FD);

  static const tinta = Color(0xFF17333D);
  static const textoSuave = Color(0xFF5C7076);
  static const linha = Color(0xFFD8E6E4);

  /// Família Water Protein (hero / chip / PDP) — não parede de card na grade.
  static const lima = Color(0xFFDCF078);

  /// Gradiente do hero WP (amostrado do mock: TL `#ECF7DB`, TR `#DAF0AC`, BR `#D1E99C`).
  static const heroGradienteInicio = Color(0xFFECF7DB);
  static const heroGradienteMeio = Color(0xFFE0F2B8);
  static const heroGradienteFim = Color(0xFFD1E99C);

  /// Tipografia / CTA no hero WP (sobre lima).
  static const heroNavy = Color(0xFF063A52);
  static const heroInk = Color(0xFF0B2E3F);
  static const heroVerdeTexto = Color(0xFF34503F);

  /// Fundo da cena de impacto (PDP águas minerais).
  static const impactoAgua = Color(0xFF43BDE6);

  /// Rótulo WP — média da tampa em `protein.webp` (rótulo iluminado ~`#9DE365`).
  static const verdeProtein = Color(0xFF95CC3C);

  /// Só Flow Fiber.
  static const amareloFlow = Color(0xFFF5C518);

  /// Badge contador sacola / “Novo” pontual.
  static const promo = Color(0xFFB51E2E);

  // --- Escala auxiliar (telas ainda não redesenhadas) ---
  static const azul900 = Color(0xFF04263A);
  static const azul700 = Color(0xFF0B4F6E);
  static const azul500 = Color(0xFF1A7BA3);
  static const azul300 = Color(0xFF7FB8D1);
  static const azul100 = Color(0xFFD9ECF4);
  static const azul50 = Color(0xFFF2F8FB);

  /// Alias legado → [fundo] (telas marketplace).
  static const fundoAgrupado = fundo;
  static const superficie = Color(0xFFFFFFFF);

  /// Texto principal (= [tinta]).
  static const texto = tinta;

  /// Texto secundário (= [textoSuave]).
  static const textoSecundario = textoSuave;

  /// Divisória (= [linha]).
  static const borda = linha;

  static const sucesso = Color(0xFF2E7D32);
  static const alerta = Color(0xFFB54708);
  static const erro = Color(0xFFC62828);

  /// Texto sobre CTA / fundos escuros da marca.
  static const sobrePrimaria = Color(0xFFFFFFFF);

  /// Link/ação: preferir [azulMarca] sobre superfície clara.
  static const linkSobreSuperficie = azulMarca;
  static const linkSobreFundoAgrupado = azul700;
}
