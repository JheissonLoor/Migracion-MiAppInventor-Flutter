import 'package:dio/dio.dart';

import '../../../core/contracts/api_contracts.dart';
import '../../../core/network/api_client.dart';
import 'movimientos_remote_datasource.dart';

class TarasData {
  final double taraCono;
  final double taraBolsa;
  final double taraCaja;
  final double taraSaco;

  const TarasData({
    required this.taraCono,
    required this.taraBolsa,
    required this.taraCaja,
    required this.taraSaco,
  });
}

class ReingresoFormData {
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
  final String usuario;
  final String movimiento;

  const ReingresoFormData({
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
    required this.usuario,
    this.movimiento = 'REINGRESO',
  });
}

class ReingresoRemoteDatasource {
  static const String _reingresoFormUrl =
      'https://docs.google.com/forms/d/1ovCx7PUk4xQB-GaVEjKflae-4WSDm_LnROzB1_4wIHw/formResponse';

  final ApiClient _client;
  final Dio _formsDio;

  ReingresoRemoteDatasource(this._client)
      : _formsDio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 18),
            followRedirects: true,
            validateStatus: (code) => code != null && code < 500,
          ),
        );

  Future<ValidacionMovimientoData> validarMovimiento({
    required String codigoPcp,
    required String nuevaUbicacion,
    required String usuario,
  }) async {
    final response = await _client.post(
      ApiRoutes.movimientoRestringido,
      data: ApiPayloads.movimientoRestringido(
        codigoPcp: codigoPcp,
        nuevaUbicacion: nuevaUbicacion,
        usuario: usuario,
      ),
    );

    if (!response.success) {
      throw Exception(
        response.message ?? 'No se pudo validar el movimiento de reingreso',
      );
    }

    final dynamic data = response.data;
    if (data is Map) {
      final result = (data['result'] ?? '').toString().trim();
      final message = (data['message'] ?? '').toString().trim();
      final error = (data['error'] ?? '').toString().trim();
      final permitido = result.toLowerCase() == 'movimiento aceptado';
      final mensaje = permitido
          ? (result.isNotEmpty ? result : 'Movimiento aceptado')
          : (message.isNotEmpty
              ? message
              : (error.isNotEmpty ? error : 'Movimiento no permitido'));
      return ValidacionMovimientoData(permitido: permitido, mensaje: mensaje);
    }

    throw Exception('Respuesta inesperada en /movimiento_restringido');
  }

  Future<TarasData> obtenerTaras({
    required String material,
    required String titulo,
    required String proveedor,
  }) async {
    final response = await _client.post(
      ApiRoutes.datosTara,
      data: ApiPayloads.datosTara(
        material: material,
        titulo: titulo,
        proveedor: proveedor,
      ),
    );

    if (!response.success) {
      throw Exception(response.message ?? 'No se pudieron obtener taras');
    }

    final dynamic data = response.responseData;
    if (data is Map) {
      return TarasData(
        taraCono: _toDouble(data['tara_cono']),
        taraBolsa: _toDouble(data['tara_bolsa']),
        taraCaja: _toDouble(data['tara_caja']),
        taraSaco: _toDouble(data['tara_saco']),
      );
    }

    throw Exception('Respuesta inesperada de /datos_tara');
  }

  Future<String> enviarFormularioReingreso(ReingresoFormData form) async {
    final params = _buildFormParams(form);
    final uri = Uri.parse(_reingresoFormUrl).replace(queryParameters: params);

    final response = await _formsDio.getUri(uri);
    if ((response.statusCode ?? 500) >= 400) {
      throw Exception('Google Forms rechazo el envio de reingreso');
    }

    return 'Reingreso enviado a Google Forms';
  }

  Map<String, String> _buildFormParams(ReingresoFormData form) {
    final base = <String, String>{
      'entry.81536486': form.codigoPcp.trim(),
      'entry.1294481590': form.material.trim(),
      'entry.1029336806': form.titulo.trim(),
      'entry.2001504827': form.color.trim(),
      'entry.1080026134': form.lote.trim(),
      'entry.1945792120': form.numCajas.trim(),
      'entry.1872168605': form.totalBobinas.trim(),
      'entry.1559869126': form.cantidadReenconado.trim(),
      'entry.1105632174': form.pesoBruto.trim(),
      'entry.1428486631': form.pesoNeto.trim(),
      'entry.892000776': form.proveedor.trim(),
      'entry.350773918': form.fechaIngreso.trim(),
      'entry.783733620': form.fechaSalida.trim(),
      'entry.333226211': form.horaSalida.trim(),
      'entry.2056541820': form.usuario.trim(),
      'entry.1454195270': form.movimiento.trim(),
    };

    if (form.codigoKardex.trim().isNotEmpty) {
      base['entry.104398647'] = form.codigoKardex.trim();
    }
    if (form.servicio.trim().isNotEmpty) {
      base['entry.1099161999'] = form.servicio.trim();
    }

    return base;
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '.')) ?? 0;
  }
}
