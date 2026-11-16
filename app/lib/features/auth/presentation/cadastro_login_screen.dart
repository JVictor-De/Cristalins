import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/dependencias.dart';
import '../../../core/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/botao_principal.dart';
import '../../../core/widgets/controle_segmentado.dart';
import '../../../core/widgets/estados.dart';
import '../../../core/widgets/secao_agrupada.dart';
import '../../../core/widgets/tela_titulo_grande.dart';
import '../data/auth_repository.dart';
import '../domain/validadores.dart';
import 'cadastro_login_controller.dart';
import 'esqueci_senha_screen.dart';

/// Tela 2 — Cadastro e login.
class CadastroLoginScreen extends StatelessWidget {
  const CadastroLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dep = context.read<Dependencias>();
    return ChangeNotifierProvider(
      create: (_) => CadastroLoginController(dep.auth, dep.assinaturas),
      child: const _Conteudo(),
    );
  }
}

class _Conteudo extends StatefulWidget {
  const _Conteudo();

  @override
  State<_Conteudo> createState() => _ConteudoState();
}

class _ConteudoState extends State<_Conteudo> {
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _cpf = TextEditingController();
  final _email = TextEditingController();
  final _celular = TextEditingController();
  final _nascimento = TextEditingController();
  final _senha = TextEditingController();

  @override
  void dispose() {
    for (final c in [_nome, _cpf, _email, _celular, _nascimento, _senha]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _enviar(CadastroLoginController c) async {
    final valido = _form.currentState!.validate();
    final cadastro = c.modo == ModoAcesso.cadastro;
    if (!valido) {
      HapticFeedback.lightImpact();
      return;
    }
    HapticFeedback.lightImpact();
    final destino = cadastro
        ? await c.cadastrar(
            DadosCadastro(
              nome: _nome.text.trim(),
              cpfCnpj: Validadores.digitos(_cpf.text),
              email: _email.text.trim().toLowerCase(),
              celular: Validadores.digitos(_celular.text),
              dataNascimento: Validadores.paraIso(_nascimento.text)!,
              senha: _senha.text,
              aceiteTermos: c.aceiteTermos,
            ),
          )
        : await c.entrar(_email.text.trim().toLowerCase(), _senha.text);
    if (!mounted) return;
    if (c.erro != null) {
      mostrarAviso(context, c.erro!, erro: true);
      return;
    }
    // RF51: tenta registrar o token de push (sem Firebase configurado, segue em silêncio).
    final dep = context.read<Dependencias>();
    await dep.push.registrarSePossivel(dep.api);
    if (!mounted) return;
    switch (destino) {
      case DestinoAposAcesso.minhaAssinatura:
        Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.minhaAssinatura, (_) => false);
      case DestinoAposAcesso.quiz:
        mostrarAviso(
          context,
          cadastro ? 'Conta criada. Vamos ao quiz.' : 'Que bom te ver de novo.',
        );
        Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.quiz, (r) => r.isFirst);
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<CadastroLoginController>();
    final cadastro = c.modo == ModoAcesso.cadastro;
    final margem = margemDaTela(context);

    CupertinoTextFormFieldRow campo(
      TextEditingController ctrl,
      String rotulo, {
      String? placeholder,
      FormFieldValidator<String>? validar,
      TextInputType? teclado,
      bool senha = false,
      List<String>? autofill,
      TextInputAction acao = TextInputAction.next,
    }) {
      return CupertinoTextFormFieldRow(
        controller: ctrl,
        prefix: SizedBox(
          width: AppSpacing.larguraRotuloCampo,
          child: Text(rotulo, style: AppTypography.body.copyWith(color: AppColors.texto)),
        ),
        placeholder: placeholder,
        placeholderStyle: AppTypography.body.copyWith(color: AppColors.textoSecundario),
        style: AppTypography.body.copyWith(color: AppColors.texto),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margem, vertical: AppSpacing.sm),
        validator: validar,
        keyboardType: teclado,
        obscureText: senha,
        autofillHints: autofill,
        textInputAction: acao,
        autovalidateMode: AutovalidateMode.onUserInteraction,
      );
    }

    return TelaTituloGrande(
      titulo: cadastro ? 'Criar conta' : 'Entrar',
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(margem, AppSpacing.xs, margem, 0),
            child: ControleSegmentado<ModoAcesso>(
              opcoes: const {
                ModoAcesso.cadastro: 'Criar conta',
                ModoAcesso.login: 'Já tenho conta',
              },
              valor: c.modo,
              onEscolher: (m) {
                _form.currentState?.reset();
                c.trocarModo(m);
              },
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Form(
            key: _form,
            child: AutofillGroup(
              child: Column(
                children: [
                  if (cadastro)
                    SecaoAgrupada(
                      cabecalho: 'Seus dados',
                      rodape: 'Usamos seus dados só para a entrega e a cobrança.',
                      children: [
                        campo(
                          _nome,
                          'Nome',
                          placeholder: 'Nome completo',
                          validar: Validadores.nome,
                          autofill: const [AutofillHints.name],
                        ),
                        campo(
                          _cpf,
                          'CPF',
                          placeholder: 'CPF ou CNPJ',
                          validar: Validadores.cpfCnpj,
                          teclado: TextInputType.number,
                        ),
                        campo(
                          _nascimento,
                          'Nascimento',
                          placeholder: 'DD/MM/AAAA',
                          validar: Validadores.dataNascimento,
                          teclado: TextInputType.datetime,
                          autofill: const [AutofillHints.birthday],
                        ),
                        campo(
                          _celular,
                          'Celular',
                          placeholder: '(21) 99999-9999 (opcional)',
                          validar: Validadores.celular,
                          teclado: TextInputType.phone,
                          autofill: const [AutofillHints.telephoneNumber],
                        ),
                      ],
                    ),
                  SecaoAgrupada(
                    cabecalho: 'Acesso',
                    rodape: cadastro ? 'A senha precisa ter pelo menos 8 caracteres.' : null,
                    children: [
                      campo(
                        _email,
                        'E-mail',
                        placeholder: 'voce@exemplo.com',
                        validar: Validadores.email,
                        teclado: TextInputType.emailAddress,
                        autofill: const [AutofillHints.email],
                      ),
                      campo(
                        _senha,
                        'Senha',
                        placeholder: cadastro ? 'Crie uma senha' : 'Sua senha',
                        validar: cadastro
                            ? Validadores.senha
                            : (v) => (v ?? '').isEmpty ? 'Informe a senha.' : null,
                        senha: true,
                        autofill: [cadastro ? AutofillHints.newPassword : AutofillHints.password],
                        acao: TextInputAction.done,
                      ),
                    ],
                  ),
                  if (!cadastro)
                    SecaoAgrupada(
                      children: [
                        LinhaLista(
                          titulo: 'Esqueci a senha',
                          corTitulo: AppColors.linkSobreSuperficie,
                          trailing: const CupertinoListTileChevron(),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.of(context).push(rotaEsqueciSenha());
                          },
                        ),
                      ],
                    ),
                  if (cadastro)
                    SecaoAgrupada(
                      rodape: c.mostrarErroTermos
                          ? 'Para criar a conta, aceite os termos de uso e a política de privacidade.'
                          : null,
                      rodapeErro: c.mostrarErroTermos,
                      children: [
                        MergeSemantics(
                          child: LinhaLista(
                            titulo: 'Li e aceito os termos de uso e a política de privacidade',
                            trailing: CupertinoCheckbox(
                              value: c.aceiteTermos,
                              activeColor: AppColors.azul800,
                              onChanged: (_) {
                                HapticFeedback.selectionClick();
                                c.alternarTermos();
                              },
                            ),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              c.alternarTermos();
                            },
                          ),
                        ),
                      ],
                    ),
                  if (c.erro != null) TextoDeApoio(c.erro!, erro: true),
                ],
              ),
            ),
          ),
        ),
      ],
      rodape: BotaoPrincipal(
        rotulo: cadastro ? 'Criar conta' : 'Entrar',
        carregando: c.enviando,
        onPressed: () => _enviar(c),
      ),
    );
  }
}
