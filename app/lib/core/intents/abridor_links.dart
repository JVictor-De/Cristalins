import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Intents implícitas de abrir link (site, `geo:`, `https://wa.me/`) via url_launcher.
/// Fica atrás de uma classe para os testes substituírem.
class AbridorLinks {
  const AbridorLinks();

  /// Abre [url] fora do app. Devolve `false` se nenhum app puder abrir.
  ///
  /// Em Flutter Web, `geo:` não abre no Safari — converte para Apple Maps HTTPS.
  Future<bool> abrir(String url) async {
    try {
      final uri = uriParaAbrir(url);
      // Na web, externalApplication falha com frequência; platformDefault + nova aba
      // funciona no Safari iOS (boleto, WhatsApp, termos, mapas).
      if (kIsWeb) {
        return await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
          webOnlyWindowName: '_blank',
        );
      }
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      // Fallback: Safari/iOS às vezes nega canLaunchUrl para https/wa.me.
      return await launchUrl(uri, mode: LaunchMode.platformDefault);
    } on Exception {
      return false;
    }
  }

  /// Normaliza a URL antes de abrir. Em web, `geo:` vira Apple Maps HTTPS.
  @visibleForTesting
  static Uri uriParaAbrir(String url, {bool? forcarWeb}) {
    final uri = Uri.parse(url);
    final web = forcarWeb ?? kIsWeb;
    if (!web || uri.scheme != 'geo') return uri;
    final q = uri.queryParameters['q'];
    if (q != null && q.isNotEmpty) {
      return Uri.https('maps.apple.com', '/', {'q': q});
    }
    final raw = uri.path;
    if (raw.isNotEmpty) {
      return Uri.https('maps.apple.com', '/', {'ll': raw});
    }
    return Uri.https('maps.apple.com', '/');
  }
}
