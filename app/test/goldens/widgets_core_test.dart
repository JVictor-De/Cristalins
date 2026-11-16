import 'package:cristalins_assinatura/core/theme/app_colors.dart';
import 'package:cristalins_assinatura/core/theme/app_theme.dart';
import 'package:cristalins_assinatura/core/widgets/botao_principal.dart';
import 'package:cristalins_assinatura/core/widgets/controles.dart';
import 'package:cristalins_assinatura/core/widgets/estado_vazio.dart';
import 'package:cristalins_assinatura/core/widgets/estados.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Golden dos widgets de `core/widgets` (Anexo).
/// Nomes do prompt → nomes reais: AppButton→BotaoPrincipal, QuantityStepper→SeletorQuantidade,
/// StatusBadge→Selo, EmptyState→EstadoVazio. ProductCard não existe neste app.
void main() {
  Widget envelopar(Widget filho) {
    return MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(
        backgroundColor: AppColors.fundoAgrupado,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Padding(padding: const EdgeInsets.all(16), child: filho),
          ),
        ),
      ),
    );
  }

  testWidgets('golden BotaoPrincipal (AppButton)', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 120));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(envelopar(BotaoPrincipal(rotulo: 'Continuar', onPressed: () {})));
    await expectLater(find.byType(BotaoPrincipal), matchesGoldenFile('botao_principal.png'));
  });

  testWidgets('golden SeletorQuantidade (QuantityStepper)', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 120));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      envelopar(
        SeletorQuantidade(rotulo: 'Water Protein', quantidade: 12, passo: 6, onAlterar: (_) {}),
      ),
    );
    await expectLater(find.byType(SeletorQuantidade), matchesGoldenFile('seletor_quantidade.png'));
  });

  testWidgets('golden Selo (StatusBadge)', (tester) async {
    await tester.binding.setSurfaceSize(const Size(200, 80));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      envelopar(const Selo(texto: 'Ativa', fundo: AppColors.azul100, cor: AppColors.azul900)),
    );
    await expectLater(find.byType(Selo), matchesGoldenFile('selo.png'));
  });

  testWidgets('golden EstadoVazio (EmptyState)', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 320));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      envelopar(
        EstadoVazio(
          icone: CupertinoIcons.cube_box,
          mensagem: 'Você ainda não tem assinatura.',
          rotuloAcao: 'Fazer o quiz',
          onAcao: () {},
        ),
      ),
    );
    await expectLater(find.byType(EstadoVazio), matchesGoldenFile('estado_vazio.png'));
  });

  testWidgets('golden EstadoErro (RNF09 tentar de novo)', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 480));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      envelopar(
        EstadoErro(
          mensagem: 'Sem conexão. Tente de novo.',
          onTentarDeNovo: () {},
        ),
      ),
    );
    await expectLater(find.byType(EstadoErro), matchesGoldenFile('estado_erro.png'));
  });
}
