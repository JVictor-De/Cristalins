import 'package:flutter/material.dart';

import '../features/address/presentation/endereco_screen.dart';
import '../features/auth/presentation/cadastro_login_screen.dart';
import '../features/auth/presentation/esqueci_senha_screen.dart';
import '../features/auth/presentation/redefinir_senha_screen.dart';
import '../features/catalog/presentation/catalogo_screen.dart';
import '../features/catalog/presentation/produto_screen.dart';
import '../features/catalog/presentation/sacola_screen.dart';
import '../features/ocorrencias/domain/ocorrencia.dart';
import '../features/ocorrencias/presentation/ocorrencia_screen.dart';
import '../features/quiz/presentation/quiz_screen.dart';
import '../features/quiz/presentation/resultado_screen.dart';
import '../features/shell/presentation/shell_screen.dart';
import '../features/subscription/domain/assinatura.dart';
import '../features/subscription/presentation/aguardando_pagamento_screen.dart';
import '../features/subscription/presentation/minha_assinatura_screen.dart';
import '../features/subscription/presentation/plano_pagamento_screen.dart';
import '../features/welcome/presentation/boas_vindas_screen.dart';
import '../features/welcome/presentation/onboarding_screen.dart';
import '../features/welcome/presentation/splash_screen.dart';

/// Rotas nomeadas do app marketplace.
abstract final class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const shell = '/shell';
  static const boasVindas = '/boas-vindas';
  static const cadastroLogin = '/cadastro-login';
  static const esqueciSenha = '/esqueci-senha';
  static const redefinirSenha = '/redefinir-senha';
  static const quiz = '/quiz';
  static const resultado = '/resultado';
  static const catalogo = '/catalogo';
  static const produto = '/produto';
  static const sacola = '/sacola';
  static const endereco = '/endereco';
  static const planoPagamento = '/plano-pagamento';
  static const aguardandoPagamento = '/aguardando-pagamento';
  static const minhaAssinatura = '/minha-assinatura';
  static const ocorrencia = '/ocorrencia';

  static Route<Object?>? gerar(RouteSettings settings) {
    final args = settings.arguments;
    final Widget? tela = switch (settings.name) {
      splash => const SplashScreen(),
      onboarding => const OnboardingScreen(),
      shell when args is ShellArgs => ShellScreen(
        abaInicial: args.abaInicial,
        categoriaInicial: args.categoriaInicial,
      ),
      shell => ShellScreen(abaInicial: args is int ? args : 0),
      boasVindas => const BoasVindasScreen(), // alias → OnboardingScreen
      cadastroLogin => const CadastroLoginScreen(),
      esqueciSenha => const EsqueciSenhaScreen(),
      redefinirSenha when args is String => RedefinirSenhaScreen(email: args),
      quiz => const QuizScreen(),
      resultado when args is String => ResultadoScreen(recomendacaoId: args),
      catalogo when args is AlteracaoDeCesta => CatalogoScreen(alteracao: args),
      catalogo => CatalogoScreen(pedido: args is PedidoAssinatura ? args : null),
      produto when args is String => ProdutoScreen(codigo: args),
      sacola => const SacolaScreen(),
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
