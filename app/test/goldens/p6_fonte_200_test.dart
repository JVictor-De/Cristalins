import 'package:cristalins_assinatura/core/config/app_config.dart';
import 'package:cristalins_assinatura/core/dependencias.dart';
import 'package:cristalins_assinatura/core/formatacao.dart';
import 'package:cristalins_assinatura/core/theme/app_colors.dart';
import 'package:cristalins_assinatura/core/theme/app_theme.dart';
import 'package:cristalins_assinatura/core/widgets/card_kit.dart';
import 'package:cristalins_assinatura/features/catalog/domain/catalogo.dart';
import 'package:cristalins_assinatura/features/catalog/presentation/produtos_screen.dart';
import 'package:cristalins_assinatura/features/catalog/presentation/sacola_controller.dart';
import 'package:cristalins_assinatura/features/catalog/presentation/sacola_screen.dart';
import 'package:cristalins_assinatura/features/home/presentation/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../support/fakes.dart';
import '../support/mocks.dart';

class _MockStorage extends Mock implements FlutterSecureStorage {}

/// P6: goldens com fonte do sistema a 200% (Home / Produtos / Sacola) num viewport
/// real de 390 × 844 — o que o usuário vê sem rolar. Também falha em overflow.
const _tela = Size(390, 844);
const _escala = TextScaler.linear(2);

/// Seed real (packs): WP/FF 6×500, AMS 12×500, AMC 12×510, AMN5000 5 L.
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
    codigo: 'AMN5000',
    nome: 'Água mineral natural (galão)',
    tipo: 'COMPLEMENTO',
    volumeMl: 5000,
    embalagemQtd: 1,
    precoBase: Dinheiro(990),
  ),
];

/// Kits do seed (`api/test/preco.e2e-spec.ts`): subtotalBase = Σ precoBase × qty.
const _kits = [
  Kit(
    codigo: 'KIT-TREINO',
    nome: 'Kit Treino',
    itens: [ItemCesta('WP500', 12)],
    subtotalBase: Dinheiro(11880),
  ),
  Kit(
    codigo: 'KIT-CASA',
    nome: 'Kit Casa',
    itens: [ItemCesta('WP500', 6), ItemCesta('AMN5000', 2)],
    subtotalBase: Dinheiro(7920),
  ),
];

Simulacao _simulacao(List<ItemCesta> itens) {
  final linhas = [
    for (final i in itens)
      ItemSimulado(
        produto: i.produto,
        quantidade: i.quantidade,
        precoUnitario: _seed.firstWhere((p) => p.codigo == i.produto).precoBase,
      ),
  ];
  final sub = linhas.fold(0, (a, l) => a + l.precoUnitario.centavos * l.quantidade);
  return Simulacao(
    itens: linhas,
    ue: 18,
    subtotal: Dinheiro(sub),
    frete: const Dinheiro(990),
    total: Dinheiro(sub + 990),
    detalhe: const [LinhaPreco(fator: 'FRETE', valor: Dinheiro(990))],
    faltaParaFreteGratis: 100,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
    registrarFallbacks();
  });

  late Mocks mocks;

  SacolaController sacolaCom({Map<String, int> qtds = const {}}) {
    mocks = Mocks();
    when(() => mocks.catalogo.produtos()).thenAnswer((_) async => _seed);
    when(() => mocks.catalogo.kits()).thenAnswer((_) async => _kits);
    when(
      () => mocks.catalogo.simular(
        itens: any(named: 'itens'),
        frequencia: any(named: 'frequencia'),
        plano: any(named: 'plano'),
        enderecoId: any(named: 'enderecoId'),
        cupom: any(named: 'cupom'),
      ),
    ).thenAnswer((inv) async => _simulacao(inv.namedArguments[#itens] as List<ItemCesta>));
    final storage = _MockStorage();
    when(() => storage.read(key: any(named: 'key'))).thenAnswer((_) async => null);
    when(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
    final s = SacolaController(mocks.catalogo, storage: storage, atraso: Duration.zero);
    s.produtos = _seed;
    s.kits = _kits;
    s.carregandoCatalogo = false;
    s.quantidades.addAll(qtds);
    return s;
  }

  Dependencias dependencias() => Dependencias(
    auth: AuthFalso(),
    recomendacoes: RecomendacoesFalsas(),
    catalogo: mocks.catalogo,
    enderecos: EnderecosFalsos(),
    assinaturas: AssinaturasFalsas(),
    ocorrencias: OcorrenciasFalsas(),
    api: null,
  );

  Future<void> montar(WidgetTester tester, SacolaController sacola, Widget tela) async {
    await tester.binding.setSurfaceSize(_tela);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(
            value: const AppConfig(ambiente: Ambiente.dev, apiUrl: '', suporteWhatsapp: ''),
          ),
          Provider.value(value: dependencias()),
          ChangeNotifierProvider.value(value: sacola),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: MediaQuery(
            data: const MediaQueryData(size: _tela, textScaler: _escala, disableAnimations: true),
            child: tela,
          ),
        ),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
  }

  testWidgets('golden Home a 200%', (tester) async {
    await montar(
      tester,
      sacolaCom(),
      Scaffold(
        backgroundColor: AppColors.fundo,
        body: HomeScreen(onAbrirProdutos: ({categoria}) {}, onAbrirAssinatura: () {}),
      ),
    );
    expect(tester.takeException(), isNull);
    await expectLater(find.byType(HomeScreen), matchesGoldenFile('p6_home_200.png'));
  });

  testWidgets('golden Produtos a 200% (1 coluna)', (tester) async {
    await montar(
      tester,
      sacolaCom(),
      const Scaffold(backgroundColor: AppColors.fundo, body: ProdutosScreen()),
    );
    expect(tester.takeException(), isNull);
    await expectLater(find.byType(ProdutosScreen), matchesGoldenFile('p6_produtos_200.png'));
  });

  testWidgets('golden Produtos › Kits a 200%: âncora de preço sem overflow', (tester) async {
    await montar(
      tester,
      sacolaCom(),
      const Scaffold(
        backgroundColor: AppColors.fundo,
        body: ProdutosScreen(categoriaInicial: Categoria.kits),
      ),
    );
    expect(tester.takeException(), isNull);
    final card = find.byType(CardKit).first;
    expect(tester.getSize(card).width, CardKit.larguraPara(_escala));
    expect(tester.getSize(card).height, CardKit.alturaPara(_escala));
    expect(find.textContaining(const Dinheiro(11880).formatado), findsOneWidget);
    expect(find.text('12× Water Protein'), findsOneWidget);
    await expectLater(find.byType(ProdutosScreen), matchesGoldenFile('p6_produtos_kits_200.png'));
  });

  testWidgets('golden Sacola a 200% (WP 6 + Sem gás 12)', (tester) async {
    await montar(tester, sacolaCom(qtds: {'WP500': 6, 'AMS500': 12}), const SacolaScreen());
    expect(tester.takeException(), isNull);
    await expectLater(find.byType(SacolaScreen), matchesGoldenFile('p6_sacola_200.png'));
  });
}
