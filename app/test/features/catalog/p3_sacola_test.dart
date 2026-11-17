import 'package:cristalins_assinatura/core/dependencias.dart';
import 'package:cristalins_assinatura/core/formatacao.dart';
import 'package:cristalins_assinatura/core/theme/app_theme.dart';
import 'package:cristalins_assinatura/core/widgets/barra_sacola.dart';
import 'package:cristalins_assinatura/core/widgets/botao_principal.dart';
import 'package:cristalins_assinatura/features/catalog/domain/catalogo.dart';
import 'package:cristalins_assinatura/features/catalog/domain/sacola_copy.dart';
import 'package:cristalins_assinatura/features/catalog/presentation/sacola_controller.dart';
import 'package:cristalins_assinatura/features/catalog/presentation/sacola_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../support/fakes.dart';
import '../../support/mocks.dart';

class _MockStorage extends Mock implements FlutterSecureStorage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('SacolaCopy: total compartilhado barra/sacola', () {
    const total = Dinheiro(3630);
    expect(SacolaCopy.totalPorEntrega(total), contains(total.formatado));
    expect(SacolaCopy.totalPorEntrega(total), endsWith('por entrega'));
    expect(
      SacolaCopy.itensETotalPorEntrega(12, total),
      '12 itens · ${total.formatado} por entrega',
    );
    expect(SacolaCopy.aproximadoMes(total, 'QUINZENAL'), contains('/mês'));
  });

  testWidgets('Sacola: Continuar navy + config + total por entrega', (tester) async {
    final mocks = Mocks();
    const produto = Produto(
      codigo: 'AMS500',
      nome: 'Água mineral sem gás',
      tipo: 'COMPLEMENTO',
      volumeMl: 500,
      embalagemQtd: 12,
      precoBase: Dinheiro(220),
    );
    when(() => mocks.catalogo.produtos()).thenAnswer((_) async => [produto]);
    when(() => mocks.catalogo.kits()).thenAnswer((_) async => <Kit>[]);
    const sim = Simulacao(
      itens: [ItemSimulado(produto: 'AMS500', quantidade: 24, precoUnitario: Dinheiro(220))],
      ue: 12,
      subtotal: Dinheiro(5280),
      frete: Dinheiro(990),
      total: Dinheiro(6270),
      detalhe: [],
      ueMinima: 12,
      faltaUeParaMinimo: 0,
      economiaPlano: 12.5,
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
    sacola.produtos = [produto];
    sacola.carregandoCatalogo = false;
    sacola.quantidades['AMS500'] = 24;
    sacola.simulacao = sim;

    final dep = Dependencias(
      auth: AuthFalso(),
      recomendacoes: RecomendacoesFalsas(),
      catalogo: mocks.catalogo,
      enderecos: EnderecosFalsos(),
      assinaturas: AssinaturasFalsas(),
      ocorrencias: OcorrenciasFalsas(),
      api: null,
    );

    await tester.binding.setSurfaceSize(const Size(390, 900));
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
    await tester.pump();

    expect(find.text('Configuração da assinatura'), findsOneWidget);
    expect(find.textContaining('por entrega'), findsWidgets);
    expect(find.textContaining(sim.total.formatado), findsWidgets);
    expect(
      tester.widget<BotaoPrincipal>(find.byKey(const ValueKey('sacola-continuar'))).rotulo,
      'Continuar · ${sim.total.formatado} por entrega',
    );
    expect(find.text('Adicionar mais produtos'), findsOneWidget);
    expect(find.text('Pagamento'), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
  });

  testWidgets('Barra e Sacola usam o mesmo formatado de sim.total', (tester) async {
    final mocks = Mocks();
    when(() => mocks.catalogo.produtos()).thenAnswer((_) async => <Produto>[]);
    when(() => mocks.catalogo.kits()).thenAnswer((_) async => <Kit>[]);
    const total = Dinheiro(3630);
    const sim = Simulacao(
      itens: [ItemSimulado(produto: 'AMS500', quantidade: 12, precoUnitario: Dinheiro(220))],
      ue: 12,
      subtotal: Dinheiro(2640),
      frete: Dinheiro(990),
      total: total,
      detalhe: [],
      ueMinima: 12,
      faltaUeParaMinimo: 0,
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
    sacola.quantidades['AMS500'] = 12;
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

    expect(find.textContaining(total.formatado), findsOneWidget);
    expect(SacolaCopy.itensETotalPorEntrega(12, total), contains(total.formatado));
  });
}
