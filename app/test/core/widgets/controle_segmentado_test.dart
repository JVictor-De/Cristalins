import 'package:cristalins_assinatura/core/widgets/controle_segmentado.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ControleSegmentado (VM/nativo) troca o valor ao tocar o segmento', (tester) async {
    var atual = 'A';
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: ControleSegmentado<String>(
            opcoes: const {'A': 'Um', 'B': 'Dois'},
            valor: atual,
            onEscolher: (v) => atual = v,
          ),
        ),
      ),
    );

    expect(find.byType(CupertinoSlidingSegmentedControl<String>), findsOneWidget);
    await tester.tap(find.text('Dois'));
    await tester.pumpAndSettle();
    expect(atual, 'B');
  });

  testWidgets('tocar o segmento já selecionado não chama de novo', (tester) async {
    var chamadas = 0;
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: ControleSegmentado<String>(
            opcoes: const {'A': 'Um', 'B': 'Dois'},
            valor: 'A',
            onEscolher: (_) => chamadas++,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Um'));
    await tester.pumpAndSettle();
    expect(chamadas, 0);
  });
}
