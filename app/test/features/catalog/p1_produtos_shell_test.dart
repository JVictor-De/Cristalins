import 'package:cristalins_assinatura/app.dart';
import 'package:cristalins_assinatura/core/config/app_config.dart';
import 'package:cristalins_assinatura/core/formatacao.dart';
import 'package:cristalins_assinatura/core/theme/app_colors.dart';
import 'package:cristalins_assinatura/core/theme/app_spacing.dart';
import 'package:cristalins_assinatura/core/theme/app_theme.dart';
import 'package:cristalins_assinatura/core/widgets/botao_sacola_badge.dart';
import 'package:cristalins_assinatura/core/widgets/card_produto.dart';
import 'package:cristalins_assinatura/features/catalog/domain/catalogo.dart';
import 'package:cristalins_assinatura/features/catalog/presentation/produtos_screen.dart';
import 'package:cristalins_assinatura/features/catalog/presentation/sacola_controller.dart';
import 'package:cristalins_assinatura/features/welcome/data/onboarding_prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../support/mocks.dart';

class _MockStorage extends Mock implements FlutterSecureStorage {}

/// Ordem da API hoje: tipo + código → FF500 antes de WP500.
const _ordemApi = [
  Produto(
    codigo: 'FF500',
    nome: 'Flow Fiber',
    tipo: 'PRINCIPAL',
    volumeMl: 500,
    embalagemQtd: 6,
    precoBase: Dinheiro(890),
  ),
  Produto(
    codigo: 'WP500',
    nome: 'Water Protein (água com colágeno)',
    tipo: 'PRINCIPAL',
    volumeMl: 500,
    embalagemQtd: 6,
    precoBase: Dinheiro(990),
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
    codigo: 'AMS500',
    nome: 'Água mineral sem gás',
    tipo: 'COMPLEMENTO',
    volumeMl: 500,
    embalagemQtd: 12,
    precoBase: Dinheiro(220),
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  SacolaController sacolaCom(List<Produto> produtos) {
    final mocks = Mocks();
    when(() => mocks.catalogo.produtos()).thenAnswer((_) async => produtos);
    when(() => mocks.catalogo.kits()).thenAnswer((_) async => <Kit>[]);
    final storage = _MockStorage();
    when(() => storage.read(key: any(named: 'key'))).thenAnswer((_) async => null);
    when(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
    final s = SacolaController(mocks.catalogo, storage: storage, atraso: Duration.zero);
    s.produtos = List.of(produtos);
    s.carregandoCatalogo = false;
    return s;
  }

  Future<void> montarProdutos(WidgetTester tester, {double escala = 1}) async {
    await tester.binding.setSurfaceSize(const Size(390, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(390, 1400),
            textScaler: TextScaler.linear(escala),
            disableAnimations: true,
          ),
          child: ChangeNotifierProvider<SacolaController>.value(
            value: sacolaCom(_ordemApi),
            child: const Scaffold(backgroundColor: AppColors.fundo, body: ProdutosScreen()),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  test('ordenarGradeProdutos: WP antes de FF; resto na ordem da API', () {
    final codigos = ordenarGradeProdutos(_ordemApi).map((p) => p.codigo).toList();
    expect(codigos, ['WP500', 'FF500', 'AMC510', 'AMS500']);
  });

  test('chip Funcionais virou “Proteína e fibras”', () {
    expect(Categoria.funcionais.rotulo, 'Proteína e fibras');
  });

  testWidgets('P1.4: grade espelha CardProduto, WP primeiro, gap 16, header com sacola', (
    tester,
  ) async {
    await montarProdutos(tester);

    final cards = find.byType(CardProduto);
    expect(cards, findsNWidgets(_ordemApi.length));
    expect(tester.widget<CardProduto>(cards.first).produto.codigo, 'WP500');

    // 2 colunas, gap horizontal 16.
    final a = tester.getRect(cards.at(0));
    final b = tester.getRect(cards.at(1));
    expect(b.left - a.right, closeTo(AppSpacing.margem, 0.5));
    expect(a.top, b.top);

    // Sem fade nos chips.
    expect(
      find.descendant(
        of: find.byType(ProdutosScreen),
        matching: find.byWidgetPredicate(
          (w) =>
              w is DecoratedBox &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).gradient != null,
        ),
      ),
      findsNothing,
    );

    expect(find.byType(BotaoSacolaBadge), findsOneWidget);
  });

  testWidgets('P1.4: fonte 200% → 1 coluna', (tester) async {
    await montarProdutos(tester, escala: 2);
    final cards = find.byType(CardProduto);
    final a = tester.getRect(cards.at(0));
    final b = tester.getRect(cards.at(1));
    expect(b.left, a.left);
    expect(b.top, greaterThan(a.bottom));
  });

  testWidgets('P1.4: aba ativa do shell usa indicador #E3EEF3', (tester) async {
    OnboardingPrefs.resetParaTeste();
    addTearDown(OnboardingPrefs.resetParaTeste);
    final mocks = Mocks();
    when(() => mocks.catalogo.produtos()).thenAnswer((_) async => const []);
    when(() => mocks.catalogo.kits()).thenAnswer((_) async => const []);
    when(() => mocks.assinaturas.listar()).thenAnswer((_) async => const []);
    await tester.pumpWidget(
      CristalinsApp(
        config: const AppConfig(
          ambiente: Ambiente.dev,
          apiUrl: 'http://10.0.2.2:3000',
          suporteWhatsapp: '',
        ),
        dependencias: mocks.dependencias,
        exibirSplash: false,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final barra = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(barra.indicatorColor, AppColors.indicadorAba);
    expect(AppColors.indicadorAba, const Color(0xFFE3EEF3));
    await tester.pump(const Duration(seconds: 2));
  });
}
