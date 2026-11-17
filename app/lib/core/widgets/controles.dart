import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Botão secundário (sem fundo, texto na cor de link conforme o fundo).
class BotaoSecundario extends StatelessWidget {
  const BotaoSecundario({
    super.key,
    required this.rotulo,
    required this.onPressed,
    this.icone,
    this.sobreFundoAgrupado = true,
    this.destrutivo = false,
  });

  final String rotulo;
  final VoidCallback? onPressed;
  final IconData? icone;
  final bool sobreFundoAgrupado;
  final bool destrutivo;

  @override
  Widget build(BuildContext context) {
    final cor = destrutivo
        ? AppColors.erro
        : (sobreFundoAgrupado ? AppColors.linkSobreFundoAgrupado : AppColors.linkSobreSuperficie);
    final label = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            rotulo,
            textAlign: TextAlign.center,
            style: AppTypography.headline.copyWith(color: cor),
          ),
        ),
        if (icone != null) ...[
          const SizedBox(width: AppSpacing.xxs),
          Icon(icone, size: AppSpacing.icone, color: cor),
        ],
      ],
    );
    if (kIsWeb) {
      return Semantics(
        button: true,
        enabled: onPressed != null,
        label: rotulo,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.margem,
              vertical: AppSpacing.xs,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppSpacing.toqueMinimo),
              child: Center(child: label),
            ),
          ),
        ),
      );
    }
    return CupertinoButton(
      minimumSize: const Size(AppSpacing.toqueMinimo, AppSpacing.toqueMinimo),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margem, vertical: AppSpacing.xs),
      onPressed: onPressed,
      child: label,
    );
  }
}

/// Seletor de quantidade: − número +, botões circulares, número tabular, passo da embalagem (RN04).
class SeletorQuantidade extends StatelessWidget {
  const SeletorQuantidade({
    super.key,
    required this.quantidade,
    required this.passo,
    required this.onAlterar,
    required this.rotulo,
  });

  final int quantidade;
  final int passo;
  final ValueChanged<int> onAlterar;
  final String rotulo;

  @override
  Widget build(BuildContext context) {
    Widget botao(IconData icone, String dica, int? novo) {
      final VoidCallback? acao = novo == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onAlterar(novo);
            };
      final visual = Container(
        width: AppSpacing.botaoCircular,
        height: AppSpacing.botaoCircular,
        decoration: const BoxDecoration(color: AppColors.azul100, shape: BoxShape.circle),
        child: Icon(icone, size: AppSpacing.iconePequeno, color: AppColors.azul800),
      );
      // Web/Safari: CupertinoButton dentro de scroll às vezes engole o toque.
      if (kIsWeb) {
        return Semantics(
          button: true,
          enabled: acao != null,
          label: '$dica $rotulo',
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: acao,
            child: SizedBox(
              width: AppSpacing.toqueMinimo,
              height: AppSpacing.toqueMinimo,
              child: Center(child: visual),
            ),
          ),
        );
      }
      return Semantics(
        button: true,
        label: '$dica $rotulo',
        excludeSemantics: true,
        child: CupertinoButton(
          minimumSize: const Size(AppSpacing.toqueMinimo, AppSpacing.toqueMinimo),
          padding: EdgeInsets.zero,
          onPressed: acao,
          child: visual,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        botao(
          CupertinoIcons.minus,
          'Diminuir',
          quantidade - passo >= 0 && quantidade > 0 ? quantidade - passo : null,
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: AppSpacing.toqueMinimo),
          // Só o rótulo completo: sem excludeSemantics o leitor de tela repete o número.
          child: Semantics(
            label: '$quantidade unidades de $rotulo',
            excludeSemantics: true,
            child: Text(
              '$quantidade',
              textAlign: TextAlign.center,
              style: AppTypography.headline.copyWith(
                color: AppColors.texto,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
        botao(CupertinoIcons.plus, 'Aumentar', quantidade + passo),
      ],
    );
  }
}

/// Selo de status: fundo claro com texto escuro da mesma família de cor.
class Selo extends StatelessWidget {
  const Selo({super.key, required this.texto, required this.fundo, required this.cor});

  final String texto;
  final Color fundo;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(AppSpacing.raioSelo),
      ),
      // Caixa alta só no visual (caption2); o leitor de tela lê a palavra normal, sem soletrar.
      child: Text(
        texto.toUpperCase(),
        semanticsLabel: texto,
        style: AppTypography.caption2.copyWith(color: cor),
      ),
    );
  }
}

/// Folha inferior para escolher um índice.
///
/// No app nativo: `CupertinoPicker`. No Flutter Web (Safari iOS): ActionSheet —
/// a roda do picker perde gestos para o scroll e costuma ficar inutilizável.
Future<int?> escolherNaFolha(
  BuildContext context, {
  required String titulo,
  required List<String> opcoes,
  required int selecionado,
}) {
  if (kIsWeb) {
    return showCupertinoModalPopup<int>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(titulo),
        actions: [
          for (var i = 0; i < opcoes.length; i++)
            CupertinoActionSheetAction(
              isDefaultAction: i == selecionado,
              onPressed: () {
                HapticFeedback.selectionClick();
                Navigator.of(ctx).pop(i);
              },
              child: Text(opcoes[i]),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancelar'),
        ),
      ),
    );
  }

  var atual = selecionado;
  return showCupertinoModalPopup<int>(
    context: context,
    builder: (ctx) => Container(
      height: AppSpacing.alturaFolhaPicker,
      decoration: const BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.raioFolha)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Row(
              children: [
                const SizedBox(width: AppSpacing.margem),
                Expanded(
                  child: Text(
                    titulo,
                    style: AppTypography.headline.copyWith(color: AppColors.texto),
                  ),
                ),
                CupertinoButton(
                  minimumSize: const Size(AppSpacing.toqueMinimo, AppSpacing.toqueMinimo),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(ctx).pop(atual);
                  },
                  child: Text(
                    'Concluir',
                    style: AppTypography.headline.copyWith(color: AppColors.linkSobreSuperficie),
                  ),
                ),
              ],
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: AppSpacing.alturaItemPicker,
                scrollController: FixedExtentScrollController(initialItem: selecionado),
                onSelectedItemChanged: (i) {
                  HapticFeedback.selectionClick();
                  atual = i;
                },
                children: [
                  for (final o in opcoes)
                    Center(
                      child: Text(o, style: AppTypography.body.copyWith(color: AppColors.texto)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
