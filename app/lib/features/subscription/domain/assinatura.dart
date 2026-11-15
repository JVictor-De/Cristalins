import 'package:flutter/painting.dart';

import '../../../core/formatacao.dart';
import '../../../core/theme/app_colors.dart';
import '../../address/domain/endereco.dart';
import '../../catalog/domain/catalogo.dart';

/// Dados que passam de tela em tela (equivale à Intent explícita): cesta → endereço → plano.
class PedidoAssinatura {
  const PedidoAssinatura({
    required this.itens,
    this.frequencia = 'QUINZENAL',
    this.recomendacaoId,
    this.endereco,
    this.janela = JanelaEntrega.manha,
  });

  final List<ItemCesta> itens;
  final String frequencia;
  final String? recomendacaoId;
  final Endereco? endereco;
  final JanelaEntrega janela;

  PedidoAssinatura copyWith({
    List<ItemCesta>? itens,
    String? frequencia,
    Endereco? endereco,
    JanelaEntrega? janela,
  }) => PedidoAssinatura(
    itens: itens ?? this.itens,
    frequencia: frequencia ?? this.frequencia,
    recomendacaoId: recomendacaoId,
    endereco: endereco ?? this.endereco,
    janela: janela ?? this.janela,
  );
}

/// Argumentos da Tela 5 em modo "alterar cesta" (vindo da Tela 8).
class AlteracaoDeCesta {
  const AlteracaoDeCesta({
    required this.assinaturaId,
    required this.itens,
    required this.frequencia,
    required this.plano,
  });

  final String assinaturaId;
  final List<ItemCesta> itens;
  final String frequencia;
  final String plano;
}

class Assinatura {
  const Assinatura({
    required this.id,
    required this.status,
    required this.plano,
    required this.frequencia,
    required this.janela,
    required this.itens,
    required this.bairro,
    required this.zona,
    this.proximaEntrega,
    this.fimCompromisso,
    this.cupom,
  });

  final String id;
  final String status;
  final String plano;
  final String frequencia;
  final String janela;
  final List<ItemCesta> itens;
  final String bairro;
  final String zona;
  final String? proximaEntrega;
  final String? fimCompromisso;
  final String? cupom;

  bool get ativa => status == 'ATIVA';
  bool get pausada => status == 'PAUSADA';
  bool get cancelada => status == 'CANCELADA';
  bool get aguardandoPagamento => status == 'AGUARDANDO_PAGAMENTO';

  String get rotuloPlano =>
      plano == 'TRIMESTRAL' ? 'Trimestral' : (plano == 'EMPRESA' ? 'Empresa' : 'Flex');
}

class Ciclo {
  const Ciclo({
    required this.id,
    required this.numero,
    required this.dataEntrega,
    required this.dataCorte,
    required this.status,
    required this.itens,
    this.valor,
    this.motivoPulo,
  });

  final String id;
  final int numero;
  final String dataEntrega;
  final String dataCorte;
  final String status;
  final List<ItemCesta> itens;
  final Dinheiro? valor;
  final String? motivoPulo;

  bool get naoSeraEntregue => status == 'PULADO' || status == 'CANCELADO';
}

/// Rótulo e cores do selo de status (Anexo: fundo claro, texto escuro da mesma cor).
({String texto, Color fundo, Color cor}) seloDoStatus(String status) => switch (status) {
  'ATIVA' => (texto: 'Ativa', fundo: AppColors.azul100, cor: AppColors.azul900),
  'PAUSADA' => (texto: 'Pausada', fundo: AppColors.fundoAgrupado, cor: AppColors.textoSecundario),
  'SUSPENSA' => (texto: 'Suspensa', fundo: AppColors.azul50, cor: AppColors.alerta),
  'CANCELADA' => (texto: 'Cancelada', fundo: AppColors.fundoAgrupado, cor: AppColors.erro),
  _ => (texto: 'Aguardando pagamento', fundo: AppColors.azul50, cor: AppColors.alerta),
};

String rotuloStatusCiclo(String status, String? motivo) => switch (status) {
  'AGENDADO' => 'Agendada',
  'COBRADO' => 'Cobrança gerada',
  'PAGO' => 'Paga',
  'SEPARADO' => 'Em separação',
  'EM_ROTA' => 'Saiu para entrega',
  'ENTREGUE' => 'Entregue',
  'FALHOU' => 'Não entregue',
  'PULADO' || 'CANCELADO' => switch (motivo) {
    'PAUSA' => 'Pausada',
    'PULO' => 'Pulada',
    _ => 'Cancelada',
  },
  _ => status,
};

/// Resultado do cancelamento (RN13: diferença calculada pela API).
class Cancelamento {
  const Cancelamento({required this.diferencaCompromisso});
  final Dinheiro diferencaCompromisso;
}

/// Resultado de `POST /assinaturas`.
class AssinaturaCriada {
  const AssinaturaCriada({
    required this.id,
    required this.valorPrimeiroCiclo,
    required this.dataEntrega,
  });
  final String id;
  final Dinheiro valorPrimeiroCiclo;
  final String dataEntrega;
}
