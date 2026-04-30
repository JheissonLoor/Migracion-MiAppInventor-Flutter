import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_constants.dart';
import '../../core/storage/local_storage.dart';
import '../../core/utils/qr_parser.dart';
import '../../data/datasources/remote/produccion_remote_datasource.dart';
import '../../data/models/almacen_mov_queue_models.dart';
import '../../data/models/produccion_queue_models.dart';
import 'auth_provider.dart';

enum UrdidoStatus {
  idle,
  loadingCatalogs,
  loadingScanData,
  sending,
  queueing,
  drainingQueue,
  success,
  error,
}

class UrdidoState {
  final UrdidoStatus status;
  final Map<String, String> fields;
  final List<String> articulos;
  final List<String> colores;
  final List<String> materiales;
  final List<String> titulos;
  final List<UrdidoQueueJobModel> queue;
  final QueueTelemetryModel telemetry;
  final String? message;
  final String? errorMessage;

  const UrdidoState({
    this.status = UrdidoStatus.idle,
    this.fields = const {},
    this.articulos = const [],
    this.colores = const [],
    this.materiales = const [],
    this.titulos = const [],
    this.queue = const [],
    this.telemetry = const QueueTelemetryModel(),
    this.message,
    this.errorMessage,
  });

  bool get isBusy =>
      status == UrdidoStatus.loadingCatalogs ||
      status == UrdidoStatus.loadingScanData ||
      status == UrdidoStatus.sending ||
      status == UrdidoStatus.queueing ||
      status == UrdidoStatus.drainingQueue;

  int get pendingQueue => queue.length;

  UrdidoState copyWith({
    UrdidoStatus? status,
    Map<String, String>? fields,
    List<String>? articulos,
    List<String>? colores,
    List<String>? materiales,
    List<String>? titulos,
    List<UrdidoQueueJobModel>? queue,
    QueueTelemetryModel? telemetry,
    String? message,
    bool clearMessage = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return UrdidoState(
      status: status ?? this.status,
      fields: fields ?? this.fields,
      articulos: articulos ?? this.articulos,
      colores: colores ?? this.colores,
      materiales: materiales ?? this.materiales,
      titulos: titulos ?? this.titulos,
      queue: queue ?? this.queue,
      telemetry: telemetry ?? this.telemetry,
      message: clearMessage ? null : (message ?? this.message),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final urdidoRemoteDatasourceProvider = Provider<ProduccionRemoteDatasource>(
  (ref) => ProduccionRemoteDatasource(
    ref.read(apiClientProvider),
    ref.read(localStorageProvider),
  ),
);

class UrdidoNotifier extends StateNotifier<UrdidoState> {
  final ProduccionRemoteDatasource _datasource;
  final LocalStorage _storage;
  bool _submitLock = false;

  UrdidoNotifier(this._datasource, this._storage)
    : super(
        UrdidoState(fields: Map<String, String>.from(_defaultUrdidoFields)),
      ) {
    _bootstrap();
  }

  void _bootstrap() {
    _loadQueueAndTelemetry();
    cargarCatalogos();
  }

  void actualizarCampo(String key, String value) {
    final updated = Map<String, String>.from(state.fields);
    updated[key] = value;
    state = state.copyWith(
      fields: updated,
      status: UrdidoStatus.idle,
      clearError: true,
      clearMessage: true,
    );
  }

  Future<void> cargarCatalogos() async {
    if (state.isBusy) return;

    state = state.copyWith(
      status: UrdidoStatus.loadingCatalogs,
      clearError: true,
      clearMessage: true,
    );

    try {
      final data = await _datasource.obtenerDatosGenerales();

      state = state.copyWith(
        status: UrdidoStatus.success,
        articulos: data.articulos,
        colores: data.colores,
        materiales: data.materiales,
        titulos: data.titulos,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        status: UrdidoStatus.error,
        errorMessage: _cleanError(error),
      );
    }
  }

  Future<void> buscarDesdeQr(String qrRaw) async {
    if (state.isBusy) return;

    final codigoPcp = _extractCodigoPcp(qrRaw);
    if (codigoPcp.isEmpty) {
      state = state.copyWith(
        status: UrdidoStatus.error,
        errorMessage: 'QR invalido: no se encontro codigo PCP',
      );
      return;
    }

    state = state.copyWith(
      status: UrdidoStatus.loadingScanData,
      clearError: true,
      clearMessage: true,
    );

    try {
      final data = await _datasource.buscarUrdidoPorCodigoPcp(codigoPcp);
      if (data.isEmpty) {
        throw Exception('No se encontraron datos de urdido para este codigo');
      }

      final updated = Map<String, String>.from(state.fields);
      updated['codigo_pcp'] = codigoPcp;
      updated['codigo_urdido'] = _at(data, 3);
      updated['operario'] = _at(data, 5);
      updated['ayudante_operario'] = _at(data, 6);
      updated['orden_pedido'] = _at(data, 7);
      updated['articulo'] = _at(data, 8);
      updated['fecha_urdido'] = _at(data, 10);
      updated['cantidad_hilos'] = _at(data, 12);
      updated['hora_inicio'] = _composeTime(_at(data, 1), _at(data, 2));
      updated['hora_final'] = _composeTime(_at(data, 1), _at(data, 2));
      updated['ancho_plegador'] = _at(data, 14);
      updated['metros_urdido'] = _at(data, 15);
      updated['peso_hilos_urdido'] = _at(data, 16);
      updated['cantidad_fajas'] = _at(data, 17);
      updated['hilo_cm'] = _at(data, 18);
      updated['altura'] = _at(data, 19);
      updated['peso_plegador'] = _at(data, 20);
      updated['desplazamiento'] = _at(data, 21);
      updated['tension'] = _at(data, 22);
      updated['num_plegador'] = _at(data, 23);
      updated['velo_urdido'] = _at(data, 24);
      updated['velo_plegador'] = _at(data, 25);
      updated['freno_plegador'] = _at(data, 26);
      updated['peso_merma'] = _at(data, 27);
      updated['hilo_color1'] = _at(data, 29);
      updated['hilo_color2'] = _at(data, 30);
      updated['hilo_color3'] = _at(data, 31);
      updated['hilo_color4'] = _at(data, 32);
      updated['hilo_color5'] = _at(data, 33);
      updated['hilo_color6'] = _at(data, 34);
      updated['hilo_color7'] = _at(data, 35);
      updated['giro_encerado'] = _at(data, 37);
      updated['peso_ensimaje'] = _at(data, 38);
      updated['observacion'] = _at(data, 39);

      state = state.copyWith(
        status: UrdidoStatus.success,
        fields: updated,
        message: 'Datos de urdido cargados desde escaneo',
      );
    } catch (error) {
      state = state.copyWith(
        status: UrdidoStatus.error,
        errorMessage: _cleanError(error),
      );
    }
  }

  Future<void> enviarUrdido({required String usuario}) async {
    if (_submitLock || state.isBusy) return;

    _submitLock = true;
    Map<String, dynamic>? payload;
    try {
      payload = _buildPayload(usuario);
      state = state.copyWith(
        status: UrdidoStatus.sending,
        clearError: true,
        clearMessage: true,
      );

      final message = await _datasource.enviarUrdido(payload);
      state = state.copyWith(
        status: UrdidoStatus.success,
        message: message,
        clearError: true,
      );
    } catch (error) {
      final message = _cleanError(error);
      if (payload != null && _debeEncolar(message)) {
        await _encolar(payload, usuario, message);
      } else {
        state = state.copyWith(
          status: UrdidoStatus.error,
          errorMessage: message,
        );
      }
    } finally {
      _submitLock = false;
    }
  }

  Future<void> procesarColaPendiente({bool silent = false}) async {
    if (_submitLock || state.isBusy) return;
    if (state.queue.isEmpty) {
      if (!silent) {
        state = state.copyWith(
          status: UrdidoStatus.success,
          message: 'No hay urdidos pendientes en cola',
          clearError: true,
        );
      }
      return;
    }

    _submitLock = true;
    final previousStatus = state.status;
    if (!silent) {
      state = state.copyWith(
        status: UrdidoStatus.drainingQueue,
        clearError: true,
        clearMessage: true,
      );
    }

    try {
      var queue = [...state.queue];
      var telemetry = state.telemetry;
      var processed = 0;
      var failed = 0;

      while (queue.isNotEmpty) {
        final job = queue.first;
        final nowIso = DateTime.now().toIso8601String();
        try {
          await _datasource.enviarUrdido(job.payload);
          queue.removeAt(0);
          processed++;
          telemetry = telemetry.copyWith(
            processedTotal: telemetry.processedTotal + 1,
            lastProcessedAtIso: nowIso,
            lastAttemptAtIso: nowIso,
            lastError: '',
          );
        } catch (error) {
          failed++;
          queue[0] = job.copyWith(attempts: job.attempts + 1);
          telemetry = telemetry.copyWith(
            failedAttemptsTotal: telemetry.failedAttemptsTotal + 1,
            retryAttemptsTotal: telemetry.retryAttemptsTotal + 1,
            lastAttemptAtIso: nowIso,
            lastError: _cleanError(error),
          );
          break;
        }
      }

      await _guardarQueueAndTelemetry(queue, telemetry);
      state = state.copyWith(
        queue: queue,
        telemetry: telemetry,
        status:
            silent
                ? previousStatus
                : (failed == 0 ? UrdidoStatus.success : UrdidoStatus.error),
        message:
            !silent && processed > 0
                ? 'Cola procesada: $processed urdido(s). Pendientes: ${queue.length}'
                : null,
        errorMessage:
            failed > 0 && !silent
                ? 'La cola se detuvo por error. Pendientes: ${queue.length}'
                : null,
      );
    } catch (error) {
      if (!silent) {
        state = state.copyWith(
          status: UrdidoStatus.error,
          errorMessage: _cleanError(error),
        );
      }
    } finally {
      _submitLock = false;
    }
  }

  Future<void> eliminarTrabajoCola(String jobId) async {
    final updated = state.queue.where((job) => job.id != jobId).toList();
    await _guardarQueueAndTelemetry(updated, state.telemetry);
    state = state.copyWith(
      queue: updated,
      status: UrdidoStatus.idle,
      clearError: true,
      clearMessage: true,
    );
  }

  Future<void> limpiarCola() async {
    await _guardarQueueAndTelemetry(const [], state.telemetry);
    state = state.copyWith(
      queue: const [],
      status: UrdidoStatus.idle,
      message: 'Cola de urdido limpiada',
      clearError: true,
    );
  }

  void limpiarFormulario() {
    state = state.copyWith(
      status: UrdidoStatus.idle,
      fields: Map<String, String>.from(_defaultUrdidoFields),
      clearError: true,
      clearMessage: true,
    );
  }

  Future<void> _encolar(
    Map<String, dynamic> payload,
    String usuario,
    String baseError,
  ) async {
    final now = DateTime.now();
    final codigoPcp = (payload['codigo_pcp'] ?? '').toString();
    final codigoUrdido = (payload['codigo_urdido'] ?? '').toString();

    final job = UrdidoQueueJobModel(
      id: '${now.microsecondsSinceEpoch}-${state.queue.length}',
      codigoPcp: codigoPcp,
      codigoUrdido: codigoUrdido,
      usuario: usuario.trim(),
      createdAtIso: now.toIso8601String(),
      payload: payload,
    );

    final updatedQueue = [...state.queue, job];
    final updatedTelemetry = state.telemetry.copyWith(
      enqueuedTotal: state.telemetry.enqueuedTotal + 1,
      lastAttemptAtIso: now.toIso8601String(),
      lastError: baseError,
    );
    await _guardarQueueAndTelemetry(updatedQueue, updatedTelemetry);

    state = state.copyWith(
      status: UrdidoStatus.queueing,
      queue: updatedQueue,
      telemetry: updatedTelemetry,
      message: 'Sin red estable. Urdido guardado en cola segura.',
      clearError: true,
    );
  }

  Map<String, dynamic> _buildPayload(String usuario) {
    final payload = <String, dynamic>{};
    for (final entry in state.fields.entries) {
      payload[entry.key] = entry.value.trim();
    }

    if ((payload['operario'] ?? '').toString().trim().isEmpty) {
      payload['operario'] = usuario.trim();
    }
    if ((payload['tipo_proceso'] ?? '').toString().trim().isEmpty) {
      payload['tipo_proceso'] = 'Produccion';
    }
    if ((payload['numero_color_hilo'] ?? '').toString().trim().isEmpty) {
      payload['numero_color_hilo'] = '1';
    }

    final required = <String>[
      'codigo_pcp',
      'codigo_urdido',
      'turno',
      'operario',
      'orden_pedido',
      'articulo',
      'tipo_proceso',
      'fecha_urdido',
      'cantidad_hilos',
      'hora_inicio',
      'hora_final',
      'ancho_plegador',
      'metros_urdido',
      'peso_hilos_urdido',
      'num_plegador',
      'titulo',
      'material',
    ];

    final missing =
        required
            .where((key) => (payload[key] ?? '').toString().isEmpty)
            .toList();
    if (missing.isNotEmpty) {
      throw Exception(
        'Complete campos obligatorios de urdido: ${missing.join(', ')}',
      );
    }

    if ((payload['pasadas'] ?? '').toString().trim().isEmpty) {
      payload.remove('pasadas');
    }
    return payload;
  }

  bool _debeEncolar(String message) {
    final text = message.toLowerCase();
    return text.contains('no se puede conectar') ||
        text.contains('timeout') ||
        text.contains('connection') ||
        text.contains('wifi') ||
        text.contains('socket');
  }

  void _loadQueueAndTelemetry() {
    final rawQueue = _storage.getValue(
      AppConstants.keyUrdidoQueue,
      defaultValue: '',
    );
    final rawTelemetry = _storage.getValue(
      AppConstants.keyUrdidoTelemetry,
      defaultValue: '',
    );

    var queue = <UrdidoQueueJobModel>[];
    if (rawQueue.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawQueue);
        if (decoded is List) {
          queue =
              decoded
                  .whereType<Map>()
                  .map(
                    (map) => UrdidoQueueJobModel.fromJson(
                      Map<String, dynamic>.from(map),
                    ),
                  )
                  .where((job) => job.id.isNotEmpty && job.payload.isNotEmpty)
                  .toList();
        }
      } catch (_) {
        queue = <UrdidoQueueJobModel>[];
      }
    }

    var telemetry = const QueueTelemetryModel();
    if (rawTelemetry.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawTelemetry);
        if (decoded is Map) {
          telemetry = QueueTelemetryModel.fromJson(
            Map<String, dynamic>.from(decoded),
          );
        }
      } catch (_) {
        telemetry = const QueueTelemetryModel();
      }
    }

    state = state.copyWith(queue: queue, telemetry: telemetry);
  }

  Future<void> _guardarQueueAndTelemetry(
    List<UrdidoQueueJobModel> queue,
    QueueTelemetryModel telemetry,
  ) async {
    final queueJson = jsonEncode(queue.map((item) => item.toJson()).toList());
    final telemetryJson = jsonEncode(telemetry.toJson());

    await _storage.setValue(AppConstants.keyUrdidoQueue, queueJson);
    await _storage.setValue(AppConstants.keyUrdidoTelemetry, telemetryJson);
  }

  String _extractCodigoPcp(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      return '';
    }

    if (value.contains(',')) {
      final parsed = QrParser.parse(value);
      if (parsed.isValid && parsed.hilos != null) {
        return parsed.hilos!.codigoPcp.trim();
      }
      return value.split(',').first.trim();
    }

    return value;
  }

  String _composeTime(String hour, String minute) {
    if (hour.isEmpty && minute.isEmpty) {
      return '';
    }
    final hh = hour.isEmpty ? '00' : hour.padLeft(2, '0');
    final mm = minute.isEmpty ? '00' : minute.padLeft(2, '0');
    return '$hh:$mm';
  }

  String _at(List<String> values, int oneBasedIndex) {
    final index = oneBasedIndex - 1;
    if (index < 0 || index >= values.length) {
      return '';
    }
    return values[index].trim();
  }

  String _cleanError(Object error) {
    return error.toString().replaceAll('Exception: ', '').trim();
  }
}

final urdidoProvider = StateNotifierProvider<UrdidoNotifier, UrdidoState>(
  (ref) => UrdidoNotifier(
    ref.read(urdidoRemoteDatasourceProvider),
    ref.read(localStorageProvider),
  ),
);

const Map<String, String> _defaultUrdidoFields = {
  'codigo_pcp': '',
  'codigo_urdido': '',
  'turno': '',
  'operario': '',
  'ayudante_operario': '',
  'orden_pedido': '',
  'articulo': '',
  'tipo_proceso': '',
  'fecha_urdido': '',
  'ce_pe': '',
  'cantidad_hilos': '',
  'hora_inicio': '',
  'ancho_plegador': '',
  'metros_urdido': '',
  'peso_hilos_urdido': '',
  'cantidad_fajas': '',
  'hilo_cm': '',
  'altura': '',
  'peso_plegador': '',
  'desplazamiento': '',
  'tension': '',
  'num_plegador': '',
  'velo_urdido': '',
  'velo_plegador': '',
  'freno_plegador': '',
  'peso_merma': '',
  'titulo': '',
  'material': '',
  'numero_color_hilo': '',
  'hilo_color1': '',
  'hilo_color2': '',
  'hilo_color3': '',
  'hilo_color4': '',
  'hilo_color5': '',
  'hilo_color6': '',
  'hilo_color7': '',
  'hora_final': '',
  'giro_encerado': '',
  'peso_ensimaje': '',
  'observacion': '',
  'pasadas': '',
};
