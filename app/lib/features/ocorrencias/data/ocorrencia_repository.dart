import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_erro.dart';
import '../domain/ocorrencia.dart';

/// `POST /ocorrencias` (multipart) e `GET /ocorrencias`.
class OcorrenciaRepository {
  OcorrenciaRepository(this._api);

  final ApiClient _api;

  Future<OcorrenciaCriada> criar({
    required String cicloId,
    required String tipo,
    required String produto,
    required int quantidade,
    required String solucao,
    required String caminhoFoto,
  }) async {
    try {
      final form = FormData.fromMap({
        'cicloId': cicloId,
        'tipo': tipo,
        'produto': produto,
        'quantidade': quantidade,
        'solucao': solucao,
        'foto': await MultipartFile.fromFile(caminhoFoto, filename: 'foto.jpg'),
      });
      final r = await _api.dio.post<Map<String, dynamic>>('/ocorrencias', data: form);
      return _deJson(r.data!);
    } catch (e) {
      throw ApiErro.de(e);
    }
  }

  Future<List<OcorrenciaCriada>> listar() async {
    try {
      final r = await _api.dio.get<List<dynamic>>('/ocorrencias');
      return (r.data ?? []).map((e) => _deJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ApiErro.de(e);
    }
  }

  OcorrenciaCriada _deJson(Map<String, dynamic> j) => OcorrenciaCriada(
    id: j['id'] as String,
    tipo: j['tipo'] as String,
    produto: j['produto'] as String,
    quantidade: j['quantidade'] as int,
    solucao: j['solucao'] as String,
    status: j['status'] as String,
    temFoto: j['temFoto'] as bool? ?? false,
    credito: (j['credito'] as num?)?.toDouble(),
  );
}
