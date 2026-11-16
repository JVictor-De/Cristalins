import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_erro.dart';
import '../../subscription/domain/assinatura.dart';
import '../data/ocorrencia_repository.dart';
import '../domain/ocorrencia.dart';

/// Estado da tela de ocorrência (RN15): foto + tipo + item + reposição ou crédito.
class OcorrenciaController extends ChangeNotifier {
  OcorrenciaController(this._repo, this.ciclo);

  final OcorrenciaRepository _repo;
  final Ciclo ciclo;
  final ImagePicker _picker = ImagePicker();

  String tipo = 'AVARIA';
  String? produto;
  int quantidade = 1;
  String solucao = 'REPOSICAO';
  String? caminhoFoto;
  bool enviando = false;
  String? erro;

  int get maxQuantidade {
    for (final i in ciclo.itens) {
      if (i.produto == produto) return i.quantidade;
    }
    return 1;
  }

  Future<void> escolherFoto(ImageSource origem) async {
    erro = null;
    final x = await _picker.pickImage(source: origem, imageQuality: 85, maxWidth: 1600);
    if (x == null) return;
    caminhoFoto = x.path;
    notifyListeners();
  }

  void escolherTipo(String t) {
    tipo = t;
    notifyListeners();
  }

  void escolherProduto(String codigo) {
    produto = codigo;
    quantidade = 1;
    notifyListeners();
  }

  void escolherQuantidade(int q) {
    quantidade = q.clamp(1, maxQuantidade);
    notifyListeners();
  }

  void escolherSolucao(String s) {
    solucao = s;
    notifyListeners();
  }

  Future<OcorrenciaCriada?> enviar() async {
    if (caminhoFoto == null) {
      erro = 'Tire ou escolha uma foto do problema.';
      notifyListeners();
      return null;
    }
    if (produto == null) {
      erro = 'Escolha o produto avariado ou faltante.';
      notifyListeners();
      return null;
    }
    enviando = true;
    erro = null;
    notifyListeners();
    try {
      final r = await _repo.criar(
        cicloId: ciclo.id,
        tipo: tipo,
        produto: produto!,
        quantidade: quantidade,
        solucao: solucao,
        caminhoFoto: caminhoFoto!,
      );
      return r;
    } on ApiErro catch (e) {
      erro = e.mensagem;
      return null;
    } finally {
      enviando = false;
      notifyListeners();
    }
  }
}
