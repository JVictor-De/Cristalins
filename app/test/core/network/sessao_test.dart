import 'package:cristalins_assinatura/core/network/sessao.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ArmazenamentoEmMemoria', () {
    test('salva, lê e limpa tokens', () async {
      final s = ArmazenamentoEmMemoria();
      expect(await s.lerAcesso(), isNull);
      expect(await s.lerRefresh(), isNull);

      await s.salvar(acesso: 'a1', refresh: 'r1');
      expect(await s.lerAcesso(), 'a1');
      expect(await s.lerRefresh(), 'r1');

      await s.limpar();
      expect(await s.lerAcesso(), isNull);
      expect(await s.lerRefresh(), isNull);
    });

    test('salvar sobrescreve tokens anteriores', () async {
      final s = ArmazenamentoEmMemoria();
      await s.salvar(acesso: 'old', refresh: 'old-r');
      await s.salvar(acesso: 'new', refresh: 'new-r');
      expect(await s.lerAcesso(), 'new');
      expect(await s.lerRefresh(), 'new-r');
    });
  });
}
