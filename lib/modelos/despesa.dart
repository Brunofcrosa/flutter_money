enum TipoDespesa { fixa, avulsa }

class Despesa {
  int? id;
  String? nome;
  double valor;
  int? numParcelas;
  DateTime dataVencimento;
  String? descricao;
  TipoDespesa tipo;

  Despesa({
    this.id,
    this.nome,
    required this.valor,
    this.numParcelas,
    required this.dataVencimento,
    this.descricao,
    required this.tipo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'valor': valor,
      'numParcelas': numParcelas,
      'dataVencimento': dataVencimento.toIso8601String(),
      'descricao': descricao,
      'tipo': tipo.name,
    };
  }

  factory Despesa.fromMap(Map<String, dynamic> map) {
    return Despesa(
      id: map['id'] as int?,
      nome: map['nome'] as String?,
      valor: map['valor'] as double,
      numParcelas: map['numParcelas'] as int?,
      dataVencimento: DateTime.parse(map['dataVencimento'] as String),
      descricao: map['descricao'] as String?,
      tipo: TipoDespesa.values.firstWhere(
        (e) => e.name == map['tipo'] as String,
      ),
    );
  }

  Despesa copyWith({
    int? id,
    String? nome,
    double? valor,
    int? numParcelas,
    DateTime? dataVencimento,
    String? descricao,
    TipoDespesa? tipo,
  }) {
    return Despesa(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      valor: valor ?? this.valor,
      numParcelas: numParcelas ?? this.numParcelas,
      dataVencimento: dataVencimento ?? this.dataVencimento,
      descricao: descricao ?? this.descricao,
      tipo: tipo ?? this.tipo,
    );
  }

  @override
  String toString() {
    return 'Despesa(id: $id, nome: $nome, valor: $valor, numParcelas: $numParcelas, dataVencimento: $dataVencimento, descricao: $descricao, tipo: $tipo)';
  }
}
