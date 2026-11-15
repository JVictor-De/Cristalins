import 'package:flutter/foundation.dart';

import '../../../core/network/api_erro.dart';
import '../data/endereco_repository.dart';
import '../domain/endereco.dart';

/// Tela 6. Valida o CEP na API (área do Rio e zona); o app só exibe.
class EnderecoController extends ChangeNotifier {
  EnderecoController(this._repo) {
    carregar();
  }

  final EnderecoRepository _repo;

  bool carregando = true;
  String? erroCarregar;
  List<Endereco> salvos = [];

  /// Endereço salvo escolhido; nulo = cadastrar um novo.
  Endereco? escolhido;
  JanelaEntrega janela = JanelaEntrega.manha;

  bool consultando = false;
  CepConsultado? cep;
  String? erroCep;

  /// CEP_FORA_AREA ou BAIRRO_NAO_ATENDIDO: oferece a lista de espera (CT23).
  bool foraDaArea = false;
  String? cepForaDaArea;

  bool salvando = false;
  bool listaEsperaEnviada = false;

  bool get novo => escolhido == null;

  Future<void> carregar() async {
    carregando = true;
    erroCarregar = null;
    notifyListeners();
    try {
      salvos = await _repo.listar();
      escolhido = salvos.where((e) => e.principal).firstOrNull ?? salvos.firstOrNull;
    } on ApiErro catch (e) {
      erroCarregar = e.mensagem;
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  void escolher(Endereco? e) {
    escolhido = e;
    notifyListeners();
  }

  void escolherJanela(JanelaEntrega j) {
    janela = j;
    notifyListeners();
  }

  Future<void> consultarCep(String digitos) async {
    consultando = true;
    erroCep = null;
    foraDaArea = false;
    cep = null;
    listaEsperaEnviada = false;
    notifyListeners();
    try {
      cep = await _repo.consultarCep(digitos);
    } on ApiErro catch (e) {
      erroCep = e.mensagem;
      foraDaArea = e.codigo == 'CEP_FORA_AREA' || e.codigo == 'BAIRRO_NAO_ATENDIDO';
      cepForaDaArea = digitos;
    } finally {
      consultando = false;
      notifyListeners();
    }
  }

  Future<Endereco?> salvar(NovoEndereco novo) async {
    salvando = true;
    erroCep = null;
    notifyListeners();
    try {
      final e = await _repo.criar(novo);
      salvos = [...salvos, e];
      escolhido = e;
      return e;
    } on ApiErro catch (e) {
      erroCep = e.mensagem;
      return null;
    } finally {
      salvando = false;
      notifyListeners();
    }
  }

  Future<String?> entrarNaListaDeEspera(String email) async {
    try {
      await _repo.entrarNaListaDeEspera(email: email, cep: cepForaDaArea ?? '', bairro: null);
      listaEsperaEnviada = true;
      notifyListeners();
      return null;
    } on ApiErro catch (e) {
      return e.mensagem;
    }
  }
}
