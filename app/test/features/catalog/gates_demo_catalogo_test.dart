import 'package:cristalins_assinatura/core/dependencias.dart';
import 'package:cristalins_assinatura/core/formatacao.dart';
import 'package:cristalins_assinatura/core/theme/app_theme.dart';
import 'package:cristalins_assinatura/core/widgets/card_produto.dart';
import 'package:cristalins_assinatura/features/address/domain/cep_sessao.dart';
import 'package:cristalins_assinatura/features/auth/domain/perfil_cliente.dart';
import 'package:cristalins_assinatura/features/catalog/data/catalogo_repository.dart';
import 'package:cristalins_assinatura/features/catalog/domain/catalogo.dart';
import 'package:cristalins_assinatura/features/catalog/domain/pdp_copy.dart';
import 'package:cristalins_assinatura/features/catalog/presentation/produto_screen.dart';
import 'package:cristalins_assinatura/features/catalog/presentation/sacola_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../support/fakes.dart';
import '../../support/mocks.dart';

class _MockStorage extends Mock implements FlutterSecureStorage {}

/// Formato de `GET /produtos` com os campos dos gates demo (API + mapas demo AP2).
final _jsonWp = <String, dynamic>{
  'id': 'p1',
  'codigo': 'WP500',
  'nome': 'Water Protein (água com colágeno)',
  'descricao': 'Cristalins com colágeno em garrafa de 500 ml.',
  'tipo': 'PRINCIPAL',
  'volumeMl': 500,
  'ue': 1,
  'embalagemQtd': 6,
  'precoBase': 9.9,
  'precoPiso': 7.5,
  'pesoKg': 0.53,
  'estoque': 1200,
  'precoAvulso': 11.9,
  'claims': ['5 g de proteína', 'Com colágeno', 'Zero açúcar', 'Zero gordura'],
  'tabelaNutricional': {
    'porcao': '500 ml (1 garrafa)',
    'linhas': [
      {'nutriente': 'Valor energético', 'valor': '20 kcal'},
      {'nutriente': 'Proteínas', 'valor': '5 g'},
    ],
  },
};

const _guarana = Produto(
  codigo: 'GUA2000',
  nome: 'Guaraná Cristalins',
  tipo: 'ADDON',
  volumeMl: 2000,
  embalagemQtd: 1,
  precoBase: Dinheiro(790),
  estoque: 0,
  precoAvulso: Dinheiro(950),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => CepDaSessao.valor = null);

  group('CatalogoJson (gates demo)', () {
    test('lê estoque, precoAvulso, claims e tabela nutricional da API', () {
      final p = CatalogoJson.produto(_jsonWp);
      expect(p.estoque, 1200);
      expect(p.esgotado, isFalse);
      expect(p.precoAvulso, const Dinheiro(1190));
      expect(p.claims, contains('Zero açúcar'));
      expect(p.tabelaNutricional!.porcao, '500 ml (1 garrafa)');
      expect(p.tabelaNutricional!.linhas.last.valor, '5 g');
    });

    test('API antiga (sem os campos) continua válida: tudo nulo/vazio', () {
      final antigo = Map<String, dynamic>.of(_jsonWp)
        ..remove('estoque')
        ..remove('precoAvulso')
        ..remove('claims')
        ..remove('tabelaNutricional');
      final p = CatalogoJson.produto(antigo);
      expect(p.estoque, isNull);
      expect(p.esgotado, isFalse);
      expect(p.precoAvulso, isNull);
      expect(p.claims, isEmpty);
      expect(p.tabelaNutricional, isNull);
    });

    test('estoque 0 = esgotado; null = sem controle (disponível)', () {
      expect(_guarana.esgotado, isTrue);
      expect(CatalogoJson.produto({..._jsonWp, 'estoque': null}).esgotado, isFalse);
    });
  });

  group('PdpCopy (gates demo)', () {
    test('chips vêm dos claims da API; sem claims, cai no texto do rótulo', () {
      final wp = CatalogoJson.produto(_jsonWp);
      expect(PdpCopy.chips(wp), ['5 g de proteína', 'Com colágeno', 'Zero açúcar', 'Zero gordura']);
      final semClaims = CatalogoJson.produto({..._jsonWp, 'claims': <String>[]});
      expect(PdpCopy.chips(semClaims), ['5 g de proteína', 'Com colágeno']);
    });

    test('linha avulsa só com valor da API', () {
      expect(
        PdpCopy.avulso(CatalogoJson.produto(_jsonWp)),
        'Avulso: ${const Dinheiro(1190).formatado} /garrafa',
      );
      expect(PdpCopy.avulso(_guarana), 'Avulso: ${const Dinheiro(950).formatado} /un.');
      expect(PdpCopy.avulso(CatalogoJson.produto({..._jsonWp, 'precoAvulso': null})), isNull);
    });
  });

  test('PerfilCliente.saudacao usa o primeiro nome de /clientes/me', () {
    expect(
      PerfilCliente.saudacao(const PerfilCliente(nome: 'Ana Souza', email: 'a@x.com')),
      'Olá, Ana!',
    );
    expect(PerfilCliente.saudacao(const PerfilCliente(nome: '  ', email: 'a@x.com')), 'Olá!');
    expect(PerfilCliente.saudacao(null), 'Olá!');
  });

  group('CardProduto (gates demo)', () {
    Future<Falsos> montar(WidgetTester tester, Produto produto, {int quantidade = 0}) async {
      final f = Falsos();
      await tester.pumpWidget(
        Provider<Dependencias>.value(
          value: f.dependencias,
          child: MaterialApp(
            theme: buildAppTheme(),
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 164,
                  height: 280,
                  child: CardProduto(
                    produto: produto,
                    passo: produto.embalagemQtd,
                    quantidade: quantidade,
                    onAbrir: () {},
                    onAdicionar: () {},
                    onAlterar: (_) {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      return f;
    }

    testWidgets('avulso riscado ao lado do pack; assinatura continua “A partir de”', (
      tester,
    ) async {
      await montar(tester, CatalogoJson.produto(_jsonWp));
      final avulso = tester.widget<Text>(find.byKey(const ValueKey('card-preco-avulso')));
      final spans = (avulso.textSpan! as TextSpan).children!.cast<TextSpan>();
      expect(spans.first.text, contains('Avulso'));
      expect(spans.last.text, const Dinheiro(1190).formatado);
      expect(spans.last.style!.decoration, TextDecoration.lineThrough);
      expect(find.textContaining('A partir de'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byKey(const ValueKey('selo-esgotado')), findsNothing);
    });

    testWidgets('esgotado: selo, sem “+”, Avise-me abre folha e envia e-mail + CEP', (
      tester,
    ) async {
      CepDaSessao.valor = '22041001';
      final f = await montar(tester, _guarana);

      expect(find.byKey(const ValueKey('selo-esgotado')), findsOneWidget);
      expect(find.byIcon(Icons.add), findsNothing);

      await tester.tap(find.byKey(const ValueKey('card-avise-me')));
      await tester.pumpAndSettle();
      expect(find.text('Avise-me quando voltar'), findsOneWidget);
      // CEP da sessão pré-preenchido; visitante digita o e-mail.
      expect(find.widgetWithText(TextField, '22041001'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('lista-espera-enviar')));
      await tester.pump();
      expect(find.text('Informe um e-mail válido.'), findsOneWidget);
      expect(f.enderecos.listaDeEspera, isEmpty);

      await tester.enterText(find.byKey(const ValueKey('lista-espera-email')), 'ana@exemplo.com');
      await tester.tap(find.byKey(const ValueKey('lista-espera-enviar')));
      await tester.pumpAndSettle();

      expect(f.enderecos.listaDeEspera, ['ana@exemplo.com']);
      expect(f.enderecos.cepsListaDeEspera, ['22041001']);
      expect(find.byKey(const ValueKey('folha-lista-espera')), findsNothing);
      expect(find.text('Pronto! Avisamos por e-mail.'), findsOneWidget);
    });

    testWidgets('esgotado mas já na sacola: stepper continua para poder remover', (tester) async {
      await montar(tester, _guarana, quantidade: 1);
      expect(find.byKey(const ValueKey('card-avise-me')), findsNothing);
      expect(find.byKey(const ValueKey('selo-esgotado')), findsOneWidget);
    });
  });

  group('PDP (gates demo)', () {
    Future<void> abrir(WidgetTester tester, Produto p) async {
      final mocks = Mocks();
      final storage = _MockStorage();
      when(() => storage.read(key: any(named: 'key'))).thenAnswer((_) async => null);
      when(
        () => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});
      when(() => mocks.catalogo.produtos()).thenAnswer((_) async => [p]);
      when(() => mocks.catalogo.kits()).thenAnswer((_) async => <Kit>[]);
      final sacola = SacolaController(mocks.catalogo, storage: storage, atraso: Duration.zero)
        ..produtos = [p]
        ..carregandoCatalogo = false;
      tester.view.physicalSize = const Size(390, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        Provider<Dependencias>.value(
          value: Falsos().dependencias,
          child: MaterialApp(
            theme: buildAppTheme(),
            home: MediaQuery(
              data: const MediaQueryData(size: Size(390, 1600), disableAnimations: true),
              child: ChangeNotifierProvider<SacolaController>.value(
                value: sacola,
                child: ProdutoScreen(codigo: p.codigo),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }

    testWidgets('WP: chips dos claims, avulso e tabela nutricional da API', (tester) async {
      await abrir(tester, CatalogoJson.produto(_jsonWp));
      expect(find.text('Zero açúcar'), findsOneWidget);
      expect(find.text('Zero gordura'), findsOneWidget);
      expect(find.byKey(const ValueKey('pdp-avulso')), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('pdp-tabela-nutricional')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Tabela nutricional'), findsOneWidget);
      expect(find.text('Porção de 500 ml (1 garrafa)'), findsOneWidget);
      expect(find.text('20 kcal'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.textContaining('vale o rótulo'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('vale o rótulo'), findsOneWidget);
      // Nada de alegação regulatória na tela.
      expect(find.textContaining('ANVISA'), findsNothing);
      expect(find.byKey(const ValueKey('pdp-cta')), findsOneWidget);
    });

    testWidgets('esgotado: CTA vira “Avise-me quando voltar” e some o stepper', (tester) async {
      await abrir(tester, _guarana);
      expect(find.byKey(const ValueKey('pdp-esgotado')), findsOneWidget);
      expect(find.byKey(const ValueKey('pdp-avise-me')), findsOneWidget);
      expect(find.byKey(const ValueKey('pdp-cta')), findsNothing);
      expect(find.byKey(const ValueKey('pdp-qtd')), findsNothing);
    });
  });
}
