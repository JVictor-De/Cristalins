import 'package:flutter/foundation.dart';

import '../../../core/network/api_erro.dart';
import '../data/assinatura_repository.dart';
import '../domain/assinatura.dart';

/// Tela 8. Pausar, pular, cancelar e corte são decididos pela API; a tela só mostra o resultado.
class MinhaAssinaturaController extends ChangeNotifier {
  MinhaAssinaturaController(this._repo, {this.assinaturaId}) {
    carregar();
  }

  final AssinaturaRepository _repo;
  String? assinaturaId;

  bool carregando = true;
  String? erro;
  Assinatura? assinatura;
  List<Ciclo> ciclos = [];
  bool executando = false;

  /// Próxima entrega em aberto (data vinda da API) e o corte dela.
  Ciclo? get proximoCiclo {
    final data = assinatura?.proximaEntrega;
    if (data == null) return null;
    return ciclos.where((c) => c.dataEntrega == data && !c.naoSeraEntregue).firstOrNull;
  }

  Future<void> carregar() async {
    carregando = true;
    erro = null;
    notifyListeners();
    try {
      final todas = await _repo.listar();
      assinatura =
          todas.where((a) => a.id == assinaturaId).firstOrNull ??
          todas.where((a) => !a.cancelada).firstOrNull ??
          todas.firstOrNull;
      assinaturaId = assinatura?.id;
      ciclos = assinatura == null ? [] : await _repo.ciclos(assinatura!.id);
    } on ApiErro catch (e) {
      erro = e.mensagem;
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  Future<String?> pausar(int quantidade) => _acao(() => _repo.pausar(assinaturaId!, quantidade));
  Future<String?> retomar() => _acao(() => _repo.retomar(assinaturaId!));
  Future<String?> pular() => _acao(() => _repo.pularEntrega(assinaturaId!));

  Future<(Cancelamento?, String?)> cancelar() async {
    Cancelamento? resultado;
    final erro = await _acao(() async => resultado = await _repo.cancelar(assinaturaId!));
    return (resultado, erro);
  }

  /// Executa a ação e recarrega. Devolve a mensagem de erro da API ou null.
  Future<String?> _acao(Future<void> Function() acao) async {
    executando = true;
    notifyListeners();
    try {
      await acao();
      await carregar();
      return null;
    } on ApiErro catch (e) {
      return e.mensagem;
    } finally {
      executando = false;
      notifyListeners();
    }
  }
}
