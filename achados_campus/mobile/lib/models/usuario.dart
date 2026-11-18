class Usuario {
  final int id;
  final String nome;
  final String email;
  final bool isStaff;
  final int? matricula;
  final String curso;
  final String telefone;
  final String avatar;
  final String bio;
  final bool perfilCompleto;

  const Usuario({
    required this.id,
    required this.nome,
    required this.email,
    required this.isStaff,
    required this.matricula,
    required this.curso,
    required this.telefone,
    required this.avatar,
    required this.bio,
    required this.perfilCompleto,
  });

  factory Usuario.fromJson(Map<String, dynamic> j) => Usuario(
        id: j['id'] as int,
        nome: (j['nome'] ?? '') as String,
        email: (j['email'] ?? '') as String,
        isStaff: (j['is_staff'] ?? false) as bool,
        matricula: j['matricula'] as int?,
        curso: (j['curso'] ?? '') as String,
        telefone: (j['telefone'] ?? '') as String,
        avatar: (j['avatar'] ?? '🧑‍💻') as String,
        bio: (j['bio'] ?? '') as String,
        perfilCompleto: (j['perfil_completo'] ?? false) as bool,
      );
}
