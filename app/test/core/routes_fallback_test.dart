import 'package:cristalins_assinatura/core/routes.dart';
import 'package:cristalins_assinatura/features/auth/presentation/esqueci_senha_screen.dart';
import 'package:cristalins_assinatura/features/catalog/presentation/catalogo_screen.dart';
import 'package:cristalins_assinatura/features/catalog/presentation/sacola_screen.dart';
import 'package:cristalins_assinatura/features/quiz/presentation/quiz_screen.dart';
import 'package:cristalins_assinatura/features/quiz/presentation/resultado_screen.dart';
import 'package:cristalins_assinatura/features/subscription/presentation/minha_assinatura_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget tela(String nome, {Object? arguments}) {
    final rota = AppRoutes.gerar(RouteSettings(name: nome, arguments: arguments));
    expect(rota, isA<MaterialPageRoute<Object?>>());
    return (rota! as MaterialPageRoute<Object?>).builder(_FakeContext());
  }

  test('rotas com args obrigatórios fazem fallback seguro sem arguments', () {
    expect(tela(AppRoutes.resultado), isA<QuizScreen>());
    expect(tela(AppRoutes.resultado, arguments: 'rec-1'), isA<ResultadoScreen>());
    expect(tela(AppRoutes.endereco), isA<SacolaScreen>());
    expect(tela(AppRoutes.planoPagamento), isA<SacolaScreen>());
    expect(tela(AppRoutes.produto), isA<CatalogoScreen>());
    expect(tela(AppRoutes.redefinirSenha), isA<EsqueciSenhaScreen>());
    expect(tela(AppRoutes.aguardandoPagamento), isA<MinhaAssinaturaScreen>());
    expect(tela(AppRoutes.ocorrencia), isA<MinhaAssinaturaScreen>());
  });

  test('rota desconhecida devolve null', () {
    expect(AppRoutes.gerar(const RouteSettings(name: '/nao-existe')), isNull);
  });
}

/// Contexto mínimo só para invocar o `builder` da rota (widgets const não usam o context).
class _FakeContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
