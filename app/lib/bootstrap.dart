import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app.dart';
import 'core/config/app_config.dart';

/// Ponto comum das entradas por flavor.
Future<void> iniciarApp(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'pt_BR';
  await initializeDateFormatting('pt_BR');

  // RNF11: Sentry só se --dart-define=SENTRY_DSN=... (nunca no código).
  const dsn = String.fromEnvironment('SENTRY_DSN');
  if (dsn.isEmpty) {
    runApp(CristalinsApp(config: config));
    return;
  }
  await SentryFlutter.init(
    (options) {
      options.dsn = dsn;
      options.environment = config.ambiente.name;
    },
    appRunner: () => runApp(CristalinsApp(config: config)),
  );
}
