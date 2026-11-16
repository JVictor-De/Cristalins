import 'catalogo.dart';

/// Filtros rápidos do carrossel Home (chips locais — não é [Categoria] da aba Produtos).
enum FiltroHomeCarrossel {
  todos('Todos'),
  semGas('Sem gás'),
  comGas('Com gás'),
  funcionais('Funcionais'),
  galao('Galão');

  const FiltroHomeCarrossel(this.rotulo);
  final String rotulo;

  bool inclui(Produto p) {
    final nome = p.nome.toLowerCase();
    return switch (this) {
      FiltroHomeCarrossel.todos => true,
      FiltroHomeCarrossel.semGas =>
        p.codigo == 'AMS500' ||
        p.codigo == 'AMN1500' ||
        p.codigo == 'AMN5000' ||
        nome.contains('sem gás'),
      FiltroHomeCarrossel.comGas =>
        p.codigo == 'AMC510' || p.codigo == 'AMC200' || nome.contains('com gás'),
      FiltroHomeCarrossel.funcionais => p.codigo == 'WP500' || p.codigo == 'FF500',
      FiltroHomeCarrossel.galao => p.codigo == 'AMN5000' || p.volumeMl >= 5000,
    };
  }
}

/// Ordenação Home: águas / Fiber / galão antes; WP por último (já no hero).
int pesoCarrosselHome(Produto p) => switch (p.codigo) {
  'AMS500' => 1,
  'AMC510' => 2,
  'AMN1500' => 3,
  'AMN5000' => 4,
  'AMC200' => 5,
  'FF500' => 6,
  'GUA2000' => 7,
  'WP500' => 90,
  _ => 50,
};

/// Lista do carrossel: filtro + ordem + garante `AMN5000` se existir no catálogo.
List<Produto> produtosCarrosselHome(
  List<Produto> origem, {
  FiltroHomeCarrossel filtro = FiltroHomeCarrossel.todos,
  int limite = 8,
}) {
  final filtrados = origem.where(filtro.inclui).toList()
    ..sort((a, b) => pesoCarrosselHome(a).compareTo(pesoCarrosselHome(b)));

  if (filtrados.isEmpty) return const [];

  var lista = filtrados.take(limite).toList();
  final galao = origem.where((p) => p.codigo == 'AMN5000').firstOrNull;
  if (filtro == FiltroHomeCarrossel.todos &&
      galao != null &&
      !lista.any((p) => p.codigo == 'AMN5000')) {
    // Empurra WP para fora se preciso, mantém galão visível.
    lista = [
      ...lista.where((p) => p.codigo != 'WP500').take(limite - 1),
      galao,
    ]..sort((a, b) => pesoCarrosselHome(a).compareTo(pesoCarrosselHome(b)));
  }
  return lista;
}
