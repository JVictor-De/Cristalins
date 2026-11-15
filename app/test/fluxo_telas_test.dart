import 'package:cristalins_assinatura/core/routes.dart';
import 'package:cristalins_assinatura/core/widgets/botao_principal.dart';
import 'package:cristalins_assinatura/features/address/domain/endereco.dart';
import 'package:cristalins_assinatura/features/catalog/domain/catalogo.dart';
import 'package:cristalins_assinatura/features/subscription/domain/assinatura.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show ScaffoldMessenger, ScaffoldMessengerState;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'support/fakes.dart';

/// Fluxo 1 → 8 com repositórios falsos (o integration_test contra a API local é da cr-2-testes).
void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  setUp(() {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(1080, 2340); // 360 × 780 dp
    view.devicePixelRatio = 3;
    addTearDown(view.reset);
  });

  Future<void> principal(WidgetTester tester) async {
    await tester.tap(find.byType(BotaoPrincipal));
    await tester.pumpAndSettle();
  }

  /// Fecha o aviso (SnackBar) da ação anterior: ele flutua sobre o fim da lista.
  Future<void> fecharAviso(WidgetTester tester) async {
    tester.state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger)).hideCurrentSnackBar();
    await tester.pumpAndSettle();
  }

  Future<void> rolarAte(WidgetTester tester, Finder alvo) async {
    await tester.scrollUntilVisible(alvo, 120, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(alvo);
    await tester.pumpAndSettle();
  }

  Future<void> tocar(WidgetTester tester, Finder alvo) async {
    await fecharAviso(tester);
    await rolarAte(tester, alvo);
    await tester.tap(alvo);
    await tester.pumpAndSettle();
  }

  Future<void> escrever(WidgetTester tester, int campo, String texto) async {
    final alvo = find.byType(CupertinoTextFormFieldRow).at(campo);
    await tester.ensureVisible(alvo);
    await tester.enterText(alvo, texto);
    await tester.pump();
  }

  void abrirRota(WidgetTester tester, String rota, {Object? argumentos}) {
    tester.state<NavigatorState>(find.byType(Navigator)).pushNamed(rota, arguments: argumentos);
  }

  testWidgets('cadastro → quiz → resultado → cesta → endereço → plano → minha assinatura', (
    tester,
  ) async {
    final f = Falsos();
    await tester.pumpWidget(appDeTeste(f));
    await tester.pumpAndSettle();

    // Tela 1 → 2
    await principal(tester);
    expect(find.text('Seus dados'), findsOneWidget);

    // Tela 2: valida antes de enviar
    await principal(tester);
    expect(find.text('Informe o nome completo.'), findsOneWidget);
    expect(f.auth.cadastros, 0);

    await escrever(tester, 0, 'Ana Souza');
    await escrever(tester, 1, '529.982.247-25');
    await escrever(tester, 2, '10/05/1995');
    await escrever(tester, 4, 'ana@exemplo.com');
    await escrever(tester, 5, 'senha-forte-123');
    await principal(tester);
    expect(
      find.text('Para criar a conta, aceite os termos de uso e a política de privacidade.'),
      findsOneWidget,
    );
    await tocar(tester, find.text('Li e aceito os termos de uso e a política de privacidade'));
    await principal(tester);
    expect(f.auth.cadastros, 1);

    // Tela 3: uma pergunta por vez; o avançar fica desabilitado sem resposta
    expect(find.text('Pergunta 1 de 5'), findsOneWidget);
    expect(tester.widget<BotaoPrincipal>(find.byType(BotaoPrincipal)).onPressed, isNull);
    await tocar(tester, find.text('Treino'));
    await principal(tester);
    expect(find.text('Pergunta 2 de 5'), findsOneWidget);

    // Botão voltar do Android volta uma pergunta
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Pergunta 1 de 5'), findsOneWidget);
    await principal(tester);

    for (var i = 0; i < 2; i++) {
      await tocar(tester, find.text('Escolher'));
      await tester.tap(find.text('Concluir'));
      await tester.pumpAndSettle();
      await principal(tester);
    }
    expect(find.text('Pergunta 4 de 5'), findsOneWidget);
    await principal(tester);
    await principal(tester); // "Ver minha recomendação"
    expect(f.recomendacoes.ultimas!.objetivo, 'TREINO');
    expect(f.recomendacoes.ultimas!.diasSemana, '1-2');

    // Tela 4: resultado e compartilhar (Intent)
    expect(find.text('Kit Treino'), findsOneWidget);
    // pt_BR usa espaço não separável entre "R$" e o número
    expect(find.textContaining('118,80'), findsOneWidget);
    await tocar(tester, find.text('Compartilhar resultado'));
    expect(f.compartilhador.textos.single, contains('Kit Treino'));
    await principal(tester);

    // Tela 5: cesta veio da recomendação; preço da API
    expect(find.text('Sua cesta'), findsWidgets);
    expect(f.catalogo.simulacoes.last, [const ItemCesta('WP500', 12)]);
    await principal(tester);

    // Tela 6: CEP, número, janela e mapa
    await escrever(tester, 0, '22041-001');
    await tocar(tester, find.text('Buscar CEP'));
    expect(find.text('Avenida Nossa Senhora de Copacabana'), findsOneWidget);
    await escrever(tester, 1, '100');
    await tocar(tester, find.text('Abrir no mapa'));
    expect(f.links.abertos.single, startsWith('geo:0,0?q='));
    await principal(tester); // Salvar endereço
    expect(f.enderecos.salvos, hasLength(1));

    // Tela 7: resumo vindo da API e "Assinar agora"
    expect(find.text('Plano e pagamento'), findsWidgets);
    await rolarAte(tester, find.textContaining('128,70'));
    expect(find.textContaining('128,70'), findsOneWidget);
    await principal(tester);
    expect(f.assinaturas.chamadas, ['criar']);

    // Tela 8
    expect(find.text('Minha assinatura'), findsWidgets);
    expect(find.text('AGUARDANDO PAGAMENTO'), findsOneWidget);
  });

  testWidgets('quem já tem assinatura vai do login direto para a Tela 8', (tester) async {
    final f = Falsos()..assinaturas.comAssinaturaAtiva();
    await tester.pumpWidget(appDeTeste(f));
    await tester.pumpAndSettle();
    await principal(tester);
    await tester.tap(find.text('Já tenho conta'));
    await tester.pumpAndSettle();
    await escrever(tester, 0, 'ana@exemplo.com');
    await escrever(tester, 1, 'senha-forte-123');
    await principal(tester);
    expect(f.auth.logins, 1);
    expect(find.text('Minha assinatura'), findsWidgets);
    expect(find.text('ATIVA'), findsOneWidget);
    // Sem volta para o login
    expect(find.text('Voltar'), findsNothing);
  });

  group('Tela 8', () {
    Future<Falsos> abrir(WidgetTester tester, {String whatsapp = ''}) async {
      // Desmonta o app anterior: o State do app guarda as dependências do primeiro pump.
      await tester.pumpWidget(const SizedBox());
      final f = Falsos()..assinaturas.comAssinaturaAtiva();
      await tester.pumpWidget(appDeTeste(f, whatsapp: whatsapp));
      await tester.pumpAndSettle();
      abrirRota(tester, AppRoutes.minhaAssinatura);
      await tester.pumpAndSettle();
      return f;
    }

    testWidgets('pausar pelo switch, pular e cancelar com confirmação', (tester) async {
      final f = await abrir(tester);
      expect(find.text('Alterações e pulos até 28/11 às 23h59.'), findsOneWidget);

      await tocar(tester, find.byType(CupertinoSwitch));
      await tester.tap(find.text('Pausar a próxima entrega'));
      await tester.pumpAndSettle();
      expect(f.assinaturas.chamadas, ['pausar 1']);

      await tocar(tester, find.text('Pular a próxima entrega'));
      await tester.tap(find.text('Pular entrega'));
      await tester.pumpAndSettle();
      expect(f.assinaturas.chamadas.last, 'pular');

      await tocar(tester, find.text('Cancelar assinatura'));
      expect(find.text('Manter assinatura'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(CupertinoActionSheet),
          matching: find.text('Cancelar assinatura'),
        ),
      );
      await tester.pumpAndSettle();
      expect(f.assinaturas.chamadas.last, 'cancelar');
      expect(find.textContaining('fica a diferença de'), findsOneWidget);
      expect(find.textContaining('30,60'), findsOneWidget);
    });

    testWidgets('WhatsApp sem número configurado explica; com número abre wa.me', (tester) async {
      var f = await abrir(tester);
      await tocar(tester, find.text('Falar com o suporte no WhatsApp'));
      expect(
        find.text('O número de suporte ainda não foi configurado neste aplicativo.'),
        findsOneWidget,
      );
      expect(f.links.abertos, isEmpty);

      f = await abrir(tester, whatsapp: '5521999999999');
      await tocar(tester, find.text('Falar com o suporte no WhatsApp'));
      expect(f.links.abertos.single, startsWith('https://wa.me/5521999999999'));
    });

    testWidgets('alterar cesta abre a Tela 5 em modo alteração e mostra quando passa a valer', (
      tester,
    ) async {
      final f = await abrir(tester);
      await principal(tester);
      expect(find.text('Alterar cesta'), findsWidgets);
      await principal(tester); // Salvar cesta
      expect(f.assinaturas.chamadas, ['alterar']);
      expect(find.text('Cesta alterada. Vale a partir da entrega de 30/11.'), findsOneWidget);
    });

    testWidgets('sem assinatura: estado vazio com a voz do Anexo', (tester) async {
      final f = Falsos();
      await tester.pumpWidget(appDeTeste(f));
      await tester.pumpAndSettle();
      abrirRota(tester, AppRoutes.minhaAssinatura);
      await tester.pumpAndSettle();
      expect(
        find.text('Você ainda não tem assinatura. Que tal começar pelo quiz?'),
        findsOneWidget,
      );
    });
  });

  testWidgets('Tela 6: CEP fora da área oferece a lista de espera', (tester) async {
    final f = Falsos();
    await tester.pumpWidget(appDeTeste(f));
    await tester.pumpAndSettle();
    abrirRota(
      tester,
      AppRoutes.endereco,
      argumentos: const PedidoAssinatura(itens: [ItemCesta('WP500', 12)]),
    );
    await tester.pumpAndSettle();
    await escrever(tester, 0, '01310-100');
    await tocar(tester, find.text('Buscar CEP'));
    expect(find.text('Por enquanto entregamos só no município do Rio de Janeiro.'), findsOneWidget);
    await escrever(tester, 1, 'ana@exemplo.com');
    await tocar(tester, find.text('Avisar quando chegar'));
    expect(f.enderecos.listaDeEspera, ['ana@exemplo.com']);
  });

  testWidgets('Tela 5: cesta abaixo do mínimo mostra o erro da API e trava o avançar', (
    tester,
  ) async {
    final f = Falsos();
    await tester.pumpWidget(appDeTeste(f));
    await tester.pumpAndSettle();
    abrirRota(
      tester,
      AppRoutes.catalogo,
      argumentos: const PedidoAssinatura(itens: [ItemCesta('WP500', 6)]),
    );
    await tester.pumpAndSettle();
    const mensagem = 'A cesta precisa ter pelo menos 12 UE por entrega (sem contar o Guaraná).';
    await rolarAte(tester, find.text(mensagem));
    expect(find.text(mensagem), findsOneWidget);
    expect(tester.widget<BotaoPrincipal>(find.byType(BotaoPrincipal)).onPressed, isNull);
  });

  test('janela padrão é manhã', () {
    expect(const PedidoAssinatura(itens: []).janela, JanelaEntrega.manha);
  });
}
