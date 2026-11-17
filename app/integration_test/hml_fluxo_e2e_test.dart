// E2E HML com WidgetTester (ferramenta padrão do projeto).
//
//   C:\flutter\bin\flutter.bat test integration_test/hml_fluxo_e2e_test.dart -d windows ^
//     --dart-define=API_URL=https://apicristalins.peladeiro.cloud
//
// Não paga Pix real. Abre/cancela diálogos destrutivos.

import 'dart:math';

import 'package:cristalins_assinatura/app.dart';
import 'package:cristalins_assinatura/core/config/app_config.dart';
import 'package:cristalins_assinatura/core/dependencias.dart';
import 'package:cristalins_assinatura/core/network/sessao.dart';
import 'package:cristalins_assinatura/core/routes.dart';
import 'package:cristalins_assinatura/core/widgets/botao_principal.dart';
import 'package:cristalins_assinatura/features/catalog/domain/catalogo.dart';
import 'package:cristalins_assinatura/features/ocorrencias/domain/ocorrencia.dart';
import 'package:cristalins_assinatura/features/subscription/domain/assinatura.dart';
import 'package:cristalins_assinatura/features/welcome/data/onboarding_prefs.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show Icons, Navigator, NavigatorState, ScaffoldMessenger, ScaffoldMessengerState, SizedBox, UniqueKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';

const _apiUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'https://apicristalins.peladeiro.cloud',
);

String _cpfDeTeste() {
  final r = Random();
  final base = List.generate(9, (_) => r.nextInt(9));
  int dv(List<int> d) {
    var soma = 0;
    for (var i = 0; i < d.length; i++) {
      soma += d[i] * (d.length + 1 - i);
    }
    final resto = soma % 11;
    return resto < 2 ? 0 : 11 - resto;
  }

  base.add(dv(base));
  base.add(dv(base));
  return base.join();
}

Future<void> _garantirApiHml() async {
  final url = '$_apiUrl${AppConfig.prefixoApi}/health';
  try {
    final r = await Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    ).get<Map<String, dynamic>>(url);
    if (r.data?['status'] != 'ok') {
      fail('HML em $url respondeu sem status ok: ${r.data}');
    }
  } on DioException catch (e) {
    fail('API HML indisponível em $url (${e.type.name}: ${e.message})');
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
    OnboardingPrefs.overrideVistoParaTeste = true;
    await _garantirApiHml();
  });

  tearDownAll(OnboardingPrefs.resetParaTeste);

  Future<void> esperar(
    WidgetTester tester,
    Finder alvo, {
    Duration limite = const Duration(seconds: 45),
  }) async {
    final fim = DateTime.now().add(limite);
    while (DateTime.now().isBefore(fim)) {
      await tester.pump(const Duration(milliseconds: 200));
      if (alvo.evaluate().isNotEmpty) return;
    }
    fail('Tempo esgotado esperando $alvo');
  }

  Future<void> esperarBotaoHabilitado(WidgetTester tester) async {
    final fim = DateTime.now().add(const Duration(seconds: 45));
    while (DateTime.now().isBefore(fim)) {
      await tester.pump(const Duration(milliseconds: 200));
      final botoes = find.byType(BotaoPrincipal);
      if (botoes.evaluate().isNotEmpty &&
          tester.widget<BotaoPrincipal>(botoes.last).onPressed != null) {
        return;
      }
    }
    fail('Botão principal não habilitou.');
  }

  Future<void> principal(WidgetTester tester) async {
    final botao = find.byType(BotaoPrincipal).last;
    await tester.ensureVisible(botao);
    await tester.tap(botao);
    await tester.pump();
  }

  /// Evita `pumpAndSettle` infinito (polling do Pix a cada 5s).
  Future<void> bombear(WidgetTester tester, [Duration d = const Duration(milliseconds: 400)]) async {
    await tester.pump(d);
  }

  Future<void> tocar(WidgetTester tester, Finder alvo) async {
    final messenger = find.byType(ScaffoldMessenger);
    if (messenger.evaluate().isNotEmpty) {
      tester.state<ScaffoldMessengerState>(messenger).hideCurrentSnackBar();
    }
    await bombear(tester);
    if (find.byType(Scrollable).evaluate().isNotEmpty) {
      try {
        await tester.scrollUntilVisible(alvo, 120, scrollable: find.byType(Scrollable).first);
      } catch (_) {}
    }
    await tester.ensureVisible(alvo);
    await bombear(tester);
    await tester.tap(alvo);
    await bombear(tester);
  }

  Future<void> escreverKey(WidgetTester tester, Key key, String texto) async {
    final alvo = find.byKey(key);
    await tester.ensureVisible(alvo);
    await tester.enterText(alvo, texto);
    await tester.pump();
  }

  Future<void> escolherNascimento(WidgetTester tester) async {
    await tocar(tester, find.byKey(const Key('campo-nascimento')));
    await bombear(tester);
    await tester.tap(find.text('Concluir'));
    await bombear(tester);
  }

  Future<void> escolherNaFolha(WidgetTester tester, int passos) async {
    await tocar(tester, find.text('Escolher'));
    if (passos > 0) {
      await tester.drag(find.byType(CupertinoPicker), Offset(0, -40.0 * passos));
      await bombear(tester);
    }
    await tester.tap(find.text('Concluir'));
    await bombear(tester);
  }

  Future<void> montarApp(
    WidgetTester tester, {
    required ArmazenamentoEmMemoria tokens,
    String rotaInicial = AppRoutes.cadastroLogin,
  }) async {
    // Limpa árvore anterior (evita stack/Navigator residual entre cenários).
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    final config = const AppConfig(ambiente: Ambiente.hml, apiUrl: _apiUrl, suporteWhatsapp: '');
    final dependencias = Dependencias.reais(config, tokens: tokens);
    await tester.pumpWidget(
      CristalinsApp(
        key: UniqueKey(),
        config: config,
        dependencias: dependencias,
        exibirSplash: false,
        rotaInicial: rotaInicial,
      ),
    );
    await bombear(tester, const Duration(milliseconds: 800));
  }

  Future<String> cadastrarAtePlano(WidgetTester tester) async {
    await esperar(tester, find.byKey(const Key('campo-email')));

    final carimbo = DateTime.now().millisecondsSinceEpoch;
    final email = 'qa.cristalins.$carimbo@example.com';
    await escreverKey(tester, const Key('campo-nome'), 'QA Browser Cristalins');
    await escreverKey(tester, const Key('campo-cpf'), _cpfDeTeste());
    await escolherNascimento(tester);
    await escreverKey(tester, const Key('campo-celular'), '21988887777');
    await escreverKey(tester, const Key('campo-email'), email);
    await escreverKey(tester, const Key('campo-senha'), 'senha-de-teste-123');
    await tocar(tester, find.textContaining('Li e aceito os termos'));
    await principal(tester);

    await esperar(tester, find.text('Pergunta 1 de 5'));
    await tocar(tester, find.text('Treino'));
    await principal(tester);
    await bombear(tester);
    await escolherNaFolha(tester, 2);
    await principal(tester);
    await bombear(tester);
    await escolherNaFolha(tester, 0);
    await principal(tester);
    await bombear(tester);
    await principal(tester);
    await bombear(tester);
    await principal(tester);

    await esperar(tester, find.text('Kit Treino'));
    expect(find.text('Preço estimado por entrega'), findsOneWidget);
    await principal(tester);

    await esperar(tester, find.textContaining('cesta').first);
    // F — kits / +/- se existirem
    if (find.textContaining('Kits').evaluate().isNotEmpty) {
      expect(find.textContaining('Kits'), findsWidgets);
    }
    final mais = find.byIcon(Icons.add);
    if (mais.evaluate().isNotEmpty) {
      await tocar(tester, mais.first);
      await bombear(tester);
    }
    await esperarBotaoHabilitado(tester);
    await principal(tester);

    await esperar(tester, find.text('Buscar CEP'));
    await escreverKey(tester, const Key('campo-cep'), '22041-001');
    await tocar(tester, find.text('Buscar CEP'));
    await esperar(tester, find.textContaining('Zona Sul'));
    await escreverKey(tester, const Key('campo-numero'), '100');
    await principal(tester);

    await esperar(tester, find.text('Resumo por entrega'));
    await esperar(tester, find.text('Total'));
    await esperarBotaoHabilitado(tester);
    expect(find.text('Assinar agora'), findsOneWidget);
    return email;
  }

  testWidgets('HML feliz: cadastro → quiz → cesta → endereço → assinar → Pix → assinatura', (
    tester,
  ) async {
    final tokens = ArmazenamentoEmMemoria();
    await montarApp(tester, tokens: tokens);
    await cadastrarAtePlano(tester);

    await principal(tester); // Assinar agora
    await esperar(tester, find.textContaining('Aguardando'));
    expect(find.text('Copiar código Pix'), findsOneWidget);
    // Não dispara Clipboard.setData aqui: no Windows o canal pode falhar (PlatformException)
    // e derrubar o binding do integration_test.

    final verAssinatura = find.text('Ver minha assinatura');
    await esperar(tester, verAssinatura);
    await tocar(tester, verAssinatura.first);
    await esperar(tester, find.text('Minha assinatura'));

    if (find.text('Pausar entregas').evaluate().isNotEmpty) {
      await tocar(tester, find.text('Pausar entregas'));
      await bombear(tester);
      expect(find.text('Voltar'), findsOneWidget);
      await tocar(tester, find.text('Voltar'));
      await bombear(tester);
    }

    if (find.text('Cancelar assinatura').evaluate().isNotEmpty) {
      await tocar(tester, find.text('Cancelar assinatura'));
      await bombear(tester);
      expect(find.text('Cancelar assinatura?'), findsOneWidget);
      await tocar(tester, find.text('Manter assinatura'));
      await bombear(tester);
    }

    if (find.text('Excluir minha conta').evaluate().isNotEmpty) {
      await tocar(tester, find.text('Excluir minha conta'));
      await bombear(tester);
      await tocar(tester, find.text('Manter conta'));
      await bombear(tester);
    }

    if (find.text('Faturas e forma de pagamento').evaluate().isNotEmpty) {
      await tocar(tester, find.text('Faturas e forma de pagamento'));
      await esperar(tester, find.text('Pagamentos'));
      expect(find.text('Forma de pagamento'), findsOneWidget);
      expect(find.text('Faturas'), findsWidgets);
      // K — formas visíveis; sem salvar cartão real
      expect(find.textContaining('Pix').evaluate().isNotEmpty, isTrue);
      final back = find.byType(CupertinoNavigationBarBackButton);
      if (back.evaluate().isNotEmpty) {
        await tocar(tester, back.first);
      } else if (find.text('Voltar').evaluate().isNotEmpty) {
        await tocar(tester, find.text('Voltar').first);
      }
      await bombear(tester);
    }

    if (find.text('Alterar cesta').evaluate().isNotEmpty) {
      await tocar(tester, find.text('Alterar cesta'));
      await esperar(tester, find.textContaining('cesta').first);
      if (find.text('Voltar').evaluate().isNotEmpty) {
        await tocar(tester, find.text('Voltar').first);
      }
      await bombear(tester);
    }

    expect(tokens.acesso, isNotNull);
  });

  testWidgets('HML: login errado → login ok → esqueci senha', (tester) async {
    final carimbo = DateTime.now().millisecondsSinceEpoch;
    final email = 'qa.login.$carimbo@example.com';
    final senha = 'senha-de-teste-123';
    // Conta criada na API (mesmo backend HML); UI só exercita login.
    final dio = Dio(BaseOptions(baseUrl: '$_apiUrl${AppConfig.prefixoApi}'));
    await dio.post<Map<String, dynamic>>(
      '/clientes',
      data: {
        'nome': 'QA Login Cristalins',
        'cpfCnpj': _cpfDeTeste(),
        'email': email,
        'dataNascimento': '1995-05-10',
        'senha': senha,
        'aceiteTermos': true,
        'celular': '21977776666',
        'marketingOk': false,
      },
    );

    final tokens = ArmazenamentoEmMemoria();
    await montarApp(tester, tokens: tokens, rotaInicial: AppRoutes.cadastroLogin);
    await esperar(tester, find.byKey(const Key('campo-email')));
    await tester.tap(find.text('Já tenho conta'));
    await bombear(tester, const Duration(milliseconds: 800));
    await esperar(tester, find.text('Esqueci a senha'));

    await escreverKey(tester, const Key('campo-email'), email);
    await escreverKey(tester, const Key('campo-senha'), 'senha-errada-xxx');
    final entrar = find.widgetWithText(BotaoPrincipal, 'Entrar');
    await esperar(tester, entrar);
    await tester.ensureVisible(entrar);
    await tester.tap(entrar);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Esqueci a senha'), findsOneWidget);
    expect(tokens.acesso, isNull);

    await escreverKey(tester, const Key('campo-email'), email);
    await escreverKey(tester, const Key('campo-senha'), senha);
    await tester.tap(entrar);
    final fim = DateTime.now().add(const Duration(seconds: 45));
    while (DateTime.now().isBefore(fim) && tokens.acesso == null) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(
      tokens.acesso,
      isNotNull,
      reason:
          'Login correto deve gravar accessToken. '
          'Na tela: Entrar=${entrar.evaluate().length}, '
          'quiz=${find.text('Pergunta 1 de 5').evaluate().length}',
    );
    // Pós-login: quiz (sem assinatura) ou Minha assinatura (se a API já tiver vínculo).
    final posLogin = find.text('Pergunta 1 de 5').evaluate().isNotEmpty
        ? find.text('Pergunta 1 de 5')
        : find.text('Minha assinatura').evaluate().isNotEmpty
            ? find.text('Minha assinatura')
            : find.text('Pergunta 1 de 5');
    await esperar(tester, posLogin);

    // Esqueci senha em app limpo
    final tokens2 = ArmazenamentoEmMemoria();
    await montarApp(tester, tokens: tokens2, rotaInicial: AppRoutes.cadastroLogin);
    await esperar(tester, find.byKey(const Key('campo-email')));
    await tester.tap(find.text('Já tenho conta'));
    await bombear(tester, const Duration(milliseconds: 800));
    await tester.tap(find.text('Esqueci a senha'));
    await esperar(tester, find.text('Enviar código'));
    await escreverKey(tester, const Key('campo-email-esqueci'), email);
    await principal(tester);
    await esperar(tester, find.text('Nova senha'));
    expect(find.text('Código'), findsWidgets);
  });

  testWidgets('HML: onboarding site + validações cadastro', (tester) async {
    final tokens = ArmazenamentoEmMemoria();
    await montarApp(tester, tokens: tokens, rotaInicial: AppRoutes.boasVindas);
    await esperar(tester, find.text('Assinar Water Protein'));
    expect(find.textContaining('Cristalins'), findsWidgets);

    await tocar(tester, find.textContaining('Conhecer o site da Cristalins'));
    await bombear(tester, const Duration(seconds: 1));
    // Abre externo ou snackbar — app não pode crashar
    expect(find.text('Assinar Water Protein'), findsOneWidget);

    await montarApp(tester, tokens: tokens, rotaInicial: AppRoutes.cadastroLogin);
    await esperar(tester, find.byKey(const Key('campo-email')));
    expect(find.text('Criar conta'), findsWidgets);

    await principal(tester); // vazio
    await bombear(tester, const Duration(milliseconds: 600));
    expect(find.byKey(const Key('campo-email')), findsOneWidget);

    await escreverKey(tester, const Key('campo-nome'), 'QA Sem Termos');
    await escreverKey(tester, const Key('campo-cpf'), _cpfDeTeste());
    await escolherNascimento(tester);
    await escreverKey(tester, const Key('campo-celular'), '21988887777');
    await escreverKey(tester, const Key('campo-email'), 'qa.semtermos.${DateTime.now().millisecondsSinceEpoch}@example.com');
    await escreverKey(tester, const Key('campo-senha'), 'senha-de-teste-123');
    await principal(tester);
    await bombear(tester, const Duration(seconds: 1));
    expect(find.text('Pergunta 1 de 5'), findsNothing);
    expect(
      find.textContaining('aceite os termos'),
      findsOneWidget,
      reason: 'Sem aceite de termos deve mostrar erro inline',
    );
    expect(find.widgetWithText(BotaoPrincipal, 'Criar conta'), findsOneWidget);
  });

  testWidgets('HML: CEP fora cobertura (01310-100)', (tester) async {
    final tokens = ArmazenamentoEmMemoria();
    await montarApp(tester, tokens: tokens, rotaInicial: AppRoutes.cadastroLogin);
    await esperar(tester, find.byKey(const Key('campo-email')));
    await bombear(tester);

    final email = 'qa.cep.${DateTime.now().millisecondsSinceEpoch}@example.com';
    await escreverKey(tester, const Key('campo-nome'), 'QA CEP Fora');
    await escreverKey(tester, const Key('campo-cpf'), _cpfDeTeste());
    await escolherNascimento(tester);
    await escreverKey(tester, const Key('campo-celular'), '21988887777');
    await escreverKey(tester, const Key('campo-email'), email);
    await escreverKey(tester, const Key('campo-senha'), 'senha-de-teste-123');
    await tocar(tester, find.textContaining('Li e aceito os termos'));
    await principal(tester);

    await esperar(tester, find.text('Pergunta 1 de 5'));
    await tocar(tester, find.text('Treino'));
    await principal(tester);
    await bombear(tester);
    await escolherNaFolha(tester, 2);
    await principal(tester);
    await bombear(tester);
    await escolherNaFolha(tester, 0);
    await principal(tester);
    await bombear(tester);
    await principal(tester);
    await bombear(tester);
    await principal(tester);
    await esperar(tester, find.text('Kit Treino'));
    await principal(tester);
    await esperar(tester, find.textContaining('cesta').first);
    await esperarBotaoHabilitado(tester);
    await principal(tester);

    await esperar(tester, find.text('Buscar CEP'));
    await escreverKey(tester, const Key('campo-cep'), '01310-100');
    await tester.tap(find.text('Buscar CEP'));
    await bombear(tester, const Duration(seconds: 2));
    await esperar(tester, find.text('Lista de espera'));
    expect(find.textContaining('avisamos'), findsWidgets);
  });

  testWidgets('HML: shell abas Início/Produtos/Assinatura/Perfil', (tester) async {
    final tokens = ArmazenamentoEmMemoria();
    await montarApp(tester, tokens: tokens, rotaInicial: AppRoutes.shell);
    await esperar(tester, find.text('Início'));
    expect(find.text('Produtos'), findsWidgets);
    expect(find.text('Assinatura'), findsWidgets);
    expect(find.text('Perfil'), findsWidgets);

    await tester.tap(find.text('Produtos').last);
    await bombear(tester, const Duration(seconds: 2));
    expect(find.text('Produtos'), findsWidgets);

    await tester.tap(find.text('Assinatura').last);
    await bombear(tester, const Duration(seconds: 2));

    await tester.tap(find.text('Perfil').last);
    await bombear(tester, const Duration(seconds: 1));

    await tester.tap(find.text('Início').last);
    await bombear(tester, const Duration(seconds: 1));
  });

  testWidgets('HML: ocorrência UI (rota direta ciclo ENTREGUE)', (tester) async {
    final tokens = ArmazenamentoEmMemoria();
    await montarApp(tester, tokens: tokens, rotaInicial: AppRoutes.shell);
    await esperar(tester, find.text('Início'));

    final ciclo = Ciclo(
      id: 'ciclo-qa-e2e',
      numero: 1,
      dataEntrega: '2026-11-10',
      dataCorte: '2026-11-08',
      status: 'ENTREGUE',
      itens: const [ItemCesta('WP500', 2)],
    );
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    // pushNamed só completa ao pop — não await
    nav.pushNamed(AppRoutes.ocorrencia, arguments: PedidoOcorrencia(ciclo: ciclo));
    await bombear(tester, const Duration(seconds: 1));
    await esperar(tester, find.text('Informar problema'));
    expect(find.text('Avaria'), findsOneWidget);
    expect(find.text('Falta'), findsOneWidget);
    expect(find.text('Adicionar foto'), findsOneWidget);
    await tester.tap(find.text('Falta'));
    await bombear(tester);
    await tester.tap(find.text('Water Protein 500 ml'));
    await bombear(tester);
    expect(find.text('Quantidade'), findsOneWidget);
    expect(find.text('Reposição'), findsOneWidget);
    expect(find.text('Crédito'), findsOneWidget);
  });

  testWidgets('HML: onboarding Assinar WP / Descobrir kit / Pular', (tester) async {
    OnboardingPrefs.overrideVistoParaTeste = false;
    addTearDown(() => OnboardingPrefs.overrideVistoParaTeste = true);

    final tokens = ArmazenamentoEmMemoria();
    await montarApp(tester, tokens: tokens, rotaInicial: AppRoutes.onboarding);
    await esperar(tester, find.text('Assinar Water Protein'));
    expect(find.text('Descobrir meu kit'), findsOneWidget);
    expect(find.text('Pular'), findsOneWidget);

    await tester.tap(find.text('Descobrir meu kit'));
    await esperar(tester, find.text('Pergunta 1 de 5'));

    final tokens2 = ArmazenamentoEmMemoria();
    OnboardingPrefs.overrideVistoParaTeste = false;
    await montarApp(tester, tokens: tokens2, rotaInicial: AppRoutes.onboarding);
    await esperar(tester, find.text('Assinar Water Protein'));
    await tester.tap(find.text('Pular'));
    await esperar(tester, find.text('Início'));
  });
}
