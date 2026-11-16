import 'package:cristalins_assinatura/core/network/api_erro.dart';
import 'package:cristalins_assinatura/core/theme/app_colors.dart';
import 'package:cristalins_assinatura/core/theme/app_theme.dart';
import 'package:cristalins_assinatura/core/widgets/empty_assinatura.dart';
import 'package:cristalins_assinatura/core/widgets/estado_vazio.dart';
import 'package:cristalins_assinatura/features/catalog/domain/catalogo.dart';
import 'package:cristalins_assinatura/features/subscription/domain/assinatura.dart';
import 'package:cristalins_assinatura/features/subscription/presentation/assinatura_tab_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../support/mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Mocks mocks;
  Categoria? categoriaRecebida;

  setUp(() {
    mocks = Mocks();
    categoriaRecebida = null;
  });

  Widget envelopar() {
    return MaterialApp(
      theme: buildAppTheme(),
      home: Provider.value(
        value: mocks.dependencias,
        child: Scaffold(
          backgroundColor: AppColors.gelo,
          body: AssinaturaTabScreen(
            onIrProdutos: ({Categoria? categoria}) {
              categoriaRecebida = categoria;
            },
          ),
        ),
      ),
    );
  }

  testWidgets('lista vazia → EmptyAssinatura (≠ erro)', (tester) async {
    when(() => mocks.assinaturas.listar()).thenAnswer((_) async => <Assinatura>[]);

    await tester.pumpWidget(envelopar());
    await tester.pump();
    await tester.pump();

    expect(find.byType(EmptyAssinatura), findsOneWidget);
    expect(find.text('Você ainda não tem assinatura'), findsOneWidget);
    expect(find.text('Falha ao carregar'), findsNothing);
  });

  testWidgets('NAO_AUTENTICADO → EmptyAssinatura (≠ Falha)', (tester) async {
    when(() => mocks.assinaturas.listar()).thenThrow(
      const ApiErro(codigo: 'NAO_AUTENTICADO', mensagem: 'Faça login', status: 401),
    );

    await tester.pumpWidget(envelopar());
    await tester.pump();
    await tester.pump();

    expect(find.byType(EmptyAssinatura), findsOneWidget);
    expect(find.text('Falha ao carregar'), findsNothing);
    expect(find.byType(EstadoVazio), findsNothing);
  });

  testWidgets('erro de rede → EstadoVazio com retry (≠ empty)', (tester) async {
    when(() => mocks.assinaturas.listar()).thenThrow(
      const ApiErro(codigo: 'SEM_CONEXAO', mensagem: ApiErro.semConexao),
    );

    await tester.pumpWidget(envelopar());
    await tester.pump();
    await tester.pump();

    expect(find.text('Falha ao carregar'), findsOneWidget);
    expect(find.text('Tentar de novo'), findsOneWidget);
    expect(find.byType(EmptyAssinatura), findsNothing);
  });

  testWidgets('Montar sacola ≠ Ver águas (categoria)', (tester) async {
    when(() => mocks.assinaturas.listar()).thenAnswer((_) async => <Assinatura>[]);

    await tester.pumpWidget(envelopar());
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Montar sacola'));
    await tester.pump();
    expect(categoriaRecebida, isNull);

    await tester.tap(find.text('Ver águas'));
    await tester.pump();
    expect(categoriaRecebida, Categoria.aguas);
  });
}
