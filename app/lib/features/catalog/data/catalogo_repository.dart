import '../../../core/formatacao.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_erro.dart';
import '../domain/catalogo.dart';

/// Mapeamento JSON ↔ domínio do catálogo (camada data).
abstract final class CatalogoJson {
  static ItemCesta item(Map<String, dynamic> j) =>
      ItemCesta(j['produto'] as String, j['quantidade'] as int);

  static Map<String, dynamic> itemParaJson(ItemCesta i) => {
    'produto': i.produto,
    'quantidade': i.quantidade,
  };

  static Produto produto(Map<String, dynamic> j) => Produto(
    codigo: j['codigo'] as String,
    nome: j['nome'] as String,
    tipo: j['tipo'] as String,
    volumeMl: j['volumeMl'] as int,
    embalagemQtd: j['embalagemQtd'] as int,
    precoBase: Dinheiro.daApi(j['precoBase'] as num),
  );

  static Kit kit(Map<String, dynamic> j) => Kit(
    codigo: j['codigo'] as String,
    nome: j['nome'] as String,
    itens: (j['itens'] as List).map((e) => item(e as Map<String, dynamic>)).toList(),
    subtotalBase: Dinheiro.daApi(j['subtotalBase'] as num),
  );

  static LinhaPreco linha(Map<String, dynamic> j) => LinhaPreco(
    fator: j['fator'] as String,
    percentual: j['percentual'] as num?,
    valor: j['valor'] == null ? null : Dinheiro.daApi(j['valor'] as num),
  );

  static Simulacao simulacao(Map<String, dynamic> j) => Simulacao(
    itens: (j['itens'] as List)
        .map((e) => e as Map<String, dynamic>)
        .map(
          (e) => ItemSimulado(
            produto: e['produto'] as String,
            quantidade: e['quantidade'] as int,
            precoUnitario: Dinheiro.daApi(e['precoUnitario'] as num),
          ),
        )
        .toList(),
    ue: j['ue'] as num,
    subtotal: Dinheiro.daApi(j['subtotal'] as num),
    frete: Dinheiro.daApi(j['frete'] as num),
    total: Dinheiro.daApi(j['total'] as num),
    detalhe: (j['detalhePreco'] as List).map((e) => linha(e as Map<String, dynamic>)).toList(),
    zona: (j['zona'] as Map<String, dynamic>?)?['nome'] as String?,
  );
}

/// `GET /produtos`, `GET /kits`, `POST /precos/simular`. O app nunca calcula preço.
class CatalogoRepository {
  CatalogoRepository(this._api);

  final ApiClient _api;

  Future<List<Produto>> produtos() async {
    try {
      final r = await _api.dio.get<List<dynamic>>('/produtos');
      return r.data!.map((e) => CatalogoJson.produto(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ApiErro.de(e);
    }
  }

  Future<List<Kit>> kits() async {
    try {
      final r = await _api.dio.get<List<dynamic>>('/kits');
      return r.data!.map((e) => CatalogoJson.kit(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ApiErro.de(e);
    }
  }

  Future<Simulacao> simular({
    required List<ItemCesta> itens,
    required String frequencia,
    required String plano,
    String? enderecoId,
    String? cupom,
  }) async {
    try {
      final r = await _api.dio.post<Map<String, dynamic>>(
        '/precos/simular',
        data: {
          'itens': itens.map(CatalogoJson.itemParaJson).toList(),
          'frequencia': frequencia,
          'plano': plano,
          'enderecoId': ?enderecoId,
          if (cupom != null && cupom.isNotEmpty) 'cupom': cupom,
        },
      );
      return CatalogoJson.simulacao(r.data!);
    } catch (e) {
      throw ApiErro.de(e);
    }
  }
}
