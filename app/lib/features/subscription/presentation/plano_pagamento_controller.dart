import 'package:flutter/foundation.dart';

import '../../../core/network/api_erro.dart';
import '../../catalog/data/catalogo_repository.dart';
import '../../catalog/domain/catalogo.dart';
import '../data/assinatura_repository.dart';
import '../domain/assinatura.dart';

/// Tela 7. O resumo de preço vem linha a linha de `POST /precos/simular` (com o frete da zona).
class PlanoPagamentoController extends ChangeNotifier {
  PlanoPagamentoController(this._catalogo, this._assinaturas, PedidoAssinatura pedido)
    : _pedido = pedido {
    simular();
  }

  final CatalogoRepository _catalogo;
  final AssinaturaRepository _assinaturas;
  PedidoAssinatura _pedido;

  PedidoAssinatura get pedido => _pedido;
  String plano = 'FLEX';
  String cupom = '';

  bool simulando = true;
  Simulacao? simulacao;
  String? erro;
  bool assinando = false;
  int _versao = 0;

  void escolherFrequencia(String f) {
    _pedido = _pedido.copyWith(frequencia: f);
    simular();
  }

  void escolherPlano(String p) {
    plano = p;
    simular();
  }

  void aplicarCupom(String c) {
    cupom = c.trim().toUpperCase();
    simular();
  }

  Future<void> simular() async {
    final versao = ++_versao;
    simulando = true;
    erro = null;
    notifyListeners();
    try {
      final s = await _catalogo.simular(
        itens: _pedido.itens,
        frequencia: _pedido.frequencia,
        plano: plano,
        enderecoId: _pedido.endereco?.id,
        cupom: cupom,
      );
      if (versao == _versao) simulacao = s;
    } on ApiErro catch (e) {
      if (versao == _versao) {
        simulacao = null;
        erro = e.mensagemParaUsuario;
      }
    } catch (e) {
      if (versao == _versao) {
        simulacao = null;
        erro = ApiErro.de(e).mensagemParaUsuario;
      }
    } finally {
      if (versao == _versao) {
        simulando = false;
        notifyListeners();
      }
    }
  }

  Future<AssinaturaCriada?> assinar() async {
    assinando = true;
    erro = null;
    notifyListeners();
    try {
      if (_pedido.endereco == null) {
        erro = 'Falta o endereço da entrega. Volte e salve um CEP atendido.';
        return null;
      }
      return await _assinaturas.criar(_pedido, plano: plano, cupom: cupom);
    } on ApiErro catch (e) {
      erro = e.mensagemParaUsuario;
      return null;
    } catch (e) {
      erro = ApiErro.de(e).mensagemParaUsuario;
      return null;
    } finally {
      assinando = false;
      notifyListeners();
    }
  }
}
