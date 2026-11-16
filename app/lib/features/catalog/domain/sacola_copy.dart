import '../../../core/formatacao.dart';
import 'catalogo.dart';

/// Copy e formatação compartilhadas entre [SacolaScreen] e [BarraSacola] (P3.12).
abstract final class SacolaCopy {
  static String itens(int n) => '$n ${n == 1 ? 'item' : 'itens'}';

  /// Ex.: `12 itens · R$ 36,30 por entrega` — mesma fonte [Simulacao.total].formatado.
  static String itensETotalPorEntrega(int n, Dinheiro total) =>
      '${itens(n)} · ${total.formatado} por entrega';

  /// Só o valor + “por entrega” (rodapé da Sacola).
  static String totalPorEntrega(Dinheiro total) => '${total.formatado} por entrega';

  /// Subtotal da linha a partir do unitário da API × qty (exibição; sem regra de preço).
  static Dinheiro subtotalLinha(ItemSimulado item) =>
      Dinheiro(item.precoUnitario.centavos * item.quantidade);

  /// ≈/mês a partir de [total] da simulação × entregas no mês (UI; ver DECISOES P3).
  static String? aproximadoMes(Dinheiro totalPorEntrega, String frequencia) {
    final mult = switch (frequencia) {
      'SEMANAL' => 4,
      'QUINZENAL' => 2,
      'MENSAL' => 1,
      _ => null,
    };
    if (mult == null) return null;
    return '≈ ${Dinheiro(totalPorEntrega.centavos * mult).formatado}/mês';
  }
}
