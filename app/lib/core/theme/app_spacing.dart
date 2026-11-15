/// Espaços, raios e tamanhos (skill apple-style-flutter, seções 5 e 6).
abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const margem = 16.0; // margem lateral
  static const margemLarga = 20.0; // telas largas
  static const secao = 24.0; // entre seções agrupadas
  static const secaoGrande = 32.0;

  static const raioCelula = 12.0;
  static const raioCampo = 10.0;
  static const raioAviso = 14.0;
  static const raioFolha = 16.0;

  static const alturaBotao = 50.0;
  static const raioBotao = alturaBotao / 2; // cápsula
  static const toqueMinimo = 48.0; // Android exige mais que os 44 pt do iOS

  static const icone = 24.0;
  static const iconeEstadoVazio = 48.0;
  static const divisoria = 0.5;

  static const larguraTelaLarga = 600.0;
}

/// Durações (skill apple-style-flutter, seção 8).
abstract final class AppDurations {
  static const toque = Duration(milliseconds: 150);
  static const etapa = Duration(milliseconds: 250);
  static const folha = Duration(milliseconds: 350);
}
