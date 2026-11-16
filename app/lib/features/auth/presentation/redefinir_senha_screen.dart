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

Route<void> rotaRedefinirSenha(String email) => MaterialPageRoute<void>(
  builder: (_) => RedefinirSenhaScreen(email: email),
  settings: const RouteSettings(name: '/redefinir-senha'),
);

/// RF52 — código de 6 dígitos + nova senha.
class RedefinirSenhaScreen extends StatefulWidget {
  const RedefinirSenhaScreen({super.key, required this.email});

  final String email;

  @override
  State<RedefinirSenhaScreen> createState() => _RedefinirSenhaScreenState();
}

class _RedefinirSenhaScreenState extends State<RedefinirSenhaScreen> {
  final _form = GlobalKey<FormState>();
  final _codigo = TextEditingController();
  final _senha = TextEditingController();
  bool _enviando = false;

  @override
  void dispose() {
    _codigo.dispose();
    _senha.dispose();
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
      final msg = await context.read<Dependencias>().auth.redefinirSenha(
        email: widget.email,
        codigo: _codigo.text.trim(),
        novaSenha: _senha.text,
      );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      mostrarAviso(context, msg);
      Navigator.of(context).popUntil((r) => r.isFirst || r.settings.name == '/cadastro-login');
    } on ApiErro catch (e) {
      if (mounted) mostrarAviso(context, e.mensagem, erro: true);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TelaTituloGrande(
      titulo: 'Nova senha',
      slivers: [
        SliverToBoxAdapter(
          child: Form(
            key: _form,
            child: Column(
              children: [
                TextoDeApoio('Código enviado para ${widget.email}. Vale por até 30 minutos.'),
                SecaoAgrupada(
                  cabecalho: 'Código e senha',
                  rodape: 'A senha precisa ter pelo menos 8 caracteres.',
                  children: [
                    CupertinoTextFormFieldRow(
                      controller: _codigo,
                      prefix: SizedBox(
                        width: AppSpacing.larguraRotuloCampo,
                        child: Text('Código', style: AppTypography.body.copyWith(color: AppColors.texto)),
                      ),
                      placeholder: '000000',
                      placeholderStyle: AppTypography.body.copyWith(color: AppColors.textoSecundario),
                      style: AppTypography.body.copyWith(color: AppColors.texto),
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margem, vertical: AppSpacing.sm),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || !RegExp(r'^\d{6}$').hasMatch(v.trim())) {
                          return 'Informe o código de 6 dígitos.';
                        }
                        return null;
                      },
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    ),
                    CupertinoTextFormFieldRow(
                      controller: _senha,
                      prefix: SizedBox(
                        width: AppSpacing.larguraRotuloCampo,
                        child: Text('Senha', style: AppTypography.body.copyWith(color: AppColors.texto)),
                      ),
                      placeholder: 'Nova senha',
                      placeholderStyle: AppTypography.body.copyWith(color: AppColors.textoSecundario),
                      style: AppTypography.body.copyWith(color: AppColors.texto),
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margem, vertical: AppSpacing.sm),
                      obscureText: true,
                      autofillHints: const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.done,
                      validator: Validadores.senha,
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
        rotulo: 'Salvar senha',
        carregando: _enviando,
        onPressed: _enviar,
      ),
    );
  }
}
