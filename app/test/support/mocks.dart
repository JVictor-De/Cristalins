import 'package:cristalins_assinatura/app.dart';
import 'package:cristalins_assinatura/core/dependencias.dart';
import 'package:cristalins_assinatura/core/formatacao.dart';
import 'package:cristalins_assinatura/core/intents/abridor_links.dart';
import 'package:cristalins_assinatura/core/intents/compartilhador.dart';
import 'package:cristalins_assinatura/features/address/data/endereco_repository.dart';
import 'package:cristalins_assinatura/features/address/domain/endereco.dart';
import 'package:cristalins_assinatura/features/auth/data/auth_repository.dart';
import 'package:cristalins_assinatura/features/catalog/data/catalogo_repository.dart';
import 'package:cristalins_assinatura/features/catalog/domain/catalogo.dart';
import 'package:cristalins_assinatura/features/ocorrencias/data/ocorrencia_repository.dart';
import 'package:cristalins_assinatura/features/quiz/data/recomendacao_repository.dart';
import 'package:cristalins_assinatura/features/quiz/domain/quiz.dart';
import 'package:cristalins_assinatura/features/subscription/data/assinatura_repository.dart';
import 'package:cristalins_assinatura/features/subscription/domain/assinatura.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

import 'fakes.dart' show configDeTeste, zonaSul;

/// Mocks (mocktail) da camada data: nos widget tests a "API" é simulada aqui, sem rede.
class MockAuth extends Mock implements AuthRepository {}

class MockRecomendacoes extends Mock implements RecomendacaoRepository {}

class MockCatalogo extends Mock implements CatalogoRepository {}

class MockEnderecos extends Mock implements EnderecoRepository {}

class MockAssinaturas extends Mock implements AssinaturaRepository {}

class MockOcorrencias extends Mock implements OcorrenciaRepository {}

class MockLinks extends Mock implements AbridorLinks {}

class MockCompartilhador extends Mock implements Compartilhador {}

class Mocks {
  final auth = MockAuth();
  final recomendacoes = MockRecomendacoes();
  final catalogo = MockCatalogo();
  final enderecos = MockEnderecos();
  final assinaturas = MockAssinaturas();
  final ocorrencias = MockOcorrencias();
  final links = MockLinks();
  final compartilhador = MockCompartilhador();

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

  /// Simulação padrão (formato de `POST /precos/simular`).
  void simularDevolve(Simulacao s) {
    when(
      () => catalogo.simular(
        itens: any(named: 'itens'),
        frequencia: any(named: 'frequencia'),
        plano: any(named: 'plano'),
        enderecoId: any(named: 'enderecoId'),
        cupom: any(named: 'cupom'),
      ),
    ).thenAnswer((_) async => s);
  }
}

/// Registre uma vez por arquivo de teste (`setUpAll`).
void registrarFallbacks() {
  registerFallbackValue(
    const DadosCadastro(
      nome: '',
      cpfCnpj: '',
      email: '',
      dataNascimento: '',
      senha: '',
      aceiteTermos: false,
    ),
  );
  registerFallbackValue(const RespostasQuiz());
  registerFallbackValue(const NovoEndereco(cep: '', numero: ''));
  registerFallbackValue(<ItemCesta>[]);
  registerFallbackValue(const PedidoAssinatura(itens: []));
}

/// 360 × 780 dp e datas em pt-BR, como nos demais testes de tela.
Future<void> prepararTela(WidgetTester tester) async {
  await initializeDateFormatting('pt_BR');
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Widget appComMocks(Mocks m) =>
    CristalinsApp(config: configDeTeste(), dependencias: m.dependencias, exibirSplash: false);

const simulacaoCasoA = Simulacao(
  itens: [ItemSimulado(produto: 'WP500', quantidade: 12, precoUnitario: Dinheiro(990))],
  ue: 12,
  subtotal: Dinheiro(11880),
  frete: Dinheiro(990),
  total: Dinheiro(12870),
  detalhe: [LinhaPreco(fator: 'FRETE', valor: Dinheiro(990))],
  zona: 'Zona Sul',
);

const enderecoCopacabana = Endereco(
  id: 'end-1',
  cep: '22041001',
  logradouro: 'Avenida Nossa Senhora de Copacabana',
  numero: '100',
  bairro: 'Copacabana',
  zona: zonaSul,
  principal: true,
  apelido: 'Casa',
);

const enderecoTrabalho = Endereco(
  id: 'end-2',
  cep: '20040002',
  logradouro: 'Avenida Rio Branco',
  numero: '1',
  bairro: 'Centro',
  zona: ZonaEntrega(
    id: 'zona-centro',
    nome: 'Centro',
    taxa: Dinheiro(990),
    dias: ['SEG', 'QUA', 'SEX'],
  ),
  principal: false,
  apelido: 'Trabalho',
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
