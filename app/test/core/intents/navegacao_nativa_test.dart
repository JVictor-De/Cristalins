import 'package:cristalins_assinatura/core/intents/navegacao_nativa.dart';
import 'package:cristalins_assinatura/core/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('constantes de Activity batem com cascas Kotlin', () {
    expect(NavegacaoNativa.channelName, 'br.com.cristalins.assinatura/navegacao');
    expect(NavegacaoNativa.boasVindas, 'BoasVindasActivity');
    expect(NavegacaoNativa.cadastroLogin, 'CadastroLoginActivity');
    expect(NavegacaoNativa.quiz, 'QuizActivity');
    expect(NavegacaoNativa.resultado, 'ResultadoActivity');
    expect(NavegacaoNativa.catalogo, 'CatalogoActivity');
    expect(NavegacaoNativa.endereco, 'EnderecoActivity');
    expect(NavegacaoNativa.planoPagamento, 'PlanoPagamentoActivity');
    expect(NavegacaoNativa.minhaAssinatura, 'MinhaAssinaturaActivity');
  });

  testWidgets('NavegacaoNativa.abrir navega pela rota (fallback sem plugin)', (tester) async {
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    Object? chamado;
    messenger.setMockMethodCallHandler(
      const MethodChannel(NavegacaoNativa.channelName),
      (call) async {
        chamado = call.method;
        return null;
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.quiz,
        onGenerateRoute: (s) {
          if (s.name == AppRoutes.quiz) {
            return MaterialPageRoute<void>(
              settings: s,
              builder: (_) => Builder(
                builder: (context) => TextButton(
                  onPressed: () => NavegacaoNativa.instancia.abrir(
                    context,
                    activity: NavegacaoNativa.resultado,
                    rota: AppRoutes.resultado,
                    arguments: 'rec-1',
                    extras: {'recomendacaoId': 'rec-1'},
                    finish: true,
                  ),
                  child: const Text('ir'),
                ),
              ),
            );
          }
          if (s.name == AppRoutes.resultado) {
            return MaterialPageRoute<void>(
              settings: s,
              builder: (_) => Text('resultado:${s.arguments}'),
            );
          }
          return null;
        },
      ),
    );

    await tester.tap(find.text('ir'));
    await tester.pumpAndSettle();

    expect(find.text('resultado:rec-1'), findsOneWidget);
    // Em teste VM o channel pode ou não ser invocado (plataforma ≠ Android).
    // Garante que o handler mock não quebrou se chamado.
    expect(chamado == null || chamado == 'abrirActivity', isTrue);

    messenger.setMockMethodCallHandler(
      const MethodChannel(NavegacaoNativa.channelName),
      null,
    );
  });
}
