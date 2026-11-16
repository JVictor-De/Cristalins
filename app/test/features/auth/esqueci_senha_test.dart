import 'package:cristalins_assinatura/features/auth/presentation/esqueci_senha_screen.dart';
import 'package:cristalins_assinatura/features/auth/presentation/redefinir_senha_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

void main() {
  testWidgets('Esqueci a senha: envia e-mail e abre Nova senha', (tester) async {
    final f = Falsos();
    await tester.binding.setSurfaceSize(const Size(360, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(appDeTeste(f));
    await tester.pumpAndSettle();

    // Vai ao login → Esqueci a senha
    await tester.tap(find.text('Começar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Já tenho conta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Esqueci a senha'));
    await tester.pumpAndSettle();

    expect(find.byType(EsqueciSenhaScreen), findsOneWidget);
    await tester.enterText(find.byType(CupertinoTextFormFieldRow).first, 'ana@cristalins.local');
    await tester.tap(find.text('Enviar código'));
    await tester.pumpAndSettle();

    expect(find.byType(RedefinirSenhaScreen), findsOneWidget);
    expect(find.textContaining('ana@cristalins.local'), findsWidgets);
  });
}
