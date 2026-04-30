class DespachoQueueRolloModel {
  final String codigo;
  final String articulo;
  final double metraje;
  final double peso;
  final String ubicacion;

  const DespachoQueueRolloModel({
    required this.codigo,
    required this.articulo,
    required this.metraje,
    required this.peso,
    required this.ubicacion,
  });

  Map<String, dynamic> toJson() {
    return {
      'codigo': codigo,
      'articulo': articulo,
      'metraje': metraje,
      'peso': peso,
      'ubicacion': ubicacion,
    };
  }

  factory DespachoQueueRolloModel.fromJson(Map<String, dynamic> map) {
    return DespachoQueueRolloModel(
      codigo: (map['codigo'] ?? '').toString(),
      articulo: (map['articulo'] ?? '').toString(),
      metraje: _toDouble(map['metraje']),
      peso: _toDouble(map['peso']),
      ubicacion: (map['ubicacion'] ?? '').toString(),
    );
  }
}

class DespachoQueueJobModel {
  final String id;
  final List<DespachoQueueRolloModel> rollos;
  final String destino;
  final String guia;
  final String observaciones;
  final String usuario;
  final String createdAtIso;
  final int attempts;

  const DespachoQueueJobModel({
    required this.id,
    required this.rollos,
    required this.destino,
    required this.guia,
    required this.observaciones,
    required this.usuario,
    required this.createdAtIso,
    this.attempts = 0,
  });

  double get totalMetros =>
      rollos.fold<double>(0, (sum, item) => sum + item.metraje);
  double get totalPeso =>
      rollos.fold<double>(0, (sum, item) => sum + item.peso);

  DespachoQueueJobModel copyWith({
    String? id,
    List<DespachoQueueRolloModel>? rollos,
    String? destino,
    String? guia,
    String? observaciones,
    String? usuario,
    String? createdAtIso,
    int? attempts,
  }) {
    return DespachoQueueJobModel(
      id: id ?? this.id,
      rollos: rollos ?? this.rollos,
      destino: destino ?? this.destino,
      guia: guia ?? this.guia,
      observaciones: observaciones ?? this.observaciones,
      usuario: usuario ?? this.usuario,
      createdAtIso: createdAtIso ?? this.createdAtIso,
      attempts: attempts ?? this.attempts,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rollos': rollos.map((item) => item.toJson()).toList(),
      'destino': destino,
      'guia': guia,
      'observaciones': observaciones,
      'usuario': usuario,
      'created_at_iso': createdAtIso,
      'attempts': attempts,
    };
  }

  factory DespachoQueueJobModel.fromJson(Map<String, dynamic> map) {
    final rawRollos = map['rollos'];
    final rollos = <DespachoQueueRolloModel>[];

    if (rawRollos is List) {
      for (final item in rawRollos) {
        if (item is Map) {
          rollos.add(
            DespachoQueueRolloModel.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    return DespachoQueueJobModel(
      id: (map['id'] ?? '').toString(),
      rollos: rollos,
      destino: (map['destino'] ?? '').toString(),
      guia: (map['guia'] ?? '').toString(),
      observaciones: (map['observaciones'] ?? '').toString(),
      usuario: (map['usuario'] ?? '').toString(),
      createdAtIso: (map['created_at_iso'] ?? '').toString(),
      attempts: int.tryParse((map['attempts'] ?? '').toString()) ?? 0,
    );
  }
}

class DespachoQueueTelemetryModel {
  final int enqueuedTotal;
  final int processedTotal;
  final int failedAttemptsTotal;
  final int retryAttemptsTotal;
  final String lastAttemptAtIso;
  final String lastProcessedAtIso;
  final String lastError;

  const DespachoQueueTelemetryModel({
    this.enqueuedTotal = 0,
    this.processedTotal = 0,
    this.failedAttemptsTotal = 0,
    this.retryAttemptsTotal = 0,
    this.lastAttemptAtIso = '',
    this.lastProcessedAtIso = '',
    this.lastError = '',
  });

  DespachoQueueTelemetryModel copyWith({
    int? enqueuedTotal,
    int? processedTotal,
    int? failedAttemptsTotal,
    int? retryAttemptsTotal,
    String? lastAttemptAtIso,
    String? lastProcessedAtIso,
    String? lastError,
  }) {
    return DespachoQueueTelemetryModel(
      enqueuedTotal: enqueuedTotal ?? this.enqueuedTotal,
      processedTotal: processedTotal ?? this.processedTotal,
      failedAttemptsTotal: failedAttemptsTotal ?? this.failedAttemptsTotal,
      retryAttemptsTotal: retryAttemptsTotal ?? this.retryAttemptsTotal,
      lastAttemptAtIso: lastAttemptAtIso ?? this.lastAttemptAtIso,
      lastProcessedAtIso: lastProcessedAtIso ?? this.lastProcessedAtIso,
      lastError: lastError ?? this.lastError,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enqueued_total': enqueuedTotal,
      'processed_total': processedTotal,
      'failed_attempts_total': failedAttemptsTotal,
      'retry_attempts_total': retryAttemptsTotal,
      'last_attempt_at_iso': lastAttemptAtIso,
      'last_processed_at_iso': lastProcessedAtIso,
      'last_error': lastError,
    };
  }

  factory DespachoQueueTelemetryModel.fromJson(Map<String, dynamic> map) {
    return DespachoQueueTelemetryModel(
      enqueuedTotal:
          int.tryParse((map['enqueued_total'] ?? '').toString()) ?? 0,
      processedTotal:
          int.tryParse((map['processed_total'] ?? '').toString()) ?? 0,
      failedAttemptsTotal:
          int.tryParse((map['failed_attempts_total'] ?? '').toString()) ?? 0,
      retryAttemptsTotal:
          int.tryParse((map['retry_attempts_total'] ?? '').toString()) ?? 0,
      lastAttemptAtIso: (map['last_attempt_at_iso'] ?? '').toString(),
      lastProcessedAtIso: (map['last_processed_at_iso'] ?? '').toString(),
      lastError: (map['last_error'] ?? '').toString(),
    );
  }
}

double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString().trim().replaceAll(',', '.')) ?? 0;
}
