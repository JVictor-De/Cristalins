import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/dependencias.dart';
import '../../../core/network/api_erro.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/botao_principal.dart';
import '../../../core/widgets/estados.dart';
import '../../../core/widgets/secao_agrupada.dart';
import '../../../core/widgets/tela_titulo_grande.dart';
import '../domain/validadores.dart';
import 'redefinir_senha_screen.dart';

Route<void> rotaEsqueciSenha() => MaterialPageRoute<void>(
  builder: (_) => const EsqueciSenhaScreen(),
  settings: const RouteSettings(name: '/esqueci-senha'),
);

/// RF52 — pede o código por e-mail (sempre a mesma resposta da API).
class EsqueciSenhaScreen extends StatefulWidget {
  const EsqueciSenhaScreen({super.key});

  @override
  State<EsqueciSenhaScreen> createState() => _EsqueciSenhaScreenState();
}

class _EsqueciSenhaScreenState extends State<EsqueciSenhaScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _enviando = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_form.currentState!.validate()) {
      HapticFeedback.lightImpact();
      return;
    }
    HapticFeedback.lightImpact();
    setState(() => _enviando = true);
    try {
      final msg = await context.read<Dependencias>().auth.esqueciSenha(_email.text.trim().toLowerCase());
      if (!mounted) return;
      mostrarAviso(context, msg);
      await Navigator.of(context).push(rotaRedefinirSenha(_email.text.trim().toLowerCase()));
    } on ApiErro catch (e) {
      if (mounted) mostrarAviso(context, e.mensagem, erro: true);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TelaTituloGrande(
      titulo: 'Esqueci a senha',
      slivers: [
        SliverToBoxAdapter(
          child: Form(
            key: _form,
            child: Column(
              children: [
                const TextoDeApoio(
                  'Informe o e-mail da sua conta. Se houver cadastro, enviamos um código de 6 dígitos.',
                ),
                SecaoAgrupada(
                  cabecalho: 'E-mail',
                  children: [
                    CupertinoTextFormFieldRow(
                      key: const Key('campo-email-esqueci'),
                      controller: _email,
                      prefix: SizedBox(
                        width: AppSpacing.larguraRotuloCampo,
                        child: Text('E-mail', style: AppTypography.body.copyWith(color: AppColors.texto)),
                      ),
                      placeholder: 'voce@exemplo.com',
                      placeholderStyle: AppTypography.body.copyWith(color: AppColors.textoSecundario),
                      style: AppTypography.body.copyWith(color: AppColors.texto),
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margem, vertical: AppSpacing.sm),
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.done,
                      validator: Validadores.email,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      onFieldSubmitted: (_) => _enviar(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
      rodape: BotaoPrincipal(
        rotulo: 'Enviar código',
        carregando: _enviando,
        onPressed: _enviar,
      ),
    );
  }
}
