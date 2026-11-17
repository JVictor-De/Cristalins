/// Recorte de `GET /clientes/me` que as telas usam (saudação e perfil).
class PerfilCliente {
  const PerfilCliente({required this.nome, required this.email});

  final String nome;
  final String email;

  /// “Ana Souza” → “Ana”. Vazio se o nome vier em branco (conta anonimizada).
  String get primeiroNome {
    final partes = nome.trim().split(RegExp(r'\s+'));
    return partes.first;
  }

  /// “Olá, Ana!” com nome; “Olá!” sem perfil ou sem nome.
  static String saudacao(PerfilCliente? perfil) {
    final nome = perfil?.primeiroNome ?? '';
    return nome.isEmpty ? 'Olá!' : 'Olá, $nome!';
  }
}
