import '../../../core/formatacao.dart';

class ZonaEntrega {
  const ZonaEntrega({required this.id, required this.nome, required this.taxa, required this.dias});

  final String id;
  final String nome;
  final Dinheiro taxa;
  final List<String> dias;

  String get diasLegiveis {
    const nomes = {
      'DOM': 'dom',
      'SEG': 'seg',
      'TER': 'ter',
      'QUA': 'qua',
      'QUI': 'qui',
      'SEX': 'sex',
      'SAB': 'sáb',
    };
    final lista = dias.map((d) => nomes[d] ?? d).toList();
    if (lista.length <= 1) return lista.join();
    return '${lista.sublist(0, lista.length - 1).join(', ')} e ${lista.last}';
  }
}

class CepConsultado {
  const CepConsultado({
    required this.cep,
    required this.logradouro,
    required this.bairro,
    required this.zona,
  });

  final String cep;
  final String logradouro;
  final String bairro;
  final ZonaEntrega zona;
}

class Endereco {
  const Endereco({
    required this.id,
    required this.cep,
    required this.logradouro,
    required this.numero,
    required this.bairro,
    required this.zona,
    required this.principal,
    this.apelido,
    this.complemento,
  });

  final String id;
  final String cep;
  final String logradouro;
  final String numero;
  final String bairro;
  final ZonaEntrega zona;
  final bool principal;
  final String? apelido;
  final String? complemento;

  String get linha =>
      '$logradouro, $numero${complemento == null || complemento!.isEmpty ? '' : ' – $complemento'}';

  /// Texto para o mapa (Intent `geo:`).
  String get paraMapa => '$logradouro, $numero, $bairro, Rio de Janeiro - RJ';
}

/// Janela de entrega (Anexo: manhã 8h–12h ou tarde 13h–18h).
enum JanelaEntrega {
  manha('MANHA', 'Manhã, 8h–12h'),
  tarde('TARDE', 'Tarde, 13h–18h');

  const JanelaEntrega(this.valor, this.rotulo);
  final String valor;
  final String rotulo;

  static JanelaEntrega de(String v) => values.firstWhere((j) => j.valor == v, orElse: () => manha);
}
