import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/dependencias.dart';
import '../../../core/network/api_erro.dart';
import '../../../core/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/botao_sacola_badge.dart';
import '../../../core/widgets/card_proxima_entrega.dart';
import '../../../core/widgets/card_produto.dart';
import '../../../core/widgets/chip_categoria.dart';
import '../../../core/widgets/estado_vazio.dart';
import '../../../core/widgets/estados.dart';
import '../../../core/widgets/folha_lista_espera.dart';
import '../../../core/widgets/hero_water_protein.dart';
import '../../../core/widgets/logo_marca.dart';
import '../../../core/widgets/secao_com_titulo.dart';
import '../../../core/widgets/skeleton_card.dart';
import '../../address/domain/cep_sessao.dart';
import '../../auth/domain/perfil_cliente.dart';
import '../../auth/domain/validadores.dart';
import '../../catalog/domain/carrossel_home.dart';
import '../../catalog/domain/catalogo.dart';
import '../../catalog/domain/sacola_copy.dart';
import '../../catalog/presentation/sacola_controller.dart';
import '../../shell/presentation/shell_screen.dart';
import '../../subscription/domain/assinatura.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onAbrirProdutos, required this.onAbrirAssinatura});

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

  /// `GET /clientes/me` (cache no AuthRepository); nulo = visitante → “Olá!”.
  PerfilCliente? _perfil;

  FiltroHomeCarrossel _filtro = FiltroHomeCarrossel.todos;

  @override
  void initState() {
    super.initState();
    _checarAssinatura();
    _carregarPerfil();
  }

  Future<void> _carregarPerfil() async {
    final dep = context.read<Dependencias>();
    try {
      final token = await dep.api?.tokens.lerAcesso();
      if (dep.api != null && (token == null || token.isEmpty)) return;
      final perfil = await dep.auth.perfil();
      if (mounted) setState(() => _perfil = perfil);
    } catch (_) {
      // Sem sessão válida ou API fora: mantém “Olá!”.
    }
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
    if (resultado.foraDaArea) {
      await abrirFolhaListaEspera(context, cepForaDaArea: resultado.cep);
      return;
    }
    CepDaSessao.valor = resultado.cep;
    setState(() => _rotuloCep = resultado.rotulo);
  }

  Future<void> _abrirWhatsApp(AppConfig config) async {
    final url = config.urlWhatsApp();
    if (url == null) return;
    HapticFeedback.selectionClick();
    final abriu = await context.read<Dependencias>().links.abrir(url);
    if (!abriu && mounted) {
      mostrarAviso(context, 'Não conseguimos abrir o WhatsApp agora.', erro: true);
    }
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
                saudacao: PerfilCliente.saudacao(_perfil),
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
                            Navigator.of(
                              context,
                            ).pushNamed(AppRoutes.produto, arguments: wp.codigo);
                          },
                          precoAPartirDe: wp?.precoBase,
                        ),
                ),
              ),
              SliverToBoxAdapter(
                child: _FaixaPrimeiraAssinatura(
                  freteGratisAcima: sacola.simulacao?.freteGratisAcima ?? kFreteGratisAcimaPadrao,
                ),
              ),
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
                  // P1.3: mesmo fundo da tela (sem faixa branca órfã).
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.margem,
                    AppSpacing.secaoGrande,
                    AppSpacing.margem,
                    0,
                  ),
                  child: _ComoFunciona(),
                ),
              ),
              SliverToBoxAdapter(
                child: _FaqESuporte(
                  suporteWhatsapp: config.suporteWhatsappDigitos,
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
    required this.saudacao,
    required this.modoAssinante,
    required this.totalItens,
    required this.onAbrirSacola,
    required this.onAbrirCep,
    this.bairro,
    this.rotuloCep,
  });

  final String saudacao;
  final bool modoAssinante;
  final String? bairro;
  final String? rotuloCep;
  final int totalItens;
  final VoidCallback onAbrirSacola;
  final VoidCallback onAbrirCep;

  @override
  Widget build(BuildContext context) {
    // P1.1: texto do chip sem “Alterar” — a ação fica só no trailing.
    final textoCep = modoAssinante && bairro != null
        ? 'Entrega em $bairro · Rio de Janeiro'
        : (rotuloCep ?? 'Entrega no Rio de Janeiro');

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.margem, AppSpacing.sm, AppSpacing.margem, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // P1.1: logo no eixo da tela (Stack), “Olá!” à esquerda, sacola à direita.
          SizedBox(
            height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  // Nome longo não passa do eixo central: encolhe só acima de meia largura
                  // (“Olá!” a 200% cabe sem escala — golden P6).
                  child: FractionallySizedBox(
                    widthFactor: 0.5,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Semantics(
                        header: true,
                        child: Text(
                          saudacao,
                          key: const ValueKey('home-saudacao'),
                          maxLines: 1,
                          style: AppTypography.title3.copyWith(color: AppColors.navy),
                        ),
                      ),
                    ),
                  ),
                ),
                const LogoMarca(key: ValueKey('logo-home'), altura: 44),
                Align(
                  alignment: Alignment.centerRight,
                  child: BotaoSacolaBadge(totalItens: totalItens, onTap: onAbrirSacola),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _ChipEntrega(texto: textoCep, onTap: onAbrirCep),
        ],
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
    // P1.1: full-width; “Alterar” aparece uma vez (trailing) e uma vez no leitor.
    return Semantics(
      button: true,
      label: '$texto. Alterar CEP',
      excludeSemantics: true,
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
            // 15 + 18 (footnote) + 15 = 48 dp de alvo.
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 15),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: AppColors.azulMarca),
                const SizedBox(width: 6),
                Expanded(
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
  const _ResultadoCepHome({required this.cep, required this.rotulo}) : foraDaArea = false;
  const _ResultadoCepHome.foraDaArea(this.cep) : rotulo = '', foraDaArea = true;
  final String cep;
  final String rotulo;

  /// CEP_FORA_AREA / BAIRRO_NAO_ATENDIDO: a home abre a lista de espera.
  final bool foraDaArea;
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

  /// CEP consultado que a API recusou por área; habilita “Entrar na lista de espera”.
  String? _cepForaDaArea;

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
      _cepForaDaArea = null;
    });
    final digitos = Validadores.digitos(_ctrl.text);
    try {
      final r = await context.read<Dependencias>().enderecos.consultarCep(digitos);
      if (!mounted) return;
      final rotulo = '${r.bairro} · ${r.zona.nome}';
      Navigator.of(context).pop(_ResultadoCepHome(cep: digitos, rotulo: 'Entrega em $rotulo'));
    } catch (e) {
      if (!mounted) return;
      final erro = ApiErro.de(e);
      setState(() {
        _carregando = false;
        _erro = erro.mensagem;
        if (erro.codigo == 'CEP_FORA_AREA' || erro.codigo == 'BAIRRO_NAO_ATENDIDO') {
          _cepForaDaArea = digitos;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.margem,
          AppSpacing.sm,
          AppSpacing.margem,
          AppSpacing.margem,
        ),
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
            Text(
              'Confirmar área de entrega',
              style: AppTypography.title3.copyWith(color: AppColors.navy),
            ),
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
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(8),
              ],
              decoration: InputDecoration(
                labelText: 'CEP',
                hintText: '00000000',
                errorText: _erro,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.raioCard),
                ),
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
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.sobrePrimaria,
                      ),
                    )
                  : const Text('Confirmar CEP'),
            ),
            if (_cepForaDaArea != null)
              TextButton(
                key: const ValueKey('home-cep-lista-espera'),
                onPressed: () =>
                    Navigator.of(context).pop(_ResultadoCepHome.foraDaArea(_cepForaDaArea!)),
                child: Text(
                  'Entrar na lista de espera',
                  style: AppTypography.subheadline.copyWith(
                    color: AppColors.azulMarca,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
  const _FaixaPrimeiraAssinatura({required this.freteGratisAcima});

  /// Limite RN18 vindo da última simulação (default do modelo = contrato da API).
  final num freteGratisAcima;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.margem, 0, AppSpacing.margem, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // P1.2: hint de frete grátis logo abaixo do hero (above-the-fold).
          Row(
            key: const ValueKey('hint-frete-gratis'),
            children: [
              const Icon(Icons.local_shipping_outlined, size: 18, color: AppColors.heroNavy),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  SacolaCopy.freteGratisAcima(freteGratisAcima),
                  style: AppTypography.footnote.copyWith(
                    color: AppColors.heroInk,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Na primeira assinatura você escolhe frequência e paga com Pix.',
            style: AppTypography.footnote.copyWith(color: AppColors.textoSuave),
          ),
        ],
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
  var _paginas = 1;

  static const _gap = AppSpacing.sm;

  /// Máximo de indicadores (P0.6: não um dot por SKU).
  static const _maxIndicadores = 4;

  /// ~2,3 cards visíveis (terceiro cortado), limitado ao alvo ~164 px.
  static double larguraCardPara(double larguraTela) =>
      ((larguraTela - AppSpacing.margem - _gap * 2) / 2.3).clamp(140.0, 176.0);

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
    if (!_scroll.hasClients || _paginas <= 1) return;
    final max = _scroll.position.maxScrollExtent;
    final frac = max <= 0 ? 0.0 : (_scroll.offset / max).clamp(0.0, 1.0);
    final i = (frac * (_paginas - 1)).round();
    if (i != _pagina) setState(() => _pagina = i);
  }

  @override
  Widget build(BuildContext context) {
    final sacola = widget.sacola;

    final filtros = Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.margem, 0, AppSpacing.margem, AppSpacing.sm),
      child: ScrollConfiguration(
        behavior: const AppScrollBehavior(),
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
      ),
    );

    if (sacola.carregandoCatalogo) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          filtros,
          SizedBox(
            height: 220,
            child: ScrollConfiguration(
              behavior: const AppScrollBehavior(),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margem),
                scrollDirection: Axis.horizontal,
                itemCount: 3,
                separatorBuilder: (_, _) => const SizedBox(width: _gap),
                itemBuilder: (_, _) => const SkeletonCard(
                  altura: AppSpacing.alturaBlocoProduto,
                  largura: AppSpacing.larguraBlocoProduto,
                ),
              ),
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
            child: EstadoErro(mensagem: sacola.erroCatalogo!, onTentarDeNovo: widget.onRetry),
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

    final larguraTela = MediaQuery.sizeOf(context).width;
    final larguraCard = larguraCardPara(larguraTela);
    final alturaBloco =
        larguraCard * AppSpacing.alturaBlocoProduto / AppSpacing.larguraBlocoProduto;
    final alturaCard = CardProduto.alturaPara(alturaBloco, MediaQuery.textScalerOf(context));
    final conteudo = AppSpacing.margem * 2 + lista.length * larguraCard + (lista.length - 1) * _gap;
    _paginas = (conteudo / larguraTela).ceil().clamp(1, _maxIndicadores);
    final ativo = _pagina.clamp(0, _paginas - 1);

    // RepaintBoundary: isola repaint do scroll horizontal (e recorta o golden P0).
    return RepaintBoundary(
      key: const ValueKey('carrossel-home'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          filtros,
          SizedBox(
            height: alturaCard,
            // ScrollConfiguration local: garante mouse/trackpad mesmo se o tema
            // ancestral mudar (web desktop).
            child: ScrollConfiguration(
              behavior: const AppScrollBehavior(),
              child: ListView.separated(
                controller: _scroll,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margem),
                scrollDirection: Axis.horizontal,
                itemCount: lista.length,
                separatorBuilder: (_, _) => const SizedBox(width: _gap),
                itemBuilder: (context, i) {
                  final p = lista[i];
                  return SizedBox(
                    width: larguraCard,
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
          ),
          if (_paginas > 1) ...[
            const SizedBox(height: AppSpacing.sm),
            ExcludeSemantics(
              child: Row(
                key: const ValueKey('indicador-carrossel-home'),
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _paginas; i++)
                    AnimatedContainer(
                      duration: (MediaQuery.maybeDisableAnimationsOf(context) ?? false)
                          ? Duration.zero
                          : AppDurations.toque,
                      // Ativo = pílula navy (forma ≠ só cor); inativo textoSuave (≥4,5:1 em #F6F9FB).
                      width: i == ativo ? 18 : 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppSpacing.raioChip),
                        color: i == ativo ? AppColors.heroNavy : AppColors.textoSuave,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// P1.3: lista numerada vertical sobre `AppColors.fundo`; nomes completos de linha.
/// Sem rodapé “água mineral natural” — a seção cobre WP/FF (não misturar denominação).
class _ComoFunciona extends StatelessWidget {
  static const passos = [
    ('Monte sua sacola', 'Escolha águas, Water Protein ou Flow Fiber.'),
    ('Escolha a frequência', 'Semanal, quinzenal ou mensal — você decide na sacola.'),
    ('Pague com Pix', 'Finalize no checkout quando estiver pronto.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('como-funciona'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text('Como funciona', style: AppTypography.title3.copyWith(color: AppColors.navy)),
        ),
        const SizedBox(height: AppSpacing.margem),
        for (var i = 0; i < passos.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.margem),
          MergeSemantics(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.heroNavy,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${i + 1}',
                    style: AppTypography.subheadline.copyWith(
                      color: AppColors.sobrePrimaria,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        passos[i].$1,
                        style: AppTypography.headline.copyWith(color: AppColors.heroInk),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        passos[i].$2,
                        style: AppTypography.subheadline.copyWith(color: AppColors.textoSuave),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _FaqESuporte extends StatelessWidget {
  const _FaqESuporte({required this.suporteWhatsapp, required this.onWhatsApp});

  final String suporteWhatsapp;
  final VoidCallback onWhatsApp;

  @override
  Widget build(BuildContext context) {
    const faqs = [
      (
        'Onde vocês entregam?',
        'Atendemos bairros oficiais do município do Rio de Janeiro. Confirme pelo CEP na home ou no checkout.',
      ),
      (
        'Posso pausar a assinatura?',
        'Sim. Na área logada você pausa ou ajusta a frequência conforme as regras da assinatura.',
      ),
      (
        'Como cancelo?',
        'Pelo app, em Minha assinatura, com confirmação. Sem taxa inventada nesta tela.',
      ),
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
