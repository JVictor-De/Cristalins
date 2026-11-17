import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
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

/// Callback tipado: abrir aba Produtos com categoria opcional.
typedef AbrirProdutosCallback = void Function({Categoria? categoria});

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
  late Categoria? _categoriaProdutos = widget.categoriaInicial;
  int _geracaoHome = 0;
  int _geracaoAssinatura = 0;

  void _irPara(int i, {Categoria? categoria}) {
    setState(() {
      _aba = i;
      if (categoria != null) _categoriaProdutos = categoria;
      if (i == 0) _geracaoHome++;
      if (i == 2) _geracaoAssinatura++;
    });
  }

  void _selecionarAba(int i) {
    HapticFeedback.selectionClick();
    setState(() {
      _aba = i;
      if (i == 0) _geracaoHome++;
      if (i == 2) _geracaoAssinatura++;
    });
  }

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
        backgroundColor: AppColors.fundo,
        body: IndexedStack(
          index: _aba,
          children: [
            HomeScreen(
              key: ValueKey('home-$_geracaoHome'),
              onAbrirProdutos: ({Categoria? categoria}) => _irPara(1, categoria: categoria),
              onAbrirAssinatura: () => _irPara(2),
            ),
            ProdutosScreen(
              key: ValueKey('produtos-${_categoriaProdutos?.name ?? 'todos'}'),
              categoriaInicial: _categoriaProdutos,
            ),
            AssinaturaTabScreen(
              key: ValueKey('assinatura-$_geracaoAssinatura'),
              onIrProdutos: ({Categoria? categoria}) => _irPara(1, categoria: categoria),
            ),
            const PerfilScreen(),
          ],
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BarraSacola(),
            NavigationBarTheme(
              data: NavigationBarThemeData(
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  final selected = states.contains(WidgetState.selected);
                  // P5.1: inativas em heroInk (não tinta clara) — ≥ 4,5:1 sobre superficie.
                  return AppTypography.caption2.copyWith(
                    color: selected ? AppColors.navy : AppColors.heroInk,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  );
                }),
                iconTheme: WidgetStateProperty.resolveWith((states) {
                  final selected = states.contains(WidgetState.selected);
                  return IconThemeData(
                    color: selected ? AppColors.navy : AppColors.heroInk,
                    size: 24,
                  );
                }),
              ),
              child: NavigationBar(
                key: const ValueKey('shell-nav'),
                selectedIndex: _aba,
                backgroundColor: AppColors.superficie,
                indicatorColor: AppColors.indicadorAba,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                onDestinationSelected: _selecionarAba,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home),
                    label: 'Início',
                    tooltip: 'Início',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.grid_view_outlined),
                    selectedIcon: Icon(Icons.grid_view),
                    label: 'Produtos',
                    tooltip: 'Produtos',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.water_drop_outlined),
                    selectedIcon: Icon(Icons.water_drop),
                    label: 'Assinatura',
                    tooltip: 'Assinatura',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(Icons.person),
                    label: 'Perfil',
                    tooltip: 'Perfil',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
