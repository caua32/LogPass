class UserData {
  final int id;
  final String nome;
  final String email;
  final String tipo;
  final String? cpf;
  final String? telefone;
  final String? cnpj;
  final String? razaoSocial;

  const UserData({
    required this.id,
    required this.nome,
    required this.email,
    required this.tipo,
    this.cpf,
    this.telefone,
    this.cnpj,
    this.razaoSocial,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    final u = json['usuario'] ?? json;
    return UserData(
      id: u['id'] ?? 0,
      nome: u['nome'] ?? '',
      email: u['email'] ?? '',
      tipo: u['tipo'] ?? '',
      cpf: json['cpf'],
      telefone: json['telefone'],
      cnpj: json['cnpj'],
      razaoSocial: json['razao_social'],
    );
  }
}
