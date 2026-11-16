/// Espaços, raios e tamanhos (marketplace + legado).
abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const margem = 16.0;
  static const margemLarga = 20.0;
  static const secao = 24.0;
  static const secaoGrande = 32.0;

  /// Card marketplace (CSS `--radius: 24px`).
  static const raioCard = 24.0;

  /// Botão marketplace (não cápsula).
  static const raioBotao = 16.0;

  /// Chip / pílula.
  static const raioChip = 999.0;

  static const raioCelula = 12.0;
  static const raioCampo = 16.0;
  static const raioAviso = 14.0;
  static const raioFolha = 24.0;

  static const alturaBotao = 50.0;
  static const toqueMinimo = 48.0;

  static const icone = 24.0;
  static const iconePequeno = 18.0;
  static const iconeEstadoVazio = 48.0;
  static const iconeProduto = 40.0;
  static const divisoria = 0.5;

  static const botaoCircular = 32.0;
  static const raioSelo = 6.0;
  static const imagemProduto = 72.0;
  static const alturaFolhaPicker = 300.0;
  static const alturaItemPicker = 40.0;
  static const barraProgresso = 4.0;
  static const larguraRotuloCampo = 104.0;

  static const larguraTelaLarga = 600.0;
}

/// Durações de movimento (respeitar reduzir movimento nas telas).
abstract final class AppDurations {
  static const toque = Duration(milliseconds: 150);
  static const etapa = Duration(milliseconds: 250);
  static const folha = Duration(milliseconds: 350);
}
