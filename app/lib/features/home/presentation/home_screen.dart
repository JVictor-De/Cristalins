import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/dependencias.dart';
import '../../../core/marca_assets.dart';
import '../../../core/network/api_erro.dart';
import '../../../core/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/card_proxima_entrega.dart';
import '../../../core/widgets/card_produto.dart';
import '../../../core/widgets/estado_vazio.dart';
import '../../../core/widgets/hero_water_protein.dart';
import '../../../core/widgets/logo_marca.dart';
import '../../../core/widgets/secao_com_titulo.dart';
import '../../../core/widgets/skeleton_card.dart';
import '../../catalog/domain/catalogo.dart';
import '../../catalog/presentation/sacola_controller.dart';
import '../../shell/presentation/shell_screen.dart';
import '../../subscription/domain/assinatura.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onAbrirProdutos,
    required this.onAbrirAssinatura,
  });

  final AbrirProdutosCallback onAbrirProdutos;
  final VoidCallback onAbrirAssinatura;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Assinatura? _assinaturaAtiva;
  bool _checandoAssinatura = true;
  bool _erroAssinatura = false;

  @override
  void initState() {
    super.initState();
    _checarAssinatura();
  }

  Future<void> _checarAssinatura() async {
    setState(() {
      _checandoAssinatura = true;
      _erroAssinatura = false;
    });
    final dep = context.read<Dependencias>();
    try {
      // Sem sessão na API real → visitante. Com `api` null (testes) chama o mock.
      final token = await dep.api?.tokens.lerAcesso();
      if (dep.api != null && (token == null || token.isEmpty)) {
        _assinaturaAtiva = null;
        _erroAssinatura = false;
      } else {
        final lista = await dep.assinaturas.listar();
        _assinaturaAtiva = lista.where((a) => !a.cancelada).firstOrNull;
        _erroAssinatura = false;
      }
    } catch (e) {
      final err = ApiErro.de(e);
      _assinaturaAtiva = null;
      // 401 = visitante; demais falhas mantêm modo visitante sem banner (home).
      _erroAssinatura = err.codigo != 'NAO_AUTENTICADO' && err.status != 401;
    }
    if (mounted) setState(() => _checandoAssinatura = false);
  }

  void _abrirWpOuProdutos(SacolaController sacola) {
    if (sacola.produtoDe('WP500') != null) {
      Navigator.of(context).pushNamed(AppRoutes.produto, arguments: 'WP500');
      return;
    }
    widget.onAbrirProdutos();
  }

  @override
  Widget build(BuildContext context) {
    final sacola = context.watch<SacolaController>();
    final modoAssinante = !_checandoAssinatura && !_erroAssinatura && _assinaturaAtiva != null;

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
                  onAssinar: () => _abrirWpOuProdutos(sacola),
                  onVerAguas: () => widget.onAbrirProdutos(categoria: Categoria.aguas),
                ),
              ),
            ),
          ],
          SliverToBoxAdapter(
            child: SecaoComTitulo(
              titulo: modoAssinante ? 'Sua sacola recorrente' : 'Produtos',
              acaoRotulo: 'Ver todos',
              onAcao: () => widget.onAbrirProdutos(),
              child: _CarrosselProdutos(
                sacola: sacola,
                onRetry: sacola.carregarCatalogo,
              ),
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
              const LogoMarca(altura: 36),
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
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.menta,
          borderRadius: BorderRadius.circular(AppSpacing.raioChip),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on_outlined, size: 16, color: AppColors.azulMarca),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                texto,
                style: AppTypography.footnote.copyWith(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CarrosselProdutos extends StatelessWidget {
  const _CarrosselProdutos({
    required this.sacola,
    required this.onRetry,
  });

  final SacolaController sacola;
  final VoidCallback onRetry;

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

    if (sacola.erroCatalogo != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margem),
        child: EstadoVazio(
          icone: Icons.cloud_off_outlined,
          titulo: 'Não foi possível carregar',
          subtitulo: sacola.erroCatalogo!,
          rotuloAcao: 'Tentar de novo',
          onAcao: onRetry,
        ),
      );
    }

    final lista = sacola.produtos.take(8).toList();
    if (lista.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margem),
        child: EstadoVazio(
          titulo: 'Catálogo indisponível',
          subtitulo: 'Os produtos ainda não chegaram. Tente de novo em instantes.',
          rotuloAcao: 'Tentar de novo',
          onAcao: onRetry,
        ),
      );
    }

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
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Da fonte ao Rio — água mineral natural.',
          style: AppTypography.footnote.copyWith(color: AppColors.textoSuave),
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.raioCard),
          child: ColoredBox(
            color: AppColors.aqua.withValues(alpha: 0.4),
            child: SizedBox(
              height: 120,
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Image.asset(
                  assetProdutoAguaMineral,
                  fit: BoxFit.contain,
                  semanticLabel: 'Água mineral Cristalins',
                  cacheWidth: 600,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
