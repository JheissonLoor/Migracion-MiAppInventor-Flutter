class AgregarProveedorQueueJobModel {
  final String id;
  final String proveedor;
  final String material;
  final String titulo;
  final String taraCono;
  final String taraBolsa;
  final String taraCaja;
  final String taraSaco;
  final String createdAtIso;
  final int attempts;

  const AgregarProveedorQueueJobModel({
    required this.id,
    required this.proveedor,
    required this.material,
    required this.titulo,
    required this.taraCono,
    required this.taraBolsa,
    required this.taraCaja,
    required this.taraSaco,
    required this.createdAtIso,
    this.attempts = 0,
  });

  AgregarProveedorQueueJobModel copyWith({
    String? id,
    String? proveedor,
    String? material,
    String? titulo,
    String? taraCono,
    String? taraBolsa,
    String? taraCaja,
    String? taraSaco,
    String? createdAtIso,
    int? attempts,
  }) {
    return AgregarProveedorQueueJobModel(
      id: id ?? this.id,
      proveedor: proveedor ?? this.proveedor,
      material: material ?? this.material,
      titulo: titulo ?? this.titulo,
      taraCono: taraCono ?? this.taraCono,
      taraBolsa: taraBolsa ?? this.taraBolsa,
      taraCaja: taraCaja ?? this.taraCaja,
      taraSaco: taraSaco ?? this.taraSaco,
      createdAtIso: createdAtIso ?? this.createdAtIso,
      attempts: attempts ?? this.attempts,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'proveedor': proveedor,
      'material': material,
      'titulo': titulo,
      'tara_cono': taraCono,
      'tara_bolsa': taraBolsa,
      'tara_caja': taraCaja,
      'tara_saco': taraSaco,
      'created_at_iso': createdAtIso,
      'attempts': attempts,
    };
  }

  factory AgregarProveedorQueueJobModel.fromJson(Map<String, dynamic> map) {
    return AgregarProveedorQueueJobModel(
      id: (map['id'] ?? '').toString(),
      proveedor: (map['proveedor'] ?? '').toString(),
      material: (map['material'] ?? '').toString(),
      titulo: (map['titulo'] ?? '').toString(),
      taraCono: (map['tara_cono'] ?? '').toString(),
      taraBolsa: (map['tara_bolsa'] ?? '').toString(),
      taraCaja: (map['tara_caja'] ?? '').toString(),
      taraSaco: (map['tara_saco'] ?? '').toString(),
      createdAtIso: (map['created_at_iso'] ?? '').toString(),
      attempts: int.tryParse((map['attempts'] ?? '').toString()) ?? 0,
    );
  }
}

class IngresoTelasQueueJobModel {
  final String id;
  final int qrCampos;
  final String codigoKardex;
  final String codigoPcp;
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
  final String almacen;
  final String ubicacion;
  final String servicio;
  final String nombre;
  final String createdAtIso;
  final int attempts;

  const IngresoTelasQueueJobModel({
    required this.id,
    required this.qrCampos,
    required this.codigoKardex,
    required this.codigoPcp,
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
    required this.almacen,
    required this.ubicacion,
    required this.servicio,
    required this.nombre,
    required this.createdAtIso,
    this.attempts = 0,
  });

  IngresoTelasQueueJobModel copyWith({
    String? id,
    int? qrCampos,
    String? codigoKardex,
    String? codigoPcp,
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
    String? almacen,
    String? ubicacion,
    String? servicio,
    String? nombre,
    String? createdAtIso,
    int? attempts,
  }) {
    return IngresoTelasQueueJobModel(
      id: id ?? this.id,
      qrCampos: qrCampos ?? this.qrCampos,
      codigoKardex: codigoKardex ?? this.codigoKardex,
      codigoPcp: codigoPcp ?? this.codigoPcp,
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
      almacen: almacen ?? this.almacen,
      ubicacion: ubicacion ?? this.ubicacion,
      servicio: servicio ?? this.servicio,
      nombre: nombre ?? this.nombre,
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
      'num_cajas': numCajas,
      'total_bobinas': totalBobinas,
      'cantidad_reenconado': cantidadReenconado,
      'peso_bruto': pesoBruto,
      'peso_neto': pesoNeto,
      'proveedor': proveedor,
      'fecha_ingreso': fechaIngreso,
      'almacen': almacen,
      'ubicacion': ubicacion,
      'servicio': servicio,
      'nombre': nombre,
      'created_at_iso': createdAtIso,
      'attempts': attempts,
    };
  }

  factory IngresoTelasQueueJobModel.fromJson(Map<String, dynamic> map) {
    return IngresoTelasQueueJobModel(
      id: (map['id'] ?? '').toString(),
      qrCampos: int.tryParse((map['qr_campos'] ?? '').toString()) ?? 0,
      codigoKardex: (map['codigo_kardex'] ?? '').toString(),
      codigoPcp: (map['codigo_pcp'] ?? '').toString(),
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
      almacen: (map['almacen'] ?? '').toString(),
      ubicacion: (map['ubicacion'] ?? '').toString(),
      servicio: (map['servicio'] ?? '').toString(),
      nombre: (map['nombre'] ?? '').toString(),
      createdAtIso: (map['created_at_iso'] ?? '').toString(),
      attempts: int.tryParse((map['attempts'] ?? '').toString()) ?? 0,
    );
  }
}

class ContenedorQueueJobModel {
  final String id;
  final int qrCampos;
  final String codigoHc;
  final String material;
  final String titulo;
  final String color;
  final String lote;
  final String numCajasMovidas;
  final String nroConos;
  final String pesoBruto;
  final String pesoNeto;
  final String totalBobinas;
  final String pesoBrutoTotal;
  final String pesoNetoTotal;
  final String proveedor;
  final String fechaIngreso;
  final String fechaSalida;
  final String nombreOperario;
  final String usuario;
  final String createdAtIso;
  final int attempts;

  const ContenedorQueueJobModel({
    required this.id,
    required this.qrCampos,
    required this.codigoHc,
    required this.material,
    required this.titulo,
    required this.color,
    required this.lote,
    required this.numCajasMovidas,
    required this.nroConos,
    required this.pesoBruto,
    required this.pesoNeto,
    required this.totalBobinas,
    required this.pesoBrutoTotal,
    required this.pesoNetoTotal,
    required this.proveedor,
    required this.fechaIngreso,
    required this.fechaSalida,
    required this.nombreOperario,
    required this.usuario,
    required this.createdAtIso,
    this.attempts = 0,
  });

  ContenedorQueueJobModel copyWith({
    String? id,
    int? qrCampos,
    String? codigoHc,
    String? material,
    String? titulo,
    String? color,
    String? lote,
    String? numCajasMovidas,
    String? nroConos,
    String? pesoBruto,
    String? pesoNeto,
    String? totalBobinas,
    String? pesoBrutoTotal,
    String? pesoNetoTotal,
    String? proveedor,
    String? fechaIngreso,
    String? fechaSalida,
    String? nombreOperario,
    String? usuario,
    String? createdAtIso,
    int? attempts,
  }) {
    return ContenedorQueueJobModel(
      id: id ?? this.id,
      qrCampos: qrCampos ?? this.qrCampos,
      codigoHc: codigoHc ?? this.codigoHc,
      material: material ?? this.material,
      titulo: titulo ?? this.titulo,
      color: color ?? this.color,
      lote: lote ?? this.lote,
      numCajasMovidas: numCajasMovidas ?? this.numCajasMovidas,
      nroConos: nroConos ?? this.nroConos,
      pesoBruto: pesoBruto ?? this.pesoBruto,
      pesoNeto: pesoNeto ?? this.pesoNeto,
      totalBobinas: totalBobinas ?? this.totalBobinas,
      pesoBrutoTotal: pesoBrutoTotal ?? this.pesoBrutoTotal,
      pesoNetoTotal: pesoNetoTotal ?? this.pesoNetoTotal,
      proveedor: proveedor ?? this.proveedor,
      fechaIngreso: fechaIngreso ?? this.fechaIngreso,
      fechaSalida: fechaSalida ?? this.fechaSalida,
      nombreOperario: nombreOperario ?? this.nombreOperario,
      usuario: usuario ?? this.usuario,
      createdAtIso: createdAtIso ?? this.createdAtIso,
      attempts: attempts ?? this.attempts,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'qr_campos': qrCampos,
      'codigo_hc': codigoHc,
      'material': material,
      'titulo': titulo,
      'color': color,
      'lote': lote,
      'num_cajas_movidas': numCajasMovidas,
      'nro_conos': nroConos,
      'peso_bruto': pesoBruto,
      'peso_neto': pesoNeto,
      'total_bobinas': totalBobinas,
      'peso_bruto_total': pesoBrutoTotal,
      'peso_neto_total': pesoNetoTotal,
      'proveedor': proveedor,
      'fecha_ingreso': fechaIngreso,
      'fecha_salida': fechaSalida,
      'nombre_operario': nombreOperario,
      'usuario': usuario,
      'created_at_iso': createdAtIso,
      'attempts': attempts,
    };
  }

  factory ContenedorQueueJobModel.fromJson(Map<String, dynamic> map) {
    return ContenedorQueueJobModel(
      id: (map['id'] ?? '').toString(),
      qrCampos: int.tryParse((map['qr_campos'] ?? '').toString()) ?? 0,
      codigoHc: (map['codigo_hc'] ?? '').toString(),
      material: (map['material'] ?? '').toString(),
      titulo: (map['titulo'] ?? '').toString(),
      color: (map['color'] ?? '').toString(),
      lote: (map['lote'] ?? '').toString(),
      numCajasMovidas: (map['num_cajas_movidas'] ?? '').toString(),
      nroConos: (map['nro_conos'] ?? '').toString(),
      pesoBruto: (map['peso_bruto'] ?? '').toString(),
      pesoNeto: (map['peso_neto'] ?? '').toString(),
      totalBobinas: (map['total_bobinas'] ?? '').toString(),
      pesoBrutoTotal: (map['peso_bruto_total'] ?? '').toString(),
      pesoNetoTotal: (map['peso_neto_total'] ?? '').toString(),
      proveedor: (map['proveedor'] ?? '').toString(),
      fechaIngreso: (map['fecha_ingreso'] ?? '').toString(),
      fechaSalida: (map['fecha_salida'] ?? '').toString(),
      nombreOperario: (map['nombre_operario'] ?? '').toString(),
      usuario: (map['usuario'] ?? '').toString(),
      createdAtIso: (map['created_at_iso'] ?? '').toString(),
      attempts: int.tryParse((map['attempts'] ?? '').toString()) ?? 0,
    );
  }
}
