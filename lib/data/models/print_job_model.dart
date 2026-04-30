class PrintJobModel {
  final String id;
  final String qrRaw;
  final String text;
  final String codigo;
  final String lote;
  final String articulo;
  final String metraje;
  final String revisador;
  final String createdAtIso;
  final int attempts;

  const PrintJobModel({
    required this.id,
    required this.qrRaw,
    required this.text,
    required this.codigo,
    required this.lote,
    required this.articulo,
    required this.metraje,
    required this.revisador,
    required this.createdAtIso,
    this.attempts = 0,
  });

  PrintJobModel copyWith({
    String? id,
    String? qrRaw,
    String? text,
    String? codigo,
    String? lote,
    String? articulo,
    String? metraje,
    String? revisador,
    String? createdAtIso,
    int? attempts,
  }) {
    return PrintJobModel(
      id: id ?? this.id,
      qrRaw: qrRaw ?? this.qrRaw,
      text: text ?? this.text,
      codigo: codigo ?? this.codigo,
      lote: lote ?? this.lote,
      articulo: articulo ?? this.articulo,
      metraje: metraje ?? this.metraje,
      revisador: revisador ?? this.revisador,
      createdAtIso: createdAtIso ?? this.createdAtIso,
      attempts: attempts ?? this.attempts,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'qr_raw': qrRaw,
      'text': text,
      'codigo': codigo,
      'lote': lote,
      'articulo': articulo,
      'metraje': metraje,
      'revisador': revisador,
      'created_at_iso': createdAtIso,
      'attempts': attempts,
    };
  }

  factory PrintJobModel.fromJson(Map<String, dynamic> map) {
    return PrintJobModel(
      id: (map['id'] ?? '').toString(),
      qrRaw: (map['qr_raw'] ?? '').toString(),
      text: (map['text'] ?? '').toString(),
      codigo: (map['codigo'] ?? '').toString(),
      lote: (map['lote'] ?? '').toString(),
      articulo: (map['articulo'] ?? '').toString(),
      metraje: (map['metraje'] ?? '').toString(),
      revisador: (map['revisador'] ?? '').toString(),
      createdAtIso: (map['created_at_iso'] ?? '').toString(),
      attempts: int.tryParse((map['attempts'] ?? '').toString()) ?? 0,
    );
  }
}
