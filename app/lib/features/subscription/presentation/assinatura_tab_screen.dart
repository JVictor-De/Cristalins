import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/dependencias.dart';
import '../../../core/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_assinatura.dart';
import '../../../core/widgets/estados.dart';
import 'minha_assinatura_screen.dart';

/// Aba Assinatura no shell.
class AssinaturaTabScreen extends StatefulWidget {
  const AssinaturaTabScreen({super.key, required this.onIrProdutos});

  final VoidCallback onIrProdutos;

  @override
  State<AssinaturaTabScreen> createState() => _AssinaturaTabScreenState();
}

class _AssinaturaTabScreenState extends State<AssinaturaTabScreen> {
  var _temAssinatura = false;
  var _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final lista = await context.read<Dependencias>().assinaturas.listar();
      _temAssinatura = lista.any((a) => !a.cancelada);
    } catch (_) {
      _temAssinatura = false;
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

    if (!_temAssinatura) {
      return Scaffold(
        backgroundColor: AppColors.gelo,
        body: EmptyAssinatura(
          onMontarSacola: widget.onIrProdutos,
          onVerAguas: widget.onIrProdutos,
          onQuiz: () => Navigator.of(context).pushNamed(AppRoutes.quiz),
        ),
      );
    }

    return const MinhaAssinaturaScreen();
  }
}