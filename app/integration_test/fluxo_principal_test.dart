// Fluxo principal contra a API LOCAL (cr-2-testes): quiz → resultado → cesta → endereço → plano.
//
// Como rodar (emulador Android ligado e API local no ar):
//   docker compose up -d postgres
//   cd api && npx prisma migrate deploy && npx prisma db seed && npm run start:dev
//   cd app && flutter test integration_test/fluxo_principal_test.dart \
//       --flavor dev --dart-define=API_URL=http://10.0.2.2:3000
//
// O teste cria um cliente novo a cada execução (e-mail e CPF de teste) e guarda os tokens só em
// memória. Nenhum token ou segredo de produção é usado. A API consulta o ViaCEP, então o
// computador precisa de internet.

import 'dart:math';

import 'package:cristalins_assinatura/app.dart';
import 'package:cristalins_assinatura/core/config/app_config.dart';
import 'package:cristalins_assinatura/core/dependencias.dart';
import 'package:cristalins_assinatura/core/network/sessao.dart';
import 'package:cristalins_assinatura/core/widgets/botao_principal.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show ScaffoldMessenger, ScaffoldMessengerState;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';

const _apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:3000');

/// CPF válido aleatório (dígitos verificadores), só para o cliente de teste.
String _cpfDeTeste() {
  final r = Random();
  final base = List.generate(9, (_) => r.nextInt(10));
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

/// Falha com instrução clara quando a API local não está no ar (ou está sem banco).
Future<void> _garantirApiNoAr() async {
  final url = '$_apiUrl${AppConfig.prefixoApi}/health';
  const comoSubir =
      'Suba a API local: `docker compose up -d postgres`, depois `cd api && npx prisma migrate deploy && '
      'npx prisma db seed && npm run start:dev`. No emulador Android use --dart-define=API_URL=http://10.0.2.2:3000.';
  try {
    final r = await Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ),
    ).get<Map<String, dynamic>>(url);
    if (r.data?['status'] != 'ok') {
      fail('A API respondeu em $url, mas não com status ok: ${r.data}. $comoSubir');
    }
  } on DioException catch (e) {
    if (e.response?.statusCode == 503) {
      fail(
        'A API está no ar em $url, mas o banco não responde (503 SERVICO_INDISPONIVEL). $comoSubir',
      );
    }
    fail('A API local não respondeu em $url (${e.type.name}: ${e.message}). $comoSubir');
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
    await _garantirApiNoAr();
  });

  /// Rede real: espera o widget aparecer (pumpAndSettle não espera HTTP).
  Future<void> esperar(
    WidgetTester tester,
    Finder alvo, {
    Duration limite = const Duration(seconds: 20),
  }) async {
    final fim = DateTime.now().add(limite);
    while (DateTime.now().isBefore(fim)) {
      await tester.pump(const Duration(milliseconds: 200));
      if (alvo.evaluate().isNotEmpty) return;
    }
    fail('Tempo esgotado esperando $alvo. Confira o log da API.');
  }

  Future<void> esperarBotaoHabilitado(WidgetTester tester) async {
    final fim = DateTime.now().add(const Duration(seconds: 20));
    while (DateTime.now().isBefore(fim)) {
      await tester.pump(const Duration(milliseconds: 200));
      final botao = find.byType(BotaoPrincipal);
      if (botao.evaluate().isNotEmpty && tester.widget<BotaoPrincipal>(botao).onPressed != null) {
        return;
      }
    }
    fail('O botão principal não habilitou: a API pode ter recusado a cesta ou o endereço.');
  }

  Future<void> principal(WidgetTester tester) async {
    await tester.tap(find.byType(BotaoPrincipal));
    await tester.pump();
  }

  Future<void> tocar(WidgetTester tester, Finder alvo) async {
    tester.state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger)).hideCurrentSnackBar();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(alvo, 120, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(alvo);
    await tester.pumpAndSettle();
    await tester.tap(alvo);
    await tester.pumpAndSettle();
  }

  Future<void> escrever(WidgetTester tester, int campo, String texto) async {
    final alvo = find.byType(CupertinoTextFormFieldRow).at(campo);
    await tester.ensureVisible(alvo);
    await tester.enterText(alvo, texto);
    await tester.pump();
  }

  Future<void> escolherNaFolha(WidgetTester tester, int passos) async {
    await tocar(tester, find.text('Escolher'));
    if (passos > 0) {
      await tester.drag(find.byType(CupertinoPicker), Offset(0, -40.0 * passos));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Concluir'));
    await tester.pumpAndSettle();
  }

  testWidgets('quiz → resultado → cesta → endereço → plano contra a API local', (tester) async {
    final config = const AppConfig(ambiente: Ambiente.dev, apiUrl: _apiUrl, suporteWhatsapp: '');
    final dependencias = Dependencias.reais(config, tokens: ArmazenamentoEmMemoria());
    await tester.pumpWidget(
      CristalinsApp(config: config, dependencias: dependencias, exibirSplash: false),
    );
    await tester.pumpAndSettle();

    // Tela 1 → Tela 2: cria um cliente novo (POST /clientes)
    await principal(tester);
    await tester.pumpAndSettle();
    final carimbo = DateTime.now().millisecondsSinceEpoch;
    await escrever(tester, 0, 'Cliente Teste Integração');
    await escrever(tester, 1, _cpfDeTeste());
    await escrever(tester, 2, '10/05/1995');
    await escrever(tester, 4, 'teste.$carimbo@cristalins.local');
    await escrever(tester, 5, 'senha-de-teste-123');
    await tocar(tester, find.text('Li e aceito os termos de uso e a política de privacidade'));
    await principal(tester);

    // Tela 3: caso A (Treino, 5 a 7 dias, 1 pessoa, sem Flow Fiber, sem gás)
    await esperar(tester, find.text('Pergunta 1 de 5'));
    await tocar(tester, find.text('Treino'));
    await principal(tester);
    await tester.pumpAndSettle();
    await escolherNaFolha(tester, 2); // 5 a 7 dias
    await principal(tester);
    await tester.pumpAndSettle();
    await escolherNaFolha(tester, 0); // 1 pessoa
    await principal(tester);
    await tester.pumpAndSettle();
    await principal(tester); // Flow Fiber: não
    await tester.pumpAndSettle();
    await principal(tester); // Gás: não → POST /recomendacoes

    // Tela 4: GET /recomendacoes/{id}
    await esperar(tester, find.text('Kit Treino'));
    expect(find.text('Preço estimado por entrega'), findsOneWidget);
    // 118,80 fora do verão; 124,74 de 01/12 a 31/03 (demanda +5% da data do cálculo)
    expect(
      find.textContaining('118,80').evaluate().isNotEmpty ||
          find.textContaining('124,74').evaluate().isNotEmpty,
      isTrue,
      reason: 'Preço do caso A diferente do Anexo',
    );
    await principal(tester);

    // Tela 5: GET /produtos, GET /kits, POST /precos/simular
    await esperar(tester, find.text('Kits prontos'));
    await esperarBotaoHabilitado(tester);
    await principal(tester);

    // Tela 6: GET /cep/{cep} (ViaCEP pela API) e POST /enderecos
    await esperar(tester, find.text('Buscar CEP'));
    await escrever(tester, 0, '22041-001');
    await tocar(tester, find.text('Buscar CEP'));
    await esperar(tester, find.textContaining('Zona Sul'));
    await escrever(tester, 1, '100');
    await principal(tester);

    // Tela 7: resumo de POST /precos/simular com o frete da zona
    await esperar(tester, find.text('Resumo por entrega'));
    await esperar(tester, find.text('Total'));
    await esperarBotaoHabilitado(tester);
    expect(find.text('Assinar agora'), findsOneWidget);
    expect(find.text('Entrega'), findsWidgets);
  });
}
