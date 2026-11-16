import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/dependencias.dart';
import '../../../core/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/botao_principal.dart';
import '../../subscription/domain/assinatura.dart';
import '../domain/catalogo.dart';
import '../domain/produto_assets.dart';
import 'sacola_controller.dart';

class SacolaScreen extends StatelessWidget {
  const SacolaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sacola = context.watch<SacolaController>();

    if (!sacola.temItens) {
      return Scaffold(
        backgroundColor: AppColors.gelo,
        appBar: AppBar(title: const Text('Sacola')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.secao),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Sua sacola está vazia', style: AppTypography.title3),
                const SizedBox(height: AppSpacing.secao),
                BotaoPrincipal(
                  rotulo: 'Assinar Water Protein',
                  onPressed: () => Navigator.of(context).pushNamed(AppRoutes.produto, arguments: 'WP500'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Ver todas as águas'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final sim = sacola.simulacao;
    final sugestao = sacola.sugerirParaMinimo();

    return Scaffold(
      backgroundColor: AppColors.gelo,
      appBar: AppBar(title: const Text('Sacola')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.margem),
        children: [
          for (final item in sacola.itens)
            _ItemLinha(
              item: item,
              produto: sacola.produtoDe(item.produto),
              unitario: sim?.itens.where((e) => e.produto == item.produto).firstOrNull?.precoUnitario.formatado,
              passo: sacola.produtoDe(item.produto) == null
                  ? 1
                  : sacola.passo(sacola.produtoDe(item.produto)!),
              onChange: (q) => sacola.alterar(item.produto, q),
            ),
          if (sim != null && sim.abaixoDoMinimo) ...[
            const SizedBox(height: AppSpacing.sm),
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
            if (sugestao != null)
              TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  sacola.adicionarPasso(sugestao);
                },
                child: Text('Adicionar ${sugestao.nome} (${sugestao.embalagem})'),
              ),
          ],
          const SizedBox(height: AppSpacing.secao),
          Text('Frequência', style: AppTypography.headline),
          const SizedBox(height: 4),
          Text(
            'Padrão: quinzenal · Flex — você pode mudar abaixo.',
            style: AppTypography.caption1.copyWith(color: AppColors.textoSuave),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: 8,
            children: [
              for (final f in const ['SEMANAL', 'QUINZENAL', 'MENSAL'])
                ChoiceChip(
                  label: Text(switch (f) {
                    'SEMANAL' => 'Semanal',
                    'MENSAL' => 'Mensal',
                    _ => 'Quinzenal',
                  }),
                  selected: sacola.frequencia == f,
                  onSelected: (_) => sacola.escolherFrequencia(f),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('Plano', style: AppTypography.headline),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Flex'),
                selected: sacola.plano == 'FLEX',
                onSelected: (_) => sacola.escolherPlano('FLEX'),
              ),
              ChoiceChip(
                label: Text(
                  sim != null && sim.economiaPlano > 0
                      ? 'Trimestral (−${sim.economiaPlano.toStringAsFixed(2).replaceAll('.', ',')})'
                      : 'Trimestral',
                ),
                selected: sacola.plano == 'TRIMESTRAL',
                onSelected: (_) => sacola.escolherPlano('TRIMESTRAL'),
              ),
            ],
          ),
          if (sim != null && sim.faltaParaFreteGratis > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Faltam R\$ ${sim.faltaParaFreteGratis.toStringAsFixed(2).replaceAll('.', ',')} para entrega grátis',
              style: AppTypography.footnote.copyWith(color: AppColors.azulPetroleo),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          ExpansionTile(
            title: Text('Ver detalhes do preço', style: AppTypography.subheadline),
            children: [
              if (sim != null)
                for (final l in sim.detalhe)
                  ListTile(
                    dense: true,
                    title: Text(l.rotulo),
                    trailing: Text(l.valorFormatado),
                  )
              else if (sacola.erroSimulacao != null)
                ListTile(title: Text(sacola.erroSimulacao!)),
            ],
          ),
          const SizedBox(height: 100),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.margem),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (sim != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Total ${sim.total.formatado}/entrega',
                    style: AppTypography.title3.copyWith(color: AppColors.navy),
                  ),
                ),
              const SizedBox(height: AppSpacing.xs),
              BotaoPrincipal(
                rotulo: 'Continuar',
                onPressed: sacola.simulando || (sim?.abaixoDoMinimo ?? true)
                    ? null
                    : () => _continuar(context, sacola),
              ),
            ],
          ),
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

class _ItemLinha extends StatelessWidget {
  const _ItemLinha({
    required this.item,
    required this.produto,
    required this.passo,
    required this.onChange,
    this.unitario,
  });

  final ItemCesta item;
  final Produto? produto;
  final int passo;
  final String? unitario;
  final void Function(int) onChange;

  @override
  Widget build(BuildContext context) {
    final asset = produto == null ? null : assetDoProduto(produto!.codigo);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      color: AppColors.superficie,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.raioCard)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: asset == null
                  ? const ColoredBox(color: AppColors.aqua)
                  : Image.asset(asset, semanticLabel: produto?.nome),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(produto?.nome ?? item.produto, style: AppTypography.headline),
                  if (unitario != null)
                    Text('$unitario / un.', style: AppTypography.caption1.copyWith(color: AppColors.textoSuave)),
                ],
              ),
            ),
            IconButton(
              onPressed: () => onChange(item.quantidade - passo),
              icon: const Icon(Icons.remove),
            ),
            Text('${item.quantidade}', style: AppTypography.headline),
            IconButton(
              onPressed: () => onChange(item.quantidade + passo),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }
}
