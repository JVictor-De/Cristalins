import 'dart:async';

import 'package:cristalins_assinatura/core/network/api_erro.dart';
import 'package:cristalins_assinatura/core/routes.dart';
import 'package:cristalins_assinatura/core/widgets/botao_principal.dart';
import 'package:cristalins_assinatura/features/address/data/endereco_repository.dart';
import 'package:cristalins_assinatura/features/address/domain/endereco.dart';
import 'package:cristalins_assinatura/features/catalog/domain/catalogo.dart';
import 'package:cristalins_assinatura/features/subscription/domain/assinatura.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show ScaffoldMessenger, ScaffoldMessengerState;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/fakes.dart' show zonaSul;
import '../../support/mocks.dart';

/// Tela 6 — Endereço com a API simulada por mocktail.
void main() {
  setUpAll(registrarFallbacks);

  const pedido = PedidoAssinatura(itens: [ItemCesta('WP500', 12)]);
  const cepCopacabana = CepConsultado(
    cep: '22041001',
    logradouro: 'Avenida Nossa Senhora de Copacabana',
    bairro: 'Copacabana',
    zona: zonaSul,
  );

  late Mocks m;

  setUp(() {
    m = Mocks()..simularDevolve(simulacaoCasoA);
    when(() => m.links.abrir(any())).thenAnswer((_) async => true);
  });

  Future<void> abrir(WidgetTester tester, {bool esperar = true}) async {
    await prepararTela(tester);
    await tester.pumpWidget(appComMocks(m));
    await tester.pumpAndSettle();
    tester
        .state<NavigatorState>(find.byType(Navigator))
        .pushNamed(AppRoutes.endereco, arguments: pedido);
    if (esperar) await tester.pumpAndSettle();
  }

  Future<void> escrever(WidgetTester tester, int campo, String texto) async {
    final alvo = find.byType(CupertinoTextFormFieldRow).at(campo);
    await tester.ensureVisible(alvo);
    await tester.enterText(alvo, texto);
    await tester.pump();
  }

  Future<void> tocar(WidgetTester tester, Finder alvo) async {
    tester.state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger)).hideCurrentSnackBar();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(alvo, 120, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(alvo);
    await tester.pumpAndSettle();
    await tester.tap(alvo);
    await tester.pumpAndSettle();
  }

  BotaoPrincipal botao(WidgetTester tester) =>
      tester.widget<BotaoPrincipal>(find.byType(BotaoPrincipal));

  testWidgets('carregando e depois vazio: sem endereços salvos, mostra o formulário de CEP', (
    tester,
  ) async {
    final lista = Completer<List<Endereco>>();
    when(() => m.enderecos.listar()).thenAnswer((_) => lista.future);
    await abrir(tester, esperar: false);
    await tester.pump(); // monta a rota
    await tester.pump(const Duration(milliseconds: 500)); // transição
    expect(find.byType(CupertinoActivityIndicator), findsOneWidget);

    lista.complete([]);
    await tester.pumpAndSettle();
    expect(find.text('Entregar em'), findsNothing);
    expect(find.text('Buscar CEP'), findsOneWidget);
    expect(find.text('Salvar endereço'), findsOneWidget);
    expect(botao(tester).onPressed, isNull); // sem CEP consultado não avança
  });

  testWidgets('erro ao carregar mostra "Tentar de novo" e recarrega', (tester) async {
    var chamadas = 0;
    when(() => m.enderecos.listar()).thenAnswer((_) async {
      chamadas++;
      if (chamadas == 1) throw const ApiErro(codigo: 'ERRO', mensagem: ApiErro.generico);
      return [enderecoCopacabana];
    });
    await abrir(tester);
    expect(find.text(ApiErro.generico), findsOneWidget);

    await tester.tap(find.text('Tentar de novo'));
    await tester.pumpAndSettle();
    expect(chamadas, 2);
    expect(find.text('Entregar em'), findsOneWidget);
  });

  testWidgets('CEP com formato errado não chama a API', (tester) async {
    when(() => m.enderecos.listar()).thenAnswer((_) async => []);
    await abrir(tester);
    await escrever(tester, 0, '2204');
    await tocar(tester, find.text('Buscar CEP'));
    expect(find.text('Informe o CEP com 8 dígitos.'), findsOneWidget);
    verifyNever(() => m.enderecos.consultarCep(any()));
  });

  testWidgets('CEP do Rio: mostra zona e taxa, exige número e salva o endereço', (tester) async {
    when(() => m.enderecos.listar()).thenAnswer((_) async => []);
    when(() => m.enderecos.consultarCep('22041001')).thenAnswer((_) async => cepCopacabana);
    when(() => m.enderecos.criar(any())).thenAnswer((_) async => enderecoCopacabana);
    await abrir(tester);
    await escrever(tester, 0, '22041-001');
    await tocar(tester, find.text('Buscar CEP'));

    expect(find.text('Avenida Nossa Senhora de Copacabana'), findsOneWidget);
    expect(find.textContaining('Zona Sul: entrega seg, qua e sex'), findsOneWidget);

    // Número obrigatório
    await tester.tap(find.byType(BotaoPrincipal));
    await tester.pumpAndSettle();
    expect(find.text('Informe o número.'), findsOneWidget);
    verifyNever(() => m.enderecos.criar(any()));

    await escrever(tester, 1, ' 100 ');
    await escrever(tester, 2, 'Apto 301');
    await tester.tap(find.byType(BotaoPrincipal));
    await tester.pumpAndSettle();

    final novo = verify(() => m.enderecos.criar(captureAny())).captured.single as NovoEndereco;
    expect(novo.toJson(), {
      'cep': '22041001',
      'numero': '100',
      'complemento': 'Apto 301',
      'apelido': 'Casa',
    });
    // Segue para a Tela 7 com o endereço (frete da zona na simulação)
    expect(find.text('Plano e pagamento'), findsWidgets);
    verify(
      () => m.catalogo.simular(
        itens: any(named: 'itens'),
        frequencia: any(named: 'frequencia'),
        plano: any(named: 'plano'),
        enderecoId: 'end-1',
        cupom: any(named: 'cupom'),
      ),
    ).called(greaterThan(0));
  });

  testWidgets('CT08/CT23: fora da área oferece a lista de espera', (tester) async {
    when(() => m.enderecos.listar()).thenAnswer((_) async => []);
    when(() => m.enderecos.consultarCep('01310100')).thenThrow(
      const ApiErro(
        codigo: 'CEP_FORA_AREA',
        mensagem: 'Por enquanto entregamos só no município do Rio de Janeiro.',
      ),
    );
    when(
      () => m.enderecos.entrarNaListaDeEspera(
        email: any(named: 'email'),
        cep: any(named: 'cep'),
        bairro: any(named: 'bairro'),
      ),
    ).thenAnswer((_) async {});
    await abrir(tester);
    await escrever(tester, 0, '01310-100');
    await tocar(tester, find.text('Buscar CEP'));

    expect(find.text('Por enquanto entregamos só no município do Rio de Janeiro.'), findsOneWidget);
    expect(find.text('Lista de espera'), findsOneWidget);
    expect(botao(tester).onPressed, isNull);

    await escrever(tester, 1, 'ana@exemplo');
    await tocar(tester, find.text('Avisar quando chegar'));
    expect(find.text('Informe um e-mail válido.'), findsOneWidget);

    await escrever(tester, 1, ' Ana@Exemplo.com ');
    await tocar(tester, find.text('Avisar quando chegar'));
    verify(
      () => m.enderecos.entrarNaListaDeEspera(
        email: 'ana@exemplo.com',
        cep: '01310100',
        bairro: null,
      ),
    ).called(1);
    expect(
      find.text('Você está na lista. Avisamos assim que a entrega chegar aí.'),
      findsOneWidget,
    );
  });

  testWidgets('endereço salvo: escolhe outro, troca a janela e abre no mapa', (tester) async {
    when(
      () => m.enderecos.listar(),
    ).thenAnswer((_) async => [enderecoCopacabana, enderecoTrabalho]);
    await abrir(tester);
    expect(find.text('Entregar em'), findsOneWidget);
    expect(find.text('Continuar'), findsOneWidget);

    await tocar(tester, find.text('Trabalho'));
    await tocar(tester, find.text(JanelaEntrega.manha.rotulo));
    await tester.drag(find.byType(CupertinoPicker), const Offset(0, -40));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Concluir'));
    await tester.pumpAndSettle();
    expect(find.text(JanelaEntrega.tarde.rotulo), findsOneWidget);

    await tocar(tester, find.text('Abrir no mapa'));
    final url = verify(() => m.links.abrir(captureAny())).captured.single as String;
    expect(url, startsWith('geo:0,0?q='));
    expect(Uri.decodeComponent(url), contains('Avenida Rio Branco, 1, Centro'));

    await tester.tap(find.byType(BotaoPrincipal));
    await tester.pumpAndSettle();
    expect(find.text('Plano e pagamento'), findsWidgets);
    expect(find.text('Tarde, 13h–18h'), findsOneWidget);
    verifyNever(() => m.enderecos.criar(any()));
  });

  testWidgets('erro ao salvar mostra a mensagem e não sai da tela', (tester) async {
    when(() => m.enderecos.listar()).thenAnswer((_) async => []);
    when(() => m.enderecos.consultarCep(any())).thenAnswer((_) async => cepCopacabana);
    when(() => m.enderecos.criar(any())).thenThrow(
      const ApiErro(codigo: 'BAIRRO_NAO_ATENDIDO', mensagem: 'Ainda não entregamos em Copacabana.'),
    );
    await abrir(tester);
    await escrever(tester, 0, '22041001');
    await tocar(tester, find.text('Buscar CEP'));
    await escrever(tester, 1, '100');
    await tester.tap(find.byType(BotaoPrincipal));
    await tester.pumpAndSettle();
    expect(find.text('Ainda não entregamos em Copacabana.'), findsWidgets);
    expect(find.text('Endereço'), findsWidgets);
  });
}
