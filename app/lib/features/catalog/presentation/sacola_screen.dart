import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/dependencias.dart';
import '../../../core/formatacao.dart';
import '../../../core/intents/navegacao_nativa.dart';
import '../../../core/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sombras.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/botao_principal.dart';
import '../../../core/widgets/detalhe_preco_expansivel.dart';
import '../../../core/widgets/stepper_quantidade.dart';
import '../../../core/widgets/sugestao_minimo_cesta.dart';
import '../../shell/presentation/shell_screen.dart';
import '../../subscription/domain/assinatura.dart';
import '../domain/catalogo.dart';
import '../domain/produto_assets.dart';
import '../domain/sacola_copy.dart';
import 'produtos_screen.dart' show kEscalaFonteUmaColuna;
import 'sacola_controller.dart';

/// Sacola (P3 design_ux_ui). Preço/total só da simulação; com erro de embalagem o
/// resumo continua visível (estimativa pelo `precoBase`, marcada como tal) e o card
/// do SKU mostra o que falta + “Completar caixa”.
class SacolaScreen extends StatelessWidget {
  const SacolaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sacola = context.watch<SacolaController>();

    if (!sacola.temItens) {
      return _SacolaVazia(sacola: sacola);
    }

    final sim = sacola.simulacao;
    final nProdutos = sacola.itens.length;
    final mista = sacola.caixaMistaNaSacola;
    // Erro de caixa mista aparece uma vez: no último SKU WP/FF da lista.
    final skuErroMista = mista.isEmpty
        ? null
        : sacola.itens.lastWhere((i) => mista.contains(i.produto)).produto;

    return Scaffold(
      backgroundColor: AppColors.fundo,
      // P3.2: “Sacola” + subtítulo “N produtos”.
      appBar: AppBar(
        backgroundColor: AppColors.fundo,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Sacola', style: AppTypography.headline.copyWith(color: AppColors.heroInk)),
            Text(
              '$nProdutos ${nProdutos == 1 ? 'produto' : 'produtos'}',
              key: const ValueKey('sacola-subtitulo'),
              style: AppTypography.footnote.copyWith(color: AppColors.textoSuave),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.margem,
          AppSpacing.sm,
          AppSpacing.margem,
          AppSpacing.secao,
        ),
        children: [
          const _PassosCheckout(),
          const SizedBox(height: AppSpacing.sm),
          for (final item in sacola.itens)
            _ItemLinha(
              item: item,
              produto: sacola.produtoDe(item.produto),
              simulado: sim?.itens.where((e) => e.produto == item.produto).firstOrNull,
              passo: sacola.produtoDe(item.produto) == null
                  ? 1
                  : sacola.passo(sacola.produtoDe(item.produto)!),
              faltaCaixa: _faltaNoCard(sacola, item, skuErroMista),
              caixaMista: SacolaController.caixaMista.contains(item.produto) && mista.length > 1,
              onCompletar: () {
                final p = sacola.produtoDe(item.produto);
                if (p == null) return;
                HapticFeedback.lightImpact();
                sacola.completarCaixa(p);
              },
              onChange: (q) => sacola.alterar(item.produto, q),
              onRemover: () => _removerComDesfazer(context, sacola, item),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.shell,
                (_) => false,
                arguments: const ShellArgs(abaInicial: 1),
              ),
              icon: const Icon(Icons.add, color: AppColors.azulMarca),
              label: Text(
                'Adicionar mais produtos',
                style: AppTypography.subheadline.copyWith(
                  color: AppColors.azulMarca,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (sim != null && sim.abaixoDoMinimo) ...[
            const SizedBox(height: AppSpacing.xs),
            LinearProgressIndicator(
              value: ((sim.ueMinima - sim.faltaUeParaMinimo) / sim.ueMinima).clamp(0, 1).toDouble(),
              color: AppColors.azulMarca,
              backgroundColor: AppColors.linha,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              SacolaCopy.motivoMinimo,
              style: AppTypography.footnote.copyWith(color: AppColors.textoSuave),
            ),
            const SugestaoMinimoCesta(),
          ],
          if (sim != null) ...[const SizedBox(height: AppSpacing.sm), _BarraFreteGratis(sim: sim)],
          const SizedBox(height: AppSpacing.secao),
          _CardConfigAssinatura(sacola: sacola, sim: sim),
          const SizedBox(height: AppSpacing.sm),
          // P3.2: resumo SEMPRE visível.
          if (sim != null) ...[
            DetalhePrecoExpansivel(
              detalhe: sim.detalhe,
              subtotal: sim.subtotal,
              frete: sim.frete,
              total: sim.total,
              inicialmenteAberto: true,
            ),
            if (SacolaCopy.aproximadoMes(sim.total, sacola.frequencia) case final approx?)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xxs),
                child: Text(
                  approx,
                  style: AppTypography.caption1.copyWith(color: AppColors.textoSuave),
                ),
              ),
          ] else
            _ResumoEstimado(sacola: sacola),
          const SizedBox(height: AppSpacing.sm),
          Text(
            SacolaCopy.proximoPasso,
            key: const ValueKey('sacola-proximo-passo'),
            style: AppTypography.footnote.copyWith(color: AppColors.textoSuave),
          ),
          const _LinksLegais(),
        ],
      ),
      bottomNavigationBar: _BarraInferiorSacola(
        sacola: sacola,
        sim: sim,
        onContinuar: () => _continuar(context, sacola),
      ),
    );
  }

  int _faltaNoCard(SacolaController sacola, ItemCesta item, String? skuErroMista) {
    final p = sacola.produtoDe(item.produto);
    if (p == null) return 0;
    if (SacolaController.caixaMista.contains(item.produto) && item.produto != skuErroMista) {
      return 0;
    }
    return sacola.faltaParaCompletarCaixa(p);
  }

  /// P3.3: remover com “Desfazer” por 4 s.
  void _removerComDesfazer(BuildContext context, SacolaController sacola, ItemCesta item) {
    HapticFeedback.selectionClick();
    final p = sacola.produtoDe(item.produto);
    final nome = p == null ? item.produto : nomeCardProduto(p);
    final anterior = item.quantidade;
    sacola.alterar(item.produto, 0);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$nome removido da sacola'),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Desfazer',
            onPressed: () => sacola.alterar(item.produto, anterior),
          ),
        ),
      );
  }

  Future<void> _continuar(BuildContext context, SacolaController sacola) async {
    HapticFeedback.mediumImpact();
    final dep = context.read<Dependencias>();
    final token = await dep.api?.tokens.lerAcesso();
    if (!context.mounted) return;
    if (token == null || token.isEmpty) {
      await NavegacaoNativa.instancia.abrir(
        context,
        activity: NavegacaoNativa.cadastroLogin,
        rota: AppRoutes.cadastroLogin,
        arguments: 'checkout',
      );
      if (!context.mounted) return;
      final deNovo = await dep.api?.tokens.lerAcesso();
      if (deNovo == null || deNovo.isEmpty) return;
    }

    final pedido = PedidoAssinatura(itens: sacola.itens, frequencia: sacola.frequencia);
    if (!context.mounted) return;
    await NavegacaoNativa.instancia.abrir(
      context,
      activity: NavegacaoNativa.endereco,
      rota: AppRoutes.endereco,
      arguments: pedido,
    );
  }
}

class _SacolaVazia extends StatelessWidget {
  const _SacolaVazia({required this.sacola});

  final SacolaController sacola;

  @override
  Widget build(BuildContext context) {
    final temWp = sacola.produtoDe('WP500') != null;
    final temAguas = sacola.produtos.any(Categoria.aguas.inclui);
    final wp = sacola.produtoDe('WP500');

    return Scaffold(
      backgroundColor: AppColors.fundo,
      appBar: AppBar(
        backgroundColor: AppColors.fundo,
        surfaceTintColor: Colors.transparent,
        title: const Text('Sacola'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.secao),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                size: 56,
                color: AppColors.textoSuave.withValues(alpha: 0.7),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Sua sacola está vazia',
                style: AppTypography.title3.copyWith(color: AppColors.navy),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Monte a assinatura com águas e Water Protein.',
                textAlign: TextAlign.center,
                style: AppTypography.footnote.copyWith(color: AppColors.textoSuave),
              ),
              const SizedBox(height: AppSpacing.secao),
              BotaoPrincipal(
                rotulo: 'Assinar Water Protein',
                variante: VarianteBotaoPrincipal.navy,
                onPressed: () {
                  if (wp != null) {
                    HapticFeedback.lightImpact();
                    sacola.adicionarPasso(wp);
                    return;
                  }
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.shell,
                    (_) => false,
                    arguments: const ShellArgs(abaInicial: 1),
                  );
                },
              ),
              if (temAguas)
                TextButton(
                  onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.shell,
                    (_) => false,
                    arguments: const ShellArgs(abaInicial: 1, categoriaInicial: Categoria.aguas),
                  ),
                  child: const Text('Ver todas as águas'),
                )
              else if (!temWp)
                TextButton(
                  onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.shell,
                    (_) => false,
                    arguments: const ShellArgs(abaInicial: 1),
                  ),
                  child: const Text('Ver produtos'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PassosCheckout extends StatelessWidget {
  const _PassosCheckout();

  @override
  Widget build(BuildContext context) {
    const passos = ['Sacola', 'Entrega', 'Pagamento'];
    // Indicador compacto: o rótulo semântico já diz tudo, então a fonte para em 130%
    // (3 rótulos lado a lado não cabem em 358 dp a 200%).
    return Semantics(
      label: 'Etapas: Sacola, Entrega, Pagamento. Você está em Sacola.',
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: Row(
          children: [
            for (var i = 0; i < passos.length; i++) ...[
              if (i > 0)
                Expanded(
                  child: Container(
                    height: 1,
                    color: AppColors.linha,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                ),
              Column(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: i == 0 ? AppColors.navy : AppColors.linha,
                    child: Text(
                      '${i + 1}',
                      style: AppTypography.caption1.copyWith(
                        color: i == 0 ? AppColors.sobrePrimaria : AppColors.textoSuave,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    passos[i],
                    style: AppTypography.caption1.copyWith(
                      color: i == 0 ? AppColors.navy : AppColors.textoSuave,
                      fontWeight: i == 0 ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// P3.2: texto + barra até o limite RN18 (valores da simulação).
class _BarraFreteGratis extends StatelessWidget {
  const _BarraFreteGratis({required this.sim});

  final Simulacao sim;

  @override
  Widget build(BuildContext context) {
    final gratis = sim.frete.centavos == 0 || sim.faltaParaFreteGratis <= 0;
    final limiteCentavos = sim.freteGratisAcima * 100;
    final progresso = gratis || limiteCentavos <= 0
        ? 1.0
        : (sim.subtotal.centavos / limiteCentavos).clamp(0.0, 1.0).toDouble();
    final texto = gratis
        ? 'Entrega grátis nesta sacola'
        : '${SacolaCopy.faltaFreteGratis(sim)} · entrega atual ${sim.frete.formatado}';

    return Container(
      key: const ValueKey('sacola-frete'),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(AppSpacing.raioCelula),
        border: Border.all(color: AppColors.linha),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.local_shipping_outlined, size: 18, color: AppColors.heroNavy),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  texto,
                  style: AppTypography.footnote.copyWith(color: AppColors.heroInk),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.raioChip),
            child: LinearProgressIndicator(
              key: const ValueKey('sacola-frete-barra'),
              value: progresso,
              minHeight: AppSpacing.barraProgresso,
              backgroundColor: AppColors.linha,
              color: AppColors.heroNavy,
              semanticsLabel: 'Progresso até o frete grátis',
            ),
          ),
        ],
      ),
    );
  }
}

class _CardConfigAssinatura extends StatelessWidget {
  const _CardConfigAssinatura({required this.sacola, required this.sim});

  final SacolaController sacola;
  final Simulacao? sim;

  @override
  Widget build(BuildContext context) {
    final economia = sim == null ? null : SacolaCopy.economiaTrimestral(sim!.economiaPlano);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.margem),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(AppSpacing.raioCard),
        boxShadow: AppSombras.card,
        border: Border.all(color: AppColors.linha),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configuração da assinatura',
            style: AppTypography.headline.copyWith(color: AppColors.navy),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Frequência',
            style: AppTypography.subheadline.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final f in const ['SEMANAL', 'QUINZENAL', 'MENSAL'])
                _ChipPill(
                  rotulo: switch (f) {
                    'SEMANAL' => 'Semanal',
                    'MENSAL' => 'Mensal',
                    _ => 'Quinzenal',
                  },
                  selecionado: sacola.frequencia == f,
                  onSelected: () => sacola.escolherFrequencia(f),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('Plano', style: AppTypography.subheadline.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ChipPill(
                rotulo: 'Flex',
                selecionado: sacola.plano == 'FLEX',
                onSelected: () => sacola.escolherPlano('FLEX'),
              ),
              _ChipPill(
                rotulo: 'Trimestral',
                selecionado: sacola.plano == 'TRIMESTRAL',
                onSelected: () => sacola.escolherPlano('TRIMESTRAL'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          // P3.2/P3.3: copy real do plano + economia em R$ (simulação).
          Text(
            SacolaCopy.descricaoPlano(sacola.plano),
            key: const ValueKey('sacola-plano-descricao'),
            style: AppTypography.footnote.copyWith(color: AppColors.textoSuave),
          ),
          if (economia != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xxs),
              child: Text(
                economia,
                key: const ValueKey('sacola-economia'),
                style: AppTypography.footnote.copyWith(
                  color: AppColors.sucesso,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Chip pílula 48 dp (P3.2).
class _ChipPill extends StatelessWidget {
  const _ChipPill({required this.rotulo, required this.selecionado, required this.onSelected});

  final String rotulo;
  final bool selecionado;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(rotulo),
      selected: selecionado,
      showCheckmark: false,
      shape: const StadiumBorder(side: BorderSide(color: AppColors.linha)),
      backgroundColor: AppColors.superficie,
      selectedColor: AppColors.heroNavy,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      labelStyle: AppTypography.footnote.copyWith(
        color: selecionado ? AppColors.sobrePrimaria : AppColors.heroInk,
        fontWeight: FontWeight.w600,
      ),
      onSelected: (_) {
        HapticFeedback.selectionClick();
        onSelected();
      },
    );
  }
}

/// P3.1: sem simulação válida (erro/primeira carga) o resumo continua na tela,
/// com subtotal **estimado** pelo `precoBase` e o total marcado como pendente.
class _ResumoEstimado extends StatelessWidget {
  const _ResumoEstimado({required this.sacola});

  final SacolaController sacola;

  @override
  Widget build(BuildContext context) {
    var centavos = 0;
    for (final i in sacola.itens) {
      final p = sacola.produtoDe(i.produto);
      if (p != null) centavos += p.precoBase.centavos * i.quantidade;
    }
    final erro = sacola.erroSimulacao;
    final linha = AppTypography.subheadline.copyWith(color: AppColors.heroInk);
    final apoio = AppTypography.footnote.copyWith(color: AppColors.textoSuave);

    return Container(
      key: const ValueKey('sacola-resumo-estimado'),
      padding: const EdgeInsets.all(AppSpacing.margem),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(AppSpacing.raioCard),
        border: Border.all(color: AppColors.linha),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Resumo', style: AppTypography.headline.copyWith(color: AppColors.navy)),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(child: Text('Subtotal estimado', style: linha)),
              Text('≈ ${Dinheiro(centavos).formatado}', style: linha),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Row(
            children: [
              Expanded(child: Text('Entrega e descontos', style: apoio)),
              Text(sacola.simulando ? 'calculando…' : 'após ajustar a sacola', style: apoio),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Total por entrega',
                  style: linha.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text('—', style: linha.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text('Estimativa pelo preço base de cada produto.', style: apoio),
          if (erro != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Semantics(
              container: true,
              liveRegion: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, size: 18, color: AppColors.erro),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      erro,
                      key: const ValueKey('sacola-erro-api'),
                      style: AppTypography.footnote.copyWith(color: AppColors.erro),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// P3.3: Termos / Privacidade quando configurados (`--dart-define`); sem URL, nada.
class _LinksLegais extends StatelessWidget {
  const _LinksLegais();

  @override
  Widget build(BuildContext context) {
    const termos = AppConfig.urlTermos;
    const privacidade = AppConfig.urlPrivacidade;
    if (termos.isEmpty && privacidade.isEmpty) return const SizedBox.shrink();
    final links = context.read<Dependencias>().links;
    return Wrap(
      children: [
        if (termos.isNotEmpty)
          TextButton(onPressed: () => links.abrir(termos), child: const Text('Termos de uso')),
        if (privacidade.isNotEmpty)
          TextButton(onPressed: () => links.abrir(privacidade), child: const Text('Privacidade')),
      ],
    );
  }
}

class _BarraInferiorSacola extends StatelessWidget {
  const _BarraInferiorSacola({required this.sacola, required this.sim, required this.onContinuar});

  final SacolaController sacola;
  final Simulacao? sim;
  final VoidCallback onContinuar;

  @override
  Widget build(BuildContext context) {
    // P3.1: motivo visível ao lado do botão quando bloqueado.
    final String? motivo;
    if (sacola.simulando) {
      motivo = null;
    } else if (sacola.temCaixaIncompleta) {
      motivo = SacolaCopy.motivoCaixaIncompleta;
    } else if (sim == null) {
      motivo = sacola.erroSimulacao;
    } else if (sim!.abaixoDoMinimo) {
      motivo = SacolaCopy.motivoMinimo;
    } else {
      motivo = null;
    }
    final podeContinuar = !sacola.simulando && sim != null && motivo == null;

    return Material(
      color: AppColors.superficie,
      elevation: 0,
      child: DecoratedBox(
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
              children: [
                // P3.2: selos acima do CTA (sem “Dados protegidos” morto).
                const _FaixaConfianca(),
                const SizedBox(height: AppSpacing.xs),
                if (motivo != null) ...[
                  Semantics(
                    container: true,
                    liveRegion: true,
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: AppColors.erro),
                        const SizedBox(width: AppSpacing.xxs),
                        Expanded(
                          child: Text(
                            motivo,
                            key: const ValueKey('sacola-motivo'),
                            style: AppTypography.footnote.copyWith(
                              color: AppColors.erro,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],
                BotaoPrincipal(
                  key: const ValueKey('sacola-continuar'),
                  rotulo: sim == null
                      ? 'Continuar'
                      : 'Continuar · ${SacolaCopy.totalPorEntrega(sim!.total)}',
                  variante: VarianteBotaoPrincipal.cta,
                  carregando: sacola.simulando,
                  onPressed: podeContinuar ? onContinuar : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FaixaConfianca extends StatelessWidget {
  const _FaixaConfianca();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xxs,
      children: [
        _selo(Icons.qr_code_2_outlined, 'Pagamento com Pix'),
        _selo(Icons.pause_circle_outline, 'Pause quando quiser'),
      ],
    );
  }

  Widget _selo(IconData icon, String texto) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textoSuave),
        const SizedBox(width: 4),
        Flexible(
          child: Text(texto, style: AppTypography.footnote.copyWith(color: AppColors.textoSuave)),
        ),
      ],
    );
  }
}

class _ItemLinha extends StatelessWidget {
  const _ItemLinha({
    required this.item,
    required this.produto,
    required this.passo,
    required this.faltaCaixa,
    required this.caixaMista,
    required this.onCompletar,
    required this.onChange,
    required this.onRemover,
    this.simulado,
  });

  final ItemCesta item;
  final Produto? produto;
  final ItemSimulado? simulado;
  final int passo;
  final int faltaCaixa;
  final bool caixaMista;
  final VoidCallback onCompletar;
  final void Function(int) onChange;
  final VoidCallback onRemover;

  @override
  Widget build(BuildContext context) {
    final asset = produto == null ? null : assetDoProduto(produto!.codigo);
    final nome = produto == null ? item.produto : nomeCardProduto(produto!);
    // Pack real (`12 × 500 ml`) desambigua nomes curtos repetidos (“Sem gás” 500 ml × 1,5 L).
    final emb = produto?.pack;
    final sub = simulado == null ? null : SacolaCopy.subtotalLinha(simulado!);
    final unit = simulado?.precoUnitario.formatado;
    // Sem simulação: estimativa pelo preço base, marcada com “≈”.
    final estimado = sub == null && produto != null
        ? Dinheiro(produto!.precoBase.centavos * item.quantidade)
        : null;
    final comErro = faltaCaixa > 0;
    final empilhar = MediaQuery.textScalerOf(context).scale(16) / 16 >= kEscalaFonteUmaColuna;
    final nomeBloco = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(nome, style: AppTypography.headline.copyWith(color: AppColors.heroInk)),
        if (emb != null)
          Text(emb, style: AppTypography.footnote.copyWith(color: AppColors.textoSuave)),
      ],
    );
    final precoBloco = Column(
      crossAxisAlignment: empilhar ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        if (sub != null)
          Text(
            sub.formatado,
            key: ValueKey('sacola-preco-${item.produto}'),
            style: AppTypography.subheadline.copyWith(
              color: AppColors.heroInk,
              fontWeight: FontWeight.w700,
            ),
          )
        else if (estimado != null)
          Text(
            '≈ ${estimado.formatado}',
            key: ValueKey('sacola-preco-${item.produto}'),
            style: AppTypography.subheadline.copyWith(
              color: AppColors.textoSuave,
              fontWeight: FontWeight.w600,
            ),
          ),
        if (unit != null)
          Text('$unit /un.', style: AppTypography.footnote.copyWith(color: AppColors.textoSuave)),
      ],
    );

    return Dismissible(
      key: ValueKey('sacola-${item.produto}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.only(right: AppSpacing.margem),
        decoration: BoxDecoration(
          color: AppColors.erro.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppSpacing.raioCard),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.erro),
      ),
      onDismissed: (_) => onRemover(),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.superficie,
          borderRadius: BorderRadius.circular(AppSpacing.raioCard),
          boxShadow: AppSombras.card,
          border: Border.all(color: comErro ? AppColors.erro : AppColors.linha),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: produto == null
                          ? AppColors.blocoAgua
                          : fundoBlocoProduto(produto!.codigo),
                      borderRadius: BorderRadius.circular(AppSpacing.raioCelula),
                    ),
                    child: asset == null
                        ? const SizedBox.shrink()
                        : Image.asset(asset, fit: BoxFit.contain, semanticLabel: nome),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // P3.2: nome + volume/pack à esquerda; preço à direita
                      // (abaixo do nome com fonte ≥ 160%, como a grade de Produtos).
                      if (empilhar) ...[
                        nomeBloco,
                        const SizedBox(height: AppSpacing.xxs),
                        precoBloco,
                      ] else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: nomeBloco),
                            const SizedBox(width: AppSpacing.xs),
                            precoBloco,
                          ],
                        ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          StepperQuantidade(
                            quantidade: item.quantidade,
                            passo: passo,
                            onAlterar: onChange,
                            rotulo: nome,
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Remover $nome',
                            onPressed: onRemover,
                            icon: const Icon(Icons.delete_outline, color: AppColors.textoSuave),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // P3.1: erro de embalagem no card do SKU + ação “Completar caixa”.
            if (comErro && produto != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Semantics(
                container: true,
                liveRegion: true,
                child: Container(
                  key: ValueKey('sacola-erro-${item.produto}'),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.sm,
                    AppSpacing.xs,
                    AppSpacing.xs,
                    AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.erro.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppSpacing.raioCelula),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline, size: 18, color: AppColors.erro),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              SacolaCopy.faltaCaixa(
                                falta: faltaCaixa,
                                tamanho: produto!.embalagemQtd,
                                mista: caixaMista,
                              ),
                              style: AppTypography.footnote.copyWith(
                                color: AppColors.heroInk,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          key: ValueKey('sacola-completar-${item.produto}'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.heroNavy,
                            minimumSize: const Size(0, AppSpacing.toqueMinimo),
                          ),
                          onPressed: onCompletar,
                          child: Text('Completar caixa (+$faltaCaixa)'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
