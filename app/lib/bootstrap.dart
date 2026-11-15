import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'app.dart';
import 'core/config/app_config.dart';

/// Ponto comum das entradas por flavor.
void iniciarApp(AppConfig config) {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'pt_BR';
  runApp(CristalinsApp(config: config));
}
