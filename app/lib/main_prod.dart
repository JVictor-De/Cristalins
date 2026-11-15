import 'bootstrap.dart';
import 'core/config/app_config.dart';

/// Entrada do flavor `prod`: flutter run --flavor prod -t lib/main_prod.dart
void main() => iniciarApp(AppConfig.doAmbiente(Ambiente.prod));
