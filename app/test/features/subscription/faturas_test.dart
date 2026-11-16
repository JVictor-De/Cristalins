import 'package:cristalins_assinatura/core/formatacao.dart';
import 'package:cristalins_assinatura/core/routes.dart';
import 'package:cristalins_assinatura/features/subscription/domain/pagamento.dart';
import 'package:cristalins_assinatura/features/subscription/presentation/cartao_screen.dart';
import 'package:cristalins_assinatura/features/subscription/presentation/faturas_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../support/fakes.dart';

/// cr-5-cobranca: faturas, comprovante, forma de pagamento e cartão (sem guardar PAN nem CVV).
void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  const pan = '4111111111111111';
  const cvv = '737';

  const paga = Fatura(
    id: 'pag-1',
    cicloNumero: 1,
    dataEntrega: '2026-11-16',
    forma: FormaPagamento.pix,
    valor: Dinheiro(21319),
    vencimento: '2026-11-14',
    status: 'PAGO',
    temComprovante: true,
  );
  const boletoAberto = Fatura(
    id: 'pag-2',
    cicloNumero: 2,
    dataEntrega: '2026-11-30',
    forma: FormaPagamento.boleto,
    valor: Dinheiro(21319),
    vencimento: '2026-11-25',
    status: 'PENDENTE',
    link: 'https://fake.asaas.local/b/pay_2',
  );
  const recusada = Fatura(
    id: 'pag-3',
    cicloNumero: 2,
    dataEntrega: '2026-11-30',
    forma: FormaPagamento.cartao,
    valor: Dinheiro(21319),
    vencimento: '2026-11-25',
    status: 'CANCELADO',
    observacao: 'Cartão recusado.',
  );

  Future<Falsos> abrir(
    WidgetTester tester, {
    List<Fatura> faturas = const [],
    double escala = 1,
  }) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = escala;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final f = Falsos()..assinaturas.comAssinaturaAtiva();
    f.assinaturas.faturasSalvas.addAll(faturas);
    await tester.pumpWidget(appDeTeste(f));
    await tester.pumpAndSettle();
    tester.state<NavigatorState>(find.byType(Navigator)).pushNamed(AppRoutes.minhaAssinatura);
    await tester.pumpAndSettle();
    // A linha fica no meio da Tela 8: rola até ela (acima do botão preso ao rodapé).
    final linha = find.text('Faturas e forma de pagamento');
    await tester.ensureVisible(linha);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -200));
    await tester.pumpAndSettle();
    await tester.tap(linha);
    await tester.pumpAndSettle();
    expect(find.byType(FaturasScreen), findsOneWidget);
    return f;
  }

  testWidgets('Tela 8 abre Pagamentos: faturas com selo, forma atual e comprovante', (
    tester,
  ) async {
    final f = await abrir(tester, faturas: [boletoAberto, recusada, paga]);

    expect(find.text('Pagamentos'), findsWidgets);
    expect(find.text('Forma de pagamento'), findsOneWidget);
    // Pix marcado (Semantics selected) e as três opções na mesma seção
    for (final forma in FormaPagamento.values) {
      expect(find.text(forma.rotulo), findsWidgets);
    }
    expect(find.byIcon(CupertinoIcons.checkmark_alt), findsOneWidget);

    expect(find.text('PAGA'), findsOneWidget);
    expect(find.text('EM ABERTO'), findsOneWidget);
    expect(find.textContaining('Cartão recusado.'), findsOneWidget);
    expect(find.textContaining('vence 25/11'), findsOneWidget);

    // Ação principal: abrir o boleto em aberto
    await tester.tap(find.text('Abrir boleto'));
    await tester.pumpAndSettle();
    expect(f.links.abertos, ['https://fake.asaas.local/b/pay_2']);

    // Fatura paga abre o comprovante
    await tester.fling(find.byType(Scrollable).last, const Offset(0, -3000), 3000);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entrega de 16/11'));
    await tester.pumpAndSettle();
    expect(f.links.abertos.last, 'https://fake.asaas.local/comprovantes/pag-1');
  });

  testWidgets('sem faturas: estado vazio e nenhuma ação principal', (tester) async {
    await abrir(tester);
    expect(find.text('Suas faturas aparecem aqui depois da primeira cobrança.'), findsOneWidget);
    expect(find.text('Abrir boleto'), findsNothing);
  });

  testWidgets('troca para boleto vale para a próxima cobrança', (tester) async {
    final f = await abrir(tester);
    await tester.tap(find.text('Boleto'));
    await tester.pumpAndSettle();
    expect(f.assinaturas.chamadas, contains('forma BOLETO'));
    expect(find.text('Boleto vale a partir da próxima cobrança.'), findsOneWidget);
  });

  testWidgets('CT18 no app: cadastra o cartão sem guardar PAN nem CVV e passa a usá-lo', (
    tester,
  ) async {
    final f = await abrir(tester);
    await tester.tap(find.text('Cartão de crédito'));
    await tester.pumpAndSettle();
    expect(find.byType(CartaoScreen), findsOneWidget);

    // Validação local antes de enviar
    await tester.tap(find.text('Salvar cartão'));
    await tester.pumpAndSettle();
    expect(find.text('Número do cartão inválido.'), findsOneWidget);
    expect(f.assinaturas.chamadas.where((c) => c.startsWith('cartao')), isEmpty);

    Future<void> digitar(String placeholder, String texto) async {
      final campo = find.widgetWithText(CupertinoTextField, placeholder);
      await tester.ensureVisible(campo);
      await tester.enterText(campo, texto);
    }

    await digitar('Como está no cartão', 'ANA SOUZA');
    await digitar('0000 0000 0000 0000', pan);
    await digitar('MM', '12');
    await digitar('AAAA', '2030');
    await digitar('3 ou 4 dígitos', cvv);
    await digitar('00000-000', '22041-001');
    await digitar('Do endereço', '100');
    await digitar('(21) 99999-9999', '21987654321');
    // CVV fica oculto enquanto digita
    final campoCvv = tester.widget<EditableText>(
      find.descendant(
        of: find.widgetWithText(CupertinoTextField, '3 ou 4 dígitos'),
        matching: find.byType(EditableText),
      ),
    );
    expect(campoCvv.obscureText, isTrue);

    await tester.tap(find.text('Salvar cartão'));
    await tester.pumpAndSettle();

    // Volta para Pagamentos com o cartão em uso; só bandeira e final aparecem
    expect(find.byType(CartaoScreen), findsNothing);
    expect(f.assinaturas.chamadas, containsAllInOrder(['cartao 1111', 'forma CARTAO']));
    expect(find.text('Visa final 1111'), findsOneWidget);
    expect(find.text('Cartão salvo. Vale a partir da próxima cobrança.'), findsOneWidget);
    // Nada do número nem do CVV em nenhum texto da árvore
    for (final t in tester.widgetList<EditableText>(find.byType(EditableText))) {
      expect(t.controller.text, isNot(contains(pan)));
    }
    expect(find.textContaining(pan), findsNothing);
    expect(find.text(cvv), findsNothing);
  });

  testWidgets('com cartão salvo, a folha deixa escolher o cartão existente', (tester) async {
    final f = Falsos();
    f.assinaturas.cartoesSalvos.add(
      const CartaoSalvo(id: 'cartao-1', bandeira: 'MASTERCARD', final4: '4444'),
    );
    // reaproveita o fluxo de abertura com o cartão já cadastrado
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    f.assinaturas.comAssinaturaAtiva();
    await tester.pumpWidget(appDeTeste(f));
    await tester.pumpAndSettle();
    tester.state<NavigatorState>(find.byType(Navigator)).push(rotaFaturas('ass-1'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cartão de crédito'));
    await tester.pumpAndSettle();
    expect(find.text('Adicionar outro cartão'), findsOneWidget);
    await tester.tap(find.text('Mastercard final 4444'));
    await tester.pumpAndSettle();
    expect(f.assinaturas.chamadas, contains('forma CARTAO'));
    expect(find.text('Mastercard final 4444'), findsOneWidget);
  });

  // Checklist da seção 10 automatizável nas duas telas novas, a 100% e 130%.
  for (final escala in [1.0, 1.3]) {
    for (final tela in ['Pagamentos', 'Novo cartão']) {
      testWidgets('$tela a ${(escala * 100).round()}%: sem estouro, toque, rótulos e contraste', (
        tester,
      ) async {
        final semantica = tester.ensureSemantics();
        await abrir(tester, faturas: [boletoAberto, recusada, paga], escala: escala);
        if (tela == 'Novo cartão') {
          await tester.tap(find.text('Cartão de crédito'));
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
        await tester.fling(find.byType(Scrollable).first, const Offset(0, -3000), 3000);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.fling(find.byType(Scrollable).first, const Offset(0, 3000), 3000);
        await tester.pumpAndSettle();
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        semantica.dispose();
      });
    }
  }
}
