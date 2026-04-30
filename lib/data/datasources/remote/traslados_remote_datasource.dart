import 'package:dio/dio.dart';

import '../../../core/contracts/api_contracts.dart';
import '../../../core/network/api_client.dart';
import 'movimientos_remote_datasource.dart';

class CambioAlmacenFormData {
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
  final String almacen;
  final String ubicacion;
  final String fechaSalida;
  final String horaSalida;
  final String servicio;

  const CambioAlmacenFormData({
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
    required this.almacen,
    required this.ubicacion,
    required this.fechaSalida,
    required this.horaSalida,
    required this.servicio,
  });
}

class CambioUbicacionFormData {
  final int qrCampos;
  final String codigoKardex;
  final String codigoPcp;
  final String planta;
  final String ubicacion;
  final String fechaSalida;
  final String horaSalida;
  final String servicio;
  final String usuario;
  final String telar;
  final String movimiento;

  const CambioUbicacionFormData({
    required this.qrCampos,
    required this.codigoKardex,
    required this.codigoPcp,
    required this.planta,
    required this.ubicacion,
    required this.fechaSalida,
    required this.horaSalida,
    required this.servicio,
    required this.usuario,
    required this.telar,
    this.movimiento = 'SALIDA',
  });
}

class TrasladosRemoteDatasource {
  static const String _cambioAlmacenFormUrl =
      'https://docs.google.com/forms/d/1WWOfGakxK78SgO62zvik7jW0weICIujEqLmNiN4SJSY/formResponse';
  static const String _cambioUbicacionFormUrl =
      'https://docs.google.com/forms/d/1CxNbTYCOyCdFycphugHReoijXm2ATdvB7rE2Pr0UUdE/formResponse';

  final ApiClient _client;
  final Dio _formsDio;

  TrasladosRemoteDatasource(this._client)
    : _formsDio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 18),
          followRedirects: true,
          validateStatus: (code) => code != null && code < 500,
        ),
      );

  Future<String> enviarCambioAlmacen(CambioAlmacenFormData form) async {
    final params = _buildCambioAlmacenParams(form);
    final uri = Uri.parse(
      _cambioAlmacenFormUrl,
    ).replace(queryParameters: params);

    final response = await _formsDio.getUri(uri);
    if ((response.statusCode ?? 500) >= 400) {
      throw Exception('Google Forms rechazo cambio de almacen');
    }

    return 'Cambio de almacen enviado correctamente';
  }

  Future<String> enviarCambioUbicacion(CambioUbicacionFormData form) async {
    final params = _buildCambioUbicacionParams(form);
    final uri = Uri.parse(
      _cambioUbicacionFormUrl,
    ).replace(queryParameters: params);

    final response = await _formsDio.getUri(uri);
    if ((response.statusCode ?? 500) >= 400) {
      throw Exception('Google Forms rechazo cambio de ubicacion');
    }

    return 'Cambio de ubicacion enviado correctamente';
  }

  Future<UbicacionAlmacenData> consultarUltimaUbicacion(
    String codigoPcp,
  ) async {
    final cleanCode = codigoPcp.trim();
    if (cleanCode.isEmpty) {
      throw Exception('Debe ingresar codigo PCP para consultar ubicacion');
    }

    final response = await _client.post(
      ApiRoutes.almacenUbicacion,
      data: ApiPayloads.almacenUbicacion(cleanCode),
    );

    if (!response.success) {
      throw Exception(
        response.message ?? 'No se pudo consultar ultima ubicacion',
      );
    }

    dynamic data = response.responseData;
    if (data is List && data.isNotEmpty && data.first is Map) {
      data = data.first;
    }

    if (data is Map) {
      final almacen = (data['Almacen'] ?? data['almacen'] ?? '').toString();
      final ubicacion =
          (data['Ubicacion'] ?? data['ubicacion'] ?? '').toString();
      return UbicacionAlmacenData(
        almacen: almacen.trim(),
        ubicacion: ubicacion.trim(),
      );
    }

    throw Exception('Respuesta inesperada de /almacen_ubicacion');
  }

  Map<String, String> _buildCambioAlmacenParams(CambioAlmacenFormData form) {
    final params = <String, String>{
      'entry.1287672487': form.numTelar.trim(),
      'entry.170864125': form.codigoTelas.trim(),
      'entry.641541708': form.ordenOperacion.trim(),
      'entry.431468071': form.articulo.trim(),
      'entry.402627413': form.numPlegador.trim(),
      'entry.1044873844': form.metroCorte.trim(),
      'entry.152425249': form.pesoKg.trim(),
      'entry.959910349': form.fechaCorte.trim(),
      'entry.1713198428': form.fechaRevisado.trim(),
      'entry.739013893': form.almacen.trim(),
      'entry.1736321845': form.ubicacion.trim(),
    };

    if (form.qrCampos == 16) {
      // Replica el comportamiento legacy de Screen5 para 16 campos.
      params['entry.1733316970'] = form.servicio.trim();
      params['entry.2110610078'] = form.servicio.trim();
      params['entry.1880539811'] = form.servicio.trim();
    } else {
      params['entry.1733316970'] = form.fechaRevisado.trim();
      params['entry.2110610078'] = form.horaSalida.trim();
      params['entry.1880539811'] = form.servicio.trim();
    }

    return params;
  }

  Map<String, String> _buildCambioUbicacionParams(
    CambioUbicacionFormData form,
  ) {
    final hasKardex = form.codigoKardex.trim().isNotEmpty;

    if (!hasKardex) {
      return {
        'entry.1083098882': form.codigoPcp.trim(),
        'entry.620416969': form.planta.trim(),
        'entry.1624934217': form.ubicacion.trim(),
        'entry.591236589': form.fechaSalida.trim(),
        'entry.441717960': form.horaSalida.trim(),
        'entry.1117527060': form.usuario.trim(),
        'entry.256331314': form.telar.trim(),
        'entry.2082052035': form.movimiento.trim(),
      };
    }

    return {
      'entry.40194284': form.codigoKardex.trim(),
      'entry.1083098882': form.codigoPcp.trim(),
      'entry.620416969': form.planta.trim(),
      'entry.1624934217': form.ubicacion.trim(),
      'entry.591236589': form.fechaSalida.trim(),
      'entry.441717960': form.horaSalida.trim(),
      'entry.996256703': form.servicio.trim(),
      'entry.1117527060': form.usuario.trim(),
      'entry.256331314': form.telar.trim(),
      'entry.2082052035': form.movimiento.trim(),
    };
  }
}
