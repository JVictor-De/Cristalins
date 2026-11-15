import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/network/api_erro.dart';
import '../../subscription/data/assinatura_repository.dart';
import '../data/catalogo_repository.dart';
import '../domain/catalogo.dart';

/// Cesta da Tela 5. Guarda só quantidades; preço e validação (mínimo, máximo, embalagem) vêm da API.
class CestaController extends ChangeNotifier {
  CestaController(
    this._catalogo,
    this._assinaturas, {
    required List<ItemCesta> itensIniciais,
    required this.frequencia,
    required this.plano,
    this.assinaturaId,
    this.atraso = const Duration(milliseconds: 400),
  }) {
    for (final i in itensIniciais) {
      quantidades[i.produto] = i.quantidade;
    }
    carregar();
  }

  final CatalogoRepository _catalogo;
  final AssinaturaRepository _assinaturas;
  final String frequencia;
  final String plano;

  /// Preenchido quando a tela veio de "Alterar cesta" (Tela 8).
  final String? assinaturaId;
  final Duration atraso;

  /// RN04: Water Protein e Flow Fiber podem dividir a caixa de 6 (caixa mista).
  static const caixaMista = {'WP500', 'FF500'};

  final Map<String, int> quantidades = {};
  List<Produto> produtos = [];
  List<Kit> kits = [];
  Categoria categoria = Categoria.todos;

  bool carregando = true;
  String? erroCarregar;

  bool simulando = false;
  Simulacao? simulacao;
  String? erroSimulacao;

  bool salvando = false;
  Timer? _espera;
  int _versao = 0;

  List<ItemCesta> get itens => [
    for (final p in produtos)
      if ((quantidades[p.codigo] ?? 0) > 0) ItemCesta(p.codigo, quantidades[p.codigo]!),
  ];

  List<Produto> get visiveis => produtos.where(categoria.inclui).toList();

  bool get podeContinuar =>
      itens.isNotEmpty && simulacao != null && erroSimulacao == null && !simulando;

  /// Passo do seletor: a embalagem de venda; na caixa mista, meia caixa (3 + 3).
  int passo(Produto p) => caixaMista.contains(p.codigo) ? p.embalagemQtd ~/ 2 : p.embalagemQtd;

  Future<void> carregar() async {
    carregando = true;
    erroCarregar = null;
    notifyListeners();
    try {
      final r = await Future.wait([_catalogo.produtos(), _catalogo.kits()]);
      produtos = r[0] as List<Produto>;
      kits = r[1] as List<Kit>;
      carregando = false;
      notifyListeners();
      await simular();
    } on ApiErro catch (e) {
      erroCarregar = e.mensagem;
      carregando = false;
      notifyListeners();
    }
  }

  void escolherCategoria(Categoria c) {
    categoria = c;
    notifyListeners();
  }

  void alterar(String produto, int quantidade) {
    quantidades[produto] = quantidade < 0 ? 0 : quantidade;
    _agendarSimulacao();
  }

  void usarKit(Kit kit) {
    quantidades
      ..clear()
      ..addEntries(kit.itens.map((i) => MapEntry(i.produto, i.quantidade)));
    _agendarSimulacao();
  }

  void _agendarSimulacao() {
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
      erroSimulacao = 'Escolha os produtos da sua cesta.';
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

  /// Modo "alterar cesta": `PUT /assinaturas/{id}`; devolve a data da entrega em que passa a valer.
  Future<String?> salvarAlteracao() async {
    salvando = true;
    notifyListeners();
    try {
      return await _assinaturas.alterarCesta(assinaturaId!, itens);
    } on ApiErro catch (e) {
      erroSimulacao = e.mensagem;
      return null;
    } finally {
      salvando = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _espera?.cancel();
    super.dispose();
  }
}
