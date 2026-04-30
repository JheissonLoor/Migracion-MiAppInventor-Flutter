class QueueTelemetryModel {
  final int enqueuedTotal;
  final int processedTotal;
  final int failedAttemptsTotal;
  final int retryAttemptsTotal;
  final String lastAttemptAtIso;
  final String lastProcessedAtIso;
  final String lastError;

  const QueueTelemetryModel({
    this.enqueuedTotal = 0,
    this.processedTotal = 0,
    this.failedAttemptsTotal = 0,
    this.retryAttemptsTotal = 0,
    this.lastAttemptAtIso = '',
    this.lastProcessedAtIso = '',
    this.lastError = '',
  });

  QueueTelemetryModel copyWith({
    int? enqueuedTotal,
    int? processedTotal,
    int? failedAttemptsTotal,
    int? retryAttemptsTotal,
    String? lastAttemptAtIso,
    String? lastProcessedAtIso,
    String? lastError,
  }) {
    return QueueTelemetryModel(
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

  factory QueueTelemetryModel.fromJson(Map<String, dynamic> map) {
    return QueueTelemetryModel(
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

class SalidaQueueJobModel {
  final String id;
  final int qrCampos;
  final String codigoKardex;
  final String codigoPcp;
  final String material;
  final String titulo;
  final String color;
  final String lote;
  final String numCaja;
  final String planta;
  final String nuevaUbicacion;
  final String ubicacionPayload;
  final String destinoVenta;
  final String destinoCliente;
  final String fechaSalida;
  final String horaSalida;
  final String servicio;
  final String movimiento;
  final String telar;
  final String numeroGuia;
  final String ordenCompra;
  final String numCajas;
  final String totalBobinas;
  final String pesoBrutoTotal;
  final String pesoNetoTotal;
  final String usuario;
  final String createdAtIso;
  final int attempts;

  const SalidaQueueJobModel({
    required this.id,
    this.qrCampos = 0,
    this.codigoKardex = '',
    required this.codigoPcp,
    this.material = '',
    this.titulo = '',
    this.color = '',
    this.lote = '',
    this.numCaja = '',
    this.planta = '',
    required this.nuevaUbicacion,
    this.ubicacionPayload = '',
    this.destinoVenta = '',
    this.destinoCliente = '',
    this.fechaSalida = '',
    this.horaSalida = '',
    this.servicio = '',
    this.movimiento = 'SALIDA',
    this.telar = '',
    this.numeroGuia = '',
    this.ordenCompra = '',
    required this.numCajas,
    required this.totalBobinas,
    required this.pesoBrutoTotal,
    required this.pesoNetoTotal,
    required this.usuario,
    required this.createdAtIso,
    this.attempts = 0,
  });

  SalidaQueueJobModel copyWith({
    String? id,
    int? qrCampos,
    String? codigoKardex,
    String? codigoPcp,
    String? material,
    String? titulo,
    String? color,
    String? lote,
    String? numCaja,
    String? planta,
    String? nuevaUbicacion,
    String? ubicacionPayload,
    String? destinoVenta,
    String? destinoCliente,
    String? fechaSalida,
    String? horaSalida,
    String? servicio,
    String? movimiento,
    String? telar,
    String? numeroGuia,
    String? ordenCompra,
    String? numCajas,
    String? totalBobinas,
    String? pesoBrutoTotal,
    String? pesoNetoTotal,
    String? usuario,
    String? createdAtIso,
    int? attempts,
  }) {
    return SalidaQueueJobModel(
      id: id ?? this.id,
      qrCampos: qrCampos ?? this.qrCampos,
      codigoKardex: codigoKardex ?? this.codigoKardex,
      codigoPcp: codigoPcp ?? this.codigoPcp,
      material: material ?? this.material,
      titulo: titulo ?? this.titulo,
      color: color ?? this.color,
      lote: lote ?? this.lote,
      numCaja: numCaja ?? this.numCaja,
      planta: planta ?? this.planta,
      nuevaUbicacion: nuevaUbicacion ?? this.nuevaUbicacion,
      ubicacionPayload: ubicacionPayload ?? this.ubicacionPayload,
      destinoVenta: destinoVenta ?? this.destinoVenta,
      destinoCliente: destinoCliente ?? this.destinoCliente,
      fechaSalida: fechaSalida ?? this.fechaSalida,
      horaSalida: horaSalida ?? this.horaSalida,
      servicio: servicio ?? this.servicio,
      movimiento: movimiento ?? this.movimiento,
      telar: telar ?? this.telar,
      numeroGuia: numeroGuia ?? this.numeroGuia,
      ordenCompra: ordenCompra ?? this.ordenCompra,
      numCajas: numCajas ?? this.numCajas,
      totalBobinas: totalBobinas ?? this.totalBobinas,
      pesoBrutoTotal: pesoBrutoTotal ?? this.pesoBrutoTotal,
      pesoNetoTotal: pesoNetoTotal ?? this.pesoNetoTotal,
      usuario: usuario ?? this.usuario,
      createdAtIso: createdAtIso ?? this.createdAtIso,
      attempts: attempts ?? this.attempts,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'qr_campos': qrCampos,
      'codigo_kardex': codigoKardex,
      'codigo_pcp': codigoPcp,
      'material': material,
      'titulo': titulo,
      'color': color,
      'lote': lote,
      'num_caja': numCaja,
      'planta': planta,
      'nueva_ubicacion': nuevaUbicacion,
      'ubicacion_payload': ubicacionPayload,
      'destino_venta': destinoVenta,
      'destino_cliente': destinoCliente,
      'fecha_salida': fechaSalida,
      'hora_salida': horaSalida,
      'servicio': servicio,
      'movimiento': movimiento,
      'telar': telar,
      'numero_guia': numeroGuia,
      'orden_compra': ordenCompra,
      'num_cajas': numCajas,
      'total_bobinas': totalBobinas,
      'peso_bruto_total': pesoBrutoTotal,
      'peso_neto_total': pesoNetoTotal,
      'usuario': usuario,
      'created_at_iso': createdAtIso,
      'attempts': attempts,
    };
  }

  factory SalidaQueueJobModel.fromJson(Map<String, dynamic> map) {
    final codigoKardex = (map['codigo_kardex'] ?? '').toString();
    final qrCamposRaw = int.tryParse((map['qr_campos'] ?? '').toString()) ?? 0;
    final qrCampos =
        qrCamposRaw > 0
            ? qrCamposRaw
            : (codigoKardex.trim().isNotEmpty
                ? 16
                : ((map['num_caja'] ?? '').toString().trim().isNotEmpty
                    ? 14
                    : 0));

    return SalidaQueueJobModel(
      id: (map['id'] ?? '').toString(),
      qrCampos: qrCampos,
      codigoKardex: codigoKardex,
      codigoPcp: (map['codigo_pcp'] ?? '').toString(),
      material: (map['material'] ?? '').toString(),
      titulo: (map['titulo'] ?? '').toString(),
      color: (map['color'] ?? '').toString(),
      lote: (map['lote'] ?? '').toString(),
      numCaja: (map['num_caja'] ?? map['num_cajas'] ?? '').toString(),
      planta: (map['planta'] ?? '').toString(),
      nuevaUbicacion: (map['nueva_ubicacion'] ?? '').toString(),
      ubicacionPayload:
          (map['ubicacion_payload'] ?? map['nueva_ubicacion'] ?? '').toString(),
      destinoVenta: (map['destino_venta'] ?? '').toString(),
      destinoCliente: (map['destino_cliente'] ?? '').toString(),
      fechaSalida: (map['fecha_salida'] ?? '').toString(),
      horaSalida: (map['hora_salida'] ?? '').toString(),
      servicio: (map['servicio'] ?? '').toString(),
      movimiento: (map['movimiento'] ?? 'SALIDA').toString(),
      telar: (map['telar'] ?? '').toString(),
      numeroGuia:
          (map['numero_guia'] ?? map['guia'] ?? map['guia_box'] ?? '')
              .toString(),
      ordenCompra:
          (map['orden_compra'] ?? map['oc'] ?? map['oc_box'] ?? '').toString(),
      numCajas: (map['num_cajas'] ?? '').toString(),
      totalBobinas: (map['total_bobinas'] ?? '').toString(),
      pesoBrutoTotal: (map['peso_bruto_total'] ?? '').toString(),
      pesoNetoTotal: (map['peso_neto_total'] ?? '').toString(),
      usuario: (map['usuario'] ?? '').toString(),
      createdAtIso: (map['created_at_iso'] ?? '').toString(),
      attempts: int.tryParse((map['attempts'] ?? '').toString()) ?? 0,
    );
  }
}

class ReingresoQueueJobModel {
  final String id;
  final String nuevaUbicacion;
  final String usuario;
  final String createdAtIso;
  final int attempts;

  // Campos de formulario legacy Google Forms
  final String codigoPcp;
  final String codigoKardex;
  final String material;
  final String titulo;
  final String color;
  final String lote;
  final String numCajas;
  final String totalBobinas;
  final String cantidadReenconado;
  final String pesoBruto;
  final String pesoNeto;
  final String proveedor;
  final String fechaIngreso;
  final String fechaSalida;
  final String horaSalida;
  final String servicio;
  final String movimiento;

  const ReingresoQueueJobModel({
    required this.id,
    required this.nuevaUbicacion,
    required this.usuario,
    required this.createdAtIso,
    this.attempts = 0,
    required this.codigoPcp,
    required this.codigoKardex,
    required this.material,
    required this.titulo,
    required this.color,
    required this.lote,
    required this.numCajas,
    required this.totalBobinas,
    required this.cantidadReenconado,
    required this.pesoBruto,
    required this.pesoNeto,
    required this.proveedor,
    required this.fechaIngreso,
    required this.fechaSalida,
    required this.horaSalida,
    required this.servicio,
    required this.movimiento,
  });

  ReingresoQueueJobModel copyWith({
    String? id,
    String? nuevaUbicacion,
    String? usuario,
    String? createdAtIso,
    int? attempts,
    String? codigoPcp,
    String? codigoKardex,
    String? material,
    String? titulo,
    String? color,
    String? lote,
    String? numCajas,
    String? totalBobinas,
    String? cantidadReenconado,
    String? pesoBruto,
    String? pesoNeto,
    String? proveedor,
    String? fechaIngreso,
    String? fechaSalida,
    String? horaSalida,
    String? servicio,
    String? movimiento,
  }) {
    return ReingresoQueueJobModel(
      id: id ?? this.id,
      nuevaUbicacion: nuevaUbicacion ?? this.nuevaUbicacion,
      usuario: usuario ?? this.usuario,
      createdAtIso: createdAtIso ?? this.createdAtIso,
      attempts: attempts ?? this.attempts,
      codigoPcp: codigoPcp ?? this.codigoPcp,
      codigoKardex: codigoKardex ?? this.codigoKardex,
      material: material ?? this.material,
      titulo: titulo ?? this.titulo,
      color: color ?? this.color,
      lote: lote ?? this.lote,
      numCajas: numCajas ?? this.numCajas,
      totalBobinas: totalBobinas ?? this.totalBobinas,
      cantidadReenconado: cantidadReenconado ?? this.cantidadReenconado,
      pesoBruto: pesoBruto ?? this.pesoBruto,
      pesoNeto: pesoNeto ?? this.pesoNeto,
      proveedor: proveedor ?? this.proveedor,
      fechaIngreso: fechaIngreso ?? this.fechaIngreso,
      fechaSalida: fechaSalida ?? this.fechaSalida,
      horaSalida: horaSalida ?? this.horaSalida,
      servicio: servicio ?? this.servicio,
      movimiento: movimiento ?? this.movimiento,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nueva_ubicacion': nuevaUbicacion,
      'usuario': usuario,
      'created_at_iso': createdAtIso,
      'attempts': attempts,
      'codigo_pcp': codigoPcp,
      'codigo_kardex': codigoKardex,
      'material': material,
      'titulo': titulo,
      'color': color,
      'lote': lote,
      'num_cajas': numCajas,
      'total_bobinas': totalBobinas,
      'cantidad_reenconado': cantidadReenconado,
      'peso_bruto': pesoBruto,
      'peso_neto': pesoNeto,
      'proveedor': proveedor,
      'fecha_ingreso': fechaIngreso,
      'fecha_salida': fechaSalida,
      'hora_salida': horaSalida,
      'servicio': servicio,
      'movimiento': movimiento,
    };
  }

  factory ReingresoQueueJobModel.fromJson(Map<String, dynamic> map) {
    return ReingresoQueueJobModel(
      id: (map['id'] ?? '').toString(),
      nuevaUbicacion: (map['nueva_ubicacion'] ?? '').toString(),
      usuario: (map['usuario'] ?? '').toString(),
      createdAtIso: (map['created_at_iso'] ?? '').toString(),
      attempts: int.tryParse((map['attempts'] ?? '').toString()) ?? 0,
      codigoPcp: (map['codigo_pcp'] ?? '').toString(),
      codigoKardex: (map['codigo_kardex'] ?? '').toString(),
      material: (map['material'] ?? '').toString(),
      titulo: (map['titulo'] ?? '').toString(),
      color: (map['color'] ?? '').toString(),
      lote: (map['lote'] ?? '').toString(),
      numCajas: (map['num_cajas'] ?? '').toString(),
      totalBobinas: (map['total_bobinas'] ?? '').toString(),
      cantidadReenconado: (map['cantidad_reenconado'] ?? '').toString(),
      pesoBruto: (map['peso_bruto'] ?? '').toString(),
      pesoNeto: (map['peso_neto'] ?? '').toString(),
      proveedor: (map['proveedor'] ?? '').toString(),
      fechaIngreso: (map['fecha_ingreso'] ?? '').toString(),
      fechaSalida: (map['fecha_salida'] ?? '').toString(),
      horaSalida: (map['hora_salida'] ?? '').toString(),
      servicio: (map['servicio'] ?? '').toString(),
      movimiento: (map['movimiento'] ?? '').toString(),
    );
  }
}
