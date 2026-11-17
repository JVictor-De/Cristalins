import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/formatacao.dart';
import '../../../core/marca_assets.dart';
import '../../../core/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sombras.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/botao_principal.dart';
import '../../../core/widgets/cena_impacto_agua.dart';
import '../../../core/widgets/folha_lista_espera.dart';
import '../domain/catalogo.dart';
import '../domain/pdp_copy.dart';
import '../domain/produto_assets.dart';
import '../domain/sacola_copy.dart';
import 'sacola_controller.dart';

/// PDP (P2 design_ux_ui) — hero full-bleed, título Inter, CTA navy com o valor da
/// quantidade local. Total da assinatura (descontos/frete) continua só na sacola.
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
        appBar: AppBar(backgroundColor: AppColors.fundo, title: const Text('Produto')),
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
    // Antes do sync pós-frame, _qtd = 0: exibe o mínimo (1 passo).
    final qtd = _qtd < passo ? passo : _qtd;
    final sim = sacola.simulacao;
    final teto = (PdpCopy.tetoPadrao ~/ passo) * passo;
    final noMinimo = qtd <= passo;
    final noTeto = qtd + passo > teto;
    final naSacola = sacola.quantidadeDe(p.codigo) > 0;
    final unitario = PdpCopy.unitario(p, sim);
    final valorItem = PdpCopy.valorItem(p, qtd, sim);
    final asset = garrafaDaCenaImpacto(p.codigo);
    final usaImpacto = usaCenaImpactoAgua(p.codigo);
    final fundoHero = switch (p.codigo) {
      'WP500' => AppColors.lima,
      'FF500' => AppColors.amareloFlow.withValues(alpha: 0.35),
      _ => AppColors.aqua,
    };
    final rotuloQtd = PdpCopy.quantidade(p, qtd);
    final chips = PdpCopy.chips(p);
    final apoio = AppTypography.subheadline.copyWith(color: AppColors.textoSuave);
    final funcional = p.codigo == 'WP500' || p.codigo == 'FF500';
    final avulso = PdpCopy.avulso(p);
    final tabela = p.tabelaNutricional;
    // Esgotado e fora da sacola: troca quantidade + CTA por “Avise-me”.
    final soAviseMe = p.esgotado && !naSacola;

    return Scaffold(
      backgroundColor: AppColors.fundo,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                // P2.1: hero full-bleed ~40% da altura; voltar em círculo branco 40/48.
                SliverAppBar(
                  expandedHeight: MediaQuery.sizeOf(context).height * 0.40,
                  pinned: true,
                  automaticallyImplyLeading: false,
                  leadingWidth: AppSpacing.toqueMinimo + AppSpacing.xs * 2,
                  leading: const Padding(
                    padding: EdgeInsets.only(left: AppSpacing.xs),
                    child: Center(child: _BotaoVoltar()),
                  ),
                  backgroundColor: usaImpacto ? AppColors.impactoAgua : fundoHero,
                  surfaceTintColor: Colors.transparent,
                  flexibleSpace: FlexibleSpaceBar(
                    background: usaImpacto
                        ? CenaImpactoAgua(
                            // Fundo + respingo iguais; só a garrafa muda por SKU.
                            key: ValueKey('impacto-${p.codigo}'),
                            garrafaAsset: asset,
                            fullBleed: true,
                            mostrarCopyMarca: usaCopyImpactoMineral(p.codigo),
                            rotuloSemantico: PdpCopy.altFoto(p),
                          )
                        : ColoredBox(
                            color: fundoHero,
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.secao),
                              child: Image.asset(
                                asset,
                                fit: BoxFit.contain,
                                semanticLabel: PdpCopy.altFoto(p),
                              ),
                            ),
                          ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.margem,
                    AppSpacing.margem,
                    AppSpacing.margem,
                    AppSpacing.secao,
                  ),
                  sliver: SliverList.list(
                    children: [
                      // P2.2/P2.3: título Inter 600 28 heroInk, sem rótulo duplicado.
                      Semantics(
                        header: true,
                        child: Text(
                          PdpCopy.titulo(p),
                          key: const ValueKey('pdp-titulo'),
                          style: AppTypography.title1.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.heroInk,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(PdpCopy.embalagem(p), style: apoio),
                      const SizedBox(height: AppSpacing.sm),
                      // P2.4: preço por garrafa + caixa sob o título (valor de referência).
                      Text.rich(
                        key: const ValueKey('pdp-preco'),
                        TextSpan(
                          children: [
                            TextSpan(
                              text: unitario.formatado,
                              style: AppTypography.title3.copyWith(
                                color: AppColors.heroInk,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(
                              text: p.embalagemQtd > 1 ? ' /garrafa' : ' /un.',
                              style: apoio,
                            ),
                            if (p.embalagemQtd > 1)
                              TextSpan(
                                text:
                                    '  ·  caixa com ${p.embalagemQtd} ≈ '
                                    '${Dinheiro(unitario.centavos * p.embalagemQtd).formatado}',
                                style: apoio,
                              ),
                          ],
                        ),
                      ),
                      if (avulso != null) ...[
                        const SizedBox(height: AppSpacing.xxs),
                        Text(avulso, key: const ValueKey('pdp-avulso'), style: apoio),
                      ],
                      if (p.esgotado) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Esgotado no momento',
                          key: const ValueKey('pdp-esgotado'),
                          style: AppTypography.headline.copyWith(color: AppColors.alerta),
                        ),
                      ],
                      if (chips.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [for (final c in chips) _chip(c)],
                        ),
                      ],
                      if (p.descricao != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          p.descricao!,
                          style: AppTypography.body.copyWith(color: AppColors.tinta),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.secao),
                      // Quantidade + nota de mistura num card branco raio 28.
                      if (!soAviseMe)
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.margem),
                          decoration: BoxDecoration(
                            color: AppColors.superficie,
                            borderRadius: BorderRadius.circular(AppSpacing.raioBlocoProduto),
                            border: Border.all(color: AppColors.linha),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Quantidade por entrega',
                                style: AppTypography.headline.copyWith(color: AppColors.heroInk),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Row(
                                children: [
                                  _BotaoQtd(
                                    icone: Icons.remove,
                                    rotulo: 'Diminuir quantidade',
                                    habilitado: !noMinimo,
                                    destaque: false,
                                    onTap: () => setState(() => _qtd = qtd - passo),
                                  ),
                                  Expanded(
                                    child: Semantics(
                                      container: true,
                                      liveRegion: true,
                                      label: 'Quantidade: $rotuloQtd',
                                      excludeSemantics: true,
                                      child: Text(
                                        rotuloQtd,
                                        key: const ValueKey('pdp-qtd'),
                                        textAlign: TextAlign.center,
                                        style: AppTypography.headline.copyWith(
                                          color: AppColors.heroInk,
                                          fontFeatures: const [FontFeature.tabularFigures()],
                                        ),
                                      ),
                                    ),
                                  ),
                                  _BotaoQtd(
                                    icone: Icons.add,
                                    rotulo: 'Aumentar quantidade',
                                    habilitado: !noTeto,
                                    destaque: true,
                                    onTap: () => setState(() => _qtd = qtd + passo),
                                  ),
                                ],
                              ),
                              if (SacolaController.caixaMista.contains(p.codigo)) ...[
                                const SizedBox(height: AppSpacing.sm),
                                // P2.3: explica o passo de meia caixa sem “corrigir” para 6.
                                Text(
                                  'Você pode montar a caixa de ${p.embalagemQtd} com Water Protein '
                                  'e Flow Fiber — por isso a quantidade anda de $passo em $passo.',
                                  key: const ValueKey('pdp-mistura'),
                                  style: apoio,
                                ),
                              ],
                            ],
                          ),
                        ),
                      const SizedBox(height: AppSpacing.margem),
                      // P2.4: frequência / frete no próximo passo.
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.local_shipping_outlined,
                              size: 18,
                              color: AppColors.heroNavy,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              'Frequência e plano você escolhe na sacola. '
                              '${SacolaCopy.freteGratisAcima(sim?.freteGratisAcima ?? kFreteGratisAcimaPadrao)}.',
                              key: const ValueKey('pdp-proximo-passo'),
                              style: apoio,
                            ),
                          ),
                        ],
                      ),
                      if (tabela != null) ...[
                        const SizedBox(height: AppSpacing.secao),
                        _TabelaNutricional(tabela: tabela),
                      ],
                      const SizedBox(height: AppSpacing.margem),
                      // Tabela só com dados da API; o resto do rótulo segue na embalagem (DECISOES).
                      Text(
                        tabela != null
                            ? 'Ingredientes e alergênicos: consulte o rótulo da embalagem. '
                                  'Em caso de diferença, vale o rótulo.'
                            : funcional
                            ? 'Tabela nutricional, ingredientes e alergênicos: '
                                  'consulte o rótulo da embalagem.'
                            : 'Consulte o rótulo para informações completas.',
                        style: apoio,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // P2.2: rodapé branco + borda 1 px; CTA heroNavy raio 14 com R$ da qty local.
          DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.superficie,
              border: Border(top: BorderSide(color: AppColors.linha)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.margem,
                  AppSpacing.sm,
                  AppSpacing.margem,
                  AppSpacing.sm,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: soAviseMe
                      ? [
                          BotaoPrincipal(
                            key: const ValueKey('pdp-avise-me'),
                            variante: VarianteBotaoPrincipal.cta,
                            rotulo: 'Avise-me quando voltar',
                            onPressed: () => abrirFolhaListaEspera(context, produto: p),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            'Entramos em contato por e-mail quando houver estoque.',
                            textAlign: TextAlign.center,
                            style: AppTypography.footnote.copyWith(color: AppColors.textoSuave),
                          ),
                        ]
                      : [
                          BotaoPrincipal(
                            key: const ValueKey('pdp-cta'),
                            variante: VarianteBotaoPrincipal.cta,
                            rotulo: PdpCopy.cta(naSacola: naSacola, valor: valorItem),
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              sacola.alterar(p.codigo, qtd);
                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      naSacola ? 'Quantidade atualizada' : 'Adicionado à sacola',
                                    ),
                                    action: SnackBarAction(
                                      label: 'Ver sacola',
                                      onPressed: () =>
                                          Navigator.of(context).pushNamed(AppRoutes.sacola),
                                    ),
                                  ),
                                );
                            },
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            'Valor deste item; descontos e entrega são calculados na sacola.',
                            textAlign: TextAlign.center,
                            style: AppTypography.footnote.copyWith(color: AppColors.textoSuave),
                          ),
                        ],
                ),
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
    child: Text(t, style: AppTypography.footnote.copyWith(color: AppColors.navy)),
  );
}

/// Tabela nutricional exatamente como a API manda (porção + linhas); nada calculado aqui.
class _TabelaNutricional extends StatelessWidget {
  const _TabelaNutricional({required this.tabela});

  final TabelaNutricional tabela;

  @override
  Widget build(BuildContext context) {
    final valor = AppTypography.subheadline.copyWith(
      color: AppColors.heroInk,
      fontWeight: FontWeight.w600,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Container(
      key: const ValueKey('pdp-tabela-nutricional'),
      padding: const EdgeInsets.all(AppSpacing.margem),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(AppSpacing.raioBlocoProduto),
        border: Border.all(color: AppColors.linha),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              'Tabela nutricional',
              style: AppTypography.headline.copyWith(color: AppColors.heroInk),
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Porção de ${tabela.porcao}',
            style: AppTypography.footnote.copyWith(color: AppColors.textoSuave),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (var i = 0; i < tabela.linhas.length; i++) ...[
            if (i > 0) const Divider(height: 1, thickness: 0.5, color: AppColors.linha),
            MergeSemantics(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        tabela.linhas[i].nutriente,
                        style: AppTypography.subheadline.copyWith(color: AppColors.tinta),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(tabela.linhas[i].valor, style: valor),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Voltar: círculo branco 40 visível, alvo 48 (P2.1) — legível sobre o céu claro do hero.
class _BotaoVoltar extends StatelessWidget {
  const _BotaoVoltar();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Voltar',
      excludeSemantics: true,
      child: InkResponse(
        radius: AppSpacing.toqueMinimo / 2,
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.of(context).maybePop();
        },
        child: SizedBox(
          key: const ValueKey('pdp-voltar'),
          width: AppSpacing.toqueMinimo,
          height: AppSpacing.toqueMinimo,
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.superficie,
                shape: BoxShape.circle,
                boxShadow: AppSombras.cardGrade,
              ),
              child: const Icon(Icons.arrow_back, color: AppColors.heroInk, size: 22),
            ),
          ),
        ),
      ),
    );
  }
}

/// “−”/“+” 48 dp; desabilitado fica a 40% (mínimo / teto). Semantics próprios (P2.4).
class _BotaoQtd extends StatelessWidget {
  const _BotaoQtd({
    required this.icone,
    required this.rotulo,
    required this.habilitado,
    required this.destaque,
    required this.onTap,
  });

  final IconData icone;
  final String rotulo;
  final bool habilitado;
  final bool destaque;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fundo = destaque ? AppColors.heroNavy : AppColors.gelo;
    final frente = destaque ? AppColors.sobrePrimaria : AppColors.heroInk;
    return Semantics(
      button: true,
      enabled: habilitado,
      label: rotulo,
      excludeSemantics: true,
      child: Opacity(
        opacity: habilitado ? 1 : 0.4,
        child: Material(
          color: fundo,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: habilitado
                ? () {
                    HapticFeedback.selectionClick();
                    onTap();
                  }
                : null,
            child: SizedBox(
              width: AppSpacing.toqueMinimo,
              height: AppSpacing.toqueMinimo,
              child: Icon(icone, color: frente),
            ),
          ),
        ),
      ),
    );
  }
}
