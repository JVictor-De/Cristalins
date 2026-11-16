import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show MaterialPageRoute;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/dependencias.dart';
import '../../../core/formatacao.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/botao_principal.dart';
import '../../../core/widgets/controles.dart';
import '../../../core/widgets/estado_vazio.dart';
import '../../../core/widgets/estados.dart';
import '../../../core/widgets/secao_agrupada.dart';
import '../../../core/widgets/tela_titulo_grande.dart';
import '../domain/pagamento.dart';
import 'cartao_screen.dart';
import 'faturas_controller.dart';

/// Abre "Pagamentos" a partir da Tela 8 (rota da própria feature).
Route<void> rotaFaturas(String assinaturaId) => MaterialPageRoute<void>(
  settings: const RouteSettings(name: '/pagamentos'),
  builder: (_) => FaturasScreen(assinaturaId: assinaturaId),
);

/// Pagamentos — forma de pagamento (seção agrupada), faturas e comprovantes.
class FaturasScreen extends StatelessWidget {
  const FaturasScreen({super.key, required this.assinaturaId});

  final String assinaturaId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          FaturasController(context.read<Dependencias>().assinaturas, assinaturaId: assinaturaId),
      child: const _Conteudo(),
    );
  }
}

class _Conteudo extends StatelessWidget {
  const _Conteudo();

  static const titulo = 'Pagamentos';

  Future<void> _abrir(BuildContext context, String url, String falha) async {
    final abriu = await context.read<Dependencias>().links.abrir(url);
    if (!abriu && context.mounted) mostrarAviso(context, falha, erro: true);
  }

  Future<void> _escolher(BuildContext context, FaturasController c, FormaPagamento f) async {
    HapticFeedback.selectionClick();
    if (f == FormaPagamento.cartao) {
      await _escolherCartao(context, c);
      return;
    }
    if (c.forma?.forma == f) return;
    final erro = await c.trocar(f);
    if (!context.mounted) return;
    if (erro != null) {
      mostrarAviso(context, erro, erro: true);
    } else {
      HapticFeedback.lightImpact();
      mostrarAviso(context, '${f.rotulo} vale a partir da próxima cobrança.');
    }
  }

  /// Com cartões salvos, uma folha para escolher; sem cartão, abre o cadastro.
  Future<void> _escolherCartao(BuildContext context, FaturasController c) async {
    String? escolhido;
    if (c.cartoes.isNotEmpty) {
      escolhido = await showCupertinoModalPopup<String>(
        context: context,
        builder: (ctx) => CupertinoActionSheet(
          title: const Text('Cartão de crédito'),
          message: const Text('A cobrança vem no cartão a partir da próxima entrega.'),
          actions: [
            for (final cartao in c.cartoes)
              CupertinoActionSheetAction(
                onPressed: () => Navigator.pop(ctx, cartao.id),
                child: Text(cartao.rotulo),
              ),
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(ctx, ''),
              child: const Text('Adicionar outro cartão'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Voltar'),
          ),
        ),
      );
      if (escolhido == null || !context.mounted) return;
    }
    if (escolhido == null || escolhido.isEmpty) {
      final salvou = await Navigator.of(context).push<bool>(rotaCartao(c));
      if (salvou == true && context.mounted) {
        HapticFeedback.mediumImpact();
        mostrarAviso(context, 'Cartão salvo. Vale a partir da próxima cobrança.');
      }
      return;
    }
    final erro = await c.trocar(FormaPagamento.cartao, cartaoId: escolhido);
    if (!context.mounted) return;
    if (erro != null) {
      mostrarAviso(context, erro, erro: true);
    } else {
      HapticFeedback.lightImpact();
      mostrarAviso(context, 'Cartão vale a partir da próxima cobrança.');
    }
  }

  Future<void> _comprovante(BuildContext context, FaturasController c, Fatura f) async {
    HapticFeedback.selectionClick();
    final (url, erro) = await c.comprovante(f);
    if (!context.mounted) return;
    if (url == null) {
      mostrarAviso(context, erro ?? 'O comprovante ainda não está disponível.', erro: true);
      return;
    }
    await _abrir(context, url, 'Não conseguimos abrir o comprovante agora.');
  }

  Future<void> _pagar(BuildContext context, Fatura f) async {
    HapticFeedback.lightImpact();
    await _abrir(
      context,
      f.link!,
      f.forma == FormaPagamento.boleto
          ? 'Não conseguimos abrir o boleto agora.'
          : 'Não conseguimos abrir a fatura agora.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<FaturasController>();

    if (c.carregando && c.forma == null) {
      return const TelaTituloGrande(
        titulo: titulo,
        slivers: [SliverFillRemaining(hasScrollBody: false, child: Carregando())],
      );
    }
    if (c.erro != null) {
      return TelaTituloGrande(
        titulo: titulo,
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: EstadoErro(mensagem: c.erro!, onTentarDeNovo: c.carregar),
          ),
        ],
      );
    }

    final atual = c.forma;
    final secundario = AppTypography.body.copyWith(color: AppColors.textoSecundario);
    final emAberto = c.faturas.where((f) => f.emAberto && f.link != null).firstOrNull;

    return TelaTituloGrande(
      titulo: titulo,
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              SecaoAgrupada(
                cabecalho: 'Forma de pagamento',
                rodape:
                    'Vale para a próxima cobrança; a atual não muda. '
                    'O cartão é guardado no Asaas: o app não guarda número nem código de segurança.',
                children: [
                  for (final f in FormaPagamento.values)
                    _LinhaForma(
                      forma: f,
                      selecionada: atual?.forma == f,
                      detalhe: f == FormaPagamento.cartao ? atual?.cartao?.rotulo : null,
                      onTap: c.executando ? null : () => _escolher(context, c, f),
                    ),
                ],
              ),
              if (c.faturas.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.secaoGrande),
                  child: EstadoVazio(
                    icone: CupertinoIcons.doc_text,
                    mensagem: 'Suas faturas aparecem aqui depois da primeira cobrança.',
                  ),
                )
              else
                SecaoAgrupada(
                  cabecalho: 'Faturas',
                  rodape: 'Toque numa fatura paga para ver o comprovante.',
                  children: [
                    for (final f in c.faturas)
                      _LinhaFatura(
                        fatura: f,
                        estiloValor: secundario,
                        onTap: f.temComprovante
                            ? () => _comprovante(context, c, f)
                            : (f.emAberto && f.link != null ? () => _pagar(context, f) : null),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
      rodape: emAberto == null
          ? null
          : BotaoPrincipal(
              rotulo: emAberto.forma == FormaPagamento.boleto
                  ? 'Abrir boleto'
                  : 'Pagar fatura em aberto',
              onPressed: () => _pagar(context, emAberto),
            ),
    );
  }
}

class _LinhaForma extends StatelessWidget {
  const _LinhaForma({
    required this.forma,
    required this.selecionada,
    required this.onTap,
    this.detalhe,
  });

  final FormaPagamento forma;
  final bool selecionada;
  final String? detalhe;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selecionada,
      inMutuallyExclusiveGroup: true,
      child: LinhaLista(
        titulo: forma.rotulo,
        subtitulo: detalhe,
        icone: switch (forma) {
          FormaPagamento.pix => CupertinoIcons.qrcode,
          FormaPagamento.boleto => CupertinoIcons.doc_plaintext,
          FormaPagamento.cartao => CupertinoIcons.creditcard,
        },
        trailing: selecionada
            ? const Icon(
                CupertinoIcons.checkmark_alt,
                color: AppColors.azul800,
                size: AppSpacing.icone,
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}

class _LinhaFatura extends StatelessWidget {
  const _LinhaFatura({required this.fatura, required this.estiloValor, required this.onTap});

  final Fatura fatura;
  final TextStyle estiloValor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final f = fatura;
    final selo = seloDaFatura(f.status);
    final partes = [
      f.forma.rotulo,
      if (f.emAberto) 'vence ${Datas.curta(f.vencimento)}',
      ?f.observacao,
    ];
    return LinhaLista(
      titulo: 'Entrega de ${Datas.curta(f.dataEntrega)}',
      subtitulo: partes.join(' · '),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            f.valor.formatado,
            style: estiloValor.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Selo(texto: selo.texto, fundo: selo.fundo, cor: selo.cor),
        ],
      ),
      onTap: onTap,
    );
  }
}
