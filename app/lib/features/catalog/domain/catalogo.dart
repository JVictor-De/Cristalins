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

/// Linha da tabela nutricional, como a API manda (texto pronto, sem conta no app).
class LinhaNutricional {
  const LinhaNutricional({required this.nutriente, required this.valor});

  final String nutriente;
  final String valor;
}

class TabelaNutricional {
  const TabelaNutricional({required this.porcao, required this.linhas});

  final String porcao;
  final List<LinhaNutricional> linhas;
}

class Produto {
  const Produto({
    required this.codigo,
    required this.nome,
    required this.tipo,
    required this.volumeMl,
    required this.embalagemQtd,
    required this.precoBase,
    this.descricao,
    this.estoque,
    this.precoAvulso,
    this.claims = const [],
    this.tabelaNutricional,
  });

  final String codigo;
  final String nome;

  /// PRINCIPAL, COMPLEMENTO, B2B ou ADDON (vem da API).
  final String tipo;
  final int volumeMl;
  final int embalagemQtd;
  final Dinheiro precoBase;

  /// Texto do catálogo (API); sem promessa de saúde.
  final String? descricao;

  /// Unidades em estoque; nulo = sem controle (sempre disponível).
  final int? estoque;

  /// Preço unitário fora da assinatura (API). Nulo = sem canal avulso.
  final Dinheiro? precoAvulso;

  /// Destaques do rótulo vindos da API (chips da PDP).
  final List<String> claims;

  final TabelaNutricional? tabelaNutricional;

  bool get esgotado => estoque == 0;

  /// Volume legível: 500 ml, 1,5 L.
  String get volume {
    if (volumeMl < 1000) return '$volumeMl ml';
    final litros = volumeMl / 1000;
    return '${litros == litros.roundToDouble() ? litros.toStringAsFixed(0) : litros.toStringAsFixed(1).replaceAll('.', ',')} L';
  }

  String get embalagem => embalagemQtd == 1 ? 'Unidade' : '$embalagemQtd por embalagem';

  /// Pack real do seed para cards/listas: `12 × 500 ml`; unitário (galão) = só `5 L`.
  String get pack => embalagemQtd <= 1 ? volume : '$embalagemQtd × $volume';

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

/// Ordem da grade Produtos (P1.4): Water Protein antes de Flow Fiber; demais SKUs
/// mantêm a ordem da API (a API ordena por tipo + código → FF500 antes de WP500).
List<Produto> ordenarGradeProdutos(Iterable<Produto> origem) {
  final lista = origem.toList();
  return [
    ...lista.where((p) => p.codigo == 'WP500'),
    ...lista.where((p) => p.codigo == 'FF500'),
    ...lista.where((p) => p.codigo != 'WP500' && p.codigo != 'FF500'),
  ];
}

/// Acima deste tamanho: busca + chips por linha (WP / Fiber / Águas / Kits).
const kLimiteCatalogoCurto = 12;

/// Chips da aba Produtos (marketplace v3).
enum Categoria {
  todos('Todos'),
  waterProtein('Water Protein'),
  flowFiber('Flow Fiber'),
  funcionais('Proteína e fibras'),
  aguas('Águas'),
  kits('Kits');

  const Categoria(this.rotulo);
  final String rotulo;

  bool inclui(Produto p) => switch (this) {
    Categoria.todos => true,
    Categoria.kits => false, // kits são outra lista
    Categoria.aguas => p.tipo == 'COMPLEMENTO' || p.tipo == 'B2B' || p.tipo == 'ADDON',
    Categoria.waterProtein => p.codigo == 'WP500',
    Categoria.flowFiber => p.codigo == 'FF500',
    Categoria.funcionais => p.codigo == 'WP500' || p.codigo == 'FF500',
  };

  /// Chips conforme tamanho do catálogo (vazio → nenhum; curto → consolidados).
  static List<Categoria> chipsPara({required int totalProdutos, required bool temKits}) {
    if (totalProdutos == 0) return const [];
    if (totalProdutos <= kLimiteCatalogoCurto) {
      return [Categoria.todos, Categoria.aguas, Categoria.funcionais, if (temKits) Categoria.kits];
    }
    return [
      Categoria.todos,
      Categoria.waterProtein,
      Categoria.flowFiber,
      Categoria.aguas,
      Categoria.kits,
    ];
  }
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

/// RN18: frete grátis acima de R$ 50 por entrega (= `FRETE_GRATIS_ACIMA` da API).
/// Só fallback de exibição antes da 1ª simulação; o valor vigente vem de [Simulacao].
const kFreteGratisAcimaPadrao = 50;

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
    this.ueMinima = 12,
    this.ueMaxima = 120,
    this.faltaUeParaMinimo = 0,
    this.freteGratisAcima = kFreteGratisAcimaPadrao,
    this.faltaParaFreteGratis = 0,
    this.economiaPlano = 0,
  });

  final List<ItemSimulado> itens;
  final num ue;
  final Dinheiro subtotal;
  final Dinheiro frete;
  final Dinheiro total;
  final List<LinhaPreco> detalhe;
  final String? zona;
  final num ueMinima;
  final num ueMaxima;
  final num faltaUeParaMinimo;
  final num freteGratisAcima;
  final num faltaParaFreteGratis;
  final num economiaPlano;

  bool get abaixoDoMinimo => faltaUeParaMinimo > 0;
}
