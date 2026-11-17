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
  Uint8List? bytesFoto;
  String nomeArquivo = 'foto.jpg';
  bool enviando = false;
  String? erro;

  bool get temFoto => bytesFoto != null;

  int get maxQuantidade {
    for (final i in ciclo.itens) {
      if (i.produto == produto) return i.quantidade;
    }
    return 1;
  }

  Future<void> escolherFoto(ImageSource origem) async {
    erro = null;
    notifyListeners();
    try {
      // Safari iOS: galeria via input file; câmera nativa costuma falhar na web.
      final x = await _picker.pickImage(source: origem, imageQuality: 85, maxWidth: 1600);
      if (x == null) return;
      bytesFoto = await x.readAsBytes();
      nomeArquivo = x.name.trim().isNotEmpty ? x.name : 'foto.jpg';
    } catch (_) {
      erro = kIsWeb
          ? 'Não conseguimos abrir a foto neste navegador. Tente de novo ou use outro arquivo.'
          : 'Não conseguimos abrir a câmera ou a galeria. Confira a permissão e tente de novo.';
    }
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
    if (bytesFoto == null) {
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
        bytesFoto: bytesFoto!,
        nomeArquivo: nomeArquivo,
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
