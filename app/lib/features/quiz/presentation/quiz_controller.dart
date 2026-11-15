import 'package:flutter/foundation.dart';

import '../../../core/network/api_erro.dart';
import '../data/recomendacao_repository.dart';
import '../domain/quiz.dart';

/// Uma pergunta por vez (RF41). O cálculo da recomendação é da API.
class QuizController extends ChangeNotifier {
  QuizController(this._repo);

  final RecomendacaoRepository _repo;

  int etapa = 0;
  RespostasQuiz respostas = const RespostasQuiz();
  bool enviando = false;
  String? erro;

  bool get ultima => etapa == PerguntasQuiz.total - 1;

  /// RF: desabilitar o avançar enquanto faltar resposta.
  bool get podeAvancar => switch (etapa) {
    0 => respostas.objetivo != null,
    1 => respostas.diasSemana != null,
    2 => respostas.pessoas != null,
    _ => true,
  };

  void responder(RespostasQuiz novas) {
    respostas = novas;
    notifyListeners();
  }

  void avancar() {
    if (!podeAvancar || ultima) return;
    etapa++;
    notifyListeners();
  }

  /// `true` se voltou uma pergunta; `false` se já estava na primeira (a tela fecha).
  bool voltar() {
    if (etapa == 0) return false;
    etapa--;
    erro = null;
    notifyListeners();
    return true;
  }

  Future<Recomendacao?> enviar() async {
    enviando = true;
    erro = null;
    notifyListeners();
    try {
      return await _repo.recomendar(respostas);
    } on ApiErro catch (e) {
      erro = e.mensagem;
      return null;
    } finally {
      enviando = false;
      notifyListeners();
    }
  }
}
