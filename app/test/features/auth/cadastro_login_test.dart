import 'dart:async';

import 'package:cristalins_assinatura/core/config/app_config.dart';
import 'package:cristalins_assinatura/core/network/api_erro.dart';
import 'package:cristalins_assinatura/core/routes.dart';
import 'package:cristalins_assinatura/core/widgets/botao_principal.dart';
import 'package:cristalins_assinatura/features/auth/data/auth_repository.dart';
import 'package:cristalins_assinatura/features/subscription/domain/assinatura.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/mocks.dart';

/// Tela 2 — Cadastro e login com a API simulada por mocktail.
void main() {
  setUpAll(registrarFallbacks);

  late Mocks m;

  setUp(() => m = Mocks());

  Future<void> abrir(WidgetTester tester, {Object? args}) async {
    await prepararTela(tester);
    await tester.pumpWidget(appComMocks(m));
    await tester.pumpAndSettle();
    tester.state<NavigatorState>(find.byType(Navigator)).pushNamed(
          AppRoutes.cadastroLogin,
          arguments: args,
        );
    await tester.pumpAndSettle();
  }

  Future<void> escrever(WidgetTester tester, Key key, String texto) async {
    final alvo = find.byKey(key);
    await tester.ensureVisible(alvo);
    await tester.enterText(alvo, texto);
    await tester.pump();
  }

  Future<void> escolherNascimento(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('campo-nascimento')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Concluir'));
    await tester.pumpAndSettle();
  }

  Future<void> enviar(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(BotaoPrincipal, 'Criar conta').hitTestable().first);
    await tester.pump();
  }

  Future<void> enviarLogin(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(BotaoPrincipal, 'Entrar').hitTestable().first);
    await tester.pump();
  }

  Future<void> preencherCadastro(WidgetTester tester, {bool termos = true}) async {
    await escrever(tester, const Key('campo-nome'), '  Ana Souza ');
    await escrever(tester, const Key('campo-cpf'), '529.982.247-25');
    // Força data válida ≥18 sem depender do picker default.
    final nasc = find.byKey(const Key('campo-nascimento'));
    await tester.ensureVisible(nasc);
    // Abre picker e confirma (máx = hoje−18).
    await escolherNascimento(tester);
    // Sobrescreve com data fixa conhecida pela digitação no controller via enterText no FormField interno.
    // O campo data é InkWell — setamos via state: reabre e... melhor setar texto no FormField se existir.
    // Fallback: find TextFormField não; usamos data já do picker (sempre ≥18).
    await escrever(tester, const Key('campo-celular'), '(21) 98765-4321');
    await escrever(tester, const Key('campo-email'), ' Ana@Exemplo.com ');
    await escrever(tester, const Key('campo-senha'), 'senha-forte-123');
    if (termos) {
      final linha = find.textContaining('Li e aceito os');
      await tester.ensureVisible(linha);
      await tester.tap(linha);
      await tester.pump();
    }
  }

  BotaoPrincipal botaoCriar(WidgetTester tester) =>
      tester.widget<BotaoPrincipal>(find.widgetWithText(BotaoPrincipal, 'Criar conta'));

  group('cadastro', () {
    testWidgets('valida cada campo antes de enviar e não chama a API', (tester) async {
      await abrir(tester);
      await enviar(tester);
      await tester.pumpAndSettle();

      expect(find.text('Informe o nome completo.'), findsOneWidget);
      expect(find.text('CPF ou CNPJ inválido. Confira os números.'), findsOneWidget);
      expect(find.textContaining('DD/MM/AAAA'), findsWidgets);
      expect(find.text('Informe o celular com DDD.'), findsOneWidget);
      expect(find.text('Informe um e-mail válido.'), findsOneWidget);
      expect(find.text('A senha precisa ter pelo menos 8 caracteres.'), findsOneWidget);
      verifyNever(() => m.auth.cadastrar(any()));
    });

    testWidgets('sem Explorar no miolo; logo e CPF ou CNPJ; CTA Criar conta uma vez no botão', (
      tester,
    ) async {
      await abrir(tester);
      expect(find.text('CPF ou CNPJ'), findsOneWidget);
      expect(find.text('Explorar sem entrar'), findsOneWidget);
      expect(find.widgetWithText(BotaoPrincipal, 'Criar conta'), findsOneWidget);
      expect(find.text('Criar conta'), findsWidgets); // aba + botão
      await tester.pump(const Duration(seconds: 2)); // splash timer residual
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

    testWidgets('termos e privacidade são links (sem “em breve”) com URLs default', (tester) async {
      await abrir(tester);
      await tester.pump(const Duration(seconds: 2)); // splash timer residual
      expect(find.textContaining('(links em breve)'), findsNothing);
      expect(find.textContaining('termos de uso'), findsOneWidget);
      expect(find.textContaining('política de privacidade'), findsOneWidget);
      expect(AppConfig.urlTermos, isNotEmpty);
      expect(AppConfig.urlPrivacidade, isNotEmpty);
    });

    testWidgets('mostra carregando no botão, envia e segue para o quiz', (tester) async {
      final resposta = Completer<void>();
      when(() => m.auth.cadastrar(any())).thenAnswer((_) => resposta.future);
      await abrir(tester);
      await preencherCadastro(tester);
      await enviar(tester);

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

    testWidgets('dados enviados normalizados + marketingOk', (tester) async {
      when(() => m.auth.cadastrar(any())).thenAnswer((_) async {});
      await abrir(tester);
      await preencherCadastro(tester);
      await enviar(tester);
      await tester.pumpAndSettle();

      final dados = verify(() => m.auth.cadastrar(captureAny())).captured.single as DadosCadastro;
      expect(dados.nome, 'Ana Souza');
      expect(dados.cpfCnpj, '52998224725');
      expect(dados.celular, '21987654321');
      expect(dados.email, 'ana@exemplo.com');
      expect(dados.aceiteTermos, isTrue);
      expect(dados.dataNascimento.length, 10);
    });

    testWidgets('origem checkout: volta em vez de quiz', (tester) async {
      when(() => m.auth.cadastrar(any())).thenAnswer((_) async {});
      await abrir(tester, args: 'checkout');
      await preencherCadastro(tester);
      await enviar(tester);
      await tester.pumpAndSettle();
      expect(find.text('Pergunta 1 de 5'), findsNothing);
      expect(find.textContaining('finalizar sua assinatura'), findsOneWidget);
    });

    testWidgets('erro da API aparece e pode tentar de novo', (tester) async {
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
      expect(botaoCriar(tester).onPressed, isNotNull);
    });

    testWidgets('e-mail duplicado oferece atalho Entrar', (tester) async {
      when(() => m.auth.cadastrar(any())).thenThrow(
        const ApiErro(
          codigo: 'CONFLITO',
          mensagem: 'Este e-mail já está cadastrado.',
          campo: 'email',
        ),
      );
      await abrir(tester);
      await preencherCadastro(tester);
      await enviar(tester);
      await tester.pumpAndSettle();
      expect(find.text('Este e-mail já tem conta.'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Entrar'));
      await tester.pumpAndSettle();
      expect(find.text('Seus dados'), findsNothing);
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
      await escrever(tester, const Key('campo-email'), ' Ana@Exemplo.com');
      await escrever(tester, const Key('campo-senha'), 'senha-forte-123');
      await enviarLogin(tester);
      await tester.pumpAndSettle();

      verify(() => m.auth.entrar('ana@exemplo.com', 'senha-forte-123')).called(1);
      expect(find.text('Minha assinatura'), findsWidgets);
    });

    testWidgets('sem assinatura ativa vai para o quiz', (tester) async {
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
      await escrever(tester, const Key('campo-email'), 'ana@exemplo.com');
      await escrever(tester, const Key('campo-senha'), 'senha-forte-123');
      await enviarLogin(tester);
      await tester.pumpAndSettle();
      expect(find.text('Pergunta 1 de 5'), findsOneWidget);
    });

    testWidgets('credenciais inválidas mostram a mensagem da API', (tester) async {
      when(() => m.auth.entrar(any(), any())).thenThrow(
        const ApiErro(codigo: 'CREDENCIAIS_INVALIDAS', mensagem: 'E-mail ou senha incorretos.'),
      );
      await irParaLogin(tester);
      await escrever(tester, const Key('campo-email'), 'ana@exemplo.com');
      await escrever(tester, const Key('campo-senha'), 'errada');
      await enviarLogin(tester);
      await tester.pumpAndSettle();
      expect(find.text('E-mail ou senha incorretos.'), findsWidgets);
      verify(() => m.auth.entrar(any(), any())).called(1);
    });

    testWidgets('login sem senha não chama a API', (tester) async {
      await irParaLogin(tester);
      await escrever(tester, const Key('campo-email'), 'ana@exemplo.com');
      await enviarLogin(tester);
      await tester.pumpAndSettle();
      expect(find.text('Informe a senha.'), findsOneWidget);
      verifyNever(() => m.auth.entrar(any(), any()));
    });
  });
}
