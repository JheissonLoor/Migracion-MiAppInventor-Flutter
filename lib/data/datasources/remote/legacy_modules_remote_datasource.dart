import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:gsheets/gsheets.dart';

import '../../../core/config/environment.dart';
import '../../../core/contracts/api_contracts.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/legacy_qr_tokenizer.dart';

class AgregarProveedorPayload {
  final String proveedor;
  final String material;
  final String titulo;
  final String taraCono;
  final String taraBolsa;
  final String taraCaja;
  final String taraSaco;

  const AgregarProveedorPayload({
    required this.proveedor,
    required this.material,
    required this.titulo,
    required this.taraCono,
    required this.taraBolsa,
    required this.taraCaja,
    required this.taraSaco,
  });
}

class IngresoStockActualData {
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
  final String fechaSalida;
  final String horaSalida;
  final String almacen;
  final String ubicacion;
  final String servicio;
  final String nombre;

  const IngresoStockActualData({
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
    required this.fechaSalida,
    required this.horaSalida,
    required this.almacen,
    required this.ubicacion,
    required this.servicio,
    required this.nombre,
  });

  factory IngresoStockActualData.fromDynamic(
    dynamic source, {
    String fallbackCodigoPcp = '',
    String fallbackCodigoKardex = '',
  }) {
    if (source is List) {
      return IngresoStockActualData.fromList(
        source,
        fallbackCodigoPcp: fallbackCodigoPcp,
        fallbackCodigoKardex: fallbackCodigoKardex,
      );
    }

    if (source is String) {
      final tokens = LegacyQrTokenizer.splitSmart(source);
      if (tokens.isNotEmpty) {
        return IngresoStockActualData.fromList(
          tokens,
          fallbackCodigoPcp: fallbackCodigoPcp,
          fallbackCodigoKardex: fallbackCodigoKardex,
        );
      }
    }

    if (source is Map) {
      final map = Map<String, dynamic>.from(source);
      final nested = map['data'];
      if (nested is List) {
        return IngresoStockActualData.fromList(
          nested,
          fallbackCodigoPcp: fallbackCodigoPcp,
          fallbackCodigoKardex: fallbackCodigoKardex,
        );
      }
      if (nested is Map) {
        return IngresoStockActualData.fromMap(
          Map<String, dynamic>.from(nested),
          fallbackCodigoPcp: fallbackCodigoPcp,
          fallbackCodigoKardex: fallbackCodigoKardex,
        );
      }
      if (nested is String) {
        final tokens = LegacyQrTokenizer.splitSmart(nested);
        if (tokens.isNotEmpty) {
          return IngresoStockActualData.fromList(
            tokens,
            fallbackCodigoPcp: fallbackCodigoPcp,
            fallbackCodigoKardex: fallbackCodigoKardex,
          );
        }
      }
      return IngresoStockActualData.fromMap(
        map,
        fallbackCodigoPcp: fallbackCodigoPcp,
        fallbackCodigoKardex: fallbackCodigoKardex,
      );
    }

    throw Exception('Formato inesperado en stock_actual_pcp');
  }

  factory IngresoStockActualData.fromList(
    List<dynamic> source, {
    String fallbackCodigoPcp = '',
    String fallbackCodigoKardex = '',
  }) {
    final values =
        source.map((item) => (item ?? '').toString().trim()).toList();
    final fallbackPcp = fallbackCodigoPcp.trim();
    final fallbackKardex = fallbackCodigoKardex.trim();

    if (values.length >= 19) {
      return IngresoStockActualData._fromLegacy19(
        values,
        fallbackCodigoPcp: fallbackPcp,
        fallbackCodigoKardex: fallbackKardex,
      );
    }

    if (_looksLikeLegacy16(values)) {
      return IngresoStockActualData._fromLegacy16(
        values,
        fallbackCodigoPcp: fallbackPcp,
        fallbackCodigoKardex: fallbackKardex,
      );
    }

    if (_looksLikeLegacy15(values)) {
      return IngresoStockActualData._fromLegacy15(
        values,
        fallbackCodigoPcp: fallbackPcp,
        fallbackCodigoKardex: fallbackKardex,
      );
    }

    if (_looksLikeLegacy14(values)) {
      return IngresoStockActualData._fromLegacy14(
        values,
        fallbackCodigoPcp: fallbackPcp,
        fallbackCodigoKardex: fallbackKardex,
      );
    }

    while (values.length < 19) {
      values.add('');
    }

    return IngresoStockActualData(
      codigoKardex: _pick(values[0], fallbackKardex),
      codigoPcp: _pick(values[1], fallbackPcp),
      material: values[2],
      titulo: values[3],
      color: values[4],
      lote: values[5],
      numCajas: values[6],
      totalBobinas: values[7],
      cantidadReenconado: values[8],
      pesoBruto: values[9],
      pesoNeto: values[10],
      proveedor: values[11],
      fechaIngreso: values[12],
      fechaSalida: values[13],
      horaSalida: values[14],
      almacen: values[15],
      ubicacion: values[16],
      servicio: values[17],
      nombre: values[18],
    );
  }

  factory IngresoStockActualData.fromMap(
    Map<String, dynamic> map, {
    String fallbackCodigoPcp = '',
    String fallbackCodigoKardex = '',
  }) {
    final normalized = <String, String>{};
    map.forEach((key, value) {
      normalized[key.toLowerCase().trim()] = (value ?? '').toString().trim();
    });

    String read(List<String> keys) {
      for (final key in keys) {
        final value = normalized[key.toLowerCase()];
        if (value != null && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
      return '';
    }

    return IngresoStockActualData(
      codigoKardex: _pick(
        read(['codigo_kardex', 'codigo kardex', 'codigokardex', 'kardex']),
        fallbackCodigoKardex,
      ),
      codigoPcp: _pick(
        read(['codigo_pcp', 'codigo pcp', 'codigopcp', 'pcp', 'codigo']),
        fallbackCodigoPcp,
      ),
      material: read(['material']),
      titulo: read(['titulo', 'título']),
      color: read(['color']),
      lote: read(['lote']),
      numCajas: read(['num_cajas', 'num cajas', 'numcajas', 'caja']),
      totalBobinas: read([
        'total_bobinas',
        'total bobinas',
        'cantidad_bobinas',
        'bobina',
      ]),
      cantidadReenconado: read([
        'cantidad_reenconado',
        'cantidad reenconado',
        'reenconado',
      ]),
      pesoBruto: read(['peso_bruto', 'peso bruto']),
      pesoNeto: read(['peso_neto', 'peso neto']),
      proveedor: read(['proveedor']),
      fechaIngreso: read(['fecha_ingreso', 'fecha ingreso']),
      fechaSalida: read(['fecha_salida', 'fecha salida']),
      horaSalida: read(['hora_salida', 'hora salida']),
      almacen: read(['almacen', 'almacén']),
      ubicacion: read(['ubicacion', 'ubicación']),
      servicio: read(['servicio']),
      nombre: read(['nombre', 'usuario']),
    );
  }

  static IngresoStockActualData _fromLegacy19(
    List<String> values, {
    required String fallbackCodigoPcp,
    required String fallbackCodigoKardex,
  }) {
    return IngresoStockActualData(
      codigoKardex: _pick(_safeAt(values, 0), fallbackCodigoKardex),
      codigoPcp: _pick(_safeAt(values, 1), fallbackCodigoPcp),
      material: _safeAt(values, 2),
      titulo: _safeAt(values, 3),
      color: _safeAt(values, 4),
      lote: _safeAt(values, 5),
      numCajas: _safeAt(values, 6),
      totalBobinas: _safeAt(values, 7),
      cantidadReenconado: _safeAt(values, 8),
      pesoBruto: _safeAt(values, 9),
      pesoNeto: _safeAt(values, 10),
      proveedor: _safeAt(values, 11),
      fechaIngreso: _safeAt(values, 12),
      fechaSalida: _safeAt(values, 13),
      horaSalida: _safeAt(values, 14),
      almacen: _safeAt(values, 15),
      ubicacion: _safeAt(values, 16),
      servicio: _safeAt(values, 17),
      nombre: _safeAt(values, 18),
    );
  }

  static IngresoStockActualData _fromLegacy16(
    List<String> values, {
    required String fallbackCodigoPcp,
    required String fallbackCodigoKardex,
  }) {
    return IngresoStockActualData(
      codigoKardex: _pick(_safeAt(values, 0), fallbackCodigoKardex),
      codigoPcp: _pick(_safeAt(values, 1), fallbackCodigoPcp),
      material: _safeAt(values, 2),
      titulo: _safeAt(values, 3),
      color: _safeAt(values, 4),
      lote: _safeAt(values, 5),
      numCajas: _safeAt(values, 6),
      totalBobinas: _safeAt(values, 7),
      cantidadReenconado: _safeAt(values, 8),
      pesoBruto: _safeAt(values, 9),
      pesoNeto: _safeAt(values, 10),
      proveedor: _safeAt(values, 11),
      fechaIngreso: _safeAt(values, 12),
      fechaSalida: '',
      horaSalida: '',
      almacen: _safeAt(values, 13),
      ubicacion: _safeAt(values, 14),
      servicio: _safeAt(values, 15),
      nombre: '',
    );
  }

  static IngresoStockActualData _fromLegacy15(
    List<String> values, {
    required String fallbackCodigoPcp,
    required String fallbackCodigoKardex,
  }) {
    return IngresoStockActualData(
      codigoKardex: _pick(_safeAt(values, 4), fallbackCodigoKardex),
      codigoPcp: _pick(_safeAt(values, 0), fallbackCodigoPcp),
      material: _safeAt(values, 1),
      titulo: _safeAt(values, 2),
      color: _safeAt(values, 3),
      lote: _safeAt(values, 5),
      numCajas: _safeAt(values, 8),
      totalBobinas: _safeAt(values, 9),
      cantidadReenconado: '',
      pesoBruto: _safeAt(values, 10),
      pesoNeto: _safeAt(values, 11),
      proveedor: _safeAt(values, 6),
      fechaIngreso: _safeAt(values, 14),
      fechaSalida: '',
      horaSalida: '',
      almacen: _safeAt(values, 13),
      ubicacion: _safeAt(values, 12),
      servicio: _safeAt(values, 7),
      nombre: '',
    );
  }

  static IngresoStockActualData _fromLegacy14(
    List<String> values, {
    required String fallbackCodigoPcp,
    required String fallbackCodigoKardex,
  }) {
    return IngresoStockActualData(
      codigoKardex: fallbackCodigoKardex.trim(),
      codigoPcp: _pick(_safeAt(values, 0), fallbackCodigoPcp),
      material: _safeAt(values, 1),
      titulo: _safeAt(values, 2),
      color: _safeAt(values, 3),
      lote: _safeAt(values, 4),
      numCajas: _safeAt(values, 5),
      totalBobinas: _safeAt(values, 6),
      cantidadReenconado: _safeAt(values, 7),
      pesoBruto: _safeAt(values, 8),
      pesoNeto: _safeAt(values, 9),
      proveedor: _safeAt(values, 10),
      fechaIngreso: _safeAt(values, 11),
      fechaSalida: '',
      horaSalida: '',
      almacen: _safeAt(values, 12),
      ubicacion: _safeAt(values, 13),
      servicio: '',
      nombre: '',
    );
  }

  static bool _looksLikeLegacy16(List<String> values) {
    return values.length >= 16 &&
        _looksLikeKardex(_safeAt(values, 0)) &&
        _looksLikePcp(_safeAt(values, 1));
  }

  static bool _looksLikeLegacy15(List<String> values) {
    return values.length >= 15 &&
        _looksLikePcp(_safeAt(values, 0)) &&
        _looksLikeKardex(_safeAt(values, 4));
  }

  static bool _looksLikeLegacy14(List<String> values) {
    return values.length >= 14 &&
        _looksLikePcp(_safeAt(values, 0)) &&
        !_looksLikeKardex(_safeAt(values, 0));
  }

  static bool _looksLikePcp(String value) {
    final token = value.trim().toUpperCase();
    if (token.isEmpty) return false;
    if (token.startsWith('PCP-')) return true;
    if (RegExp(r'^H\d{5,}-\d+$').hasMatch(token)) return true;
    if (RegExp(r'^[A-Z]{2,}\d{2,}-\d+$').hasMatch(token)) return true;
    return false;
  }

  static bool _looksLikeKardex(String value) {
    final token = value.trim().toUpperCase();
    return token.isNotEmpty && token.contains('/') && !token.contains(',');
  }

  static String _safeAt(List<String> values, int index) {
    if (index < 0 || index >= values.length) {
      return '';
    }
    return values[index].trim();
  }

  static String _pick(String value, String fallback) {
    final clean = value.trim();
    if (clean.isNotEmpty) {
      return clean;
    }
    return fallback.trim();
  }
}

class IngresoTelasFormData {
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

  const IngresoTelasFormData({
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
  });
}

class ContenedorFormData {
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

  const ContenedorFormData({
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
  });
}

class LegacyModulesRemoteDatasource {
  static const String _ingresoFormUrl =
      'https://docs.google.com/forms/u/0/d/e/1FAIpQLScxY2PYTT73NAWhosg6cLeRmpF2kO8Txn539h7w2FhJ3AipBA/formResponse';
  static const String _contenedorFormUrl =
      'https://docs.google.com/forms/d/1r0DtVI8eu_p5Jxqxnf0E4W1V6Z_O8sQ5hKFTXWEIHX4/formResponse';
  static const String _proveedorSpreadsheetId =
      '1CtALV50_HJvNrS9jiCD_vITZfuOq6cGBkgJ9Abu6N50';
  static const String _proveedorWorksheet = 'tablaProveedor';

  final ApiClient _client;
  final Dio _formsDio;

  LegacyModulesRemoteDatasource(this._client)
    : _formsDio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 18),
          followRedirects: true,
          validateStatus: (code) => code != null && code < 500,
        ),
      );

  Future<IngresoStockActualData> consultarStockActualPcp(
    String codigoPcp, {
    String fallbackCodigoPcp = '',
    String fallbackCodigoKardex = '',
  }) async {
    final clean = codigoPcp.trim();
    if (clean.isEmpty) {
      throw Exception('Debe indicar codigo PCP para consultar stock actual');
    }

    final response = await _client.post(
      ApiRoutes.stockActualPcp,
      data: ApiPayloads.stockActualPcp(clean),
    );

    if (!response.success) {
      throw Exception(
        response.message ?? 'No se pudo consultar stock_actual_pcp',
      );
    }

    final dynamic data = response.responseData;
    if (data is String && data.toLowerCase().contains('not found')) {
      throw Exception('No se encontraron datos para el codigo escaneado');
    }

    try {
      return IngresoStockActualData.fromDynamic(
        data,
        fallbackCodigoPcp:
            fallbackCodigoPcp.trim().isNotEmpty
                ? fallbackCodigoPcp.trim()
                : clean,
        fallbackCodigoKardex: fallbackCodigoKardex.trim(),
      );
    } catch (_) {
      final message = response.responseMessage.trim();
      if (message.isNotEmpty) {
        throw Exception(message);
      }
      throw Exception('Respuesta inesperada en /stock_actual_pcp');
    }
  }

  Future<String> enviarIngresoTelas(IngresoTelasFormData form) async {
    final params = _buildIngresoParams(form);
    final uri = Uri.parse(_ingresoFormUrl).replace(queryParameters: params);
    final response = await _formsDio.getUri(uri);
    if ((response.statusCode ?? 500) >= 400) {
      throw Exception('Google Forms rechazo el ingreso de telas');
    }
    return 'Ingreso de telas enviado correctamente';
  }

  Future<String> enviarContenedor(ContenedorFormData form) async {
    final params = _buildContenedorParams(form);
    final uri = Uri.parse(_contenedorFormUrl).replace(queryParameters: params);
    final response = await _formsDio.getUri(uri);
    if ((response.statusCode ?? 500) >= 400) {
      throw Exception('Google Forms rechazo el registro de contenedor');
    }
    return 'Contenedor enviado correctamente';
  }

  Future<String> actualizarDatosContenedor(ContenedorFormData form) async {
    final response = await _client.post(
      ApiRoutes.actualizarDatos,
      data: ApiPayloads.actualizarDatos(
        codigoPcp: form.codigoHc,
        numCajas: _toDouble(form.numCajasMovidas),
        totalBobinas: _toDouble(form.totalBobinas),
        pesoBrutoTotal: _toDouble(form.pesoBrutoTotal),
        pesoNetoTotal: _toDouble(form.pesoNetoTotal),
        usuario: form.usuario,
      ),
    );

    if (!response.success) {
      throw Exception(
        response.message ?? 'No se pudo actualizar stock en /actualizar_datos',
      );
    }

    if (response.data is String) {
      return response.data.toString().trim();
    }
    if (response.data is Map) {
      final map = Map<String, dynamic>.from(response.data);
      final message =
          (map['message'] ?? map['mensaje'] ?? map['result'] ?? '').toString();
      if (message.trim().isNotEmpty) {
        return message.trim();
      }
    }
    return 'Stock actualizado correctamente';
  }

  Future<String> registrarProveedor(AgregarProveedorPayload payload) async {
    final credentialsJson = await _loadServiceAccountJson();
    final gsheets = GSheets(credentialsJson);
    final spreadsheet = await gsheets.spreadsheet(_proveedorSpreadsheetId);
    final worksheet = spreadsheet.worksheetByTitle(_proveedorWorksheet);

    if (worksheet == null) {
      throw Exception(
        'No se encontro worksheet $_proveedorWorksheet en Google Sheets',
      );
    }

    final inserted = await worksheet.values.appendRow([
      '',
      payload.proveedor.trim(),
      payload.material.trim(),
      payload.titulo.trim(),
      payload.taraCono.trim(),
      payload.taraBolsa.trim(),
      payload.taraCaja.trim(),
      payload.taraSaco.trim(),
    ]);

    if (!inserted) {
      throw Exception('Google Sheets no confirmo insercion del proveedor');
    }

    return 'Proveedor registrado correctamente';
  }

  Map<String, String> _buildIngresoParams(IngresoTelasFormData form) {
    final params = <String, String>{
      'entry.1436374952': form.codigoPcp.trim(),
      'entry.801209216': form.material.trim(),
      'entry.2020567260': form.titulo.trim(),
      'entry.1097580957': form.color.trim(),
      'entry.723256792': form.lote.trim(),
      'entry.1998836419': form.numCajas.trim(),
      'entry.1309561624': form.totalBobinas.trim(),
      'entry.1885415491': form.cantidadReenconado.trim(),
      'entry.1455667082': form.pesoBruto.trim(),
      'entry.433059641': form.pesoNeto.trim(),
      'entry.110444091': form.proveedor.trim(),
      'entry.1083830371': form.fechaIngreso.trim(),
      'entry.429588365': form.almacen.trim(),
      'entry.2027387449': form.ubicacion.trim(),
      'entry.1927778603': form.nombre.trim(),
    };

    if (form.qrCampos == 16) {
      params['entry.2040636491'] = form.codigoKardex.trim();
      params['entry.1586851897'] = form.servicio.trim();
    }

    return params;
  }

  Map<String, String> _buildContenedorParams(ContenedorFormData form) {
    return {
      'entry.1291560392': form.codigoHc.trim(),
      'entry.912559180': form.material.trim(),
      'entry.131036632': form.titulo.trim(),
      'entry.972506807': form.color.trim(),
      'entry.942516383': form.lote.trim(),
      'entry.1128677452': form.numCajasMovidas.trim(),
      'entry.1647326412': form.nroConos.trim(),
      'entry.1773695393': '0',
      'entry.1250377164': form.pesoBruto.trim(),
      'entry.2047110963': form.pesoNeto.trim(),
      'entry.1956196193': form.proveedor.trim(),
      'entry.927619580': form.fechaIngreso.trim(),
      'entry.29574387': form.fechaSalida.trim(),
      'entry.2083629018': form.nombreOperario.trim(),
    };
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

  double _toDouble(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0;
  }
}
