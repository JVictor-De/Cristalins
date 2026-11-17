import 'package:cristalins_assinatura/core/widgets/secao_agrupada.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('LinhaLista com onTap dispara a ação', (tester) async {
    var toques = 0;
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: SecaoAgrupada(
            cabecalho: 'Pagamento',
            children: [
              LinhaLista(
                titulo: 'Faturas e forma de pagamento',
                icone: CupertinoIcons.creditcard,
                onTap: () => toques++,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Faturas e forma de pagamento'));
    await tester.pump();
    expect(toques, 1);
  });

  testWidgets('LinhaLista sem onTap não é botão acionável', (tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: CupertinoPageScaffold(
          child: SecaoAgrupada(
            children: [LinhaLista(titulo: 'Pix')],
          ),
        ),
      ),
    );
    await tester.tap(find.text('Pix'));
    await tester.pump();
    // Só garante que não explode.
    expect(find.text('Pix'), findsOneWidget);
  });
}
