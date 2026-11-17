import 'package:cristalins_assinatura/core/config/app_config.dart';
import 'package:cristalins_assinatura/core/dependencias.dart';
import 'package:cristalins_assinatura/core/theme/app_theme.dart';
import 'package:cristalins_assinatura/features/address/domain/cep_sessao.dart';
import 'package:cristalins_assinatura/features/auth/domain/perfil_cliente.dart';
import 'package:cristalins_assinatura/features/catalog/presentation/sacola_controller.dart';
import 'package:cristalins_assinatura/features/home/presentation/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../support/fakes.dart';

class _MockStorage extends Mock implements FlutterSecureStorage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  tearDown(() => CepDaSessao.valor = null);

  Future<Falsos> montar(WidgetTester tester, {PerfilCliente? perfil}) async {
    final f = Falsos()..auth.perfilAtual = perfil;
    final storage = _MockStorage();
    when(() => storage.read(key: any(named: 'key'))).thenAnswer((_) async => null);
    when(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
    final sacola = SacolaController(f.catalogo, storage: storage, atraso: Duration.zero)
      ..produtos = await f.catalogo.produtos()
      ..carregandoCatalogo = false;

    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(
            value: const AppConfig(ambiente: Ambiente.dev, apiUrl: '', suporteWhatsapp: ''),
          ),
          Provider<Dependencias>.value(value: f.dependencias),
          ChangeNotifierProvider<SacolaController>.value(value: sacola),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: HomeScreen(onAbrirProdutos: ({categoria}) {}, onAbrirAssinatura: () {}),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    return f;
  }

  Future<void> assentar(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('logado: “Olá, {primeiro nome}!” vindo de GET /clientes/me', (tester) async {
    await montar(
      tester,
      perfil: const PerfilCliente(nome: 'Ana Souza', email: 'ana@exemplo.com'),
    );
    expect(find.text('Olá, Ana!'), findsOneWidget);
    expect(find.text('Olá!'), findsNothing);
  });

  testWidgets('sem sessão (NAO_AUTENTICADO): mantém “Olá!”', (tester) async {
    await montar(tester);
    expect(find.text('Olá!'), findsOneWidget);
  });

  testWidgets('CEP fora da área na home oferece a lista de espera (POST /lista-espera)', (
    tester,
  ) async {
    final f = await montar(tester);

    await tester.tap(find.text('Alterar'));
    await assentar(tester);
    await tester.enterText(find.byType(TextField), '01310100');
    await tester.tap(find.text('Confirmar CEP'));
    await assentar(tester);

    expect(find.text('Por enquanto entregamos só no município do Rio de Janeiro.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('home-cep-lista-espera')));
    await assentar(tester);

    // CEP já conhecido: a folha pede só o e-mail.
    expect(find.text('Ainda não entregamos aí'), findsOneWidget);
    expect(find.textContaining('01310-100'), findsOneWidget);
    expect(find.byKey(const ValueKey('lista-espera-cep')), findsNothing);

    await tester.enterText(find.byKey(const ValueKey('lista-espera-email')), 'bia@exemplo.com');
    await tester.tap(find.byKey(const ValueKey('lista-espera-enviar')));
    await assentar(tester);

    expect(f.enderecos.listaDeEspera, ['bia@exemplo.com']);
    expect(f.enderecos.cepsListaDeEspera, ['01310100']);
    expect(find.text('Pronto! Avisamos por e-mail.'), findsOneWidget);
    // CEP fora da área não vira “CEP da sessão”.
    expect(CepDaSessao.valor, isNull);
  });

  testWidgets('CEP atendido vira CEP da sessão (pré-preenche o Avise-me)', (tester) async {
    await montar(tester);
    await tester.tap(find.text('Alterar'));
    await assentar(tester);
    await tester.enterText(find.byType(TextField), '22041001');
    await tester.tap(find.text('Confirmar CEP'));
    await assentar(tester);
    expect(CepDaSessao.valor, '22041001');
    expect(find.textContaining('Copacabana'), findsWidgets);
  });
}
