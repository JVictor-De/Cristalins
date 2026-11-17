import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/dependencias.dart';
import '../../../core/intents/navegacao_nativa.dart';
import '../../../core/network/api_erro.dart';
import '../../../core/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/botao_principal.dart';
import '../../../core/widgets/controles.dart';
import '../../../core/widgets/estados.dart';
import '../../../core/widgets/secao_agrupada.dart';
import '../../../core/widgets/tela_titulo_grande.dart';
import '../../subscription/domain/assinatura.dart';
import '../data/recomendacao_repository.dart';
import '../domain/quiz.dart';

class ResultadoController extends ChangeNotifier {
  ResultadoController(this._repo, this.id) {
    carregar();
  }

  final RecomendacaoRepository _repo;
  final String id;
  Recomendacao? recomendacao;
  String? erro;
  bool carregando = true;

  Future<void> carregar() async {
    carregando = true;
    erro = null;
    notifyListeners();
    try {
      recomendacao = await _repo.buscar(id);
    } on ApiErro catch (e) {
      erro = e.mensagem;
    } finally {
      carregando = false;
      notifyListeners();
    }
  }
}

/// Tela 4 — Resultado: kit, frequência e preço estimado (tudo da API) e compartilhar.
class ResultadoScreen extends StatelessWidget {
  const ResultadoScreen({super.key, required this.recomendacaoId});

  final String recomendacaoId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          ResultadoController(context.read<Dependencias>().recomendacoes, recomendacaoId),
      child: const _Conteudo(),
    );
  }
}

class _Conteudo extends StatelessWidget {
  const _Conteudo();

  String _textoParaCompartilhar(Recomendacao r) {
    final itens = r.itens.map((i) => '${i.quantidade} ${nomeDoProduto(i.produto)}').join(', ');
    final preco = r.valorEstimado == null
        ? ''
        : ', a partir de ${r.valorEstimado!.formatado} por entrega';
    return 'Meu resultado no quiz Cristalins: ${r.nomeDoKit} ($itens), entrega '
        '${rotuloFrequencia(r.frequencia).toLowerCase()}$preco. ${AppConfig.siteMarca}';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ResultadoController>();
    final r = c.recomendacao;
    final dep = context.read<Dependencias>();

    if (c.carregando) {
      return const TelaTituloGrande(
        titulo: 'Sua recomendação',
        slivers: [SliverFillRemaining(hasScrollBody: false, child: Carregando())],
      );
    }
    if (r == null) {
      return TelaTituloGrande(
        titulo: 'Sua recomendação',
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: EstadoErro(mensagem: c.erro ?? ApiErro.generico, onTentarDeNovo: c.carregar),
          ),
        ],
      );
    }

    final destaque = AppTypography.title1.copyWith(
      color: AppColors.texto,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return TelaTituloGrande(
      titulo: 'Sua recomendação',
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              if (r.perfilEmpresa) ...[
                const TextoDeApoio(
                  'Para esse volume, o plano Empresa atende melhor. Fale com o nosso time comercial.',
                ),
                SecaoAgrupada(
                  cabecalho: 'Contato comercial',
                  children: [
                    LinhaLista(
                      titulo: r.contatoEmail ?? 'contato@cristalins.com.br',
                      icone: CupertinoIcons.mail,
                    ),
                    LinhaLista(
                      titulo: r.contatoTelefone ?? '(14) 3523-1001',
                      icone: CupertinoIcons.phone,
                    ),
                  ],
                ),
              ] else ...[
                SecaoAgrupada(
                  cabecalho: r.nomeDoKit,
                  rodape: '${r.ue} unidades equivalentes por entrega.',
                  children: [
                    for (final i in r.itens)
                      LinhaLista(
                        titulo: nomeDoProduto(i.produto),
                        trailing: Text(
                          '${i.quantidade}',
                          style: AppTypography.body.copyWith(color: AppColors.textoSecundario),
                        ),
                      ),
                    LinhaLista(
                      titulo: 'Entrega',
                      trailing: Text(
                        rotuloFrequencia(r.frequencia),
                        style: AppTypography.body.copyWith(color: AppColors.textoSecundario),
                      ),
                    ),
                  ],
                ),
                SecaoAgrupada(
                  cabecalho: 'Preço estimado por entrega',
                  rodape:
                      'No plano Flex, sem a taxa de entrega. O valor final aparece na escolha do plano.',
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.margem),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(r.valorEstimado?.formatado ?? '—', style: destaque),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.xs),
              BotaoSecundario(
                rotulo: 'Compartilhar resultado',
                icone: CupertinoIcons.share,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  dep.compartilhador.compartilhar(
                    _textoParaCompartilhar(r),
                    assunto: 'Minha recomendação Cristalins',
                  );
                },
              ),
              BotaoSecundario(
                rotulo: 'Refazer o quiz',
                onPressed: () {
                  HapticFeedback.selectionClick();
                  // RF44: recomeça do zero (o quiz anterior sai da pilha).
                  Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.quiz, (r) => r.isFirst);
                },
              ),
            ],
          ),
        ),
      ],
      rodape: r.perfilEmpresa
          ? null
          : BotaoPrincipal(
              rotulo: 'Montar minha cesta',
              onPressed: () {
                HapticFeedback.lightImpact();
                NavegacaoNativa.instancia.abrir(
                  context,
                  activity: NavegacaoNativa.catalogo,
                  rota: AppRoutes.catalogo,
                  arguments: PedidoAssinatura(
                    itens: r.itens,
                    frequencia: r.frequencia,
                    recomendacaoId: r.id,
                  ),
                  finish: true,
                );
              },
            ),
    );
  }
}
