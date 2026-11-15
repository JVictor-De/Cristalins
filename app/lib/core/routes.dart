import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../features/welcome/presentation/boas_vindas_screen.dart';
import 'theme/app_colors.dart';
import 'widgets/estado_vazio.dart';

/// Rotas nomeadas do app (passagem explícita entre telas).
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

  static const _titulos = <String, String>{
    cadastroLogin: 'Entrar',
    quiz: 'Quiz',
    resultado: 'Resultado',
    catalogo: 'Catálogo',
    endereco: 'Endereço',
    planoPagamento: 'Plano e pagamento',
    aguardandoPagamento: 'Pagamento',
    minhaAssinatura: 'Minha assinatura',
  };

  static Route<void>? gerar(RouteSettings settings) {
    final Widget tela;
    switch (settings.name) {
      case boasVindas:
        tela = const BoasVindasScreen();
      default:
        final titulo = _titulos[settings.name];
        if (titulo == null) return null;
        // Telas 2–8 chegam em cr-2-telas; até lá a rota existe com um estado vazio.
        tela = _TelaEmConstrucao(titulo: titulo);
    }
    return MaterialPageRoute<void>(builder: (_) => tela, settings: settings);
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
