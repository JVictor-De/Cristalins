import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Dispara Intent explícita Activity→Activity no Android (MethodChannel).
/// Em outras plataformas / testes: só [Navigator] (mesmo contrato de rotas).
class NavegacaoNativa {
  const NavegacaoNativa();

  static const instancia = NavegacaoNativa();

  static const channelName = 'br.com.cristalins.assinatura/navegacao';

  static const boasVindas = 'BoasVindasActivity';
  static const cadastroLogin = 'CadastroLoginActivity';
  static const quiz = 'QuizActivity';
  static const resultado = 'ResultadoActivity';
  static const catalogo = 'CatalogoActivity';
  static const endereco = 'EnderecoActivity';
  static const planoPagamento = 'PlanoPagamentoActivity';
  static const minhaAssinatura = 'MinhaAssinaturaActivity';

  static const _channel = MethodChannel(channelName);

  static bool get _androidNativo =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Navega na rota Flutter e, no Android, abre a [activity] com Intent explícita.
  Future<void> abrir(
    BuildContext context, {
    required String activity,
    required String rota,
    Object? arguments,
    Map<String, String>? extras,
    bool finish = false,
    bool limparPilha = false,
  }) async {
    if (!context.mounted) return;

    if (limparPilha) {
      Navigator.of(context).pushNamedAndRemoveUntil(rota, (_) => false, arguments: arguments);
    } else if (finish) {
      Navigator.of(context).pushNamedAndRemoveUntil(rota, (r) => r.isFirst, arguments: arguments);
    } else {
      await Navigator.of(context).pushNamed(rota, arguments: arguments);
    }

    if (!_androidNativo) return;

    try {
      await _channel.invokeMethod<void>('abrirActivity', <String, Object?>{
        'activity': activity,
        'extras': extras ?? <String, String>{},
        'finish': finish || limparPilha,
      });
    } on MissingPluginException {
      // Widget/integration sem registrar channel — Navigator já cumpriu.
    } on PlatformException {
      // Intent falhou; UI Flutter já está na rota (engine compartilhado).
    }
  }
}
