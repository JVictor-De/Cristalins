import 'package:cristalins_assinatura/app.dart';
import 'package:cristalins_assinatura/core/config/app_config.dart';
import 'package:cristalins_assinatura/core/routes.dart';
import 'package:cristalins_assinatura/features/welcome/presentation/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _config = AppConfig(
  ambiente: Ambiente.dev,
  apiUrl: 'http://10.0.2.2:3000',
  suporteWhatsapp: '',
);

void main() {
  testWidgets('splash monta e, ao terminar, abre boas-vindas na rota /boas-vindas', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const CristalinsApp(config: _config));
    await tester.pump();

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.bySemanticsLabel('Cristalins'), findsOneWidget);
    expect(find.text('Começar'), findsNothing);

    // 1s de água → morph 1250ms → pausa 700ms → fade 550ms.
    // O ticker só conclui com elapsed maior que a duração, e o primeiro frame
    // conta zero. Sem pumpAndSettle: o loop da splash não termina sozinho.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 1251));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 551));
    await tester.pump();

    expect(find.byType(SplashScreen), findsNothing);
    expect(find.text('Começar'), findsOneWidget);
    expect(
      ModalRoute.of(tester.element(find.text('Começar')))!.settings.name,
      AppRoutes.boasVindas,
    );
  });

  testWidgets('sair no meio do morph não deixa exceção pendente', (tester) async {
    await tester.pumpWidget(const CristalinsApp(config: _config));
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
    await tester.pumpWidget(const CristalinsApp(config: _config));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));

    expect(tester.takeException(), isNull);
    expect(find.text('Começar'), findsNothing);
  });
}
