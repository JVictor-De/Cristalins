import '../features/address/data/endereco_repository.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/catalog/data/catalogo_repository.dart';
import '../features/ocorrencias/data/ocorrencia_repository.dart';
import '../features/quiz/data/recomendacao_repository.dart';
import '../features/subscription/data/assinatura_repository.dart';
import 'config/app_config.dart';
import 'intents/abridor_links.dart';
import 'intents/compartilhador.dart';
import 'network/api_client.dart';
import 'network/sessao.dart';
import 'push/push_registro.dart';

/// Tudo que as telas usam de fora. Em testes, troque por implementações falsas.
class Dependencias {
  Dependencias({
    required this.auth,
    required this.recomendacoes,
    required this.catalogo,
    required this.enderecos,
    required this.assinaturas,
    required this.ocorrencias,
    this.links = const AbridorLinks(),
    this.compartilhador = const Compartilhador(),
    this.push = const PushRegistro(),
    this.api,
  });

  factory Dependencias.reais(AppConfig config, {ArmazenamentoTokens? tokens, AbridorLinks? links}) {
    final api = ApiClient(config, tokens: tokens ?? ArmazenamentoSeguro());
    return Dependencias(
      api: api,
      auth: AuthRepository(api),
      recomendacoes: RecomendacaoRepository(api),
      catalogo: CatalogoRepository(api),
      enderecos: EnderecoRepository(api),
      assinaturas: AssinaturaRepository(api),
      ocorrencias: OcorrenciaRepository(api),
      links: links ?? const AbridorLinks(),
    );
  }

  final AuthRepository auth;
  final RecomendacaoRepository recomendacoes;
  final CatalogoRepository catalogo;
  final EnderecoRepository enderecos;
  final AssinaturaRepository assinaturas;
  final OcorrenciaRepository ocorrencias;
  final AbridorLinks links;
  final Compartilhador compartilhador;
  final PushRegistro push;

  /// Cliente HTTP real (nulo nos testes com repositórios falsos).
  final ApiClient? api;
}
