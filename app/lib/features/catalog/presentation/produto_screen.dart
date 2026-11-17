import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/marca_assets.dart';
import '../../../core/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/botao_principal.dart';
import '../../../core/widgets/cena_impacto_agua.dart';
import '../domain/produto_assets.dart';
import 'sacola_controller.dart';

/// PDP — quantidade + adicionar; preço só via simulação da sacola.
class ProdutoScreen extends StatefulWidget {
  const ProdutoScreen({super.key, required this.codigo});

  final String codigo;

  @override
  State<ProdutoScreen> createState() => _ProdutoScreenState();
}

class _ProdutoScreenState extends State<ProdutoScreen> {
  int _qtd = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sincronizarQuantidade());
  }

  @override
  void didUpdateWidget(covariant ProdutoScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.codigo != widget.codigo) {
      _sincronizarQuantidade();
    }
  }

  void _sincronizarQuantidade() {
    if (!mounted) return;
    final s = context.read<SacolaController>();
    final p = s.produtoDe(widget.codigo);
    if (p == null) return;
    // `clamp(passo, …)` já cobre qtd 0 → mínimo = passo da embalagem.
    setState(() => _qtd = s.quantidadeDe(p.codigo).clamp(s.passo(p), 9999));
  }

  @override
  Widget build(BuildContext context) {
    final sacola = context.watch<SacolaController>();
    final p = sacola.produtoDe(widget.codigo);
    if (p == null) {
      return Scaffold(
        backgroundColor: AppColors.fundo,
        appBar: AppBar(
          backgroundColor: AppColors.fundo,
          title: const Text('Produto'),
        ),
        body: sacola.carregandoCatalogo
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.margem),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.azulMarca),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        sacola.produtos.isEmpty
                            ? 'Catálogo indisponível'
                            : 'Produto não encontrado',
                        style: AppTypography.title3.copyWith(color: AppColors.navy),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        sacola.produtos.isEmpty
                            ? 'Não foi possível abrir este item. Tente de novo depois.'
                            : 'O código ${widget.codigo} não está no catálogo.',
                        style: AppTypography.subheadline.copyWith(color: AppColors.textoSuave),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.margem),
                      BotaoPrincipal(
                        rotulo: 'Voltar',
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ],
                  ),
                ),
              ),
      );
    }

    final passo = sacola.passo(p);
    final caixas = (_qtd / passo).round();
    final asset = garrafaDaCenaImpacto(p.codigo);
    final fundo = switch (p.codigo) {
      'WP500' => AppColors.lima,
      'FF500' => AppColors.amareloFlow.withValues(alpha: 0.35),
      _ => AppColors.aqua,
    };
    final totalTxt = sacola.simulacao?.total.formatado;
    final usaImpacto = usaCenaImpactoAgua(p.codigo);

    return Scaffold(
      backgroundColor: AppColors.fundo,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: MediaQuery.sizeOf(context).height *
                      (usaImpacto
                          ? (sacola.temItens ? 0.40 : 0.46)
                          : (sacola.temItens ? 0.36 : 0.42)),
                  pinned: true,
                  backgroundColor: usaImpacto ? AppColors.impactoAgua : fundo,
                  flexibleSpace: FlexibleSpaceBar(
                    background: usaImpacto
                        ? CenaImpactoAgua(
                            // Fundo + respingo iguais; só a garrafa muda por SKU.
                            key: ValueKey('impacto-${p.codigo}'),
                            garrafaAsset: asset,
                            mostrarCopyMarca: usaCopyImpactoMineral(p.codigo),
                            rotuloSemantico: usaCopyImpactoMineral(p.codigo)
                                ? '${p.nome}. Garrafa toca a água com um respingo.'
                                : '${p.nome}. Cena Cristalins com respingo.',
                          )
                        : Padding(
                            padding: const EdgeInsets.all(AppSpacing.secao),
                            child: Image.asset(
                              asset,
                              fit: BoxFit.contain,
                              semanticLabel: p.nome,
                            ),
                          ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.superficie,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    padding: const EdgeInsets.all(AppSpacing.margem),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.rotuloTipo,
                          style: AppTypography.caption1.copyWith(color: AppColors.azulPetroleo, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          p.nome,
                          style: (p.codigo == 'WP500' || p.codigo == 'FF500')
                              ? AppTypography.heroTitle.copyWith(fontSize: 28)
                              : AppTypography.title2.copyWith(color: AppColors.navy),
                        ),
                        Text(
                          '${p.volume} · ${p.embalagem}',
                          style: AppTypography.subheadline.copyWith(color: AppColors.textoSuave),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (p.codigo == 'WP500') ...[
                              _chip('5 g proteína e colágeno'),
                              _chip('0 açúcares'),
                              _chip('0 gorduras'),
                            ] else if (p.codigo == 'FF500') ...[
                              _chip('5 g fibras prebióticas'),
                              _chip('0 açúcares'),
                              _chip('0 sódio'),
                            ] else
                              _chip('Água mineral natural'),
                          ],
                        ),
                        if (p.descricao != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(p.descricao!, style: AppTypography.body.copyWith(color: AppColors.tinta)),
                        ],
                        const SizedBox(height: AppSpacing.secao),
                        Text('Quantidade por entrega', style: AppTypography.headline),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            IconButton.filled(
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.gelo,
                                foregroundColor: AppColors.navy,
                                minimumSize: const Size(48, 48),
                              ),
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                setState(() => _qtd = (_qtd - passo).clamp(passo, 9999));
                              },
                              icon: const Icon(Icons.remove),
                            ),
                            Expanded(
                              child: Text(
                                '$caixas ${caixas == 1 ? 'caixa' : 'caixas'} · $_qtd un.',
                                textAlign: TextAlign.center,
                                style: AppTypography.title3,
                              ),
                            ),
                            IconButton.filled(
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.azulMarca,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(48, 48),
                              ),
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                setState(() => _qtd += passo);
                              },
                              icon: const Icon(Icons.add),
                            ),
                          ],
                        ),
                        if (SacolaController.caixaMista.contains(p.codigo))
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.sm),
                            child: Text(
                              'Pode misturar Water Protein e Flow Fiber na mesma caixa.',
                              style: AppTypography.footnote.copyWith(color: AppColors.textoSuave),
                            ),
                          ),
                        const SizedBox(height: AppSpacing.secao),
                        Text(
                          'Consulte o rótulo para informações completas.',
                          style: AppTypography.caption1.copyWith(color: AppColors.textoSuave),
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.margem, 0, AppSpacing.margem, AppSpacing.margem),
              child: BotaoPrincipal(
                rotulo: totalTxt == null
                    ? 'Adicionar à assinatura'
                    : 'Adicionar à assinatura · $totalTxt/entrega',
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  sacola.alterar(p.codigo, _qtd);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Adicionado'),
                      action: SnackBarAction(
                        label: 'Ver sacola',
                        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.sacola),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String t) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.gelo,
      borderRadius: BorderRadius.circular(AppSpacing.raioChip),
    ),
    child: Text(t, style: AppTypography.caption1.copyWith(color: AppColors.navy)),
  );
}
