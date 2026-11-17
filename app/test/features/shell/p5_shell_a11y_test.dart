import 'package:cristalins_assinatura/app.dart';
import 'package:cristalins_assinatura/core/config/app_config.dart';
import 'package:cristalins_assinatura/core/formatacao.dart';
import 'package:cristalins_assinatura/core/theme/app_colors.dart';
import 'package:cristalins_assinatura/core/theme/app_theme.dart';
import 'package:cristalins_assinatura/core/widgets/chip_categoria.dart';
import 'package:cristalins_assinatura/features/catalog/domain/catalogo.dart';
import 'package:cristalins_assinatura/features/catalog/domain/produto_assets.dart';
import 'package:cristalins_assinatura/features/quiz/domain/quiz.dart';
import 'package:cristalins_assinatura/features/shell/presentation/shell_screen.dart';
import 'package:cristalins_assinatura/features/welcome/data/onboarding_prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('P5.2: nomeDoProduto alinhado a nomeCurtoPorCodigo / nomeCardProduto', () {
    const wp = Produto(
      codigo: 'WP500',
      nome: 'Water Protein (água com colágeno)',
      tipo: 'PRINCIPAL',
      volumeMl: 500,
      embalagemQtd: 6,
      precoBase: Dinheiro(990),
    );
    expect(nomeDoProduto('WP500'), nomeCardProduto(wp));
    expect(nomeDoProduto('AMS500'), 'Sem gás');
    expect(nomeDoProduto('AMC510'), 'Com gás');
    expect(nomeDoProduto('AMN5000'), 'Galão');
    expect(nomeDoProduto('FF500'), 'Flow Fiber');
    // Sem Produto: fallback curto de recibo; com API: nome completo no card.
    expect(nomeDoProduto('GUA2000'), 'Guaraná Cristalins');
    expect(
      nomeCardProduto(
        const Produto(
          codigo: 'GUA2000',
          nome: 'Guaraná Cristalins 2 L',
          tipo: 'COMPLEMENTO',
          volumeMl: 2000,
          embalagemQtd: 1,
          precoBase: Dinheiro(500),
        ),
      ),
      'Guaraná Cristalins 2 L',
    );
  });

  testWidgets('P5.1: shell indicator #E3EEF3; abas inativas em heroInk', (tester) async {
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

    expect(find.byType(ShellScreen), findsOneWidget);
    final barra = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(barra.indicatorColor, AppColors.indicadorAba);
    expect(AppColors.indicadorAba, const Color(0xFFE3EEF3));

    final tema = NavigationBarTheme.of(
      tester.element(find.byType(NavigationBar)),
    );
    final inativo = tema.labelTextStyle?.resolve({})?.color;
    expect(inativo, AppColors.heroInk);

    expect(find.text('Início'), findsWidgets);
    expect(find.text('Produtos'), findsOneWidget);
    expect(find.text('Assinatura'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('P5.1: chip inativo usa navy (≥ contraste sobre superficie)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: ChipCategoria(rotulo: 'Proteína e fibras', selecionado: false, onTap: () {}),
        ),
      ),
    );
    await tester.pump();
    final texto = tester.widget<Text>(find.text('Proteína e fibras'));
    expect(texto.style?.color, AppColors.navy);
    expect(Categoria.funcionais.rotulo, 'Proteína e fibras');
  });
}
