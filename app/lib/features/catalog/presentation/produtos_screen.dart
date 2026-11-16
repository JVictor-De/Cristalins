import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/card_kit.dart';
import '../../../core/widgets/card_produto.dart';
import '../../../core/widgets/chip_categoria.dart';
import '../../../core/widgets/estado_vazio.dart';
import '../../../core/widgets/estados.dart';
import '../../../core/widgets/skeleton_card.dart';
import '../domain/catalogo.dart';
import 'sacola_controller.dart';

/// Aba Produtos — grade 2 colunas, sem preço.
class ProdutosScreen extends StatefulWidget {
  const ProdutosScreen({super.key, this.categoriaInicial});

  final Categoria? categoriaInicial;

  @override
  State<ProdutosScreen> createState() => _ProdutosScreenState();
}

class _ProdutosScreenState extends State<ProdutosScreen> {
  late Categoria _categoria = widget.categoriaInicial ?? Categoria.todos;
  final _busca = TextEditingController();
  String _filtro = '';

  @override
  void didUpdateWidget(covariant ProdutosScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.categoriaInicial != oldWidget.categoriaInicial && widget.categoriaInicial != null) {
      _categoria = widget.categoriaInicial!;
    }
  }

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  bool _filtroAtivo(Categoria ativa) => _filtro.isNotEmpty || ativa != Categoria.todos;

  @override
  Widget build(BuildContext context) {
    final sacola = context.watch<SacolaController>();

    if (sacola.erroCatalogo != null) {
      return SafeArea(
        child: EstadoErro(mensagem: sacola.erroCatalogo!, onTentarDeNovo: sacola.carregarCatalogo),
      );
    }

    final total = sacola.produtos.length;
    final catalogoVazio = !sacola.carregandoCatalogo && total == 0;
    final catalogoCurto = total > 0 && total <= kLimiteCatalogoCurto;
    final mostrarBusca = !sacola.carregandoCatalogo && total > kLimiteCatalogoCurto;
    final chips = sacola.carregandoCatalogo
        ? const <Categoria>[]
        : Categoria.chipsPara(totalProdutos: total, temKits: sacola.kits.isNotEmpty);

    // Catálogo curto: WP/Fiber individuais → Funcionais (sem mutar state no build).
    final categoriaAtiva = catalogoCurto &&
            (_categoria == Categoria.waterProtein || _categoria == Categoria.flowFiber)
        ? Categoria.funcionais
        : _categoria;

    final produtos = sacola.produtos.where((p) {
      if (!categoriaAtiva.inclui(p)) return false;
      if (_filtro.isEmpty) return true;
      final q = _filtro.toLowerCase();
      return p.nome.toLowerCase().contains(q) || p.codigo.toLowerCase().contains(q);
    }).toList();

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.margem,
                AppSpacing.sm,
                AppSpacing.margem,
                AppSpacing.xs,
              ),
              child: Text('Produtos', style: AppTypography.largeTitle.copyWith(color: AppColors.navy)),
            ),
          ),
          if (mostrarBusca)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margem),
                child: TextField(
                  controller: _busca,
                  onChanged: (v) => setState(() => _filtro = v.trim()),
                  style: AppTypography.body.copyWith(color: AppColors.tinta),
                  decoration: InputDecoration(
                    hintText: 'Buscar produto',
                    hintStyle: AppTypography.body.copyWith(color: AppColors.textoSuave),
                    prefixIcon: const Icon(Icons.search, color: AppColors.navy),
                    filled: true,
                    fillColor: AppColors.superficie,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.raioBotao),
                      borderSide: BorderSide(color: AppColors.navy.withValues(alpha: 0.25)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.raioBotao),
                      borderSide: BorderSide(color: AppColors.navy.withValues(alpha: 0.25)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.raioBotao),
                      borderSide: const BorderSide(color: AppColors.azulMarca, width: 1.5),
                    ),
                  ),
                ),
              ),
            ),
          if (chips.isNotEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: AppSpacing.toqueMinimo + AppSpacing.sm * 2,
                child: Stack(
                  children: [
                    ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.margem,
                        AppSpacing.sm,
                        AppSpacing.margem + 24,
                        AppSpacing.sm,
                      ),
                      children: [
                        for (final c in chips)
                          Padding(
                            padding: const EdgeInsets.only(right: AppSpacing.xs),
                            child: ChipCategoria(
                              rotulo: c.rotulo,
                              selecionado: categoriaAtiva == c,
                              onTap: () => setState(() => _categoria = c),
                            ),
                          ),
                      ],
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      width: 28,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.gelo.withValues(alpha: 0),
                                AppColors.gelo,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (categoriaAtiva == Categoria.kits && !sacola.carregandoCatalogo)
            SliverToBoxAdapter(
              child: sacola.kits.isEmpty
                  ? EstadoVazio(
                      icone: Icons.widgets_outlined,
                      titulo: catalogoVazio ? 'Catálogo indisponível' : 'Nenhum kit no momento',
                      subtitulo: catalogoVazio
                          ? 'Tente de novo em instantes.'
                          : 'Escolha produtos individuais na grade.',
                      rotuloAcao: catalogoVazio ? 'Atualizar' : 'Ver todos',
                      onAcao: catalogoVazio
                          ? sacola.carregarCatalogo
                          : () => setState(() => _categoria = Categoria.todos),
                    )
                  : SizedBox(
                      height: 176,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margem),
                        scrollDirection: Axis.horizontal,
                        itemCount: sacola.kits.length,
                        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                        itemBuilder: (context, i) {
                          final k = sacola.kits[i];
                          final resumo = k.itens.map((e) => e.produto).join(', ');
                          return CardKit(
                            nome: k.nome,
                            resumoItens: resumo,
                            codigosItens: [for (final e in k.itens) e.produto],
                            onTap: () => sacola.usarKit(k),
                            onAdicionar: () => sacola.usarKit(k),
                          );
                        },
                      ),
                    ),
            ),
          if (sacola.carregandoCatalogo)
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.margem),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.sm,
                  crossAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 0.72,
                ),
                delegate: SliverChildBuilderDelegate(
                  (_, _) => const SkeletonCard(altura: 200),
                  childCount: 6,
                ),
              ),
            )
          else if (categoriaAtiva != Categoria.kits && produtos.isEmpty)
            SliverToBoxAdapter(
              child: catalogoVazio
                  ? EstadoVazio(
                      titulo: 'Catálogo indisponível',
                      subtitulo: 'Os produtos ainda não chegaram. Toque para tentar de novo.',
                      rotuloAcao: 'Atualizar',
                      onAcao: sacola.carregarCatalogo,
                    )
                  : EstadoVazio(
                      icone: Icons.filter_alt_off_outlined,
                      titulo: 'Nada neste filtro',
                      subtitulo: _filtroAtivo(categoriaAtiva)
                          ? 'Tente limpar a busca ou escolher outra categoria.'
                          : 'Nenhum produto nesta categoria.',
                      rotuloAcao: 'Limpar filtros',
                      onAcao: () => setState(() {
                        _categoria = Categoria.todos;
                        _filtro = '';
                        _busca.clear();
                      }),
                    ),
            )
          else if (categoriaAtiva != Categoria.kits)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.margem,
                0,
                AppSpacing.margem,
                AppSpacing.secaoGrande,
              ),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.sm,
                  crossAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 0.72,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final p = produtos[i];
                    return CardProduto(
                      produto: p,
                      quantidade: sacola.quantidadeDe(p.codigo),
                      passo: sacola.passo(p),
                      onAbrir: () =>
                          Navigator.of(context).pushNamed(AppRoutes.produto, arguments: p.codigo),
                      onAdicionar: () => sacola.adicionarPasso(p),
                      onAlterar: (q) => sacola.alterar(p.codigo, q),
                    );
                  },
                  childCount: produtos.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
