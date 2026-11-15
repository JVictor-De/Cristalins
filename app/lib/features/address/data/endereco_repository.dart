import '../../../core/formatacao.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_erro.dart';
import '../domain/endereco.dart';

abstract final class EnderecoJson {
  static ZonaEntrega zona(Map<String, dynamic> j) => ZonaEntrega(
    id: j['id'] as String,
    nome: j['nome'] as String,
    taxa: Dinheiro.daApi(j['taxaEntrega'] as num),
    dias: (j['diasEntrega'] as List).cast<String>(),
  );

  static CepConsultado cep(Map<String, dynamic> j) => CepConsultado(
    cep: j['cep'] as String,
    logradouro: j['logradouro'] as String,
    bairro: j['bairro'] as String,
    zona: zona(j['zona'] as Map<String, dynamic>),
  );

  static Endereco endereco(Map<String, dynamic> j) => Endereco(
    id: j['id'] as String,
    cep: j['cep'] as String,
    logradouro: j['logradouro'] as String,
    numero: j['numero'] as String,
    bairro: j['bairro'] as String,
    zona: zona(j['zona'] as Map<String, dynamic>),
    principal: j['principal'] as bool,
    apelido: j['apelido'] as String?,
    complemento: j['complemento'] as String?,
  );
}

class NovoEndereco {
  const NovoEndereco({
    required this.cep,
    required this.numero,
    this.complemento,
    this.apelido,
    this.referencia,
    this.instrucoes,
  });

  final String cep;
  final String numero;
  final String? complemento;
  final String? apelido;
  final String? referencia;
  final String? instrucoes;

  Map<String, dynamic> toJson() {
    String? vazioNulo(String? v) => v == null || v.trim().isEmpty ? null : v.trim();
    return {
      'cep': cep,
      'numero': numero.trim(),
      'complemento': ?vazioNulo(complemento),
      'apelido': ?vazioNulo(apelido),
      'referencia': ?vazioNulo(referencia),
      'instrucoes': ?vazioNulo(instrucoes),
    };
  }
}

/// `GET /cep/{cep}`, `GET/POST /enderecos`, `POST /lista-espera`.
class EnderecoRepository {
  EnderecoRepository(this._api);

  final ApiClient _api;

  Future<CepConsultado> consultarCep(String cep) => _chamar(() async {
    final r = await _api.dio.get<Map<String, dynamic>>('/cep/$cep');
    return EnderecoJson.cep(r.data!);
  });

  Future<List<Endereco>> listar() => _chamar(() async {
    final r = await _api.dio.get<List<dynamic>>('/enderecos');
    return r.data!.map((e) => EnderecoJson.endereco(e as Map<String, dynamic>)).toList();
  });

  Future<Endereco> criar(NovoEndereco novo) => _chamar(() async {
    final r = await _api.dio.post<Map<String, dynamic>>('/enderecos', data: novo.toJson());
    return EnderecoJson.endereco(r.data!);
  });

  Future<void> entrarNaListaDeEspera({
    required String email,
    required String cep,
    String? bairro,
  }) => _chamar(() async {
    await _api.dio.post<dynamic>(
      '/lista-espera',
      data: {'email': email, 'cep': cep, 'bairro': ?bairro},
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
