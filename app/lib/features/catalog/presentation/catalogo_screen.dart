import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/dependencias.dart';
import '../../../core/formatacao.dart';
import '../../../core/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/botao_principal.dart';
import '../../../core/widgets/card_produto.dart';
import '../../../core/widgets/controles.dart';
import '../../../core/widgets/estados.dart';
import '../../subscription/domain/assinatura.dart';
import '../domain/catalogo.dart';
import '../domain/produto_assets.dart';
import 'cesta_controller.dart';
import 'sacola_controller.dart';

/// Aba Produtos (marketplace) ou fluxo legado de cesta (pedido/alteração).
class CatalogoScreen extends StatelessWidget {
  const CatalogoScreen({
    super.key,
    this.pedido,
    this.alteracao,
    this.modoAba = false,
  });

  final PedidoAssinatura? pedido;
  final AlteracaoDeCesta? alteracao;
  final bool modoAba;

  @override
  Widget build(BuildContext context) {
    if (modoAba) return const _AbaProdutos();

    final dep = context.read<Dependencias>();
    return ChangeNotifierProvider(
      create: (_) => CestaController(
        dep.catalogo,
        dep.assinaturas,
        itensIniciais: alteracao?.itens ?? pedido?.itens ?? const [],
        frequencia: alteracao?.frequencia ?? pedido?.frequencia ?? 'QUINZENAL',
        plano: alteracao?.plano ?? 'FLEX',
        assinaturaId: alteracao?.assinaturaId,
      ),
      child: _FluxoLegado(pedido: pedido),
    );
  }
}

class _AbaProdutos extends StatefulWidget {
  const _AbaProdutos();

  @override
  State<_AbaProdutos> createState() => _AbaProdutosState();
}

class _AbaProdutosState extends State<_AbaProdutos> {
  Categoria _cat = Categoria.todos;
  String _busca = '';

  @override
  Widget build(BuildContext context) {
    final sacola = context.watch<SacolaController>();
    final q = _busca.trim().toLowerCase();
    final lista = _cat == Categoria.kits
        ? <Produto>[]
        : sacola.produtos.where((p) {
            if (!_cat.inclui(p)) return false;
            if (q.isEmpty) return true;
            return p.nome.toLowerCase().contains(q) || p.codigo.toLowerCase().contains(q);
          }).toList();

    return Scaffold(
      backgroundColor: AppColors.gelo,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.margem, AppSpacing.sm, AppSpacing.margem, 0),
              child: Text('Produtos', style: AppTypography.title2.copyWith(color: AppColors.navy)),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.margem),
              child: TextField(
                onChanged: (v) => setState(() => _busca = v),
                decoration: InputDecoration(
                  hintText: 'Buscar Water Protein, água com gás…',
                  prefixIcon: const Icon(Icons.search, color: AppColors.textoSuave),
                  filled: true,
                  fillColor: AppColors.superficie,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.raioChip),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margem),
                children: [
                  for (final c in Categoria.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(c.rotulo),
                        selected: _cat == c,
                        onSelected: (_) {
                          HapticFeedback.selectionClick();
                          setState(() => _cat = c);
                        },
                        selectedColor: AppColors.aqua,
                        labelStyle: AppTypography.caption1.copyWith(
                          color: _cat == c ? AppColors.navy : AppColors.textoSuave,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: sacola.carregandoCatalogo
                  ? const Center(child: CircularProgressIndicator(color: AppColors.azulMarca))
                  : sacola.erroCatalogo != null
                      ? EstadoErro(
                          mensagem: sacola.erroCatalogo!,
                          onTentarDeNovo: sacola.carregarCatalogo,
                        )
                      : _cat == Categoria.kits
                          ? _GradeKits(kits: sacola.kits, onUsar: sacola.usarKit)
                          : lista.isEmpty
                              ? Center(
                                  child: TextButton(
                                    onPressed: () => setState(() => _cat = Categoria.todos),
                                    child: const Text('Ver todos'),
                                  ),
                                )
                              : GridView.builder(
                                  padding: const EdgeInsets.all(AppSpacing.margem),
                                  gridDelegate: const ContagemGrade(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: AppSpacing.sm,
                                    crossAxisSpacing: AppSpacing.sm,
                                    childAspectRatio: 0.62,
                                  ),
                                  itemCount: lista.length,
                                  itemBuilder: (context, i) {
                                    final p = lista[i];
                                    return CardProduto(
                                      produto: p,
                                      quantidade: sacola.quantidadeDe(p.codigo),
                                      onAbrir: () => Navigator.of(context).pushNamed(
                                        AppRoutes.produto,
                                        arguments: p.codigo,
                                      ),
                                      onAdicionar: () => sacola.adicionarPasso(p),
                                    );
                                  },
                                ),
            ),
          ],
        ),
      ),
    );
  }
}

typedef ContagemGrade = SliverGridDelegateWithFixedCrossAxisCount;

class _GradeKits extends StatelessWidget {
  const _GradeKits({required this.kits, required this.onUsar});

  final List<Kit> kits;
  final void Function(Kit) onUsar;

  @override
  Widget build(BuildContext context) {
    if (kits.isEmpty) {
      return const Center(child: Text('Nenhum kit disponível.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.margem),
      itemCount: kits.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) {
        final k = kits[i];
        return ListTile(
          tileColor: AppColors.superficie,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.raioCard)),
          title: Text(k.nome, style: AppTypography.headline),
          subtitle: Text('${k.itens.length} produtos na cesta'),
          trailing: IconButton.filled(
            style: IconButton.styleFrom(backgroundColor: AppColors.azulMarca),
            onPressed: () {
              HapticFeedback.lightImpact();
              onUsar(k);
            },
            icon: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }
}

class _FluxoLegado extends StatelessWidget {
  const _FluxoLegado({this.pedido});

  final PedidoAssinatura? pedido;

  Future<void> _confirmar(BuildContext context, CestaController c) async {
    HapticFeedback.lightImpact();
    if (c.assinaturaId == null) {
      final base = pedido ?? const PedidoAssinatura(itens: []);
      Navigator.of(context).pushNamed(AppRoutes.endereco, arguments: base.copyWith(itens: c.itens));
      return;
    }
    final aPartirDe = await c.salvarAlteracao();
    if (!context.mounted) return;
    if (aPartirDe == null) {
      mostrarAviso(
        context,
        c.erroSimulacao ?? 'Não conseguimos salvar a cesta. Tente de novo.',
        erro: true,
      );
      return;
    }
    mostrarAviso(context, 'Cesta alterada. Vale a partir da entrega de ${Datas.curta(aPartirDe)}.');
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<CestaController>();
    return Scaffold(
      backgroundColor: AppColors.gelo,
      appBar: AppBar(title: Text(c.assinaturaId == null ? 'Sua cesta' : 'Alterar cesta')),
      body: c.carregando
          ? const Center(child: CircularProgressIndicator())
          : c.erroCarregar != null
          ? EstadoErro(mensagem: c.erroCarregar!, onTentarDeNovo: c.carregar)
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.margem),
              children: [
                for (final p in c.visiveis) _LinhaCestaLegado(produto: p),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Water Protein e Flow Fiber dividem a caixa de 6. '
                  'As águas vêm na embalagem de venda.',
                  style: AppTypography.footnote.copyWith(color: AppColors.textoSuave),
                ),
                if (c.erroSimulacao != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    c.erroSimulacao!,
                    style: AppTypography.footnote.copyWith(color: AppColors.erro),
                  ),
                ],
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.margem),
          child: BotaoPrincipal(
            rotulo: c.assinaturaId == null ? 'Continuar' : 'Salvar cesta',
            carregando: c.salvando,
            onPressed: c.podeContinuar ? () => _confirmar(context, c) : null,
          ),
        ),
      ),
    );
  }
}

/// Linha da cesta legada (pedido / alterar) — imagem + [SeletorQuantidade] (a11y Tela 5).
class _LinhaCestaLegado extends StatelessWidget {
  const _LinhaCestaLegado({required this.produto});

  final Produto produto;

  @override
  Widget build(BuildContext context) {
    final c = context.watch<CestaController>();
    final quantidade = c.quantidades[produto.codigo] ?? 0;
    final asset = assetDoProduto(produto.codigo);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(AppSpacing.raioCard),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.raioChip),
                    child: SizedBox(
                      width: AppSpacing.imagemProduto,
                      height: AppSpacing.imagemProduto,
                      child: ColoredBox(
                        color: corDoProduto(produto.codigo).withValues(alpha: 0.35),
                        child: asset == null
                            ? const Icon(Icons.water_drop_outlined, color: AppColors.azulMarca)
                            : Image.asset(
                                asset,
                                fit: BoxFit.contain,
                                semanticLabel: produto.nome,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          produto.rotuloTipo,
                          style: AppTypography.caption1.copyWith(color: AppColors.textoSuave),
                        ),
                        Text(
                          produto.nome,
                          style: AppTypography.headline.copyWith(color: AppColors.tinta),
                        ),
                        Text(
                          '${produto.volume} · ${produto.embalagem}',
                          style: AppTypography.subheadline.copyWith(color: AppColors.textoSuave),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: SeletorQuantidade(
                  rotulo: produto.nome,
                  quantidade: quantidade,
                  passo: c.passo(produto),
                  onAlterar: (q) => c.alterar(produto.codigo, q),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
