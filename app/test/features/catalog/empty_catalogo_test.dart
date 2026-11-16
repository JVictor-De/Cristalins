import 'package:cristalins_assinatura/core/formatacao.dart';
import 'package:cristalins_assinatura/core/theme/app_colors.dart';
import 'package:cristalins_assinatura/core/theme/app_theme.dart';
import 'package:cristalins_assinatura/core/widgets/estado_vazio.dart';
import 'package:cristalins_assinatura/features/catalog/domain/catalogo.dart';
import 'package:cristalins_assinatura/features/catalog/presentation/produtos_screen.dart';
import 'package:cristalins_assinatura/features/catalog/presentation/sacola_controller.dart';
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

  SacolaController controller({
    List<Produto> produtos = const [],
    String? erro,
  }) {
    final mocks = Mocks();
    when(() => mocks.catalogo.produtos()).thenAnswer((_) async => produtos);
    when(() => mocks.catalogo.kits()).thenAnswer((_) async => <Kit>[]);
    final storage = _MockStorage();
    when(() => storage.read(key: any(named: 'key'))).thenAnswer((_) async => null);
    when(() => storage.write(key: any(named: 'key'), value: any(named: 'value'))).thenAnswer((_) async {});
    final s = SacolaController(mocks.catalogo, storage: storage, atraso: Duration.zero);
    s.produtos = List.of(produtos);
    s.kits = [];
    s.carregandoCatalogo = false;
    s.erroCatalogo = erro;
    return s;
  }

  Widget envelopar(SacolaController sacola, {Categoria? categoria}) {
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

  testWidgets('catálogo vazio mostra Catálogo indisponível (≠ filtro)', (tester) async {
    await tester.pumpWidget(envelopar(controller()));
    await tester.pump();

    expect(find.text('Catálogo indisponível'), findsOneWidget);
    expect(find.text('Nada neste filtro'), findsNothing);
    expect(find.text('Tentar de novo'), findsOneWidget);
    expect(find.byType(EstadoVazio), findsOneWidget);
  });

  testWidgets('filtro sem hit mostra Nada neste filtro (≠ catálogo vazio)', (tester) async {
    await tester.pumpWidget(
      envelopar(controller(produtos: [agua]), categoria: Categoria.waterProtein),
    );
    await tester.pump();

    expect(find.text('Nada neste filtro'), findsOneWidget);
    expect(find.text('Catálogo indisponível'), findsNothing);
    expect(find.text('Limpar filtros'), findsOneWidget);
  });
}
