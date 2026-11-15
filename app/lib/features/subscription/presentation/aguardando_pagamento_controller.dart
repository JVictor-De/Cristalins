import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/network/api_erro.dart';
import '../data/assinatura_repository.dart';
import '../domain/assinatura.dart';

enum EstadoPagamento { aguardando, confirmado, erro }

/// Consulta `GET /assinaturas/{id}` a cada [intervalo] até a API marcar `ATIVA`.
/// Quem confirma é a API (webhook do Asaas no sandbox; confirmação de demonstração no fake).
class AguardandoPagamentoController extends ChangeNotifier {
  AguardandoPagamentoController(
    this._repo,
    this.criada, {
    this.intervalo = const Duration(seconds: 5),
  }) {
    _agendar(imediato: true);
  }

  final AssinaturaRepository _repo;
  final AssinaturaCriada criada;
  final Duration intervalo;

  EstadoPagamento estado = EstadoPagamento.aguardando;
  bool consultando = false;
  String? erro;
  int consultas = 0;
  Timer? _timer;
  bool _descartado = false;

  /// "Tentar de novo" depois de um erro: volta a consultar.
  void tentarDeNovo() {
    estado = EstadoPagamento.aguardando;
    erro = null;
    notifyListeners();
    _agendar(imediato: true);
  }

  void _agendar({bool imediato = false}) {
    _timer?.cancel();
    _timer = Timer(imediato ? Duration.zero : intervalo, consultar);
  }

  Future<void> consultar() async {
    if (_descartado || estado == EstadoPagamento.confirmado) return;
    consultando = true;
    notifyListeners();
    try {
      final a = await _repo.buscar(criada.id);
      if (_descartado) return;
      consultas++;
      if (a.ativa) {
        estado = EstadoPagamento.confirmado;
      } else if (a.cancelada) {
        estado = EstadoPagamento.erro;
        erro = 'A assinatura foi cancelada porque o pagamento não foi confirmado a tempo.';
      } else {
        _agendar();
      }
    } on ApiErro catch (e) {
      if (_descartado) return;
      estado = EstadoPagamento.erro;
      erro = e.mensagem;
    } finally {
      if (!_descartado) {
        consultando = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _descartado = true;
    _timer?.cancel();
    super.dispose();
  }
}
