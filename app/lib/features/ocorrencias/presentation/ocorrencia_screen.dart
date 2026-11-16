import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/dependencias.dart';
import '../../../core/formatacao.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/botao_principal.dart';
import '../../../core/widgets/controle_segmentado.dart';
import '../../../core/widgets/controles.dart';
import '../../../core/widgets/estados.dart';
import '../../../core/widgets/secao_agrupada.dart';
import '../../../core/widgets/tela_titulo_grande.dart';
import '../../quiz/domain/quiz.dart';
import '../../subscription/domain/assinatura.dart';
import '../domain/ocorrencia.dart';
import 'ocorrencia_controller.dart';

Route<void> rotaOcorrencia(Ciclo ciclo) => MaterialPageRoute<void>(
  builder: (_) => OcorrenciaScreen(pedido: PedidoOcorrencia(ciclo: ciclo)),
  settings: const RouteSettings(name: '/ocorrencia'),
);

/// Informe avaria ou falta (foto + reposição ou crédito), até 24 h da entrega.
class OcorrenciaScreen extends StatelessWidget {
  const OcorrenciaScreen({super.key, required this.pedido});

  final PedidoOcorrencia pedido;

  @override
  Widget build(BuildContext context) {
    final dep = context.read<Dependencias>();
    return ChangeNotifierProvider(
      create: (_) => OcorrenciaController(dep.ocorrencias, pedido.ciclo),
      child: const _Conteudo(),
    );
  }
}

class _Conteudo extends StatelessWidget {
  const _Conteudo();

  Future<void> _foto(BuildContext context, OcorrenciaController c) async {
    // Na web a câmera nativa é limitada; prioriza arquivo/galeria.
    if (kIsWeb) {
      HapticFeedback.selectionClick();
      await c.escolherFoto(ImageSource.gallery);
      return;
    }
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Foto do problema'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              HapticFeedback.selectionClick();
              c.escolherFoto(ImageSource.camera);
            },
            child: const Text('Tirar foto'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              HapticFeedback.selectionClick();
              c.escolherFoto(ImageSource.gallery);
            },
            child: const Text('Escolher da galeria'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar'),
        ),
      ),
    );
  }

  Future<void> _enviar(BuildContext context, OcorrenciaController c) async {
    HapticFeedback.lightImpact();
    final r = await c.enviar();
    if (!context.mounted) return;
    if (c.erro != null) {
      mostrarAviso(context, c.erro!, erro: true);
      return;
    }
    if (r == null) return;
    HapticFeedback.mediumImpact();
    final msg = r.solucao == 'CREDITO' && r.credito != null
        ? 'Registramos. O crédito de ${Dinheiro.daApi(r.credito!).formatado} já está na sua conta.'
        : 'Registramos. A reposição vai na próxima entrega.';
    await showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Pronto'),
        content: Text(msg),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Ok'),
          ),
        ],
      ),
    );
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<OcorrenciaController>();
    final ciclo = c.ciclo;
    final secundario = AppTypography.subheadline.copyWith(color: AppColors.textoSecundario);
    final margem = margemDaTela(context);

    return TelaTituloGrande(
      titulo: 'Informar problema',
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextoDeApoio(
                'Entrega de ${Datas.comDiaDaSemana(ciclo.dataEntrega)}. '
                'Avarie ou falta só valem até 24 horas depois da entrega.',
              ),
              SecaoAgrupada(
                cabecalho: 'Foto',
                rodape: 'A foto fica só no servidor, sem link público.',
                children: [
                  LinhaLista(
                    titulo: c.temFoto ? 'Trocar foto' : 'Adicionar foto',
                    icone: CupertinoIcons.camera,
                    trailing: const CupertinoListTileChevron(),
                    onTap: () => _foto(context, c),
                  ),
                ],
              ),
              if (c.bytesFoto != null)
                Padding(
                  padding: EdgeInsets.fromLTRB(margem, AppSpacing.sm, margem, 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.raioCelula),
                    child: Image.memory(
                      c.bytesFoto!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      semanticLabel: 'Foto do problema',
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.fromLTRB(margem, AppSpacing.secao, margem, 0),
                child: ControleSegmentado<String>(
                  opcoes: const {'AVARIA': 'Avaria', 'FALTA': 'Falta'},
                  valor: c.tipo,
                  onEscolher: (t) {
                    HapticFeedback.selectionClick();
                    c.escolherTipo(t);
                  },
                ),
              ),
              SecaoAgrupada(
                cabecalho: 'Produto',
                children: [
                  for (final i in ciclo.itens)
                    LinhaLista(
                      titulo: nomeDoProduto(i.produto),
                      subtitulo: '${i.quantidade} nesta entrega',
                      trailing: c.produto == i.produto
                          ? const Icon(CupertinoIcons.check_mark, color: AppColors.azul800, size: AppSpacing.icone)
                          : null,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        c.escolherProduto(i.produto);
                      },
                    ),
                ],
              ),
              if (c.produto != null)
                SecaoAgrupada(
                  cabecalho: 'Quantidade',
                  children: [
                    LinhaLista(
                      titulo: nomeDoProduto(c.produto!),
                      trailing: SeletorQuantidade(
                        rotulo: nomeDoProduto(c.produto!),
                        quantidade: c.quantidade,
                        passo: 1,
                        onAlterar: (q) {
                          if (q < 1 || q > c.maxQuantidade) return;
                          c.escolherQuantidade(q);
                        },
                      ),
                    ),
                  ],
                ),
              Padding(
                padding: EdgeInsets.fromLTRB(margem, AppSpacing.secao, margem, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Solução', style: AppTypography.footnote.copyWith(color: AppColors.textoSecundario)),
                    const SizedBox(height: AppSpacing.sm),
                    ControleSegmentado<String>(
                      opcoes: const {'REPOSICAO': 'Reposição', 'CREDITO': 'Crédito'},
                      valor: c.solucao,
                      onEscolher: (s) {
                        HapticFeedback.selectionClick();
                        c.escolherSolucao(s);
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      c.solucao == 'REPOSICAO'
                          ? 'Enviamos de novo na próxima entrega.'
                          : 'O valor pago do item vira crédito na hora (90 dias).',
                      style: secundario,
                    ),
                  ],
                ),
              ),
              if (c.erro != null) TextoDeApoio(c.erro!, erro: true),
            ],
          ),
        ),
      ],
      rodape: BotaoPrincipal(
        rotulo: 'Enviar',
        carregando: c.enviando,
        onPressed: () => _enviar(context, c),
      ),
    );
  }
}
