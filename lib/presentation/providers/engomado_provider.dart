import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_constants.dart';
import '../../core/storage/local_storage.dart';
import '../../core/utils/qr_parser.dart';
import '../../data/datasources/remote/produccion_remote_datasource.dart';
import '../../data/models/almacen_mov_queue_models.dart';
import '../../data/models/produccion_queue_models.dart';
import 'auth_provider.dart';

enum EngomadoStatus {
  idle,
  loadingCatalogs,
  loadingUrdido,
  sending,
  queueing,
  drainingQueue,
  success,
  error,
}

class EngomadoState {
  final EngomadoStatus status;
  final Map<String, String> fields;
  final Map<String, String> urdidoSnapshot;
  final List<String> materiales;
  final List<String> titulos;
  final List<EngomadoQueueJobModel> queue;
  final QueueTelemetryModel telemetry;
  final String? message;
  final String? errorMessage;

  const EngomadoState({
    this.status = EngomadoStatus.idle,
    this.fields = const {},
    this.urdidoSnapshot = const {},
    this.materiales = const [],
    this.titulos = const [],
    this.queue = const [],
    this.telemetry = const QueueTelemetryModel(),
    this.message,
    this.errorMessage,
  });

  bool get isBusy =>
      status == EngomadoStatus.loadingCatalogs ||
      status == EngomadoStatus.loadingUrdido ||
      status == EngomadoStatus.sending ||
      status == EngomadoStatus.queueing ||
      status == EngomadoStatus.drainingQueue;

  int get pendingQueue => queue.length;

  EngomadoState copyWith({
    EngomadoStatus? status,
    Map<String, String>? fields,
    Map<String, String>? urdidoSnapshot,
    List<String>? materiales,
    List<String>? titulos,
    List<EngomadoQueueJobModel>? queue,
    QueueTelemetryModel? telemetry,
    String? message,
    bool clearMessage = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return EngomadoState(
      status: status ?? this.status,
      fields: fields ?? this.fields,
      urdidoSnapshot: urdidoSnapshot ?? this.urdidoSnapshot,
      materiales: materiales ?? this.materiales,
      titulos: titulos ?? this.titulos,
      queue: queue ?? this.queue,
      telemetry: telemetry ?? this.telemetry,
      message: clearMessage ? null : (message ?? this.message),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final engomadoRemoteDatasourceProvider = Provider<ProduccionRemoteDatasource>(
  (ref) => ProduccionRemoteDatasource(
    ref.read(apiClientProvider),
    ref.read(localStorageProvider),
  ),
);

class EngomadoNotifier extends StateNotifier<EngomadoState> {
  final ProduccionRemoteDatasource _datasource;
  final LocalStorage _storage;
  bool _submitLock = false;

  EngomadoNotifier(this._datasource, this._storage)
    : super(
        EngomadoState(
          fields: Map<String, String>.from(_defaultEngomadoFields),
          urdidoSnapshot: const {},
        ),
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
      status: EngomadoStatus.idle,
      clearError: true,
      clearMessage: true,
    );
  }

  Future<void> cargarCatalogos() async {
    if (state.isBusy) return;

    state = state.copyWith(
      status: EngomadoStatus.loadingCatalogs,
      clearError: true,
      clearMessage: true,
    );

    try {
      final data = await _datasource.obtenerDatosGenerales();
      state = state.copyWith(
        status: EngomadoStatus.success,
        materiales: data.materiales,
        titulos: data.titulos,
      );
    } catch (error) {
      state = state.copyWith(
        status: EngomadoStatus.error,
        errorMessage: _cleanError(error),
      );
    }
  }

  Future<void> buscarUrdidoDesdeQr(String qrRaw) async {
    if (state.isBusy) return;

    final codigoPcp = _extractCodigoPcp(qrRaw);
    if (codigoPcp.isEmpty) {
      state = state.copyWith(
        status: EngomadoStatus.error,
        errorMessage: 'QR invalido: no se encontro codigo PCP',
      );
      return;
    }

    state = state.copyWith(
      status: EngomadoStatus.loadingUrdido,
      clearError: true,
      clearMessage: true,
    );

    try {
      final data = await _datasource.buscarUrdidoParaEngomado(codigoPcp);
      if (data.isEmpty) {
        throw Exception('No se encontro urdido para el codigo escaneado');
      }

      final snapshot = <String, String>{
        'codigo_urdido': _at(data, 1),
        'nro_plegador_urdido': _at(data, 2),
        'cantidad_hilos_urdido': _at(data, 3),
        'metros_urdido': _at(data, 4),
        'ancho_plegador_urdido': _at(data, 5),
        'peso_inicial_urdido': _at(data, 6),
        'articulo_urdido': _at(data, 7),
        'op_urdido': _at(data, 8),
      };

      final updatedFields = Map<String, String>.from(state.fields);
      updatedFields['codigopcp'] = codigoPcp;
      if ((snapshot['codigo_urdido'] ?? '').isNotEmpty) {
        updatedFields['codigo_urdido'] = snapshot['codigo_urdido']!;
      }

      state = state.copyWith(
        status: EngomadoStatus.success,
        fields: updatedFields,
        urdidoSnapshot: snapshot,
        message: 'Datos de urdido vinculados al proceso',
      );
    } catch (error) {
      state = state.copyWith(
        status: EngomadoStatus.error,
        errorMessage: _cleanError(error),
      );
    }
  }

  Future<void> enviarEngomado({required String usuario}) async {
    if (_submitLock || state.isBusy) return;

    _submitLock = true;
    Map<String, dynamic>? payload;
    try {
      payload = _buildPayload(usuario);
      state = state.copyWith(
        status: EngomadoStatus.sending,
        clearError: true,
        clearMessage: true,
      );
      final message = await _datasource.enviarEngomado(payload);
      state = state.copyWith(
        status: EngomadoStatus.success,
        message: message,
        clearError: true,
      );
    } catch (error) {
      final message = _cleanError(error);
      if (payload != null && _debeEncolar(message)) {
        await _encolar(payload, usuario, message);
      } else {
        state = state.copyWith(
          status: EngomadoStatus.error,
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
          status: EngomadoStatus.success,
          message: 'No hay procesos pendientes en cola',
          clearError: true,
        );
      }
      return;
    }

    _submitLock = true;
    final previousStatus = state.status;
    if (!silent) {
      state = state.copyWith(
        status: EngomadoStatus.drainingQueue,
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
          await _datasource.enviarEngomado(job.payload);
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
                : (failed == 0 ? EngomadoStatus.success : EngomadoStatus.error),
        message:
            !silent && processed > 0
                ? 'Cola procesada: $processed proceso(s). Pendientes: ${queue.length}'
                : null,
        errorMessage:
            failed > 0 && !silent
                ? 'La cola se detuvo por error. Pendientes: ${queue.length}'
                : null,
      );
    } catch (error) {
      if (!silent) {
        state = state.copyWith(
          status: EngomadoStatus.error,
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
      status: EngomadoStatus.idle,
      clearError: true,
      clearMessage: true,
    );
  }

  Future<void> limpiarCola() async {
    await _guardarQueueAndTelemetry(const [], state.telemetry);
    state = state.copyWith(
      queue: const [],
      status: EngomadoStatus.idle,
      message: 'Cola de engomado limpiada',
      clearError: true,
    );
  }

  void limpiarFormulario() {
    state = state.copyWith(
      status: EngomadoStatus.idle,
      fields: Map<String, String>.from(_defaultEngomadoFields),
      urdidoSnapshot: const {},
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
    final tipoProceso = (payload['tipo_proceso'] ?? '').toString();
    final codigoPcp = (payload['codigopcp'] ?? '').toString();

    final job = EngomadoQueueJobModel(
      id: '${now.microsecondsSinceEpoch}-${state.queue.length}',
      tipoProceso: tipoProceso,
      codigoPcp: codigoPcp,
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
      status: EngomadoStatus.queueing,
      queue: updatedQueue,
      telemetry: updatedTelemetry,
      message: 'Sin red estable. Proceso guardado en cola segura.',
      clearError: true,
    );
  }

  Map<String, dynamic> _buildPayload(String usuario) {
    final normalized = <String, String>{};
    for (final entry in state.fields.entries) {
      normalized[entry.key] = entry.value.trim();
    }

    if ((normalized['operario'] ?? '').isEmpty) {
      normalized['operario'] = usuario.trim();
    }
    if ((normalized['tipo_proceso'] ?? '').isEmpty) {
      normalized['tipo_proceso'] = AppConstants.procesoEngomado;
    }
    if ((normalized['codigo_urdido'] ?? '').isEmpty &&
        (state.urdidoSnapshot['codigo_urdido'] ?? '').isNotEmpty) {
      normalized['codigo_urdido'] = state.urdidoSnapshot['codigo_urdido']!;
    }

    final tipo = normalized['tipo_proceso']!.toLowerCase();
    if (tipo == AppConstants.procesoEngomado.toLowerCase()) {
      final payload = <String, dynamic>{
        'codigopcp': normalized['codigopcp'],
        'tipo_proceso': normalized['tipo_proceso'],
        'turno': normalized['turno'],
        'operario': normalized['operario'],
        'hora_inicial': normalized['hora_inicial'],
        'hora_final': normalized['hora_final'],
        'metros_engomado': normalized['metros_engomado'],
        'tipo_plegador': normalized['tipo_plegador'],
        'ancho_plegador': normalized['ancho_plegador'],
        'porcentaje_solido': normalized['porcentaje_solido'],
        'peso_engomado_final': normalized['peso_engomado_final'],
        'plegador_final_engomado': normalized['plegador_final_engomado'],
        'viscosidad_engomado': normalized['viscosidad_engomado'],
        'formula_engomado': normalized['formula_engomado'],
        'velocidad_engomadora': normalized['velocidad_engomadora'],
        'titulo': normalized['titulo'],
        'material': normalized['material'],
        'observacion': normalized['observacion'],
      };
      _validateRequired(payload, [
        'codigopcp',
        'tipo_proceso',
        'turno',
        'operario',
        'hora_inicial',
        'hora_final',
        'metros_engomado',
        'ancho_plegador',
        'peso_engomado_final',
        'plegador_final_engomado',
        'titulo',
        'material',
      ]);
      return payload;
    }

    if (tipo == AppConstants.procesoEnsimaje.toLowerCase()) {
      final payload = <String, dynamic>{
        'codigopcp': normalized['codigopcp'],
        'tipo_proceso': normalized['tipo_proceso'],
        'turno': normalized['turno'],
        'operario': normalized['operario'],
        'hora_inicial': normalized['hora_inicial'],
        'hora_final': normalized['hora_final'],
        'metros_engomado': normalized['metros_engomado'],
        'tipo_plegador': normalized['tipo_plegador'],
        'ancho_plegador': normalized['ancho_plegador'],
        'peso_engomado_final': normalized['peso_engomado_final'],
        'plegador_final_engomado': normalized['plegador_final_engomado'],
        'formula_engomado': normalized['formula_engomado'],
        'titulo': normalized['titulo'],
        'material': normalized['material'],
        'observacion': normalized['observacion'],
        'codigo_urdido': normalized['codigo_urdido'],
        'giro_encerado': normalized['giro_encerado'],
        'kilo_ensimaje': normalized['kilo_ensimaje'],
      };
      _validateRequired(payload, [
        'codigopcp',
        'tipo_proceso',
        'turno',
        'operario',
        'hora_inicial',
        'hora_final',
        'metros_engomado',
        'ancho_plegador',
        'peso_engomado_final',
        'plegador_final_engomado',
        'titulo',
        'material',
        'codigo_urdido',
        'giro_encerado',
        'kilo_ensimaje',
      ]);
      return payload;
    }

    if (tipo == AppConstants.procesoVolteado.toLowerCase()) {
      final payload = <String, dynamic>{
        'codigopcp': normalized['codigopcp'],
        'tipo_proceso': normalized['tipo_proceso'],
        'turno': normalized['turno'],
        'fecha_volteado': normalized['fecha_volteado'],
        'operario': normalized['operario'],
        'plegador_final_volteado': normalized['plegador_final_volteado'],
        'observacion': normalized['observacion'],
      };
      _validateRequired(payload, [
        'codigopcp',
        'tipo_proceso',
        'turno',
        'fecha_volteado',
        'operario',
        'plegador_final_volteado',
      ]);
      return payload;
    }

    throw Exception(
      'Tipo de proceso invalido. Use Engomado, Ensimaje o Volteado.',
    );
  }

  void _validateRequired(Map<String, dynamic> payload, List<String> keys) {
    final missing =
        keys
            .where((key) => (payload[key] ?? '').toString().trim().isEmpty)
            .toList();
    if (missing.isNotEmpty) {
      throw Exception(
        'Complete campos obligatorios de engomado: ${missing.join(', ')}',
      );
    }
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
      AppConstants.keyEngomadoQueue,
      defaultValue: '',
    );
    final rawTelemetry = _storage.getValue(
      AppConstants.keyEngomadoTelemetry,
      defaultValue: '',
    );

    var queue = <EngomadoQueueJobModel>[];
    if (rawQueue.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawQueue);
        if (decoded is List) {
          queue =
              decoded
                  .whereType<Map>()
                  .map(
                    (map) => EngomadoQueueJobModel.fromJson(
                      Map<String, dynamic>.from(map),
                    ),
                  )
                  .where((job) => job.id.isNotEmpty && job.payload.isNotEmpty)
                  .toList();
        }
      } catch (_) {
        queue = <EngomadoQueueJobModel>[];
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
    List<EngomadoQueueJobModel> queue,
    QueueTelemetryModel telemetry,
  ) async {
    final queueJson = jsonEncode(queue.map((item) => item.toJson()).toList());
    final telemetryJson = jsonEncode(telemetry.toJson());

    await _storage.setValue(AppConstants.keyEngomadoQueue, queueJson);
    await _storage.setValue(AppConstants.keyEngomadoTelemetry, telemetryJson);
  }

  String _extractCodigoPcp(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '';

    if (value.contains(',')) {
      final parsed = QrParser.parse(value);
      if (parsed.isValid && parsed.hilos != null) {
        return parsed.hilos!.codigoPcp.trim();
      }
      return value.split(',').first.trim();
    }

    return value;
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

final engomadoProvider = StateNotifierProvider<EngomadoNotifier, EngomadoState>(
  (ref) => EngomadoNotifier(
    ref.read(engomadoRemoteDatasourceProvider),
    ref.read(localStorageProvider),
  ),
);

const Map<String, String> _defaultEngomadoFields = {
  'codigopcp': '',
  'tipo_proceso': '',
  'turno': '',
  'operario': '',
  'hora_inicial': '',
  'hora_final': '',
  'metros_engomado': '',
  'tipo_plegador': '',
  'ancho_plegador': '',
  'porcentaje_solido': '',
  'peso_engomado_final': '',
  'plegador_final_engomado': '',
  'viscosidad_engomado': '',
  'formula_engomado': '',
  'velocidad_engomadora': '',
  'titulo': '',
  'material': '',
  'observacion': '',
  'codigo_urdido': '',
  'giro_encerado': '',
  'kilo_ensimaje': '',
  'fecha_volteado': '',
  'plegador_final_volteado': '',
};
