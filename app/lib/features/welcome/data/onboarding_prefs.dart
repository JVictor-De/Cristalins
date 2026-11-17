import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Flag de 1ª abertura (onboarding v3). Em teste sem plugin, cai em memória.
abstract final class OnboardingPrefs {
  static const _chave = 'onboarding_visto';
  static const _storage = FlutterSecureStorage();

  /// Override só para testes (`true`/`false`); `null` = storage real.
  static bool? overrideVistoParaTeste;

  static bool? _memoria;

  static Future<bool> visto() async {
    if (overrideVistoParaTeste != null) return overrideVistoParaTeste!;
    if (_memoria != null) return _memoria!;
    try {
      final v = await _storage.read(key: _chave);
      return v == '1';
    } catch (_) {
      return false;
    }
  }

  static Future<void> marcarVisto() async {
    overrideVistoParaTeste = true;
    _memoria = true;
    // Persistência best-effort e não bloqueante (plugin pode pendurar em testes).
    unawaited(_persistirVisto());
  }

  static Future<void> _persistirVisto() async {
    try {
      await _storage.write(key: _chave, value: '1');
    } catch (_) {}
  }

  /// Limpa override entre testes.
  static void resetParaTeste() {
    overrideVistoParaTeste = null;
    _memoria = null;
  }
}
