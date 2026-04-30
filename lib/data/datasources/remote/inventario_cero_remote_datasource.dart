import '../../../core/contracts/api_contracts.dart';
import '../../../core/network/api_client.dart';

class VerificacionPcpResult {
  final bool existe;
  final String almacen;
  final String ubicacion;
  final int fila;

  const VerificacionPcpResult({
    required this.existe,
    this.almacen = '',
    this.ubicacion = '',
    this.fila = 0,
  });
}

class RegistroInventarioCeroResult {
  final String message;
  final String codigoPcp;
  final String almacen;
  final String ubicacion;

  const RegistroInventarioCeroResult({
    required this.message,
    required this.codigoPcp,
    required this.almacen,
    required this.ubicacion,
  });
}

class InventarioCeroRemoteDatasource {
  final ApiClient _client;

  const InventarioCeroRemoteDatasource(this._client);

  Future<VerificacionPcpResult> verificarPcp(String codigoPcp) async {
    final code = codigoPcp.trim();
    if (code.isEmpty) {
      throw Exception('Ingrese codigo PCP');
    }

    final endpoint =
        '${ApiRoutes.verificarPcpPrefix}/${Uri.encodeComponent(code)}';
    final response = await _client.get(endpoint);

    if (!response.success) {
      throw Exception(response.message ?? 'No se pudo verificar codigo PCP');
    }

    final data = response.data;
    if (data is! Map) {
      throw Exception('Respuesta inesperada de /api/verificar_pcp');
    }

    final exists = data['existe'] == true;
    return VerificacionPcpResult(
      existe: exists,
      almacen: (data['almacen'] ?? '').toString(),
      ubicacion: (data['ubicacion'] ?? '').toString(),
      fila: int.tryParse((data['fila'] ?? '').toString()) ?? 0,
    );
  }

  Future<RegistroInventarioCeroResult> registrarInventario({
    required String codigoPcp,
    required String material,
    required String titulo,
    required String color,
    required String cantidadBobinas,
    required String pesoBruto,
    required String pesoNeto,
    required String almacen,
    required String ubicacion,
    String codigoKardex = '',
    String lote = '',
    String caja = '',
    String cantidadReenconado = '',
    String proveedor = '',
    String fechaIngreso = '',
    String servicio = '',
    String guia = '',
    String responsable = '',
  }) async {
    final response = await _client.post(
      ApiRoutes.inventarioCero,
      data: ApiPayloads.inventarioCero(
        codigoPcp: codigoPcp,
        material: material,
        titulo: titulo,
        color: color,
        cantidadBobinas: cantidadBobinas,
        pesoBruto: pesoBruto,
        pesoNeto: pesoNeto,
        almacen: almacen,
        ubicacion: ubicacion,
        codigoKardex: codigoKardex,
        lote: lote,
        caja: caja,
        cantidadReenconado: cantidadReenconado,
        proveedor: proveedor,
        fechaIngreso: fechaIngreso,
        servicio: servicio,
        guia: guia,
        responsable: responsable,
      ),
    );

    if (!response.success) {
      throw Exception(
        response.message ?? 'No se pudo registrar inventario en backend',
      );
    }

    final data = response.data;
    if (data is! Map) {
      throw Exception('Respuesta inesperada de /api/inventario_cero');
    }

    final success = data['success'] == true;
    final message = (data['message'] ?? '').toString();
    if (!success) {
      throw Exception(
        message.isNotEmpty ? message : 'El backend rechazo el registro',
      );
    }

    final resultData = data['data'];
    if (resultData is! Map) {
      throw Exception('No se recibieron datos de registro creado');
    }

    return RegistroInventarioCeroResult(
      message: message.isNotEmpty ? message : 'Inventario registrado',
      codigoPcp: (resultData['codigo_pcp'] ?? '').toString(),
      almacen: (resultData['almacen'] ?? '').toString(),
      ubicacion: (resultData['ubicacion'] ?? '').toString(),
    );
  }
}
