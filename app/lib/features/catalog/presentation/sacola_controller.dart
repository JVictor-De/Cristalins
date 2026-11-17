import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/api_erro.dart';
import '../data/catalogo_repository.dart';
import '../domain/catalogo.dart';

/// Sacola global da assinatura (guest-first). Default: quinzenal + Flex.
class SacolaController extends ChangeNotifier {
  SacolaController(
    this._catalogo, {
    FlutterSecureStorage? storage,
    this.atraso = const Duration(milliseconds: 400),
  }) : _storage = storage ?? const FlutterSecureStorage() {
    unawaited(_restaurar());
  }

  static const _chave = 'cristalins_sacola_v1';
  static const caixaMista = {'WP500', 'FF500'};

  final CatalogoRepository _catalogo;
  final FlutterSecureStorage _storage;
  final Duration atraso;

  final Map<String, int> quantidades = {};
  List<Produto> produtos = [];
  List<Kit> kits = [];

  String frequencia = 'QUINZENAL';
  String plano = 'FLEX';

  bool carregandoCatalogo = true;
  String? erroCatalogo;

  bool simulando = false;
  Simulacao? simulacao;
  String? erroSimulacao;

  Timer? _espera;
  int _versao = 0;
  bool _pronto = false;

  bool get temItens => itens.isNotEmpty;
  int get totalItens => itens.fold(0, (a, i) => a + i.quantidade);

  List<ItemCesta> get itens => [
    for (final e in quantidades.entries)
      if (e.value > 0) ItemCesta(e.key, e.value),
  ];

  Produto? produtoDe(String codigo) {
    for (final p in produtos) {
      if (p.codigo == codigo) return p;
    }
    return null;
  }

  int passo(Produto p) => caixaMista.contains(p.codigo) ? p.embalagemQtd ~/ 2 : p.embalagemQtd;

  int quantidadeDe(String codigo) => quantidades[codigo] ?? 0;

  /// Garrafas que faltam para fechar a embalagem de [p] (P3.1 — **só exibição**;
  /// a API continua sendo quem valida, `EMBALAGEM_INVALIDA`). Caixa mista: conta a
  /// soma WP+FF na caixa de 6 (RN04); demais: múltiplo de `embalagemQtd`.
  int faltaParaCompletarCaixa(Produto p) {
    final tamanho = p.embalagemQtd;
    if (tamanho <= 1) return 0;
    final soma = caixaMista.contains(p.codigo)
        ? caixaMista.fold(0, (a, c) => a + quantidadeDe(c))
        : quantidadeDe(p.codigo);
    if (soma == 0) return 0;
    final resto = soma % tamanho;
    return resto == 0 ? 0 : tamanho - resto;
  }

  /// SKUs de caixa mista presentes na sacola (para a copy não citar FF ausente).
  List<String> get caixaMistaNaSacola => [
    for (final c in caixaMista)
      if (quantidadeDe(c) > 0) c,
  ];

  /// “Completar caixa”: soma ao **mesmo** SKU o que falta para fechar a caixa.
  void completarCaixa(Produto p) {
    final falta = faltaParaCompletarCaixa(p);
    if (falta <= 0) return;
    alterar(p.codigo, quantidadeDe(p.codigo) + falta);
  }

  /// Algum SKU da sacola com caixa incompleta (bloqueia “Continuar” com motivo).
  bool get temCaixaIncompleta => itens.any((i) {
    final p = produtoDe(i.produto);
    return p != null && faltaParaCompletarCaixa(p) > 0;
  });

  Future<void> carregarCatalogo() async {
    carregandoCatalogo = true;
    erroCatalogo = null;
    notifyListeners();
    try {
      final r = await Future.wait([_catalogo.produtos(), _catalogo.kits()]);
      produtos = r[0] as List<Produto>;
      kits = r[1] as List<Kit>;
      carregandoCatalogo = false;
      notifyListeners();
      if (temItens) await simular();
    } on ApiErro catch (e) {
      erroCatalogo = e.mensagem;
      carregandoCatalogo = false;
      notifyListeners();
    }
  }

  void alterar(String produto, int quantidade) {
    if (quantidade <= 0) {
      quantidades.remove(produto);
    } else {
      quantidades[produto] = quantidade;
    }
    _persistir();
    _agendarSimulacao();
  }

  void adicionarPasso(Produto p) {
    final atual = quantidadeDe(p.codigo);
    alterar(p.codigo, atual + passo(p));
  }

  void usarKit(Kit kit) {
    quantidades
      ..clear()
      ..addEntries(kit.itens.map((i) => MapEntry(i.produto, i.quantidade)));
    _persistir();
    _agendarSimulacao();
  }

  void escolherFrequencia(String f) {
    frequencia = f;
    _persistir();
    _agendarSimulacao();
  }

  void escolherPlano(String p) {
    plano = p;
    _persistir();
    _agendarSimulacao();
  }

  void limpar() {
    quantidades.clear();
    simulacao = null;
    erroSimulacao = null;
    _persistir();
    notifyListeners();
  }

  void _agendarSimulacao() {
    if (!_pronto) {
      notifyListeners();
      return;
    }
    simulando = true;
    notifyListeners();
    _espera?.cancel();
    _espera = Timer(atraso, simular);
  }

  Future<void> simular() async {
    final versao = ++_versao;
    final atuais = itens;
    if (atuais.isEmpty) {
      simulacao = null;
      erroSimulacao = null;
      simulando = false;
      notifyListeners();
      return;
    }
    simulando = true;
    notifyListeners();
    try {
      final s = await _catalogo.simular(itens: atuais, frequencia: frequencia, plano: plano);
      if (versao != _versao) return;
      simulacao = s;
      erroSimulacao = null;
    } on ApiErro catch (e) {
      if (versao != _versao) return;
      simulacao = null;
      erroSimulacao = e.mensagem;
    } finally {
      if (versao == _versao) {
        simulando = false;
        notifyListeners();
      }
    }
  }

  /// Sugere um SKU complementar barato para fechar o mínimo (nunca “só WP”).
  Produto? sugerirParaMinimo() {
    final falta = simulacao?.faltaUeParaMinimo ?? 0;
    if (falta <= 0 || produtos.isEmpty) return null;
    final candidatos = produtos.where((p) {
      if (p.codigo == 'WP500') return false;
      if (p.tipo == 'ADDON') return false;
      return true;
    }).toList()..sort((a, b) => a.precoBase.centavos.compareTo(b.precoBase.centavos));
    return candidatos.isEmpty ? null : candidatos.first;
  }

  Future<void> _restaurar() async {
    try {
      final raw = await _storage.read(key: _chave);
      if (raw != null && raw.isNotEmpty) {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        frequencia = (j['frequencia'] as String?) ?? 'QUINZENAL';
        plano = (j['plano'] as String?) ?? 'FLEX';
        final itens = j['itens'] as Map<String, dynamic>? ?? {};
        quantidades
          ..clear()
          ..addAll({for (final e in itens.entries) e.key: (e.value as num).toInt()});
      }
    } catch (_) {
      // ignore corrupt storage
    }
    _pronto = true;
    await carregarCatalogo();
  }

  Future<void> _persistir() async {
    try {
      await _storage.write(
        key: _chave,
        value: jsonEncode({'frequencia': frequencia, 'plano': plano, 'itens': quantidades}),
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _espera?.cancel();
    super.dispose();
  }
}
