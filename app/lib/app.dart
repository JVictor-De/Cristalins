import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/config/app_config.dart';
import 'core/intents/abridor_links.dart';
import 'core/network/api_client.dart';
import 'core/routes.dart';
import 'core/theme/app_theme.dart';

/// Raiz do app: tema único, pt-BR, rotas nomeadas e dependências por `provider`.
class CristalinsApp extends StatelessWidget {
  const CristalinsApp({super.key, required this.config, this.abridorLinks = const AbridorLinks()});

  final AppConfig config;
  final AbridorLinks abridorLinks;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppConfig>.value(value: config),
        Provider<AbridorLinks>.value(value: abridorLinks),
        Provider<ApiClient>(create: (_) => ApiClient(config)),
      ],
      child: MaterialApp(
        title: 'Cristalins',
        debugShowCheckedModeBanner: config.ambiente != Ambiente.prod,
        theme: buildAppTheme(),
        scrollBehavior: const AppScrollBehavior(),
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        initialRoute: AppRoutes.boasVindas,
        onGenerateRoute: AppRoutes.gerar,
      ),
    );
  }
}
