import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/dependencias.dart';
import '../../../core/marca_assets.dart';
import '../../../core/network/api_erro.dart';
import '../../../core/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/card_proxima_entrega.dart';
import '../../../core/widgets/card_produto.dart';
import '../../../core/widgets/chip_categoria.dart';
import '../../../core/widgets/estado_vazio.dart';
import '../../../core/widgets/estados.dart';
import '../../../core/widgets/hero_water_protein.dart';
import '../../../core/widgets/logo_marca.dart';
import '../../../core/widgets/secao_com_titulo.dart';
import '../../../core/widgets/skeleton_card.dart';
import '../../auth/domain/validadores.dart';
import '../../catalog/domain/carrossel_home.dart';
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

  /// Rótulo do CEP confirmado na sessão (sem store de domínio guest ainda).
  String? _rotuloCep;

  FiltroHomeCarrossel _filtro = FiltroHomeCarrossel.todos;

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
      _erroAssinatura = err.codigo != 'NAO_AUTENTICADO' && err.status != 401;
    }
    if (mounted) setState(() => _checandoAssinatura = false);
  }

  void _assinarWp(SacolaController sacola) {
    final wp = sacola.produtoDe('WP500');
    if (wp == null) {
      widget.onAbrirProdutos();
      return;
    }
    sacola.adicionarPasso(wp);
    Navigator.of(context).pushNamed(AppRoutes.sacola);
  }

  Future<void> _abrirFolhaCep() async {
    final resultado = await showModalBottomSheet<_ResultadoCepHome>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.superficie,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.raioCard)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: const _FolhaCepHome(),
      ),
    );
    if (!mounted || resultado == null) return;
    setState(() => _rotuloCep = resultado.rotulo);
  }

  Future<void> _abrirWhatsApp(AppConfig config) async {
    final n = config.suporteWhatsapp;
    if (n.isEmpty) return;
    await context.read<Dependencias>().links.abrir('https://wa.me/$n');
  }

  @override
  Widget build(BuildContext context) {
    final sacola = context.watch<SacolaController>();
    final config = context.watch<AppConfig>();
    final modoAssinante = !_checandoAssinatura && !_erroAssinatura && _assinaturaAtiva != null;
    final wp = sacola.produtoDe('WP500');

    return ColoredBox(
      color: AppColors.fundo,
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _Header(
                modoAssinante: modoAssinante,
                bairro: _assinaturaAtiva?.bairro,
                rotuloCep: _rotuloCep,
                totalItens: sacola.totalItens,
                onAbrirSacola: () => Navigator.of(context).pushNamed(AppRoutes.sacola),
                onAbrirCep: _abrirFolhaCep,
              ),
            ),
            if (modoAssinante && _assinaturaAtiva!.proximaEntrega != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: CardProximaEntrega(
                    dataEntrega: _assinaturaAtiva!.proximaEntrega!,
                    janela: _assinaturaAtiva!.janela,
                    status: 'Em preparação',
                    onEditarSacola: () => Navigator.of(context).pushNamed(AppRoutes.sacola),
                    onPularEntrega: widget.onAbrirAssinatura,
                    onEditarAssinatura: widget.onAbrirAssinatura,
                  ),
                ),
              )
            else if (!modoAssinante) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.margem),
                  child: sacola.carregandoCatalogo
                      ? const SkeletonCard(altura: 316)
                      : HeroWaterProtein(
                          onAssinar: () => _assinarWp(sacola),
                          onAbrirProduto: () {
                            if (wp == null) {
                              widget.onAbrirProdutos();
                              return;
                            }
                            Navigator.of(context).pushNamed(
                              AppRoutes.produto,
                              arguments: wp.codigo,
                            );
                          },
                          precoAPartirDe: wp?.precoBase,
                        ),
                ),
              ),
              const SliverToBoxAdapter(child: _FaixaPrimeiraAssinatura()),
            ],
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.secao),
                child: SecaoComTitulo(
                  titulo: modoAssinante ? 'Sua sacola recorrente' : 'Produtos',
                  acaoRotulo: (!sacola.carregandoCatalogo && sacola.produtos.isEmpty)
                      ? null
                      : 'Ver todos',
                  onAcao: (!sacola.carregandoCatalogo && sacola.produtos.isEmpty)
                      ? null
                      : () => widget.onAbrirProdutos(),
                  child: _CarrosselProdutos(
                    sacola: sacola,
                    filtro: _filtro,
                    onFiltro: (f) => setState(() => _filtro = f),
                    onRetry: sacola.carregarCatalogo,
                  ),
                ),
              ),
            ),
            if (!modoAssinante) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.secao),
                  child: ColoredBox(
                    color: AppColors.superficie,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.margem,
                        AppSpacing.secao,
                        AppSpacing.margem,
                        AppSpacing.secao,
                      ),
                      child: _ComoFunciona(),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: _BannerMarca()),
              const SliverToBoxAdapter(child: _SelosHonestos()),
              SliverToBoxAdapter(
                child: _FaqESuporte(
                  suporteWhatsapp: config.suporteWhatsapp,
                  onWhatsApp: () => _abrirWhatsApp(config),
                ),
              ),
            ],
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
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.modoAssinante,
    required this.totalItens,
    required this.onAbrirSacola,
    required this.onAbrirCep,
    this.bairro,
    this.rotuloCep,
  });

  final bool modoAssinante;
  final String? bairro;
  final String? rotuloCep;
  final int totalItens;
  final VoidCallback onAbrirSacola;
  final VoidCallback onAbrirCep;

  @override
  Widget build(BuildContext context) {
    final textoCep = modoAssinante && bairro != null
        ? 'Entrega em $bairro · Rio de Janeiro'
        : (rotuloCep ?? 'Entrega no Rio de Janeiro · Alterar CEP');

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
                  style: AppTypography.title3.copyWith(color: AppColors.navy),
                ),
              ),
              const LogoMarca(altura: 52),
              const SizedBox(width: AppSpacing.sm),
              _BotaoSacolaBadge(totalItens: totalItens, onTap: onAbrirSacola),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _ChipEntrega(texto: textoCep, onTap: onAbrirCep),
        ],
      ),
    );
  }
}

class _BotaoSacolaBadge extends StatelessWidget {
  const _BotaoSacolaBadge({required this.totalItens, required this.onTap});

  final int totalItens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: totalItens == 0
          ? 'Abrir sacola'
          : 'Abrir sacola, $totalItens ${totalItens == 1 ? 'item' : 'itens'}',
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(AppSpacing.raioChip),
        child: SizedBox(
          width: AppSpacing.toqueMinimo,
          height: AppSpacing.toqueMinimo,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              const Icon(Icons.shopping_bag_outlined, color: AppColors.navy),
              if (totalItens > 0)
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: AppColors.promo,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      totalItens > 99 ? '99+' : '$totalItens',
                      textAlign: TextAlign.center,
                      style: AppTypography.caption2.copyWith(
                        color: AppColors.sobrePrimaria,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChipEntrega extends StatelessWidget {
  const _ChipEntrega({required this.texto, required this.onTap});

  final String texto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$texto. Alterar CEP',
      child: Material(
        color: AppColors.menta,
        borderRadius: BorderRadius.circular(AppSpacing.raioChip),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.raioChip),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 8),
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
                const SizedBox(width: 6),
                Text(
                  'Alterar',
                  style: AppTypography.caption1.copyWith(
                    color: AppColors.azulMarca,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.azulMarca),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultadoCepHome {
  const _ResultadoCepHome({required this.cep, required this.rotulo});
  final String cep;
  final String rotulo;
}

class _FolhaCepHome extends StatefulWidget {
  const _FolhaCepHome();

  @override
  State<_FolhaCepHome> createState() => _FolhaCepHomeState();
}

class _FolhaCepHomeState extends State<_FolhaCepHome> {
  final _ctrl = TextEditingController();
  var _carregando = false;
  String? _erro;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _consultar() async {
    final msg = Validadores.cep(_ctrl.text);
    if (msg != null) {
      setState(() => _erro = msg);
      return;
    }
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final digitos = Validadores.digitos(_ctrl.text);
      final r = await context.read<Dependencias>().enderecos.consultarCep(digitos);
      if (!mounted) return;
      final rotulo = '${r.bairro} · ${r.zona.nome}';
      Navigator.of(context).pop(_ResultadoCepHome(cep: digitos, rotulo: 'Entrega em $rotulo'));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _erro = ApiErro.de(e).mensagem;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.margem, AppSpacing.sm, AppSpacing.margem, AppSpacing.margem),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.linha,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('Confirmar área de entrega', style: AppTypography.title3.copyWith(color: AppColors.navy)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Informe o CEP para ver se atendemos o bairro (mesma consulta do checkout).',
              style: AppTypography.footnote.copyWith(color: AppColors.textoSuave),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _ctrl,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.postalCode],
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
              decoration: InputDecoration(
                labelText: 'CEP',
                hintText: '00000000',
                errorText: _erro,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.raioCard)),
              ),
              onSubmitted: (_) => _consultar(),
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton(
              onPressed: _carregando ? null : _consultar,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.navy,
                minimumSize: const Size(0, AppSpacing.toqueMinimo),
              ),
              child: _carregando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.sobrePrimaria),
                    )
                  : const Text('Confirmar CEP'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Informar no checkout',
                style: AppTypography.subheadline.copyWith(color: AppColors.azulMarca),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaixaPrimeiraAssinatura extends StatelessWidget {
  const _FaixaPrimeiraAssinatura();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.margem, 0, AppSpacing.margem, 0),
      child: Text(
        'Na primeira assinatura você escolhe frequência e paga com Pix.',
        style: AppTypography.footnote.copyWith(color: AppColors.textoSuave),
      ),
    );
  }
}

class _CarrosselProdutos extends StatefulWidget {
  const _CarrosselProdutos({
    required this.sacola,
    required this.filtro,
    required this.onFiltro,
    required this.onRetry,
  });

  final SacolaController sacola;
  final FiltroHomeCarrossel filtro;
  final ValueChanged<FiltroHomeCarrossel> onFiltro;
  final VoidCallback onRetry;

  @override
  State<_CarrosselProdutos> createState() => _CarrosselProdutosState();
}

class _CarrosselProdutosState extends State<_CarrosselProdutos> {
  final _scroll = ScrollController();
  var _pagina = 0;

  static const _larguraCard = 160.0;
  static const _gap = AppSpacing.sm;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final passo = _larguraCard + _gap;
    final i = (_scroll.offset / passo).round().clamp(0, 99);
    if (i != _pagina) setState(() => _pagina = i);
  }

  @override
  Widget build(BuildContext context) {
    final sacola = widget.sacola;

    final filtros = Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.margem, 0, AppSpacing.margem, AppSpacing.sm),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final f in FiltroHomeCarrossel.values) ...[
              ChipCategoria(
                rotulo: f.rotulo,
                selecionado: widget.filtro == f,
                onTap: () {
                  widget.onFiltro(f);
                  if (_scroll.hasClients) {
                    _scroll.jumpTo(0);
                  }
                  setState(() => _pagina = 0);
                },
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
          ],
        ),
      ),
    );

    if (sacola.carregandoCatalogo) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          filtros,
          SizedBox(
            height: 220,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margem),
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              separatorBuilder: (_, _) => const SizedBox(width: _gap),
              itemBuilder: (_, _) => const SkeletonCard(altura: 200, largura: _larguraCard),
            ),
          ),
        ],
      );
    }

    if (sacola.erroCatalogo != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          filtros,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margem),
            child: EstadoErro(
              mensagem: sacola.erroCatalogo!,
              onTentarDeNovo: widget.onRetry,
            ),
          ),
        ],
      );
    }

    final lista = produtosCarrosselHome(sacola.produtos, filtro: widget.filtro);
    if (lista.isEmpty) {
      return Column(
        children: [
          filtros,
          EstadoVazio(
            titulo: sacola.produtos.isEmpty ? 'Catálogo indisponível' : 'Nada neste filtro',
            subtitulo: sacola.produtos.isEmpty
                ? 'Os produtos ainda não chegaram. Tente de novo em instantes.'
                : 'Escolha outro filtro ou veja todos os produtos.',
            rotuloAcao: sacola.produtos.isEmpty ? 'Atualizar' : 'Limpar filtro',
            onAcao: sacola.produtos.isEmpty
                ? widget.onRetry
                : () => widget.onFiltro(FiltroHomeCarrossel.todos),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        filtros,
        SizedBox(
          height: 248,
          child: ListView.separated(
            controller: _scroll,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margem),
            scrollDirection: Axis.horizontal,
            itemCount: lista.length,
            separatorBuilder: (_, _) => const SizedBox(width: _gap),
            itemBuilder: (context, i) {
              final p = lista[i];
              return SizedBox(
                width: _larguraCard,
                child: CardProduto(
                  produto: p,
                  quantidade: sacola.quantidadeDe(p.codigo),
                  passo: sacola.passo(p),
                  onAbrir: () =>
                      Navigator.of(context).pushNamed(AppRoutes.produto, arguments: p.codigo),
                  onAdicionar: () => sacola.adicionarPasso(p),
                  onAlterar: (q) => sacola.alterar(p.codigo, q),
                ),
              );
            },
          ),
        ),
        if (lista.length > 1) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < lista.length; i++)
                Container(
                  width: i == _pagina.clamp(0, lista.length - 1) ? 8 : 6,
                  height: i == _pagina.clamp(0, lista.length - 1) ? 8 : 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _pagina.clamp(0, lista.length - 1)
                        ? AppColors.navy
                        : AppColors.linha,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ComoFunciona extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const passos = [
      (Icons.shopping_bag_outlined, 'Monte sua sacola', 'Escolha águas, Water Protein ou Fiber.'),
      (Icons.calendar_month_outlined, 'Escolha frequência', 'Semanal, quinzenal ou mensal — você decide na sacola.'),
      (Icons.qr_code_2_outlined, 'Pague com Pix', 'Finalize no checkout quando estiver pronto.'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Como funciona', style: AppTypography.title3.copyWith(color: AppColors.navy)),
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < passos.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.fundo,
                    borderRadius: BorderRadius.circular(AppSpacing.raioCard),
                    border: Border.all(color: AppColors.linha),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(passos[i].$1, color: AppColors.azulMarca, size: 28),
                      const SizedBox(height: AppSpacing.xs),
                      Text(passos[i].$2, style: AppTypography.headline.copyWith(color: AppColors.tinta)),
                      const SizedBox(height: 2),
                      Text(passos[i].$3, style: AppTypography.caption1.copyWith(color: AppColors.textoSuave)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Da fonte ao Rio — água mineral natural.',
          style: AppTypography.footnote.copyWith(color: AppColors.textoSuave),
        ),
      ],
    );
  }
}

class _BannerMarca extends StatelessWidget {
  const _BannerMarca();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.margem, AppSpacing.secao, AppSpacing.margem, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.raioCard),
        child: SizedBox(
          height: 120,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                assetHeroAguaBokeh,
                fit: BoxFit.cover,
                semanticLabel: 'Água Cristalins',
                errorBuilder: (_, _, _) => const ColoredBox(color: AppColors.aqua),
              ),
              ColoredBox(color: AppColors.navy.withValues(alpha: 0.35)),
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Text(
                    'Da fonte ao Rio',
                    style: AppTypography.title3.copyWith(color: AppColors.sobrePrimaria),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelosHonestos extends StatelessWidget {
  const _SelosHonestos();

  @override
  Widget build(BuildContext context) {
    const selos = [
      'Água mineral natural',
      'Entrega no município do Rio',
      'Pagamento com Pix',
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.margem, AppSpacing.sm, AppSpacing.margem, 0),
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [
          for (final s in selos)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.menta,
                borderRadius: BorderRadius.circular(AppSpacing.raioChip),
              ),
              child: Text(
                s,
                style: AppTypography.caption1.copyWith(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FaqESuporte extends StatelessWidget {
  const _FaqESuporte({
    required this.suporteWhatsapp,
    required this.onWhatsApp,
  });

  final String suporteWhatsapp;
  final VoidCallback onWhatsApp;

  @override
  Widget build(BuildContext context) {
    const faqs = [
      ('Onde vocês entregam?', 'Atendemos bairros oficiais do município do Rio de Janeiro. Confirme pelo CEP na home ou no checkout.'),
      ('Posso pausar a assinatura?', 'Sim. Na área logada você pausa ou ajusta a frequência conforme as regras da assinatura.'),
      ('Como cancelo?', 'Pelo app, em Minha assinatura, com confirmação. Sem taxa inventada nesta tela.'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.margem,
        AppSpacing.secao,
        AppSpacing.margem,
        AppSpacing.secaoGrande,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Perguntas frequentes', style: AppTypography.title3.copyWith(color: AppColors.navy)),
          const SizedBox(height: AppSpacing.sm),
          for (final (q, a) in faqs) ...[
            Text(q, style: AppTypography.headline.copyWith(color: AppColors.tinta)),
            const SizedBox(height: 2),
            Text(a, style: AppTypography.footnote.copyWith(color: AppColors.textoSuave)),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (suporteWhatsapp.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                HapticFeedback.selectionClick();
                onWhatsApp();
              },
              icon: const Icon(Icons.chat_outlined, color: AppColors.azulMarca),
              label: Text(
                'Falar no WhatsApp',
                style: AppTypography.subheadline.copyWith(
                  color: AppColors.azulMarca,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
