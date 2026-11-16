import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/dependencias.dart';
import '../../../core/formatacao.dart';
import '../../../core/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/botao_principal.dart';
import '../../../core/widgets/controles.dart';
import '../../../core/widgets/estado_vazio.dart';
import '../../../core/widgets/estados.dart';
import '../../../core/widgets/secao_agrupada.dart';
import '../../../core/widgets/tela_titulo_grande.dart';
import '../../address/domain/endereco.dart';
import '../../ocorrencias/presentation/ocorrencia_screen.dart';
import '../../quiz/domain/quiz.dart';
import '../domain/assinatura.dart';
import 'faturas_screen.dart';
import 'minha_assinatura_controller.dart';

/// Tela 8 — Minha assinatura.
class MinhaAssinaturaScreen extends StatelessWidget {
  const MinhaAssinaturaScreen({super.key, this.assinaturaId});

  final String? assinaturaId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MinhaAssinaturaController(
        context.read<Dependencias>().assinaturas,
        assinaturaId: assinaturaId,
      ),
      child: const _Conteudo(),
    );
  }
}

class _Conteudo extends StatelessWidget {
  const _Conteudo();

  static const titulo = 'Minha assinatura';

  Future<void> _resultado(
    BuildContext context,
    String? erro,
    String sucesso, {
    bool impactoMedio = false,
  }) async {
    if (!context.mounted) return;
    if (erro != null) {
      mostrarAviso(context, erro, erro: true);
    } else {
      impactoMedio ? HapticFeedback.mediumImpact() : HapticFeedback.lightImpact();
      mostrarAviso(context, sucesso);
    }
  }

  Future<void> _alternarPausa(
    BuildContext context,
    MinhaAssinaturaController c,
    bool pausar,
  ) async {
    HapticFeedback.selectionClick();
    if (!pausar) {
      final erro = await c.retomar();
      if (context.mounted) {
        await _resultado(context, erro, 'Entregas retomadas.', impactoMedio: true);
      }
      return;
    }
    final quantidade = await showCupertinoModalPopup<int>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Pausar entregas'),
        message: const Text('Você pode pausar até 2 entregas seguidas e 4 por ano.'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, 1),
            child: const Text('Pausar a próxima entrega'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, 2),
            child: const Text('Pausar as próximas 2 entregas'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Voltar'),
        ),
      ),
    );
    if (quantidade == null) return;
    final erro = await c.pausar(quantidade);
    if (context.mounted) {
      await _resultado(
        context,
        erro,
        quantidade == 1 ? 'Próxima entrega pausada.' : '2 entregas pausadas.',
      );
    }
  }

  Future<void> _pular(BuildContext context, MinhaAssinaturaController c) async {
    HapticFeedback.selectionClick();
    final data = c.assinatura?.proximaEntrega;
    final confirmar = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Pular a próxima entrega?'),
        content: Text(
          data == null
              ? 'Essa entrega não será cobrada.'
              : 'A entrega de ${Datas.curta(data)} não será feita nem cobrada.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Manter'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Pular entrega'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    final erro = await c.pular();
    if (context.mounted) await _resultado(context, erro, 'Entrega pulada.');
  }

  Future<void> _cancelar(BuildContext context, MinhaAssinaturaController c) async {
    HapticFeedback.selectionClick();
    final confirmar = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Cancelar assinatura?'),
        message: const Text('As entregas já pagas continuam agendadas.'),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancelar assinatura'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Manter assinatura'),
        ),
      ),
    );
    if (confirmar != true) return;
    final (resultado, erro) = await c.cancelar();
    final diferenca = resultado?.diferencaCompromisso;
    final texto = diferenca == null || diferenca.centavos == 0
        ? 'Assinatura cancelada.'
        : 'Assinatura cancelada. Pelo compromisso do plano, fica a diferença de ${diferenca.formatado}.';
    if (context.mounted) await _resultado(context, erro, texto);
  }

  Future<void> _alterarCesta(BuildContext context, MinhaAssinaturaController c) async {
    HapticFeedback.lightImpact();
    final a = c.assinatura!;
    final alterou = await Navigator.of(context).pushNamed(
      AppRoutes.catalogo,
      arguments: AlteracaoDeCesta(
        assinaturaId: a.id,
        itens: a.itens,
        frequencia: a.frequencia,
        plano: a.plano,
      ),
    );
    if (alterou == true) await c.carregar();
  }

  Future<void> _whatsapp(BuildContext context, String numero) async {
    HapticFeedback.selectionClick();
    final digitos = numero.replaceAll(RegExp(r'\D'), '');
    final texto = Uri.encodeComponent('Olá! Preciso de ajuda com a minha assinatura Cristalins.');
    final abriu = await context.read<Dependencias>().links.abrir(
      'https://wa.me/$digitos?text=$texto',
    );
    if (!abriu && context.mounted) {
      mostrarAviso(context, 'Não conseguimos abrir o WhatsApp agora.', erro: true);
    }
  }

  Future<void> _sair(BuildContext context) async {
    HapticFeedback.selectionClick();
    await context.read<Dependencias>().auth.sair();
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.boasVindas, (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<MinhaAssinaturaController>();
    final sair = CupertinoButton(
      minimumSize: const Size(AppSpacing.toqueMinimo, AppSpacing.toqueMinimo),
      padding: EdgeInsets.zero,
      onPressed: () => _sair(context),
      child: Text('Sair', style: AppTypography.body.copyWith(color: AppColors.azul800)),
    );

    if (c.carregando && c.assinatura == null) {
      return TelaTituloGrande(
        titulo: titulo,
        voltar: false,
        acaoNaBarra: sair,
        slivers: const [SliverFillRemaining(hasScrollBody: false, child: Carregando())],
      );
    }
    if (c.erro != null) {
      return TelaTituloGrande(
        titulo: titulo,
        voltar: false,
        acaoNaBarra: sair,
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: EstadoErro(mensagem: c.erro!, onTentarDeNovo: c.carregar),
          ),
        ],
      );
    }
    final a = c.assinatura;
    if (a == null) {
      return TelaTituloGrande(
        titulo: titulo,
        voltar: false,
        acaoNaBarra: sair,
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: EstadoVazio(
              icone: CupertinoIcons.cube_box,
              mensagem: 'Você ainda não tem assinatura. Que tal começar pelo quiz?',
              rotuloAcao: 'Fazer o quiz',
              onAcao: () => Navigator.of(context).pushNamed(AppRoutes.quiz),
            ),
          ),
        ],
      );
    }

    final selo = seloDoStatus(a.status);
    final proximo = c.proximoCiclo;
    final numero = context.read<AppConfig>().suporteWhatsapp;
    final secundario = AppTypography.body.copyWith(color: AppColors.textoSecundario);
    final podeAlterar = !a.cancelada && !c.executando;

    return TelaTituloGrande(
      titulo: titulo,
      voltar: false,
      acaoNaBarra: sair,
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              SecaoAgrupada(
                cabecalho: 'Assinatura',
                rodape: a.aguardandoPagamento
                    ? 'Estamos aguardando o pagamento do primeiro ciclo por Pix. A data da entrega é confirmada depois do pagamento.'
                    : (a.fimCompromisso != null && a.plano != 'FLEX'
                          ? 'Compromisso até ${Datas.curta(a.fimCompromisso!)}.'
                          : null),
                children: [
                  LinhaLista(
                    titulo: 'Status',
                    trailing: Selo(texto: selo.texto, fundo: selo.fundo, cor: selo.cor),
                  ),
                  LinhaLista(
                    titulo: 'Plano',
                    trailing: Text(a.rotuloPlano, style: secundario),
                  ),
                  LinhaLista(
                    titulo: 'Entrega',
                    trailing: Text(rotuloFrequencia(a.frequencia), style: secundario),
                  ),
                  LinhaLista(
                    titulo: 'Endereço',
                    subtitulo: '${a.bairro} · ${a.zona} · ${JanelaEntrega.de(a.janela).rotulo}',
                  ),
                ],
              ),
              if (a.proximaEntrega != null)
                SecaoAgrupada(
                  cabecalho: 'Próxima entrega',
                  rodape: proximo == null
                      ? null
                      : 'Alterações e pulos até ${Datas.instante(proximo.dataCorte)}.',
                  children: [
                    LinhaLista(
                      titulo: Datas.comDiaDaSemana(a.proximaEntrega!),
                      icone: CupertinoIcons.calendar,
                      trailing: proximo?.valor == null
                          ? null
                          : Text(proximo!.valor!.formatado, style: secundario),
                    ),
                    if (a.ativa)
                      LinhaLista(
                        titulo: 'Pular a próxima entrega',
                        corTitulo: AppColors.linkSobreSuperficie,
                        onTap: c.executando ? null : () => _pular(context, c),
                      ),
                  ],
                ),
              if (a.ativa || a.pausada)
                SecaoAgrupada(
                  rodape: a.pausada
                      ? 'Desligue para voltar a receber.'
                      : 'Até 2 entregas seguidas e 4 por ano.',
                  children: [
                    MergeSemantics(
                      child: LinhaLista(
                        titulo: 'Pausar entregas',
                        trailing: CupertinoSwitch(
                          value: a.pausada,
                          activeTrackColor: AppColors.azul800,
                          onChanged: c.executando ? null : (v) => _alternarPausa(context, c, v),
                        ),
                      ),
                    ),
                  ],
                ),
              SecaoAgrupada(
                cabecalho: 'Sua cesta',
                children: [
                  for (final i in a.itens)
                    LinhaLista(
                      titulo: nomeDoProduto(i.produto),
                      trailing: Text('${i.quantidade}', style: secundario),
                    ),
                ],
              ),
              if (c.ciclos.isNotEmpty)
                SecaoAgrupada(
                  cabecalho: 'Entregas',
                  rodape: 'Nas entregues, informe avaria ou falta em até 24 horas.',
                  children: [
                    for (final ciclo in c.ciclos.reversed.take(6))
                      LinhaLista(
                        titulo: Datas.comDiaDaSemana(ciclo.dataEntrega),
                        subtitulo: ciclo.status == 'ENTREGUE'
                            ? '${rotuloStatusCiclo(ciclo.status, ciclo.motivoPulo)} · Informar problema'
                            : rotuloStatusCiclo(ciclo.status, ciclo.motivoPulo),
                        trailing: ciclo.status == 'ENTREGUE'
                            ? const CupertinoListTileChevron()
                            : (ciclo.valor == null
                                ? null
                                : Text(ciclo.valor!.formatado, style: secundario)),
                        onTap: ciclo.status == 'ENTREGUE'
                            ? () {
                                HapticFeedback.selectionClick();
                                Navigator.of(context).push(rotaOcorrencia(ciclo));
                              }
                            : null,
                      ),
                  ],
                ),
              SecaoAgrupada(
                cabecalho: 'Pagamento',
                children: [
                  LinhaLista(
                    titulo: 'Faturas e forma de pagamento',
                    icone: CupertinoIcons.creditcard,
                    trailing: const CupertinoListTileChevron(),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.of(context).push(rotaFaturas(a.id));
                    },
                  ),
                ],
              ),
              SecaoAgrupada(
                cabecalho: 'Ajuda',
                rodape: numero.isEmpty
                    ? 'O número de suporte ainda não foi configurado neste aplicativo.'
                    : null,
                children: [
                  LinhaLista(
                    titulo: 'Falar com o suporte no WhatsApp',
                    icone: CupertinoIcons.chat_bubble_2,
                    corTitulo: numero.isEmpty
                        ? AppColors.textoSecundario
                        : AppColors.linkSobreSuperficie,
                    trailing: numero.isEmpty
                        ? null
                        : const Icon(
                            CupertinoIcons.arrow_up_right,
                            color: AppColors.linkSobreSuperficie,
                            size: AppSpacing.icone,
                          ),
                    onTap: numero.isEmpty
                        ? () => mostrarAviso(
                            context,
                            'O número de suporte ainda não foi configurado.',
                          )
                        : () => _whatsapp(context, numero),
                  ),
                ],
              ),
              if (!a.cancelada)
                BotaoSecundario(
                  rotulo: 'Cancelar assinatura',
                  destrutivo: true,
                  onPressed: c.executando ? null : () => _cancelar(context, c),
                ),
            ],
          ),
        ),
      ],
      rodape: a.cancelada
          ? BotaoPrincipal(
              rotulo: 'Assinar de novo',
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.quiz),
            )
          : BotaoPrincipal(
              rotulo: 'Alterar cesta',
              carregando: c.executando,
              onPressed: podeAlterar ? () => _alterarCesta(context, c) : null,
            ),
    );
  }
}
