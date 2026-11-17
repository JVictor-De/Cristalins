// Marketplace v3 — fluxos sacola + smoke animação PDP mineral (mocks, sem API).
//
//   cd app && flutter test integration_test/marketplace_fluxo_test.dart
//
// Cobertura: (1) só água → mínimo (2) WP mista (3) smoke CenaImpactoAgua na PDP AMS500.
// Empty catalog (#33) fica em test/features/catalog/empty_catalogo_test.dart.

import 'package:cristalins_assinatura/core/formatacao.dart';
import 'package:cristalins_assinatura/core/theme/app_colors.dart';
import 'package:cristalins_assinatura/core/theme/app_theme.dart';
import 'package:cristalins_assinatura/core/widgets/cena_impacto_agua.dart';
import 'package:cristalins_assinatura/core/widgets/sugestao_minimo_cesta.dart';
import 'package:cristalins_assinatura/features/catalog/domain/catalogo.dart';
import 'package:cristalins_assinatura/features/catalog/presentation/produto_screen.dart';
import 'package:cristalins_assinatura/features/catalog/presentation/sacola_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../test/support/mocks.dart';

class _MockStorage extends Mock implements FlutterSecureStorage {}

const _agua = Produto(
  codigo: 'AMS500',
  nome: 'Água mineral 500 ml',
  tipo: 'COMPLEMENTO',
  volumeMl: 500,
  embalagemQtd: 12,
  precoBase: Dinheiro(220),
);

const _wp = Produto(
  codigo: 'WP500',
  nome: 'Water Protein',
  tipo: 'PRINCIPAL',
  volumeMl: 500,
  embalagemQtd: 6,
  precoBase: Dinheiro(990),
);

const _fiber = Produto(
  codigo: 'FF500',
  nome: 'Flow Fiber',
  tipo: 'PRINCIPAL',
  volumeMl: 500,
  embalagemQtd: 6,
  precoBase: Dinheiro(990),
);

Simulacao _sim({
  required List<ItemSimulado> itens,
  required num ue,
  num falta = 0,
}) {
  return Simulacao(
    itens: itens,
    ue: ue,
    subtotal: Dinheiro((ue * 220).round()),
    frete: const Dinheiro(990),
    total: Dinheiro((ue * 220).round() + 990),
    detalhe: const [],
    ueMinima: 12,
    faltaUeParaMinimo: falta,
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
    registrarFallbacks();
  });

  late Mocks mocks;
  late _MockStorage storage;
  late SacolaController sacola;

  setUp(() {
    mocks = Mocks();
    storage = _MockStorage();
    when(() => storage.read(key: any(named: 'key'))).thenAnswer((_) async => null);
    when(() => storage.write(key: any(named: 'key'), value: any(named: 'value')))
        .thenAnswer((_) async {});
    when(() => mocks.catalogo.produtos()).thenAnswer((_) async => [_agua, _wp, _fiber]);
    when(() => mocks.catalogo.kits()).thenAnswer((_) async => <Kit>[]);
    sacola = SacolaController(mocks.catalogo, storage: storage, atraso: Duration.zero);
    sacola.produtos = [_agua, _wp, _fiber];
    sacola.kits = [];
    sacola.carregandoCatalogo = false;
  });

  tearDown(() {
    sacola.dispose();
  });

  Widget envelopar(Widget filho) {
    return MaterialApp(
      theme: buildAppTheme(),
      home: ChangeNotifierProvider<SacolaController>.value(
        value: sacola,
        child: Scaffold(backgroundColor: AppColors.gelo, body: filho),
      ),
    );
  }

  testWidgets('(1) só água → abaixo do mínimo → sugestão → fecha mínimo', (tester) async {
    // 6 un. de AMS500 = 6 UE → falta 6
    mocks.simularDevolve(
      _sim(
        itens: const [ItemSimulado(produto: 'AMS500', quantidade: 6, precoUnitario: Dinheiro(220))],
        ue: 6,
        falta: 6,
      ),
    );
    await tester.pumpWidget(envelopar(const SizedBox.shrink()));
    sacola.alterar('AMS500', 6);
    await tester.pump(const Duration(milliseconds: 1));
    await sacola.simular();
    await tester.pump();

    expect(sacola.simulacao?.abaixoDoMinimo, isTrue);
    expect(sacola.sugerirParaMinimo()?.codigo, 'AMS500'); // nunca WP

    await tester.pumpWidget(
      envelopar(
        ListView(
          children: const [
            Text('abaixo'),
            SugestaoMinimoCesta(),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    // P5.2: copy visível usa nome curto; Semantics guarda o nome API completo.
    expect(find.textContaining('Adicionar Sem gás'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp(r'Adicionar Água mineral')),
      findsOneWidget,
    );

    // Fecha o mínimo: 12 un. → falta 0
    mocks.simularDevolve(
      _sim(
        itens: const [ItemSimulado(produto: 'AMS500', quantidade: 12, precoUnitario: Dinheiro(220))],
        ue: 12,
      ),
    );
    await tester.tap(find.byType(TextButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await sacola.simular();
    await tester.pump();

    expect(sacola.quantidadeDe('AMS500'), greaterThanOrEqualTo(12));
    expect(sacola.quantidadeDe('WP500'), 0);
    expect(sacola.simulacao?.abaixoDoMinimo, isFalse);
  });

  testWidgets('(2) WP mista — WP + água na mesma sacola', (tester) async {
    mocks.simularDevolve(
      _sim(
        itens: const [
          ItemSimulado(produto: 'WP500', quantidade: 6, precoUnitario: Dinheiro(990)),
          ItemSimulado(produto: 'AMS500', quantidade: 12, precoUnitario: Dinheiro(220)),
        ],
        ue: 18,
      ),
    );

    await tester.pumpWidget(envelopar(const SizedBox.shrink()));
    sacola.adicionarPasso(_wp); // +3 (passo WP = embalagem/2)
    sacola.adicionarPasso(_wp);
    sacola.alterar('AMS500', 12);
    await tester.pump(const Duration(milliseconds: 1));
    await sacola.simular();
    await tester.pump();

    expect(sacola.quantidadeDe('WP500'), greaterThan(0));
    expect(sacola.quantidadeDe('AMS500'), 12);
    expect(sacola.itens.length, 2);
    expect(sacola.simulacao?.abaixoDoMinimo, isFalse);
    expect(sacola.frequencia, 'QUINZENAL');
    expect(sacola.plano, 'FLEX');
  });

  testWidgets('(3) smoke animação na PDP mineral (AMS500)', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(envelopar(const ProdutoScreen(codigo: 'AMS500')));
    await tester.pump(); // 1º frame
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(CenaImpactoAgua), findsOneWidget);
    expect(find.text('Ver de novo'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'Água mineral tem nome: Cristalins. Garrafa de água mineral sem gás toca a água com um respingo.',
      ),
      findsOneWidget,
    );

    // WP não usa a cena mineral
    await tester.pumpWidget(envelopar(const ProdutoScreen(codigo: 'WP500')));
    await tester.pump();
    expect(find.byType(CenaImpactoAgua), findsNothing);
  });
}
