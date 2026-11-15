import '../../../core/formatacao.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_erro.dart';
import '../../catalog/data/catalogo_repository.dart';
import '../../catalog/domain/catalogo.dart';
import '../domain/assinatura.dart';

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
        );
        final ciclo = r.data!['ciclo'] as Map<String, dynamic>;
        return AssinaturaCriada(
          id: r.data!['id'] as String,
          valorPrimeiroCiclo: Dinheiro.daApi(ciclo['valor'] as num),
          dataEntrega: ciclo['dataEntrega'] as String,
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

  Future<T> _chamar<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } catch (e) {
      throw ApiErro.de(e);
    }
  }
}
