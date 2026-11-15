import 'package:share_plus/share_plus.dart';

/// Intent implícita de compartilhar texto (share_plus). Atrás de uma classe para os testes.
class Compartilhador {
  const Compartilhador();

  Future<void> compartilhar(String texto, {String? assunto}) async {
    await SharePlus.instance.share(ShareParams(text: texto, subject: assunto));
  }
}
