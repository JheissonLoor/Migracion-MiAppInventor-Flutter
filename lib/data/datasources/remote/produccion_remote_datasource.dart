import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/config/environment.dart';
import '../../../core/contracts/api_contracts.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/local_storage.dart';

class ProduccionCatalogosData {
  final List<String> articulos;
  final List<String> colores;
  final List<String> materiales;
  final List<String> titulos;

  const ProduccionCatalogosData({
    this.articulos = const [],
    this.colores = const [],
    this.materiales = const [],
    this.titulos = const [],
  });
}

class TelaresSearchData {
  final List<String> raw;

  const TelaresSearchData({this.raw = const []});

  String get articuloUrdido => _at(1);
  String get codigoUrdido => _at(2);
  String get nroPlegadorUrdido => _at(3);
  String get opUrdido => _at(4);
  String get metrosUrdido => _at(5);
  String get metrosEngomado => _at(6);
  String get nuevoCorteDisponible => _at(7).toLowerCase();
  String get reloj => _at(8);
  String get puntajeInicial => _at(9);
  String get puntajeAnterior => _at(10);
  String get telarAnterior => _at(11);

  String _at(int oneBasedIndex) {
    final index = oneBasedIndex - 1;
    if (index < 0 || index >= raw.length) return '';
    return raw[index].trim();
  }
}

class IngresoTelarProgresoData {
  final String telar;
  final String articulo;
  final String hilo;
  final String titulo;
  final String metraje;
  final String fechaInicio;
  final String fechaFinal;
  final String pesoTotal;

  const IngresoTelarProgresoData({
    this.telar = '',
    this.articulo = '',
    this.hilo = '',
    this.titulo = '',
    this.metraje = '',
    this.fechaInicio = '',
    this.fechaFinal = '',
    this.pesoTotal = '',
  });

  factory IngresoTelarProgresoData.fromMap(Map<String, dynamic> map) {
    return IngresoTelarProgresoData(
      telar: (map['telar'] ?? '').toString().trim(),
      articulo: (map['articulo'] ?? '').toString().trim(),
      hilo: (map['hilo'] ?? '').toString().trim(),
      titulo: (map['titulo'] ?? '').toString().trim(),
      metraje: (map['metraje'] ?? '').toString().trim(),
      fechaInicio: (map['fecha_inicio'] ?? '').toString().trim(),
      fechaFinal: (map['fecha_final'] ?? '').toString().trim(),
      pesoTotal: (map['peso_total'] ?? '').toString().trim(),
    );
  }

  bool get hasData =>
      telar.isNotEmpty ||
      articulo.isNotEmpty ||
      hilo.isNotEmpty ||
      titulo.isNotEmpty ||
      metraje.isNotEmpty ||
      fechaInicio.isNotEmpty ||
      fechaFinal.isNotEmpty ||
      pesoTotal.isNotEmpty;

  Map<String, String> toFields() {
    return {
      'telar': telar,
      'articulo': articulo,
      'hilo': hilo,
      'titulo': titulo,
      'metraje': metraje,
      'fecha_inicio': fechaInicio,
      'fecha_final': fechaFinal,
      'peso_total': pesoTotal,
    };
  }
}

class UrdidoHistorialTablaItem {
  final String codigoUrdido;
  final String articulo;
  final String metrosUrdido;
  final String pesoHilosUrdido;
  final String fecha;

  const UrdidoHistorialTablaItem({
    this.codigoUrdido = '',
    this.articulo = '',
    this.metrosUrdido = '',
    this.pesoHilosUrdido = '',
    this.fecha = '',
  });

  factory UrdidoHistorialTablaItem.fromMap(Map<String, dynamic> map) {
    return UrdidoHistorialTablaItem(
      codigoUrdido: (map['codigo_urdido'] ?? '').toString().trim(),
      articulo: (map['articulo'] ?? '').toString().trim(),
      metrosUrdido: (map['metros_urdido'] ?? '').toString().trim(),
      pesoHilosUrdido: (map['peso_hilos_urdido'] ?? '').toString().trim(),
      fecha: (map['fecha'] ?? '').toString().trim(),
    );
  }
}

class TelarHistorialTablaItem {
  final String telar;
  final String articulo;
  final String hilos;
  final String mts;
  final String titulo;
  final String caract;
  final String parcial;
  final String fechaInicio;
  final String pesoTotal;
  final String estado;

  const TelarHistorialTablaItem({
    this.telar = '',
    this.articulo = '',
    this.hilos = '',
    this.mts = '',
    this.titulo = '',
    this.caract = '',
    this.parcial = '',
    this.fechaInicio = '',
    this.pesoTotal = '',
    this.estado = '',
  });

  factory TelarHistorialTablaItem.fromMap(Map<String, dynamic> map) {
    return TelarHistorialTablaItem(
      telar: (map['telar'] ?? '').toString().trim(),
      articulo: (map['articulo'] ?? '').toString().trim(),
      hilos: (map['hilos'] ?? '').toString().trim(),
      mts: (map['mts'] ?? map['metraje'] ?? '').toString().trim(),
      titulo: (map['titulo'] ?? '').toString().trim(),
      caract: (map['caract'] ?? '').toString().trim(),
      parcial: (map['parcial'] ?? '').toString().trim(),
      fechaInicio: (map['fecha_inicio'] ?? '').toString().trim(),
      pesoTotal: (map['peso_total'] ?? '').toString().trim(),
      estado: (map['estado'] ?? '').toString().trim(),
    );
  }
}

class TelaCrudaHistorialItem {
  final String fecha;
  final String hora;
  final String codTela;
  final String op;
  final String articulo;
  final String telar;
  final String plegador;
  final String cc;
  final String metro;
  final String peso;
  final String fechaRevisado;
  final String rendimiento;
  final String validacionRendimiento;

  const TelaCrudaHistorialItem({
    this.fecha = '',
    this.hora = '',
    this.codTela = '',
    this.op = '',
    this.articulo = '',
    this.telar = '',
    this.plegador = '',
    this.cc = '',
    this.metro = '',
    this.peso = '',
    this.fechaRevisado = '',
    this.rendimiento = '',
    this.validacionRendimiento = '',
  });

  factory TelaCrudaHistorialItem.fromMap(Map<String, dynamic> map) {
    return TelaCrudaHistorialItem(
      fecha: (map['fecha'] ?? '').toString().trim(),
      hora: (map['hora'] ?? '').toString().trim(),
      codTela: (map['codtela'] ?? map['codTela'] ?? '').toString().trim(),
      op: (map['op'] ?? '').toString().trim(),
      articulo: (map['articulo'] ?? '').toString().trim(),
      telar: (map['telar'] ?? '').toString().trim(),
      plegador: (map['plegador'] ?? '').toString().trim(),
      cc: (map['cc'] ?? '').toString().trim(),
      metro: (map['metro'] ?? '').toString().trim(),
      peso: (map['peso'] ?? '').toString().trim(),
      fechaRevisado: (map['fecha_revisado'] ?? '').toString().trim(),
      rendimiento: (map['rendimiento'] ?? '').toString().trim(),
      validacionRendimiento:
          (map['val_rendimiento'] ?? map['validacion_rendimiento'] ?? '')
              .toString()
              .trim(),
    );
  }

  bool get rendimientoFuera {
    final raw = '$rendimiento $validacionRendimiento'.toUpperCase();
    return raw.contains('FUERA');
  }
}

class HistorialAdminItem {
  final String fecha;
  final String hora;
  final String codigoKardex;
  final String codigo;
  final String almacen;
  final String ubicacion;
  final String movimiento;

  const HistorialAdminItem({
    this.fecha = '',
    this.hora = '',
    this.codigoKardex = '',
    this.codigo = '',
    this.almacen = '',
    this.ubicacion = '',
    this.movimiento = '',
  });

  factory HistorialAdminItem.fromMap(Map<String, dynamic> map) {
    return HistorialAdminItem(
      fecha: (map['fecha'] ?? '').toString().trim(),
      hora: (map['hora'] ?? '').toString().trim(),
      codigoKardex:
          (map['codigoKardex'] ?? map['codigo_kardex'] ?? '---------')
              .toString()
              .trim(),
      codigo: (map['codigo'] ?? map['codigoPCP'] ?? '').toString().trim(),
      almacen: (map['almacen'] ?? '').toString().trim(),
      ubicacion: (map['ubicacion'] ?? '').toString().trim(),
      movimiento: (map['movimiento'] ?? '').toString().trim(),
    );
  }
}

class ProduccionRemoteDatasource {
  final ApiClient _client;
  final LocalStorage _storage;

  const ProduccionRemoteDatasource(this._client, this._storage);

  Future<ProduccionCatalogosData> obtenerDatosGenerales() async {
    final response = await _client.post(
      ApiRoutes.obtenerDatosGenerales,
      data: ApiPayloads.obtenerDatosGenerales(),
    );

    if (!response.success) {
      throw Exception(
        response.message ?? 'No se pudo cargar catalogos de produccion',
      );
    }

    final map = _normalizeMap(response.responseData);
    return ProduccionCatalogosData(
      articulos: _extractStringList(map['articulos']),
      colores: _extractStringList(map['colores']),
      materiales: _extractStringList(map['materiales']),
      titulos: _extractStringList(map['titulo_materiales']),
    );
  }

  Future<List<String>> buscarUrdidoPorCodigoPcp(String codigoPcp) async {
    final codigo = codigoPcp.trim();
    if (codigo.isEmpty) {
      throw Exception('Ingrese codigo PCP para escanear urdido');
    }

    final response = await _client.post(
      ApiRoutes.urdidoScan,
      data: ApiPayloads.buscarProduccionPorCodigo(codigo),
    );
    if (!response.success) {
      throw Exception(
        response.message ?? 'No se pudo consultar datos de urdido',
      );
    }

    return _extractDataList(response.responseData);
  }

  Future<List<String>> buscarUrdidoParaEngomado(String codigoPcp) async {
    final codigo = codigoPcp.trim();
    if (codigo.isEmpty) {
      throw Exception('Ingrese codigo PCP para consultar urdido');
    }

    final response = await _client.post(
      ApiRoutes.engomadoUrdidoSearch,
      data: ApiPayloads.buscarProduccionPorCodigo(codigo),
    );
    if (!response.success) {
      throw Exception(response.message ?? 'No se pudo consultar urdido');
    }

    return _extractDataList(response.responseData);
  }

  Future<String> enviarUrdido(Map<String, dynamic> payload) async {
    final response = await _client.post(ApiRoutes.urdidoSend, data: payload);
    if (!response.success) {
      throw Exception(response.message ?? 'No se pudo enviar registro urdido');
    }
    return _extractMessage(response);
  }

  Future<String> enviarEngomado(Map<String, dynamic> payload) async {
    final response = await _client.post(ApiRoutes.engomadoData, data: payload);
    if (!response.success) {
      throw Exception(
        response.message ?? 'No se pudo enviar registro engomado',
      );
    }
    return _extractMessage(response);
  }

  Future<TelaresSearchData> buscarTelaresPorCodigoPcp(String codigoPcp) async {
    final codigo = codigoPcp.trim();
    if (codigo.isEmpty) {
      throw Exception('Ingrese codigo PCP para consultar telares');
    }

    final localAttempt = await _tryLocalTelares(
      ApiRoutes.telarSearch,
      ApiPayloads.buscarProduccionPorCodigo(codigo),
    );
    if (localAttempt?.response.success == true) {
      return TelaresSearchData(
        raw: _extractDataList(localAttempt!.response.responseData),
      );
    }

    final response = await _client.post(
      ApiRoutes.telarSearch,
      data: ApiPayloads.buscarProduccionPorCodigo(codigo),
    );
    if (!response.success) {
      final localError = localAttempt?.errorMessage;
      throw Exception(
        localError == null || localError.isEmpty
            ? (response.message ?? 'No se pudo consultar datos de telares')
            : '${response.message ?? 'No se pudo consultar datos de telares'} '
                '(local: $localError)',
      );
    }

    return TelaresSearchData(raw: _extractDataList(response.responseData));
  }

  Future<String> enviarTelares(Map<String, dynamic> payload) async {
    final localAttempt = await _tryLocalTelares(ApiRoutes.telarSend, payload);
    if (localAttempt?.response.success == true) {
      return _extractMessage(localAttempt!.response);
    }

    final response = await _client.post(ApiRoutes.telarSend, data: payload);
    if (!response.success) {
      final localError = localAttempt?.errorMessage;
      throw Exception(
        localError == null || localError.isEmpty
            ? (response.message ?? 'No se pudo enviar registro de telares')
            : '${response.message ?? 'No se pudo enviar registro de telares'} '
                '(local: $localError)',
      );
    }
    return _extractMessage(response);
  }

  Future<IngresoTelarProgresoData?> cargarProgresoIngresoTelar(
    String operario,
  ) async {
    final safeOperario = operario.trim();
    if (safeOperario.isEmpty) {
      return null;
    }

    final response = await _client.get(
      '${ApiRoutes.telarCargarProgreso}?operario=${Uri.encodeQueryComponent(safeOperario)}',
    );
    if (!response.success) {
      final message = (response.message ?? '').trim().toLowerCase();
      if (message == 'sin_progreso') {
        return null;
      }
      throw Exception(
        response.message ?? 'No se pudo cargar progreso de telar',
      );
    }

    final root = _normalizeMap(response.data);
    final message = (root['message'] ?? '').toString().trim().toLowerCase();
    if (message == 'sin_progreso') {
      return null;
    }
    if (message != 'ok') {
      throw Exception(
        message.isEmpty ? 'No se pudo cargar progreso de telar' : message,
      );
    }

    final data = _normalizeMap(root['data']);
    final parsed = IngresoTelarProgresoData.fromMap(data);
    if (!parsed.hasData) {
      return null;
    }
    return parsed;
  }

  Future<String> obtenerArticuloActualTelar(String telar) async {
    final safeTelar = telar.trim();
    if (safeTelar.isEmpty) {
      return '';
    }

    final response = await _client.get(
      '${ApiRoutes.telarArticuloActual}?telar=${Uri.encodeQueryComponent(safeTelar)}',
    );
    if (!response.success) {
      throw Exception(
        response.message ?? 'No se pudo consultar articulo actual del telar',
      );
    }

    final root = _normalizeMap(response.data);
    final message = (root['message'] ?? '').toString().trim().toLowerCase();
    if (message == 'ok') {
      return (root['articulo'] ?? '').toString().trim();
    }
    if (message == 'no_encontrado') {
      return '';
    }

    final articulo = (root['articulo'] ?? '').toString().trim();
    if (articulo.isNotEmpty) {
      return articulo;
    }

    if (message.isNotEmpty) {
      throw Exception(message);
    }
    return '';
  }

  Future<String> enviarIngresoTelar(Map<String, dynamic> payload) async {
    final response = await _client.post(ApiRoutes.telarIngreso, data: payload);
    if (!response.success) {
      throw Exception(
        response.message ?? 'No se pudo guardar el registro de ingreso telar',
      );
    }
    return _extractMessage(response);
  }

  Future<String> consultarHistorialUrdidoOperario(String operario) async {
    final response = await _client.post(
      ApiRoutes.urdidoHistorial,
      data: ApiPayloads.urdidoHistorial(operario: operario),
    );
    if (!response.success) {
      throw Exception(
        response.message ?? 'No se pudo consultar historial urdido',
      );
    }

    final root = _normalizeMap(response.data);
    return (root['message'] ?? response.responseMessage).toString().trim();
  }

  Future<List<UrdidoHistorialTablaItem>> consultarHistorialUrdidoTabla(
    String urdidora,
  ) async {
    final response = await _client.get(
      '${ApiRoutes.urdidoHistorialTabla}?urdidora=${Uri.encodeQueryComponent(urdidora.trim())}',
    );
    if (!response.success) {
      throw Exception(
        response.message ?? 'No se pudo consultar tabla de historial urdido',
      );
    }

    final root = _normalizeMap(response.data);
    final list = _extractMapList(root['data'] ?? response.responseData);
    return list.map(UrdidoHistorialTablaItem.fromMap).toList();
  }

  Future<List<TelarHistorialTablaItem>> consultarHistorialTelarTabla(
    String telar,
  ) async {
    final safeTelar = telar.trim().isEmpty ? 'TODOS' : telar.trim();
    final response = await _client.get(
      '${ApiRoutes.telarHistorialTabla}?telar=${Uri.encodeQueryComponent(safeTelar)}',
    );
    if (!response.success) {
      throw Exception(
        response.message ?? 'No se pudo consultar tabla de historial telar',
      );
    }

    final root = _normalizeMap(response.data);
    final list = _extractMapList(root['data'] ?? response.responseData);
    return list.map(TelarHistorialTablaItem.fromMap).toList();
  }

  Future<String> generarKardex({
    required String material,
    required String titulo,
    required String color,
  }) async {
    final safeMaterial = material.trim();
    final safeTitulo = titulo.trim();
    final safeColor = color.trim();
    if (safeMaterial.isEmpty || safeTitulo.isEmpty || safeColor.isEmpty) {
      throw Exception('Faltan MATERIAL, TITULO Y/O COLOR');
    }

    final response = await _client.post(
      ApiRoutes.generarKardex,
      data: ApiPayloads.generarKardex(
        material: safeMaterial,
        titulo: safeTitulo,
        color: safeColor,
      ),
    );
    if (!response.success) {
      throw Exception(response.message ?? 'No se pudo generar kardex');
    }

    final root = _normalizeMap(response.data);
    final kardex = (root['kardex'] ?? '').toString().trim();
    if (kardex.isEmpty) {
      throw Exception('El backend no retorno codigo kardex');
    }
    return kardex;
  }

  Future<List<TelaCrudaHistorialItem>> consultarHistorialTelaCruda(
    String nombre,
  ) async {
    final safeNombre = nombre.trim();
    if (safeNombre.isEmpty) {
      throw Exception('Ingrese usuario para consultar historial de tela cruda');
    }

    final response = await _client.post(
      ApiRoutes.consultaHistorialTelaCruda,
      data: ApiPayloads.consultaHistorialTelaCruda(nombre: safeNombre),
    );
    if (!response.success) {
      throw Exception(
        response.message ?? 'No se pudo consultar historial de tela cruda',
      );
    }

    final root = _normalizeMap(response.data);
    final list = _extractMapList(root['data'] ?? response.responseData);
    return list.map(TelaCrudaHistorialItem.fromMap).toList();
  }

  Future<List<String>> cargarUsuariosHistorialAdmin() async {
    final response = await _client.get(
      '${ApiRoutes.readColumn}?sheet=datos&column=8',
    );
    if (!response.success) {
      throw Exception(
        response.message ?? 'No se pudo cargar usuarios para historial',
      );
    }

    final rawUsers = _extractStringList(response.responseData);
    if (rawUsers.isEmpty) {
      return const [];
    }

    var users = rawUsers;
    final first = users.first.trim().toLowerCase();
    if (first.contains('nombre') || first.contains('usuario')) {
      users = users.skip(1).toList();
    }

    final seen = <String>{};
    return users
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .where((item) => seen.add(item.toUpperCase()))
        .toList(growable: false);
  }

  Future<List<HistorialAdminItem>> consultarHistorialAdmin(
    String usuario,
  ) async {
    final safeUsuario = usuario.trim();
    if (safeUsuario.isEmpty) {
      throw Exception('Seleccione usuario para buscar inventario');
    }

    final dio = Dio(
      BaseOptions(
        connectTimeout: Duration(seconds: EnvironmentConfig.connectTimeout),
        receiveTimeout: Duration(seconds: EnvironmentConfig.receiveTimeout),
        headers: const {'Accept': 'application/json'},
      ),
    );

    try {
      final url =
          Uri.parse(
            ApiRoutes.historialAdminScriptUrl,
          ).replace(queryParameters: {'usuario': safeUsuario}).toString();
      final response = await dio.get(url);
      final list = _extractMapList(response.data);
      return list.map(HistorialAdminItem.fromMap).toList();
    } on DioException catch (error) {
      final message = _extractErrorFromData(error.response?.data);
      throw Exception(
        message.isNotEmpty
            ? message
            : 'No se pudo consultar historial administrativo',
      );
    }
  }

  Future<_LocalTelaresAttempt?> _tryLocalTelares(
    String endpoint,
    Map<String, dynamic> payload,
  ) async {
    final candidates = _buildTelaresLocalCandidates();
    String? lastError;

    for (final baseUrl in candidates) {
      final dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: Duration(
            seconds: EnvironmentConfig.localConnectTimeout,
          ),
          receiveTimeout: Duration(
            seconds: EnvironmentConfig.localReceiveTimeout,
          ),
          headers: const {'Content-Type': 'application/json'},
        ),
      );

      try {
        final response = await dio.post(endpoint, data: payload);
        return _LocalTelaresAttempt(
          baseUrl: baseUrl,
          response: ApiResponse.success(
            response.data,
            response.statusCode ?? 200,
          ),
        );
      } on DioException catch (error) {
        if (_isConnectivityError(error)) {
          lastError = 'sin conexion a $baseUrl';
          continue;
        }

        final statusCode = error.response?.statusCode ?? 0;
        final mapError = _extractErrorFromData(error.response?.data);
        return _LocalTelaresAttempt(
          baseUrl: baseUrl,
          response: ApiResponse.error(
            mapError.isNotEmpty ? mapError : 'HTTP $statusCode',
            statusCode: statusCode,
          ),
          errorMessage: mapError.isNotEmpty ? mapError : 'HTTP $statusCode',
        );
      } catch (_) {
        lastError = 'error inesperado en $baseUrl';
      }
    }

    if (lastError == null || lastError.isEmpty) {
      return null;
    }
    return _LocalTelaresAttempt(
      baseUrl: '',
      response: ApiResponse.error(lastError),
      errorMessage: lastError,
    );
  }

  List<String> _buildTelaresLocalCandidates() {
    final seen = <String>{};
    final candidates = <String>[];

    void add(String raw) {
      final normalized = _normalizeBaseUrl(raw);
      if (normalized == null) return;
      final key = normalized.toLowerCase();
      if (seen.add(key)) {
        candidates.add(normalized);
      }
    }

    add(_storage.telaresLocalApiUrl);
    add(EnvironmentConfig.telaresLocalApiUrl);
    for (final fallback in EnvironmentConfig.telaresLocalApiFallbackUrls) {
      add(fallback);
    }

    return candidates;
  }

  String? _normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final normalized =
        trimmed.endsWith('/')
            ? trimmed.substring(0, trimmed.length - 1)
            : trimmed;
    final uri = Uri.tryParse(normalized);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return null;
    }
    return normalized;
  }

  bool _isConnectivityError(DioException error) {
    return error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout;
  }

  String _extractErrorFromData(dynamic data) {
    if (data is Map) {
      final message =
          (data['message'] ?? data['error'] ?? '').toString().trim();
      if (message.isNotEmpty) {
        return message;
      }
    }
    if (data is String) {
      final message = data.trim();
      if (message.isNotEmpty) {
        return message;
      }
    }
    return '';
  }

  String _extractMessage(ApiResponse response) {
    final data = response.responseData;
    if (data is Map) {
      final message = (data['message'] ?? data['mensaje'] ?? '').toString();
      if (message.trim().isNotEmpty) {
        return message.trim();
      }
    }
    final fallback = response.responseMessage.trim();
    if (fallback.isNotEmpty) {
      return fallback;
    }
    return 'Registro enviado correctamente';
  }

  Map<String, dynamic> _normalizeMap(dynamic input) {
    if (input is Map<String, dynamic>) {
      return input;
    }
    if (input is Map) {
      return input.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }

  List<String> _extractDataList(dynamic input) {
    if (input is List) {
      return input.map((item) => item.toString()).toList();
    }

    if (input is Map) {
      final directData = input['data'] ?? input['result'];
      if (directData is List) {
        return directData.map((item) => item.toString()).toList();
      }
      if (directData is String) {
        return _splitCsvLoose(directData);
      }
    }

    if (input is String) {
      final text = input.trim();
      if (text.isEmpty) {
        return const [];
      }

      // Algunos endpoints legacy pueden responder data como string JSON.
      try {
        final decoded = jsonDecode(text);
        if (decoded is List) {
          return decoded.map((item) => item.toString()).toList();
        }
      } catch (_) {
        // Fallback a separacion por coma si no es JSON.
      }
      return _splitCsvLoose(text);
    }

    return const [];
  }

  List<Map<String, dynamic>> _extractMapList(dynamic input) {
    if (input is List) {
      return input
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
    }
    if (input is Map) {
      final data = input['data'] ?? input['result'];
      if (data is List) {
        return data
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList(growable: false);
      }
    }
    if (input is String) {
      try {
        final decoded = jsonDecode(input);
        return _extractMapList(decoded);
      } catch (_) {
        return const [];
      }
    }
    return const [];
  }

  List<String> _splitCsvLoose(String raw) {
    return raw
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  List<String> _extractStringList(dynamic input) {
    if (input is List) {
      return input
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    if (input is Map) {
      final data = input['data'] ?? input['result'] ?? input['values'];
      return _extractStringList(data);
    }
    if (input is String) {
      try {
        final decoded = jsonDecode(input);
        final list = _extractStringList(decoded);
        if (list.isNotEmpty) {
          return list;
        }
      } catch (_) {
        // Fallback a CSV legacy.
      }
      return _splitCsvLoose(input);
    }
    return const [];
  }
}

class _LocalTelaresAttempt {
  final String baseUrl;
  final ApiResponse response;
  final String? errorMessage;

  const _LocalTelaresAttempt({
    required this.baseUrl,
    required this.response,
    this.errorMessage,
  });
}
