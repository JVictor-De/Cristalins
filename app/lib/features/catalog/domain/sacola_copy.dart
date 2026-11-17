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

  /// Hint de frete grátis (RN18) com valores **da simulação**; `null` se já grátis.
  /// Ex.: `Faltam R$ 120,00 para frete grátis`.
  static String? faltaFreteGratis(Simulacao sim) => sim.faltaParaFreteGratis > 0
      ? 'Faltam ${Dinheiro.daApi(sim.faltaParaFreteGratis).formatado} para frete grátis'
      : null;

  /// Hint estático (sem simulação): limite da RN18, vindo da API quando houver simulação.
  static String freteGratisAcima(num limite) =>
      'Frete grátis acima de ${Dinheiro.daApi(limite).formatado} por entrega';

  /// P3.1: erro no card do SKU. Só cita os dois produtos quando **ambos** estão na sacola.
  static String faltaCaixa({required int falta, required int tamanho, required bool mista}) {
    final g = falta == 1 ? 'garrafa' : 'garrafas';
    final base = 'Faltam $falta $g para completar a caixa de $tamanho';
    return mista ? '$base (Water Protein + Flow Fiber juntos).' : '$base.';
  }

  /// P3.1: motivo ao lado do “Continuar” quando bloqueado.
  static const motivoCaixaIncompleta = 'Complete a caixa para continuar.';
  static const motivoMinimo = 'Falta um pouco para o mínimo da assinatura.';

  /// P3.2: copy real dos planos (Anexo: Flex sem fidelidade; Trimestral 3 meses, 7%, RN13).
  static String descricaoPlano(String plano) => switch (plano) {
    'TRIMESTRAL' =>
      'Compromisso de 3 meses com 7% de desconto. Se cancelar antes, paga só a diferença do desconto.',
    _ => 'Sem fidelidade: cancele quando quiser, sem multa.',
  };

  /// Economia do Trimestral por entrega (valor da simulação).
  static String? economiaTrimestral(num economia) => economia > 0
      ? 'Economize ${Dinheiro.daApi(economia).formatado} por entrega no Trimestral'
      : null;

  /// P3.3: datas sem inventar (a API só dá datas no passo de entrega/pagamento).
  static const proximoPasso = 'Data da 1ª entrega e da cobrança: você confirma no próximo passo.';

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
