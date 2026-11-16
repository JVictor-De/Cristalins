import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show MaterialPageRoute;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/botao_principal.dart';
import '../../../core/widgets/secao_agrupada.dart';
import '../../../core/widgets/tela_titulo_grande.dart';
import '../domain/pagamento.dart';
import 'faturas_controller.dart';

/// Cadastro do cartão, usando o mesmo controller da tela de pagamentos.
Route<bool> rotaCartao(FaturasController c) => MaterialPageRoute<bool>(
  settings: const RouteSettings(name: '/pagamentos/cartao'),
  builder: (_) => ChangeNotifierProvider.value(value: c, child: const CartaoScreen()),
);

/// Novo cartão. Os dados vão direto para a API (tokenização no Asaas) e são apagados
/// dos campos logo no envio: o app não guarda número nem CVV em memória, disco ou log.
class CartaoScreen extends StatefulWidget {
  const CartaoScreen({super.key});

  @override
  State<CartaoScreen> createState() => _CartaoScreenState();
}

class _CartaoScreenState extends State<CartaoScreen> {
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _numero = TextEditingController();
  final _mes = TextEditingController();
  final _ano = TextEditingController();
  final _cvv = TextEditingController();
  final _cep = TextEditingController();
  final _numeroEndereco = TextEditingController();
  final _telefone = TextEditingController();
  String? _erro;

  @override
  void dispose() {
    for (final c in [_nome, _numero, _mes, _ano, _cvv, _cep, _numeroEndereco, _telefone]) {
      c.clear();
      c.dispose();
    }
    super.dispose();
  }

  static String _digitos(String s) => s.replaceAll(RegExp(r'\D'), '');

  Future<void> _salvar(FaturasController c) async {
    if (!(_form.currentState?.validate() ?? false)) {
      HapticFeedback.lightImpact();
      return;
    }
    HapticFeedback.lightImpact();
    final dados = DadosCartao(
      nomeNoCartao: _nome.text.trim(),
      numero: _digitos(_numero.text),
      mesValidade: _mes.text.trim().padLeft(2, '0'),
      anoValidade: _ano.text.trim(),
      cvv: _cvv.text.trim(),
      cep: _digitos(_cep.text),
      numeroEndereco: _numeroEndereco.text.trim(),
      telefone: _digitos(_telefone.text),
    );
    // Número e CVV saem dos campos já no envio (se falhar, a pessoa digita de novo).
    _numero.clear();
    _cvv.clear();
    final erro = await c.cadastrarEUsar(dados);
    if (!mounted) return;
    if (erro != null) {
      setState(() => _erro = erro);
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<FaturasController>();

    CupertinoTextFormFieldRow campo(
      TextEditingController ctrl,
      String rotulo, {
      String? placeholder,
      FormFieldValidator<String>? validar,
      TextInputType teclado = TextInputType.number,
      bool oculto = false,
      List<String>? autofill,
    }) => CupertinoTextFormFieldRow(
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
      obscureText: oculto,
      autofillHints: autofill,
      autocorrect: false,
      enableSuggestions: false,
      textInputAction: TextInputAction.next,
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );

    String? digitos(String? v, int min, int max, String msg) {
      final d = _digitos(v ?? '');
      return d.length < min || d.length > max ? msg : null;
    }

    return TelaTituloGrande(
      titulo: 'Novo cartão',
      slivers: [
        SliverToBoxAdapter(
          child: Form(
            key: _form,
            child: Column(
              children: [
                SecaoAgrupada(
                  cabecalho: 'Cartão',
                  rodape:
                      _erro ??
                      'Enviamos o cartão direto para o Asaas, que devolve um código seguro. '
                          'Ficam só a bandeira e os 4 últimos dígitos.',
                  rodapeErro: _erro != null,
                  children: [
                    campo(
                      _nome,
                      'Nome',
                      placeholder: 'Como está no cartão',
                      teclado: TextInputType.name,
                      autofill: const [AutofillHints.creditCardName],
                      validar: (v) =>
                          (v ?? '').trim().length < 2 ? 'Informe o nome do cartão.' : null,
                    ),
                    campo(
                      _numero,
                      'Número',
                      placeholder: '0000 0000 0000 0000',
                      autofill: const [AutofillHints.creditCardNumber],
                      validar: (v) => digitos(v, 13, 19, 'Número do cartão inválido.'),
                    ),
                    campo(
                      _mes,
                      'Mês',
                      placeholder: 'MM',
                      autofill: const [AutofillHints.creditCardExpirationMonth],
                      validar: (v) {
                        final m = int.tryParse((v ?? '').trim());
                        return m == null || m < 1 || m > 12 ? 'Mês de validade inválido.' : null;
                      },
                    ),
                    campo(
                      _ano,
                      'Ano',
                      placeholder: 'AAAA',
                      autofill: const [AutofillHints.creditCardExpirationYear],
                      validar: (v) => RegExp(r'^20\d{2}$').hasMatch((v ?? '').trim())
                          ? null
                          : 'Ano com 4 dígitos.',
                    ),
                    campo(
                      _cvv,
                      'CVV',
                      placeholder: '3 ou 4 dígitos',
                      oculto: true,
                      autofill: const [AutofillHints.creditCardSecurityCode],
                      validar: (v) => digitos(v, 3, 4, 'CVV inválido.'),
                    ),
                  ],
                ),
                SecaoAgrupada(
                  cabecalho: 'Titular',
                  rodape: 'O Asaas pede o CEP, o número do endereço e um telefone do titular.',
                  children: [
                    campo(
                      _cep,
                      'CEP',
                      placeholder: '00000-000',
                      autofill: const [AutofillHints.postalCode],
                      validar: (v) => digitos(v, 8, 8, 'Informe o CEP com 8 dígitos.'),
                    ),
                    campo(
                      _numeroEndereco,
                      'Número',
                      placeholder: 'Do endereço',
                      teclado: TextInputType.text,
                      validar: (v) => (v ?? '').trim().isEmpty ? 'Informe o número.' : null,
                    ),
                    campo(
                      _telefone,
                      'Telefone',
                      placeholder: '(21) 99999-9999',
                      teclado: TextInputType.phone,
                      autofill: const [AutofillHints.telephoneNumber],
                      validar: (v) => digitos(v, 10, 11, 'Informe o telefone com DDD.'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
      rodape: BotaoPrincipal(
        rotulo: 'Salvar cartão',
        carregando: c.executando,
        onPressed: c.executando ? null : () => _salvar(c),
      ),
    );
  }
}
