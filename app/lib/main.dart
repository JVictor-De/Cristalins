import 'package:flutter/services.dart';

import 'bootstrap.dart';
import 'core/config/app_config.dart';

/// Entrada padrão (`flutter run --flavor dev`): escolhe o ambiente pelo flavor do build.
void main() => iniciarApp(AppConfig.doFlavor(appFlavor));
