import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/dependencias.dart';
import '../../../core/formatacao.dart';
import '../../../core/intents/navegacao_nativa.dart';
import '../../../core/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/botao_principal.dart';
import '../../../core/widgets/controles.dart';
import '../../../core/widgets/estados.dart';
import '../../subscription/domain/assinatura.dart';
import '../domain/catalogo.dart';
import '../domain/produto_assets.dart';
import 'cesta_controller.dart';

/// Fluxo legado de cesta (pedido/alteração). A aba marketplace é [ProdutosScreen].
class CatalogoScreen extends StatelessWidget {
  const CatalogoScreen({super.key, this.pedido, this.alteracao});

  final PedidoAssinatura? pedido;
  final AlteracaoDeCesta? alteracao;

  @override
  Widget build(BuildContext context) {
    final dep = context.read<Dependencias>();
    return ChangeNotifierProvider(
      create: (_) => CestaController(
        dep.catalogo,
        dep.assinaturas,
        itensIniciais: alteracao?.itens ?? pedido?.itens ?? const [],
        frequencia: alteracao?.frequencia ?? pedido?.frequencia ?? 'QUINZENAL',
        plano: alteracao?.plano ?? 'FLEX',
        assinaturaId: alteracao?.assinaturaId,
      ),
      child: _FluxoLegado(pedido: pedido),
    );
  }
}

class _FluxoLegado extends StatelessWidget {
  const _FluxoLegado({this.pedido});

  final PedidoAssinatura? pedido;

  Future<void> _confirmar(BuildContext context, CestaController c) async {
    HapticFeedback.lightImpact();
    if (c.assinaturaId == null) {
      final base = pedido ?? const PedidoAssinatura(itens: []);
      await NavegacaoNativa.instancia.abrir(
        context,
        activity: NavegacaoNativa.endereco,
        rota: AppRoutes.endereco,
        arguments: base.copyWith(itens: c.itens),
      );
      return;
    }
    final aPartirDe = await c.salvarAlteracao();
    if (!context.mounted) return;
    if (aPartirDe == null) {
      mostrarAviso(
        context,
        c.erroSimulacao ?? 'Não conseguimos salvar a cesta. Tente de novo.',
        erro: true,
      );
      return;
    }
    mostrarAviso(context, 'Cesta alterada. Vale a partir da entrega de ${Datas.curta(aPartirDe)}.');
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<CestaController>();
    return Scaffold(
      backgroundColor: AppColors.fundo,
      appBar: AppBar(title: Text(c.assinaturaId == null ? 'Sua cesta' : 'Alterar cesta')),
      body: c.carregando
          ? const Center(child: CircularProgressIndicator())
          : c.erroCarregar != null
          ? EstadoErro(mensagem: c.erroCarregar!, onTentarDeNovo: c.carregar)
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.margem),
              children: [
                for (final p in c.visiveis) _LinhaCestaLegado(produto: p),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Water Protein e Flow Fiber dividem a caixa de 6. '
                  'As águas vêm na embalagem de venda.',
                  style: AppTypography.footnote.copyWith(color: AppColors.textoSuave),
                ),
                if (c.erroSimulacao != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    c.erroSimulacao!,
                    style: AppTypography.footnote.copyWith(color: AppColors.erro),
                  ),
                ],
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.margem),
          child: BotaoPrincipal(
            rotulo: c.assinaturaId == null ? 'Continuar' : 'Salvar cesta',
            carregando: c.salvando,
            onPressed: c.podeContinuar ? () => _confirmar(context, c) : null,
          ),
        ),
      ),
    );
  }
}

/// Linha da cesta legada (pedido / alterar) — imagem + [SeletorQuantidade] (a11y Tela 5).
class _LinhaCestaLegado extends StatelessWidget {
  const _LinhaCestaLegado({required this.produto});

  final Produto produto;

  @override
  Widget build(BuildContext context) {
    final c = context.watch<CestaController>();
    final quantidade = c.quantidades[produto.codigo] ?? 0;
    final asset = assetDoProduto(produto.codigo);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(AppSpacing.raioCard),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.raioChip),
                    child: SizedBox(
                      width: AppSpacing.imagemProduto,
                      height: AppSpacing.imagemProduto,
                      child: ColoredBox(
                        color: corDoProduto(produto.codigo).withValues(alpha: 0.35),
                        child: asset == null
                            ? const Icon(Icons.water_drop_outlined, color: AppColors.azulMarca)
                            : Image.asset(
                                asset,
                                fit: BoxFit.contain,
                                semanticLabel: produto.nome,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          produto.rotuloTipo,
                          style: AppTypography.caption1.copyWith(color: AppColors.textoSuave),
                        ),
                        Text(
                          nomeCardProduto(produto),
                          style: AppTypography.headline.copyWith(color: AppColors.tinta),
                        ),
                        Text(
                          produto.pack,
                          style: AppTypography.subheadline.copyWith(color: AppColors.textoSuave),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: SeletorQuantidade(
                  rotulo: nomeCardProduto(produto),
                  quantidade: quantidade,
                  passo: c.passo(produto),
                  onAlterar: (q) => c.alterar(produto.codigo, q),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
