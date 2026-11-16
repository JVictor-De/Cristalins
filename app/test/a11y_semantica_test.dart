import 'dart:ui' show CheckedState, Tristate;

import 'package:cristalins_assinatura/core/routes.dart';
import 'package:cristalins_assinatura/features/address/domain/endereco.dart';
import 'package:cristalins_assinatura/features/catalog/domain/catalogo.dart';
import 'package:cristalins_assinatura/features/subscription/domain/assinatura.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'support/fakes.dart';

/// cr-4-a11y: o que o leitor de tela (TalkBack) anuncia em cada tela.
/// Complementa `checklist_telas_test.dart` (contraste, toque de 48 dp e fonte a 130%).
void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  const endereco = Endereco(
    id: 'end-1',
    cep: '22041001',
    logradouro: 'Avenida Nossa Senhora de Copacabana',
    numero: '100',
    bairro: 'Copacabana',
    zona: zonaSul,
    principal: true,
    apelido: 'Casa',
  );
  const pedido = PedidoAssinatura(itens: [ItemCesta('WP500', 12)], endereco: endereco);

  /// testWidgets com o leitor de tela ligado; fecha o handle antes da verificação de fim de teste.
  void testA11y(String nome, Future<void> Function(WidgetTester) corpo) {
    testWidgets(nome, (tester) async {
      final semantica = tester.ensureSemantics();
      try {
        await corpo(tester);
      } finally {
        semantica.dispose();
      }
    });
  }

  Future<void> abrir(WidgetTester tester, String rota, {Object? args}) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final f = Falsos()..assinaturas.comAssinaturaAtiva();
    await tester.pumpWidget(appDeTeste(f));
    await tester.pumpAndSettle();
    if (rota != AppRoutes.boasVindas) {
      tester.state<NavigatorState>(find.byType(Navigator)).pushNamed(rota, arguments: args);
      await tester.pumpAndSettle();
    }
  }

  SemanticsNode campo(WidgetTester tester, int indice) =>
      tester.getSemantics(find.byType(CupertinoTextField).at(indice));

  testA11y('títulos grandes são anunciados como cabeçalho', (tester) async {
    await abrir(tester, AppRoutes.cadastroLogin);
    final cabecalhos = find.bySemanticsLabel('Criar conta').evaluate().where((e) {
      return tester
          .getSemantics(find.byWidget(e.widget).first)
          .getSemanticsData()
          .flagsCollection
          .isHeader;
    });
    expect(cabecalhos, isNotEmpty, reason: 'O título grande precisa da marca de cabeçalho');
  });

  testA11y('Tela 2: cada campo é anunciado com o seu rótulo, não só pelo placeholder', (
    tester,
  ) async {
    await abrir(tester, AppRoutes.cadastroLogin);
    expect(campo(tester, 0).label, contains('Nome'));
    expect(campo(tester, 1).label, contains('CPF'));
    expect(campo(tester, 2).label, contains('Nascimento'));
    expect(campo(tester, 4).label, contains('E-mail'));
    expect(campo(tester, 5).label, contains('Senha'));
    // Depois de digitar, o placeholder some: o rótulo precisa continuar
    await tester.enterText(find.byType(CupertinoTextField).first, 'Ana');
    await tester.pump();
    expect(campo(tester, 0).label, contains('Nome'));
  });

  testA11y('Tela 2: termos é uma caixa de seleção com rótulo e estado', (tester) async {
    await abrir(tester, AppRoutes.cadastroLogin);
    final dados = tester.getSemantics(find.byType(CupertinoCheckbox)).getSemanticsData();
    expect(dados.label, contains('termos de uso'));
    expect(dados.flagsCollection.isChecked, isNot(CheckedState.none));
  });

  testA11y('Tela 3: progresso e opções do quiz com rótulo e seleção', (tester) async {
    await abrir(tester, AppRoutes.quiz);
    expect(find.bySemanticsLabel('Pergunta 1 de 5'), findsOneWidget);
    final radio = tester.getSemantics(find.byType(CupertinoRadio<String>).first).getSemanticsData();
    expect(radio.label, contains('Treino'));
    expect(radio.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
  });

  testA11y('Tela 5: seletor diz o produto e a quantidade, sem repetir o número', (tester) async {
    await abrir(tester, AppRoutes.catalogo, args: pedido);
    expect(find.bySemanticsLabel(RegExp('^Aumentar Water Protein')), findsWidgets);
    expect(find.bySemanticsLabel(RegExp('^Diminuir Water Protein')), findsWidgets);
    final card = find.bySemanticsLabel(RegExp('12 unidades de Water Protein'));
    expect(card, findsOneWidget);
    final linhas = tester.getSemantics(card).label.split('\n');
    expect(
      linhas.where((l) => l.trim() == '12'),
      isEmpty,
      reason: 'o número não pode ser lido duas vezes',
    );
  });

  testA11y('Tela 5: foto do produto anuncia o nome (não fica muda)', (tester) async {
    await abrir(tester, AppRoutes.catalogo, args: pedido);
    const nome = 'Water Protein (água com colágeno)';
    final foto = find.byWidgetPredicate(
      (w) => w is Image && w.semanticLabel == nome,
    );
    expect(foto, findsOneWidget);
  });


  testA11y('Tela 6: campo de CEP com rótulo', (tester) async {
    await abrir(tester, AppRoutes.endereco, args: pedido);
    // Sem endereço salvo, a tela abre direto no formulário de CEP
    expect(find.text('Buscar CEP'), findsOneWidget);
    expect(campo(tester, 0).label, contains('CEP'));
  });

  testA11y('Tela 8: rótulo e valor da linha juntos, selo em caixa normal, switch com rótulo', (
    tester,
  ) async {
    await abrir(tester, AppRoutes.minhaAssinatura);
    expect(find.bySemanticsLabel(RegExp(r'^Status\s+Ativa$')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^Plano\s+Trimestral$')), findsOneWidget);
    expect(find.bySemanticsLabel('ATIVA'), findsNothing);
    final pausa = tester.getSemantics(find.byType(CupertinoSwitch)).getSemanticsData();
    expect(pausa.label, contains('Pausar entregas'));
    expect(pausa.flagsCollection.isToggled, isNot(Tristate.none));
  });

  testA11y('voltar tem rótulo "Voltar"', (tester) async {
    await abrir(tester, AppRoutes.quiz);
    expect(find.bySemanticsLabel('Voltar'), findsOneWidget);
  });
}
