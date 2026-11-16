import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/dependencias.dart';
import '../../../core/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/botao_principal.dart';

/// Perfil mínimo — guest e logado.
class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  var _logado = false;
  var _carregando = true;
  var _iniciou = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_iniciou) {
      _iniciou = true;
      _checarSessao();
    }
  }

  Future<void> _checarSessao() async {
    final token = await context.read<Dependencias>().api?.tokens.lerAcesso();
    if (mounted) {
      setState(() {
        _logado = token != null && token.isNotEmpty;
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<AppConfig>();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.margem),
        children: [
          Text('Perfil', style: AppTypography.largeTitle.copyWith(color: AppColors.navy)),
          const SizedBox(height: AppSpacing.secao),
          if (_carregando)
            const Center(child: CircularProgressIndicator())
          else if (!_logado) ...[
            Text(
              'Entre para ver endereços, pagamento e faturas.',
              style: AppTypography.body.copyWith(color: AppColors.textoSuave),
            ),
            const SizedBox(height: AppSpacing.margem),
            BotaoPrincipal(
              rotulo: 'Entrar',
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.cadastroLogin),
            ),
            const SizedBox(height: AppSpacing.sm),
            BotaoPrincipal(
              rotulo: 'Explorar sem entrar',
              variante: VarianteBotaoPrincipal.contorno,
              onPressed: () {},
            ),
          ] else ...[
            ListTile(
              title: const Text('Minha assinatura'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.minhaAssinatura),
            ),
            ListTile(
              title: const Text('Faturas e pagamento'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.minhaAssinatura),
            ),
          ],
          const Divider(height: AppSpacing.secao),
          ListTile(
            title: const Text('Site Cristalins'),
            onTap: () => context.read<Dependencias>().links.abrir(AppConfig.siteMarca),
          ),
          if (config.suporteWhatsapp.isNotEmpty)
            ListTile(
              title: const Text('WhatsApp'),
              onTap: () => context.read<Dependencias>().links.abrir(
                'https://wa.me/${config.suporteWhatsapp}',
              ),
            ),
        ],
      ),
    );
  }
}