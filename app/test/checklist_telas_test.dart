import 'package:cristalins_assinatura/app.dart';
import 'package:cristalins_assinatura/core/routes.dart';
import 'package:cristalins_assinatura/features/address/domain/endereco.dart';
import 'package:cristalins_assinatura/features/catalog/domain/catalogo.dart';
import 'package:cristalins_assinatura/features/subscription/domain/assinatura.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'support/fakes.dart';

/// Checklist da skill (seção 10) que dá para automatizar, em cada uma das 8 telas:
/// fonte a 130% sem estourar, toque ≥ 48 dp, rótulos nos alvos de toque e contraste ≥ 4,5:1.
void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  const endereco = Endereco(
    id: 'end-1',
    cep: '22041001',
    logradouro: 'Avenida Nossa Senhora de Copacabana',
    numero: '100',
    bairro: 'Copacabana',
    zona: zonaSul,
    principal: true,
    apelido: 'Casa',
  );
  const pedido = PedidoAssinatura(itens: [ItemCesta('WP500', 12)], endereco: endereco);

  final telas = <String, (String, Object?)>{
    '1 Onboarding': (AppRoutes.onboarding, null),
    '2 Cadastro e login': (AppRoutes.cadastroLogin, null),
    '3 Quiz': (AppRoutes.quiz, null),
    '4 Resultado': (AppRoutes.resultado, 'rec-1'),
    '5 Catálogo e cesta': (AppRoutes.catalogo, pedido),
    '6 Endereço': (AppRoutes.endereco, pedido),
    '7 Plano e pagamento': (AppRoutes.planoPagamento, pedido),
    '8 Minha assinatura': (AppRoutes.minhaAssinatura, null),
  };

  for (final MapEntry(key: nome, value: (rota, args)) in telas.entries) {
    for (final escala in [1.0, 1.3]) {
      testWidgets(
        'Tela $nome a ${(escala * 100).round()}%: sem estouro, toque, rótulos e contraste',
        (tester) async {
          final view = tester.view;
          view.physicalSize = const Size(1080, 2340); // 360 × 780 dp (celular de ~6")
          view.devicePixelRatio = 3;
          addTearDown(view.reset);
          tester.platformDispatcher.textScaleFactorTestValue = escala;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final semantica = tester.ensureSemantics();

          final f = Falsos()..assinaturas.comAssinaturaAtiva();
          await tester.pumpWidget(
            CristalinsApp(
              config: configDeTeste(),
              dependencias: f.dependencias,
              exibirSplash: false,
              rotaInicial: args == null ? rota : AppRoutes.shell,
            ),
          );
          await tester.pumpAndSettle();
          if (args != null) {
            tester.state<NavigatorState>(find.byType(Navigator)).pushNamed(rota, arguments: args);
            await tester.pumpAndSettle();
          }

          expect(tester.takeException(), isNull);
          // Rola até o fim quando a tela tem scroll (onboarding é Stack fixo).
          final scroll = find.byType(Scrollable);
          if (scroll.evaluate().isNotEmpty) {
            await tester.fling(scroll.first, const Offset(0, -3000), 3000);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await tester.fling(scroll.first, const Offset(0, 3000), 3000);
            await tester.pumpAndSettle();
          }

          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          semantica.dispose();
        },
      );
    }
  }
}
