import 'package:dio/dio.dart';

import '../../../core/contracts/api_contracts.dart';
import '../../../core/network/api_client.dart';

class MovimientoTelasCatalogosData {
  final List<String> articulos;
  final List<String> codigosFalla;

  const MovimientoTelasCatalogosData({
    required this.articulos,
    required this.codigosFalla,
  });
}

class MovimientoTelaCortePayload {
  final String codigoBase;
  final String correlativo;
  final String opPrefijo;
  final String opNumero;
  final String articulo;
  final String numTelar;
  final String numPlegador;
  final String metroCorte;
  final String ancho;
  final String peso;
  final String cc;
  final String cd;
  final String fechaCorte;
  final String fechaRevisado;
  final List<String> fallasSecundarias;
  final String numCorte;
  final String nombre;
  final String fallaPrincipal;

  const MovimientoTelaCortePayload({
    required this.codigoBase,
    required this.correlativo,
    required this.opPrefijo,
    required this.opNumero,
    required this.articulo,
    required this.numTelar,
    required this.numPlegador,
    required this.metroCorte,
    required this.ancho,
    required this.peso,
    required this.cc,
    required this.cd,
    required this.fechaCorte,
    required this.fechaRevisado,
    required this.fallasSecundarias,
    required this.numCorte,
    required this.nombre,
    required this.fallaPrincipal,
  });
}

class MovimientoTelasRemoteDatasource {
  static const String _corteFormUrl =
      'https://docs.google.com/forms/u/0/d/e/'
      '1FAIpQLSe9czYgEi8n-y-WHoRDZu_9p4OL75btcQZ8tTF3tf-UNMOI7Q/formResponse';

  final ApiClient _apiClient;
  final LocalApiClient _localApiClient;
  final Dio _formsDio;

  MovimientoTelasRemoteDatasource(this._apiClient, this._localApiClient)
    : _formsDio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 12),
          receiveTimeout: const Duration(seconds: 18),
          followRedirects: true,
          validateStatus: (code) => code != null && code < 500,
        ),
      );

  Future<MovimientoTelasCatalogosData> obtenerCatalogos() async {
    final response = await _apiClient.post(
      ApiRoutes.obtenerDatosGenerales,
      data: ApiPayloads.obtenerDatosGenerales(),
    );

    if (!response.success) {
      throw Exception(
        response.message ?? 'No se pudieron obtener catalogos de ingreso telas',
      );
    }

    final map = _toMap(response.data);

    final articulos = _extractListByKeys(map, const [
      'articulos',
      'articulo',
      'lista_articulos',
      'articulos_lista',
    ]);

    final fallas = _extractListByKeys(map, const [
      'codigos_falla',
      'codigos_fallo',
      'codigo_falla',
      'cod_falla',
      'fallas',
      'fallos',
      'codigos',
    ]);

    return MovimientoTelasCatalogosData(
      articulos: articulos,
      codigosFalla: fallas,
    );
  }

  Future<String> enviarCorte(MovimientoTelaCortePayload payload) async {
    final params = _buildCorteFormParams(payload);
    final uri = Uri.parse(_corteFormUrl).replace(queryParameters: params);
    final response = await _formsDio.getUri(uri);

    if ((response.statusCode ?? 500) >= 400) {
      throw Exception('Google Forms rechazo el corte de tela');
    }

    return 'Corte enviado correctamente';
  }

  Future<String> generarPdfEtiqueta({
    required String imageBase64,
    required String text,
  }) async {
    final response = await _localApiClient.post(
      ApiRoutes.localGeneratePdf,
      data: {'image': imageBase64.trim(), 'text': text.trim()},
    );

    if (!response.success) {
      throw Exception(
        response.message ?? 'No se pudo generar el PDF de etiqueta',
      );
    }

    final data = response.data;
    if (data is! Map) {
      throw Exception('Respuesta invalida de /generate_pdf');
    }

    final success = data['success'] == true;
    final message = (data['message'] ?? '').toString().trim();
    if (!success) {
      throw Exception(
        message.isNotEmpty
            ? message
            : 'La API local rechazo la generacion del PDF',
      );
    }

    return message.isNotEmpty ? message : 'PDF generado correctamente';
  }

  Future<String> imprimirEtiqueta() async {
    final response = await _localApiClient.post(ApiRoutes.localImprimir);

    if (!response.success) {
      throw Exception(response.message ?? 'No se pudo imprimir etiqueta');
    }

    final data = response.data;
    if (data is! Map) {
      throw Exception('Respuesta invalida de /imprimir');
    }

    final success = data['success'] == true;
    final message = (data['message'] ?? '').toString().trim();
    if (!success) {
      throw Exception(
        message.isNotEmpty ? message : 'La API local rechazo la impresion',
      );
    }

    return message.isNotEmpty ? message : 'Etiqueta enviada a impresion';
  }

  Map<String, String> _buildCorteFormParams(
    MovimientoTelaCortePayload payload,
  ) {
    final codigoCompleto =
        '${payload.codigoBase.trim()}${payload.correlativo.trim()}';
    final opCompleto = '${payload.opPrefijo.trim()}${payload.opNumero.trim()}';
    final observaciones = _buildObservaciones(payload.fallasSecundarias);

    return {
      'entry.1436967880': codigoCompleto,
      'entry.2002915432': opCompleto,
      'entry.237900973': payload.articulo.trim().toUpperCase(),
      'entry.77787340': payload.numTelar.trim(),
      'entry.884918138': payload.numPlegador.trim(),
      'entry.933551434': payload.metroCorte.trim(),
      'entry.358018867': payload.ancho.trim(),
      'entry.649711315': payload.peso.trim(),
      'entry.1476969918': payload.cc.trim(),
      'entry.1493336099': payload.cd.trim(),
      'entry.253505744': payload.fechaCorte.trim(),
      'entry.517453585': payload.fechaRevisado.trim(),
      'entry.198776140': observaciones,
      'entry.317094871': payload.numCorte.trim(),
      'entry.1586908334': payload.nombre.trim(),
      'entry.6627925': payload.fallaPrincipal.trim(),
    };
  }

  String _buildObservaciones(List<String> fallas) {
    final clean = fallas
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    return clean.join(';');
  }

  Map<String, dynamic> _toMap(dynamic source) {
    if (source is Map) {
      final map = Map<String, dynamic>.from(source);
      final nested = map['data'];
      if (nested is Map) {
        return Map<String, dynamic>.from(nested);
      }
      return map;
    }
    return <String, dynamic>{};
  }

  List<String> _extractListByKeys(
    Map<String, dynamic> source,
    List<String> keys,
  ) {
    for (final key in keys) {
      final direct = _normalizeStringList(source[key]);
      if (direct.isNotEmpty) return direct;
    }

    final data = source['data'];
    if (data is Map) {
      final nested = Map<String, dynamic>.from(data);
      for (final key in keys) {
        final nestedList = _normalizeStringList(nested[key]);
        if (nestedList.isNotEmpty) return nestedList;
      }
    }

    return const <String>[];
  }

  List<String> _normalizeStringList(dynamic raw) {
    if (raw == null) return const <String>[];

    if (raw is String) {
      return raw
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toSet()
          .toList(growable: false);
    }

    if (raw is List) {
      final values = raw
          .map((item) {
            if (item is Map) {
              final map = Map<String, dynamic>.from(item);
              return (map['nombre'] ??
                      map['name'] ??
                      map['value'] ??
                      map['codigo'] ??
                      map['articulo'] ??
                      '')
                  .toString()
                  .trim();
            }
            return (item ?? '').toString().trim();
          })
          .where((item) => item.isNotEmpty)
          .toList(growable: false);

      final unique = <String>{};
      final ordered = <String>[];
      for (final value in values) {
        if (unique.add(value)) {
          ordered.add(value);
        }
      }
      return ordered;
    }

    return const <String>[];
  }
}
