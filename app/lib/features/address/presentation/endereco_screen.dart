import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/dependencias.dart';
import '../../../core/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/botao_principal.dart';
import '../../../core/widgets/controles.dart';
import '../../../core/widgets/estados.dart';
import '../../../core/widgets/secao_agrupada.dart';
import '../../../core/widgets/tela_titulo_grande.dart';
import '../../auth/domain/validadores.dart';
import '../../subscription/domain/assinatura.dart';
import '../data/endereco_repository.dart';
import '../domain/endereco.dart';
import 'endereco_controller.dart';

/// Tela 6 — Endereço: CEP (ViaCEP + zona na API), janela de entrega e mapa (`geo:`).
class EnderecoScreen extends StatelessWidget {
  const EnderecoScreen({super.key, required this.pedido});

  final PedidoAssinatura pedido;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EnderecoController(context.read<Dependencias>().enderecos),
      child: _Conteudo(pedido: pedido),
    );
  }
}

class _Conteudo extends StatefulWidget {
  const _Conteudo({required this.pedido});

  final PedidoAssinatura pedido;

  @override
  State<_Conteudo> createState() => _ConteudoState();
}

class _ConteudoState extends State<_Conteudo> {
  final _form = GlobalKey<FormState>();
  final _cep = TextEditingController();
  final _numero = TextEditingController();
  final _complemento = TextEditingController();
  final _apelido = TextEditingController(text: 'Casa');
  final _referencia = TextEditingController();
  final _instrucoes = TextEditingController();
  final _email = TextEditingController();

  @override
  void dispose() {
    for (final c in [_cep, _numero, _complemento, _apelido, _referencia, _instrucoes, _email]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _buscarCep(EnderecoController c) async {
    final erro = Validadores.cep(_cep.text);
    if (erro != null) {
      mostrarAviso(context, erro, erro: true);
      return;
    }
    HapticFeedback.selectionClick();
    await c.consultarCep(Validadores.digitos(_cep.text));
  }

  Future<void> _abrirMapa(String endereco) async {
    HapticFeedback.selectionClick();
    final abriu = await context.read<Dependencias>().links.abrir(
      'geo:0,0?q=${Uri.encodeComponent(endereco)}',
    );
    if (!abriu && mounted) {
      mostrarAviso(context, 'Não encontramos um app de mapas neste celular.', erro: true);
    }
  }

  Future<void> _escolherJanela(EnderecoController c) async {
    HapticFeedback.selectionClick();
    final i = await escolherNaFolha(
      context,
      titulo: 'Janela de entrega',
      opcoes: [for (final j in JanelaEntrega.values) j.rotulo],
      selecionado: c.janela.index,
    );
    if (i != null) c.escolherJanela(JanelaEntrega.values[i]);
  }

  Future<void> _continuar(EnderecoController c) async {
    HapticFeedback.lightImpact();
    var endereco = c.escolhido;
    if (endereco == null) {
      if (c.cep == null) {
        mostrarAviso(context, 'Busque o CEP antes de continuar.', erro: true);
        return;
      }
      if (!_form.currentState!.validate()) return;
      endereco = await c.salvar(
        NovoEndereco(
          cep: c.cep!.cep,
          numero: _numero.text,
          complemento: _complemento.text,
          apelido: _apelido.text,
          referencia: _referencia.text,
          instrucoes: _instrucoes.text,
        ),
      );
      if (!mounted) return;
      if (endereco == null) {
        mostrarAviso(
          context,
          c.erroCep ?? 'Não conseguimos salvar o endereço. Tente de novo.',
          erro: true,
        );
        return;
      }
      mostrarAviso(context, 'Endereço salvo.');
    }
    Navigator.of(context).pushNamed(
      AppRoutes.planoPagamento,
      arguments: widget.pedido.copyWith(endereco: endereco, janela: c.janela),
    );
  }

  Future<void> _avisarMe(EnderecoController c) async {
    if (Validadores.email(_email.text) != null) {
      mostrarAviso(context, 'Informe um e-mail válido.', erro: true);
      return;
    }
    HapticFeedback.lightImpact();
    final erro = await c.entrarNaListaDeEspera(_email.text.trim().toLowerCase());
    if (!mounted) return;
    mostrarAviso(
      context,
      erro ?? 'Pronto. Avisamos você quando a entrega chegar aí.',
      erro: erro != null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<EnderecoController>();
    if (c.carregando) {
      return const TelaTituloGrande(
        titulo: 'Endereço',
        slivers: [SliverFillRemaining(hasScrollBody: false, child: Carregando())],
      );
    }
    if (c.erroCarregar != null) {
      return TelaTituloGrande(
        titulo: 'Endereço',
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: EstadoErro(mensagem: c.erroCarregar!, onTentarDeNovo: c.carregar),
          ),
        ],
      );
    }

    final estiloValor = AppTypography.body.copyWith(color: AppColors.textoSecundario);
    CupertinoTextFormFieldRow campo(
      TextEditingController ctrl,
      String rotulo,
      String placeholder, {
      Key? key,
      FormFieldValidator<String>? validar,
      TextInputType? teclado,
    }) => CupertinoTextFormFieldRow(
      key: key,
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
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );

    return TelaTituloGrande(
      titulo: 'Endereço',
      slivers: [
        SliverToBoxAdapter(
          child: Form(
            key: _form,
            child: Column(
              children: [
                if (c.salvos.isNotEmpty)
                  RadioGroup<String>(
                    groupValue: c.escolhido?.id ?? '',
                    onChanged: (id) {
                      HapticFeedback.selectionClick();
                      c.escolher(c.salvos.where((e) => e.id == id).firstOrNull);
                    },
                    child: SecaoAgrupada(
                      cabecalho: 'Entregar em',
                      children: [
                        for (final e in c.salvos)
                          MergeSemantics(
                            child: LinhaLista(
                              titulo: e.apelido ?? e.bairro,
                              subtitulo: '${e.linha} · ${e.bairro} (${e.zona.nome})',
                              destaque: c.escolhido?.id == e.id,
                              trailing: CupertinoRadio<String>(
                                value: e.id,
                                activeColor: AppColors.azul800,
                              ),
                              onTap: () {
                                HapticFeedback.selectionClick();
                                c.escolher(e);
                              },
                            ),
                          ),
                        MergeSemantics(
                          child: LinhaLista(
                            titulo: 'Novo endereço',
                            destaque: c.novo,
                            trailing: const CupertinoRadio<String>(
                              value: '',
                              activeColor: AppColors.azul800,
                            ),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              c.escolher(null);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                if (c.novo) ...[
                  SecaoAgrupada(
                    cabecalho: 'CEP',
                    rodape: c.erroCep ?? 'Entregamos no município do Rio de Janeiro.',
                    rodapeErro: c.erroCep != null,
                    children: [
                      campo(
                        _cep,
                        'CEP',
                        '00000-000',
                        key: const Key('campo-cep'),
                        teclado: TextInputType.number,
                      ),
                      LinhaLista(
                        titulo: c.consultando ? 'Buscando…' : 'Buscar CEP',
                        corTitulo: AppColors.linkSobreSuperficie,
                        trailing: c.consultando ? const CupertinoActivityIndicator() : null,
                        onTap: c.consultando ? null : () => _buscarCep(c),
                      ),
                    ],
                  ),
                  if (c.foraDaArea)
                    SecaoAgrupada(
                      cabecalho: 'Lista de espera',
                      rodape: c.listaEsperaEnviada
                          ? 'Você está na lista. Avisamos assim que a entrega chegar aí.'
                          : 'Deixe seu e-mail e avisamos quando começarmos a entregar aí.',
                      children: [
                        campo(
                          _email,
                          'E-mail',
                          'voce@exemplo.com',
                          teclado: TextInputType.emailAddress,
                        ),
                        LinhaLista(
                          titulo: 'Avisar quando chegar',
                          corTitulo: AppColors.linkSobreSuperficie,
                          onTap: c.listaEsperaEnviada ? null : () => _avisarMe(c),
                        ),
                      ],
                    ),
                  if (c.cep != null) ...[
                    SecaoAgrupada(
                      cabecalho: 'Endereço',
                      rodape:
                          '${c.cep!.zona.nome}: entrega ${c.cep!.zona.diasLegiveis}, taxa de ${c.cep!.zona.taxa.formatado} '
                          '(grátis acima de R\$ 250).',
                      children: [
                        LinhaLista(
                          titulo: c.cep!.logradouro,
                          subtitulo: '${c.cep!.bairro}, Rio de Janeiro - RJ',
                        ),
                        campo(
                          _numero,
                          'Número',
                          '100',
                          key: const Key('campo-numero'),
                          validar: (v) => (v ?? '').trim().isEmpty ? 'Informe o número.' : null,
                        ),
                        campo(_complemento, 'Compl.', 'Apto, bloco (opcional)'),
                        campo(_apelido, 'Apelido', 'Casa, Trabalho, Academia'),
                        campo(_referencia, 'Referência', 'Perto de… (opcional)'),
                        campo(_instrucoes, 'Instruções', 'Portaria, horário (opcional)'),
                      ],
                    ),
                  ],
                ],
                SecaoAgrupada(
                  cabecalho: 'Janela de entrega',
                  children: [
                    LinhaLista(
                      titulo: c.janela.rotulo,
                      trailing: const CupertinoListTileChevron(),
                      onTap: () => _escolherJanela(c),
                    ),
                  ],
                ),
                if (c.escolhido != null || c.cep != null)
                  BotaoSecundario(
                    rotulo: 'Abrir no mapa',
                    icone: CupertinoIcons.arrow_up_right,
                    onPressed: () => _abrirMapa(
                      c.escolhido?.paraMapa ??
                          '${c.cep!.logradouro}, ${_numero.text}, ${c.cep!.bairro}, Rio de Janeiro - RJ',
                    ),
                  ),
                if (c.escolhido != null)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: margemDaTela(context)),
                    child: Text(
                      'Entrega ${c.escolhido!.zona.diasLegiveis} · taxa de ${c.escolhido!.zona.taxa.formatado}',
                      style: estiloValor,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
      rodape: BotaoPrincipal(
        rotulo: c.novo ? 'Salvar endereço' : 'Continuar',
        carregando: c.salvando,
        onPressed: (c.novo && c.cep == null) ? null : () => _continuar(c),
      ),
    );
  }
}
