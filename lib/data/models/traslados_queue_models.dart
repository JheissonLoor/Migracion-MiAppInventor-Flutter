class CambioAlmacenQueueJobModel {
  final String id;
  final int qrCampos;
  final String numTelar;
  final String codigoTelas;
  final String ordenOperacion;
  final String articulo;
  final String numPlegador;
  final String metroCorte;
  final String pesoKg;
  final String fechaCorte;
  final String fechaRevisado;
  final String fechaSalida;
  final String horaSalida;
  final String servicio;
  final String almacen;
  final String ubicacion;
  final String usuario;
  final String createdAtIso;
  final int attempts;

  const CambioAlmacenQueueJobModel({
    required this.id,
    required this.qrCampos,
    required this.numTelar,
    required this.codigoTelas,
    required this.ordenOperacion,
    required this.articulo,
    required this.numPlegador,
    required this.metroCorte,
    required this.pesoKg,
    required this.fechaCorte,
    required this.fechaRevisado,
    required this.fechaSalida,
    required this.horaSalida,
    required this.servicio,
    required this.almacen,
    required this.ubicacion,
    required this.usuario,
    required this.createdAtIso,
    this.attempts = 0,
  });

  CambioAlmacenQueueJobModel copyWith({int? attempts}) {
    return CambioAlmacenQueueJobModel(
      id: id,
      qrCampos: qrCampos,
      numTelar: numTelar,
      codigoTelas: codigoTelas,
      ordenOperacion: ordenOperacion,
      articulo: articulo,
      numPlegador: numPlegador,
      metroCorte: metroCorte,
      pesoKg: pesoKg,
      fechaCorte: fechaCorte,
      fechaRevisado: fechaRevisado,
      fechaSalida: fechaSalida,
      horaSalida: horaSalida,
      servicio: servicio,
      almacen: almacen,
      ubicacion: ubicacion,
      usuario: usuario,
      createdAtIso: createdAtIso,
      attempts: attempts ?? this.attempts,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'qr_campos': qrCampos,
      'num_telar': numTelar,
      'codigo_telas': codigoTelas,
      'orden_operacion': ordenOperacion,
      'articulo': articulo,
      'num_plegador': numPlegador,
      'metro_corte': metroCorte,
      'peso_kg': pesoKg,
      'fecha_corte': fechaCorte,
      'fecha_revisado': fechaRevisado,
      'fecha_salida': fechaSalida,
      'hora_salida': horaSalida,
      'servicio': servicio,
      'almacen': almacen,
      'ubicacion': ubicacion,
      'usuario': usuario,
      'created_at_iso': createdAtIso,
      'attempts': attempts,
    };
  }

  factory CambioAlmacenQueueJobModel.fromJson(Map<String, dynamic> map) {
    return CambioAlmacenQueueJobModel(
      id: (map['id'] ?? '').toString(),
      qrCampos: int.tryParse((map['qr_campos'] ?? '').toString()) ?? 0,
      numTelar: (map['num_telar'] ?? '').toString(),
      codigoTelas: (map['codigo_telas'] ?? '').toString(),
      ordenOperacion: (map['orden_operacion'] ?? '').toString(),
      articulo: (map['articulo'] ?? '').toString(),
      numPlegador: (map['num_plegador'] ?? '').toString(),
      metroCorte: (map['metro_corte'] ?? '').toString(),
      pesoKg: (map['peso_kg'] ?? '').toString(),
      fechaCorte: (map['fecha_corte'] ?? '').toString(),
      fechaRevisado: (map['fecha_revisado'] ?? '').toString(),
      fechaSalida: (map['fecha_salida'] ?? '').toString(),
      horaSalida: (map['hora_salida'] ?? '').toString(),
      servicio: (map['servicio'] ?? '').toString(),
      almacen: (map['almacen'] ?? '').toString(),
      ubicacion: (map['ubicacion'] ?? '').toString(),
      usuario: (map['usuario'] ?? '').toString(),
      createdAtIso: (map['created_at_iso'] ?? '').toString(),
      attempts: int.tryParse((map['attempts'] ?? '').toString()) ?? 0,
    );
  }
}

class CambioUbicacionQueueJobModel {
  final String id;
  final int qrCampos;
  final String codigoKardex;
  final String codigoPcp;
  final String material;
  final String titulo;
  final String color;
  final String lote;
  final String numCaja;
  final String servicio;
  final String planta;
  final String ubicacion;
  final String telar;
  final String fechaSalida;
  final String horaSalida;
  final String movimiento;
  final String usuario;
  final String createdAtIso;
  final int attempts;

  const CambioUbicacionQueueJobModel({
    required this.id,
    required this.qrCampos,
    required this.codigoKardex,
    required this.codigoPcp,
    required this.material,
    required this.titulo,
    required this.color,
    required this.lote,
    required this.numCaja,
    required this.servicio,
    required this.planta,
    required this.ubicacion,
    required this.telar,
    required this.fechaSalida,
    required this.horaSalida,
    required this.movimiento,
    required this.usuario,
    required this.createdAtIso,
    this.attempts = 0,
  });

  CambioUbicacionQueueJobModel copyWith({int? attempts}) {
    return CambioUbicacionQueueJobModel(
      id: id,
      qrCampos: qrCampos,
      codigoKardex: codigoKardex,
      codigoPcp: codigoPcp,
      material: material,
      titulo: titulo,
      color: color,
      lote: lote,
      numCaja: numCaja,
      servicio: servicio,
      planta: planta,
      ubicacion: ubicacion,
      telar: telar,
      fechaSalida: fechaSalida,
      horaSalida: horaSalida,
      movimiento: movimiento,
      usuario: usuario,
      createdAtIso: createdAtIso,
      attempts: attempts ?? this.attempts,
    );
  }

  bool get hasKardex => codigoKardex.trim().isNotEmpty;

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
      'servicio': servicio,
      'planta': planta,
      'ubicacion': ubicacion,
      'telar': telar,
      'fecha_salida': fechaSalida,
      'hora_salida': horaSalida,
      'movimiento': movimiento,
      'usuario': usuario,
      'created_at_iso': createdAtIso,
      'attempts': attempts,
    };
  }

  factory CambioUbicacionQueueJobModel.fromJson(Map<String, dynamic> map) {
    return CambioUbicacionQueueJobModel(
      id: (map['id'] ?? '').toString(),
      qrCampos: int.tryParse((map['qr_campos'] ?? '').toString()) ?? 0,
      codigoKardex: (map['codigo_kardex'] ?? '').toString(),
      codigoPcp: (map['codigo_pcp'] ?? '').toString(),
      material: (map['material'] ?? '').toString(),
      titulo: (map['titulo'] ?? '').toString(),
      color: (map['color'] ?? '').toString(),
      lote: (map['lote'] ?? '').toString(),
      numCaja: (map['num_caja'] ?? '').toString(),
      servicio: (map['servicio'] ?? '').toString(),
      planta: (map['planta'] ?? '').toString(),
      ubicacion: (map['ubicacion'] ?? '').toString(),
      telar: (map['telar'] ?? '').toString(),
      fechaSalida: (map['fecha_salida'] ?? '').toString(),
      horaSalida: (map['hora_salida'] ?? '').toString(),
      movimiento: (map['movimiento'] ?? '').toString(),
      usuario: (map['usuario'] ?? '').toString(),
      createdAtIso: (map['created_at_iso'] ?? '').toString(),
      attempts: int.tryParse((map['attempts'] ?? '').toString()) ?? 0,
    );
  }
}
