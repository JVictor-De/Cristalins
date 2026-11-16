import 'package:flutter/material.dart';

import '../features/address/presentation/endereco_screen.dart';
import '../features/auth/presentation/cadastro_login_screen.dart';
import '../features/auth/presentation/esqueci_senha_screen.dart';
import '../features/auth/presentation/redefinir_senha_screen.dart';
import '../features/catalog/presentation/catalogo_screen.dart';
import '../features/ocorrencias/domain/ocorrencia.dart';
import '../features/ocorrencias/presentation/ocorrencia_screen.dart';
import '../features/quiz/presentation/quiz_screen.dart';
import '../features/quiz/presentation/resultado_screen.dart';
import '../features/subscription/domain/assinatura.dart';
import '../features/subscription/presentation/aguardando_pagamento_screen.dart';
import '../features/subscription/presentation/minha_assinatura_screen.dart';
import '../features/subscription/presentation/plano_pagamento_screen.dart';
import '../features/welcome/presentation/boas_vindas_screen.dart';

/// Rotas nomeadas do app. Os dados de uma etapa passam para a seguinte em `arguments`
/// (equivalente à Intent explícita): id da recomendação → [PedidoAssinatura] → [AlteracaoDeCesta].
abstract final class AppRoutes {
  static const boasVindas = '/';
  static const cadastroLogin = '/cadastro-login';
  static const esqueciSenha = '/esqueci-senha';
  static const redefinirSenha = '/redefinir-senha';
  static const quiz = '/quiz';
  static const resultado = '/resultado';
  static const catalogo = '/catalogo';
  static const endereco = '/endereco';
  static const planoPagamento = '/plano-pagamento';
  static const aguardandoPagamento = '/aguardando-pagamento';
  static const minhaAssinatura = '/minha-assinatura';
  static const ocorrencia = '/ocorrencia';

  static Route<Object?>? gerar(RouteSettings settings) {
    final args = settings.arguments;
    final Widget? tela = switch (settings.name) {
      boasVindas => const BoasVindasScreen(),
      cadastroLogin => const CadastroLoginScreen(),
      esqueciSenha => const EsqueciSenhaScreen(),
      redefinirSenha when args is String => RedefinirSenhaScreen(email: args),
      quiz => const QuizScreen(),
      resultado when args is String => ResultadoScreen(recomendacaoId: args),
      catalogo when args is AlteracaoDeCesta => CatalogoScreen(alteracao: args),
      catalogo => CatalogoScreen(pedido: args is PedidoAssinatura ? args : null),
      endereco when args is PedidoAssinatura => EnderecoScreen(pedido: args),
      planoPagamento when args is PedidoAssinatura => PlanoPagamentoScreen(pedido: args),
      aguardandoPagamento when args is AssinaturaCriada => AguardandoPagamentoScreen(criada: args),
      minhaAssinatura => MinhaAssinaturaScreen(assinaturaId: args is String ? args : null),
      ocorrencia when args is PedidoOcorrencia => OcorrenciaScreen(pedido: args),
      _ => null,
    };
    if (tela == null) return null;
    return MaterialPageRoute<Object?>(builder: (_) => tela, settings: settings);
  }
}
