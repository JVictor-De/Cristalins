import 'package:cristalins_assinatura/app.dart';
import 'package:cristalins_assinatura/core/config/app_config.dart';
import 'package:cristalins_assinatura/core/dependencias.dart';
import 'package:cristalins_assinatura/core/formatacao.dart';
import 'package:cristalins_assinatura/core/intents/abridor_links.dart';
import 'package:cristalins_assinatura/core/intents/compartilhador.dart';
import 'package:cristalins_assinatura/core/network/api_erro.dart';
import 'package:cristalins_assinatura/features/address/data/endereco_repository.dart';
import 'package:cristalins_assinatura/features/address/domain/endereco.dart';
import 'package:cristalins_assinatura/features/auth/data/auth_repository.dart';
import 'package:cristalins_assinatura/features/catalog/data/catalogo_repository.dart';
import 'package:cristalins_assinatura/features/catalog/domain/catalogo.dart';
import 'package:cristalins_assinatura/features/ocorrencias/data/ocorrencia_repository.dart';
import 'package:cristalins_assinatura/features/ocorrencias/domain/ocorrencia.dart';
import 'package:cristalins_assinatura/features/quiz/data/recomendacao_repository.dart';
import 'package:cristalins_assinatura/features/quiz/domain/quiz.dart';
import 'package:cristalins_assinatura/features/subscription/data/assinatura_repository.dart';
import 'package:cristalins_assinatura/features/subscription/domain/assinatura.dart';
import 'package:cristalins_assinatura/features/subscription/domain/pagamento.dart';
import 'package:flutter/widgets.dart';

/// Repositórios falsos com os mesmos formatos da API (valores do Anexo: caso A, CT02).

const zonaSul = ZonaEntrega(
  id: 'zona-sul',
  nome: 'Zona Sul',
  taxa: Dinheiro(990),
  dias: ['SEG', 'QUA', 'SEX'],
);

const recomendacaoCasoA = Recomendacao(
  id: 'rec-1',
  kit: 'KIT-TREINO',
  multiplicador: 1,
  frequencia: 'QUINZENAL',
  itens: [ItemCesta('WP500', 12)],
  ue: 12,
  valorEstimado: Dinheiro(11880),
  perfilEmpresa: false,
);

class AuthFalso implements AuthRepository {
  int cadastros = 0;
  int logins = 0;
  ApiErro? erro;

  @override
  Future<void> cadastrar(DadosCadastro dados) async {
    if (erro != null) throw erro!;
    cadastros++;
  }

  @override
  Future<void> entrar(String email, String senha) async {
    if (erro != null) throw erro!;
    logins++;
  }

  @override
  Future<void> sair() async {}

  int exclusoes = 0;

  @override
  Future<void> excluirConta() async {
    if (erro != null) throw erro!;
    exclusoes++;
  }

  @override
  Future<String> esqueciSenha(String email) async {
    if (erro != null) throw erro!;
    return 'Se o e-mail tiver cadastro, enviamos um código para criar uma nova senha.';
  }

  @override
  Future<String> redefinirSenha({
    required String email,
    required String codigo,
    required String novaSenha,
  }) async {
    if (erro != null) throw erro!;
    return 'Senha alterada. Entre com a nova senha.';
  }
}

class OcorrenciasFalsas implements OcorrenciaRepository {
  final criadas = <OcorrenciaCriada>[];

  @override
  Future<OcorrenciaCriada> criar({
    required String cicloId,
    required String tipo,
    required String produto,
    required int quantidade,
    required String solucao,
    required String caminhoFoto,
  }) async {
    final o = OcorrenciaCriada(
      id: 'oc-${criadas.length + 1}',
      tipo: tipo,
      produto: produto,
      quantidade: quantidade,
      solucao: solucao,
      status: solucao == 'CREDITO' ? 'RESOLVIDA' : 'ABERTA',
      temFoto: true,
      credito: solucao == 'CREDITO' ? 19.8 : null,
    );
    criadas.add(o);
    return o;
  }

  @override
  Future<List<OcorrenciaCriada>> listar() async => List.of(criadas);
}

class RecomendacoesFalsas implements RecomendacaoRepository {
  RespostasQuiz? ultimas;
  Recomendacao recomendacao = recomendacaoCasoA;

  @override
  Future<Recomendacao> recomendar(RespostasQuiz respostas) async {
    ultimas = respostas;
    return recomendacao;
  }

  @override
  Future<Recomendacao> buscar(String id) async => recomendacao;
}

class CatalogoFalso implements CatalogoRepository {
  final simulacoes = <List<ItemCesta>>[];

  @override
  Future<List<Produto>> produtos() async => const [
    Produto(
      codigo: 'WP500',
      nome: 'Water Protein (água com colágeno)',
      tipo: 'PRINCIPAL',
      volumeMl: 500,
      embalagemQtd: 6,
      precoBase: Dinheiro(990),
    ),
    Produto(
      codigo: 'FF500',
      nome: 'Flow Fiber',
      tipo: 'PRINCIPAL',
      volumeMl: 500,
      embalagemQtd: 6,
      precoBase: Dinheiro(890),
    ),
    Produto(
      codigo: 'AMS500',
      nome: 'Água mineral sem gás',
      tipo: 'COMPLEMENTO',
      volumeMl: 500,
      embalagemQtd: 12,
      precoBase: Dinheiro(220),
    ),
    Produto(
      codigo: 'AMN5000',
      nome: 'Água mineral natural (galão)',
      tipo: 'COMPLEMENTO',
      volumeMl: 5000,
      embalagemQtd: 1,
      precoBase: Dinheiro(990),
    ),
    Produto(
      codigo: 'GUA2000',
      nome: 'Guaraná Cristalins',
      tipo: 'ADDON',
      volumeMl: 2000,
      embalagemQtd: 1,
      precoBase: Dinheiro(790),
    ),
  ];

  @override
  Future<List<Kit>> kits() async => const [
    Kit(
      codigo: 'KIT-TREINO',
      nome: 'Kit Treino',
      itens: [ItemCesta('WP500', 12)],
      subtotalBase: Dinheiro(11880),
    ),
    Kit(
      codigo: 'KIT-CASA',
      nome: 'Kit Casa',
      itens: [ItemCesta('WP500', 6), ItemCesta('AMN5000', 2)],
      subtotalBase: Dinheiro(7920),
    ),
  ];

  @override
  Future<Simulacao> simular({
    required List<ItemCesta> itens,
    required String frequencia,
    required String plano,
    String? enderecoId,
    String? cupom,
  }) async {
    simulacoes.add(itens);
    final ue = itens.fold<int>(0, (a, i) => a + i.quantidade);
    if (ue < 12) {
      throw const ApiErro(
        codigo: 'CESTA_ABAIXO_MINIMO',
        mensagem: 'A cesta precisa ter pelo menos 12 UE por entrega (sem contar o Guaraná).',
      );
    }
    final comFrete = enderecoId != null;
    return Simulacao(
      itens: [
        for (final i in itens)
          ItemSimulado(
            produto: i.produto,
            quantidade: i.quantidade,
            precoUnitario: const Dinheiro(990),
          ),
      ],
      ue: ue,
      subtotal: const Dinheiro(11880),
      frete: comFrete ? const Dinheiro(990) : const Dinheiro(0),
      total: comFrete ? const Dinheiro(12870) : const Dinheiro(11880),
      detalhe: [
        if (plano == 'TRIMESTRAL') const LinhaPreco(fator: 'COMPROMISSO', percentual: -7),
        if (comFrete) const LinhaPreco(fator: 'FRETE', valor: Dinheiro(990)),
      ],
      zona: comFrete ? 'Zona Sul' : null,
    );
  }
}

class EnderecosFalsos implements EnderecoRepository {
  final salvos = <Endereco>[];
  final listaDeEspera = <String>[];

  @override
  Future<CepConsultado> consultarCep(String cep) async {
    if (cep == '01310100') {
      throw const ApiErro(
        codigo: 'CEP_FORA_AREA',
        mensagem: 'Por enquanto entregamos só no município do Rio de Janeiro.',
      );
    }
    return const CepConsultado(
      cep: '22041001',
      logradouro: 'Avenida Nossa Senhora de Copacabana',
      bairro: 'Copacabana',
      zona: zonaSul,
    );
  }

  @override
  Future<List<Endereco>> listar() async => List.of(salvos);

  @override
  Future<Endereco> criar(NovoEndereco novo) async {
    final e = Endereco(
      id: 'end-${salvos.length + 1}',
      cep: novo.cep,
      logradouro: 'Avenida Nossa Senhora de Copacabana',
      numero: novo.numero,
      bairro: 'Copacabana',
      zona: zonaSul,
      principal: salvos.isEmpty,
      apelido: novo.apelido,
    );
    salvos.add(e);
    return e;
  }

  @override
  Future<void> entrarNaListaDeEspera({
    required String email,
    required String cep,
    String? bairro,
  }) async {
    listaDeEspera.add(email);
  }
}

class AssinaturasFalsas implements AssinaturaRepository {
  final assinaturas = <Assinatura>[];
  final chamadas = <String>[];

  Assinatura _nova(String id, PedidoAssinatura p, String plano) => Assinatura(
    id: id,
    status: 'AGUARDANDO_PAGAMENTO',
    plano: plano,
    frequencia: p.frequencia,
    janela: p.janela.valor,
    itens: p.itens,
    bairro: 'Copacabana',
    zona: 'Zona Sul',
    proximaEntrega: '2026-11-16',
  );

  /// Cenário: assinatura ativa já existente (login vai direto à Tela 8).
  void comAssinaturaAtiva() => assinaturas.add(
    const Assinatura(
      id: 'ass-1',
      status: 'ATIVA',
      plano: 'TRIMESTRAL',
      frequencia: 'QUINZENAL',
      janela: 'MANHA',
      itens: [ItemCesta('WP500', 24)],
      bairro: 'Copacabana',
      zona: 'Zona Sul',
      proximaEntrega: '2026-11-30',
      fimCompromisso: '2027-02-16',
    ),
  );

  @override
  Future<List<Assinatura>> listar() async => List.of(assinaturas);

  @override
  Future<Assinatura> buscar(String id) async => assinaturas.firstWhere((a) => a.id == id);

  @override
  Future<List<Ciclo>> ciclos(String id) async => [
    const Ciclo(
      id: 'c1',
      numero: 1,
      dataEntrega: '2026-11-16',
      dataCorte: '2026-11-15T02:59:59.999Z',
      status: 'PAGO',
      itens: [ItemCesta('WP500', 24)],
      valor: Dinheiro(21319),
    ),
    const Ciclo(
      id: 'c2',
      numero: 2,
      dataEntrega: '2026-11-30',
      dataCorte: '2026-11-29T02:59:59.999Z',
      status: 'AGENDADO',
      itens: [],
    ),
  ];

  @override
  Future<AssinaturaCriada> criar(
    PedidoAssinatura pedido, {
    required String plano,
    String? cupom,
  }) async {
    chamadas.add('criar');
    final id = 'ass-${assinaturas.length + 1}';
    assinaturas.add(_nova(id, pedido, plano));
    return AssinaturaCriada(
      id: id,
      valorPrimeiroCiclo: const Dinheiro(12870),
      dataEntrega: '2026-11-16',
    );
  }

  @override
  Future<String> alterarCesta(String id, List<ItemCesta> itens) async {
    chamadas.add('alterar');
    return '2026-11-30';
  }

  @override
  Future<void> pausar(String id, int ciclos) async => chamadas.add('pausar $ciclos');

  @override
  Future<void> retomar(String id) async => chamadas.add('retomar');

  @override
  Future<void> pularEntrega(String id) async => chamadas.add('pular');

  @override
  Future<Cancelamento> cancelar(String id) async {
    chamadas.add('cancelar');
    return const Cancelamento(diferencaCompromisso: Dinheiro(3060));
  }

  // cr-5-cobranca
  final faturasSalvas = <Fatura>[];
  final cartoesSalvos = <CartaoSalvo>[];
  var formaAtual = const FormaAtual(forma: FormaPagamento.pix);

  @override
  Future<List<Fatura>> faturas() async => List.of(faturasSalvas);

  @override
  Future<String> comprovante(String faturaId) async =>
      'https://fake.asaas.local/comprovantes/$faturaId';

  @override
  Future<List<CartaoSalvo>> cartoes() async => List.of(cartoesSalvos);

  /// Como a API: devolve só bandeira e final (nada do número fica neste fake).
  @override
  Future<CartaoSalvo> cadastrarCartao(DadosCartao dados) async {
    final cartao = CartaoSalvo(
      id: 'cartao-${cartoesSalvos.length + 1}',
      bandeira: 'VISA',
      final4: dados.numero.substring(dados.numero.length - 4),
    );
    cartoesSalvos.add(cartao);
    chamadas.add('cartao ${cartao.final4}');
    return cartao;
  }

  @override
  Future<FormaAtual> formaPagamento(String assinaturaId) async => formaAtual;

  @override
  Future<FormaAtual> trocarForma(
    String assinaturaId,
    FormaPagamento forma, {
    String? cartaoId,
  }) async {
    chamadas.add('forma ${forma.valor}');
    return formaAtual = FormaAtual(
      forma: forma,
      cartao: cartaoId == null ? null : cartoesSalvos.firstWhere((c) => c.id == cartaoId),
    );
  }
}

class LinksFalsos extends AbridorLinks {
  final abertos = <String>[];

  @override
  Future<bool> abrir(String url) async {
    abertos.add(url);
    return true;
  }
}

class CompartilhadorFalso extends Compartilhador {
  final textos = <String>[];

  @override
  Future<void> compartilhar(String texto, {String? assunto}) async => textos.add(texto);
}

class Falsos {
  final auth = AuthFalso();
  final recomendacoes = RecomendacoesFalsas();
  final catalogo = CatalogoFalso();
  final enderecos = EnderecosFalsos();
  final assinaturas = AssinaturasFalsas();
  final ocorrencias = OcorrenciasFalsas();
  final links = LinksFalsos();
  final compartilhador = CompartilhadorFalso();

  Dependencias get dependencias => Dependencias(
    auth: auth,
    recomendacoes: recomendacoes,
    catalogo: catalogo,
    enderecos: enderecos,
    assinaturas: assinaturas,
    ocorrencias: ocorrencias,
    links: links,
    compartilhador: compartilhador,
  );
}

AppConfig configDeTeste({String whatsapp = ''}) =>
    AppConfig(ambiente: Ambiente.dev, apiUrl: 'http://10.0.2.2:3000', suporteWhatsapp: whatsapp);

Widget appDeTeste(Falsos f, {String whatsapp = ''}) => CristalinsApp(
  config: configDeTeste(whatsapp: whatsapp),
  dependencias: f.dependencias,
);
