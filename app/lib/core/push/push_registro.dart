import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../network/api_client.dart';

/// RF51: registra o token FCM em `PUT /notificacoes/push-token`.
/// Sem `google-services.json` / Firebase configurado, falha em silêncio e o app segue.
class PushRegistro {
  const PushRegistro();

  Future<void> registrarSePossivel(ApiClient? api) async {
    if (api == null) return;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      final token = await messaging.getToken();
      if (token == null || token.length < 10) return;
      await api.dio.put<void>('/notificacoes/push-token', data: {'token': token});
    } catch (e, s) {
      debugPrint('Push não configurado nesta build: $e\n$s');
    }
  }
}
