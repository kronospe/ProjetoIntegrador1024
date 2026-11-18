class Reivindicacao {
  final String status; // pendente | aprovada | recusada
  final String? descricaoProva; // só para os envolvidos
  final String? requerenteNome;
  final String? contato; // telefone da outra parte, só após aprovada

  const Reivindicacao({
    required this.status,
    this.descricaoProva,
    this.requerenteNome,
    this.contato,
  });

  bool get detalhada => descricaoProva != null;

  factory Reivindicacao.fromJson(Map<String, dynamic> j) => Reivindicacao(
        status: j['status'] as String,
        descricaoProva: j['descricao_prova'] as String?,
        requerenteNome: j['requerente_nome'] as String?,
        contato: j['contato'] as String?,
      );
}

class Item {
  final int id;
  final String nome;
  final String descricao;
  final String local;
  final String localDisplay;
  final String situacao; // perdido | encontrado
  final String status; // ativo | reivindicado | entregue
  final String icone;
  final String? foto;
  final DateTime dataEncontro;
  final int donoId;
  final String donoNome;
  final bool podeEditar;
  final bool podeReivindicar;
  final bool podeDecidir;
  final Reivindicacao? reivindicacao;

  const Item({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.local,
    required this.localDisplay,
    required this.situacao,
    required this.status,
    required this.icone,
    required this.foto,
    required this.dataEncontro,
    required this.donoId,
    required this.donoNome,
    required this.podeEditar,
    required this.podeReivindicar,
    required this.podeDecidir,
    required this.reivindicacao,
  });

  factory Item.fromJson(Map<String, dynamic> j) {
    final reiv = j['reivindicacao'];
    return Item(
      id: j['id'] as int,
      nome: j['nome'] as String,
      descricao: (j['descricao'] ?? '') as String,
      local: j['local'] as String,
      localDisplay: (j['local_display'] ?? j['local']) as String,
      situacao: j['situacao_item'] as String,
      status: j['status_item'] as String,
      icone: (j['icone'] ?? 'fa-laptop') as String,
      foto: j['foto'] as String?,
      dataEncontro: DateTime.parse(j['data_encontro'] as String),
      donoId: j['cadastrado_por_id'] as int,
      donoNome: (j['cadastrado_por_nome'] ?? '') as String,
      podeEditar: (j['pode_editar'] ?? false) as bool,
      podeReivindicar: (j['pode_reivindicar'] ?? false) as bool,
      podeDecidir: (j['pode_decidir'] ?? false) as bool,
      reivindicacao: reiv is Map<String, dynamic> ? Reivindicacao.fromJson(reiv) : null,
    );
  }
}

class PaginaItens {
  final List<Item> itens;
  final bool temMais;
  const PaginaItens(this.itens, this.temMais);
}
