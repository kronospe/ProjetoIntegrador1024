class Opcao {
  final String valor;
  final String nome;
  const Opcao(this.valor, this.nome);

  factory Opcao.fromJson(Map<String, dynamic> j) =>
      Opcao(j['valor'] as String, j['nome'] as String);
}

class Opcoes {
  final List<String> cursos;
  final List<Opcao> locais;
  final List<Opcao> situacoes;
  final List<Opcao> icones;
  final List<String> sugestoesChatbot;

  const Opcoes({
    required this.cursos,
    required this.locais,
    required this.situacoes,
    required this.icones,
    required this.sugestoesChatbot,
  });

  static List<Opcao> _lista(dynamic v) =>
      (v as List).map((e) => Opcao.fromJson(e as Map<String, dynamic>)).toList();

  factory Opcoes.fromJson(Map<String, dynamic> j) => Opcoes(
        cursos: (j['cursos'] as List).cast<String>(),
        locais: _lista(j['locais']),
        situacoes: _lista(j['situacoes']),
        icones: _lista(j['icones']),
        sugestoesChatbot: (j['sugestoes_chatbot'] as List).cast<String>(),
      );
}
