import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../features/catalog/domain/catalogo.dart';
import '../../features/catalog/domain/produto_assets.dart';
import '../theme/app_colors.dart';
import '../theme/app_sombras.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'folha_lista_espera.dart';
import 'stepper_quantidade.dart';

/// Card foto-âncora (P0 design_ux_ui): o bloco de cor **é** o card; nome, pack e
/// preço ficam soltos sobre o fundo da tela (sem caixa branca no texto).
/// Preço = âncora `precoBase` (“A partir de”); total da assinatura só via simulação.
/// `precoAvulso` (API) aparece riscado ao lado do pack; `estoque == 0` troca o “+” por “Avise-me”.
class CardProduto extends StatelessWidget {
  const CardProduto({
    super.key,
    required this.produto,
    required this.onAbrir,
    required this.onAdicionar,
    required this.onAlterar,
    required this.passo,
    this.quantidade = 0,
    this.onAvisarMe,
  });

  final Produto produto;
  final VoidCallback onAbrir;
  final VoidCallback onAdicionar;
  final ValueChanged<int> onAlterar;
  final int passo;
  final int quantidade;

  /// Esgotado: padrão abre a folha de lista de espera com este produto.
  final VoidCallback? onAvisarMe;

  /// Espaço entre bloco e texto (~12 px).
  static const gapTexto = AppSpacing.sm;

  /// Altura das 3 linhas de texto (16/13/16 com line-height do token), sem escala.
  static const alturaTextoBase = 21.0 + 18.0 + 21.0;

  /// Altura total para um bloco de [alturaBloco], respeitando a escala de fonte.
  static double alturaPara(double alturaBloco, TextScaler escala) =>
      alturaBloco + gapTexto + escala.scale(21) + escala.scale(18) + escala.scale(21) + 2;

  void _abrir() {
    HapticFeedback.selectionClick();
    onAbrir();
  }

  @override
  Widget build(BuildContext context) {
    final asset = assetCardProduto(produto.codigo);
    final nomeCurto = nomeCardProduto(produto);
    final preco = produto.precoBase.formatado;
    final avulso = produto.precoAvulso?.formatado;
    final raio = BorderRadius.circular(AppSpacing.raioBlocoProduto);

    return Semantics(
      container: true,
      button: true,
      label:
          '${produto.nome}, ${produto.pack}, a partir de $preco por unidade'
          '${avulso == null ? '' : ' na assinatura, avulso $avulso'}'
          '${produto.esgotado ? ', esgotado' : ''}',
      hint: 'Abrir detalhes',
      onTap: _abrir,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: raio,
          excludeFromSemantics: true,
          onTap: _abrir,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ExcludeSemantics(
                        child: _BlocoFoto(produto: produto, asset: asset, raio: raio),
                      ),
                    ),
                    if (produto.esgotado)
                      const Positioned(
                        left: AppSpacing.xs,
                        top: AppSpacing.xs,
                        child: ExcludeSemantics(child: _SeloEsgotado()),
                      ),
                    Positioned(
                      right: AppSpacing.xxs,
                      bottom: AppSpacing.xxs,
                      child: quantidade == 0 && produto.esgotado
                          ? _BotaoAvisarMe(
                              label: 'Avise-me quando ${produto.nome} voltar ao estoque',
                              onTap:
                                  onAvisarMe ??
                                  () => abrirFolhaListaEspera(context, produto: produto),
                            )
                          : quantidade > 0
                          ? DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppColors.superficie,
                                borderRadius: BorderRadius.circular(AppSpacing.raioBotao + 2),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(2),
                                child: StepperQuantidade(
                                  quantidade: quantidade,
                                  passo: passo,
                                  rotulo: produto.nome,
                                  onAlterar: onAlterar,
                                ),
                              ),
                            )
                          : _BotaoAdicionar(
                              label:
                                  'Adicionar ${produto.nome}, ${produto.pack}, à assinatura, a partir de $preco por unidade',
                              onTap: () {
                                onAdicionar();
                                final messenger = ScaffoldMessenger.maybeOf(context);
                                messenger
                                  ?..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    const SnackBar(
                                      content: Text('Adicionado à sacola'),
                                      behavior: SnackBarBehavior.floating,
                                      duration: Duration(milliseconds: 1600),
                                    ),
                                  );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: gapTexto),
              ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nomeCurto,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.cardNome.copyWith(color: AppColors.heroInk),
                    ),
                    if (avulso == null)
                      Text(
                        produto.pack,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.cardDetalhe.copyWith(color: AppColors.textoSuave),
                      )
                    else
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text.rich(
                          key: const ValueKey('card-preco-avulso'),
                          TextSpan(
                            style: AppTypography.cardDetalhe.copyWith(color: AppColors.textoSuave),
                            children: [
                              TextSpan(text: '${produto.pack} · Avulso '),
                              TextSpan(
                                text: avulso,
                                style: const TextStyle(decoration: TextDecoration.lineThrough),
                              ),
                            ],
                          ),
                          maxLines: 1,
                        ),
                      ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'A partir de ',
                              style: AppTypography.cardDetalhe.copyWith(
                                color: AppColors.textoSuave,
                              ),
                            ),
                            TextSpan(
                              text: preco,
                              style: AppTypography.cardPreco.copyWith(color: AppColors.heroInk),
                            ),
                            TextSpan(
                              text: '/un.',
                              style: AppTypography.cardDetalhe.copyWith(
                                color: AppColors.textoSuave,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 1,
                      ),
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
}

/// Bloco de cor raio 28 com garrafa alinhada na base + sombra elíptica de contato.
class _BlocoFoto extends StatelessWidget {
  const _BlocoFoto({required this.produto, required this.asset, required this.raio});

  final Produto produto;
  final String? asset;
  final BorderRadius raio;

  @override
  Widget build(BuildContext context) {
    final escala = escalaGarrafaCard(produto);

    return ClipRRect(
      borderRadius: raio,
      child: ColoredBox(
        color: fundoBlocoProduto(produto.codigo),
        child: LayoutBuilder(
          builder: (context, c) {
            // ~12 px de folga na base; garrafa ocupa a fração da altura útil.
            const folga = AppSpacing.sm;
            final util = (c.maxHeight - folga * 2).clamp(0.0, double.infinity);
            final alturaGarrafa = util * escala.altura;
            final larguraGarrafa = c.maxWidth * escala.largura;
            final larguraSombra = larguraGarrafa * 0.55;

            return Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Positioned(
                  bottom: folga - 3,
                  child: Container(
                    width: larguraSombra,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.elliptical(larguraSombra / 2, 4)),
                      boxShadow: AppSombras.garrafaContato,
                    ),
                  ),
                ),
                Positioned(
                  bottom: folga,
                  child: SizedBox(
                    width: larguraGarrafa,
                    height: alturaGarrafa,
                    child: asset == null
                        ? const SizedBox.shrink()
                        : Image.asset(
                            asset!,
                            fit: BoxFit.contain,
                            alignment: Alignment.bottomCenter,
                            cacheHeight: 600,
                            errorBuilder: (_, _, _) => const SizedBox.shrink(),
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// “+” navy 40 visível / 48 de toque, com haptic e escala 0,96 ao pressionar.
class _BotaoAdicionar extends StatefulWidget {
  const _BotaoAdicionar({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_BotaoAdicionar> createState() => _BotaoAdicionarState();
}

class _BotaoAdicionarState extends State<_BotaoAdicionar> {
  var _pressionado = false;

  void _set(bool v) {
    if (_pressionado != v) setState(() => _pressionado = v);
  }

  @override
  Widget build(BuildContext context) {
    final semMovimento = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return Semantics(
      button: true,
      label: widget.label,
      excludeSemantics: true,
      onTap: widget.onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapCancel: () => _set(false),
        onTapUp: (_) => _set(false),
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        child: SizedBox(
          width: AppSpacing.toqueMinimo,
          height: AppSpacing.toqueMinimo,
          child: Center(
            child: AnimatedScale(
              scale: _pressionado ? 0.96 : 1,
              duration: semMovimento ? Duration.zero : AppDurations.toque,
              curve: Curves.easeOut,
              child: Container(
                width: AppSpacing.botaoAdicionarCard,
                height: AppSpacing.botaoAdicionarCard,
                decoration: const BoxDecoration(color: AppColors.heroNavy, shape: BoxShape.circle),
                child: const Icon(Icons.add, color: AppColors.sobrePrimaria, size: 22),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SeloEsgotado extends StatelessWidget {
  const _SeloEsgotado();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('selo-esgotado'),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(AppSpacing.raioChip),
      ),
      child: Text(
        'Esgotado',
        style: AppTypography.caption2.copyWith(color: AppColors.navy, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Pílula navy 36 visível / 48 de toque no lugar do “+” quando o produto está esgotado.
class _BotaoAvisarMe extends StatelessWidget {
  const _BotaoAvisarMe({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        key: const ValueKey('card-avise-me'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: AppSpacing.toqueMinimo,
          child: Center(
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.heroNavy,
                borderRadius: BorderRadius.circular(AppSpacing.raioChip),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.notifications_none, color: AppColors.sobrePrimaria, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Avise-me',
                    style: AppTypography.caption1.copyWith(
                      color: AppColors.sobrePrimaria,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
