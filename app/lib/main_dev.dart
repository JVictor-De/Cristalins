import 'bootstrap.dart';
import 'core/config/app_config.dart';

/// Entrada do flavor `dev`: flutter run --flavor dev -t lib/main_dev.dart
void main() => iniciarApp(AppConfig.doAmbiente(Ambiente.dev));
