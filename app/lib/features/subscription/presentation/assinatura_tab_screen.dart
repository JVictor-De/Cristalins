import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/dependencias.dart';
import '../../../core/network/api_erro.dart';
import '../../../core/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_assinatura.dart';
import '../../../core/widgets/estado_vazio.dart';
import '../../../core/widgets/estados.dart';
import '../../catalog/domain/catalogo.dart';
import '../../shell/presentation/shell_screen.dart';
import 'minha_assinatura_screen.dart';

/// Aba Assinatura no shell.
class AssinaturaTabScreen extends StatefulWidget {
  const AssinaturaTabScreen({super.key, required this.onIrProdutos});

  final AbrirProdutosCallback onIrProdutos;

  @override
  State<AssinaturaTabScreen> createState() => _AssinaturaTabScreenState();
}

class _AssinaturaTabScreenState extends State<AssinaturaTabScreen> {
  var _temAssinatura = false;
  var _carregando = true;
  var _erro = false;
  String? _mensagemErro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = false;
      _mensagemErro = null;
    });
    try {
      final dep = context.read<Dependencias>();
      // Visitante sem token (API real): empty real (BUGS_UX #27), não "Falha".
      // Em testes `api` é null — segue para o mock de `listar()`.
      final token = await dep.api?.tokens.lerAcesso();
      if (dep.api != null && (token == null || token.isEmpty)) {
        _temAssinatura = false;
        _erro = false;
      } else {
        final lista = await dep.assinaturas.listar();
        _temAssinatura = lista.any((a) => !a.cancelada);
        _erro = false;
      }
    } catch (e) {
      final err = ApiErro.de(e);
      _temAssinatura = false;
      if (err.codigo == 'NAO_AUTENTICADO' || err.status == 401) {
        _erro = false;
        _mensagemErro = null;
      } else {
        _erro = true;
        _mensagemErro = err.mensagem.isNotEmpty
            ? err.mensagem
            : 'Não foi possível carregar sua assinatura.';
      }
    }
    if (mounted) setState(() => _carregando = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(
        backgroundColor: AppColors.gelo,
        body: Center(child: Carregando()),
      );
    }

    if (_erro) {
      return Scaffold(
        backgroundColor: AppColors.gelo,
        body: EstadoVazio(
          icone: Icons.cloud_off_outlined,
          titulo: 'Falha ao carregar',
          subtitulo: _mensagemErro ?? 'Tente de novo.',
          rotuloAcao: 'Tentar de novo',
          onAcao: _carregar,
        ),
      );
    }

    if (!_temAssinatura) {
      return Scaffold(
        backgroundColor: AppColors.gelo,
        body: EmptyAssinatura(
          onMontarSacola: () => widget.onIrProdutos(),
          onVerAguas: () => widget.onIrProdutos(categoria: Categoria.aguas),
          onQuiz: () => Navigator.of(context).pushNamed(AppRoutes.quiz),
        ),
      );
    }

    return const MinhaAssinaturaScreen();
  }
}
