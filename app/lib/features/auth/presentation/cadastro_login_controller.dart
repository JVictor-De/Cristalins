import 'package:flutter/foundation.dart';

import '../../../core/network/api_erro.dart';
import '../../subscription/data/assinatura_repository.dart';
import '../data/auth_repository.dart';

enum ModoAcesso { cadastro, login }

/// Depois de entrar: quem já tem assinatura vai para a Tela 8; os demais, para o quiz.
enum DestinoAposAcesso { quiz, minhaAssinatura }

class CadastroLoginController extends ChangeNotifier {
  CadastroLoginController(this._auth, this._assinaturas);

  final AuthRepository _auth;
  final AssinaturaRepository _assinaturas;

  ModoAcesso modo = ModoAcesso.cadastro;
  bool aceiteTermos = false;
  bool enviando = false;
  String? erro;
  bool mostrarErroTermos = false;

  void trocarModo(ModoAcesso novo) {
    modo = novo;
    erro = null;
    mostrarErroTermos = false;
    notifyListeners();
  }

  void alternarTermos() {
    aceiteTermos = !aceiteTermos;
    mostrarErroTermos = false;
    notifyListeners();
  }

  Future<DestinoAposAcesso?> cadastrar(DadosCadastro dados) async {
    if (!aceiteTermos) {
      mostrarErroTermos = true;
      notifyListeners();
      return null;
    }
    return _executar(() async {
      await _auth.cadastrar(dados);
      return DestinoAposAcesso.quiz;
    });
  }

  Future<DestinoAposAcesso?> entrar(String email, String senha) => _executar(() async {
    await _auth.entrar(email, senha);
    final assinaturas = await _assinaturas.listar();
    return assinaturas.any((a) => !a.cancelada)
        ? DestinoAposAcesso.minhaAssinatura
        : DestinoAposAcesso.quiz;
  });

  Future<DestinoAposAcesso?> _executar(Future<DestinoAposAcesso> Function() acao) async {
    enviando = true;
    erro = null;
    notifyListeners();
    try {
      return await acao();
    } on ApiErro catch (e) {
      erro = e.mensagem;
      return null;
    } finally {
      enviando = false;
      notifyListeners();
    }
  }
}
