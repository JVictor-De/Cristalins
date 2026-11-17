import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'tela_titulo_grande.dart';

/// Lista agrupada (estilo Ajustes), cabeçalho e nota em footnote.
class SecaoAgrupada extends StatelessWidget {
  const SecaoAgrupada({
    super.key,
    this.cabecalho,
    this.rodape,
    this.rodapeErro = false,
    required this.children,
  });

  final String? cabecalho;
  final String? rodape;
  final bool rodapeErro;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final margem = margemDaTela(context);
    final nota = AppTypography.footnote.copyWith(color: AppColors.textoSecundario);
    return CupertinoListSection.insetGrouped(
      margin: EdgeInsets.fromLTRB(margem, AppSpacing.secao, margem, 0),
      backgroundColor: AppColors.fundoAgrupado,
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(AppSpacing.raioCelula),
      ),
      separatorColor: AppColors.borda,
      header: cabecalho == null ? null : Text(cabecalho!, style: nota),
      footer: rodape == null
          ? null
          : Text(rodape!, style: rodapeErro ? nota.copyWith(color: AppColors.erro) : nota),
      children: children,
    );
  }
}

/// Linha de lista com título, subtítulo e ação opcional. Altura mínima de 48 dp.
class LinhaLista extends StatelessWidget {
  const LinhaLista({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.icone,
    this.trailing,
    this.onTap,
    this.destaque = false,
    this.corTitulo,
  });

  final String titulo;
  final String? subtitulo;
  final IconData? icone;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destaque;
  final Color? corTitulo;

  @override
  Widget build(BuildContext context) {
    // Título, subtítulo, valor e controle da linha são anunciados juntos (ex.: "Plano, Trimestral").
    final tile = CupertinoListTile(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margem, vertical: AppSpacing.sm),
      backgroundColor: destaque ? AppColors.azul100 : null,
      leading: icone == null
          ? null
          : Icon(icone, color: AppColors.azul800, size: AppSpacing.icone),
      title: Text(
        titulo,
        maxLines: 3,
        style: AppTypography.body.copyWith(color: corTitulo ?? AppColors.texto),
      ),
      subtitle: subtitulo == null
          ? null
          : Text(
              subtitulo!,
              maxLines: 4,
              style: AppTypography.subheadline.copyWith(color: AppColors.textoSecundario),
            ),
      trailing: trailing,
      // No web (Safari iOS) o onTap do CupertinoListTile falha com frequência
      // dentro do CustomScrollView — o GestureDetector abaixo cobre o toque.
      onTap: kIsWeb ? null : onTap,
    );

    if (!kIsWeb || onTap == null) {
      return MergeSemantics(child: tile);
    }

    return MergeSemantics(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: tile,
      ),
    );
  }
}

/// Texto de apoio solto entre seções, alinhado à margem.
class TextoDeApoio extends StatelessWidget {
  const TextoDeApoio(this.texto, {super.key, this.erro = false});

  final String texto;
  final bool erro;

  @override
  Widget build(BuildContext context) {
    final margem = margemDaTela(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(margem, AppSpacing.xs, margem, 0),
      child: Text(
        texto,
        style: AppTypography.body.copyWith(color: erro ? AppColors.erro : AppColors.texto),
      ),
    );
  }
}
