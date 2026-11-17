import 'package:flutter/foundation.dart';

import '../../../core/network/api_erro.dart';
import '../data/assinatura_repository.dart';
import '../domain/pagamento.dart';

/// Faturas, comprovantes e forma de pagamento. Status, régua e recusa vêm da API.
class FaturasController extends ChangeNotifier {
  FaturasController(this._repo, {required this.assinaturaId}) {
    carregar();
  }

  final AssinaturaRepository _repo;
  final String assinaturaId;

  bool carregando = true;
  String? erro;
  List<Fatura> faturas = [];
  List<CartaoSalvo> cartoes = [];
  FormaAtual? forma;
  bool executando = false;

  Future<void> carregar() async {
    carregando = true;
    erro = null;
    notifyListeners();
    try {
      faturas = await _repo.faturas();
      forma = await _repo.formaPagamento(assinaturaId);
      cartoes = await _repo.cartoes();
    } catch (e) {
      erro = _mensagem(e);
    }
    carregando = false;
    notifyListeners();
  }

  /// Troca a forma (vale para a próxima cobrança). Devolve a mensagem de erro, se houver.
  Future<String?> trocar(FormaPagamento nova, {String? cartaoId}) => _executar(
    () async => forma = await _repo.trocarForma(assinaturaId, nova, cartaoId: cartaoId),
  );

  /// Envia o cartão à API (tokenização no Asaas) e passa a usá-lo na assinatura.
  Future<String?> cadastrarEUsar(DadosCartao dados) => _executar(() async {
    final cartao = await _repo.cadastrarCartao(dados);
    cartoes = [...cartoes, cartao];
    forma = await _repo.trocarForma(assinaturaId, FormaPagamento.cartao, cartaoId: cartao.id);
  });

  Future<(String?, String?)> comprovante(Fatura f) async {
    try {
      return (await _repo.comprovante(f.id), null);
    } catch (e) {
      return (null, _mensagem(e));
    }
  }

  Future<String?> _executar(Future<void> Function() fn) async {
    executando = true;
    notifyListeners();
    String? falha;
    try {
      await fn();
    } catch (e) {
      falha = _mensagem(e);
    }
    executando = false;
    notifyListeners();
    return falha;
  }

  String _mensagem(Object e) => ApiErro.de(e).mensagemParaUsuario;
}
