import 'package:flutter/widgets.dart';

import '../../../core/formatacao.dart';
import '../../../core/theme/app_colors.dart';

/// Formas de pagamento aceitas pela API em `PUT /assinaturas/{id}/forma-pagamento`.
enum FormaPagamento {
  pix('PIX', 'Pix'),
  boleto('BOLETO', 'Boleto'),
  cartao('CARTAO', 'Cartão de crédito');

  const FormaPagamento(this.valor, this.rotulo);

  final String valor;
  final String rotulo;

  static FormaPagamento de(String valor) =>
      values.firstWhere((f) => f.valor == valor, orElse: () => FormaPagamento.pix);
}

/// Uma cobrança (fatura) de um ciclo, como `GET /faturas` devolve.
class Fatura {
  const Fatura({
    required this.id,
    required this.cicloNumero,
    required this.dataEntrega,
    required this.forma,
    required this.valor,
    required this.vencimento,
    required this.status,
    this.link,
    this.temComprovante = false,
    this.observacao,
  });

  final String id;
  final int cicloNumero;
  final String dataEntrega;
  final FormaPagamento forma;
  final Dinheiro valor;
  final String vencimento;
  final String status;

  /// Boleto ou fatura do Asaas (abre fora do app).
  final String? link;
  final bool temComprovante;

  /// Texto da API (ex.: "Cartão recusado.").
  final String? observacao;

  bool get emAberto => status == 'PENDENTE' || status == 'VENCIDO';
}

/// Cartão salvo: a API devolve só bandeira e 4 últimos dígitos (o token fica no servidor).
class CartaoSalvo {
  const CartaoSalvo({required this.id, required this.bandeira, required this.final4});

  final String id;
  final String bandeira;
  final String final4;

  String get rotulo => '${_bandeira(bandeira)} final $final4';

  static String _bandeira(String b) => switch (b) {
    'VISA' => 'Visa',
    'MASTERCARD' => 'Mastercard',
    'ELO' => 'Elo',
    'AMEX' => 'Amex',
    'HIPERCARD' => 'Hipercard',
    _ => 'Cartão',
  };
}

/// Forma atual da assinatura (vale para a próxima cobrança).
class FormaAtual {
  const FormaAtual({required this.forma, this.cartao});

  final FormaPagamento forma;

  /// Só bandeira e final (sem id): o que a API devolve.
  final CartaoSalvo? cartao;
}

/// Dados digitados do cartão. Só existem em memória até o envio; nunca são gravados no aparelho.
class DadosCartao {
  const DadosCartao({
    required this.nomeNoCartao,
    required this.numero,
    required this.mesValidade,
    required this.anoValidade,
    required this.cvv,
    required this.cep,
    required this.numeroEndereco,
    this.telefone,
  });

  final String nomeNoCartao;
  final String numero;
  final String mesValidade;
  final String anoValidade;
  final String cvv;
  final String cep;
  final String numeroEndereco;
  final String? telefone;

  Map<String, dynamic> paraJson() => {
    'nomeNoCartao': nomeNoCartao,
    'numero': numero,
    'mesValidade': mesValidade,
    'anoValidade': anoValidade,
    'cvv': cvv,
    'cep': cep,
    'numeroEndereco': numeroEndereco,
    if (telefone != null && telefone!.isNotEmpty) 'telefone': telefone,
  };

  /// Não expõe número nem CVV em logs.
  @override
  String toString() =>
      'DadosCartao(final ${numero.length >= 4 ? numero.substring(numero.length - 4) : '?'})';
}

/// Selo de status da fatura (mesmo padrão do selo da assinatura).
({String texto, Color fundo, Color cor}) seloDaFatura(String status) => switch (status) {
  'PAGO' => (texto: 'Paga', fundo: AppColors.azul100, cor: AppColors.azul900),
  'VENCIDO' => (texto: 'Vencida', fundo: AppColors.azul50, cor: AppColors.erro),
  'ESTORNADO' => (
    texto: 'Estornada',
    fundo: AppColors.fundoAgrupado,
    cor: AppColors.textoSecundario,
  ),
  'CANCELADO' => (
    texto: 'Cancelada',
    fundo: AppColors.fundoAgrupado,
    cor: AppColors.textoSecundario,
  ),
  _ => (texto: 'Em aberto', fundo: AppColors.azul50, cor: AppColors.alerta),
};
