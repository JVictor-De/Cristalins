import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/dependencias.dart';
import '../../../core/formatacao.dart';
import '../../../core/intents/navegacao_nativa.dart';
import '../../../core/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/botao_principal.dart';
import '../../../core/widgets/controle_segmentado.dart';
import '../../../core/widgets/estados.dart';
import '../../../core/widgets/secao_agrupada.dart';
import '../../../core/widgets/tela_titulo_grande.dart';
import '../../quiz/domain/quiz.dart';
import '../domain/assinatura.dart';
import 'aguardando_pagamento_screen.dart';
import 'plano_pagamento_controller.dart';

/// Tela 7 — Plano e pagamento. Pix só; o QR Code chega em `cr-3-tela`.
class PlanoPagamentoScreen extends StatelessWidget {
  const PlanoPagamentoScreen({super.key, required this.pedido});

  final PedidoAssinatura pedido;

  @override
  Widget build(BuildContext context) {
    final dep = context.read<Dependencias>();
    return ChangeNotifierProvider(
      create: (_) => PlanoPagamentoController(dep.catalogo, dep.assinaturas, pedido),
      child: const _Conteudo(),
    );
  }
}

class _Conteudo extends StatefulWidget {
  const _Conteudo();

  @override
  State<_Conteudo> createState() => _ConteudoState();
}

class _ConteudoState extends State<_Conteudo> {
  final _cupom = TextEditingController();

  @override
  void dispose() {
    _cupom.dispose();
    super.dispose();
  }

  Future<void> _assinar(PlanoPagamentoController c) async {
    HapticFeedback.lightImpact();
    final criada = await c.assinar();
    if (!mounted) return;
    if (criada == null) {
      mostrarAviso(
        context,
        c.erro ?? 'Não conseguimos criar a assinatura. Tente de novo.',
        erro: true,
      );
      return;
    }
    // Com Pix: tela de espera (QR + copia e cola) até a API ativar; o mediumImpact fica para a ativação.
    if (criada.pix != null) {
      mostrarAviso(context, 'Assinatura criada. Falta só o pagamento por Pix.');
      Navigator.of(context).pushAndRemoveUntil(rotaAguardandoPagamento(criada), (_) => false);
      return;
    }
    mostrarAviso(
      context,
      'Assinatura criada. Primeira entrega prevista para ${Datas.curta(criada.dataEntrega)}, depois do pagamento por Pix.',
    );
    await NavegacaoNativa.instancia.abrir(
      context,
      activity: NavegacaoNativa.minhaAssinatura,
      rota: AppRoutes.minhaAssinatura,
      arguments: criada.id,
      extras: {'assinaturaId': criada.id},
      limparPilha: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<PlanoPagamentoController>();
    final margem = margemDaTela(context);
    final pedido = c.pedido;
    final s = c.simulacao;
    final valor = AppTypography.body.copyWith(
      color: AppColors.texto,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    Widget segmentos(Map<String, String> opcoes, String atual, ValueChanged<String> aoEscolher) =>
        Padding(
          padding: EdgeInsets.fromLTRB(margem, AppSpacing.xs, margem, 0),
          child: ControleSegmentado<String>(opcoes: opcoes, valor: atual, onEscolher: aoEscolher),
        );

    Widget rotulo(String texto) => Padding(
      padding: EdgeInsets.fromLTRB(margem + AppSpacing.margem, AppSpacing.secao, margem, 0),
      child: Text(texto, style: AppTypography.footnote.copyWith(color: AppColors.textoSecundario)),
    );

    return TelaTituloGrande(
      titulo: 'Plano e pagamento',
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              rotulo('Frequência de entrega'),
              segmentos(
                const {'SEMANAL': 'Semanal', 'QUINZENAL': 'Quinzenal', 'MENSAL': 'Mensal'},
                pedido.frequencia,
                c.escolherFrequencia,
              ),
              rotulo('Plano'),
              segmentos(
                const {'FLEX': 'Flex', 'TRIMESTRAL': 'Trimestral'},
                c.plano,
                c.escolherPlano,
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(margem + AppSpacing.margem, AppSpacing.xs, margem, 0),
                child: Text(
                  c.plano == 'FLEX'
                      ? 'Flex: sem fidelidade, cancele quando quiser.'
                      : 'Trimestral: 3 meses de compromisso com desconto. Cancelar antes do prazo cobra a diferença do desconto.',
                  style: AppTypography.footnote.copyWith(color: AppColors.textoSecundario),
                ),
              ),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: Column(
            children: [
              SecaoAgrupada(
                cabecalho: 'Entrega',
                children: [
                  LinhaLista(
                    titulo: pedido.endereco?.apelido ?? 'Endereço',
                    subtitulo: pedido.endereco == null
                        ? null
                        : '${pedido.endereco!.linha} · ${pedido.endereco!.bairro}',
                    icone: CupertinoIcons.location,
                  ),
                  LinhaLista(titulo: pedido.janela.rotulo, icone: CupertinoIcons.time),
                ],
              ),
              SecaoAgrupada(
                cabecalho: 'Cupom',
                rodape: c.cupom.isEmpty
                    ? 'Tem um cupom? Aplique antes de assinar.'
                    : 'Cupom ${c.cupom} aplicado no resumo.',
                children: [
                  CupertinoTextFormFieldRow(
                    controller: _cupom,
                    placeholder: 'Código do cupom (opcional)',
                    placeholderStyle: AppTypography.body.copyWith(color: AppColors.textoSecundario),
                    style: AppTypography.body.copyWith(color: AppColors.texto),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.margem,
                      vertical: AppSpacing.sm,
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  LinhaLista(
                    titulo: 'Aplicar cupom',
                    corTitulo: AppColors.linkSobreSuperficie,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      c.aplicarCupom(_cupom.text);
                    },
                  ),
                ],
              ),
              SecaoAgrupada(
                cabecalho: 'Resumo por entrega',
                rodape: c.erro ?? 'Valores calculados para a data prevista da entrega.',
                rodapeErro: c.erro != null,
                children: [
                  if (c.simulando)
                    const Padding(
                      padding: EdgeInsets.all(AppSpacing.margem),
                      child: CupertinoActivityIndicator(),
                    )
                  else if (s != null) ...[
                    for (final i in s.itens)
                      LinhaLista(
                        titulo: '${i.quantidade} × ${nomeDoProduto(i.produto)}',
                        trailing: Text(i.precoUnitario.formatado, style: valor),
                      ),
                    LinhaLista(
                      titulo: 'Subtotal',
                      trailing: Text(s.subtotal.formatado, style: valor),
                    ),
                    for (final l in s.detalhe)
                      LinhaLista(
                        titulo: l.rotulo,
                        trailing: Text(l.valorFormatado, style: valor),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.margem),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              'Total',
                              style: AppTypography.headline.copyWith(color: AppColors.texto),
                            ),
                          ),
                          Flexible(
                            child: Text(
                              s.total.formatado,
                              textAlign: TextAlign.end,
                              style: AppTypography.title1.copyWith(
                                color: AppColors.texto,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else
                    LinhaLista(
                      titulo: 'Tentar de novo',
                      corTitulo: AppColors.linkSobreSuperficie,
                      onTap: c.simular,
                    ),
                ],
              ),
              const SecaoAgrupada(
                cabecalho: 'Pagamento',
                rodape: 'A cada entrega, você recebe uma cobrança por Pix.',
                children: [LinhaLista(titulo: 'Pix', icone: CupertinoIcons.qrcode)],
              ),
            ],
          ),
        ),
      ],
      rodape: BotaoPrincipal(
        rotulo: 'Assinar agora',
        carregando: c.assinando,
        onPressed: s == null || c.simulando || pedido.endereco == null ? null : () => _assinar(c),
      ),
    );
  }
}
