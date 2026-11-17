import 'package:cristalins_assinatura/core/formatacao.dart';
import 'package:cristalins_assinatura/core/theme/app_colors.dart';
import 'package:cristalins_assinatura/core/theme/app_spacing.dart';
import 'package:cristalins_assinatura/core/theme/app_theme.dart';
import 'package:cristalins_assinatura/core/widgets/botao_principal.dart';
import 'package:cristalins_assinatura/features/catalog/domain/catalogo.dart';
import 'package:cristalins_assinatura/features/catalog/domain/pdp_copy.dart';
import 'package:cristalins_assinatura/features/catalog/presentation/produto_screen.dart';
import 'package:cristalins_assinatura/features/catalog/presentation/sacola_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../support/mocks.dart';

class _MockStorage extends Mock implements FlutterSecureStorage {}

const _wp = Produto(
  codigo: 'WP500',
  nome: 'Water Protein (água com colágeno)',
  tipo: 'PRINCIPAL',
  volumeMl: 500,
  embalagemQtd: 6,
  precoBase: Dinheiro(990),
  descricao: 'Cristalins com colágeno em garrafa de 500 ml.',
);

const _galao = Produto(
  codigo: 'AMN5000',
  nome: 'Água mineral natural (galão)',
  tipo: 'COMPLEMENTO',
  volumeMl: 5000,
  embalagemQtd: 1,
  precoBase: Dinheiro(990),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
    registrarFallbacks();
  });

  late SacolaController sacola;

  setUp(() {
    final mocks = Mocks();
    final storage = _MockStorage();
    when(() => storage.read(key: any(named: 'key'))).thenAnswer((_) async => null);
    when(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
    when(() => mocks.catalogo.produtos()).thenAnswer((_) async => [_wp, _galao]);
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
    sacola = SacolaController(mocks.catalogo, storage: storage, atraso: Duration.zero);
    sacola.produtos = [_wp, _galao];
    sacola.carregandoCatalogo = false;
  });

  Future<void> abrir(
    WidgetTester tester,
    String codigo, {
    double escala = 1,
    bool rolar = true,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(390, 844),
            textScaler: TextScaler.linear(escala),
            disableAnimations: true,
          ),
          child: ChangeNotifierProvider<SacolaController>.value(
            value: sacola,
            child: ProdutoScreen(codigo: codigo),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    if (!rolar) return;
    // Stepper fica abaixo do hero (40%) + título/preço: rola até ele.
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('pdp-qtd')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
  }

  String ctaRotulo(WidgetTester tester) =>
      tester.widget<BotaoPrincipal>(find.byKey(const ValueKey('pdp-cta'))).rotulo;

  group('PdpCopy', () {
    test('stepper honesto com meia caixa (passo 3, caixa de 6)', () {
      expect(PdpCopy.quantidade(_wp, 3), '½ caixa · 3 garrafas');
      expect(PdpCopy.quantidade(_wp, 6), '1 caixa · 6 garrafas');
      expect(PdpCopy.quantidade(_wp, 9), '1 caixa e meia · 9 garrafas');
      expect(PdpCopy.quantidade(_wp, 12), '2 caixas · 12 garrafas');
      expect(PdpCopy.quantidade(_galao, 2), '2 unidades');
    });

    test('título / embalagem / chips WP', () {
      expect(PdpCopy.titulo(_wp), 'Water Protein');
      expect(PdpCopy.titulo(_galao), 'Água mineral natural (galão)');
      expect(PdpCopy.embalagem(_wp), 'Garrafa de 500 ml · caixa com 6');
      expect(PdpCopy.embalagem(_galao), 'Galão de 5 L');
      expect(PdpCopy.chips(_wp), ['5 g de proteína', 'Com colágeno']);
      expect(PdpCopy.altFoto(_wp), 'Garrafa de Water Protein Cristalins 500 ml');
    });

    test('valor do item usa unitário da simulação quando o SKU está nela', () {
      const sim = Simulacao(
        itens: [ItemSimulado(produto: 'WP500', quantidade: 6, precoUnitario: Dinheiro(900))],
        ue: 6,
        subtotal: Dinheiro(5400),
        frete: Dinheiro(0),
        total: Dinheiro(5400),
        detalhe: [],
      );
      expect(PdpCopy.valorItem(_wp, 6, sim), const Dinheiro(5400));
      expect(PdpCopy.valorItem(_wp, 3, null), const Dinheiro(2970));
    });
  });

  testWidgets('P2.2/P2.3: título Inter 600 28 heroInk, sem serif e sem “água mineral”', (
    tester,
  ) async {
    await abrir(tester, 'WP500', rolar: false);

    final titulo = tester.widget<Text>(find.byKey(const ValueKey('pdp-titulo')));
    expect(titulo.data, 'Water Protein');
    expect(titulo.style?.fontFamily, 'Inter');
    expect(titulo.style?.fontSize, 28);
    expect(titulo.style?.fontWeight, FontWeight.w600);
    expect(titulo.style?.color, AppColors.heroInk);

    expect(find.text('Garrafa de 500 ml · caixa com 6'), findsOneWidget);
    expect(find.text('5 g de proteína'), findsOneWidget);
    expect(find.text('Com colágeno'), findsOneWidget);
    expect(find.textContaining('açúcar'), findsNothing);
    expect(find.textContaining(RegExp('água mineral', caseSensitive: false)), findsNothing);
    expect(find.textContaining('Water Protein (água'), findsNothing);

    // P2.4: preço por garrafa logo abaixo do título.
    final preco = find.byKey(const ValueKey('pdp-preco'));
    expect(
      tester.getTopLeft(preco).dy,
      greaterThan(tester.getTopLeft(find.byKey(const ValueKey('pdp-titulo'))).dy),
    );
    expect(find.textContaining('/garrafa'), findsOneWidget);
  });

  testWidgets('P2.2: CTA heroNavy raio 14 com R\$ da quantidade local; − a 40% no mínimo', (
    tester,
  ) async {
    await abrir(tester, 'WP500');

    // RN intocável: passo 3.
    expect(sacola.passo(_wp), 3);
    expect(find.text('½ caixa · 3 garrafas'), findsOneWidget);
    expect(ctaRotulo(tester), 'Adicionar · ${const Dinheiro(2970).formatado} por entrega');
    final cta = tester.widget<BotaoPrincipal>(find.byKey(const ValueKey('pdp-cta')));
    expect(cta.variante, VarianteBotaoPrincipal.cta);
    expect(AppSpacing.raioCta, 14);

    // “−” desabilitado e a 40% no mínimo.
    final menos = find.ancestor(of: find.byIcon(Icons.remove), matching: find.byType(Opacity));
    expect(tester.widget<Opacity>(menos.first).opacity, 0.4);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(find.text('1 caixa · 6 garrafas'), findsOneWidget);
    expect(ctaRotulo(tester), 'Adicionar · ${const Dinheiro(5940).formatado} por entrega');
    expect(tester.widget<Opacity>(menos.first).opacity, 1);

    await tester.tap(find.byKey(const ValueKey('pdp-cta')));
    await tester.pump();
    expect(sacola.quantidadeDe('WP500'), 6);
    expect(ctaRotulo(tester), startsWith('Atualizar quantidade'));
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('P2.4: Semantics Voltar / Diminuir / Aumentar + preço sob o título', (tester) async {
    await abrir(tester, 'WP500');
    expect(find.bySemanticsLabel('Voltar'), findsOneWidget);
    expect(find.bySemanticsLabel('Diminuir quantidade'), findsOneWidget);
    expect(find.bySemanticsLabel('Aumentar quantidade'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^Quantidade: ½ caixa')), findsOneWidget);
    expect(find.byKey(const ValueKey('pdp-proximo-passo')), findsOneWidget);

    // Voltar: 48 de toque.
    expect(tester.getSize(find.byKey(const ValueKey('pdp-voltar'))), const Size(48, 48));
  });

  testWidgets('P2.4: fonte 200% não quebra o CTA (altura cresce)', (tester) async {
    await abrir(tester, 'WP500', escala: 2);
    expect(tester.takeException(), isNull);
    final cta = tester.getSize(find.byKey(const ValueKey('pdp-cta')));
    expect(cta.height, greaterThanOrEqualTo(AppSpacing.alturaBotao));
  });
}
