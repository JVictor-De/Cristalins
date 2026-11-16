import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/card_kit.dart';
import '../../../core/widgets/card_produto.dart';
import '../../../core/widgets/chip_categoria.dart';
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
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sacola = context.watch<SacolaController>();

    if (sacola.erroCatalogo != null) {
      return SafeArea(
        child: EstadoErro(mensagem: sacola.erroCatalogo!, onTentarDeNovo: sacola.carregarCatalogo),
      );
    }

    final produtos = sacola.produtos.where((p) {
      if (!_categoria.inclui(p)) return false;
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margem),
              child: SearchBar(
                hintText: 'Buscar produto',
                onChanged: (v) => setState(() => _filtro = v.trim()),
                elevation: const WidgetStatePropertyAll(0),
                backgroundColor: const WidgetStatePropertyAll(AppColors.superficie),
                side: const WidgetStatePropertyAll(BorderSide(color: AppColors.linha)),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.margem,
                AppSpacing.sm,
                AppSpacing.margem,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  for (final c in Categoria.values)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: ChipCategoria(
                        rotulo: c.rotulo,
                        selecionado: _categoria == c,
                        onTap: () => setState(() => _categoria = c),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_categoria == Categoria.kits && !sacola.carregandoCatalogo)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 140,
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
          else if (_categoria != Categoria.kits && produtos.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('Nada encontrado. Tente outro filtro.')),
            )
          else if (_categoria != Categoria.kits)
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
                      onAbrir: () =>
                          Navigator.of(context).pushNamed(AppRoutes.produto, arguments: p.codigo),
                      onAdicionar: () => sacola.adicionarPasso(p),
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