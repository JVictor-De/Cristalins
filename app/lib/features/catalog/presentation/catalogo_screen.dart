import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/dependencias.dart';
import '../../../core/formatacao.dart';
import '../../../core/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/botao_principal.dart';
import '../../../core/widgets/controle_segmentado.dart';
import '../../../core/widgets/controles.dart';
import '../../../core/widgets/estados.dart';
import '../../../core/widgets/secao_agrupada.dart';
import '../../../core/widgets/tela_titulo_grande.dart';
import '../../subscription/domain/assinatura.dart';
import '../domain/catalogo.dart';
import 'cesta_controller.dart';

/// Tela 5 — Catálogo e cesta. Recebe um [PedidoAssinatura] (fluxo novo) ou uma [AlteracaoDeCesta] (Tela 8).
class CatalogoScreen extends StatelessWidget {
  const CatalogoScreen({super.key, this.pedido, this.alteracao});

  final PedidoAssinatura? pedido;
  final AlteracaoDeCesta? alteracao;

  @override
  Widget build(BuildContext context) {
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
      child: _Conteudo(pedido: pedido),
    );
  }
}

class _Conteudo extends StatelessWidget {
  const _Conteudo({this.pedido});

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
    final titulo = c.assinaturaId == null ? 'Sua cesta' : 'Alterar cesta';

    if (c.carregando) {
      return TelaTituloGrande(
        titulo: titulo,
        slivers: const [SliverFillRemaining(hasScrollBody: false, child: Carregando())],
      );
    }
    if (c.erroCarregar != null) {
      return TelaTituloGrande(
        titulo: titulo,
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: EstadoErro(mensagem: c.erroCarregar!, onTentarDeNovo: c.carregar),
          ),
        ],
      );
    }

    final margem = margemDaTela(context);
    return TelaTituloGrande(
      titulo: titulo,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(margem, AppSpacing.xs, margem, 0),
            child: ControleSegmentado<Categoria>(
              opcoes: {for (final cat in Categoria.values) cat: cat.rotulo},
              valor: c.categoria,
              onEscolher: c.escolherCategoria,
            ),
          ),
        ),
        if (c.categoria == Categoria.todos && c.kits.isNotEmpty)
          SliverToBoxAdapter(
            child: SecaoAgrupada(
              cabecalho: 'Kits prontos',
              rodape: 'Toque em um kit para trocar a cesta inteira por ele.',
              children: [
                for (final k in c.kits)
                  LinhaLista(
                    titulo: k.nome,
                    subtitulo:
                        '${k.itens.map((i) => '${i.quantidade} ${i.produto}').join(' + ')} · ${k.subtotalBase.formatado} sem descontos',
                    trailing: const CupertinoListTileChevron(),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      c.usarKit(k);
                    },
                  ),
              ],
            ),
          ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(margem, AppSpacing.secao, margem, 0),
          sliver: SliverList.separated(
            itemCount: c.visiveis.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (_, i) => _CardProduto(produto: c.visiveis[i]),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(margem, AppSpacing.sm, margem, 0),
            child: Text(
              'Water Protein e Flow Fiber dividem a caixa de 6: a soma dos dois fecha caixas de 6. '
              'As águas vêm na embalagem de venda.',
              style: AppTypography.footnote.copyWith(color: AppColors.textoSecundario),
            ),
          ),
        ),
        SliverToBoxAdapter(child: _Resumo(controller: c)),
      ],
      rodape: BotaoPrincipal(
        rotulo: c.assinaturaId == null ? 'Continuar' : 'Salvar cesta',
        carregando: c.salvando,
        onPressed: c.podeContinuar ? () => _confirmar(context, c) : null,
      ),
    );
  }
}

/// Card de produto: imagem 1:1, rótulo do tipo, nome, volume, preço e seletor (Anexo).
class _CardProduto extends StatelessWidget {
  const _CardProduto({required this.produto});

  final Produto produto;

  @override
  Widget build(BuildContext context) {
    final c = context.watch<CestaController>();
    final quantidade = c.quantidades[produto.codigo] ?? 0;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(AppSpacing.raioCelula),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sem fotos da marca no repositório: ícone no lugar da imagem 1:1.
              Container(
                width: AppSpacing.imagemProduto,
                height: AppSpacing.imagemProduto,
                decoration: BoxDecoration(
                  color: AppColors.azul50,
                  borderRadius: BorderRadius.circular(AppSpacing.raioCelula),
                ),
                child: const Icon(
                  CupertinoIcons.drop,
                  size: AppSpacing.iconeProduto,
                  color: AppColors.azul700,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      produto.rotuloTipo,
                      style: AppTypography.caption1.copyWith(color: AppColors.textoSecundario),
                    ),
                    Text(
                      produto.nome,
                      style: AppTypography.headline.copyWith(color: AppColors.texto),
                    ),
                    Text(
                      '${produto.volume} · ${produto.embalagem}',
                      style: AppTypography.subheadline.copyWith(color: AppColors.textoSecundario),
                    ),
                    Text(
                      '${produto.precoBase.formatado} por unidade',
                      style: AppTypography.subheadline.copyWith(
                        color: AppColors.texto,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
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
    );
  }
}

class _Resumo extends StatelessWidget {
  const _Resumo({required this.controller});

  final CestaController controller;

  @override
  Widget build(BuildContext context) {
    final s = controller.simulacao;
    final valor = AppTypography.body.copyWith(
      color: AppColors.texto,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return SecaoAgrupada(
      cabecalho: 'Resumo da cesta',
      rodape:
          controller.erroSimulacao ??
          'Preço no plano Flex, sem a taxa de entrega. O plano e o frete entram na próxima etapa.',
      rodapeErro: controller.erroSimulacao != null,
      children: [
        if (controller.simulando)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.margem),
            child: CupertinoActivityIndicator(),
          )
        else if (s != null) ...[
          LinhaLista(
            titulo: 'Unidades equivalentes',
            trailing: Text('${s.ue}', style: valor),
          ),
          for (final l in s.detalhe.where((l) => l.fator != 'FRETE'))
            LinhaLista(
              titulo: l.rotulo,
              trailing: Text(l.valorFormatado, style: valor),
            ),
          LinhaLista(
            titulo: 'Total estimado',
            trailing: Text(
              s.total.formatado,
              style: AppTypography.headline.copyWith(color: AppColors.texto),
            ),
          ),
        ] else
          const LinhaLista(titulo: 'Ajuste a cesta para ver o preço.'),
      ],
    );
  }
}
