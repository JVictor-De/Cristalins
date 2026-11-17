import 'package:cristalins_assinatura/core/config/app_config.dart';
import 'package:cristalins_assinatura/core/formatacao.dart';
import 'package:cristalins_assinatura/core/routes.dart';
import 'package:cristalins_assinatura/core/theme/app_colors.dart';
import 'package:cristalins_assinatura/core/theme/app_theme.dart';
import 'package:cristalins_assinatura/core/widgets/botao_principal.dart';
import 'package:cristalins_assinatura/core/widgets/estado_vazio.dart';
import 'package:cristalins_assinatura/features/catalog/domain/catalogo.dart';
import 'package:cristalins_assinatura/features/catalog/presentation/produtos_screen.dart';
import 'package:cristalins_assinatura/features/catalog/presentation/sacola_controller.dart';
import 'package:cristalins_assinatura/features/catalog/presentation/sacola_screen.dart';
import 'package:cristalins_assinatura/features/home/presentation/home_screen.dart';
import 'package:cristalins_assinatura/features/shell/presentation/shell_screen.dart';
import 'package:cristalins_assinatura/features/subscription/domain/assinatura.dart';
import 'package:cristalins_assinatura/features/welcome/presentation/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../support/mocks.dart';

class _MockStorage extends Mock implements FlutterSecureStorage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const agua = Produto(
    codigo: 'AMS500',
    nome: 'Água mineral 500 ml',
    tipo: 'COMPLEMENTO',
    volumeMl: 500,
    embalagemQtd: 12,
    precoBase: Dinheiro(220),
  );

  const wp = Produto(
    codigo: 'WP500',
    nome: 'Water Protein',
    tipo: 'PRINCIPAL',
    volumeMl: 500,
    embalagemQtd: 6,
    precoBase: Dinheiro(990),
  );

  SacolaController controller({
    List<Produto> produtos = const [],
    List<Kit> kits = const [],
    String? erro,
  }) {
    final mocks = Mocks();
    when(() => mocks.catalogo.produtos()).thenAnswer((_) async => produtos);
    when(() => mocks.catalogo.kits()).thenAnswer((_) async => kits);
    final storage = _MockStorage();
    when(() => storage.read(key: any(named: 'key'))).thenAnswer((_) async => null);
    when(() => storage.write(key: any(named: 'key'), value: any(named: 'value'))).thenAnswer((_) async {});
    final s = SacolaController(mocks.catalogo, storage: storage, atraso: Duration.zero);
    s.produtos = List.of(produtos);
    s.kits = List.of(kits);
    s.carregandoCatalogo = false;
    s.erroCatalogo = erro;
    return s;
  }

  Widget enveloparProdutos(SacolaController sacola, {Categoria? categoria}) {
    return MaterialApp(
      theme: buildAppTheme(),
      home: ChangeNotifierProvider<SacolaController>.value(
        value: sacola,
        child: Scaffold(
          backgroundColor: AppColors.gelo,
          body: ProdutosScreen(categoriaInicial: categoria),
        ),
      ),
    );
  }

  testWidgets('catálogo vazio: empty sem BotaoPrincipal e sem busca', (tester) async {
    await tester.pumpWidget(enveloparProdutos(controller()));
    await tester.pump();

    expect(find.text('Catálogo indisponível'), findsOneWidget);
    expect(find.text('Nada neste filtro'), findsNothing);
    expect(find.text('Atualizar'), findsOneWidget);
    expect(find.text('Buscar produto'), findsNothing);
    expect(find.byType(EstadoVazio), findsOneWidget);
    expect(find.byType(BotaoPrincipal), findsNothing);
  });

  testWidgets('filtro sem hit mostra Nada neste filtro (≠ catálogo vazio)', (tester) async {
    await tester.pumpWidget(
      enveloparProdutos(controller(produtos: [agua]), categoria: Categoria.waterProtein),
    );
    await tester.pump();

    expect(find.text('Nada neste filtro'), findsOneWidget);
    expect(find.text('Catálogo indisponível'), findsNothing);
    expect(find.text('Limpar filtros'), findsOneWidget);
    expect(find.byType(BotaoPrincipal), findsNothing);
  });

  testWidgets('catálogo curto esconde busca e mostra Proteína e fibras', (tester) async {
    await tester.pumpWidget(enveloparProdutos(controller(produtos: [agua, wp])));
    await tester.pump();

    expect(find.text('Buscar produto'), findsNothing);
    expect(find.text('Proteína e fibras'), findsOneWidget);
    expect(find.text('Águas'), findsOneWidget);
    expect(find.text('Flow Fiber'), findsNothing); // chip individual oculto no curto
  });

  testWidgets('home vazia sem Ver todos', (tester) async {
    final mocks = Mocks();
    when(() => mocks.assinaturas.listar()).thenAnswer((_) async => <Assinatura>[]);
    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final sacola = controller();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: MultiProvider(
          providers: [
            Provider.value(
              value: const AppConfig(ambiente: Ambiente.dev, apiUrl: '', suporteWhatsapp: ''),
            ),
            Provider.value(value: mocks.dependencias),
            ChangeNotifierProvider<SacolaController>.value(value: sacola),
          ],
          child: Scaffold(
            body: HomeScreen(
              onAbrirProdutos: ({Categoria? categoria}) {},
              onAbrirAssinatura: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ver todos'), findsNothing);
    expect(find.text('Catálogo indisponível'), findsOneWidget);
    expect(find.text('Atualizar'), findsOneWidget);
  });

  testWidgets('onboarding tem no máximo 1 BotaoPrincipal filled', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: ChangeNotifierProvider<SacolaController>.value(
          value: controller(),
          child: const OnboardingScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(BotaoPrincipal), findsOneWidget);
    expect(find.text('Ver todos os produtos'), findsOneWidget);
  });

  testWidgets('onboarding P4: 1 CTA + secundário, sem kit', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: ChangeNotifierProvider<SacolaController>.value(
          value: controller(produtos: [agua, wp]),
          child: const OnboardingScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(BotaoPrincipal), findsOneWidget);
    expect(find.text('Montar minha assinatura'), findsOneWidget);
    expect(find.text('Ver todos os produtos'), findsOneWidget);
    expect(find.byType(OutlinedButton), findsNothing);
    expect(find.text('Descobrir meu kit'), findsNothing);
  });

  testWidgets('catálogo longo (>12) mostra busca e chips WP/Fiber', (tester) async {
    final muitos = List.generate(
      kLimiteCatalogoCurto + 1,
      (i) => Produto(
        codigo: 'SKU$i',
        nome: 'Item $i',
        tipo: 'COMPLEMENTO',
        volumeMl: 500,
        embalagemQtd: 12,
        precoBase: const Dinheiro(100),
      ),
    );
    await tester.pumpWidget(enveloparProdutos(controller(produtos: muitos)));
    await tester.pump();

    expect(find.text('Buscar produto'), findsOneWidget);
    expect(find.text('Water Protein'), findsOneWidget);
    expect(find.text('Flow Fiber'), findsOneWidget);
    expect(find.text('Proteína e fibras'), findsNothing);
  });

  testWidgets('home vazia esconde Ver todas as águas no hero', (tester) async {
    final mocks = Mocks();
    when(() => mocks.assinaturas.listar()).thenAnswer((_) async => <Assinatura>[]);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: MultiProvider(
          providers: [
            Provider.value(
              value: const AppConfig(ambiente: Ambiente.dev, apiUrl: '', suporteWhatsapp: ''),
            ),
            Provider.value(value: mocks.dependencias),
            ChangeNotifierProvider<SacolaController>.value(value: controller()),
          ],
          child: Scaffold(
            body: HomeScreen(
              onAbrirProdutos: ({Categoria? categoria}) {},
              onAbrirAssinatura: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Ver todas as águas'), findsNothing);
    expect(find.text('Assinar agora'), findsOneWidget);
  });

  testWidgets('sacola vazia sem WP: Assinar vai ao shell Produtos', (tester) async {
    Object? shellArgs;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: ChangeNotifierProvider<SacolaController>.value(
          value: controller(),
          child: const SacolaScreen(),
        ),
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.shell) {
            shellArgs = settings.arguments;
            return MaterialPageRoute(
              builder: (_) => const Scaffold(body: Text('shell')),
              settings: settings,
            );
          }
          return null;
        },
      ),
    );
    await tester.pump();

    expect(find.text('Ver todas as águas'), findsNothing);
    expect(find.text('Ver produtos'), findsOneWidget);
    await tester.tap(find.text('Assinar Water Protein'));
    await tester.pumpAndSettle();

    expect(find.text('shell'), findsOneWidget);
    expect(shellArgs, isA<ShellArgs>());
    expect((shellArgs! as ShellArgs).abaInicial, 1);
  });
}
