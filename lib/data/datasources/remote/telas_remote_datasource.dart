import '../../../core/contracts/api_contracts.dart';
import '../../../core/network/api_client.dart';

class RolloDespachoItem {
  final String codigo;
  final String articulo;
  final double metraje;
  final double peso;
  final String ubicacion;

  const RolloDespachoItem({
    required this.codigo,
    required this.articulo,
    required this.metraje,
    required this.peso,
    required this.ubicacion,
  });
}

class RegistroIngresoTelaResult {
  final String message;
  final String codigo;
  final String articulo;
  final double metraje;
  final double peso;
  final String ubicacion;

  const RegistroIngresoTelaResult({
    required this.message,
    required this.codigo,
    required this.articulo,
    required this.metraje,
    required this.peso,
    required this.ubicacion,
  });
}

class ImpresionDespachoResult {
  final String message;
  final String correlativo;
  final String impresora;
  final bool sheetsRegistrado;

  const ImpresionDespachoResult({
    required this.message,
    required this.correlativo,
    required this.impresora,
    required this.sheetsRegistrado,
  });
}

class TelasRemoteDatasource {
  final ApiClient _apiClient;
  final LocalApiClient _localApiClient;

  const TelasRemoteDatasource(this._apiClient, this._localApiClient);

  Future<bool> isLocalApiDisponible() => _localApiClient.isAvailable();

  Future<RegistroIngresoTelaResult> registrarIngresoTela({
    required String codigoQr,
    required String almacen,
    required String ubicacion,
    required String observaciones,
    required String usuario,
  }) async {
    final response = await _apiClient.post(
      ApiRoutes.registrarIngresoTela,
      data: ApiPayloads.registrarIngresoTela(
        codigoQr: codigoQr,
        almacen: almacen,
        ubicacion: ubicacion,
        observaciones: observaciones,
        usuario: usuario,
      ),
    );

    if (!response.success) {
      throw Exception(
        response.message ?? 'No se pudo registrar ingreso de tela',
      );
    }

    final map = response.data;
    if (map is! Map) {
      throw Exception('Respuesta invalida de /registrar_ingreso_tela');
    }

    final success = map['success'] == true;
    final message = (map['message'] ?? '').toString();
    if (!success) {
      throw Exception(
        message.isNotEmpty ? message : 'El backend rechazo el ingreso de tela',
      );
    }

    final data = map['data'];
    if (data is! Map) {
      throw Exception('No se recibieron datos del rollo registrado');
    }

    return RegistroIngresoTelaResult(
      message: message.isNotEmpty ? message : 'Ingreso registrado',
      codigo: (data['codigo'] ?? '').toString(),
      articulo: (data['articulo'] ?? '').toString(),
      metraje: _toDouble(data['metraje']),
      peso: _toDouble(data['peso']),
      ubicacion: (data['ubicacion'] ?? '').toString(),
    );
  }

  Future<RolloDespachoItem> validarRolloDespacho(String codigo) async {
    final response = await _apiClient.post(
      ApiRoutes.validarRolloDespacho,
      data: {'codigo': codigo.trim()},
    );

    if (!response.success) {
      throw Exception(response.message ?? 'No se pudo validar el rollo');
    }

    final map = response.data;
    if (map is! Map) {
      throw Exception('Respuesta invalida de /validar_rollo_despacho');
    }

    final success = map['success'] == true;
    final message = (map['message'] ?? '').toString();
    if (!success) {
      throw Exception(
        message.isNotEmpty ? message : 'Rollo no disponible para despacho',
      );
    }

    final data = map['data'];
    if (data is! Map) {
      throw Exception('No se recibieron datos del rollo validado');
    }

    return RolloDespachoItem(
      codigo: (data['codigo'] ?? '').toString(),
      articulo: (data['articulo'] ?? '').toString(),
      metraje: _toDouble(data['metraje']),
      peso: _toDouble(data['peso']),
      ubicacion: (data['ubicacion'] ?? '').toString(),
    );
  }

  Future<ImpresionDespachoResult> imprimirDespacho({
    required List<RolloDespachoItem> rollos,
    required String destino,
    required String guia,
    required String observaciones,
    required String usuario,
  }) async {
    final totalMetros = rollos.fold<double>(
      0,
      (sum, item) => sum + item.metraje,
    );
    final totalPeso = rollos.fold<double>(0, (sum, item) => sum + item.peso);

    final response = await _localApiClient.post(
      ApiRoutes.localImprimirDespacho,
      data: {
        'rollos':
            rollos
                .map(
                  (r) => {
                    'codigo': r.codigo,
                    'articulo': r.articulo,
                    'metraje': r.metraje,
                    'peso': r.peso,
                    'ubicacion': r.ubicacion,
                  },
                )
                .toList(),
        'destino': destino.trim(),
        'guia': guia.trim(),
        'observaciones': observaciones.trim(),
        'usuario': usuario.trim(),
        'total_metros': totalMetros,
        'total_peso': totalPeso,
      },
    );

    if (!response.success) {
      throw Exception(response.message ?? 'No se pudo imprimir el despacho');
    }

    final map = response.data;
    if (map is! Map) {
      throw Exception('Respuesta invalida de /imprimir_despacho');
    }

    final success = map['success'] == true;
    final message = (map['message'] ?? '').toString();
    if (!success) {
      throw Exception(
        message.isNotEmpty
            ? message
            : 'La API local no pudo completar despacho',
      );
    }

    final data = map['data'];
    if (data is! Map) {
      throw Exception('No se recibieron datos de impresion');
    }

    return ImpresionDespachoResult(
      message: message.isNotEmpty ? message : 'Despacho impreso',
      correlativo: (data['correlativo'] ?? '').toString(),
      impresora: (data['impresora'] ?? '').toString(),
      sheetsRegistrado: data['sheets_registrado'] == true,
    );
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '.')) ?? 0;
  }
}
