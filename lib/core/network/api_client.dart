/// ============================================================================
/// CLIENTE HTTP CENTRALIZADO - CoolImport S.A.C.
/// ============================================================================
/// Servicio centralizado de API que reemplaza los componentes Web de MIT App
/// Inventor. Maneja:
///   - Requests a PythonAnywhere (backend principal)
///   - Requests a API local para impresion
///   - Reintentos automaticos
///   - Timeout configurable
///   - Logging de requests/responses
///   - Manejo de errores unificado
/// ============================================================================

import 'package:dio/dio.dart';

import '../config/environment.dart';
import '../storage/local_storage.dart';

/// Cliente HTTP para el backend PRINCIPAL (PythonAnywhere)
class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: EnvironmentConfig.baseUrl,
        connectTimeout: Duration(seconds: EnvironmentConfig.connectTimeout),
        receiveTimeout: Duration(seconds: EnvironmentConfig.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    if (EnvironmentConfig.enableLogging) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (obj) => print('API: $obj'),
        ),
      );
    }

    _dio.interceptors.add(_RetryInterceptor(_dio));
  }

  Future<ApiResponse> post(
    String endpoint, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _dio.post(endpoint, data: data);
      return ApiResponse.success(response.data, response.statusCode ?? 200);
    } on DioException catch (error) {
      return _handleDioError(error);
    } catch (error) {
      return ApiResponse.error('Error inesperado: $error');
    }
  }

  Future<ApiResponse> get(String endpoint) async {
    try {
      final response = await _dio.get(endpoint);
      return ApiResponse.success(response.data, response.statusCode ?? 200);
    } on DioException catch (error) {
      return _handleDioError(error);
    } catch (error) {
      return ApiResponse.error('Error inesperado: $error');
    }
  }

  ApiResponse _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return ApiResponse.error(
          'Tiempo de conexion agotado. Verifica tu conexion a internet.',
        );
      case DioExceptionType.receiveTimeout:
        return ApiResponse.error(
          'El servidor tardo mucho en responder. Intenta de nuevo.',
        );
      case DioExceptionType.connectionError:
        return ApiResponse.error(
          'No se puede conectar al servidor. Verifica tu WiFi.',
        );
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 0;
        final responseData = error.response?.data;
        String message = 'Error del servidor';

        if (responseData is Map) {
          message =
              (responseData['error'] ??
                      responseData['message'] ??
                      'Error $statusCode')
                  .toString();
        } else if (responseData is String) {
          message = responseData;
        }

        return ApiResponse.error(message, statusCode: statusCode);
      default:
        return ApiResponse.error('Error de conexion: ${error.message}');
    }
  }
}

class LocalApiHealthReport {
  final bool available;
  final String configuredBaseUrl;
  final String? activeBaseUrl;
  final List<String> candidateBaseUrls;
  final String message;

  const LocalApiHealthReport({
    required this.available,
    required this.configuredBaseUrl,
    required this.activeBaseUrl,
    required this.candidateBaseUrls,
    required this.message,
  });
}

/// Cliente HTTP para la API LOCAL (Zebra + Epson).
/// Soporta URL configurable por admin y fallback de hosts.
class LocalApiClient {
  final LocalStorage _storage;

  LocalApiClient(this._storage);

  Future<bool> isAvailable() async {
    final health = await checkHealth();
    return health.available;
  }

  Future<LocalApiHealthReport> checkHealth() async {
    final candidates = _candidateBaseUrls();
    final configured = _configuredBaseUrl;
    var lastError = '';

    for (final baseUrl in candidates) {
      final dio = _buildDio(baseUrl);
      try {
        final response = await dio.get('/health');
        if (response.statusCode == 200) {
          return LocalApiHealthReport(
            available: true,
            configuredBaseUrl: configured,
            activeBaseUrl: baseUrl,
            candidateBaseUrls: candidates,
            message:
                baseUrl == configured
                    ? 'API local disponible'
                    : 'API local disponible por fallback ($baseUrl)',
          );
        }
        lastError = 'Respuesta invalida en $baseUrl';
      } catch (_) {
        lastError = 'Sin conexion a $baseUrl';
      }
    }

    return LocalApiHealthReport(
      available: false,
      configuredBaseUrl: configured,
      activeBaseUrl: null,
      candidateBaseUrls: candidates,
      message:
          lastError.isNotEmpty
              ? lastError
              : 'API local no disponible en esta red',
    );
  }

  String get configuredBaseUrl => _configuredBaseUrl;

  String get _configuredBaseUrl {
    final fromStorage = _sanitizeBaseUrl(_storage.localApiUrl);
    if (fromStorage != null) {
      return fromStorage;
    }
    return _sanitizeBaseUrl(EnvironmentConfig.localApiUrl)!;
  }

  List<String> _candidateBaseUrls() {
    final ordered = <String>[];
    final seen = <String>{};

    void addCandidate(String raw) {
      final sanitized = _sanitizeBaseUrl(raw);
      if (sanitized == null) return;
      final key = sanitized.toLowerCase();
      if (seen.add(key)) {
        ordered.add(sanitized);
      }
    }

    addCandidate(_storage.localApiUrl);
    addCandidate(EnvironmentConfig.localApiUrl);
    for (final fallback in EnvironmentConfig.localApiFallbackUrls) {
      addCandidate(fallback);
    }

    return ordered;
  }

  Dio _buildDio(String baseUrl) {
    return Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: Duration(
          seconds: EnvironmentConfig.localConnectTimeout,
        ),
        receiveTimeout: Duration(
          seconds: EnvironmentConfig.localReceiveTimeout,
        ),
        headers: {'Content-Type': 'application/json'},
      ),
    );
  }

  String? _sanitizeBaseUrl(String raw) {
    final trimmed = raw.trim();
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

  ApiResponse _mapLocalError(
    DioException error, {
    required String baseUrl,
    required bool canRetryWithFallback,
  }) {
    if (_isConnectivityError(error)) {
      final suffix = canRetryWithFallback ? ' Probando host alterno...' : '';
      return ApiResponse.error('No se puede conectar a $baseUrl.$suffix');
    }

    if (error.type == DioExceptionType.badResponse) {
      final statusCode = error.response?.statusCode ?? 0;
      final data = error.response?.data;
      if (data is Map) {
        final msg = (data['message'] ?? data['error'] ?? '').toString().trim();
        if (msg.isNotEmpty) {
          return ApiResponse.error(msg, statusCode: statusCode);
        }
      }
      if (data is String && data.trim().isNotEmpty) {
        return ApiResponse.error(data.trim(), statusCode: statusCode);
      }
      return ApiResponse.error(
        'Error de impresion HTTP $statusCode',
        statusCode: statusCode,
      );
    }

    return ApiResponse.error('Error de impresion: ${error.message}');
  }

  bool _shouldTryNextHost(ApiResponse response) {
    final text = (response.message ?? '').toLowerCase();
    return text.contains('no se puede conectar') ||
        text.contains('timeout') ||
        text.contains('sin conexion');
  }

  Future<ApiResponse> post(
    String endpoint, {
    Map<String, dynamic>? data,
  }) async {
    final candidates = _candidateBaseUrls();
    ApiResponse? lastResponse;

    for (var i = 0; i < candidates.length; i++) {
      final baseUrl = candidates[i];
      final canRetry = i < candidates.length - 1;
      final dio = _buildDio(baseUrl);

      try {
        final response = await dio.post(endpoint, data: data);
        return ApiResponse.success(response.data, response.statusCode ?? 200);
      } on DioException catch (error) {
        final mapped = _mapLocalError(
          error,
          baseUrl: baseUrl,
          canRetryWithFallback: canRetry,
        );
        lastResponse = mapped;
        if (!canRetry || !_shouldTryNextHost(mapped)) {
          return mapped;
        }
      } catch (error) {
        lastResponse = ApiResponse.error('Error inesperado: $error');
        if (!canRetry) {
          return lastResponse;
        }
      }
    }

    return lastResponse ??
        ApiResponse.error(
          'No se pudo conectar a la API local. '
          'Verifica que la PC de impresion este encendida y en la red.',
        );
  }
}

/// Wrapper de respuesta unificado.
class ApiResponse {
  final bool success;
  final dynamic data;
  final String? message;
  final int statusCode;

  ApiResponse._({
    required this.success,
    this.data,
    this.message,
    this.statusCode = 200,
  });

  factory ApiResponse.success(dynamic data, int statusCode) {
    return ApiResponse._(success: true, data: data, statusCode: statusCode);
  }

  factory ApiResponse.error(String message, {int statusCode = 0}) {
    return ApiResponse._(
      success: false,
      message: message,
      statusCode: statusCode,
    );
  }

  dynamic get responseData {
    if (data is Map) {
      return data['data'] ?? data['result'] ?? data;
    }
    return data;
  }

  String get responseMessage {
    if (data is Map) {
      return data['message'] ?? data['error'] ?? message ?? '';
    }
    return message ?? '';
  }
}

/// Interceptor de reintentos automaticos.
class _RetryInterceptor extends Interceptor {
  final Dio _dio;
  int _retryCount = 0;

  _RetryInterceptor(this._dio);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final shouldRetry =
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        (err.response?.statusCode == 502) ||
        (err.response?.statusCode == 504);

    if (shouldRetry && _retryCount < EnvironmentConfig.maxRetries) {
      _retryCount++;
      print('Reintento #$_retryCount para ${err.requestOptions.path}');

      await Future.delayed(
        Duration(milliseconds: EnvironmentConfig.retryDelayMs * _retryCount),
      );

      try {
        final response = await _dio.fetch(err.requestOptions);
        _retryCount = 0;
        return handler.resolve(response);
      } catch (_) {
        // Se mantiene flujo normal para siguiente intento o error final.
      }
    }

    _retryCount = 0;
    return handler.next(err);
  }
}
