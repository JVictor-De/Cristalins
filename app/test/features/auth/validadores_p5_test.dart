import 'package:cristalins_assinatura/features/auth/domain/validadores.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('celular obrigatório', () {
    expect(Validadores.celular(null), isNotNull);
    expect(Validadores.celular(''), isNotNull);
    expect(Validadores.celular('(21) 98765-4321'), isNull);
  });

  test('tip domínio e máscaras', () {
    expect(Validadores.tipDominioEmail('ana@gmial.com'), 'ana@gmail.com');
    expect(Validadores.mascaraCpfCnpj('52998224725'), contains('.'));
    expect(Validadores.mascaraCelular('21987654321'), startsWith('(21)'));
  });

  test('força senha checklist', () {
    final f = Validadores.forcaSenha('abc12345');
    expect(f.comprimento, isTrue);
    expect(f.letra, isTrue);
    expect(f.numero, isTrue);
    expect(Validadores.senha('12345678'), isNotNull);
  });
}
