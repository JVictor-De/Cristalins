import '../../subscription/domain/assinatura.dart';

/// Argumentos da tela de ocorrência (entrega já feita, Tela 8).
class PedidoOcorrencia {
  const PedidoOcorrencia({required this.ciclo});

  final Ciclo ciclo;
}

class OcorrenciaCriada {
  const OcorrenciaCriada({
    required this.id,
    required this.tipo,
    required this.produto,
    required this.quantidade,
    required this.solucao,
    required this.status,
    required this.temFoto,
    this.credito,
  });

  final String id;
  final String tipo;
  final String produto;
  final int quantidade;
  final String solucao;
  final String status;
  final bool temFoto;
  final double? credito;
}
