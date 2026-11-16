import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/intents/abridor_links.dart';
import '../../../core/marca_assets.dart';
import '../../../core/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/botao_principal.dart';

/// Tela 1 — Boas-vindas. Proposta, ação principal para a Tela 2 e link do site (Intent implícita).

/// Não chama a API.
class BoasVindasScreen extends StatelessWidget {
  const BoasVindasScreen({super.key});

  static const _passos = <({IconData icone, String titulo, String detalhe})>[
    (
      icone: CupertinoIcons.question_circle,
      titulo: 'Responda 5 perguntas',
      detalhe: 'Sugerimos o kit e a quantidade para a sua rotina.',
    ),
    (
      icone: CupertinoIcons.cube_box,
      titulo: 'Monte sua cesta',
      detalhe: 'Water Protein, Flow Fiber e águas Cristalins.',
    ),
    (
      icone: CupertinoIcons.calendar,
      titulo: 'Escolha a frequência',
      detalhe: 'Semanal, quinzenal ou mensal.',
    ),
    (
      icone: CupertinoIcons.qrcode,
      titulo: 'Pague com Pix',
      detalhe: 'Uma cobrança a cada entrega.',
    ),
  ];

  Future<void> _abrirSite(BuildContext context) async {
    HapticFeedback.selectionClick();
    final mensageiro = ScaffoldMessenger.of(context);
    final abriu = await context.read<AbridorLinks>().abrir(AppConfig.siteMarca);
    if (!abriu) {
      mensageiro.showSnackBar(
        const SnackBar(content: Text('Não conseguimos abrir o site agora. Tente de novo.')),
      );
    }
  }

  void _comecar(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.of(context).pushNamed(AppRoutes.cadastroLogin);
  }

  @override
  Widget build(BuildContext context) {
    final larga = MediaQuery.sizeOf(context).width >= AppSpacing.larguraTelaLarga;
    final margem = larga ? AppSpacing.margemLarga : AppSpacing.margem;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Image.asset(
              assetLogoMarca,
              height: 36,
              fit: BoxFit.contain,
              alignment: Alignment.centerLeft,
              semanticLabel: 'Cristalins',
            ),
            middle: Image.asset(
              assetLogoMarca,
              height: 22,
              fit: BoxFit.contain,
              semanticLabel: 'Cristalins',
            ),
            alwaysShowMiddle: false,
            backgroundColor: AppColors.fundoAgrupado, // opaco: sem blur no Android
            border: null,
            automaticallyImplyLeading: false,
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(margem, AppSpacing.xs, margem, 0),
              child: Text(
                'Water Protein e águas Cristalins na sua porta, no ritmo que você escolher.',
                style: AppTypography.body.copyWith(color: AppColors.texto),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _Secao(
              margem: margem,
              cabecalho: 'Como funciona',
              rodape: 'Entregamos só no município do Rio de Janeiro.',
              children: [
                for (final passo in _passos)
                  CupertinoListTile(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.margem,
                      vertical: AppSpacing.sm,
                    ),
                    leading: Icon(passo.icone, color: AppColors.azul800, size: AppSpacing.icone),
                    title: Text(
                      passo.titulo,
                      style: AppTypography.headline.copyWith(color: AppColors.texto),
                    ),
                    subtitle: Text(
                      passo.detalhe,
                      maxLines: 3,
                      style: AppTypography.subheadline.copyWith(color: AppColors.textoSecundario),
                    ),
                  ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: _Secao(
              margem: margem,
              cabecalho: 'A marca',
              children: [
                CupertinoListTile(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.margem,
                    vertical: AppSpacing.sm,
                  ),
                  leading: const Icon(
                    CupertinoIcons.globe,
                    color: AppColors.azul800,
                    size: AppSpacing.icone,
                  ),
                  title: Text(
                    'Conhecer o site da Cristalins',
                    style: AppTypography.body.copyWith(color: AppColors.linkSobreSuperficie),
                  ),
                  subtitle: Text(
                    'cristalins.com.br',
                    style: AppTypography.subheadline.copyWith(color: AppColors.textoSecundario),
                  ),
                  trailing: const Icon(
                    CupertinoIcons.arrow_up_right_square,
                    color: AppColors.linkSobreSuperficie,
                    size: AppSpacing.icone,
                  ),
                  onTap: () => _abrirSite(context),
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.secao)),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: EdgeInsets.fromLTRB(margem, AppSpacing.xs, margem, AppSpacing.margem),
        child: BotaoPrincipal(rotulo: 'Começar', onPressed: () => _comecar(context)),
      ),
    );
  }
}

/// Seção agrupada (estilo Ajustes) com cabeçalho e nota em footnote.
class _Secao extends StatelessWidget {
  const _Secao({
    required this.margem,
    required this.cabecalho,
    required this.children,
    this.rodape,
  });

  final double margem;
  final String cabecalho;
  final String? rodape;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final estiloNota = AppTypography.footnote.copyWith(color: AppColors.textoSecundario);
    return CupertinoListSection.insetGrouped(
      margin: EdgeInsets.fromLTRB(margem, AppSpacing.secao, margem, 0),
      backgroundColor: AppColors.fundoAgrupado,
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(AppSpacing.raioCelula),
      ),
      separatorColor: AppColors.borda,
      header: Text(cabecalho, style: estiloNota),
      footer: rodape == null ? null : Text(rodape!, style: estiloNota),
      children: children,
    );
  }
}
