import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/dependencias.dart';
import '../../../core/marca_assets.dart';
import '../../../core/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/card_proxima_entrega.dart';
import '../../../core/widgets/card_produto.dart';
import '../../../core/widgets/hero_water_protein.dart';
import '../../../core/widgets/secao_com_titulo.dart';
import '../../../core/widgets/skeleton_card.dart';
import '../../catalog/presentation/sacola_controller.dart';
import '../../subscription/domain/assinatura.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onAbrirProdutos,
    required this.onAbrirAssinatura,
  });

  final VoidCallback onAbrirProdutos;
  final VoidCallback onAbrirAssinatura;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Assinatura? _assinaturaAtiva;
  bool _checandoAssinatura = true;

  @override
  void initState() {
    super.initState();
    _checarAssinatura();
  }

  Future<void> _checarAssinatura() async {
    final dep = context.read<Dependencias>();
    try {
      final lista = await dep.assinaturas.listar();
      _assinaturaAtiva = lista.where((a) => !a.cancelada).firstOrNull;
    } catch (_) {
      _assinaturaAtiva = null;
    }
    if (mounted) setState(() => _checandoAssinatura = false);
  }

  @override
  Widget build(BuildContext context) {
    final sacola = context.watch<SacolaController>();
    final modoAssinante = !_checandoAssinatura && _assinaturaAtiva != null;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _Header(modoAssinante: modoAssinante, bairro: _assinaturaAtiva?.bairro)),
          if (modoAssinante && _assinaturaAtiva!.proximaEntrega != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: CardProximaEntrega(
                  dataEntrega: _assinaturaAtiva!.proximaEntrega!,
                  janela: _assinaturaAtiva!.janela,
                  status: 'Em preparação',
                  onEditarSacola: () => Navigator.of(context).pushNamed(AppRoutes.sacola),
                ),
              ),
            )
          else if (!modoAssinante) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.margem),
                child: HeroWaterProtein(
                  onAssinar: () => Navigator.of(context).pushNamed(AppRoutes.produto, arguments: 'WP500'),
                  onVerAguas: widget.onAbrirProdutos,
                ),
              ),
            ),
          ],
          SliverToBoxAdapter(
            child: SecaoComTitulo(
              titulo: modoAssinante ? 'Sua sacola recorrente' : 'Produtos',
              acaoRotulo: 'Ver todos',
              onAcao: widget.onAbrirProdutos,
              child: _CarrosselProdutos(sacola: sacola),
            ),
          ),
          if (!modoAssinante)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.margem,
                  AppSpacing.secao,
                  AppSpacing.margem,
                  AppSpacing.secaoGrande,
                ),
                child: _ComoFunciona(),
              ),
            ),
          if (modoAssinante)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.margem),
                child: TextButton(
                  onPressed: widget.onAbrirAssinatura,
                  child: const Text('Ver assinatura completa'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.modoAssinante, this.bairro});
  final bool modoAssinante;
  final String? bairro;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.margem, AppSpacing.sm, AppSpacing.margem, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Olá!',
                  style: AppTypography.largeTitle.copyWith(color: AppColors.navy),
                ),
              ),
              Image.asset(assetLogoMarca, height: 32, semanticLabel: 'Cristalins'),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _ChipEntrega(
            texto: modoAssinante && bairro != null
                ? 'Entrega em $bairro · Rio de Janeiro'
                : 'Entrega no Rio de Janeiro · CEP na hora de fechar',
          ),
        ],
      ),
    );
  }
}

class _ChipEntrega extends StatelessWidget {
  const _ChipEntrega({required this.texto});
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: texto,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: AppColors.superficie,
          borderRadius: BorderRadius.circular(AppSpacing.raioBotao),
          border: Border.all(color: AppColors.linha),
        ),
        child: Text(
          texto,
          style: AppTypography.footnote.copyWith(color: AppColors.textoSuave),
        ),
      ),
    );
  }
}

class _CarrosselProdutos extends StatelessWidget {
  const _CarrosselProdutos({required this.sacola});
  final SacolaController sacola;

  @override
  Widget build(BuildContext context) {
    if (sacola.carregandoCatalogo) {
      return SizedBox(
        height: 220,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margem),
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
          itemBuilder: (_, _) => const SkeletonCard(altura: 200, largura: 160),
        ),
      );
    }

    final lista = sacola.produtos.take(8).toList();
    if (lista.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 248,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margem),
        scrollDirection: Axis.horizontal,
        itemCount: lista.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final p = lista[i];
          return SizedBox(
            width: 160,
            child: CardProduto(
              produto: p,
              quantidade: sacola.quantidadeDe(p.codigo),
              onAbrir: () =>
                  Navigator.of(context).pushNamed(AppRoutes.produto, arguments: p.codigo),
              onAdicionar: () => sacola.adicionarPasso(p),
            ),
          );
        },
      ),
    );
  }
}

class _ComoFunciona extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const passos = [
      ('1', 'Monte sua sacola', 'Escolha águas, Water Protein ou Fiber.'),
      ('2', 'Escolha frequência', 'Quinzenal, semanal ou mensal — você decide na sacola.'),
      ('3', 'Pague com Pix', 'Finalize no checkout quando estiver pronto.'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Como funciona', style: AppTypography.title3.copyWith(color: AppColors.navy)),
        const SizedBox(height: AppSpacing.sm),
        for (final (n, t, s) in passos) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.azulMarca,
                child: Text(n, style: AppTypography.caption2.copyWith(color: AppColors.sobrePrimaria)),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t, style: AppTypography.headline.copyWith(color: AppColors.tinta)),
                    Text(s, style: AppTypography.footnote.copyWith(color: AppColors.textoSuave)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.raioCard),
          child: Image.asset(
            assetHeroColocarSite,
            height: 96,
            width: double.infinity,
            fit: BoxFit.cover,
            semanticLabel: 'Origem Cristalins',
            cacheWidth: 800,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}