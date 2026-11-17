import 'package:cristalins_assinatura/app.dart';
import 'package:cristalins_assinatura/core/config/app_config.dart';
import 'package:cristalins_assinatura/core/formatacao.dart';
import 'package:cristalins_assinatura/core/marca_assets.dart';
import 'package:cristalins_assinatura/core/routes.dart';
import 'package:cristalins_assinatura/core/theme/app_colors.dart';
import 'package:cristalins_assinatura/core/theme/app_theme.dart';
import 'package:cristalins_assinatura/core/widgets/botao_principal.dart';
import 'package:cristalins_assinatura/features/auth/presentation/cadastro_login_screen.dart';
import 'package:cristalins_assinatura/features/catalog/domain/catalogo.dart';
import 'package:cristalins_assinatura/features/catalog/presentation/sacola_controller.dart';
import 'package:cristalins_assinatura/features/shell/presentation/shell_screen.dart';
import 'package:cristalins_assinatura/features/welcome/data/onboarding_prefs.dart';
import 'package:cristalins_assinatura/features/welcome/presentation/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../support/mocks.dart';

class _MockStorage extends Mock implements FlutterSecureStorage {}

const _config = AppConfig(
  ambiente: Ambiente.dev,
  apiUrl: 'http://10.0.2.2:3000',
  suporteWhatsapp: '',
);

const _wp = Produto(
  codigo: 'WP500',
  nome: 'Water Protein (água com colágeno)',
  tipo: 'PRINCIPAL',
  volumeMl: 500,
  embalagemQtd: 6,
  precoBase: Dinheiro(990),
);

/// `/boas-vindas` = onboarding (entry canônico marketplace).
Widget _app(Mocks mocks) => CristalinsApp(
      config: _config,
      dependencias: mocks.dependencias,
      exibirSplash: false,
      rotaInicial: AppRoutes.boasVindas,
    );

SacolaController _sacolaComWp() {
  final mocks = Mocks();
  when(() => mocks.catalogo.produtos()).thenAnswer((_) async => const [_wp]);
  when(() => mocks.catalogo.kits()).thenAnswer((_) async => const []);
  final storage = _MockStorage();
  when(() => storage.read(key: any(named: 'key'))).thenAnswer((_) async => null);
  when(() => storage.write(key: any(named: 'key'), value: any(named: 'value'))).thenAnswer((_) async {});
  final s = SacolaController(mocks.catalogo, storage: storage, atraso: Duration.zero);
  s.produtos = const [_wp];
  s.carregandoCatalogo = false;
  return s;
}

void main() {
  late Mocks mocks;

  setUp(() {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(1080, 2340);
    view.devicePixelRatio = 3;
    addTearDown(view.reset);
    OnboardingPrefs.resetParaTeste();
    OnboardingPrefs.overrideVistoParaTeste = false;
    mocks = Mocks();
    when(() => mocks.catalogo.produtos()).thenAnswer((_) async => const [_wp]);
    when(() => mocks.catalogo.kits()).thenAnswer((_) async => const []);
    when(() => mocks.assinaturas.listar()).thenAnswer((_) async => const []);
    when(() => mocks.links.abrir(any())).thenAnswer((_) async => true);
  });

  tearDown(OnboardingPrefs.resetParaTeste);

  testWidgets('boas-vindas renderiza onboarding P4 (WP + CTA + Entrar)', (tester) async {
    await tester.pumpWidget(_app(mocks));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.bySemanticsLabel('Cristalins'), findsWidgets);
    expect(find.byKey(const ValueKey('onboarding-titulo')), findsOneWidget);
    expect(find.text('Water Protein no Rio'), findsOneWidget);
    expect(find.widgetWithText(BotaoPrincipal, 'Montar minha assinatura'), findsOneWidget);
    expect(find.text('Ver todos os produtos'), findsOneWidget);
    expect(find.text('Já sou assinante? Entrar'), findsOneWidget);
    expect(find.text('Descobrir meu kit'), findsNothing);
    expect(find.text('Pular'), findsNothing);
    expect(find.textContaining('água mineral'), findsNothing);
  });

  testWidgets('P4.2: preço a partir de precoBase do WP', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: ChangeNotifierProvider<SacolaController>.value(
          value: _sacolaComWp(),
          child: const OnboardingScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('onboarding-preco')), findsOneWidget);
    expect(find.text('A partir de ${const Dinheiro(990).formatado}/garrafa'), findsOneWidget);
    final cta = tester.widget<BotaoPrincipal>(find.byKey(const ValueKey('onboarding-cta')));
    expect(cta.variante, VarianteBotaoPrincipal.cta);
  });

  testWidgets('fundo do onboarding usa agua-bokeh limpa (png), sem tipografia de print', (
    tester,
  ) async {
    expect(assetHeroAguaBokeh, 'assets/images/hero/agua-bokeh-limpa.png');
    expect(assetHeroAguaBokeh.endsWith('.webp'), isFalse);

    await tester.pumpWidget(_app(mocks));
    await tester.pumpAndSettle();

    final foto = find.byWidgetPredicate((w) {
      if (w is! Image) return false;
      final provider = w.image;
      final path = switch (provider) {
        AssetImage(:final assetName) => assetName,
        ExactAssetImage(:final assetName) => assetName,
        _ => null,
      };
      return path == assetHeroAguaBokeh;
    });
    expect(foto, findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding-garrafa-wp')), findsOneWidget);
  });

  testWidgets('onboarding usa garrafa transparente + respingo + marca e scrim meio-termo', (
    tester,
  ) async {
    expect(
      assetOnboardingGarrafaWp,
      'assets/images/produtos/cristalins-garrafa-transparente.png',
    );
    expect(assetImpactoRespingo, 'assets/images/brand/impacto/impacto-respingo.webp');
    expect(assetImpactoMarca, 'assets/images/brand/impacto/impacto-marca.webp');

    await tester.pumpWidget(_app(mocks));
    await tester.pumpAndSettle();

    String? pathOf(Image image) {
      final provider = image.image;
      return switch (provider) {
        AssetImage(:final assetName) => assetName,
        ExactAssetImage(:final assetName) => assetName,
        _ => null,
      };
    }

    final garrafa = tester.widget<Image>(find.byKey(const ValueKey('onboarding-garrafa-wp')));
    expect(pathOf(garrafa), assetOnboardingGarrafaWp);

    final respingo = tester.widget<Image>(find.byKey(const ValueKey('onboarding-respingo')));
    expect(pathOf(respingo), assetImpactoRespingo);

    final marca = tester.widget<Image>(find.byKey(const ValueKey('onboarding-marca')));
    expect(pathOf(marca), assetImpactoMarca);

    // Marca e respingo escalam a partir da mesma caixa da garrafa (proporção relativa).
    final garrafaBox = tester.getSize(find.byKey(const ValueKey('onboarding-garrafa-wp')));
    final marcaBox = tester.getSize(find.byKey(const ValueKey('onboarding-marca')));
    expect(marcaBox.width, greaterThan(garrafaBox.width));
    expect(marcaBox.width, lessThan(garrafaBox.width * 1.6));

    final scrim = find.byWidgetPredicate(
      (w) => w is ColoredBox && w.color == Colors.black.withValues(alpha: 0.40),
    );
    expect(scrim, findsOneWidget);
  });

  testWidgets('onboarding com reduzir animações: marca já revelada', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(390, 844),
          disableAnimations: true,
        ),
        child: _app(mocks),
      ),
    );
    await tester.pump(); // post-frame aplica t=1
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const ValueKey('onboarding-marca')), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding-garrafa-wp')), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding-respingo')), findsOneWidget);

    final marcaBox = tester.getSize(find.byKey(const ValueKey('onboarding-marca')));
    final garrafaBox = tester.getSize(find.byKey(const ValueKey('onboarding-garrafa-wp')));
    expect(marcaBox.width, greaterThan(garrafaBox.width));
  });

  testWidgets('onboarding anima impacto PDP: respingo some no início e aparece no fim', (
    tester,
  ) async {
    await tester.pumpWidget(_app(mocks));
    await tester.pump(); // inicia o controller
    await tester.pump(const Duration(milliseconds: 200)); // t≈0.11 — splash ainda 0

    Opacity? opacityDoRespingo() {
      final img = find.byKey(const ValueKey('onboarding-respingo'));
      final opacities = find.ancestor(of: img, matching: find.byType(Opacity));
      if (opacities.evaluate().isEmpty) return null;
      return tester.widget<Opacity>(opacities.first);
    }

    expect(opacityDoRespingo()?.opacity, 0);

    await tester.pumpAndSettle();
    expect(opacityDoRespingo()?.opacity, 1);
    expect(find.byKey(const ValueKey('onboarding-marca')), findsOneWidget);
  });

  testWidgets('tema usa Inter, plataforma iOS e azulMarca como primária', (tester) async {
    await tester.pumpWidget(_app(mocks));
    await tester.pumpAndSettle();
    final tema = Theme.of(tester.element(find.text('Montar minha assinatura')));

    expect(tema.platform, TargetPlatform.iOS);
    expect(tema.textTheme.bodyMedium?.fontFamily, 'Inter');
    expect(tema.colorScheme.primary, AppColors.azulMarca);
    expect(tema.cupertinoOverrideTheme?.primaryColor, AppColors.azulMarca);
  });

  testWidgets('Ver todos os produtos abre o shell marketplace', (tester) async {
    await tester.pumpWidget(_app(mocks));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver todos os produtos'));
    await tester.pumpAndSettle();

    expect(find.byType(ShellScreen), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
  });

  testWidgets('Entrar abre cadastro/login', (tester) async {
    await tester.pumpWidget(_app(mocks));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Já sou assinante? Entrar'));
    await tester.pumpAndSettle();

    expect(find.byType(CadastroLoginScreen), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
  });

  testWidgets('fonte a 130% sem estouro de layout', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(_app(mocks));
    await tester.pumpAndSettle();

    final contexto = tester.element(find.text('Montar minha assinatura'));
    expect(MediaQuery.textScalerOf(contexto).scale(10), closeTo(13, 0.01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('acessibilidade: toque ≥ 48 dp, rótulos e contraste', (tester) async {
    final semantica = tester.ensureSemantics();
    await tester.pumpWidget(_app(mocks));
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    semantica.dispose();
  });
}
