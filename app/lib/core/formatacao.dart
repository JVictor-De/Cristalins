import 'package:intl/intl.dart';

/// Valor monetário em centavos inteiros, só para exibir o que a API calculou (sem conta no app).
class Dinheiro {
  const Dinheiro(this.centavos);

  /// A API manda número com 2 casas (ex.: 213.19).
  factory Dinheiro.daApi(num valor) => Dinheiro((valor * 100).round());

  final int centavos;

  static final _formato = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');

  String get formatado => _formato.format(centavos / 100);

  @override
  bool operator ==(Object other) => other is Dinheiro && other.centavos == centavos;

  @override
  int get hashCode => centavos.hashCode;

  @override
  String toString() => formatado;
}

/// Datas da API (AAAA-MM-DD ou ISO) no padrão brasileiro.
abstract final class Datas {
  static DateTime _civil(String iso) {
    final p = iso.substring(0, 10).split('-').map(int.parse).toList();
    return DateTime(p[0], p[1], p[2]);
  }

  /// 16/11
  static String curta(String iso) => DateFormat('dd/MM', 'pt_BR').format(_civil(iso));

  /// segunda, 16/11
  static String comDiaDaSemana(String iso) =>
      DateFormat('EEEE, dd/MM', 'pt_BR').format(_civil(iso));

  /// Instante (ISO com fuso) em data e hora de São Paulo (UTC−3): 14/11 às 23h59
  static String instante(String iso) {
    final sp = DateTime.parse(iso).toUtc().subtract(const Duration(hours: 3));
    return '${DateFormat('dd/MM').format(sp)} às ${DateFormat("HH'h'mm").format(sp)}';
  }
}
