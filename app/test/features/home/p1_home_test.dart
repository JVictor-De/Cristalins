import 'package:cristalins_assinatura/core/formatacao.dart';
import 'package:cristalins_assinatura/core/theme/app_colors.dart';
import 'package:cristalins_assinatura/core/theme/app_theme.dart';
import 'package:cristalins_assinatura/core/widgets/barra_sacola.dart';
import 'package:cristalins_assinatura/core/widgets/botao_principal.dart';
import 'package:cristalins_assinatura/core/widgets/hero_water_protein.dart';
import 'package:cristalins_assinatura/features/catalog/domain/catalogo.dart';
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

  testWidgets('hero: Mais vendido, a partir de, sem Carro-chefe', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: Scaffold(
            backgroundColor: AppColors.fundo,
            body: HeroWaterProtein(
              onAssinar: () {},
              onVerAguas: () {},
              precoAPartirDe: const Dinheiro(990),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Mais vendido'), findsOneWidget);
    expect(find.text('Carro-chefe'), findsNothing);
    expect(find.textContaining('5 g de proteína por garrafa'), findsOneWidget);
    expect(find.textContaining('a partir de'), findsOneWidget);
    expect(find.textContaining('/un.'), findsOneWidget);
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
    when(() => storage.write(key: any(named: 'key'), value: any(named: 'value'))).thenAnswer((_) async {});
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

  test('fundo token P1', () {
    expect(AppColors.fundo, const Color(0xFFF6F9FB));
  });
}
