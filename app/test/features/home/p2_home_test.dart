import 'package:cristalins_assinatura/core/config/app_config.dart';
import 'package:cristalins_assinatura/core/dependencias.dart';
import 'package:cristalins_assinatura/core/formatacao.dart';
import 'package:cristalins_assinatura/core/theme/app_theme.dart';
import 'package:cristalins_assinatura/core/widgets/card_proxima_entrega.dart';
import 'package:cristalins_assinatura/features/catalog/domain/catalogo.dart';
import 'package:cristalins_assinatura/features/catalog/presentation/sacola_controller.dart';
import 'package:cristalins_assinatura/features/home/presentation/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../support/fakes.dart';
import '../../support/mocks.dart';

class _MockStorage extends Mock implements FlutterSecureStorage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  testWidgets('home visitante: FAQ + oferta sem % + filtros', (tester) async {
    final mocks = Mocks();
    final produtos = [
      const Produto(
        codigo: 'WP500',
        nome: 'Water Protein',
        tipo: 'PRINCIPAL',
        volumeMl: 500,
        embalagemQtd: 6,
        precoBase: Dinheiro(990),
      ),
      const Produto(
        codigo: 'AMS500',
        nome: 'Água mineral sem gás',
        tipo: 'COMPLEMENTO',
        volumeMl: 500,
        embalagemQtd: 12,
        precoBase: Dinheiro(220),
      ),
      const Produto(
        codigo: 'AMN5000',
        nome: 'Água mineral natural (galão)',
        tipo: 'COMPLEMENTO',
        volumeMl: 5000,
        embalagemQtd: 1,
        precoBase: Dinheiro(990),
      ),
    ];
    when(() => mocks.catalogo.produtos()).thenAnswer((_) async => produtos);
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
    sacola.produtos = produtos;
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

    await tester.binding.setSurfaceSize(const Size(390, 1200));
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
          home: Scaffold(
            body: HomeScreen(onAbrirProdutos: ({categoria}) {}, onAbrirAssinatura: () {}),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining('primeira assinatura'), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
    // Chip de filtro + nome curto do card (P0.5).
    expect(find.text('Sem gás'), findsNWidgets(2));
    expect(find.text('Galão'), findsNWidgets(2));
    // Banner/selo promocionais removidos na crítica de hierarquia.
    expect(find.text('Da fonte ao Rio'), findsNothing);
    // P1.2: hint de frete grátis above-the-fold (RN18).
    expect(
      find.text('Frete grátis acima de ${const Dinheiro(25000).formatado} por entrega'),
      findsOneWidget,
    );
    // P1.1: “Alterar” não duplicado no chip CEP; logo no eixo da tela.
    expect(find.textContaining('Alterar CEP'), findsNothing);
    expect(find.text('Alterar'), findsOneWidget);
    final logo = tester.getCenter(find.byKey(const ValueKey('logo-home')));
    expect(logo.dx, closeTo(390 / 2, 1));

    await tester.scrollUntilVisible(
      find.text('Como funciona'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Como funciona'), findsOneWidget);
    // P1.3: rodapé “água mineral natural” removido (seção cobre WP/FF); “Flow Fiber” completo.
    expect(find.textContaining('Da fonte ao Rio'), findsNothing);
    expect(find.textContaining('Water Protein ou Flow Fiber'), findsOneWidget);
    // Lista vertical numerada: passos empilhados (x igual, y crescente).
    final p1 = tester.getTopLeft(find.text('Monte sua sacola'));
    final p2 = tester.getTopLeft(find.text('Escolha a frequência'));
    expect(p1.dx, p2.dx);
    expect(p2.dy, greaterThan(p1.dy));
    expect(find.text('1'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Perguntas frequentes'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Perguntas frequentes'), findsOneWidget);
    expect(find.text('Falar no WhatsApp'), findsNothing);
  });

  testWidgets('CardProximaEntrega tem atalhos Pular / Editar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: CardProximaEntrega(
            dataEntrega: '2026-11-20',
            onPularEntrega: () {},
            onEditarAssinatura: () {},
          ),
        ),
      ),
    );
    expect(find.text('Pular entrega'), findsOneWidget);
    expect(find.text('Editar assinatura'), findsOneWidget);
  });
}
