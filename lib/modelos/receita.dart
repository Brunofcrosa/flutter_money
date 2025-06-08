class Receita {
  int? id;
  double valor;
  DateTime data;
  String? descricao;

  Receita({this.id, required this.valor, required this.data, this.descricao});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'valor': valor,
      'data': data.toIso8601String(),
      'descricao': descricao,
    };
  }

  factory Receita.fromMap(Map<String, dynamic> map) {
    return Receita(
      id: map['id'] as int?,
      valor: map['valor'] as double,
      data: DateTime.parse(map['data'] as String),
      descricao: map['descricao'] as String?,
    );
  }

  Receita copyWith({
    int? id,
    double? valor,
    DateTime? data,
    String? descricao,
  }) {
    return Receita(
      id: id ?? this.id,
      valor: valor ?? this.valor,
      data: data ?? this.data,
      descricao: descricao ?? this.descricao,
    );
  }

  @override
  String toString() {
    return 'Receita(id: $id, valor: $valor, data: $data, descricao: $descricao)';
  }
}
