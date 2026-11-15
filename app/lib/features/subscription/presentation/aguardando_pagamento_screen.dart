import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/dependencias.dart';
import '../../../core/formatacao.dart';
import '../../../core/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/botao_principal.dart';
import '../../../core/widgets/controles.dart';
import '../../../core/widgets/estados.dart';
import '../../../core/widgets/secao_agrupada.dart';
import '../../../core/widgets/tela_titulo_grande.dart';
import '../domain/assinatura.dart';
import 'aguardando_pagamento_controller.dart';

/// Abre a tela de espera do Pix (rota nomeada `/aguardando-pagamento`, com a assinatura criada).
Route<void> rotaAguardandoPagamento(AssinaturaCriada criada) => MaterialPageRoute<void>(
  settings: RouteSettings(name: AppRoutes.aguardandoPagamento, arguments: criada),
  builder: (_) => AguardandoPagamentoScreen(criada: criada),
);

/// Aguardando pagamento — QR e copia e cola do Pix da API; consulta o status a cada 5 s até `ATIVA`.
class AguardandoPagamentoScreen extends StatelessWidget {
  const AguardandoPagamentoScreen({super.key, required this.criada, this.intervalo});

  final AssinaturaCriada criada;

  /// Intervalo da consulta (padrão 5 s); os testes reduzem.
  final Duration? intervalo;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AguardandoPagamentoController(
        context.read<Dependencias>().assinaturas,
        criada,
        intervalo: intervalo ?? const Duration(seconds: 5),
      ),
      child: const _Conteudo(),
    );
  }
}

class _Conteudo extends StatefulWidget {
  const _Conteudo();

  @override
  State<_Conteudo> createState() => _ConteudoState();
}

class _ConteudoState extends State<_Conteudo> {
  EstadoPagamento? _anterior;

  void _irParaMinhaAssinatura(String id) {
    HapticFeedback.lightImpact();
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.minhaAssinatura, (_) => false, arguments: id);
  }

  Future<void> _copiar(String codigo) async {
    HapticFeedback.selectionClick();
    await Clipboard.setData(ClipboardData(text: codigo));
    if (mounted) mostrarAviso(context, 'Código Pix copiado. Cole no app do seu banco.');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AguardandoPagamentoController>();
    final criada = c.criada;
    final pix = criada.pix;

    // Háptica de sucesso uma vez, quando a API confirma (assinatura ativa).
    if (_anterior != EstadoPagamento.confirmado && c.estado == EstadoPagamento.confirmado) {
      HapticFeedback.mediumImpact();
    }
    _anterior = c.estado;

    final secundario = AppTypography.body.copyWith(color: AppColors.textoSecundario);
    final valor = AppTypography.title1.copyWith(
      color: AppColors.texto,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return TelaTituloGrande(
      titulo: c.estado == EstadoPagamento.confirmado ? 'Pagamento confirmado' : 'Pagamento',
      voltar: false,
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              SecaoAgrupada(
                cabecalho: 'Primeira entrega',
                rodape:
                    'Prevista para ${Datas.comDiaDaSemana(criada.dataEntrega)}. '
                    'A data é confirmada depois do pagamento.',
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.margem),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            'Valor',
                            style: AppTypography.headline.copyWith(color: AppColors.texto),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            criada.valorPrimeiroCiclo.formatado,
                            textAlign: TextAlign.end,
                            style: valor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (criada.vencimento != null)
                    LinhaLista(
                      titulo: 'Vencimento',
                      trailing: Text(Datas.curta(criada.vencimento!), style: secundario),
                    ),
                ],
              ),
              _Status(controller: c),
              if (pix != null && c.estado != EstadoPagamento.confirmado) ...[
                SecaoAgrupada(
                  cabecalho: 'Pix',
                  rodape: pix.demonstracao
                      ? 'Ambiente de demonstração: este código não é um Pix real. '
                            'O pagamento é confirmado pela equipe no modo de teste da API.'
                      : 'Abra o app do seu banco, escolha Pix copia e cola ou ler QR Code e confirme o valor.',
                  children: [
                    _QrCode(pix: pix),
                    LinhaLista(
                      titulo: 'Código copia e cola',
                      subtitulo: pix.copiaECola,
                      icone: CupertinoIcons.doc_on_clipboard,
                      onTap: () => _copiar(pix.copiaECola),
                    ),
                  ],
                ),
              ],
              if (pix == null && c.estado == EstadoPagamento.aguardando)
                const TextoDeApoio(
                  'A cobrança Pix ainda não foi gerada. Acompanhe em Minha assinatura.',
                ),
              if (c.estado != EstadoPagamento.confirmado)
                BotaoSecundario(
                  rotulo: 'Ver minha assinatura',
                  onPressed: () => _irParaMinhaAssinatura(criada.id),
                ),
            ],
          ),
        ),
      ],
      rodape: switch (c.estado) {
        EstadoPagamento.confirmado => BotaoPrincipal(
          rotulo: 'Ver minha assinatura',
          onPressed: () => _irParaMinhaAssinatura(criada.id),
        ),
        EstadoPagamento.erro => BotaoPrincipal(rotulo: 'Tentar de novo', onPressed: c.tentarDeNovo),
        EstadoPagamento.aguardando => BotaoPrincipal(
          rotulo: 'Copiar código Pix',
          onPressed: pix == null ? null : () => _copiar(pix.copiaECola),
        ),
      },
    );
  }
}

/// Estado da confirmação: aguardando (com indicador), confirmado ou erro.
class _Status extends StatelessWidget {
  const _Status({required this.controller});

  final AguardandoPagamentoController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final (titulo, subtitulo, icone, cor) = switch (c.estado) {
      EstadoPagamento.confirmado => (
        'Pagamento confirmado',
        'Sua assinatura está ativa.',
        CupertinoIcons.checkmark_circle,
        AppColors.sucesso,
      ),
      EstadoPagamento.erro => (
        'Não conseguimos confirmar agora',
        c.erro ?? 'Não conseguimos carregar agora. Tente de novo.',
        CupertinoIcons.exclamationmark_circle,
        AppColors.erro,
      ),
      EstadoPagamento.aguardando => (
        'Aguardando o pagamento',
        'Verificamos a cada 5 segundos. Pode deixar esta tela aberta.',
        CupertinoIcons.time,
        AppColors.azul800,
      ),
    };
    return SecaoAgrupada(
      cabecalho: 'Status',
      children: [
        Semantics(
          liveRegion: true,
          child: LinhaLista(
            titulo: titulo,
            subtitulo: subtitulo,
            icone: icone,
            corTitulo: c.estado == EstadoPagamento.aguardando ? null : cor,
            trailing: c.estado == EstadoPagamento.aguardando
                ? const CupertinoActivityIndicator()
                : null,
          ),
        ),
      ],
    );
  }
}

/// Lado do QR: 3 × a imagem do produto (216 dp), a partir do token do tema.
const _ladoQr = AppSpacing.imagemProduto * 3;

/// QR do Pix (PNG em base64 da API). Se não for imagem (modo fake), fica só o copia e cola.
class _QrCode extends StatelessWidget {
  const _QrCode({required this.pix});

  final PixCobranca pix;

  @override
  Widget build(BuildContext context) {
    final semImagem = Padding(
      padding: const EdgeInsets.all(AppSpacing.margem),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.qrcode,
            size: AppSpacing.iconeEstadoVazio,
            color: AppColors.textoSecundario,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              pix.demonstracao
                  ? 'QR Code de demonstração indisponível. Use o código abaixo.'
                  : 'Use o código abaixo.',
              style: AppTypography.subheadline.copyWith(color: AppColors.textoSecundario),
            ),
          ),
        ],
      ),
    );
    if (pix.demonstracao) return semImagem;
    try {
      final bytes = base64Decode(pix.qrCodeBase64);
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.margem),
        child: Center(
          child: Semantics(
            label: 'QR Code do Pix',
            image: true,
            child: Container(
              color: AppColors.superficie,
              width: _ladoQr,
              height: _ladoQr,
              child: Image.memory(bytes, fit: BoxFit.contain, errorBuilder: (_, _, _) => semImagem),
            ),
          ),
        ),
      );
    } on FormatException {
      return semImagem;
    }
  }
}
