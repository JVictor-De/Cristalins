import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/dependencias.dart';
import '../../../core/formatacao.dart';
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
import 'sacola_controller.dart';

class SacolaScreen extends StatelessWidget {
  const SacolaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sacola = context.watch<SacolaController>();

    if (!sacola.temItens) {
      return _SacolaVazia(sacola: sacola);
    }

    final sim = sacola.simulacao;
    final n = sacola.totalItens;
    final titulo = SacolaCopy.itens(n);

    return Scaffold(
      backgroundColor: AppColors.fundo,
      appBar: AppBar(
        backgroundColor: AppColors.fundo,
        surfaceTintColor: Colors.transparent,
        title: Text(titulo),
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
              onChange: (q) => sacola.alterar(item.produto, q),
              onRemover: () => sacola.alterar(item.produto, 0),
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
              'Falta um pouco para o mínimo da assinatura.',
              style: AppTypography.footnote.copyWith(color: AppColors.textoSuave),
            ),
            const SugestaoMinimoCesta(),
          ],
          if (sim != null && sim.faltaParaFreteGratis > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            _BarraFreteGratis(falta: sim.faltaParaFreteGratis, frete: sim.frete),
          ],
          const SizedBox(height: AppSpacing.secao),
          _CardConfigAssinatura(sacola: sacola, sim: sim),
          const SizedBox(height: AppSpacing.sm),
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
          ] else if (sacola.simulando)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Center(child: CircularProgressIndicator(color: AppColors.azulMarca)),
            )
          else if (sacola.erroSimulacao != null)
            Text(
              sacola.erroSimulacao!,
              style: AppTypography.footnote.copyWith(color: AppColors.erro),
            ),
          const SizedBox(height: AppSpacing.sm),
          const _FaixaConfianca(),
        ],
      ),
      bottomNavigationBar: _BarraInferiorSacola(
        sacola: sacola,
        sim: sim,
        onContinuar: () => _continuar(context, sacola),
      ),
    );
  }

  Future<void> _continuar(BuildContext context, SacolaController sacola) async {
    HapticFeedback.mediumImpact();
    final dep = context.read<Dependencias>();
    final token = await dep.api?.tokens.lerAcesso();
    if (!context.mounted) return;
    if (token == null || token.isEmpty) {
      await Navigator.of(context).pushNamed(AppRoutes.cadastroLogin, arguments: 'checkout');
      if (!context.mounted) return;
      final deNovo = await dep.api?.tokens.lerAcesso();
      if (deNovo == null || deNovo.isEmpty) return;
    }

    final pedido = PedidoAssinatura(
      itens: sacola.itens,
      frequencia: sacola.frequencia,
    );
    if (!context.mounted) return;
    Navigator.of(context).pushNamed(AppRoutes.endereco, arguments: pedido);
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
              Icon(Icons.shopping_bag_outlined, size: 56, color: AppColors.textoSuave.withValues(alpha: 0.7)),
              const SizedBox(height: AppSpacing.sm),
              Text('Sua sacola está vazia', style: AppTypography.title3.copyWith(color: AppColors.navy)),
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
    return Semantics(
      label: 'Etapas: Sacola, Entrega, Pagamento. Você está em Sacola.',
      child: Row(
        children: [
          for (var i = 0; i < passos.length; i++) ...[
            if (i > 0)
              Expanded(
                child: Container(height: 1, color: AppColors.linha, margin: const EdgeInsets.symmetric(horizontal: 4)),
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
    );
  }
}

class _BarraFreteGratis extends StatelessWidget {
  const _BarraFreteGratis({required this.falta, required this.frete});

  final num falta;
  final Dinheiro frete;

  @override
  Widget build(BuildContext context) {
    final faltaTxt = Dinheiro.daApi(falta).formatado;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.menta,
        borderRadius: BorderRadius.circular(AppSpacing.raioChip),
        border: Border.all(color: AppColors.linha),
      ),
      child: Text(
        frete.centavos == 0
            ? 'Entrega grátis nesta simulação'
            : 'Faltam $faltaTxt para entrega grátis · entrega atual ${frete.formatado}',
        style: AppTypography.footnote.copyWith(color: AppColors.azulPetroleo),
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
          Text('Configuração da assinatura', style: AppTypography.headline.copyWith(color: AppColors.navy)),
          const SizedBox(height: AppSpacing.sm),
          Text('Frequência', style: AppTypography.subheadline.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final f in const ['SEMANAL', 'QUINZENAL', 'MENSAL'])
                ChoiceChip(
                  label: Text(switch (f) {
                    'SEMANAL' => 'Semanal',
                    'MENSAL' => 'Mensal',
                    _ => 'Quinzenal',
                  }),
                  selected: sacola.frequencia == f,
                  selectedColor: AppColors.navy,
                  labelStyle: AppTypography.footnote.copyWith(
                    color: sacola.frequencia == f ? AppColors.sobrePrimaria : AppColors.tinta,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) => sacola.escolherFrequencia(f),
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
              ChoiceChip(
                label: const Text('Flex'),
                selected: sacola.plano == 'FLEX',
                selectedColor: AppColors.navy,
                labelStyle: AppTypography.footnote.copyWith(
                  color: sacola.plano == 'FLEX' ? AppColors.sobrePrimaria : AppColors.tinta,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) => sacola.escolherPlano('FLEX'),
              ),
              ChoiceChip(
                label: Text(
                  sim != null && sim!.economiaPlano > 0
                      ? 'Trimestral (−${sim!.economiaPlano.toStringAsFixed(2).replaceAll('.', ',')})'
                      : 'Trimestral',
                ),
                selected: sacola.plano == 'TRIMESTRAL',
                selectedColor: AppColors.navy,
                labelStyle: AppTypography.footnote.copyWith(
                  color: sacola.plano == 'TRIMESTRAL' ? AppColors.sobrePrimaria : AppColors.tinta,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) => sacola.escolherPlano('TRIMESTRAL'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FaixaConfianca extends StatelessWidget {
  const _FaixaConfianca();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        _selo(Icons.qr_code_2_outlined, 'Pagamento com Pix'),
        _selo(Icons.pause_circle_outline, 'Pause quando quiser'),
        _selo(Icons.lock_outline, 'Dados protegidos'),
      ],
    );
  }

  Widget _selo(IconData icon, String texto) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textoSuave),
        const SizedBox(width: 4),
        Text(texto, style: AppTypography.caption1.copyWith(color: AppColors.textoSuave)),
      ],
    );
  }
}

class _BarraInferiorSacola extends StatelessWidget {
  const _BarraInferiorSacola({
    required this.sacola,
    required this.sim,
    required this.onContinuar,
  });

  final SacolaController sacola;
  final Simulacao? sim;
  final VoidCallback onContinuar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.superficie,
      elevation: 0,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.superficie,
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(7, 59, 83, 0.12),
              offset: Offset(0, -4),
              blurRadius: 16,
            ),
          ],
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
                if (sim != null)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: Align(
                      key: ValueKey(sim!.total.centavos),
                      alignment: Alignment.centerLeft,
                      child: Text.rich(
                        TextSpan(
                          style: AppTypography.title3.copyWith(color: AppColors.navy),
                          children: [
                            TextSpan(
                              text: sim!.total.formatado,
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            TextSpan(
                              text: ' por entrega',
                              style: AppTypography.subheadline.copyWith(color: AppColors.tinta),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else if (sacola.simulando)
                  Text(
                    SacolaCopy.itens(sacola.totalItens),
                    style: AppTypography.subheadline.copyWith(color: AppColors.textoSuave),
                  ),
                const SizedBox(height: AppSpacing.xs),
                BotaoPrincipal(
                  rotulo: 'Continuar',
                  variante: VarianteBotaoPrincipal.navy,
                  carregando: sacola.simulando,
                  onPressed: sacola.simulando || (sim?.abaixoDoMinimo ?? true) ? null : onContinuar,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemLinha extends StatelessWidget {
  const _ItemLinha({
    required this.item,
    required this.produto,
    required this.passo,
    required this.onChange,
    required this.onRemover,
    this.simulado,
  });

  final ItemCesta item;
  final Produto? produto;
  final ItemSimulado? simulado;
  final int passo;
  final void Function(int) onChange;
  final VoidCallback onRemover;

  @override
  Widget build(BuildContext context) {
    final asset = produto == null ? null : assetDoProduto(produto!.codigo);
    final nome = produto == null ? item.produto : nomeCardProduto(produto!);
    final emb = produto?.embalagem;
    final sub = simulado == null ? null : SacolaCopy.subtotalLinha(simulado!);
    final unit = simulado?.precoUnitario.formatado;

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
          border: Border.all(color: AppColors.linha),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: (produto == null ? AppColors.aqua : corDoProduto(produto!.codigo))
                      .withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(AppSpacing.raioChip),
                ),
                child: asset == null
                    ? const ColoredBox(color: AppColors.aqua)
                    : Image.asset(
                        asset,
                        fit: BoxFit.contain,
                        semanticLabel: nome,
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nome, style: AppTypography.headline.copyWith(color: AppColors.tinta)),
                  if (emb != null)
                    Text(emb, style: AppTypography.caption1.copyWith(color: AppColors.textoSuave)),
                  if (unit != null)
                    Text(
                      '$unit / un. · ${item.quantidade} un.',
                      style: AppTypography.caption1.copyWith(color: AppColors.textoSuave),
                    ),
                  if (sub != null)
                    Text(
                      sub.formatado,
                      style: AppTypography.subheadline.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w700,
                      ),
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
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          onRemover();
                        },
                        icon: const Icon(Icons.delete_outline, color: AppColors.textoSuave),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
