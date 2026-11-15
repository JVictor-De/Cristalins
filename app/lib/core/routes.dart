import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../features/address/presentation/endereco_screen.dart';
import '../features/auth/presentation/cadastro_login_screen.dart';
import '../features/catalog/presentation/catalogo_screen.dart';
import '../features/quiz/presentation/quiz_screen.dart';
import '../features/quiz/presentation/resultado_screen.dart';
import '../features/subscription/domain/assinatura.dart';
import '../features/subscription/presentation/minha_assinatura_screen.dart';
import '../features/subscription/presentation/plano_pagamento_screen.dart';
import '../features/welcome/presentation/boas_vindas_screen.dart';
import 'theme/app_colors.dart';
import 'widgets/estado_vazio.dart';

/// Rotas nomeadas do app. Os dados de uma etapa passam para a seguinte em `arguments`
/// (equivalente à Intent explícita): id da recomendação → [PedidoAssinatura] → [AlteracaoDeCesta].
abstract final class AppRoutes {
  static const boasVindas = '/';
  static const cadastroLogin = '/cadastro-login';
  static const quiz = '/quiz';
  static const resultado = '/resultado';
  static const catalogo = '/catalogo';
  static const endereco = '/endereco';
  static const planoPagamento = '/plano-pagamento';
  static const aguardandoPagamento = '/aguardando-pagamento';
  static const minhaAssinatura = '/minha-assinatura';

  static Route<Object?>? gerar(RouteSettings settings) {
    final args = settings.arguments;
    final Widget? tela = switch (settings.name) {
      boasVindas => const BoasVindasScreen(),
      cadastroLogin => const CadastroLoginScreen(),
      quiz => const QuizScreen(),
      resultado when args is String => ResultadoScreen(recomendacaoId: args),
      catalogo when args is AlteracaoDeCesta => CatalogoScreen(alteracao: args),
      catalogo => CatalogoScreen(pedido: args is PedidoAssinatura ? args : null),
      endereco when args is PedidoAssinatura => EnderecoScreen(pedido: args),
      planoPagamento when args is PedidoAssinatura => PlanoPagamentoScreen(pedido: args),
      minhaAssinatura => MinhaAssinaturaScreen(assinaturaId: args is String ? args : null),
      // QR Code Pix e "Aguardando pagamento" chegam em cr-3-tela.
      aguardandoPagamento => const _TelaEmConstrucao(titulo: 'Pagamento'),
      _ => null,
    };
    if (tela == null) return null;
    return MaterialPageRoute<Object?>(builder: (_) => tela, settings: settings);
  }
}

class _TelaEmConstrucao extends StatelessWidget {
  const _TelaEmConstrucao({required this.titulo});

  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(titulo),
            backgroundColor: AppColors.fundoAgrupado,
            border: null,
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: EstadoVazio(
              icone: CupertinoIcons.hammer,
              mensagem: 'Esta tela ainda está em construção.',
              rotuloAcao: 'Voltar',
              onAcao: () => Navigator.of(context).maybePop(),
            ),
          ),
        ],
      ),
    );
  }
}
