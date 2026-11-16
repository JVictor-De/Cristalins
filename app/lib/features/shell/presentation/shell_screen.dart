import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/barra_sacola.dart';
import '../../catalog/domain/catalogo.dart';
import '../../home/presentation/home_screen.dart';
import '../../catalog/presentation/produtos_screen.dart';
import '../../profile/presentation/perfil_screen.dart';
import '../../subscription/presentation/assinatura_tab_screen.dart';

/// Args opcionais ao abrir o shell (onboarding / deep link).
class ShellArgs {
  const ShellArgs({this.abaInicial = 0, this.categoriaInicial});

  final int abaInicial;
  final Categoria? categoriaInicial;
}

/// Shell com 4 abas + [BarraSacola] quando há itens.
class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key, this.abaInicial = 0, this.categoriaInicial});

  final int abaInicial;
  final Categoria? categoriaInicial;

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  late int _aba = widget.abaInicial.clamp(0, 3);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _aba == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _aba != 0) {
          setState(() => _aba = 0);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.gelo,
        body: IndexedStack(
          index: _aba,
          children: [
            HomeScreen(
              onAbrirProdutos: () => _irPara(1),
              onAbrirAssinatura: () => _irPara(2),
            ),
            ProdutosScreen(categoriaInicial: widget.categoriaInicial),
            AssinaturaTabScreen(onIrProdutos: () => _irPara(1)),
            const PerfilScreen(),
          ],
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BarraSacola(),
            NavigationBar(
              selectedIndex: _aba,
              backgroundColor: AppColors.superficie,
              indicatorColor: AppColors.gelo,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              onDestinationSelected: (i) {
                HapticFeedback.selectionClick();
                setState(() => _aba = i);
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home, color: AppColors.navy),
                  label: 'Início',
                ),
                NavigationDestination(
                  icon: Icon(Icons.grid_view_outlined),
                  selectedIcon: Icon(Icons.grid_view, color: AppColors.navy),
                  label: 'Produtos',
                ),
                NavigationDestination(
                  icon: Icon(Icons.autorenew_outlined),
                  selectedIcon: Icon(Icons.autorenew, color: AppColors.navy),
                  label: 'Assinatura',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person, color: AppColors.navy),
                  label: 'Perfil',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _irPara(int i) => setState(() => _aba = i);
}