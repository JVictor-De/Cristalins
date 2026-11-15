import '../../../core/formatacao.dart';

/// Item da cesta: código do produto e quantidade (o preço vem sempre da API).
class ItemCesta {
  const ItemCesta(this.produto, this.quantidade);

  final String produto;
  final int quantidade;

  @override
  bool operator ==(Object other) =>
      other is ItemCesta && other.produto == produto && other.quantidade == quantidade;

  @override
  int get hashCode => Object.hash(produto, quantidade);
}

class Produto {
  const Produto({
    required this.codigo,
    required this.nome,
    required this.tipo,
    required this.volumeMl,
    required this.embalagemQtd,
    required this.precoBase,
  });

  final String codigo;
  final String nome;

  /// PRINCIPAL, COMPLEMENTO, B2B ou ADDON (vem da API).
  final String tipo;
  final int volumeMl;
  final int embalagemQtd;
  final Dinheiro precoBase;

  /// Volume legível: 500 ml, 1,5 L.
  String get volume {
    if (volumeMl < 1000) return '$volumeMl ml';
    final litros = volumeMl / 1000;
    return '${litros == litros.roundToDouble() ? litros.toStringAsFixed(0) : litros.toStringAsFixed(1).replaceAll('.', ',')} L';
  }

  String get embalagem => embalagemQtd == 1 ? 'Unidade' : '$embalagemQtd por embalagem';

  String get rotuloTipo => switch (tipo) {
    'PRINCIPAL' => codigo == 'FF500' ? 'Flow Fiber' : 'Water Protein',
    'ADDON' => 'Para acompanhar',
    'B2B' => 'Água no copo',
    _ => 'Água mineral',
  };
}

class Kit {
  const Kit({
    required this.codigo,
    required this.nome,
    required this.itens,
    required this.subtotalBase,
  });

  final String codigo;
  final String nome;
  final List<ItemCesta> itens;
  final Dinheiro subtotalBase;
}

/// Categorias do controle segmentado da Tela 5.
enum Categoria {
  todos('Todos'),
  aguas('Águas'),
  waterProtein('Water Protein'),
  flowFiber('Flow Fiber');

  const Categoria(this.rotulo);
  final String rotulo;

  bool inclui(Produto p) => switch (this) {
    Categoria.todos => true,
    Categoria.aguas => p.tipo == 'COMPLEMENTO' || p.tipo == 'B2B',
    Categoria.waterProtein => p.codigo == 'WP500',
    Categoria.flowFiber => p.codigo == 'FF500',
  };
}

/// Linha do detalhe de preço vinda da API (`detalhePreco`).
class LinhaPreco {
  const LinhaPreco({required this.fator, this.percentual, this.valor});

  final String fator;
  final num? percentual;
  final Dinheiro? valor;

  String get rotulo => switch (fator) {
    'VOLUME' => 'Desconto por volume',
    'COMPROMISSO' => 'Desconto do plano',
    'FIDELIDADE' => 'Desconto de fidelidade',
    'DEMANDA' => 'Ajuste de demanda',
    'CUPOM' => 'Cupom',
    'FRETE' => 'Entrega',
    _ => fator,
  };

  String get valorFormatado {
    if (valor != null) return valor!.centavos == 0 ? 'Grátis' : valor!.formatado;
    final p = percentual ?? 0;
    final texto = p.abs() == p.abs().roundToDouble()
        ? p.abs().toStringAsFixed(0)
        : p.abs().toString().replaceAll('.', ',');
    return '${p < 0 ? '−' : '+'}$texto%';
  }
}

class ItemSimulado {
  const ItemSimulado({
    required this.produto,
    required this.quantidade,
    required this.precoUnitario,
  });

  final String produto;
  final int quantidade;
  final Dinheiro precoUnitario;
}

/// Resultado de `POST /precos/simular` (tudo calculado pela API).
class Simulacao {
  const Simulacao({
    required this.itens,
    required this.ue,
    required this.subtotal,
    required this.frete,
    required this.total,
    required this.detalhe,
    this.zona,
  });

  final List<ItemSimulado> itens;
  final num ue;
  final Dinheiro subtotal;
  final Dinheiro frete;
  final Dinheiro total;
  final List<LinhaPreco> detalhe;
  final String? zona;
}
