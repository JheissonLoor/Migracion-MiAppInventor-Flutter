import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:gsheets/gsheets.dart';

import '../../../core/config/environment.dart';
import '../../../core/contracts/api_contracts.dart';
import '../../../core/network/api_client.dart';

class UbicacionAlmacenData {
  final String almacen;
  final String ubicacion;

  const UbicacionAlmacenData({required this.almacen, required this.ubicacion});
}

class ValidacionMovimientoData {
  final bool permitido;
  final String mensaje;

  const ValidacionMovimientoData({
    required this.permitido,
    required this.mensaje,
  });
}

class ResumenSalidaData {
  final String mensaje;

  const ResumenSalidaData(this.mensaje);
}

class SalidaCatalogosData {
  final List<String> destinosVenta;
  final List<String> destinosCliente;

  const SalidaCatalogosData({
    required this.destinosVenta,
    required this.destinosCliente,
  });
}

class SalidaLegacyFormData {
  final int qrCampos;
  final String codigoKardex;
  final String codigoPcp;
  final String planta;
  final String ubicacion;
  final String fechaSalida;
  final String horaSalida;
  final String servicio;
  final String usuario;
  final String movimiento;
  final String lote;
  final String telar;
  final String numeroGuia;
  final String ordenCompra;
  final String pesoNeto;

  const SalidaLegacyFormData({
    required this.qrCampos,
    required this.codigoKardex,
    required this.codigoPcp,
    required this.planta,
    required this.ubicacion,
    required this.fechaSalida,
    required this.horaSalida,
    required this.servicio,
    required this.usuario,
    required this.movimiento,
    required this.lote,
    required this.telar,
    required this.numeroGuia,
    required this.ordenCompra,
    required this.pesoNeto,
  });
}

class MovimientosRemoteDatasource {
  static const String _salidaFormUrl =
      'https://docs.google.com/forms/d/1CxNbTYCOyCdFycphugHReoijXm2ATdvB7rE2Pr0UUdE/formResponse';
  static const String _salidaSpreadsheetId =
      '1_BRF7YyRkkT6f6qwioliJ07nYz_KLMaJko8brQHkTZM';
  static const String _salidaWorksheet = 'datosKardex';
  static const String _salidaWorksheetGid = '1227674840';
  static const int _colDestinoVenta = 13;
  static const int _colDestinoCliente = 14;

  final ApiClient _client;
  final Dio _formsDio;

  MovimientosRemoteDatasource(this._client)
    : _formsDio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 18),
          followRedirects: true,
          validateStatus: (code) => code != null && code < 500,
        ),
      );

  Future<SalidaCatalogosData> obtenerCatalogosSalida() async {
    SalidaCatalogosData? backendData;
    Object? backendError;

    try {
      backendData = await _obtenerCatalogosDesdeBackendReadColumn();
      if (_esCatalogoRobusto(backendData)) {
        return backendData;
      }
    } catch (error) {
      backendError = error;
    }

    SalidaCatalogosData? sheetsData;
    Object? sheetsError;

    try {
      sheetsData = await _obtenerCatalogosDesdeGSheets();
      if (_esCatalogoRobusto(sheetsData)) {
        return sheetsData;
      }
    } catch (error) {
      sheetsError = error;
    }

    try {
      final csvData = await _obtenerCatalogosDesdeCsvExport();
      if (_esCatalogoRobusto(csvData)) {
        return csvData;
      }
      if (sheetsData != null) {
        return _mergeCatalogosPreferRobusto(
          primary: sheetsData,
          fallback: csvData,
        );
      }
      if (backendData != null) {
        return _mergeCatalogosPreferRobusto(
          primary: backendData,
          fallback: csvData,
        );
      }
      return csvData;
    } catch (csvError) {
      if (backendData != null && _esCatalogoRobusto(backendData)) {
        return backendData;
      }
      if (sheetsData != null) {
        return sheetsData;
      }
      if (backendData != null) {
        return backendData;
      }
      if (sheetsError != null) {
        throw Exception(
          'No se pudieron cargar catalogos (backend: '
          '${_shortError(backendError ?? 'sin intento')} | gsheets: '
          '${_shortError(sheetsError)} | csv: ${_shortError(csvError)})',
        );
      }
      if (backendError != null) {
        throw Exception(
          'No se pudieron cargar catalogos (backend: '
          '${_shortError(backendError)} | csv: ${_shortError(csvError)})',
        );
      }
      rethrow;
    }
  }

  Future<UbicacionAlmacenData> obtenerUltimaUbicacion(String codigoPcp) async {
    final codigo = codigoPcp.trim();
    if (codigo.isEmpty) {
      throw Exception('Debe ingresar un codigo PCP');
    }

    final response = await _client.post(
      ApiRoutes.almacenUbicacion,
      data: ApiPayloads.almacenUbicacion(codigo),
    );

    if (!response.success) {
      throw Exception(
        response.message ?? 'No se pudo consultar la ubicacion del codigo',
      );
    }

    final dynamic data = response.responseData;
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

  Future<ValidacionMovimientoData> validarMovimientoSalida({
    required String codigoPcp,
    required String nuevaUbicacion,
    required String usuario,
  }) async {
    final response = await _client.post(
      ApiRoutes.movimientoRestringidoSalida,
      data: ApiPayloads.movimientoRestringido(
        codigoPcp: codigoPcp,
        nuevaUbicacion: nuevaUbicacion,
        usuario: usuario,
      ),
    );

    if (!response.success) {
      throw Exception(
        response.message ?? 'No se pudo validar la restriccion de movimiento',
      );
    }

    final dynamic data = response.data;
    if (data is Map) {
      final result = (data['result'] ?? '').toString().trim();
      final message = (data['message'] ?? '').toString().trim();
      final error = (data['error'] ?? '').toString().trim();

      final permitido = result.toLowerCase() == 'movimiento aceptado';
      final mensaje =
          permitido
              ? (result.isNotEmpty ? result : 'Movimiento aceptado')
              : (message.isNotEmpty
                  ? message
                  : (error.isNotEmpty ? error : 'Movimiento no permitido'));

      return ValidacionMovimientoData(permitido: permitido, mensaje: mensaje);
    }

    throw Exception('Respuesta inesperada en validacion de movimiento');
  }

  Future<ResumenSalidaData> actualizarStockSalida({
    required String codigoPcp,
    required double numCajas,
    required double totalBobinas,
    required double pesoBrutoTotal,
    required double pesoNetoTotal,
    required String usuario,
  }) async {
    final response = await _client.post(
      ApiRoutes.actualizarDatos,
      data: ApiPayloads.actualizarDatos(
        codigoPcp: codigoPcp,
        numCajas: numCajas,
        totalBobinas: totalBobinas,
        pesoBrutoTotal: pesoBrutoTotal,
        pesoNetoTotal: pesoNetoTotal,
        usuario: usuario,
      ),
    );

    if (!response.success) {
      throw Exception(response.message ?? 'No se pudo actualizar el stock');
    }

    if (response.data is String) {
      return ResumenSalidaData(response.data.toString());
    }
    if (response.data is Map) {
      final map = response.data as Map;
      final mensaje =
          (map['mensaje'] ?? map['message'] ?? 'Stock actualizado').toString();
      return ResumenSalidaData(mensaje);
    }

    return ResumenSalidaData('Stock actualizado correctamente');
  }

  Future<String> enviarFormularioSalida(SalidaLegacyFormData form) async {
    final params = _buildSalidaFormParams(form);
    final uri = Uri.parse(_salidaFormUrl).replace(queryParameters: params);

    final response = await _formsDio.getUri(uri);
    if ((response.statusCode ?? 500) >= 400) {
      throw Exception('Google Forms rechazo el envio de salida de almacen');
    }

    return 'Salida de almacen enviada a Google Forms';
  }

  Map<String, String> _buildSalidaFormParams(SalidaLegacyFormData form) {
    final params = <String, String>{
      'entry.1083098882': form.codigoPcp.trim(),
      'entry.620416969': form.planta.trim(),
      'entry.1624934217': form.ubicacion.trim(),
      'entry.591236589': form.fechaSalida.trim(),
      'entry.441717960': form.horaSalida.trim(),
      'entry.1117527060': form.usuario.trim(),
      'entry.256331314': form.telar.trim(),
      'entry.2082052035': form.movimiento.trim(),
      'entry.19047762': form.numeroGuia.trim(),
      'entry.243664336': form.lote.trim(),
      'entry.1591121424': form.ordenCompra.trim(),
      'entry.386749025': form.pesoNeto.trim(),
    };

    if (form.qrCampos == 16) {
      params['entry.40194284'] = form.codigoKardex.trim();
      params['entry.996256703'] = form.servicio.trim();
    }

    return params;
  }

  List<String> _normalizeCatalogColumn(List<String> rawValues) {
    if (rawValues.isEmpty) {
      return const <String>[];
    }

    // Evita eliminar valores reales cuando la primera fila no es header.
    final values = rawValues
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    if (values.isEmpty) {
      return const <String>[];
    }

    final deduped = <String>{};
    final ordered = <String>[];
    for (final item in values) {
      final key = item.toUpperCase();
      if (deduped.add(key)) {
        ordered.add(item);
      }
    }
    return ordered;
  }

  Future<SalidaCatalogosData> _obtenerCatalogosDesdeBackendReadColumn() async {
    final responseVenta = await _client.get(
      '${ApiRoutes.readColumn}?sheet=$_salidaWorksheet&column=$_colDestinoVenta',
    );
    if (!responseVenta.success) {
      throw Exception(
        responseVenta.message ??
            'No se pudo leer columna $_colDestinoVenta de datosKardex',
      );
    }

    final responseCliente = await _client.get(
      '${ApiRoutes.readColumn}?sheet=$_salidaWorksheet&column=$_colDestinoCliente',
    );
    if (!responseCliente.success) {
      throw Exception(
        responseCliente.message ??
            'No se pudo leer columna $_colDestinoCliente de datosKardex',
      );
    }

    final ventaRaw = _extractRawColumnList(responseVenta.responseData);
    final clienteRaw = _extractRawColumnList(responseCliente.responseData);

    return SalidaCatalogosData(
      destinosVenta: _normalizeCatalogColumn(ventaRaw),
      destinosCliente: _normalizeCatalogColumn(clienteRaw),
    );
  }

  List<String> _extractRawColumnList(dynamic input) {
    if (input is List) {
      return input.map((item) => item.toString()).toList(growable: false);
    }

    if (input is Map) {
      final directData =
          input['data'] ??
          input['result'] ??
          input['values'] ??
          input['column_data'] ??
          input['column'] ??
          input['items'];
      if (directData is List) {
        return directData
            .map((item) => item.toString())
            .toList(growable: false);
      }
      if (directData is String) {
        return _decodeJsonListOrSplit(directData);
      }
    }

    if (input is String) {
      return _decodeJsonListOrSplit(input);
    }

    return const <String>[];
  }

  List<String> _decodeJsonListOrSplit(String raw) {
    final text = raw.trim();
    if (text.isEmpty) {
      return const <String>[];
    }

    try {
      final decoded = jsonDecode(text);
      if (decoded is List) {
        return decoded.map((item) => item.toString()).toList(growable: false);
      }
    } catch (_) {
      // Si no es JSON, cae al split basico.
    }

    return text.split(',').map((item) => item.trim()).toList(growable: false);
  }

  Future<List<String>> _readWorksheetColumn(
    Worksheet worksheet,
    int columnIndex,
  ) async {
    // Algunas hojas legacy tienen la fila 1 vacia y el SDK puede devolver
    // colecciones vacias al iniciar desde 1. Probamos ambas posiciones.
    final candidates = <int>[1, 2];
    for (final startRow in candidates) {
      final rows = await worksheet.values.allRows(fromRow: startRow);
      if (rows.isEmpty) {
        continue;
      }

      final values = <String>[];
      var nonEmptyCount = 0;
      for (final row in rows) {
        final value = row.length >= columnIndex ? row[columnIndex - 1] : '';
        values.add(value);
        if (value.trim().isNotEmpty) {
          nonEmptyCount += 1;
        }
      }

      if (nonEmptyCount > 0) {
        return values;
      }
    }

    return const <String>[];
  }

  Future<SalidaCatalogosData> _obtenerCatalogosDesdeGSheets() async {
    final credentialsJson = await _loadServiceAccountJson();
    final gsheets = GSheets(credentialsJson);
    final spreadsheet = await gsheets.spreadsheet(_salidaSpreadsheetId);
    final worksheet = spreadsheet.worksheetByTitle(_salidaWorksheet);

    if (worksheet == null) {
      throw Exception(
        'No se encontro worksheet $_salidaWorksheet en Google Sheets',
      );
    }

    final ventaRaw = await _readWorksheetColumn(worksheet, _colDestinoVenta);
    final clienteRaw = await _readWorksheetColumn(
      worksheet,
      _colDestinoCliente,
    );

    return SalidaCatalogosData(
      destinosVenta: _normalizeCatalogColumn(ventaRaw),
      destinosCliente: _normalizeCatalogColumn(clienteRaw),
    );
  }

  Future<SalidaCatalogosData> _obtenerCatalogosDesdeCsvExport() async {
    final uri = Uri.parse(
      'https://docs.google.com/spreadsheets/d/$_salidaSpreadsheetId/export'
      '?format=csv&gid=$_salidaWorksheetGid',
    );
    final response = await _formsDio.getUri<String>(uri);
    if ((response.statusCode ?? 500) >= 400) {
      throw Exception('Google Sheets export rechazo la consulta CSV');
    }

    final csvText = (response.data ?? '').trim();
    if (csvText.isEmpty) {
      throw Exception('CSV de catalogos vacio');
    }

    final rows = _parseCsvRows(csvText);
    if (rows.isEmpty) {
      throw Exception('No se pudo parsear CSV de catalogos');
    }

    final ventaRaw = _extractCsvColumn(rows, _colDestinoVenta);
    final clienteRaw = _extractCsvColumn(rows, _colDestinoCliente);
    return SalidaCatalogosData(
      destinosVenta: _normalizeCatalogColumn(ventaRaw),
      destinosCliente: _normalizeCatalogColumn(clienteRaw),
    );
  }

  List<String> _extractCsvColumn(List<List<String>> rows, int columnIndex) {
    final values = <String>[];
    for (final row in rows) {
      if (row.length >= columnIndex) {
        values.add(row[columnIndex - 1]);
      } else {
        values.add('');
      }
    }
    return values;
  }

  List<List<String>> _parseCsvRows(String content) {
    final rows = <List<String>>[];
    var row = <String>[];
    var field = StringBuffer();
    var inQuotes = false;

    void commitField() {
      row.add(field.toString());
      field = StringBuffer();
    }

    void commitRow() {
      // Evita crear ultima fila fantasma al final del archivo.
      if (row.isEmpty && field.isEmpty) {
        return;
      }
      commitField();
      rows.add(row);
      row = <String>[];
    }

    for (var i = 0; i < content.length; i++) {
      final char = content[i];

      if (char == '"') {
        final nextIsQuote = i + 1 < content.length && content[i + 1] == '"';
        if (inQuotes && nextIsQuote) {
          field.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
        continue;
      }

      if (!inQuotes && char == ',') {
        commitField();
        continue;
      }

      if (!inQuotes && (char == '\n' || char == '\r')) {
        if (char == '\r' && i + 1 < content.length && content[i + 1] == '\n') {
          i++;
        }
        commitRow();
        continue;
      }

      field.write(char);
    }

    // Ultima fila sin salto de linea.
    if (field.isNotEmpty || row.isNotEmpty) {
      commitRow();
    }

    return rows;
  }

  bool _esCatalogoRobusto(SalidaCatalogosData data) {
    return data.destinosVenta.length > 1 && data.destinosCliente.length > 1;
  }

  SalidaCatalogosData _mergeCatalogosPreferRobusto({
    required SalidaCatalogosData primary,
    required SalidaCatalogosData fallback,
  }) {
    final ventas =
        primary.destinosVenta.length >= fallback.destinosVenta.length
            ? primary.destinosVenta
            : fallback.destinosVenta;
    final clientes =
        primary.destinosCliente.length >= fallback.destinosCliente.length
            ? primary.destinosCliente
            : fallback.destinosCliente;
    return SalidaCatalogosData(
      destinosVenta: ventas,
      destinosCliente: clientes,
    );
  }

  String _shortError(Object error) {
    return error.toString().replaceAll('\n', ' ').trim();
  }

  Future<String> _loadServiceAccountJson() async {
    const rawJson = String.fromEnvironment(
      'GOOGLE_SHEETS_SA_JSON',
      defaultValue: '',
    );
    if (rawJson.trim().isNotEmpty) {
      return rawJson.trim();
    }

    const encoded = String.fromEnvironment(
      'GOOGLE_SHEETS_SA_B64',
      defaultValue: '',
    );
    if (encoded.trim().isNotEmpty) {
      try {
        return utf8.decode(base64Decode(encoded.trim()));
      } catch (_) {
        throw Exception('GOOGLE_SHEETS_SA_B64 no tiene formato Base64 valido');
      }
    }

    if (kReleaseMode && !EnvironmentConfig.allowEmbeddedSheetsCredentials) {
      throw Exception(
        'Build release bloqueado: configure GOOGLE_SHEETS_SA_B64 '
        'o habilite ALLOW_EMBEDDED_SHEETS_CREDENTIALS=true de forma temporal.',
      );
    }

    try {
      return await rootBundle.loadString(
        EnvironmentConfig.googleSheetsServiceAccountAsset,
      );
    } catch (_) {
      throw Exception(
        'No se encontro la credencial de Google Sheets. '
        'Agregue el JSON en ${EnvironmentConfig.googleSheetsServiceAccountAsset} '
        'o use --dart-define=GOOGLE_SHEETS_SA_B64=...',
      );
    }
  }
}
