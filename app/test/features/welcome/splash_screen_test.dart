import 'package:cristalins_assinatura/app.dart';
import 'package:cristalins_assinatura/core/dependencias.dart';
import 'package:cristalins_assinatura/core/network/api_client.dart';
import 'package:cristalins_assinatura/core/network/sessao.dart';
import 'package:cristalins_assinatura/core/routes.dart';
import 'package:cristalins_assinatura/features/shell/presentation/shell_screen.dart';
import 'package:cristalins_assinatura/features/welcome/data/onboarding_prefs.dart';
import 'package:cristalins_assinatura/features/welcome/presentation/onboarding_screen.dart';
import 'package:cristalins_assinatura/features/welcome/presentation/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/fakes.dart';
import '../../support/mocks.dart';

Future<void> _avancarSplash(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(milliseconds: 1251));
  await tester.pump(const Duration(milliseconds: 700));
  await tester.pump(); // destino (prefs / token)
  await tester.pump(const Duration(milliseconds: 551));
  await tester.pumpAndSettle();
}

void main() {
  late Mocks mocks;

  setUp(() {
    mocks = Mocks();
    whenCatalogoVazio(mocks);
    OnboardingPrefs.resetParaTeste();
    OnboardingPrefs.overrideVistoParaTeste = false;
  });

  tearDown(OnboardingPrefs.resetParaTeste);

  testWidgets('splash monta e, ao terminar, abre onboarding na 1ª vez', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      CristalinsApp(
        config: configDeTeste(),
        dependencias: mocks.dependencias,
      ),
    );
    await tester.pump();

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.bySemanticsLabel('Cristalins'), findsOneWidget);

    await _avancarSplash(tester);

    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('Montar minha assinatura'), findsOneWidget);
    expect(find.text('Já sou assinante? Entrar'), findsOneWidget);
    expect(
      ModalRoute.of(tester.element(find.text('Já sou assinante? Entrar')))!.settings.name,
      AppRoutes.onboarding,
    );
  });

  testWidgets('P4.3: sessão válida pula onboarding e abre o shell', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final tokens = ArmazenamentoEmMemoria();
    await tokens.salvar(acesso: 'access-test', refresh: 'refresh-test');
    final config = configDeTeste();
    final dep = Dependencias(
      auth: mocks.auth,
      recomendacoes: mocks.recomendacoes,
      catalogo: mocks.catalogo,
      enderecos: mocks.enderecos,
      assinaturas: mocks.assinaturas,
      ocorrencias: mocks.ocorrencias,
      links: mocks.links,
      compartilhador: mocks.compartilhador,
      api: ApiClient(config, tokens: tokens),
    );

    await tester.pumpWidget(
      CristalinsApp(config: config, dependencias: dep),
    );
    await tester.pump();
    await _avancarSplash(tester);

    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(ShellScreen), findsOneWidget);
  });

  testWidgets('sair no meio do morph não deixa exceção pendente', (tester) async {
    await tester.pumpWidget(
      CristalinsApp(config: configDeTeste(), dependencias: mocks.dependencias),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 400));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(tester.takeException(), isNull);
    expect(find.byType(SplashScreen), findsNothing);
  });

  testWidgets('sair na espera inicial não navega nem estoura', (tester) async {
    await tester.pumpWidget(
      CristalinsApp(config: configDeTeste(), dependencias: mocks.dependencias),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));

    expect(tester.takeException(), isNull);
    expect(find.text('Montar minha assinatura'), findsNothing);
  });
}

void whenCatalogoVazio(Mocks m) {
  when(() => m.catalogo.produtos()).thenAnswer((_) async => const []);
  when(() => m.catalogo.kits()).thenAnswer((_) async => const []);
  when(() => m.assinaturas.listar()).thenAnswer((_) async => const []);
}
