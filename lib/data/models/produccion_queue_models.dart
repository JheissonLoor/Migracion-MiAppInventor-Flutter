class UrdidoQueueJobModel {
  final String id;
  final String codigoPcp;
  final String codigoUrdido;
  final String usuario;
  final String createdAtIso;
  final int attempts;
  final Map<String, dynamic> payload;

  const UrdidoQueueJobModel({
    required this.id,
    required this.codigoPcp,
    required this.codigoUrdido,
    required this.usuario,
    required this.createdAtIso,
    required this.payload,
    this.attempts = 0,
  });

  UrdidoQueueJobModel copyWith({
    String? id,
    String? codigoPcp,
    String? codigoUrdido,
    String? usuario,
    String? createdAtIso,
    int? attempts,
    Map<String, dynamic>? payload,
  }) {
    return UrdidoQueueJobModel(
      id: id ?? this.id,
      codigoPcp: codigoPcp ?? this.codigoPcp,
      codigoUrdido: codigoUrdido ?? this.codigoUrdido,
      usuario: usuario ?? this.usuario,
      createdAtIso: createdAtIso ?? this.createdAtIso,
      attempts: attempts ?? this.attempts,
      payload: payload ?? this.payload,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigo_pcp': codigoPcp,
      'codigo_urdido': codigoUrdido,
      'usuario': usuario,
      'created_at_iso': createdAtIso,
      'attempts': attempts,
      'payload': payload,
    };
  }

  factory UrdidoQueueJobModel.fromJson(Map<String, dynamic> map) {
    final payloadRaw = map['payload'];
    final payload =
        payloadRaw is Map
            ? payloadRaw.map((key, value) => MapEntry(key.toString(), value))
            : <String, dynamic>{};

    return UrdidoQueueJobModel(
      id: (map['id'] ?? '').toString(),
      codigoPcp: (map['codigo_pcp'] ?? '').toString(),
      codigoUrdido: (map['codigo_urdido'] ?? '').toString(),
      usuario: (map['usuario'] ?? '').toString(),
      createdAtIso: (map['created_at_iso'] ?? '').toString(),
      attempts: int.tryParse((map['attempts'] ?? '').toString()) ?? 0,
      payload: payload,
    );
  }
}

class EngomadoQueueJobModel {
  final String id;
  final String tipoProceso;
  final String codigoPcp;
  final String usuario;
  final String createdAtIso;
  final int attempts;
  final Map<String, dynamic> payload;

  const EngomadoQueueJobModel({
    required this.id,
    required this.tipoProceso,
    required this.codigoPcp,
    required this.usuario,
    required this.createdAtIso,
    required this.payload,
    this.attempts = 0,
  });

  EngomadoQueueJobModel copyWith({
    String? id,
    String? tipoProceso,
    String? codigoPcp,
    String? usuario,
    String? createdAtIso,
    int? attempts,
    Map<String, dynamic>? payload,
  }) {
    return EngomadoQueueJobModel(
      id: id ?? this.id,
      tipoProceso: tipoProceso ?? this.tipoProceso,
      codigoPcp: codigoPcp ?? this.codigoPcp,
      usuario: usuario ?? this.usuario,
      createdAtIso: createdAtIso ?? this.createdAtIso,
      attempts: attempts ?? this.attempts,
      payload: payload ?? this.payload,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tipo_proceso': tipoProceso,
      'codigo_pcp': codigoPcp,
      'usuario': usuario,
      'created_at_iso': createdAtIso,
      'attempts': attempts,
      'payload': payload,
    };
  }

  factory EngomadoQueueJobModel.fromJson(Map<String, dynamic> map) {
    final payloadRaw = map['payload'];
    final payload =
        payloadRaw is Map
            ? payloadRaw.map((key, value) => MapEntry(key.toString(), value))
            : <String, dynamic>{};

    return EngomadoQueueJobModel(
      id: (map['id'] ?? '').toString(),
      tipoProceso: (map['tipo_proceso'] ?? '').toString(),
      codigoPcp: (map['codigo_pcp'] ?? '').toString(),
      usuario: (map['usuario'] ?? '').toString(),
      createdAtIso: (map['created_at_iso'] ?? '').toString(),
      attempts: int.tryParse((map['attempts'] ?? '').toString()) ?? 0,
      payload: payload,
    );
  }
}

class TelaresQueueJobModel {
  final String id;
  final String codigoPcp;
  final String modoRegistro;
  final String usuario;
  final String createdAtIso;
  final int attempts;
  final Map<String, dynamic> payload;

  const TelaresQueueJobModel({
    required this.id,
    required this.codigoPcp,
    required this.modoRegistro,
    required this.usuario,
    required this.createdAtIso,
    required this.payload,
    this.attempts = 0,
  });

  TelaresQueueJobModel copyWith({
    String? id,
    String? codigoPcp,
    String? modoRegistro,
    String? usuario,
    String? createdAtIso,
    int? attempts,
    Map<String, dynamic>? payload,
  }) {
    return TelaresQueueJobModel(
      id: id ?? this.id,
      codigoPcp: codigoPcp ?? this.codigoPcp,
      modoRegistro: modoRegistro ?? this.modoRegistro,
      usuario: usuario ?? this.usuario,
      createdAtIso: createdAtIso ?? this.createdAtIso,
      attempts: attempts ?? this.attempts,
      payload: payload ?? this.payload,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigo_pcp': codigoPcp,
      'modo_registro': modoRegistro,
      'usuario': usuario,
      'created_at_iso': createdAtIso,
      'attempts': attempts,
      'payload': payload,
    };
  }

  factory TelaresQueueJobModel.fromJson(Map<String, dynamic> map) {
    final payloadRaw = map['payload'];
    final payload =
        payloadRaw is Map
            ? payloadRaw.map((key, value) => MapEntry(key.toString(), value))
            : <String, dynamic>{};

    return TelaresQueueJobModel(
      id: (map['id'] ?? '').toString(),
      codigoPcp: (map['codigo_pcp'] ?? '').toString(),
      modoRegistro: (map['modo_registro'] ?? '').toString(),
      usuario: (map['usuario'] ?? '').toString(),
      createdAtIso: (map['created_at_iso'] ?? '').toString(),
      attempts: int.tryParse((map['attempts'] ?? '').toString()) ?? 0,
      payload: payload,
    );
  }
}
