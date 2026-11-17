import 'package:cristalins_assinatura/core/formatacao.dart';
import 'package:cristalins_assinatura/core/theme/app_colors.dart';
import 'package:cristalins_assinatura/core/theme/app_theme.dart';
import 'package:cristalins_assinatura/core/widgets/barra_sacola.dart';
import 'package:cristalins_assinatura/core/widgets/botao_principal.dart';
import 'package:cristalins_assinatura/core/widgets/hero_water_protein.dart';
import 'package:cristalins_assinatura/features/catalog/domain/catalogo.dart';
import 'package:cristalins_assinatura/features/catalog/domain/sacola_copy.dart';
import 'package:cristalins_assinatura/features/catalog/presentation/sacola_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../support/mocks.dart';

class _MockStorage extends Mock implements FlutterSecureStorage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('hero P1.2: sem “Mais vendido”, claims do lote PDP, a partir de', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844), disableAnimations: true),
          child: Scaffold(
            backgroundColor: AppColors.fundo,
            body: HeroWaterProtein(
              onAssinar: () {},
              onAbrirProduto: () {},
              precoAPartirDe: const Dinheiro(990),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    // Claim sem fonte removido (P1.2).
    expect(find.text('Mais vendido'), findsNothing);
    expect(find.text('Carro-chefe'), findsNothing);
    expect(find.text('Assinar agora'), findsOneWidget);
    expect(find.text('Ver todas as águas'), findsNothing);
    expect(find.textContaining('5 g de proteína'), findsOneWidget);
    expect(find.text('Com colágeno'), findsOneWidget);
    // “Zero açúcar” só com rótulo confirmado (gate).
    expect(find.textContaining('açúcar'), findsNothing);
    // Título na escala do DS (title1 28 em mobile), não 30 avulso.
    final titulo = tester.widget<Text>(find.text('Water Protein'));
    expect(titulo.style?.fontSize, 28);
    expect(find.textContaining('Na assinatura, a partir de'), findsOneWidget);
    expect(find.textContaining('/garrafa'), findsOneWidget);
  });

  testWidgets('BarraSacola: copy N itens · total por entrega + botão preenchido', (tester) async {
    final mocks = Mocks();
    when(() => mocks.catalogo.produtos()).thenAnswer((_) async => <Produto>[]);
    when(() => mocks.catalogo.kits()).thenAnswer((_) async => <Kit>[]);
    mocks.simularDevolve(
      const Simulacao(
        itens: [ItemSimulado(produto: 'AMS500', quantidade: 12, precoUnitario: Dinheiro(220))],
        ue: 6,
        subtotal: Dinheiro(2640),
        frete: Dinheiro(990),
        total: Dinheiro(3630),
        detalhe: [],
        ueMinima: 12,
        faltaUeParaMinimo: 6,
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
    sacola.produtos = const [];
    sacola.quantidades['AMS500'] = 12;
    sacola.simulacao = const Simulacao(
      itens: [ItemSimulado(produto: 'AMS500', quantidade: 12, precoUnitario: Dinheiro(220))],
      ue: 6,
      subtotal: Dinheiro(2640),
      frete: Dinheiro(990),
      total: Dinheiro(3630),
      detalhe: [],
      ueMinima: 12,
      faltaUeParaMinimo: 6,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: ChangeNotifierProvider.value(
          value: sacola,
          child: const Scaffold(
            body: Align(alignment: Alignment.bottomCenter, child: BarraSacola()),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.textContaining('por entrega'), findsOneWidget);
    expect(find.textContaining('12 itens'), findsOneWidget);
    expect(find.widgetWithText(BotaoPrincipal, 'Ver sacola'), findsOneWidget);
  });

  testWidgets('BarraSacola P1.4: total + “Faltam R\$ X para frete grátis” da simulação', (
    tester,
  ) async {
    final mocks = Mocks();
    when(() => mocks.catalogo.produtos()).thenAnswer((_) async => <Produto>[]);
    when(() => mocks.catalogo.kits()).thenAnswer((_) async => <Kit>[]);
    const sim = Simulacao(
      itens: [ItemSimulado(produto: 'AMS500', quantidade: 24, precoUnitario: Dinheiro(220))],
      ue: 24,
      subtotal: Dinheiro(5280),
      frete: Dinheiro(990),
      total: Dinheiro(6270),
      detalhe: [],
      ueMinima: 12,
      faltaParaFreteGratis: 197.20,
    );
    mocks.simularDevolve(sim);
    final storage = _MockStorage();
    when(() => storage.read(key: any(named: 'key'))).thenAnswer((_) async => null);
    when(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
    final sacola = SacolaController(mocks.catalogo, storage: storage, atraso: Duration.zero);
    sacola.produtos = const [];
    sacola.quantidades['AMS500'] = 24;
    sacola.simulacao = sim;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: ChangeNotifierProvider.value(
          value: sacola,
          child: const Scaffold(
            body: Align(alignment: Alignment.bottomCenter, child: BarraSacola()),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.textContaining(const Dinheiro(6270).formatado), findsOneWidget);
    expect(
      find.text('Faltam ${const Dinheiro(19720).formatado} para frete grátis'),
      findsOneWidget,
    );
  });

  test('SacolaCopy frete: sem hint quando já grátis; limite RN18 formatado', () {
    const gratis = Simulacao(
      itens: [],
      ue: 24,
      subtotal: Dinheiro(26000),
      frete: Dinheiro(0),
      total: Dinheiro(26000),
      detalhe: [],
    );
    expect(SacolaCopy.faltaFreteGratis(gratis), isNull);
    expect(
      SacolaCopy.freteGratisAcima(50),
      'Frete grátis acima de ${const Dinheiro(5000).formatado} por entrega',
    );
  });

  test('fundo token P1', () {
    expect(AppColors.fundo, const Color(0xFFF6F9FB));
  });
}
