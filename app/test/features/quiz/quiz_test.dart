import 'dart:async';

import 'package:cristalins_assinatura/core/network/api_erro.dart';
import 'package:cristalins_assinatura/core/routes.dart';
import 'package:cristalins_assinatura/core/widgets/botao_principal.dart';
import 'package:cristalins_assinatura/features/quiz/domain/quiz.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/mocks.dart';

/// Tela 3 (quiz) e Tela 4 (resultado) com a API simulada por mocktail.
void main() {
  setUpAll(registrarFallbacks);

  late Mocks m;

  setUp(() => m = Mocks());

  Future<void> abrir(WidgetTester tester, String rota, {Object? argumentos}) async {
    await prepararTela(tester);
    await tester.pumpWidget(appComMocks(m));
    await tester.pumpAndSettle();
    tester.state<NavigatorState>(find.byType(Navigator)).pushNamed(rota, arguments: argumentos);
    await tester.pumpAndSettle();
  }

  BotaoPrincipal botao(WidgetTester tester) =>
      tester.widget<BotaoPrincipal>(find.byType(BotaoPrincipal));

  Future<void> continuar(WidgetTester tester) async {
    await tester.tap(find.byType(BotaoPrincipal));
    await tester.pumpAndSettle();
  }

  /// Abre a folha do CupertinoPicker, rola [passos] itens e toca em "Concluir".
  Future<void> escolher(WidgetTester tester, int passos) async {
    await tester.tap(find.text('Escolher'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CupertinoPicker), Offset(0, -40.0 * passos));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Concluir'));
    await tester.pumpAndSettle();
  }

  Future<void> responderTudo(WidgetTester tester) async {
    await tester.tap(find.text('Casa e família'));
    await tester.pump();
    await continuar(tester);
    await escolher(tester, 1); // 3 a 4 dias
    await continuar(tester);
    await escolher(tester, 2); // 3 pessoas
    await continuar(tester);
    await tester.tap(find.byType(CupertinoSwitch)); // Flow Fiber: sim
    await tester.pump();
    await continuar(tester);
  }

  group('Quiz', () {
    testWidgets('avançar fica desabilitado até responder e a barra mostra a pergunta', (
      tester,
    ) async {
      await abrir(tester, AppRoutes.quiz);
      expect(find.text('Pergunta 1 de 5'), findsOneWidget);
      expect(botao(tester).onPressed, isNull);

      await tester.tap(find.text('Treino'));
      await tester.pump();
      expect(botao(tester).onPressed, isNotNull);
      await continuar(tester);
      expect(find.text('Pergunta 2 de 5'), findsOneWidget);
      expect(botao(tester).onPressed, isNull); // dias ainda sem resposta
    });

    testWidgets('caso B: envia as 5 respostas no formato da API', (tester) async {
      when(() => m.recomendacoes.recomendar(any())).thenAnswer((_) async => recomendacaoCasoA);
      when(() => m.recomendacoes.buscar(any())).thenAnswer((_) async => recomendacaoCasoA);
      await abrir(tester, AppRoutes.quiz);
      await responderTudo(tester);
      expect(find.text('Pergunta 5 de 5'), findsOneWidget);
      expect(find.text('Ver minha recomendação'), findsOneWidget);
      await continuar(tester);

      final r =
          verify(() => m.recomendacoes.recomendar(captureAny())).captured.single as RespostasQuiz;
      expect(r.objetivo, 'CASA');
      expect(r.diasSemana, '3-4');
      expect(r.pessoas, '3');
      expect(r.flowFiber, isTrue);
      expect(r.comGas, isFalse);
      // Navega para o resultado com o id da recomendação
      verify(() => m.recomendacoes.buscar('rec-1')).called(1);
    });

    testWidgets('voltar (botão do Android) volta uma pergunta e mantém a resposta', (tester) async {
      await abrir(tester, AppRoutes.quiz);
      await tester.tap(find.text('Escritório'));
      await tester.pump();
      await continuar(tester);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Pergunta 1 de 5'), findsOneWidget);
      expect(botao(tester).onPressed, isNotNull); // Escritório continua marcado
    });

    testWidgets('carregando no botão enquanto a API calcula', (tester) async {
      final resposta = Completer<Recomendacao>();
      when(() => m.recomendacoes.recomendar(any())).thenAnswer((_) => resposta.future);
      when(() => m.recomendacoes.buscar(any())).thenAnswer((_) async => recomendacaoCasoA);
      await abrir(tester, AppRoutes.quiz);
      await responderTudo(tester);
      await tester.tap(find.byType(BotaoPrincipal));
      await tester.pump();
      expect(
        find.descendant(
          of: find.byType(BotaoPrincipal),
          matching: find.byType(CupertinoActivityIndicator),
        ),
        findsOneWidget,
      );
      resposta.complete(recomendacaoCasoA);
      await tester.pumpAndSettle();
      expect(find.text('Kit Treino'), findsOneWidget);
    });

    testWidgets('erro da API: aviso e o usuário pode tentar de novo na mesma pergunta', (
      tester,
    ) async {
      var chamadas = 0;
      when(() => m.recomendacoes.recomendar(any())).thenAnswer((_) async {
        chamadas++;
        if (chamadas == 1) throw const ApiErro(codigo: 'SEM_CONEXAO', mensagem: ApiErro.semConexao);
        return recomendacaoCasoA;
      });
      when(() => m.recomendacoes.buscar(any())).thenAnswer((_) async => recomendacaoCasoA);
      await abrir(tester, AppRoutes.quiz);
      await responderTudo(tester);
      await continuar(tester);
      expect(find.text(ApiErro.semConexao), findsOneWidget);
      expect(find.text('Pergunta 5 de 5'), findsOneWidget);

      await continuar(tester);
      expect(chamadas, 2);
      expect(find.text('Kit Treino'), findsOneWidget);
    });
  });

  group('Resultado', () {
    testWidgets('carregando, erro com "Tentar de novo" e sucesso', (tester) async {
      final primeira = Completer<Recomendacao>();
      var chamadas = 0;
      when(() => m.recomendacoes.buscar('rec-1')).thenAnswer((_) {
        chamadas++;
        if (chamadas == 1) return primeira.future;
        return Future.value(recomendacaoCasoA);
      });
      await prepararTela(tester);
      await tester.pumpWidget(appComMocks(m));
      await tester.pumpAndSettle();
      tester
          .state<NavigatorState>(find.byType(Navigator))
          .pushNamed(AppRoutes.resultado, arguments: 'rec-1');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Carregando
      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
      primeira.completeError(const ApiErro(codigo: 'ERRO', mensagem: ApiErro.generico));
      await tester.pumpAndSettle();

      // Erro
      expect(find.text(ApiErro.generico), findsOneWidget);
      await tester.tap(find.text('Tentar de novo'));
      await tester.pumpAndSettle();

      // Sucesso
      expect(chamadas, 2);
      expect(find.text('Kit Treino'), findsOneWidget);
      expect(find.textContaining('118,80'), findsOneWidget);
    });

    testWidgets('perfil Empresa mostra o contato comercial e não oferece montar cesta', (
      tester,
    ) async {
      when(() => m.recomendacoes.buscar(any())).thenAnswer(
        (_) async => const Recomendacao(
          id: 'rec-2',
          kit: null,
          multiplicador: 8,
          frequencia: 'SEMANAL',
          itens: [],
          ue: 249.6,
          valorEstimado: null,
          perfilEmpresa: true,
          contatoEmail: 'contato@cristalins.com.br',
          contatoTelefone: '(14) 3523-1001',
        ),
      );
      await abrir(tester, AppRoutes.resultado, argumentos: 'rec-2');
      expect(find.text('contato@cristalins.com.br'), findsOneWidget);
      expect(find.text('Montar minha cesta'), findsNothing);
    });

    testWidgets('compartilhar resultado chama a Intent com o texto do kit', (tester) async {
      when(() => m.recomendacoes.buscar(any())).thenAnswer((_) async => recomendacaoCasoA);
      when(
        () => m.compartilhador.compartilhar(any(), assunto: any(named: 'assunto')),
      ).thenAnswer((_) async => true);
      await abrir(tester, AppRoutes.resultado, argumentos: 'rec-1');
      await tester.tap(find.text('Compartilhar resultado'));
      await tester.pump();
      final texto =
          verify(
                () => m.compartilhador.compartilhar(captureAny(), assunto: any(named: 'assunto')),
              ).captured.single
              as String;
      expect(texto, contains('Kit Treino'));
      expect(texto, contains('https://www.cristalins.com.br/'));
    });
  });
}
