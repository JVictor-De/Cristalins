import 'dart:async';

import 'package:cristalins_assinatura/core/network/api_erro.dart';
import 'package:cristalins_assinatura/core/routes.dart';
import 'package:cristalins_assinatura/core/widgets/botao_principal.dart';
import 'package:cristalins_assinatura/features/auth/data/auth_repository.dart';
import 'package:cristalins_assinatura/features/subscription/domain/assinatura.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/mocks.dart';

/// Tela 2 — Cadastro e login com a API simulada por mocktail.
void main() {
  setUpAll(registrarFallbacks);

  late Mocks m;

  setUp(() => m = Mocks());

  Future<void> abrir(WidgetTester tester) async {
    await prepararTela(tester);
    await tester.pumpWidget(appComMocks(m));
    await tester.pumpAndSettle();
    tester.state<NavigatorState>(find.byType(Navigator)).pushNamed(AppRoutes.cadastroLogin);
    await tester.pumpAndSettle();
  }

  Future<void> escrever(WidgetTester tester, int campo, String texto) async {
    final alvo = find.byType(CupertinoTextFormFieldRow).at(campo);
    await tester.ensureVisible(alvo);
    await tester.enterText(alvo, texto);
    await tester.pump();
  }

  Future<void> enviar(WidgetTester tester) async {
    await tester.tap(find.byType(BotaoPrincipal));
    await tester.pump();
  }

  Future<void> preencherCadastro(WidgetTester tester, {bool termos = true}) async {
    await escrever(tester, 0, '  Ana Souza ');
    await escrever(tester, 1, '529.982.247-25');
    await escrever(tester, 2, '10/05/1995');
    await escrever(tester, 3, '(21) 98765-4321');
    await escrever(tester, 4, ' Ana@Exemplo.com ');
    await escrever(tester, 5, 'senha-forte-123');
    if (termos) {
      final linha = find.text('Li e aceito os termos de uso e a política de privacidade');
      await tester.ensureVisible(linha);
      await tester.tap(linha);
      await tester.pump();
    }
  }

  BotaoPrincipal botao(WidgetTester tester) =>
      tester.widget<BotaoPrincipal>(find.byType(BotaoPrincipal));

  group('cadastro', () {
    testWidgets('valida cada campo antes de enviar e não chama a API', (tester) async {
      await abrir(tester);
      await enviar(tester);
      await tester.pumpAndSettle();

      expect(find.text('Informe o nome completo.'), findsOneWidget);
      expect(find.text('CPF ou CNPJ inválido. Confira os números.'), findsOneWidget);
      expect(find.text('Informe a data no formato DD/MM/AAAA.'), findsOneWidget);
      expect(find.text('Informe um e-mail válido.'), findsOneWidget);
      // Uma vez na nota da seção e outra como erro do campo
      expect(find.text('A senha precisa ter pelo menos 8 caracteres.'), findsNWidgets(2));

      // CPF com dígito errado e data inexistente também param no app
      await escrever(tester, 1, '529.982.247-26');
      await escrever(tester, 2, '31/02/1995');
      await enviar(tester);
      await tester.pumpAndSettle();
      expect(find.text('CPF ou CNPJ inválido. Confira os números.'), findsOneWidget);
      expect(find.text('Informe a data no formato DD/MM/AAAA.'), findsOneWidget);
      verifyNever(() => m.auth.cadastrar(any()));
    });

    testWidgets('sem aceite dos termos não envia', (tester) async {
      await abrir(tester);
      await preencherCadastro(tester, termos: false);
      await enviar(tester);
      await tester.pumpAndSettle();
      expect(
        find.text('Para criar a conta, aceite os termos de uso e a política de privacidade.'),
        findsOneWidget,
      );
      verifyNever(() => m.auth.cadastrar(any()));
    });

    testWidgets('mostra carregando no botão, envia os dados normalizados e segue para o quiz', (
      tester,
    ) async {
      final resposta = Completer<void>();
      when(() => m.auth.cadastrar(any())).thenAnswer((_) => resposta.future);
      await abrir(tester);
      await preencherCadastro(tester);
      await enviar(tester);

      // Carregando: indicador no botão e sem toque duplo
      expect(
        find.descendant(
          of: find.byType(BotaoPrincipal),
          matching: find.byType(CupertinoActivityIndicator),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byType(BotaoPrincipal));
      verify(() => m.auth.cadastrar(any())).called(1);

      resposta.complete();
      await tester.pumpAndSettle();
      expect(find.text('Pergunta 1 de 5'), findsOneWidget);
    });

    testWidgets('dados enviados à API: CPF só dígitos, data ISO, e-mail em minúsculas, aceite', (
      tester,
    ) async {
      when(() => m.auth.cadastrar(any())).thenAnswer((_) async {});
      await abrir(tester);
      await preencherCadastro(tester);
      await enviar(tester);
      await tester.pumpAndSettle();

      final dados = verify(() => m.auth.cadastrar(captureAny())).captured.single as DadosCadastro;
      expect(dados.nome, 'Ana Souza');
      expect(dados.cpfCnpj, '52998224725');
      expect(dados.dataNascimento, '1995-05-10');
      expect(dados.celular, '21987654321');
      expect(dados.email, 'ana@exemplo.com');
      expect(dados.aceiteTermos, isTrue);
    });

    testWidgets('erro da API (CT24 / CPF já cadastrado) aparece e o usuário continua na tela', (
      tester,
    ) async {
      when(() => m.auth.cadastrar(any())).thenThrow(
        const ApiErro(
          codigo: 'MENOR_DE_IDADE',
          mensagem: 'A assinatura é só para maiores de 18 anos.',
          campo: 'dataNascimento',
        ),
      );
      await abrir(tester);
      await preencherCadastro(tester);
      await enviar(tester);
      await tester.pumpAndSettle();

      expect(find.text('A assinatura é só para maiores de 18 anos.'), findsWidgets);
      expect(find.text('Seus dados'), findsOneWidget);
      expect(botao(tester).onPressed, isNotNull); // pode tentar de novo
    });
  });

  group('login', () {
    Future<void> irParaLogin(WidgetTester tester) async {
      await abrir(tester);
      await tester.tap(find.text('Já tenho conta'));
      await tester.pumpAndSettle();
      expect(find.text('Seus dados'), findsNothing);
    }

    testWidgets('quem tem assinatura vai para a Tela 8', (tester) async {
      when(() => m.auth.entrar(any(), any())).thenAnswer((_) async {});
      when(() => m.assinaturas.listar()).thenAnswer(
        (_) async => const [
          Assinatura(
            id: 'ass-1',
            status: 'ATIVA',
            plano: 'FLEX',
            frequencia: 'SEMANAL',
            janela: 'MANHA',
            itens: [],
            bairro: 'Copacabana',
            zona: 'Zona Sul',
          ),
        ],
      );
      when(() => m.assinaturas.ciclos(any())).thenAnswer((_) async => []);
      await irParaLogin(tester);
      await escrever(tester, 0, ' Ana@Exemplo.com');
      await escrever(tester, 1, 'senha-forte-123');
      await enviar(tester);
      await tester.pumpAndSettle();

      verify(() => m.auth.entrar('ana@exemplo.com', 'senha-forte-123')).called(1);
      expect(find.text('Minha assinatura'), findsWidgets);
    });

    testWidgets('sem assinatura ativa (só cancelada) vai para o quiz', (tester) async {
      when(() => m.auth.entrar(any(), any())).thenAnswer((_) async {});
      when(() => m.assinaturas.listar()).thenAnswer(
        (_) async => const [
          Assinatura(
            id: 'ass-1',
            status: 'CANCELADA',
            plano: 'FLEX',
            frequencia: 'SEMANAL',
            janela: 'MANHA',
            itens: [],
            bairro: 'Copacabana',
            zona: 'Zona Sul',
          ),
        ],
      );
      await irParaLogin(tester);
      await escrever(tester, 0, 'ana@exemplo.com');
      await escrever(tester, 1, 'senha-forte-123');
      await enviar(tester);
      await tester.pumpAndSettle();
      expect(find.text('Pergunta 1 de 5'), findsOneWidget);
    });

    testWidgets('credenciais inválidas mostram a mensagem da API', (tester) async {
      when(() => m.auth.entrar(any(), any())).thenThrow(
        const ApiErro(codigo: 'CREDENCIAIS_INVALIDAS', mensagem: 'E-mail ou senha incorretos.'),
      );
      await irParaLogin(tester);
      await escrever(tester, 0, 'ana@exemplo.com');
      await escrever(tester, 1, 'errada');
      await enviar(tester);
      await tester.pumpAndSettle();
      expect(find.text('E-mail ou senha incorretos.'), findsWidgets);
      verifyNever(() => m.assinaturas.listar());
    });

    testWidgets('login sem senha não chama a API', (tester) async {
      await irParaLogin(tester);
      await escrever(tester, 0, 'ana@exemplo.com');
      await enviar(tester);
      await tester.pumpAndSettle();
      expect(find.text('Informe a senha.'), findsOneWidget);
      verifyNever(() => m.auth.entrar(any(), any()));
    });
  });
}
