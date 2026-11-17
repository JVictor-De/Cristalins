import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/config/app_config.dart';
import 'core/dependencias.dart';
import 'core/intents/abridor_links.dart';
import 'core/routes.dart';
import 'core/theme/app_theme.dart';
import 'features/catalog/presentation/sacola_controller.dart';

/// Raiz do app: tema único, pt-BR, rotas nomeadas e dependências por `provider`.
class CristalinsApp extends StatefulWidget {
  const CristalinsApp({
    super.key,
    required this.config,
    this.abridorLinks,
    this.dependencias,
    this.exibirSplash = true,
    this.rotaInicial,
  });

  final AppConfig config;

  /// Atalho dos testes da Tela 1 (sem repositórios).
  final AbridorLinks? abridorLinks;

  /// Repositórios e Intents; nulo = implementação real com a API do [config].
  final Dependencias? dependencias;

  /// Splash na abertura. `false` nos testes que não precisam do loop da splash
  /// (`pumpAndSettle` não termina com o `AnimationController.repeat` dela).
  final bool exibirSplash;

  /// Sobrescreve a rota inicial (ex.: testes usam [AppRoutes.onboarding] / [AppRoutes.boasVindas]).
  /// Se nulo: splash ou shell conforme [exibirSplash].
  final String? rotaInicial;

  @override
  State<CristalinsApp> createState() => _CristalinsAppState();
}

class _CristalinsAppState extends State<CristalinsApp> {
  final _navegador = GlobalKey<NavigatorState>();
  late final Dependencias _dep =
      widget.dependencias ?? Dependencias.reais(widget.config, links: widget.abridorLinks);

  @override
  void initState() {
    super.initState();
    // Sessão expirada (refresh falhou): volta ao login (cr-2: interceptor do dio).
    _dep.api?.aoExpirarSessao = () {
      _navegador.currentState?.pushNamedAndRemoveUntil(AppRoutes.cadastroLogin, (r) => r.isFirst);
    };
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppConfig>.value(value: widget.config),
        Provider<Dependencias>.value(value: _dep),
        Provider<AbridorLinks>.value(value: _dep.links),
        ChangeNotifierProvider(
          create: (_) => SacolaController(_dep.catalogo),
        ),
      ],
      child: MaterialApp(
        title: 'Cristalins',
        navigatorKey: _navegador,
        debugShowCheckedModeBanner: widget.config.ambiente != Ambiente.prod,
        theme: buildAppTheme(),
        scrollBehavior: const AppScrollBehavior(),
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        // Sem `onGenerateInitialRoutes`, `initialRoute: '/boas-vindas'` também monta `/`
        // (splash com timer/loop) e `pumpAndSettle` nunca termina.
        initialRoute: widget.rotaInicial ??
            (widget.exibirSplash ? AppRoutes.splash : AppRoutes.shell),
        onGenerateInitialRoutes: widget.rotaInicial == null
            ? null
            : (_) {
                final settings = RouteSettings(name: widget.rotaInicial);
                final rota = AppRoutes.gerar(settings);
                return [
                  rota ??
                      MaterialPageRoute<void>(
                        settings: settings,
                        builder: (_) => const SizedBox.shrink(),
                      ),
                ];
              },
        onGenerateRoute: AppRoutes.gerar,
      ),
    );
  }
}
