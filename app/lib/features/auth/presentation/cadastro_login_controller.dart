import 'package:flutter/foundation.dart';

import '../../../core/network/api_erro.dart';
import '../../subscription/data/assinatura_repository.dart';
import '../data/auth_repository.dart';

enum ModoAcesso { cadastro, login }

/// Depois de entrar: assinante → Tela 8; checkout → volta origem; demais → quiz.
enum DestinoAposAcesso { quiz, minhaAssinatura, checkout }

class CadastroLoginController extends ChangeNotifier {
  CadastroLoginController(this._auth, this._assinaturas);

  final AuthRepository _auth;
  final AssinaturaRepository _assinaturas;

  ModoAcesso modo = ModoAcesso.cadastro;
  bool aceiteTermos = false;
  bool marketingOk = false;
  bool enviando = false;
  String? erro;
  bool mostrarErroTermos = false;
  bool emailDuplicado = false;

  void trocarModo(ModoAcesso novo) {
    modo = novo;
    erro = null;
    mostrarErroTermos = false;
    emailDuplicado = false;
    notifyListeners();
  }

  void alternarTermos() {
    aceiteTermos = !aceiteTermos;
    mostrarErroTermos = false;
    notifyListeners();
  }

  void alternarMarketing() {
    marketingOk = !marketingOk;
    notifyListeners();
  }

  Future<DestinoAposAcesso?> cadastrar(DadosCadastro dados, {bool origemCheckout = false}) async {
    if (!aceiteTermos) {
      mostrarErroTermos = true;
      notifyListeners();
      return null;
    }
    return _executar(() async {
      await _auth.cadastrar(dados);
      return origemCheckout ? DestinoAposAcesso.checkout : DestinoAposAcesso.quiz;
    });
  }

  Future<DestinoAposAcesso?> entrar(
    String email,
    String senha, {
    bool origemCheckout = false,
  }) =>
      _executar(() async {
        await _auth.entrar(email, senha);
        final assinaturas = await _assinaturas.listar();
        if (assinaturas.any((a) => !a.cancelada)) {
          return DestinoAposAcesso.minhaAssinatura;
        }
        return origemCheckout ? DestinoAposAcesso.checkout : DestinoAposAcesso.quiz;
      });

  Future<DestinoAposAcesso?> _executar(Future<DestinoAposAcesso> Function() acao) async {
    if (enviando) return null;
    enviando = true;
    erro = null;
    emailDuplicado = false;
    notifyListeners();
    try {
      return await acao();
    } on ApiErro catch (e) {
      erro = e.mensagem;
      emailDuplicado = e.campo == 'email' ||
          e.codigo == 'CONFLITO' ||
          (e.mensagem.toLowerCase().contains('e-mail') &&
              e.mensagem.toLowerCase().contains('cadastr'));
      return null;
    } finally {
      enviando = false;
      notifyListeners();
    }
  }
}
