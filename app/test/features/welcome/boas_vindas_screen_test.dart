import 'package:cristalins_assinatura/app.dart';
import 'package:cristalins_assinatura/core/config/app_config.dart';
import 'package:cristalins_assinatura/core/intents/abridor_links.dart';
import 'package:cristalins_assinatura/core/routes.dart';
import 'package:cristalins_assinatura/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _AbridorLinksMock extends Mock implements AbridorLinks {}

const _config = AppConfig(
  ambiente: Ambiente.dev,
  apiUrl: 'http://10.0.2.2:3000',
  suporteWhatsapp: '',
);

/// Tela 1 — não shell/home (marketplace). `exibirSplash: false` sozinho abre o shell.
Widget _app(AbridorLinks abridor) => CristalinsApp(
      config: _config,
      abridorLinks: abridor,
      exibirSplash: false,
      rotaInicial: AppRoutes.boasVindas,
    );

final _linkDoSite = find.text('Conhecer o site da Cristalins');

/// `scrollUntilVisible` para quando o item existe na árvore (mesmo fora da tela, no cache);
/// `ensureVisible` então traz o item para a área visível, acima do botão do rodapé.
Future<void> _mostrarLinkDoSite(WidgetTester tester) async {
  await tester.scrollUntilVisible(_linkDoSite, 100, scrollable: find.byType(Scrollable).first);
  await tester.ensureVisible(_linkDoSite);
  await tester.pumpAndSettle();
}

void main() {
  late _AbridorLinksMock abridor;

  setUp(() {
    // Celular típico: 360 x 780 dp.
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(1080, 2340);
    view.devicePixelRatio = 3;
    addTearDown(view.reset);
    abridor = _AbridorLinksMock();
    when(() => abridor.abrir(any())).thenAnswer((_) async => true);
  });

  testWidgets('mostra a proposta, os passos e a ação principal', (tester) async {
    await tester.pumpWidget(_app(abridor));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Cristalins'), findsWidgets);
    expect(find.image(const AssetImage('assets/images/brand/logo.png')), findsWidgets);
    expect(find.text('Responda 5 perguntas'), findsOneWidget);

    expect(find.text('Pague com Pix'), findsOneWidget);
    expect(find.text('Começar'), findsOneWidget);
  });

  testWidgets('tema usa Inter, plataforma iOS e azulMarca como primária', (tester) async {
    await tester.pumpWidget(_app(abridor));
    await tester.pumpAndSettle();
    final tema = Theme.of(tester.element(find.text('Começar')));

    expect(tema.platform, TargetPlatform.iOS);
    expect(tema.textTheme.bodyMedium?.fontFamily, 'Inter');
    expect(tema.colorScheme.primary, AppColors.azulMarca);
    expect(tema.cupertinoOverrideTheme?.primaryColor, AppColors.azulMarca);
  });

  testWidgets('Começar abre a rota da Tela 2 e o voltar retorna', (tester) async {
    await tester.pumpWidget(_app(abridor));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Começar'));
    await tester.pumpAndSettle();

    // Tela 2 (cr-2-telas): cadastro e login.
    expect(find.text('Criar conta'), findsWidgets);
    expect(find.text('Já tenho conta'), findsOneWidget);

    // Botão/gesto de voltar do Android
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Começar'), findsOneWidget);
  });

  testWidgets('link abre o site da marca', (tester) async {
    await tester.pumpWidget(_app(abridor));
    await _mostrarLinkDoSite(tester);
    await tester.tap(_linkDoSite);
    await tester.pump();

    verify(() => abridor.abrir('https://www.cristalins.com.br/')).called(1);
  });

  testWidgets('avisa quando o site não abre', (tester) async {
    when(() => abridor.abrir(any())).thenAnswer((_) async => false);
    await tester.pumpWidget(_app(abridor));
    await _mostrarLinkDoSite(tester);
    await tester.tap(_linkDoSite);
    await tester.pumpAndSettle();

    expect(find.text('Não conseguimos abrir o site agora. Tente de novo.'), findsOneWidget);
  });

  testWidgets('fonte a 130% sem estouro de layout', (tester) async {
    // MaterialApp lê a escala da view; um MediaQuery por fora seria ignorado.
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(_app(abridor));
    await tester.pumpAndSettle();

    final contexto = tester.element(find.text('Começar'));
    expect(MediaQuery.textScalerOf(contexto).scale(10), closeTo(13, 0.01));
    expect(tester.takeException(), isNull);
    await _mostrarLinkDoSite(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Começar'), findsOneWidget);
  });

  testWidgets('acessibilidade: toque ≥ 48 dp, rótulos e contraste', (tester) async {
    final semantica = tester.ensureSemantics();
    await tester.pumpWidget(_app(abridor));
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    semantica.dispose();
  });
}
