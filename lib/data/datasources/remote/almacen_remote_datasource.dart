/// ============================================================================
/// DATASOURCE DE ALMACÉN - CoolImport S.A.C.
/// ============================================================================
/// Maneja las llamadas API relacionadas con almacén:
///   - /consulta_almacen (Consultar última ubicación por código PCP)
///   - /almacen_ubicacion (Obtener ubicación de almacén)
/// ============================================================================

import '../../../core/network/api_client.dart';
import '../../../core/contracts/api_contracts.dart';

/// Modelo de resultado de consulta de almacén
class AlmacenResult {
  final String codigoPcp;
  final String codigoKardex;
  final String planta;
  final String ubicacion;
  final String fecha;
  final String hora;
  final String operario;
  final String movimiento;
  final String material;
  final String titulo;

  AlmacenResult({
    required this.codigoPcp,
    this.codigoKardex = '',
    required this.planta,
    required this.ubicacion,
    required this.fecha,
    required this.hora,
    required this.operario,
    this.movimiento = '',
    this.material = '',
    this.titulo = '',
  });

  factory AlmacenResult.fromList(List<dynamic> data) {
    // El backend retorna una lista de campos en este orden:
    // [CodigoPCP, Planta, Ubicacion, Fecha, Hora, Operario]
    return AlmacenResult(
      codigoPcp: data.isNotEmpty ? data[0].toString() : '',
      planta: data.length > 1 ? data[1].toString() : '',
      ubicacion: data.length > 2 ? data[2].toString() : '',
      fecha: data.length > 3 ? data[3].toString() : '',
      hora: data.length > 4 ? data[4].toString() : '',
      operario: data.length > 5 ? data[5].toString() : '',
    );
  }
}

/// Modelo de resultado de historial
class HistorialItem {
  final String fecha;
  final String hora;
  final String codigoKardex;
  final String codigoPcp;
  final String almacen;
  final String ubicacion;
  final String movimiento;

  HistorialItem({
    required this.fecha,
    required this.hora,
    this.codigoKardex = '',
    required this.codigoPcp,
    required this.almacen,
    required this.ubicacion,
    required this.movimiento,
  });

  factory HistorialItem.fromList(List<dynamic> data) {
    // El backend retorna: [Fecha, Hora, CKardex, Codigo, Almacen, Ubicacion, Movimiento]
    return HistorialItem(
      fecha: data.isNotEmpty ? data[0].toString() : '',
      hora: data.length > 1 ? data[1].toString() : '',
      codigoKardex: data.length > 2 ? data[2].toString() : '',
      codigoPcp: data.length > 3 ? data[3].toString() : '',
      almacen: data.length > 4 ? data[4].toString() : '',
      ubicacion: data.length > 5 ? data[5].toString() : '',
      movimiento: data.length > 6 ? data[6].toString() : '',
    );
  }

  /// Color basado en tipo de movimiento
  bool get isSalida => movimiento.toUpperCase().contains('SALIDA');
  bool get isReingreso => movimiento.toUpperCase().contains('REINGRESO');
}

class AlmacenRemoteDatasource {
  final ApiClient _client;

  AlmacenRemoteDatasource(this._client);

  /// ════════════════════════════════════════
  /// CONSULTA ALMACÉN - Última ubicación
  /// ════════════════════════════════════════
  /// Endpoint: POST /consulta_almacen
  /// Body legacy (MIT): {"codigopcp": "PCP-XXXX"}
  /// Nota: enviamos ambas claves durante la migracion gradual.
  /// Response: {"data": [[CodigoPCP, Planta, Ubicacion, Fecha, Hora, Operario], ...]}
  Future<List<AlmacenResult>> consultarUbicacion(String codigoPcp) async {
    final response = await _client.post(
      ApiRoutes.consultaAlmacen,
      data: ApiPayloads.consultaAlmacen(codigoPcp: codigoPcp),
    );

    if (!response.success) {
      throw Exception(response.message ?? 'Error al consultar ubicación');
    }

    final responseData = response.responseData;
    if (responseData is List) {
      return responseData.map((item) {
        if (item is List) {
          return AlmacenResult.fromList(item);
        }
        return AlmacenResult(
          codigoPcp: codigoPcp,
          planta: '-',
          ubicacion: '-',
          fecha: '-',
          hora: '-',
          operario: '-',
        );
      }).toList();
    }

    throw Exception('No se encontraron resultados para este código');
  }

  /// ════════════════════════════════════════
  /// HISTORIAL DE MOVIMIENTOS
  /// ════════════════════════════════════════
  /// Endpoint: POST /consulta_historial
  /// Body legacy (MIT): {"nombre": "usuario", "filtro": "..."}
  /// Nota: enviamos ambas claves durante la migracion gradual.
  /// Response: {"data": [[Fecha, Hora, CKardex, Codigo, Almacen, Ubicacion, Movimiento], ...]}
  Future<List<HistorialItem>> consultarHistorial({
    required String usuario,
    required String filtro,
  }) async {
    final response = await _client.post(
      ApiRoutes.consultaHistorial,
      data: ApiPayloads.consultaHistorial(usuario: usuario, filtro: filtro),
    );

    if (!response.success) {
      throw Exception(response.message ?? 'Error al consultar historial');
    }

    final responseData = response.responseData;
    if (responseData is List) {
      return responseData.map((item) {
        if (item is List) {
          return HistorialItem.fromList(item);
        }
        return HistorialItem(
          fecha: '-',
          hora: '-',
          codigoPcp: '-',
          almacen: '-',
          ubicacion: '-',
          movimiento: filtro,
        );
      }).toList();
    }

    return [];
  }
}
