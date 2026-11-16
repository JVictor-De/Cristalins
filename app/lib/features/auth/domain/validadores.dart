/// Validação de formulário antes de enviar (Anexo: "validar campos antes de enviar").
/// As regras de negócio (18+, CPF único) ficam na API; aqui só formato e dígitos verificadores.
abstract final class Validadores {
  static String digitos(String v) => v.replaceAll(RegExp(r'\D'), '');

  static String? nome(String? v) => (v ?? '').trim().length < 2 ? 'Informe o nome completo.' : null;

  static String? razaoSocial(String? v) =>
      (v ?? '').trim().length < 2 ? 'Informe a razão social.' : null;

  static String? email(String? v) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch((v ?? '').trim())
      ? null
      : 'Informe um e-mail válido.';

  /// Sugestão local de domínio (ex.: gmial → gmail). Null se ok.
  static String? tipDominioEmail(String? v) {
    final e = (v ?? '').trim().toLowerCase();
    final at = e.lastIndexOf('@');
    if (at < 1) return null;
    final local = e.substring(0, at);
    final dominio = e.substring(at + 1);
    const mapa = {
      'gmial.com': 'gmail.com',
      'gmal.com': 'gmail.com',
      'gnail.com': 'gmail.com',
      'hotmal.com': 'hotmail.com',
      'hotnail.com': 'hotmail.com',
      'outlok.com': 'outlook.com',
    };
    final corr = mapa[dominio];
    if (corr == null) return null;
    return '$local@$corr';
  }

  static const _senhasComuns = {
    '12345678',
    '123456789',
    'password',
    'senha123',
    'qwerty12',
    'abcdefgh',
  };

  static String? senha(String? v) {
    final s = v ?? '';
    if (s.length < 8) return 'A senha precisa ter pelo menos 8 caracteres.';
    if (s.length > 72) return 'A senha pode ter no máximo 72 caracteres.';
    if (_senhasComuns.contains(s.toLowerCase())) {
      return 'Escolha uma senha menos óbvia.';
    }
    return null;
  }

  /// Checklist de força (UI) — não substitui [senha].
  static ({bool comprimento, bool letra, bool numero}) forcaSenha(String s) => (
        comprimento: s.length >= 8,
        letra: RegExp(r'[A-Za-z]').hasMatch(s),
        numero: RegExp(r'\d').hasMatch(s),
      );

  /// Celular obrigatório (P5): DDD + número.
  static String? celular(String? v) {
    final d = digitos(v ?? '');
    if (d.isEmpty) return 'Informe o celular com DDD.';
    return d.length == 10 || d.length == 11 ? null : 'Informe o celular com DDD.';
  }

  static String? cpfCnpj(String? v) {
    final d = digitos(v ?? '');
    final valido = d.length == 11 ? _cpf(d) : (d.length == 14 && _cnpj(d));
    return valido ? null : 'CPF ou CNPJ inválido. Confira os números.';
  }

  static bool ehCnpj(String? v) => digitos(v ?? '').length == 14;

  static bool ehCpf(String? v) => digitos(v ?? '').length == 11;

  /// DD/MM/AAAA → data real. Devolve a mensagem de erro ou null.
  static String? dataNascimento(String? v) {
    final iso = paraIso(v);
    if (iso == null) return 'Informe a data no formato DD/MM/AAAA.';
    if (!_maiorDeIdade(iso)) return 'A assinatura é só para maiores de 18 anos.';
    return null;
  }

  static bool _maiorDeIdade(String iso) {
    final p = iso.split('-').map(int.parse).toList();
    final nasc = DateTime(p[0], p[1], p[2]);
    final hoje = DateTime.now();
    final corte = DateTime(hoje.year - 18, hoje.month, hoje.day);
    return !nasc.isAfter(corte);
  }

  /// DD/MM/AAAA → AAAA-MM-DD (null se inválida).
  static String? paraIso(String? v) {
    final m = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch((v ?? '').trim());
    if (m == null) return null;
    final dia = int.parse(m[1]!), mes = int.parse(m[2]!), ano = int.parse(m[3]!);
    final d = DateTime(ano, mes, dia);
    if (d.year != ano || d.month != mes || d.day != dia || ano < 1900) return null;
    return '${m[3]}-${m[2]}-${m[1]}';
  }

  static String deIsoParaBr(String iso) {
    final p = iso.split('-');
    if (p.length != 3) return iso;
    return '${p[2]}/${p[1]}/${p[0]}';
  }

  static String? cep(String? v) =>
      digitos(v ?? '').length == 8 ? null : 'Informe o CEP com 8 dígitos.';

  static String mascaraCpfCnpj(String bruto) {
    final d = digitos(bruto);
    if (d.length <= 11) {
      final b = StringBuffer();
      for (var i = 0; i < d.length && i < 11; i++) {
        if (i == 3 || i == 6) b.write('.');
        if (i == 9) b.write('-');
        b.write(d[i]);
      }
      return b.toString();
    }
    final b = StringBuffer();
    for (var i = 0; i < d.length && i < 14; i++) {
      if (i == 2 || i == 5) b.write('.');
      if (i == 8) b.write('/');
      if (i == 12) b.write('-');
      b.write(d[i]);
    }
    return b.toString();
  }

  static String mascaraCelular(String bruto) {
    final d = digitos(bruto);
    if (d.isEmpty) return '';
    if (d.length <= 2) return '($d';
    if (d.length <= 7) return '(${d.substring(0, 2)}) ${d.substring(2)}';
    if (d.length <= 10) {
      return '(${d.substring(0, 2)}) ${d.substring(2, 6)}-${d.substring(6)}';
    }
    final n = d.substring(0, 11);
    return '(${n.substring(0, 2)}) ${n.substring(2, 7)}-${n.substring(7)}';
  }

  static bool _repetido(String d) => RegExp(r'^(\d)\1*$').hasMatch(d);

  static bool _cpf(String d) {
    if (_repetido(d)) return false;
    int dv(int n) {
      var soma = 0;
      for (var i = 0; i < n; i++) {
        soma += int.parse(d[i]) * (n + 1 - i);
      }
      final r = soma % 11;
      return r < 2 ? 0 : 11 - r;
    }

    return dv(9) == int.parse(d[9]) && dv(10) == int.parse(d[10]);
  }

  static bool _cnpj(String d) {
    if (_repetido(d)) return false;
    int dv(List<int> pesos) {
      var soma = 0;
      for (var i = 0; i < pesos.length; i++) {
        soma += int.parse(d[i]) * pesos[i];
      }
      final r = soma % 11;
      return r < 2 ? 0 : 11 - r;
    }

    const p1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    const p2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    return dv(p1) == int.parse(d[12]) && dv(p2) == int.parse(d[13]);
  }
}
