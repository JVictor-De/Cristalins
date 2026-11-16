import 'package:cristalins_assinatura/core/formatacao.dart';
import 'package:cristalins_assinatura/core/theme/app_colors.dart';
import 'package:cristalins_assinatura/core/theme/app_theme.dart';
import 'package:cristalins_assinatura/core/widgets/barra_sacola.dart';
import 'package:cristalins_assinatura/core/widgets/botao_principal.dart';
import 'package:cristalins_assinatura/core/widgets/card_kit.dart';
import 'package:cristalins_assinatura/core/widgets/card_produto.dart';
import 'package:cristalins_assinatura/core/widgets/card_proxima_entrega.dart';
import 'package:cristalins_assinatura/core/widgets/chip_categoria.dart';
import 'package:cristalins_assinatura/core/widgets/detalhe_preco_expansivel.dart';
import 'package:cristalins_assinatura/core/widgets/empty_assinatura.dart';
import 'package:cristalins_assinatura/core/widgets/folha_arredondada.dart';
import 'package:cristalins_assinatura/core/widgets/hero_water_protein.dart';
import 'package:cristalins_assinatura/core/widgets/secao_com_titulo.dart';
import 'package:cristalins_assinatura/core/widgets/selo_promo.dart';
import 'package:cristalins_assinatura/core/widgets/seletor_opcao.dart';
import 'package:cristalins_assinatura/core/widgets/skeleton_card.dart';
import 'package:cristalins_assinatura/core/widgets/stepper_quantidade.dart';
import 'package:cristalins_assinatura/core/widgets/sugestao_minimo_cesta.dart';
import 'package:cristalins_assinatura/features/catalog/domain/catalogo.dart';
import 'package:cristalins_assinatura/features/catalog/presentation/sacola_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../support/mocks.dart';

class _MockStorage extends Mock implements FlutterSecureStorage {}

/// Goldens marketplace v3. Contraste CTA: branco sobre azulMarca (AA ~4,51).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  const wp = Produto(
    codigo: 'WP500',
    nome: 'Water Protein',
    tipo: 'PRINCIPAL',
    volumeMl: 500,
    embalagemQtd: 6,
    precoBase: Dinheiro(990),
  );

  const agua = Produto(
    codigo: 'AMS500',
    nome: 'Água mineral 500 ml',
    tipo: 'COMPLEMENTO',
    volumeMl: 500,
    embalagemQtd: 12,
    precoBase: Dinheiro(220),
  );

  Widget envelopar(Widget filho, {SacolaController? sacola, Size size = const Size(390, 844)}) {
    Widget home = Scaffold(
      backgroundColor: AppColors.gelo,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(padding: const EdgeInsets.all(16), child: filho),
        ),
      ),
    );
    if (sacola != null) {
      home = ChangeNotifierProvider<SacolaController>.value(value: sacola, child: home);
    }
    return MaterialApp(
      theme: buildAppTheme(),
      home: MediaQuery(data: MediaQueryData(size: size), child: home),
    );
  }

  SacolaController sacolaComItens() {
    final mocks = Mocks();
    when(() => mocks.catalogo.produtos()).thenAnswer((_) async => [wp, agua]);
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
    final s = SacolaController(mocks.catalogo, storage: storage, atraso: Duration.zero);
    s.produtos = [wp, agua];
    s.quantidades['AMS500'] = 12;
    s.simulacao = const Simulacao(
      itens: [ItemSimulado(produto: 'AMS500', quantidade: 12, precoUnitario: Dinheiro(220))],
      ue: 6,
      subtotal: Dinheiro(2640),
      frete: Dinheiro(990),
      total: Dinheiro(3630),
      detalhe: [LinhaPreco(fator: 'FRETE', valor: Dinheiro(990))],
      ueMinima: 12,
      faltaUeParaMinimo: 6,
    );
    return s;
  }

  testWidgets('golden BotaoPrincipal primaria (contraste AA azulMarca)', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(envelopar(BotaoPrincipal(rotulo: 'Continuar', onPressed: () {})));
    expect(AppColors.azulMarca, const Color(0xFF087FAE));
    await expectLater(find.byType(BotaoPrincipal), matchesGoldenFile('mk_botao_principal.png'));
  });

  testWidgets('golden CardProduto sem preço', (tester) async {
    await tester.binding.setSurfaceSize(const Size(200, 280));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      envelopar(
        SizedBox(
          width: 160,
          height: 240,
          child: CardProduto(produto: wp, onAbrir: () {}, onAdicionar: () {}),
        ),
      ),
    );
    expect(find.textContaining('R\$'), findsNothing);
    await expectLater(find.byType(CardProduto), matchesGoldenFile('mk_card_produto.png'));
  });

  testWidgets('golden CardKit sem preço', (tester) async {
    await tester.binding.setSurfaceSize(const Size(260, 180));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      envelopar(
        SizedBox(
          height: 140,
          child: CardKit(
            nome: 'Kit Treino',
            resumoItens: '12× Water Protein',
            onTap: () {},
            onAdicionar: () {},
          ),
        ),
      ),
    );
    expect(find.textContaining('R\$'), findsNothing);
    await expectLater(find.byType(CardKit), matchesGoldenFile('mk_card_kit.png'));
  });

  testWidgets('golden HeroWaterProtein', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      envelopar(HeroWaterProtein(onAssinar: () {}, onVerAguas: () {}), size: const Size(400, 800)),
    );
    await tester.pump();
    await expectLater(find.byType(HeroWaterProtein), matchesGoldenFile('mk_hero_wp.png'));
  });

  testWidgets('golden ChipCategoria', (tester) async {
    await tester.binding.setSurfaceSize(const Size(200, 80));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      envelopar(ChipCategoria(rotulo: 'Águas', selecionado: true, onTap: () {})),
    );
    await expectLater(find.byType(ChipCategoria), matchesGoldenFile('mk_chip_categoria.png'));
  });

  testWidgets('golden StepperQuantidade', (tester) async {
    await tester.binding.setSurfaceSize(const Size(240, 80));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      envelopar(
        StepperQuantidade(quantidade: 12, passo: 6, rotulo: 'Water Protein', onAlterar: (_) {}),
      ),
    );
    await expectLater(find.byType(StepperQuantidade), matchesGoldenFile('mk_stepper.png'));
  });

  testWidgets('golden SeletorOpcao', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      envelopar(
        SeletorOpcao(
          opcoes: const ['Semanal', 'Quinzenal', 'Mensal'],
          selecionado: 'Quinzenal',
          onChanged: (_) {},
        ),
      ),
    );
    await expectLater(find.byType(SeletorOpcao), matchesGoldenFile('mk_seletor_opcao.png'));
  });

  testWidgets('golden SeloPromo', (tester) async {
    await tester.binding.setSurfaceSize(const Size(120, 60));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(envelopar(const SeloPromo(texto: 'Novo')));
    await expectLater(find.byType(SeloPromo), matchesGoldenFile('mk_selo_promo.png'));
  });

  testWidgets('golden SecaoComTitulo', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 140));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      envelopar(
        SecaoComTitulo(
          titulo: 'Produtos',
          acaoRotulo: 'Ver todos',
          onAcao: () {},
          child: const SizedBox(height: 40, child: ColoredBox(color: AppColors.menta)),
        ),
      ),
    );
    await expectLater(find.byType(SecaoComTitulo), matchesGoldenFile('mk_secao.png'));
  });

  testWidgets('golden SkeletonCard', (tester) async {
    await tester.binding.setSurfaceSize(const Size(200, 160));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(envelopar(const SkeletonCard()));
    await expectLater(find.byType(SkeletonCard), matchesGoldenFile('mk_skeleton.png'));
  });

  testWidgets('golden FolhaArredondada', (tester) async {
    await tester.binding.setSurfaceSize(const Size(280, 120));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(envelopar(const FolhaArredondada(child: Text('Folha'))));
    await expectLater(find.byType(FolhaArredondada), matchesGoldenFile('mk_folha.png'));
  });

  testWidgets('golden EmptyAssinatura', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 420));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      envelopar(EmptyAssinatura(onMontarSacola: () {}, onVerAguas: () {}, onQuiz: () {})),
    );
    await expectLater(find.byType(EmptyAssinatura), matchesGoldenFile('mk_empty_assinatura.png'));
  });

  testWidgets('golden CardProximaEntrega', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 340));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          backgroundColor: AppColors.gelo,
          body: CardProximaEntrega(
            dataEntrega: '2026-11-16',
            status: 'Agendado',
            janela: '9h–13h',
            onEditarSacola: () {},
          ),
        ),
      ),
    );
    await expectLater(find.byType(CardProximaEntrega), matchesGoldenFile('mk_proxima_entrega.png'));
  });

  testWidgets('golden SugestaoMinimoCesta', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 80));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final sacola = sacolaComItens();
    await tester.pumpWidget(envelopar(const SugestaoMinimoCesta(), sacola: sacola));
    await tester.pump();
    await expectLater(find.byType(SugestaoMinimoCesta), matchesGoldenFile('mk_sugestao_minimo.png'));
  });

  testWidgets('golden BarraSacola', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 280));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final sacola = sacolaComItens();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: ChangeNotifierProvider<SacolaController>.value(
          value: sacola,
          child: const Scaffold(
            backgroundColor: AppColors.gelo,
            body: Align(alignment: Alignment.bottomCenter, child: BarraSacola()),
          ),
        ),
      ),
    );
    await tester.pump();
    await expectLater(find.byType(BarraSacola), matchesGoldenFile('mk_barra_sacola.png'));
  });

  testWidgets('golden DetalhePrecoExpansivel', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 220));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      envelopar(
        DetalhePrecoExpansivel(
          detalhe: const [LinhaPreco(fator: 'VOLUME', percentual: -8)],
          subtotal: const Dinheiro(20329),
          frete: const Dinheiro(990),
          total: const Dinheiro(21319),
        ),
      ),
    );
    await tester.tap(find.text('Ver detalhes do preço'));
    await tester.pumpAndSettle();
    await expectLater(find.byType(DetalhePrecoExpansivel), matchesGoldenFile('mk_detalhe_preco.png'));
  });

  testWidgets('semantics + do CardProduto', (tester) async {
    await tester.pumpWidget(
      envelopar(
        SizedBox(
          width: 160,
          height: 220,
          child: CardProduto(
            produto: const Produto(
              codigo: 'FF500',
              nome: 'Flow Fiber',
              tipo: 'PRINCIPAL',
              volumeMl: 500,
              embalagemQtd: 6,
              precoBase: Dinheiro(890),
            ),
            onAbrir: () {},
            onAdicionar: () {},
          ),
        ),
      ),
    );
    expect(
      find.byWidgetPredicate(
        (w) => w is Semantics && (w.properties.label?.contains('Adicionar Flow Fiber') ?? false),
      ),
      findsOneWidget,
    );
  });
}
