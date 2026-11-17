import 'package:cristalins_assinatura/core/config/app_config.dart';
import 'package:cristalins_assinatura/core/dependencias.dart';
import 'package:cristalins_assinatura/core/theme/app_theme.dart';
import 'package:cristalins_assinatura/core/widgets/botao_principal.dart';
import 'package:cristalins_assinatura/features/profile/presentation/perfil_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LinksFalsos links;

  Dependencias dep() => Dependencias(
        auth: AuthFalso(),
        recomendacoes: RecomendacoesFalsas(),
        catalogo: CatalogoFalso(),
        enderecos: EnderecosFalsos(),
        assinaturas: AssinaturasFalsas(),
        ocorrencias: OcorrenciasFalsas(),
        api: null,
        links: links,
      );

  setUp(() => links = LinksFalsos());

  testWidgets('guest: sem Explorar; CTA Entrar ou criar conta; blocos; WhatsApp oculto', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(
            value: const AppConfig(ambiente: Ambiente.dev, apiUrl: '', suporteWhatsapp: ''),
          ),
          Provider.value(value: dep()),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const Scaffold(body: PerfilScreen()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Explorar sem entrar'), findsNothing);
    expect(find.widgetWithText(BotaoPrincipal, 'Entrar ou criar conta'), findsOneWidget);
    expect(find.text('Com e-mail e senha'), findsOneWidget);
    expect(find.text('Suporte'), findsOneWidget);
    expect(find.text('Sobre'), findsOneWidget);
    expect(find.text('Ajuda e perguntas frequentes'), findsOneWidget);
    expect(find.text('Área de entrega'), findsOneWidget);
    expect(find.text('Site Cristalins'), findsOneWidget);
    expect(find.textContaining('Versão'), findsOneWidget);
    expect(find.text('Termos de uso'), findsOneWidget);
    expect(find.text('Política de privacidade'), findsOneWidget);
    expect(find.text('Em breve'), findsNothing);
    expect(find.text('Fale conosco no WhatsApp'), findsNothing);
    expect(find.text('Excluir conta'), findsNothing);
  });

  testWidgets('guest: WhatsApp aparece e sanitiza número formatado ao abrir', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(
            value: const AppConfig(
              ambiente: Ambiente.dev,
              apiUrl: '',
              suporteWhatsapp: '+55 (21) 99999-9999',
            ),
          ),
          Provider.value(value: dep()),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const Scaffold(body: PerfilScreen()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Fale conosco no WhatsApp'), findsOneWidget);
    await tester.ensureVisible(find.text('Fale conosco no WhatsApp'));
    await tester.tap(find.text('Fale conosco no WhatsApp'));
    await tester.pumpAndSettle();
    expect(links.abertos, ['https://wa.me/5521999999999']);
  });

  testWidgets('guest: toque em Termos e Privacidade abre as URLs default', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(
            value: const AppConfig(ambiente: Ambiente.dev, apiUrl: '', suporteWhatsapp: ''),
          ),
          Provider.value(value: dep()),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const Scaffold(body: PerfilScreen()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.ensureVisible(find.text('Termos de uso'));
    await tester.tap(find.text('Termos de uso'));
    await tester.pump();

    await tester.ensureVisible(find.text('Política de privacidade'));
    await tester.tap(find.text('Política de privacidade'));
    await tester.pump();

    expect(links.abertos, [
      AppConfig.urlTermos,
      AppConfig.urlPrivacidade,
    ]);
  });
}
