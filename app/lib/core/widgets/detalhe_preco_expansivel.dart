import 'package:flutter/material.dart';

import '../../features/catalog/domain/catalogo.dart';
import '../formatacao.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Cupom + linhas `detalhePreco` da simulação.
class DetalhePrecoExpansivel extends StatefulWidget {
  const DetalhePrecoExpansivel({
    super.key,
    required this.detalhe,
    this.subtotal,
    this.frete,
    this.total,
  });

  final List<LinhaPreco> detalhe;
  final Dinheiro? subtotal;
  final Dinheiro? frete;
  final Dinheiro? total;

  @override
  State<DetalhePrecoExpansivel> createState() => _DetalhePrecoExpansivelState();
}

class _DetalhePrecoExpansivelState extends State<DetalhePrecoExpansivel> {
  var _aberto = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => _aberto = !_aberto),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Ver detalhes do preço',
                    style: AppTypography.subheadline.copyWith(
                      color: AppColors.azulMarca,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  _aberto ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.azulMarca,
                ),
              ],
            ),
          ),
        ),
        if (_aberto) ...[
          if (widget.subtotal != null)
            _Linha('Subtotal', widget.subtotal!.formatado),
          for (final l in widget.detalhe)
            _Linha(l.rotulo, l.valorFormatado),
          if (widget.frete != null)
            _Linha('Entrega', widget.frete!.centavos == 0 ? 'Grátis' : widget.frete!.formatado),
          if (widget.total != null)
            _Linha('Total', widget.total!.formatado, destaque: true),
        ],
      ],
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha(this.rotulo, this.valor, {this.destaque = false});
  final String rotulo;
  final String valor;
  final bool destaque;

  @override
  Widget build(BuildContext context) {
    final estilo = destaque
        ? AppTypography.headline.copyWith(color: AppColors.navy)
        : AppTypography.footnote.copyWith(color: AppColors.tinta);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
      child: Row(
        children: [
          Expanded(child: Text(rotulo, style: estilo)),
          Text(valor, style: estilo),
        ],
      ),
    );
  }
}