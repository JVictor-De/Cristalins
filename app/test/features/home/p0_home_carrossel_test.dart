import 'package:cristalins_assinatura/core/config/app_config.dart';
import 'package:cristalins_assinatura/core/dependencias.dart';
import 'package:cristalins_assinatura/core/formatacao.dart';
import 'package:cristalins_assinatura/core/theme/app_colors.dart';
import 'package:cristalins_assinatura/core/theme/app_theme.dart';
import 'package:cristalins_assinatura/core/widgets/card_produto.dart';
import 'package:cristalins_assinatura/features/catalog/domain/catalogo.dart';
import 'package:cristalins_assinatura/features/catalog/presentation/sacola_controller.dart';
import 'package:cristalins_assinatura/features/home/presentation/home_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../support/fakes.dart';
import '../../support/mocks.dart';

class _MockStorage extends Mock implements FlutterSecureStorage {}

/// Seed real (packs): AMS 12×500, AMC 12×510, AMN1500 6×1,5 L, AMN5000 5 L, WP/FF 6×500.
const _seed = [
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
    codigo: 'AMC510',
    nome: 'Água mineral com gás',
    tipo: 'COMPLEMENTO',
    volumeMl: 510,
    embalagemQtd: 12,
    precoBase: Dinheiro(290),
  ),
  Produto(
    codigo: 'AMN1500',
    nome: 'Água mineral natural',
    tipo: 'COMPLEMENTO',
    volumeMl: 1500,
    embalagemQtd: 6,
    precoBase: Dinheiro(390),
  ),
  Produto(
    codigo: 'AMN5000',
    nome: 'Água mineral natural (galão)',
    tipo: 'COMPLEMENTO',
    volumeMl: 5000,
    embalagemQtd: 1,
    precoBase: Dinheiro(990),
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  Future<SacolaController> montarHome(WidgetTester tester) async {
    final mocks = Mocks();
    when(() => mocks.catalogo.produtos()).thenAnswer((_) async => _seed);
    when(() => mocks.catalogo.kits()).thenAnswer((_) async => <Kit>[]);
    mocks.simularDevolve(
      const Simulacao(
        itens: [],
        ue: 0,
        subtotal: Dinheiro(0),
        frete: Dinheiro(0),
        total: Dinheiro(0),
        detalhe: [],
      ),
    );
    final storage = _MockStorage();
    when(() => storage.read(key: any(named: 'key'))).thenAnswer((_) async => null);
    when(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
    final sacola = SacolaController(mocks.catalogo, storage: storage, atraso: Duration.zero);
    sacola.produtos = _seed;
    sacola.carregandoCatalogo = false;

    final dep = Dependencias(
      auth: AuthFalso(),
      recomendacoes: RecomendacoesFalsas(),
      catalogo: mocks.catalogo,
      enderecos: EnderecosFalsos(),
      assinaturas: AssinaturasFalsas(),
      ocorrencias: OcorrenciasFalsas(),
      api: null,
    );

    await tester.binding.setSurfaceSize(const Size(390, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(
            value: const AppConfig(ambiente: Ambiente.dev, apiUrl: '', suporteWhatsapp: ''),
          ),
          Provider.value(value: dep),
          ChangeNotifierProvider.value(value: sacola),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          scrollBehavior: const AppScrollBehavior(),
          home: MediaQuery(
            data: const MediaQueryData(size: Size(390, 1600), disableAnimations: true),
            child: Scaffold(
              backgroundColor: AppColors.fundo,
              body: HomeScreen(onAbrirProdutos: ({categoria}) {}, onAbrirAssinatura: () {}),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    return sacola;
  }

  testWidgets('P0.6: ~2,3 cards visíveis e indicador enxuto (≤ 4)', (tester) async {
    await montarHome(tester);

    final carrossel = find.byKey(const ValueKey('carrossel-home'));
    expect(carrossel, findsOneWidget);

    final primeiro = find.byType(CardProduto).first;
    final largura = tester.getSize(primeiro).width;
    // (390 − 16 − 2×12) / 2,3 ≈ 152 → 2,3 cards no viewport.
    expect(390 / (largura + 12), closeTo(2.3, 0.25));

    final indicador = find.byKey(const ValueKey('indicador-carrossel-home'));
    expect(indicador, findsOneWidget);
    final pontos = find.descendant(of: indicador, matching: find.byType(AnimatedContainer));
    expect(pontos.evaluate().length, inInclusiveRange(2, 4));
    expect(pontos.evaluate().length, lessThan(_seed.length));
  });

  test('AppScrollBehavior aceita mouse/trackpad (web desktop)', () {
    const behavior = AppScrollBehavior();
    expect(behavior.dragDevices, contains(PointerDeviceKind.mouse));
    expect(behavior.dragDevices, contains(PointerDeviceKind.trackpad));
    expect(behavior.dragDevices, contains(PointerDeviceKind.touch));
  });

  testWidgets('carrossel Home rola na horizontal (offset > 0 após drag)', (tester) async {
    await montarHome(tester);

    final listaHorizontal = find.descendant(
      of: find.byKey(const ValueKey('carrossel-home')),
      matching: find.byWidgetPredicate(
        (w) => w is ListView && w.scrollDirection == Axis.horizontal,
      ),
    );
    expect(listaHorizontal, findsOneWidget);

    final scrollable = find.descendant(of: listaHorizontal, matching: find.byType(Scrollable));
    final estado = tester.state<ScrollableState>(scrollable);
    expect(estado.position.maxScrollExtent, greaterThan(0), reason: 'catálogo curto demais p/ rolar');
    expect(estado.position.pixels, 0);

    await tester.drag(listaHorizontal, const Offset(-240, 0));
    await tester.pumpAndSettle();

    expect(estado.position.pixels, greaterThan(0), reason: 'drag horizontal não moveu o carrossel');
  });

  testWidgets('carrossel Home rola com scroll de mouse/trackpad (web)', (tester) async {
    await montarHome(tester);

    final listaHorizontal = find.descendant(
      of: find.byKey(const ValueKey('carrossel-home')),
      matching: find.byWidgetPredicate(
        (w) => w is ListView && w.scrollDirection == Axis.horizontal,
      ),
    );
    final scrollable = find.descendant(of: listaHorizontal, matching: find.byType(Scrollable));
    final estado = tester.state<ScrollableState>(scrollable);
    expect(
      ScrollConfiguration.of(tester.element(listaHorizontal)).dragDevices,
      containsAll([PointerDeviceKind.mouse, PointerDeviceKind.trackpad]),
    );
    expect(estado.position.pixels, 0);

    // Web desktop: wheel/trackpad → PointerScrollEvent (não só drag).
    final centro = tester.getCenter(listaHorizontal);
    await tester.sendEventToBinding(
      PointerScrollEvent(position: centro, scrollDelta: const Offset(280, 0)),
    );
    await tester.pumpAndSettle();

    expect(
      estado.position.pixels,
      greaterThan(0),
      reason: 'scroll horizontal com mouse/trackpad não moveu o carrossel',
    );
  });

  testWidgets('P0.4/P0.5: nomes curtos + pack do seed nos cards', (tester) async {
    await montarHome(tester);
    final card = find.byType(CardProduto);
    expect(find.descendant(of: card, matching: find.text('12 × 500 ml')), findsOneWidget);
    expect(find.descendant(of: card, matching: find.text('Sem gás')), findsWidgets);
    expect(find.textContaining('por embalagem'), findsNothing);
  });

  testWidgets('P0.3: “+” do card adiciona e badge da sacola atualiza', (tester) async {
    final sacola = await montarHome(tester);
    final primeiroCard = find.byType(CardProduto).first;
    await tester.tap(find.descendant(of: primeiroCard, matching: find.byIcon(Icons.add)));
    await tester.pump();
    expect(sacola.totalItens, greaterThan(0));
    expect(find.bySemanticsLabel(RegExp(r'^Abrir sacola, \d+')), findsOneWidget);
    // Drena debounce da simulação + SnackBar.
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('golden Home carrossel foto-âncora', (tester) async {
    await montarHome(tester);
    await expectLater(
      find.byKey(const ValueKey('carrossel-home')),
      matchesGoldenFile('../../goldens/p0_home_carrossel.png'),
    );
  });
}
