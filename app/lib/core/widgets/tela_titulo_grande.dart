import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Esqueleto padrão das telas: título grande que encolhe ao rolar (fundo opaco, sem blur),
/// voltar em chevron e uma ação principal presa ao rodapé.
class TelaTituloGrande extends StatelessWidget {
  const TelaTituloGrande({
    super.key,
    required this.titulo,
    required this.slivers,
    this.rodape,
    this.acaoNaBarra,
    this.voltar = true,
  });

  final String titulo;
  final List<Widget> slivers;
  final Widget? rodape;
  final Widget? acaoNaBarra;
  final bool voltar;

  @override
  Widget build(BuildContext context) {
    final podeVoltar = voltar && (ModalRoute.of(context)?.canPop ?? false);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(titulo),
            backgroundColor: AppColors.fundoAgrupado,
            border: null,
            automaticallyImplyLeading: false,
            leading: podeVoltar ? const BotaoVoltar() : null,
            trailing: acaoNaBarra,
          ),
          ...slivers,
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.secao)),
        ],
      ),
      bottomNavigationBar: rodape == null ? null : RodapeAcao(child: rodape!),
    );
  }
}

/// Voltar em chevron (HIG) com rótulo para leitor de tela. Usa `maybePop`, então respeita o
/// `PopScope` das telas (ex.: o quiz volta uma pergunta) igual ao botão voltar do Android.
class BotaoVoltar extends StatelessWidget {
  const BotaoVoltar({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Voltar',
      excludeSemantics: true,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: const Size(AppSpacing.toqueMinimo, AppSpacing.toqueMinimo),
        onPressed: () => Navigator.of(context).maybePop(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.chevron_left,
              color: AppColors.azul800,
              size: AppSpacing.icone,
            ),
            Text('Voltar', style: AppTypography.body.copyWith(color: AppColors.azul800)),
          ],
        ),
      ),
    );
  }
}

/// Rodapé da ação principal, acima da área segura, com a margem do layout.
class RodapeAcao extends StatelessWidget {
  const RodapeAcao({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final larga = MediaQuery.sizeOf(context).width >= AppSpacing.larguraTelaLarga;
    final margem = larga ? AppSpacing.margemLarga : AppSpacing.margem;
    return SafeArea(
      minimum: EdgeInsets.fromLTRB(margem, AppSpacing.xs, margem, AppSpacing.margem),
      child: child,
    );
  }
}

/// Margem lateral conforme a largura (16 dp; 20 dp em tela larga).
double margemDaTela(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= AppSpacing.larguraTelaLarga
    ? AppSpacing.margemLarga
    : AppSpacing.margem;
