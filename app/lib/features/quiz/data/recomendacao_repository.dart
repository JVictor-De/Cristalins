import '../../../core/formatacao.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_erro.dart';
import '../../catalog/data/catalogo_repository.dart';
import '../domain/quiz.dart';

abstract final class RecomendacaoJson {
  static Recomendacao de(Map<String, dynamic> j) {
    final contato = j['contatoComercial'] as Map<String, dynamic>?;
    return Recomendacao(
      id: j['id'] as String,
      kit: j['kit'] as String?,
      multiplicador: j['multiplicador'] as int,
      frequencia: j['frequencia'] as String,
      itens: (j['itens'] as List).map((e) => CatalogoJson.item(e as Map<String, dynamic>)).toList(),
      ue: j['ue'] as num,
      valorEstimado: j['valorEstimado'] == null ? null : Dinheiro.daApi(j['valorEstimado'] as num),
      perfilEmpresa: j['perfilEmpresa'] as bool,
      contatoEmail: contato?['email'] as String?,
      contatoTelefone: contato?['telefone'] as String?,
    );
  }

  static Map<String, dynamic> respostas(RespostasQuiz r) => {
    'objetivo': r.objetivo,
    'diasSemana': r.diasSemana,
    'pessoas': r.pessoas,
    'flowFiber': r.flowFiber,
    'comGas': r.comGas,
  };
}

/// `POST /recomendacoes`, `GET /recomendacoes/{id}`. O cálculo do quiz é todo da API.
class RecomendacaoRepository {
  RecomendacaoRepository(this._api);

  final ApiClient _api;

  Future<Recomendacao> recomendar(RespostasQuiz respostas) async {
    try {
      final r = await _api.dio.post<Map<String, dynamic>>(
        '/recomendacoes',
        data: RecomendacaoJson.respostas(respostas),
      );
      return RecomendacaoJson.de(r.data!);
    } catch (e) {
      throw ApiErro.de(e);
    }
  }

  Future<Recomendacao> buscar(String id) async {
    try {
      final r = await _api.dio.get<Map<String, dynamic>>('/recomendacoes/$id');
      return RecomendacaoJson.de(r.data!);
    } catch (e) {
      throw ApiErro.de(e);
    }
  }
}
