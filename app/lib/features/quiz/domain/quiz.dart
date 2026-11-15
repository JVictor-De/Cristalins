import '../../../core/formatacao.dart';
import '../../catalog/domain/catalogo.dart';

/// Opção de resposta: rótulo para a tela e valor enviado à API.
class Opcao {
  const Opcao(this.valor, this.rotulo);
  final String valor;
  final String rotulo;
}

/// As 5 perguntas do quiz (Anexo). As regras de cálculo ficam na API.
abstract final class PerguntasQuiz {
  static const total = 5;

  static const objetivos = [
    Opcao('TREINO', 'Treino'),
    Opcao('EQUILIBRIO', 'Rotina equilibrada'),
    Opcao('CASA', 'Casa e família'),
    Opcao('ESCRITORIO', 'Escritório'),
  ];

  static const dias = [
    Opcao('1-2', '1 a 2 dias'),
    Opcao('3-4', '3 a 4 dias'),
    Opcao('5-7', '5 a 7 dias'),
  ];

  static const pessoas = [
    Opcao('1', '1 pessoa'),
    Opcao('2', '2 pessoas'),
    Opcao('3', '3 pessoas'),
    Opcao('4', '4 pessoas'),
    Opcao('5-10', '5 a 10 pessoas'),
    Opcao('11-20', '11 a 20 pessoas'),
  ];
}

class RespostasQuiz {
  const RespostasQuiz({
    this.objetivo,
    this.diasSemana,
    this.pessoas,
    this.flowFiber = false,
    this.comGas = false,
  });

  final String? objetivo;
  final String? diasSemana;
  final String? pessoas;
  final bool flowFiber;
  final bool comGas;

  RespostasQuiz copyWith({
    String? objetivo,
    String? diasSemana,
    String? pessoas,
    bool? flowFiber,
    bool? comGas,
  }) => RespostasQuiz(
    objetivo: objetivo ?? this.objetivo,
    diasSemana: diasSemana ?? this.diasSemana,
    pessoas: pessoas ?? this.pessoas,
    flowFiber: flowFiber ?? this.flowFiber,
    comGas: comGas ?? this.comGas,
  );
}

class Recomendacao {
  const Recomendacao({
    required this.id,
    required this.kit,
    required this.multiplicador,
    required this.frequencia,
    required this.itens,
    required this.ue,
    required this.valorEstimado,
    required this.perfilEmpresa,
    this.contatoEmail,
    this.contatoTelefone,
  });

  final String id;
  final String? kit;
  final int multiplicador;
  final String frequencia;
  final List<ItemCesta> itens;
  final num ue;
  final Dinheiro? valorEstimado;
  final bool perfilEmpresa;
  final String? contatoEmail;
  final String? contatoTelefone;

  String get nomeDoKit => switch (kit) {
    'KIT-TREINO' => 'Kit Treino',
    'KIT-EQUILIBRIO' => 'Kit Equilíbrio',
    'KIT-CASA' => 'Kit Casa',
    'KIT-ESCRITORIO' => 'Kit Escritório',
    _ => kit ?? 'Plano Empresa',
  };
}

/// Nomes de produto para o texto (a API manda o código).
String nomeDoProduto(String codigo) => switch (codigo) {
  'WP500' => 'Water Protein 500 ml',
  'FF500' => 'Flow Fiber 500 ml',
  'AMS500' => 'Água mineral sem gás 500 ml',
  'AMC510' => 'Água mineral com gás 510 ml',
  'AMN1500' => 'Água mineral 1,5 L',
  'AMN5000' => 'Água mineral 5 L',
  'AMC200' => 'Água no copo 200 ml',
  'GUA2000' => 'Guaraná Cristalins 2 L',
  _ => codigo,
};

String rotuloFrequencia(String f) => switch (f) {
  'SEMANAL' => 'Semanal',
  'QUINZENAL' => 'Quinzenal',
  'MENSAL' => 'Mensal',
  _ => f,
};
