import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// Intent implícita de compartilhar texto (share_plus). Atrás de uma classe para os testes.
class Compartilhador {
  const Compartilhador();

  /// No Safari iOS o Share Sheet nativo às vezes falha; cai no clipboard.
  ///
  /// - `true`: compartilhou, copiou, ou o usuário fechou a folha (não é erro)
  /// - `false`: não foi possível compartilhar nem copiar
  Future<bool> compartilhar(String texto, {String? assunto}) async {
    try {
      final r = await SharePlus.instance.share(ShareParams(text: texto, subject: assunto));
      switch (r.status) {
        case ShareResultStatus.success:
        case ShareResultStatus.dismissed:
          return true;
        case ShareResultStatus.unavailable:
          break;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Compartilhador: share falhou ($e); tentando clipboard.');
    }
    try {
      await Clipboard.setData(ClipboardData(text: texto));
      return true;
    } catch (_) {
      return false;
    }
  }
}
