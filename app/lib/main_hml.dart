import 'bootstrap.dart';
import 'core/config/app_config.dart';

/// Entrada do flavor `hml`: flutter run --flavor hml -t lib/main_hml.dart
void main() => iniciarApp(AppConfig.doAmbiente(Ambiente.hml));
