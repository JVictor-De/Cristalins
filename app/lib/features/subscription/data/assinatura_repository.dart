import 'package:dio/dio.dart';

import '../../../core/formatacao.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_erro.dart';
import '../../catalog/data/catalogo_repository.dart';
import '../../catalog/domain/catalogo.dart';
import '../domain/assinatura.dart';
import '../domain/pagamento.dart';

abstract final class AssinaturaJson {
  static Assinatura assinatura(Map<String, dynamic> j) {
    final endereco = j['endereco'] as Map<String, dynamic>;
    return Assinatura(
      id: j['id'] as String,
      status: j['status'] as String,
      plano: j['plano'] as String,
      frequencia: j['frequencia'] as String,
      janela: j['janela'] as String,
      itens: (j['itens'] as List).map((e) => CatalogoJson.item(e as Map<String, dynamic>)).toList(),
      bairro: endereco['bairro'] as String,
      zona: endereco['zona'] as String,
      proximaEntrega: j['proximaEntrega'] as String?,
      fimCompromisso: j['fimCompromisso'] as String?,
      cupom: j['cupom'] as String?,
    );
  }

  static Ciclo ciclo(Map<String, dynamic> j) => Ciclo(
    id: j['id'] as String,
    numero: j['numero'] as int,
    dataEntrega: j['dataEntrega'] as String,
    dataCorte: j['dataCorte'] as String,
    status: j['status'] as String,
    itens: (j['itens'] as List).map((e) => CatalogoJson.item(e as Map<String, dynamic>)).toList(),
    valor: j['valor'] == null ? null : Dinheiro.daApi(j['valor'] as num),
    motivoPulo: j['motivoPulo'] as String?,
  );
}

abstract final class PagamentoJson {
  static Fatura fatura(Map<String, dynamic> j) => Fatura(
    id: j['id'] as String,
    cicloNumero: j['cicloNumero'] as int,
    dataEntrega: j['dataEntrega'] as String,
    forma: FormaPagamento.de(j['forma'] as String),
    valor: Dinheiro.daApi(j['valor'] as num),
    vencimento: j['vencimento'] as String,
    status: j['status'] as String,
    link: j['link'] as String?,
    temComprovante: j['temComprovante'] as bool? ?? false,
    observacao: j['observacao'] as String?,
  );

  static CartaoSalvo cartao(Map<String, dynamic> j) => CartaoSalvo(
    id: j['id'] as String? ?? '',
    bandeira: j['bandeira'] as String,
    final4: j['final'] as String,
  );

  static FormaAtual forma(Map<String, dynamic> j) {
    final cartao = j['cartao'] as Map<String, dynamic>?;
    return FormaAtual(
      forma: FormaPagamento.de(j['formaPagamento'] as String),
      cartao: cartao == null ? null : PagamentoJson.cartao(cartao),
    );
  }
}

/// Rotas de assinatura. Pausa, corte, pulo e preço são decididos pela API.
class AssinaturaRepository {
  AssinaturaRepository(this._api);

  final ApiClient _api;

  Future<List<Assinatura>> listar() => _chamar(() async {
    final r = await _api.dio.get<List<dynamic>>('/assinaturas');
    return r.data!.map((e) => AssinaturaJson.assinatura(e as Map<String, dynamic>)).toList();
  });

  Future<Assinatura> buscar(String id) => _chamar(() async {
    final r = await _api.dio.get<Map<String, dynamic>>('/assinaturas/$id');
    return AssinaturaJson.assinatura(r.data!);
  });

  Future<List<Ciclo>> ciclos(String id) => _chamar(() async {
    final r = await _api.dio.get<List<dynamic>>('/assinaturas/$id/ciclos');
    return r.data!.map((e) => AssinaturaJson.ciclo(e as Map<String, dynamic>)).toList();
  });

  Future<AssinaturaCriada> criar(PedidoAssinatura pedido, {required String plano, String? cupom}) =>
      _chamar(() async {
        // Assinar chama Asaas (cliente + Pix + QR); 15s do ApiClient estoura fácil no Safari.
        final r = await _api.dio.post<Map<String, dynamic>>(
          '/assinaturas',
          data: {
            'itens': pedido.itens.map(CatalogoJson.itemParaJson).toList(),
            'frequencia': pedido.frequencia,
            'plano': plano,
            'enderecoId': pedido.endereco!.id,
            'janela': pedido.janela.valor,
            'formaPagamento': 'PIX',
            'recomendacaoId': ?pedido.recomendacaoId,
            if (cupom != null && cupom.isNotEmpty) 'cupom': cupom,
          },
          options: Options(receiveTimeout: const Duration(seconds: 45)),
        );
        final ciclo = r.data!['ciclo'] as Map<String, dynamic>;
        final pix = ciclo['pix'] as Map<String, dynamic>?;
        return AssinaturaCriada(
          id: r.data!['id'] as String,
          valorPrimeiroCiclo: Dinheiro.daApi(ciclo['valor'] as num),
          dataEntrega: ciclo['dataEntrega'] as String,
          vencimento: ciclo['vencimento'] as String?,
          pix: pix == null
              ? null
              : PixCobranca(
                  // Web/Safari: campos ausentes não podem derrubar o cast e virar erro genérico.
                  copiaECola: pix['copiaECola'] as String? ?? '',
                  qrCodeBase64: pix['qrCodeBase64'] as String? ?? '',
                ),
        );
      });

  /// Devolve a data da entrega a partir da qual a alteração vale (RN09, decidido pela API).
  Future<String> alterarCesta(String id, List<ItemCesta> itens) => _chamar(() async {
    final r = await _api.dio.put<Map<String, dynamic>>(
      '/assinaturas/$id',
      data: {'itens': itens.map(CatalogoJson.itemParaJson).toList()},
    );
    return (r.data!['aplicadaAPartirDe'] as Map<String, dynamic>)['dataEntrega'] as String;
  });

  Future<void> pausar(String id, int ciclos) =>
      _chamar(() => _api.dio.post<dynamic>('/assinaturas/$id/pausar', data: {'ciclos': ciclos}));

  Future<void> retomar(String id) =>
      _chamar(() => _api.dio.post<dynamic>('/assinaturas/$id/retomar'));

  Future<void> pularEntrega(String id) =>
      _chamar(() => _api.dio.post<dynamic>('/assinaturas/$id/pular-entrega'));

  Future<Cancelamento> cancelar(String id) => _chamar(() async {
    final r = await _api.dio.delete<Map<String, dynamic>>('/assinaturas/$id');
    return Cancelamento(
      diferencaCompromisso: Dinheiro.daApi(r.data!['diferencaCompromisso'] as num),
    );
  });

  // --- cr-5-cobranca: faturas, cartão e forma de pagamento ---

  Future<List<Fatura>> faturas() => _chamar(() async {
    final r = await _api.dio.get<List<dynamic>>('/faturas');
    return r.data!.map((e) => PagamentoJson.fatura(e as Map<String, dynamic>)).toList();
  });

  /// Link do comprovante (Asaas) de uma fatura paga.
  Future<String> comprovante(String faturaId) => _chamar(() async {
    final r = await _api.dio.get<Map<String, dynamic>>('/faturas/$faturaId/comprovante');
    return r.data!['url'] as String;
  });

  Future<List<CartaoSalvo>> cartoes() => _chamar(() async {
    final r = await _api.dio.get<List<dynamic>>('/cartoes');
    return r.data!.map((e) => PagamentoJson.cartao(e as Map<String, dynamic>)).toList();
  });

  /// Envia os dados à API, que tokeniza no Asaas. O app não guarda nada do que foi digitado.
  Future<CartaoSalvo> cadastrarCartao(DadosCartao dados) => _chamar(() async {
    final r = await _api.dio.post<Map<String, dynamic>>('/cartoes', data: dados.paraJson());
    return PagamentoJson.cartao(r.data!);
  });

  Future<FormaAtual> formaPagamento(String assinaturaId) => _chamar(() async {
    final r = await _api.dio.get<Map<String, dynamic>>(
      '/assinaturas/$assinaturaId/forma-pagamento',
    );
    return PagamentoJson.forma(r.data!);
  });

  Future<FormaAtual> trocarForma(String assinaturaId, FormaPagamento forma, {String? cartaoId}) =>
      _chamar(() async {
        final r = await _api.dio.put<Map<String, dynamic>>(
          '/assinaturas/$assinaturaId/forma-pagamento',
          data: {'formaPagamento': forma.valor, 'cartaoId': ?cartaoId},
        );
        return PagamentoJson.forma(r.data!);
      });

  Future<T> _chamar<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } catch (e) {
      throw ApiErro.de(e);
    }
  }
}
