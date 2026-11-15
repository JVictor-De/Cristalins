import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/dependencias.dart';
import '../../../core/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/botao_principal.dart';
import '../../../core/widgets/controles.dart';
import '../../../core/widgets/estados.dart';
import '../../../core/widgets/secao_agrupada.dart';
import '../../../core/widgets/tela_titulo_grande.dart';
import '../domain/quiz.dart';
import 'quiz_controller.dart';

/// Tela 3 — Quiz de perfil: 5 perguntas, uma por vez.
class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => QuizController(context.read<Dependencias>().recomendacoes),
      child: const _Conteudo(),
    );
  }
}

class _Conteudo extends StatelessWidget {
  const _Conteudo();

  Future<void> _continuar(BuildContext context, QuizController c) async {
    HapticFeedback.lightImpact();
    if (!c.ultima) return c.avancar();
    final recomendacao = await c.enviar();
    if (!context.mounted) return;
    if (recomendacao == null) {
      mostrarAviso(
        context,
        c.erro ?? 'Não conseguimos gerar a recomendação agora. Tente de novo.',
        erro: true,
      );
      return;
    }
    Navigator.of(context).pushNamed(AppRoutes.resultado, arguments: recomendacao.id);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<QuizController>();
    final margem = margemDaTela(context);
    final pergunta = c.etapa + 1;

    return PopScope(
      canPop: c.etapa == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          HapticFeedback.selectionClick();
          c.voltar();
        }
      },
      child: TelaTituloGrande(
        titulo: 'Seu perfil',
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(margem, AppSpacing.xs, margem, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    label: 'Pergunta $pergunta de ${PerguntasQuiz.total}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.barraProgresso),
                      child: LinearProgressIndicator(value: pergunta / PerguntasQuiz.total),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ExcludeSemantics(
                    child: Text(
                      'Pergunta $pergunta de ${PerguntasQuiz.total}',
                      style: AppTypography.footnote.copyWith(color: AppColors.textoSecundario),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: _pergunta(context, c)),
        ],
        rodape: BotaoPrincipal(
          rotulo: c.ultima ? 'Ver minha recomendação' : 'Continuar',
          carregando: c.enviando,
          onPressed: c.podeAvancar ? () => _continuar(context, c) : null,
        ),
      ),
    );
  }

  Widget _pergunta(BuildContext context, QuizController c) {
    final r = c.respostas;
    switch (c.etapa) {
      case 0:
        return RadioGroup<String>(
          groupValue: r.objetivo,
          onChanged: (v) {
            HapticFeedback.selectionClick();
            c.responder(r.copyWith(objetivo: v));
          },
          child: SecaoAgrupada(
            cabecalho: 'Qual o seu objetivo principal?',
            children: [
              for (final o in PerguntasQuiz.objetivos)
                MergeSemantics(
                  child: LinhaLista(
                    titulo: o.rotulo,
                    destaque: r.objetivo == o.valor,
                    trailing: CupertinoRadio<String>(
                      value: o.valor,
                      activeColor: AppColors.azul800,
                    ),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      c.responder(r.copyWith(objetivo: o.valor));
                    },
                  ),
                ),
            ],
          ),
        );
      case 1:
        return _Escolha(
          pergunta: 'Em quantos dias da semana você vai consumir?',
          opcoes: PerguntasQuiz.dias,
          valor: r.diasSemana,
          onEscolher: (v) => c.responder(r.copyWith(diasSemana: v)),
        );
      case 2:
        return _Escolha(
          pergunta: 'Quantas pessoas vão consumir?',
          opcoes: PerguntasQuiz.pessoas,
          valor: r.pessoas,
          onEscolher: (v) => c.responder(r.copyWith(pessoas: v)),
        );
      case 3:
        return _Interruptor(
          pergunta: 'Quer incluir Flow Fiber?',
          titulo: 'Incluir Flow Fiber',
          nota: 'Flow Fiber é a água com fibras da Cristalins.',
          valor: r.flowFiber,
          onAlterar: (v) => c.responder(r.copyWith(flowFiber: v)),
        );
      default:
        return _Interruptor(
          pergunta: 'Quer água com gás no complemento?',
          titulo: 'Incluir água com gás',
          valor: r.comGas,
          onAlterar: (v) => c.responder(r.copyWith(comGas: v)),
        );
    }
  }
}

/// Pergunta com lista de valores em folha inferior (CupertinoPicker).
class _Escolha extends StatelessWidget {
  const _Escolha({
    required this.pergunta,
    required this.opcoes,
    required this.valor,
    required this.onEscolher,
  });

  final String pergunta;
  final List<Opcao> opcoes;
  final String? valor;
  final ValueChanged<String> onEscolher;

  @override
  Widget build(BuildContext context) {
    final atual = opcoes.indexWhere((o) => o.valor == valor);
    return SecaoAgrupada(
      cabecalho: pergunta,
      rodape: 'Toque para escolher.',
      children: [
        LinhaLista(
          titulo: atual < 0 ? 'Escolher' : opcoes[atual].rotulo,
          corTitulo: atual < 0 ? AppColors.linkSobreSuperficie : null,
          trailing: const CupertinoListTileChevron(),
          onTap: () async {
            HapticFeedback.selectionClick();
            final i = await escolherNaFolha(
              context,
              titulo: pergunta,
              opcoes: [for (final o in opcoes) o.rotulo],
              selecionado: atual < 0 ? 0 : atual,
            );
            if (i != null) onEscolher(opcoes[i].valor);
          },
        ),
      ],
    );
  }
}

/// Pergunta de sim ou não com CupertinoSwitch.
class _Interruptor extends StatelessWidget {
  const _Interruptor({
    required this.pergunta,
    required this.titulo,
    required this.valor,
    required this.onAlterar,
    this.nota,
  });

  final String pergunta;
  final String titulo;
  final String? nota;
  final bool valor;
  final ValueChanged<bool> onAlterar;

  @override
  Widget build(BuildContext context) {
    return SecaoAgrupada(
      cabecalho: pergunta,
      rodape: nota,
      children: [
        MergeSemantics(
          child: LinhaLista(
            titulo: titulo,
            trailing: CupertinoSwitch(
              value: valor,
              activeTrackColor: AppColors.azul800,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                onAlterar(v);
              },
            ),
            onTap: () {
              HapticFeedback.selectionClick();
              onAlterar(!valor);
            },
          ),
        ),
      ],
    );
  }
}
