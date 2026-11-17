import 'package:cristalins_assinatura/core/formatacao.dart';
import 'package:cristalins_assinatura/core/theme/app_colors.dart';
import 'package:cristalins_assinatura/core/theme/app_theme.dart';
import 'package:cristalins_assinatura/core/widgets/card_produto.dart';
import 'package:cristalins_assinatura/core/widgets/stepper_quantidade.dart';
import 'package:cristalins_assinatura/features/catalog/domain/catalogo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const produto = Produto(
    codigo: 'AMS500',
    nome: 'Água mineral 500 ml',
    tipo: 'COMPLEMENTO',
    volumeMl: 500,
    embalagemQtd: 12,
    precoBase: Dinheiro(220),
  );

  testWidgets('CardProduto mostra âncora precoBase sem inventar total', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 160,
            height: 260,
            child: CardProduto(
              produto: produto,
              passo: 12,
              onAbrir: () {},
              onAdicionar: () {},
              onAlterar: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('A partir de'), findsOneWidget);
    expect(find.textContaining(produto.precoBase.formatado), findsOneWidget);
    expect(find.textContaining('/un.'), findsOneWidget);
    // Não há total de assinatura no card (só âncora de catálogo).
    expect(find.textContaining('por entrega'), findsNothing);
  });

  Future<void> montar(WidgetTester tester, {int quantidade = 0}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          backgroundColor: AppColors.fundo,
          body: Center(
            child: SizedBox(
              width: 164,
              height: 280,
              child: CardProduto(
                produto: produto,
                passo: 12,
                quantidade: quantidade,
                onAbrir: () {},
                onAdicionar: () {},
                onAlterar: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('P0: foto-âncora sem caixa branca, nome curto, pack e + navy', (tester) async {
    await montar(tester);

    // Nome curto 1 linha + pack real.
    expect(find.text('Sem gás'), findsOneWidget);
    expect(find.text('12 × 500 ml'), findsOneWidget);
    expect(find.textContaining('por embalagem'), findsNothing);

    // Nenhuma superfície branca/sombra envolvendo o texto.
    final brancos = tester.widgetList<Material>(
      find.descendant(of: find.byType(CardProduto), matching: find.byType(Material)),
    );
    expect(brancos.any((m) => m.color == AppColors.superficie), isFalse);
    final caixas = tester.widgetList<DecoratedBox>(
      find.descendant(of: find.byType(CardProduto), matching: find.byType(DecoratedBox)),
    );
    expect(
      caixas.any((d) {
        final dec = d.decoration;
        return dec is BoxDecoration && dec.color == AppColors.superficie;
      }),
      isFalse,
    );

    // Bloco no fundo soft de água.
    expect(
      find.descendant(
        of: find.byType(CardProduto),
        matching: find.byWidgetPredicate((w) => w is ColoredBox && w.color == AppColors.blocoAgua),
      ),
      findsOneWidget,
    );

    // “+” navy 40 visível, 48 de toque.
    final mais = find.ancestor(of: find.byIcon(Icons.add), matching: find.byType(Container)).first;
    final dec = tester.widget<Container>(mais).decoration! as BoxDecoration;
    expect(dec.color, AppColors.heroNavy);
    expect(tester.getSize(mais), const Size(40, 40));
    final alvo = find
        .ancestor(of: find.byIcon(Icons.add), matching: find.byType(GestureDetector))
        .first;
    expect(tester.getSize(alvo).width, greaterThanOrEqualTo(48));
  });

  testWidgets('P0.5: Semantics do card usa nome completo da API + pack', (tester) async {
    final handle = tester.ensureSemantics();
    await montar(tester);
    expect(
      find.bySemanticsLabel(RegExp(r'^Água mineral 500 ml, 12 × 500 ml, a partir de')),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel(RegExp(r'^Adicionar Água mineral 500 ml')), findsOneWidget);
    handle.dispose();
  });

  testWidgets('stepper fica no bloco após o 1º toque', (tester) async {
    await montar(tester, quantidade: 12);
    expect(find.byType(StepperQuantidade), findsOneWidget);
    expect(find.byIcon(Icons.add), findsNothing);
  });
}
