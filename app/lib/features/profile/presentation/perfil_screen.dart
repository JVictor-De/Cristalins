import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/dependencias.dart';
import '../../../core/network/api_erro.dart';
import '../../../core/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/botao_principal.dart';
import '../../../core/widgets/estados.dart';
import '../../../core/widgets/folha_lista_espera.dart';
import '../../address/domain/cep_sessao.dart';
import '../../auth/domain/perfil_cliente.dart';
import '../../auth/domain/validadores.dart';

/// Perfil — guest (P4) + logado com rotas/API existentes.
class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  var _logado = false;
  var _carregando = true;
  var _iniciou = false;
  String? _rotuloCep;
  PerfilCliente? _perfil;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_iniciou) {
      _iniciou = true;
      _checarSessao();
    }
  }

  Future<void> _checarSessao() async {
    final dep = context.read<Dependencias>();
    final token = await dep.api?.tokens.lerAcesso();
    if (mounted) {
      setState(() {
        _logado = token != null && token.isNotEmpty;
        _carregando = false;
      });
    }
    if (!_logado) return;
    try {
      final perfil = await dep.auth.perfil();
      if (mounted) setState(() => _perfil = perfil);
    } catch (_) {
      // Sem perfil: a seção mostra o texto genérico.
    }
  }

  Future<void> _abrirWhatsApp(AppConfig config) async {
    final url = config.urlWhatsApp();
    if (url == null) return;
    HapticFeedback.selectionClick();
    final abriu = await context.read<Dependencias>().links.abrir(url);
    if (!abriu && mounted) {
      mostrarAviso(context, 'Não conseguimos abrir o WhatsApp agora.', erro: true);
    }
  }

  Future<void> _abrirCep() async {
    HapticFeedback.selectionClick();
    final resultado = await showModalBottomSheet<_ResultadoCepPerfil>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.superficie,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.raioCard)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: const _FolhaCepPerfil(),
      ),
    );
    if (!mounted || resultado == null) return;
    if (resultado.cepForaDaArea != null) {
      await abrirFolhaListaEspera(context, cepForaDaArea: resultado.cepForaDaArea);
      return;
    }
    CepDaSessao.valor = resultado.cep;
    setState(() => _rotuloCep = resultado.rotulo);
  }

  void _abrirFaq() {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.superficie,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.raioCard)),
      ),
      builder: (ctx) => const _FolhaFaq(),
    );
  }

  Future<void> _sair() async {
    HapticFeedback.selectionClick();
    await context.read<Dependencias>().auth.sair();
    if (!mounted) return;
    setState(() => _logado = false);
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.shell, (_) => false);
  }

  Future<void> _excluirConta() async {
    HapticFeedback.selectionClick();
    final confirmar = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Excluir minha conta?'),
        message: const Text(
          'Anonimizamos nome, contato e endereço. Dados fiscais ficam o tempo exigido por lei. Esta ação não tem volta.',
        ),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir conta'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Manter conta'),
        ),
      ),
    );
    if (confirmar != true || !mounted) return;
    try {
      await context.read<Dependencias>().auth.excluirConta();
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() => _logado = false);
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.shell, (_) => false);
      mostrarAviso(context, 'Conta excluída.');
    } catch (e) {
      if (mounted) mostrarAviso(context, ApiErro.de(e).mensagem, erro: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<AppConfig>();

    return Material(
      color: AppColors.fundo,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.margem,
            AppSpacing.sm,
            AppSpacing.margem,
            AppSpacing.secaoGrande,
          ),
          children: [
            Text('Perfil', style: AppTypography.title3.copyWith(color: AppColors.navy)),
            const SizedBox(height: AppSpacing.secao),
            if (_carregando)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.secao),
                child: Center(child: CircularProgressIndicator(color: AppColors.azulMarca)),
              )
            else if (!_logado)
              _Guest(
                config: config,
                rotuloCep: _rotuloCep,
                onEntrar: () => Navigator.of(context).pushNamed(AppRoutes.cadastroLogin),
                onFaq: _abrirFaq,
                onWhatsApp: () => _abrirWhatsApp(config),
                onCep: _abrirCep,
                onSite: () => context.read<Dependencias>().links.abrir(AppConfig.siteMarca),
              )
            else
              _Logado(
                config: config,
                perfil: _perfil,
                rotuloCep: _rotuloCep,
                onFaq: _abrirFaq,
                onWhatsApp: () => _abrirWhatsApp(config),
                onCep: _abrirCep,
                onSite: () => context.read<Dependencias>().links.abrir(AppConfig.siteMarca),
                onAssinatura: () => Navigator.of(context).pushNamed(AppRoutes.minhaAssinatura),
                onSair: _sair,
                onExcluir: _excluirConta,
              ),
          ],
        ),
      ),
    );
  }
}

class _Guest extends StatelessWidget {
  const _Guest({
    required this.config,
    required this.onEntrar,
    required this.onFaq,
    required this.onWhatsApp,
    required this.onCep,
    required this.onSite,
    this.rotuloCep,
  });

  final AppConfig config;
  final String? rotuloCep;
  final VoidCallback onEntrar;
  final VoidCallback onFaq;
  final VoidCallback onWhatsApp;
  final VoidCallback onCep;
  final VoidCallback onSite;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.person_outline, size: 56, color: AppColors.textoSuave.withValues(alpha: 0.8)),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Acompanhe entregas, pause e edite sua assinatura',
          textAlign: TextAlign.center,
          style: AppTypography.body.copyWith(color: AppColors.tinta),
        ),
        const SizedBox(height: AppSpacing.margem),
        BotaoPrincipal(
          rotulo: 'Entrar ou criar conta',
          variante: VarianteBotaoPrincipal.navy,
          onPressed: onEntrar,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Com e-mail e senha',
          textAlign: TextAlign.center,
          style: AppTypography.footnote.copyWith(color: AppColors.textoSuave),
        ),
        const SizedBox(height: AppSpacing.secao),
        _BlocoSuporteSobre(
          config: config,
          rotuloCep: rotuloCep,
          onFaq: onFaq,
          onWhatsApp: onWhatsApp,
          onCep: onCep,
          onSite: onSite,
        ),
        const SizedBox(height: AppSpacing.secao),
        Text(
          'Versão ${AppConfig.versaoApp}',
          textAlign: TextAlign.center,
          style: AppTypography.caption1.copyWith(color: AppColors.textoSuave),
        ),
      ],
    );
  }
}

class _Logado extends StatelessWidget {
  const _Logado({
    required this.config,
    required this.onFaq,
    required this.onWhatsApp,
    required this.onCep,
    required this.onSite,
    required this.onAssinatura,
    required this.onSair,
    required this.onExcluir,
    this.perfil,
    this.rotuloCep,
  });

  final AppConfig config;
  final PerfilCliente? perfil;
  final String? rotuloCep;
  final VoidCallback onFaq;
  final VoidCallback onWhatsApp;
  final VoidCallback onCep;
  final VoidCallback onSite;
  final VoidCallback onAssinatura;
  final VoidCallback onSair;
  final VoidCallback onExcluir;

  @override
  Widget build(BuildContext context) {
    final nome = perfil?.nome.trim() ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          nome.isEmpty ? 'Sua conta' : nome,
          key: const ValueKey('perfil-nome'),
          style: AppTypography.headline.copyWith(color: AppColors.navy),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          perfil == null || perfil!.email.isEmpty
              ? 'Gerencie assinatura e faturas.'
              : '${perfil!.email} · gerencie assinatura e faturas.',
          style: AppTypography.footnote.copyWith(color: AppColors.textoSuave),
        ),
        const SizedBox(height: AppSpacing.sm),
        _Linha(
          icone: Icons.local_shipping_outlined,
          titulo: 'Minha assinatura',
          onTap: onAssinatura,
        ),
        _Linha(
          icone: Icons.receipt_long_outlined,
          titulo: 'Faturas e pagamento',
          subtitulo: 'Pelo fluxo da assinatura',
          onTap: onAssinatura,
        ),
        const _Linha(
          icone: Icons.home_outlined,
          titulo: 'Endereços',
          subtitulo: 'Em breve',
          habilitado: false,
        ),
        const _Linha(
          icone: Icons.notifications_outlined,
          titulo: 'Notificações',
          subtitulo: 'Em breve',
          habilitado: false,
        ),
        const SizedBox(height: AppSpacing.secao),
        _BlocoSuporteSobre(
          config: config,
          rotuloCep: rotuloCep,
          onFaq: onFaq,
          onWhatsApp: onWhatsApp,
          onCep: onCep,
          onSite: onSite,
        ),
        const SizedBox(height: AppSpacing.secao),
        TextButton(
          onPressed: onSair,
          child: Text(
            'Sair',
            style: AppTypography.subheadline.copyWith(
              color: AppColors.azulMarca,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextButton(
          onPressed: onExcluir,
          child: Text(
            'Excluir conta',
            style: AppTypography.subheadline.copyWith(
              color: AppColors.erro,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Versão ${AppConfig.versaoApp}',
          textAlign: TextAlign.center,
          style: AppTypography.caption1.copyWith(color: AppColors.textoSuave),
        ),
      ],
    );
  }
}

class _BlocoSuporteSobre extends StatelessWidget {
  const _BlocoSuporteSobre({
    required this.config,
    required this.onFaq,
    required this.onWhatsApp,
    required this.onCep,
    required this.onSite,
    this.rotuloCep,
  });

  final AppConfig config;
  final String? rotuloCep;
  final VoidCallback onFaq;
  final VoidCallback onWhatsApp;
  final VoidCallback onCep;
  final VoidCallback onSite;

  Future<void> _abrirUrlLegal(BuildContext context, String url, String falha) async {
    HapticFeedback.selectionClick();
    final abriu = await context.read<Dependencias>().links.abrir(url);
    if (!abriu && context.mounted) mostrarAviso(context, falha, erro: true);
  }

  @override
  Widget build(BuildContext context) {
    final termosOk = AppConfig.urlTermos.isNotEmpty;
    final privOk = AppConfig.urlPrivacidade.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Suporte', style: AppTypography.headline.copyWith(color: AppColors.navy)),
        const SizedBox(height: AppSpacing.xs),
        _Linha(icone: Icons.help_outline, titulo: 'Ajuda e perguntas frequentes', onTap: onFaq),
        if (config.suporteWhatsappDigitos.isNotEmpty)
          _Linha(icone: Icons.chat_outlined, titulo: 'Fale conosco no WhatsApp', onTap: onWhatsApp),
        _Linha(
          icone: Icons.location_on_outlined,
          titulo: 'Área de entrega',
          subtitulo: rotuloCep ?? 'Consultar CEP',
          onTap: onCep,
        ),
        const SizedBox(height: AppSpacing.secao),
        Text('Sobre', style: AppTypography.headline.copyWith(color: AppColors.navy)),
        const SizedBox(height: AppSpacing.xs),
        _Linha(
          icone: Icons.description_outlined,
          titulo: 'Termos de uso',
          subtitulo: termosOk ? null : 'Em breve',
          habilitado: termosOk,
          onTap: termosOk
              ? () => _abrirUrlLegal(
                    context,
                    AppConfig.urlTermos,
                    'Não foi possível abrir os termos de uso.',
                  )
              : null,
        ),
        _Linha(
          icone: Icons.privacy_tip_outlined,
          titulo: 'Política de privacidade',
          subtitulo: privOk ? null : 'Em breve',
          habilitado: privOk,
          onTap: privOk
              ? () => _abrirUrlLegal(
                    context,
                    AppConfig.urlPrivacidade,
                    'Não foi possível abrir a política de privacidade.',
                  )
              : null,
        ),
        _Linha(
          icone: Icons.language,
          titulo: 'Site Cristalins',
          trailing: Icons.open_in_new,
          onTap: onSite,
        ),
      ],
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha({
    required this.icone,
    required this.titulo,
    this.subtitulo,
    this.trailing = Icons.chevron_right,
    this.onTap,
    this.habilitado = true,
  });

  final IconData icone;
  final String titulo;
  final String? subtitulo;
  final IconData? trailing;
  final VoidCallback? onTap;
  final bool habilitado;

  @override
  Widget build(BuildContext context) {
    final ativo = habilitado && onTap != null;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icone, color: ativo ? AppColors.azulMarca : AppColors.textoSuave),
      title: Text(
        titulo,
        style: AppTypography.subheadline.copyWith(
          color: ativo ? AppColors.tinta : AppColors.textoSuave,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitulo == null
          ? null
          : Text(subtitulo!, style: AppTypography.caption1.copyWith(color: AppColors.textoSuave)),
      trailing: trailing == null
          ? null
          : Icon(trailing, color: ativo ? AppColors.textoSuave : AppColors.linha),
      onTap: ativo ? onTap : null,
      minVerticalPadding: 12,
    );
  }
}

class _FolhaFaq extends StatelessWidget {
  const _FolhaFaq();

  static const _faqs = [
    (
      'Onde vocês entregam?',
      'Atendemos bairros oficiais do município do Rio de Janeiro. Confirme pelo CEP na home ou no checkout.',
    ),
    (
      'Posso pausar a assinatura?',
      'Sim. Na área logada você pausa ou ajusta a frequência conforme as regras da assinatura.',
    ),
    (
      'Como cancelo?',
      'Pelo app, em Minha assinatura, com confirmação. Sem taxa inventada nesta tela.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.margem,
          AppSpacing.sm,
          AppSpacing.margem,
          AppSpacing.margem,
        ),
        child: Column(
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
            Text(
              'Perguntas frequentes',
              style: AppTypography.title3.copyWith(color: AppColors.navy),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final (q, a) in _faqs) ...[
              Text(q, style: AppTypography.headline.copyWith(color: AppColors.tinta)),
              const SizedBox(height: 2),
              Text(a, style: AppTypography.footnote.copyWith(color: AppColors.textoSuave)),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultadoCepPerfil {
  const _ResultadoCepPerfil({required this.cep, required this.rotulo}) : cepForaDaArea = null;
  const _ResultadoCepPerfil.foraDaArea(String cep) : cep = cep, rotulo = '', cepForaDaArea = cep;
  final String cep;
  final String rotulo;

  /// CEP_FORA_AREA / BAIRRO_NAO_ATENDIDO: o perfil abre a lista de espera.
  final String? cepForaDaArea;
}

class _FolhaCepPerfil extends StatefulWidget {
  const _FolhaCepPerfil();

  @override
  State<_FolhaCepPerfil> createState() => _FolhaCepPerfilState();
}

class _FolhaCepPerfilState extends State<_FolhaCepPerfil> {
  final _ctrl = TextEditingController();
  var _carregando = false;
  String? _erro;
  String? _cepForaDaArea;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _consultar() async {
    final msg = Validadores.cep(_ctrl.text);
    if (msg != null) {
      setState(() => _erro = msg);
      return;
    }
    setState(() {
      _carregando = true;
      _erro = null;
      _cepForaDaArea = null;
    });
    final digitos = Validadores.digitos(_ctrl.text);
    try {
      final r = await context.read<Dependencias>().enderecos.consultarCep(digitos);
      if (!mounted) return;
      Navigator.of(
        context,
      ).pop(_ResultadoCepPerfil(cep: digitos, rotulo: 'Entrega em ${r.bairro} · ${r.zona.nome}'));
    } catch (e) {
      if (!mounted) return;
      final erro = ApiErro.de(e);
      setState(() {
        _carregando = false;
        _erro = erro.mensagem;
        if (erro.codigo == 'CEP_FORA_AREA' || erro.codigo == 'BAIRRO_NAO_ATENDIDO') {
          _cepForaDaArea = digitos;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.margem,
          AppSpacing.sm,
          AppSpacing.margem,
          AppSpacing.margem,
        ),
        child: Column(
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
            Text('Área de entrega', style: AppTypography.title3.copyWith(color: AppColors.navy)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Informe o CEP para ver se atendemos o bairro (mesma consulta do checkout).',
              style: AppTypography.footnote.copyWith(color: AppColors.textoSuave),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _ctrl,
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
                errorText: _erro,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.raioCard),
                ),
              ),
              onSubmitted: (_) => _consultar(),
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton(
              onPressed: _carregando ? null : _consultar,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.navy,
                minimumSize: const Size(0, AppSpacing.toqueMinimo),
              ),
              child: _carregando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.sobrePrimaria,
                      ),
                    )
                  : const Text('Confirmar CEP'),
            ),
            if (_cepForaDaArea != null)
              TextButton(
                key: const ValueKey('perfil-cep-lista-espera'),
                onPressed: () =>
                    Navigator.of(context).pop(_ResultadoCepPerfil.foraDaArea(_cepForaDaArea!)),
                child: Text(
                  'Entrar na lista de espera',
                  style: AppTypography.subheadline.copyWith(
                    color: AppColors.azulMarca,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Informar no checkout',
                style: AppTypography.subheadline.copyWith(color: AppColors.azulMarca),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
