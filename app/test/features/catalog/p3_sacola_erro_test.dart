import 'package:cristalins_assinatura/core/dependencias.dart';
import 'package:cristalins_assinatura/core/formatacao.dart';
import 'package:cristalins_assinatura/core/network/api_erro.dart';
import 'package:cristalins_assinatura/core/theme/app_theme.dart';
import 'package:cristalins_assinatura/core/widgets/botao_principal.dart';
import 'package:cristalins_assinatura/core/widgets/detalhe_preco_expansivel.dart';
import 'package:cristalins_assinatura/features/catalog/domain/catalogo.dart';
import 'package:cristalins_assinatura/features/catalog/domain/sacola_copy.dart';
import 'package:cristalins_assinatura/features/catalog/presentation/sacola_controller.dart';
import 'package:cristalins_assinatura/features/catalog/presentation/sacola_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../support/fakes.dart';
import '../../support/mocks.dart';

class _MockStorage extends Mock implements FlutterSecureStorage {}

const _wp = Produto(
  codigo: 'WP500',
  nome: 'Water Protein (água com colágeno)',
  tipo: 'PRINCIPAL',
  volumeMl: 500,
  embalagemQtd: 6,
  precoBase: Dinheiro(990),
);

const _ff = Produto(
  codigo: 'FF500',
  nome: 'Flow Fiber',
  tipo: 'PRINCIPAL',
  volumeMl: 500,
  embalagemQtd: 6,
  precoBase: Dinheiro(890),
);

const _agua = Produto(
  codigo: 'AMS500',
  nome: 'Água mineral sem gás',
  tipo: 'COMPLEMENTO',
  volumeMl: 500,
  embalagemQtd: 12,
  precoBase: Dinheiro(220),
);

/// Simulação “OK” devolvida pela API fake para a cesta recebida (valores ilustrativos).
Simulacao _simOk(List<ItemCesta> itens) {
  final linhas = [
    for (final i in itens)
      ItemSimulado(
        produto: i.produto,
        quantidade: i.quantidade,
        precoUnitario: switch (i.produto) {
          'WP500' => const Dinheiro(990),
          'FF500' => const Dinheiro(890),
          _ => const Dinheiro(220),
        },
      ),
  ];
  final sub = linhas.fold(0, (a, l) => a + l.precoUnitario.centavos * l.quantidade);
  return Simulacao(
    itens: linhas,
    ue: 12,
    subtotal: Dinheiro(sub),
    frete: const Dinheiro(990),
    total: Dinheiro(sub + 990),
    detalhe: const [],
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
  late SacolaController sacola;

  /// API fake: recusa caixa mista incompleta (RN04) como a API real; senão simula.
  void apiComRegraCaixa() {
    when(
      () => mocks.catalogo.simular(
        itens: any(named: 'itens'),
        frequencia: any(named: 'frequencia'),
        plano: any(named: 'plano'),
        enderecoId: any(named: 'enderecoId'),
        cupom: any(named: 'cupom'),
      ),
    ).thenAnswer((inv) async {
      final itens = inv.namedArguments[#itens] as List<ItemCesta>;
      final mista = itens
          .where((i) => SacolaController.caixaMista.contains(i.produto))
          .fold(0, (a, i) => a + i.quantidade);
      if (mista % 6 != 0) {
        throw const ApiErro(
          codigo: 'EMBALAGEM_INVALIDA',
          mensagem: 'Water Protein vem em caixas de 6: faltam 3 garrafas para completar a caixa.',
        );
      }
      return _simOk(itens);
    });
  }

  Future<void> montar(WidgetTester tester, Map<String, int> qtds) async {
    mocks = Mocks();
    when(() => mocks.catalogo.produtos()).thenAnswer((_) async => [_wp, _ff, _agua]);
    when(() => mocks.catalogo.kits()).thenAnswer((_) async => <Kit>[]);
    apiComRegraCaixa();
    final storage = _MockStorage();
    when(() => storage.read(key: any(named: 'key'))).thenAnswer((_) async => null);
    when(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
    sacola = SacolaController(mocks.catalogo, storage: storage, atraso: Duration.zero);
    sacola.quantidades.addAll(qtds);

    final dep = Dependencias(
      auth: AuthFalso(),
      recomendacoes: RecomendacoesFalsas(),
      catalogo: mocks.catalogo,
      enderecos: EnderecosFalsos(),
      assinaturas: AssinaturasFalsas(),
      ocorrencias: OcorrenciasFalsas(),
      api: null,
    );

    await tester.binding.setSurfaceSize(const Size(390, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: dep),
          ChangeNotifierProvider.value(value: sacola),
        ],
        child: MaterialApp(theme: buildAppTheme(), home: const SacolaScreen()),
      ),
    );
    // Restaura storage → carrega catálogo → simula (API fake).
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
  }

  BotaoPrincipal continuar(WidgetTester tester) =>
      tester.widget<BotaoPrincipal>(find.byKey(const ValueKey('sacola-continuar')));

  test('copy da caixa: não cita Flow Fiber quando só há WP', () {
    expect(
      SacolaCopy.faltaCaixa(falta: 3, tamanho: 6, mista: false),
      'Faltam 3 garrafas para completar a caixa de 6.',
    );
    expect(
      SacolaCopy.faltaCaixa(falta: 3, tamanho: 6, mista: true),
      contains('Water Protein + Flow Fiber'),
    );
  });

  testWidgets('WP=3 sozinho: erro no card + Completar caixa + resumo visível', (tester) async {
    await montar(tester, {'WP500': 3});

    // RN intocável: passo continua 3.
    expect(sacola.passo(_wp), 3);
    expect(sacola.simulacao, isNull);
    expect(sacola.erroSimulacao, isNotNull);

    // Erro acionável no card do SKU, sem citar FF ausente.
    expect(find.byKey(const ValueKey('sacola-erro-WP500')), findsOneWidget);
    expect(find.text('Faltam 3 garrafas para completar a caixa de 6.'), findsOneWidget);
    expect(find.textContaining('Flow Fiber'), findsNothing);
    expect(find.byKey(const ValueKey('sacola-completar-WP500')), findsOneWidget);

    // Resumo NÃO some: estimativa pelo preço base + preço da linha.
    expect(find.byKey(const ValueKey('sacola-resumo-estimado')), findsOneWidget);
    expect(find.textContaining(const Dinheiro(2970).formatado), findsWidgets);
    expect(find.text('Total por entrega'), findsOneWidget);

    // Continuar bloqueado com motivo visível ao lado.
    expect(continuar(tester).onPressed, isNull);
    expect(find.text(SacolaCopy.motivoCaixaIncompleta), findsOneWidget);

    // Completar caixa → 6 garrafas → simulação válida com preços.
    await tester.tap(find.byKey(const ValueKey('sacola-completar-WP500')));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
    expect(sacola.quantidadeDe('WP500'), 6);
    expect(sacola.simulacao, isNotNull);
    expect(find.byKey(const ValueKey('sacola-erro-WP500')), findsNothing);
    expect(find.byKey(const ValueKey('sacola-resumo-estimado')), findsNothing);
    expect(find.byType(DetalhePrecoExpansivel), findsOneWidget);
    expect(find.byKey(const ValueKey('sacola-motivo')), findsNothing);
    expect(continuar(tester).onPressed, isNotNull);
    expect(continuar(tester).rotulo, startsWith('Continuar · '));
    expect(continuar(tester).variante, VarianteBotaoPrincipal.cta);
  });

  testWidgets('WP=6: preços da simulação, sem erro', (tester) async {
    await montar(tester, {'WP500': 6});
    expect(sacola.simulacao, isNotNull);
    expect(find.byKey(const ValueKey('sacola-erro-WP500')), findsNothing);
    expect(find.text(const Dinheiro(5940).formatado), findsWidgets);
    expect(continuar(tester).onPressed, isNotNull);
  });

  testWidgets('3 WP + 3 FF: caixa mista fecha, simula OK', (tester) async {
    await montar(tester, {'WP500': 3, 'FF500': 3});
    expect(sacola.faltaParaCompletarCaixa(_wp), 0);
    expect(sacola.simulacao, isNotNull);
    expect(find.byKey(const ValueKey('sacola-erro-WP500')), findsNothing);
    expect(find.byKey(const ValueKey('sacola-erro-FF500')), findsNothing);
    expect(continuar(tester).onPressed, isNotNull);
  });

  testWidgets('3 WP + 6 FF: erro único citando os dois (ambos presentes)', (tester) async {
    await montar(tester, {'WP500': 3, 'FF500': 6});
    expect(sacola.faltaParaCompletarCaixa(_wp), 3);
    final erros = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('sacola-erro-') &&
          (w.key! as ValueKey<String>).value != 'sacola-erro-api',
    );
    expect(erros, findsOneWidget);
    expect(find.textContaining('Water Protein + Flow Fiber'), findsOneWidget);
  });

  testWidgets('P3.2/P3.3: AppBar, frete com barra, plano, remover com Desfazer', (tester) async {
    await montar(tester, {'AMS500': 24});
    expect(find.descendant(of: find.byType(AppBar), matching: find.text('Sacola')), findsOneWidget);
    expect(find.text('1 produto'), findsOneWidget);
    expect(find.byKey(const ValueKey('sacola-frete-barra')), findsOneWidget);
    expect(find.text(SacolaCopy.descricaoPlano('FLEX')), findsOneWidget);
    expect(find.text('Dados protegidos'), findsNothing);
    expect(find.text(SacolaCopy.proximoPasso), findsOneWidget);

    await tester.tap(find.byTooltip('Remover Sem gás'));
    await tester.pump();
    expect(sacola.quantidadeDe('AMS500'), 0);
    expect(find.text('Desfazer'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 600)); // entrada do SnackBar
    await tester.tap(find.text('Desfazer'));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
    expect(sacola.quantidadeDe('AMS500'), 24);
    await tester.pump(const Duration(seconds: 5));
  });
}
