import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/dependencias.dart';
import '../../../core/intents/navegacao_nativa.dart';
import '../../../core/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/botao_principal.dart';
import '../../../core/widgets/controle_segmentado.dart';
import '../../../core/widgets/estados.dart';
import '../../../core/widgets/logo_marca.dart';
import '../../../core/widgets/tela_titulo_grande.dart';
import '../data/auth_repository.dart';
import '../domain/validadores.dart';
import 'cadastro_login_controller.dart';
import 'esqueci_senha_screen.dart';

/// Tela 2 — Cadastro e login (P5).
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
  final _focoNome = FocusNode();
  final _focoCpf = FocusNode();
  final _focoEmail = FocusNode();
  final _focoCelular = FocusNode();
  final _focoSenha = FocusNode();

  var _senhaVisivel = false;
  var _optInWhatsApp = false;
  String? _tipEmail;

  bool get _origemCheckout => ModalRoute.of(context)?.settings.arguments == 'checkout';

  bool get _ehCnpj => Validadores.ehCnpj(_cpf.text);

  bool get _temDadosDigitados =>
      _nome.text.isNotEmpty ||
      _cpf.text.isNotEmpty ||
      _email.text.isNotEmpty ||
      _celular.text.isNotEmpty ||
      _nascimento.text.isNotEmpty ||
      _senha.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _cpf.addListener(() => setState(() {}));
    _senha.addListener(() => setState(() {}));
    _email.addListener(_atualizarTipEmail);
  }

  void _atualizarTipEmail() {
    final tip = Validadores.tipDominioEmail(_email.text);
    if (tip != _tipEmail) setState(() => _tipEmail = tip);
  }

  @override
  void dispose() {
    for (final c in [_nome, _cpf, _email, _celular, _nascimento, _senha]) {
      c.dispose();
    }
    for (final f in [_focoNome, _focoCpf, _focoEmail, _focoCelular, _focoSenha]) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _enviar(CadastroLoginController c) async {
    if (c.enviando) return;
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
              marketingOk: c.marketingOk || _optInWhatsApp,
            ),
            origemCheckout: _origemCheckout,
          )
        : await c.entrar(
            _email.text.trim().toLowerCase(),
            _senha.text,
            origemCheckout: _origemCheckout,
          );
    if (!mounted) return;
    if (c.erro != null) {
      mostrarAviso(context, c.erro!, erro: true);
      return;
    }
    // Sem destino = bloqueio local (ex.: termos sem aceite) — não registra push nem navega.
    if (destino == null) return;

    final dep = context.read<Dependencias>();
    await dep.push.registrarSePossivel(dep.api);
    if (!mounted) return;
    switch (destino) {
      case DestinoAposAcesso.minhaAssinatura:
        await NavegacaoNativa.instancia.abrir(
          context,
          activity: NavegacaoNativa.minhaAssinatura,
          rota: AppRoutes.minhaAssinatura,
          limparPilha: true,
        );
      case DestinoAposAcesso.checkout:
        mostrarAviso(
          context,
          cadastro
              ? 'Conta criada! Vamos finalizar sua assinatura.'
              : 'Que bom te ver de novo.',
        );
        Navigator.of(context).pop();
      case DestinoAposAcesso.quiz:
        mostrarAviso(
          context,
          cadastro ? 'Conta criada. Vamos ao quiz.' : 'Que bom te ver de novo.',
        );
        await NavegacaoNativa.instancia.abrir(
          context,
          activity: NavegacaoNativa.quiz,
          rota: AppRoutes.quiz,
          finish: true,
        );
    }
  }

  Future<void> _abrirData() async {
    HapticFeedback.selectionClick();
    final hoje = DateTime.now();
    final max = DateTime(hoje.year - 18, hoje.month, hoje.day);
    var temp = max;
    final iso = Validadores.paraIso(_nascimento.text);
    if (iso != null) {
      final p = iso.split('-').map(int.parse).toList();
      temp = DateTime(p[0], p[1], p[2]);
      if (temp.isAfter(max)) temp = max;
    }
    final escolhida = await showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (ctx) => Container(
        height: 280,
        color: AppColors.superficie,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                CupertinoButton(
                  onPressed: () => Navigator.pop(ctx, temp),
                  child: const Text('Concluir'),
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: temp,
                maximumDate: max,
                minimumDate: DateTime(1900),
                onDateTimeChanged: (d) => temp = d,
              ),
            ),
          ],
        ),
      ),
    );
    if (escolhida == null || !mounted) return;
    final br =
        '${escolhida.day.toString().padLeft(2, '0')}/${escolhida.month.toString().padLeft(2, '0')}/${escolhida.year}';
    setState(() => _nascimento.text = br);
  }

  Future<bool> _confirmarDescarte() async {
    if (context.read<CadastroLoginController>().modo != ModoAcesso.cadastro || !_temDadosDigitados) {
      return true;
    }
    final ok = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Descartar cadastro?'),
        content: const Text('Os dados preenchidos serão perdidos.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continuar'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<CadastroLoginController>();
    final cadastro = c.modo == ModoAcesso.cadastro;
    final margem = margemDaTela(context);
    final forca = Validadores.forcaSenha(_senha.text);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmarDescarte() && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.fundo,
        appBar: AppBar(
          backgroundColor: AppColors.fundo,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            tooltip: 'Voltar',
            icon: const Icon(Icons.arrow_back, color: AppColors.navy),
            onPressed: () async {
              if (await _confirmarDescarte() && mounted) Navigator.of(context).pop();
            },
          ),
          title: const LogoMarca(altura: 28),
          centerTitle: true,
        ),
        body: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(margem, AppSpacing.sm, margem, AppSpacing.secao),
            children: [
              ControleSegmentado<ModoAcesso>(
                opcoes: const {
                  ModoAcesso.cadastro: 'Criar conta',
                  ModoAcesso.login: 'Já tenho conta',
                },
                valor: c.modo,
                onEscolher: c.trocarModo,
              ),
              const SizedBox(height: AppSpacing.secao),
              Form(
                key: _form,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (cadastro) ...[
                        Text('Seus dados', style: AppTypography.headline.copyWith(color: AppColors.navy)),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Sua sacola será mantida depois do cadastro. Endereço só no checkout.',
                          style: AppTypography.footnote.copyWith(color: AppColors.textoSuave),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _Campo(
                          key: const Key('campo-nome'),
                          controller: _nome,
                          focusNode: _focoNome,
                          rotulo: _ehCnpj ? 'Razão social' : 'Como podemos te chamar?',
                          hint: _ehCnpj ? 'Empresa LTDA' : 'Seu nome',
                          validator: _ehCnpj ? Validadores.razaoSocial : Validadores.nome,
                          autofill: const [AutofillHints.name],
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) => _focoCpf.requestFocus(),
                        ),
                        _Campo(
                          key: const Key('campo-cpf'),
                          controller: _cpf,
                          focusNode: _focoCpf,
                          rotulo: 'CPF ou CNPJ',
                          hint: '000.000.000-00',
                          validator: Validadores.cpfCnpj,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          onChanged: (v) {
                            final m = Validadores.mascaraCpfCnpj(v);
                            if (m != v) {
                              _cpf.value = TextEditingValue(
                                text: m,
                                selection: TextSelection.collapsed(offset: m.length),
                              );
                            }
                          },
                          onFieldSubmitted: (_) {
                            if (_ehCnpj) {
                              _abrirData();
                            } else {
                              _abrirData();
                            }
                          },
                        ),
                        _CampoData(
                          key: const Key('campo-nascimento'),
                          controller: _nascimento,
                          rotulo: _ehCnpj ? 'Data de constituição' : 'Nascimento',
                          onTap: _abrirData,
                          validator: Validadores.dataNascimento,
                        ),
                        _Campo(
                          key: const Key('campo-celular'),
                          controller: _celular,
                          focusNode: _focoCelular,
                          rotulo: 'Celular',
                          hint: '(21) 99999-9999',
                          validator: Validadores.celular,
                          keyboardType: TextInputType.phone,
                          autofill: const [AutofillHints.telephoneNumber],
                          textInputAction: TextInputAction.next,
                          onChanged: (v) {
                            final m = Validadores.mascaraCelular(v);
                            if (m != v) {
                              _celular.value = TextEditingValue(
                                text: m,
                                selection: TextSelection.collapsed(offset: m.length),
                              );
                            }
                          },
                          onFieldSubmitted: (_) => _focoEmail.requestFocus(),
                        ),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          value: _optInWhatsApp,
                          onChanged: (v) => setState(() => _optInWhatsApp = v ?? false),
                          title: Text(
                            'Quero avisos de entrega no WhatsApp',
                            style: AppTypography.footnote.copyWith(color: AppColors.tinta),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                      Text('Acesso', style: AppTypography.headline.copyWith(color: AppColors.navy)),
                      const SizedBox(height: AppSpacing.sm),
                      _Campo(
                        key: const Key('campo-email'),
                        controller: _email,
                        focusNode: _focoEmail,
                        rotulo: 'E-mail',
                        hint: 'voce@exemplo.com',
                        validator: Validadores.email,
                        keyboardType: TextInputType.emailAddress,
                        autofill: const [AutofillHints.email],
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) => _focoSenha.requestFocus(),
                      ),
                      if (_tipEmail != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () {
                              _email.text = _tipEmail!;
                              _atualizarTipEmail();
                            },
                            child: Text(
                              'Você quis dizer $_tipEmail?',
                              style: AppTypography.caption1.copyWith(color: AppColors.azulMarca),
                            ),
                          ),
                        ),
                      if (c.emailDuplicado)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Este e-mail já tem conta.',
                                  style: AppTypography.footnote.copyWith(color: AppColors.erro),
                                ),
                              ),
                              TextButton(
                                onPressed: () => c.trocarModo(ModoAcesso.login),
                                child: const Text('Entrar'),
                              ),
                            ],
                          ),
                        ),
                      _Campo(
                        key: const Key('campo-senha'),
                        controller: _senha,
                        focusNode: _focoSenha,
                        rotulo: 'Senha',
                        hint: cadastro ? 'Crie uma senha' : 'Sua senha',
                        validator: cadastro
                            ? Validadores.senha
                            : (v) => (v ?? '').isEmpty ? 'Informe a senha.' : null,
                        obscureText: !_senhaVisivel,
                        autofill: [
                          cadastro ? AutofillHints.newPassword : AutofillHints.password,
                        ],
                        textInputAction: TextInputAction.done,
                        suffix: IconButton(
                          tooltip: _senhaVisivel ? 'Ocultar senha' : 'Mostrar senha',
                          onPressed: () => setState(() => _senhaVisivel = !_senhaVisivel),
                          icon: Icon(
                            _senhaVisivel ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppColors.textoSuave,
                          ),
                        ),
                        onFieldSubmitted: (_) => _enviar(c),
                      ),
                      if (cadastro && _senha.text.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        _Check('Pelo menos 8 caracteres', forca.comprimento),
                        _Check('Inclui letra', forca.letra),
                        _Check('Inclui número', forca.numero),
                      ],
                      if (!cadastro) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              Navigator.of(context).push(rotaEsqueciSenha());
                            },
                            child: Text(
                              'Esqueci a senha',
                              style: AppTypography.subheadline.copyWith(
                                color: AppColors.azulMarca,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (cadastro) ...[
                        const SizedBox(height: AppSpacing.sm),
                        _TermosLinha(
                          aceite: c.aceiteTermos,
                          erro: c.mostrarErroTermos,
                          onToggle: c.alternarTermos,
                        ),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          value: c.marketingOk,
                          onChanged: (_) => c.alternarMarketing(),
                          title: Text(
                            'Quero receber ofertas',
                            style: AppTypography.footnote.copyWith(color: AppColors.tinta),
                          ),
                        ),
                        if (c.mostrarErroTermos)
                          Text(
                            'Para criar a conta, aceite os termos de uso e a política de privacidade.',
                            style: AppTypography.footnote.copyWith(color: AppColors.erro),
                          ),
                      ],
                      if (c.erro != null && !c.emailDuplicado)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                          child: Text(
                            c.erro!,
                            style: AppTypography.footnote.copyWith(color: AppColors.erro),
                          ),
                        ),
                      if (c.erro != null &&
                          (c.erro!.toLowerCase().contains('conexão') ||
                              c.erro!.toLowerCase().contains('rede') ||
                              c.erro!.toLowerCase().contains('internet')))
                        TextButton(
                          onPressed: () => _enviar(c),
                          child: const Text('Tentar de novo'),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(margem, AppSpacing.xs, margem, AppSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BotaoPrincipal(
                  rotulo: cadastro ? 'Criar conta' : 'Entrar',
                  variante: VarianteBotaoPrincipal.navy,
                  carregando: c.enviando,
                  onPressed: c.enviando ? null : () => _enviar(c),
                ),
                TextButton(
                  onPressed: () async {
                    HapticFeedback.selectionClick();
                    if (await _confirmarDescarte() && mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.shell, (_) => false);
                    }
                  },
                  child: Text(
                    'Explorar sem entrar',
                    style: AppTypography.caption1.copyWith(color: AppColors.textoSuave),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Check extends StatelessWidget {
  const _Check(this.texto, this.ok);
  final String texto;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: ok ? AppColors.azulMarca : AppColors.textoSuave,
          ),
          const SizedBox(width: 6),
          Text(
            texto,
            style: AppTypography.caption1.copyWith(
              color: ok ? AppColors.tinta : AppColors.textoSuave,
            ),
          ),
        ],
      ),
    );
  }
}

class _TermosLinha extends StatelessWidget {
  const _TermosLinha({
    required this.aceite,
    required this.erro,
    required this.onToggle,
  });

  final bool aceite;
  final bool erro;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final termosUrl = AppConfig.urlTermos;
    final privUrl = AppConfig.urlPrivacidade;

    return MergeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: aceite,
            fillColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected) ? AppColors.navy : null,
            ),
            onChanged: (_) => onToggle(),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text.rich(
                  TextSpan(
                    style: AppTypography.footnote.copyWith(
                      color: erro ? AppColors.erro : AppColors.tinta,
                    ),
                    children: [
                      const TextSpan(text: 'Li e aceito os '),
                      TextSpan(
                        text: 'termos de uso',
                        style: TextStyle(
                          color: AppColors.azulMarca,
                          decoration: termosUrl.isEmpty ? null : TextDecoration.underline,
                        ),
                        recognizer: termosUrl.isEmpty
                            ? null
                            : (TapGestureRecognizer()
                              ..onTap = () => context.read<Dependencias>().links.abrir(termosUrl)),
                      ),
                      const TextSpan(text: ' e a '),
                      TextSpan(
                        text: 'política de privacidade',
                        style: TextStyle(
                          color: AppColors.azulMarca,
                          decoration: privUrl.isEmpty ? null : TextDecoration.underline,
                        ),
                        recognizer: privUrl.isEmpty
                            ? null
                            : (TapGestureRecognizer()
                              ..onTap = () => context.read<Dependencias>().links.abrir(privUrl)),
                      ),
                      if (termosUrl.isEmpty || privUrl.isEmpty)
                        TextSpan(
                          text: ' (links em breve)',
                          style: TextStyle(color: AppColors.textoSuave),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CampoData extends StatelessWidget {
  const _CampoData({
    super.key,
    required this.controller,
    required this.rotulo,
    required this.onTap,
    required this.validator,
  });

  final TextEditingController controller;
  final String rotulo;
  final VoidCallback onTap;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: FormField<String>(
        validator: (_) => validator(controller.text),
        builder: (state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(rotulo, style: AppTypography.subheadline.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              InkWell(
                onTap: () async {
                  onTap();
                  await Future<void>.delayed(const Duration(milliseconds: 300));
                  state.didChange(controller.text);
                },
                borderRadius: BorderRadius.circular(AppSpacing.raioCard),
                child: InputDecorator(
                  decoration: InputDecoration(
                    hintText: 'DD/MM/AAAA',
                    errorText: state.errorText,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.raioCard),
                    ),
                    suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
                  ),
                  child: Text(
                    controller.text.isEmpty ? 'Toque para escolher' : controller.text,
                    style: AppTypography.body.copyWith(
                      color: controller.text.isEmpty ? AppColors.textoSuave : AppColors.tinta,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Campo extends StatelessWidget {
  const _Campo({
    super.key,
    required this.controller,
    required this.rotulo,
    required this.validator,
    this.focusNode,
    this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.autofill,
    this.textInputAction = TextInputAction.next,
    this.suffix,
    this.onChanged,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String rotulo;
  final String? hint;
  final FormFieldValidator<String> validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final List<String>? autofill;
  final TextInputAction textInputAction;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(rotulo, style: AppTypography.subheadline.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            focusNode: focusNode,
            validator: validator,
            keyboardType: keyboardType,
            obscureText: obscureText,
            autofillHints: autofill,
            textInputAction: textInputAction,
            onChanged: onChanged,
            onFieldSubmitted: onFieldSubmitted,
            style: AppTypography.body.copyWith(color: AppColors.tinta),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTypography.body.copyWith(color: AppColors.textoSuave),
              suffixIcon: suffix,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.raioCard),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
