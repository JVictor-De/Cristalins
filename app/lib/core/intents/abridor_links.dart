import 'package:url_launcher/url_launcher.dart';

/// Intents implícitas de abrir link (site, `geo:`, `https://wa.me/`) via url_launcher.
/// Fica atrás de uma classe para os testes substituírem.
class AbridorLinks {
  const AbridorLinks();

  /// Abre [url] fora do app. Devolve `false` se nenhum app puder abrir.
  Future<bool> abrir(String url) async {
    try {
      return await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } on Exception {
      return false;
    }
  }
}
