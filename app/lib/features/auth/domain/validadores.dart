/// Validação de formulário antes de enviar (Anexo: "validar campos antes de enviar").
/// As regras de negócio (18+, CPF único) ficam na API; aqui só formato e dígitos verificadores.
abstract final class Validadores {
  static String digitos(String v) => v.replaceAll(RegExp(r'\D'), '');

  static String? nome(String? v) => (v ?? '').trim().length < 2 ? 'Informe o nome completo.' : null;

  static String? email(String? v) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch((v ?? '').trim())
      ? null
      : 'Informe um e-mail válido.';

  static String? senha(String? v) {
    final s = v ?? '';
    if (s.length < 8) return 'A senha precisa ter pelo menos 8 caracteres.';
    if (s.length > 72) return 'A senha pode ter no máximo 72 caracteres.';
    return null;
  }

  static String? celular(String? v) {
    final d = digitos(v ?? '');
    if (d.isEmpty) return null; // opcional
    return d.length == 10 || d.length == 11 ? null : 'Informe o celular com DDD.';
  }

  static String? cpfCnpj(String? v) {
    final d = digitos(v ?? '');
    final valido = d.length == 11 ? _cpf(d) : (d.length == 14 && _cnpj(d));
    return valido ? null : 'CPF ou CNPJ inválido. Confira os números.';
  }

  /// DD/MM/AAAA → data real. Devolve a mensagem de erro ou null.
  static String? dataNascimento(String? v) =>
      paraIso(v) == null ? 'Informe a data no formato DD/MM/AAAA.' : null;

  /// DD/MM/AAAA → AAAA-MM-DD (null se inválida).
  static String? paraIso(String? v) {
    final m = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch((v ?? '').trim());
    if (m == null) return null;
    final dia = int.parse(m[1]!), mes = int.parse(m[2]!), ano = int.parse(m[3]!);
    final d = DateTime(ano, mes, dia);
    if (d.year != ano || d.month != mes || d.day != dia || ano < 1900) return null;
    return '${m[3]}-${m[2]}-${m[1]}';
  }

  static String? cep(String? v) =>
      digitos(v ?? '').length == 8 ? null : 'Informe o CEP com 8 dígitos.';

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
