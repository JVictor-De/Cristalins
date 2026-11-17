import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../features/address/domain/cep_sessao.dart';
import '../../features/auth/domain/validadores.dart';
import '../../features/catalog/domain/catalogo.dart';
import '../../features/catalog/domain/produto_assets.dart';
import '../dependencias.dart';
import '../network/api_erro.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Abre a folha de lista de espera (`POST /lista-espera`, CT23).
///
/// - [produto] esgotado (`estoque == 0`): “Avise-me”; pede e-mail + CEP (pré-preenchido
///   com o CEP da sessão, se houver).
/// - [cepForaDaArea]: CEP_FORA_AREA / BAIRRO_NAO_ATENDIDO; o CEP já é conhecido, pede só e-mail.
///
/// Devolve `true` se entrou na lista. O aviso de sucesso aparece no Scaffold de quem chamou.
Future<bool> abrirFolhaListaEspera(
  BuildContext context, {
  Produto? produto,
  String? cepForaDaArea,
}) async {
  assert(produto != null || cepForaDaArea != null);
  HapticFeedback.selectionClick();
  final messenger = ScaffoldMessenger.maybeOf(context);
  final entrou = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.superficie,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.raioCard)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: FolhaListaEspera(produto: produto, cepForaDaArea: cepForaDaArea),
    ),
  );
  if (entrou == true) {
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Pronto! Avisamos por e-mail.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
  return entrou == true;
}

class FolhaListaEspera extends StatefulWidget {
  const FolhaListaEspera({super.key, this.produto, this.cepForaDaArea});

  final Produto? produto;
  final String? cepForaDaArea;

  @override
  State<FolhaListaEspera> createState() => _FolhaListaEsperaState();
}

class _FolhaListaEsperaState extends State<FolhaListaEspera> {
  final _email = TextEditingController();
  late final _cep = TextEditingController(text: widget.cepForaDaArea ?? CepDaSessao.valor ?? '');
  var _enviando = false;
  String? _erroEmail;
  String? _erroCep;
  String? _erroApi;

  bool get _pedeCep => widget.cepForaDaArea == null;

  @override
  void initState() {
    super.initState();
    _preencherEmail();
  }

  /// Logado: usa o e-mail de `GET /clientes/me` (cache). Visitante: digita.
  Future<void> _preencherEmail() async {
    final dep = context.read<Dependencias>();
    try {
      final token = await dep.api?.tokens.lerAcesso();
      if (dep.api != null && (token == null || token.isEmpty)) return;
      final perfil = await dep.auth.perfil();
      if (mounted && _email.text.isEmpty) _email.text = perfil.email;
    } catch (_) {
      // Sem perfil: o campo fica vazio para o visitante digitar.
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _cep.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final erroEmail = Validadores.email(_email.text);
    final erroCep = _pedeCep ? Validadores.cep(_cep.text) : null;
    setState(() {
      _erroEmail = erroEmail;
      _erroCep = erroCep;
      _erroApi = null;
    });
    if (erroEmail != null || erroCep != null) return;

    setState(() => _enviando = true);
    try {
      await context.read<Dependencias>().enderecos.entrarNaListaDeEspera(
        email: _email.text.trim(),
        cep: Validadores.digitos(_cep.text),
      );
      if (!mounted) return;
      HapticFeedback.lightImpact();
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _erroApi = ApiErro.de(e).mensagem;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final produto = widget.produto;
    final titulo = produto != null ? 'Avise-me quando voltar' : 'Ainda não entregamos aí';
    final texto = produto != null
        ? '${nomeCardProduto(produto)} (${produto.pack}) está esgotado. '
              'Deixe seu e-mail e CEP e avisamos quando voltar.'
        : 'Deixe seu e-mail e avisamos quando começarmos a entregar no CEP '
              '${_formatarCep(widget.cepForaDaArea!)}.';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.margem,
          AppSpacing.sm,
          AppSpacing.margem,
          AppSpacing.margem,
        ),
        child: Column(
          key: const ValueKey('folha-lista-espera'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.linha,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Semantics(
              header: true,
              child: Text(titulo, style: AppTypography.title3.copyWith(color: AppColors.navy)),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(texto, style: AppTypography.footnote.copyWith(color: AppColors.textoSuave)),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              key: const ValueKey('lista-espera-email'),
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: _pedeCep ? TextInputAction.next : TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              decoration: InputDecoration(
                labelText: 'E-mail',
                hintText: 'voce@exemplo.com',
                errorText: _erroEmail,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.raioCard),
                ),
              ),
              onSubmitted: _pedeCep ? null : (_) => _enviar(),
            ),
            if (_pedeCep) ...[
              const SizedBox(height: AppSpacing.sm),
              TextField(
                key: const ValueKey('lista-espera-cep'),
                controller: _cep,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.postalCode],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(8),
                ],
                decoration: InputDecoration(
                  labelText: 'CEP',
                  hintText: '00000000',
                  errorText: _erroCep,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.raioCard),
                  ),
                ),
                onSubmitted: (_) => _enviar(),
              ),
            ],
            if (_erroApi != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(_erroApi!, style: AppTypography.footnote.copyWith(color: AppColors.erro)),
            ],
            const SizedBox(height: AppSpacing.sm),
            FilledButton(
              key: const ValueKey('lista-espera-enviar'),
              onPressed: _enviando ? null : _enviar,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.navy,
                minimumSize: const Size(0, AppSpacing.toqueMinimo),
              ),
              child: _enviando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.sobrePrimaria,
                      ),
                    )
                  : const Text('Avisar quando chegar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Agora não',
                style: AppTypography.subheadline.copyWith(color: AppColors.azulMarca),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatarCep(String digitos) =>
      digitos.length == 8 ? '${digitos.substring(0, 5)}-${digitos.substring(5)}' : digitos;
}
