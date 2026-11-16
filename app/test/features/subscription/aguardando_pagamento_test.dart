import 'package:cristalins_assinatura/core/formatacao.dart';
import 'package:cristalins_assinatura/core/network/api_erro.dart';
import 'package:cristalins_assinatura/core/routes.dart';
import 'package:cristalins_assinatura/core/widgets/botao_principal.dart';
import 'package:cristalins_assinatura/features/catalog/domain/catalogo.dart';
import 'package:cristalins_assinatura/features/subscription/domain/assinatura.dart';
import 'package:cristalins_assinatura/features/subscription/presentation/aguardando_pagamento_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/mocks.dart';

/// Tela "Aguardando pagamento" (cr-3-tela) com a API simulada por mocktail.
void main() {
  setUpAll(registrarFallbacks);

  /// Como o `FakeGateway` da API devolve (ASAAS_MODE=fake): o "QR" não é imagem.
  const pixFake = PixCobranca(
    copiaECola: '00020126FAKE-PIX-pay_fake_1234',
    qrCodeBase64: 'cXItcGF5X2Zha2VfMTIzNA==',
  );

  /// PNG 1×1 válido, como um QR do sandbox.
  const pixSandbox = PixCobranca(
    copiaECola: '00020126580014br.gov.bcb.pix0136abc',
    qrCodeBase64:
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
  );

  AssinaturaCriada criada({PixCobranca? pix = pixFake}) => AssinaturaCriada(
    id: 'ass-1',
    valorPrimeiroCiclo: const Dinheiro(21319),
    dataEntrega: '2026-11-16',
    vencimento: '2026-11-14',
    pix: pix,
  );

  Assinatura assinatura(String status) => Assinatura(
    id: 'ass-1',
    status: status,
    plano: 'TRIMESTRAL',
    frequencia: 'QUINZENAL',
    janela: 'MANHA',
    itens: const [ItemCesta('WP500', 24)],
    bairro: 'Copacabana',
    zona: 'Zona Sul',
    proximaEntrega: '2026-11-16',
  );

  late Mocks m;
  late List<String> copiados;

  setUp(() {
    m = Mocks();
    copiados = [];
    when(() => m.assinaturas.listar()).thenAnswer((_) async => [assinatura('ATIVA')]);
    when(() => m.assinaturas.ciclos(any())).thenAnswer((_) async => []);
  });

  Future<void> abrir(WidgetTester tester, AssinaturaCriada c) async {
    await prepararTela(tester);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (
      call,
    ) async {
      if (call.method == 'Clipboard.setData') {
        copiados.add((call.arguments as Map)['text'] as String);
      }
      return null;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(appComMocks(m));
    await tester.pumpAndSettle();
    tester.state<NavigatorState>(find.byType(Navigator)).push(rotaAguardandoPagamento(c));
    await tester.pump();
    // Transição inteira (o indicador gira sem parar, então não dá para usar pumpAndSettle).
    await tester.pump(const Duration(milliseconds: 900));
  }

  /// Avança o relógio do teste em passos de 1 s (a tela consulta a cada 5 s).
  Future<void> esperar(WidgetTester tester, Duration total) async {
    for (var t = Duration.zero; t < total; t += const Duration(seconds: 1)) {
      await tester.pump(const Duration(seconds: 1));
    }
  }

  testWidgets('fake: confirmar o pagamento na API muda para ATIVA na tela em menos de 1 minuto', (
    tester,
  ) async {
    var status = 'AGUARDANDO_PAGAMENTO';
    when(() => m.assinaturas.buscar('ass-1')).thenAnswer((_) async => assinatura(status));
    await abrir(tester, criada());

    // Aguardando: indicador enquanto consulta, valor, copia e cola e aviso de demonstração
    expect(find.text('Aguardando o pagamento'), findsOneWidget);
    expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
    expect(find.textContaining('213,19'), findsOneWidget);
    expect(find.text('00020126FAKE-PIX-pay_fake_1234'), findsOneWidget);
    expect(
      find.textContaining('Ambiente de demonstração: este código não é um Pix real.'),
      findsOneWidget,
    );
    expect(find.text('QR Code de demonstração indisponível. Use o código abaixo.'), findsOneWidget);
    expect(find.textContaining('Abra o app do seu banco'), findsNothing);

    // Consulta a cada 5 s
    await esperar(tester, const Duration(seconds: 11));
    verify(() => m.assinaturas.buscar('ass-1')).called(3); // 0 s, 5 s e 10 s

    // A API confirma (webhook/job no fake): em até 1 minuto a tela mostra ATIVA
    status = 'ATIVA';
    await esperar(tester, const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(find.text('Pagamento confirmado'), findsWidgets);
    expect(find.text('Sua assinatura está ativa.'), findsOneWidget);
    expect(find.text('00020126FAKE-PIX-pay_fake_1234'), findsNothing);

    // Para de consultar depois de ativa
    clearInteractions(m.assinaturas);
    await esperar(tester, const Duration(seconds: 15));
    verifyNever(() => m.assinaturas.buscar(any()));

    // Uma ação principal: ver a assinatura (Tela 8)
    await tester.tap(find.byType(BotaoPrincipal));
    await tester.pumpAndSettle();
    expect(find.text('Minha assinatura'), findsWidgets);
  });

  testWidgets('erro na consulta mostra "Tentar de novo" e volta a consultar', (tester) async {
    var chamadas = 0;
    when(() => m.assinaturas.buscar('ass-1')).thenAnswer((_) async {
      chamadas++;
      if (chamadas == 1) throw const ApiErro(codigo: 'SEM_CONEXAO', mensagem: ApiErro.semConexao);
      return assinatura('ATIVA');
    });
    await abrir(tester, criada());
    await tester.pump();
    expect(find.text('Não conseguimos confirmar agora'), findsOneWidget);
    expect(find.text(ApiErro.semConexao), findsOneWidget);

    // Sem consultas novas enquanto está em erro
    await esperar(tester, const Duration(seconds: 10));
    expect(chamadas, 1);

    await tester.tap(find.text('Tentar de novo'));
    await tester.pumpAndSettle();
    expect(chamadas, 2);
    expect(find.text('Sua assinatura está ativa.'), findsOneWidget);
  });

  testWidgets('assinatura cancelada (sem pagamento no prazo) para de consultar e explica', (
    tester,
  ) async {
    when(() => m.assinaturas.buscar('ass-1')).thenAnswer((_) async => assinatura('CANCELADA'));
    await abrir(tester, criada());
    await tester.pump();
    expect(
      find.text('A assinatura foi cancelada porque o pagamento não foi confirmado a tempo.'),
      findsOneWidget,
    );
  });

  testWidgets('copia o código Pix (ação principal) com aviso', (tester) async {
    when(
      () => m.assinaturas.buscar('ass-1'),
    ).thenAnswer((_) async => assinatura('AGUARDANDO_PAGAMENTO'));
    await abrir(tester, criada());
    await tester.tap(find.byType(BotaoPrincipal));
    await tester.pump();
    expect(copiados, ['00020126FAKE-PIX-pay_fake_1234']);
    expect(find.text('Código Pix copiado. Cole no app do seu banco.'), findsOneWidget);
  });

  testWidgets('sandbox: mostra o QR da API e não fala em demonstração', (tester) async {
    when(
      () => m.assinaturas.buscar('ass-1'),
    ).thenAnswer((_) async => assinatura('AGUARDANDO_PAGAMENTO'));
    await abrir(tester, criada(pix: pixSandbox));
    expect(find.bySemanticsLabel('QR Code do Pix'), findsOneWidget);
    expect(find.textContaining('Abra o app do seu banco'), findsOneWidget);
    expect(find.textContaining('demonstração'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pushNamed /aguardando-pagamento com AssinaturaCriada abre a tela real', (
    tester,
  ) async {
    when(
      () => m.assinaturas.buscar('ass-1'),
    ).thenAnswer((_) async => assinatura('AGUARDANDO_PAGAMENTO'));
    await prepararTela(tester);
    await tester.pumpWidget(appComMocks(m));
    await tester.pumpAndSettle();
    tester
        .state<NavigatorState>(find.byType(Navigator))
        .pushNamed(AppRoutes.aguardandoPagamento, arguments: criada());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('Aguardando o pagamento'), findsOneWidget);
    expect(find.text('00020126FAKE-PIX-pay_fake_1234'), findsOneWidget);
    expect(find.textContaining('em construção'), findsNothing);
  });

  testWidgets('Tela 7: "Assinar agora" com Pix abre a tela de espera na rota nomeada', (
    tester,
  ) async {
    m.simularDevolve(simulacaoCasoA);
    when(
      () => m.assinaturas.criar(
        any(),
        plano: any(named: 'plano'),
        cupom: any(named: 'cupom'),
      ),
    ).thenAnswer((_) async => criada());
    when(
      () => m.assinaturas.buscar('ass-1'),
    ).thenAnswer((_) async => assinatura('AGUARDANDO_PAGAMENTO'));
    await prepararTela(tester);
    await tester.pumpWidget(appComMocks(m));
    await tester.pumpAndSettle();
    tester
        .state<NavigatorState>(find.byType(Navigator))
        .pushNamed(
          AppRoutes.planoPagamento,
          arguments: const PedidoAssinatura(
            itens: [ItemCesta('WP500', 12)],
            endereco: enderecoCopacabana,
          ),
        );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BotaoPrincipal));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('00020126FAKE-PIX-pay_fake_1234'), findsOneWidget);
    final rota = ModalRoute.of(tester.element(find.text('Aguardando o pagamento')))!;
    expect(rota.settings.name, AppRoutes.aguardandoPagamento);
    // Pilha limpa: sem voltar para o plano
    expect(rota.isFirst, isTrue);
  });

  for (final escala in [1.0, 1.3]) {
    testWidgets(
      'checklist a ${(escala * 100).round()}%: sem estouro, toque ≥ 48 dp, rótulos e contraste',
      (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = escala;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final semantica = tester.ensureSemantics();
        when(
          () => m.assinaturas.buscar('ass-1'),
        ).thenAnswer((_) async => assinatura('AGUARDANDO_PAGAMENTO'));
        await abrir(tester, criada());
        await tester.pump();
        expect(tester.takeException(), isNull);
        await tester.fling(find.byType(Scrollable).first, const Offset(0, -3000), 3000);
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        semantica.dispose();
      },
    );
  }
}
