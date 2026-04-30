import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_constants.dart';
import '../../core/storage/local_storage.dart';
import '../../core/utils/qr_parser.dart';
import '../../data/datasources/remote/produccion_remote_datasource.dart';
import '../../data/models/almacen_mov_queue_models.dart';
import '../../data/models/produccion_queue_models.dart';
import 'auth_provider.dart';

enum TelaresStatus {
  idle,
  loadingScanData,
  sending,
  queueing,
  drainingQueue,
  success,
  error,
}

enum TelaresRegistroMode {
  nuevoCorte,
  primerCorteNoAprobado,
  primerCorteAprobado,
}

class TelaresState {
  final TelaresStatus status;
  final TelaresRegistroMode registroMode;
  final Map<String, String> fields;
  final List<TelaresQueueJobModel> queue;
  final QueueTelemetryModel telemetry;
  final String? message;
  final String? errorMessage;

  const TelaresState({
    this.status = TelaresStatus.idle,
    this.registroMode = TelaresRegistroMode.primerCorteNoAprobado,
    this.fields = const {},
    this.queue = const [],
    this.telemetry = const QueueTelemetryModel(),
    this.message,
    this.errorMessage,
  });

  bool get isBusy =>
      status == TelaresStatus.loadingScanData ||
      status == TelaresStatus.sending ||
      status == TelaresStatus.queueing ||
      status == TelaresStatus.drainingQueue;

  int get pendingQueue => queue.length;

  bool get isNuevoCorte => registroMode == TelaresRegistroMode.nuevoCorte;

  TelaresState copyWith({
    TelaresStatus? status,
    TelaresRegistroMode? registroMode,
    Map<String, String>? fields,
    List<TelaresQueueJobModel>? queue,
    QueueTelemetryModel? telemetry,
    String? message,
    bool clearMessage = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TelaresState(
      status: status ?? this.status,
      registroMode: registroMode ?? this.registroMode,
      fields: fields ?? this.fields,
      queue: queue ?? this.queue,
      telemetry: telemetry ?? this.telemetry,
      message: clearMessage ? null : (message ?? this.message),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final telaresRemoteDatasourceProvider = Provider<ProduccionRemoteDatasource>(
  (ref) => ProduccionRemoteDatasource(
    ref.read(apiClientProvider),
    ref.read(localStorageProvider),
  ),
);

class TelaresNotifier extends StateNotifier<TelaresState> {
  final ProduccionRemoteDatasource _datasource;
  final LocalStorage _storage;
  bool _submitLock = false;

  TelaresNotifier(this._datasource, this._storage)
    : super(
        TelaresState(fields: Map<String, String>.from(_defaultTelaresFields)),
      ) {
    _bootstrap();
  }

  void _bootstrap() {
    _loadQueueAndTelemetry();
  }

  void actualizarCampo(String key, String value) {
    final updated = Map<String, String>.from(state.fields);
    updated[key] = value;
    state = state.copyWith(
      fields: updated,
      status: TelaresStatus.idle,
      clearError: true,
      clearMessage: true,
    );
  }

  void seleccionarModoPrimerCorte({required bool aprobado}) {
    if (state.registroMode == TelaresRegistroMode.nuevoCorte) return;

    state = state.copyWith(
      registroMode:
          aprobado
              ? TelaresRegistroMode.primerCorteAprobado
              : TelaresRegistroMode.primerCorteNoAprobado,
      status: TelaresStatus.idle,
      clearError: true,
      clearMessage: true,
    );
  }

  Future<void> buscarDesdeQr(String qrRaw) async {
    if (state.isBusy) return;

    final codigoPcp = _extractCodigoPcp(qrRaw);
    if (codigoPcp.isEmpty) {
      state = state.copyWith(
        status: TelaresStatus.error,
        errorMessage: 'QR invalido: no se encontro codigo PCP',
      );
      return;
    }

    state = state.copyWith(
      status: TelaresStatus.loadingScanData,
      clearError: true,
      clearMessage: true,
    );

    try {
      final data = await _datasource.buscarTelaresPorCodigoPcp(codigoPcp);
      if (data.raw.isEmpty) {
        throw Exception('No se encontraron datos para el codigo escaneado');
      }

      final updated = Map<String, String>.from(state.fields);
      updated['codigo_pcp'] = codigoPcp;
      updated['articulo_urdido'] = data.articuloUrdido;
      updated['codigo_urdido'] = data.codigoUrdido;
      updated['nro_plegador_urdido'] = data.nroPlegadorUrdido;
      updated['op_urdido'] = data.opUrdido;
      updated['metros_urdido'] = data.metrosUrdido;
      updated['metros_engomado'] = data.metrosEngomado;
      updated['si_no'] = data.nuevoCorteDisponible;
      updated['reloj'] = data.reloj;
      updated['puntaje_inicial'] = data.puntajeInicial;
      updated['puntaje_anterior'] = data.puntajeAnterior;
      updated['telar_anterior'] = data.telarAnterior;
      updated['telar_nuevo'] =
          data.telarAnterior.isEmpty
              ? updated['telar_nuevo']!
              : data.telarAnterior;

      final mode =
          data.nuevoCorteDisponible == 'si'
              ? TelaresRegistroMode.nuevoCorte
              : TelaresRegistroMode.primerCorteNoAprobado;

      state = state.copyWith(
        status: TelaresStatus.success,
        fields: updated,
        registroMode: mode,
        message: 'Datos de telares cargados desde escaneo',
      );
    } catch (error) {
      state = state.copyWith(
        status: TelaresStatus.error,
        errorMessage: _cleanError(error),
      );
    }
  }

  Future<void> enviarRegistro({required String usuario}) async {
    if (_submitLock || state.isBusy) return;

    _submitLock = true;
    Map<String, dynamic>? payload;
    try {
      payload = _buildPayload();
      state = state.copyWith(
        status: TelaresStatus.sending,
        clearError: true,
        clearMessage: true,
      );

      final message = await _datasource.enviarTelares(payload);
      state = state.copyWith(
        status: TelaresStatus.success,
        message: message,
        clearError: true,
      );
    } catch (error) {
      final message = _cleanError(error);
      if (payload != null && _debeEncolar(message)) {
        await _encolar(payload, usuario, message);
      } else {
        state = state.copyWith(
          status: TelaresStatus.error,
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
          status: TelaresStatus.success,
          message: 'No hay registros pendientes en cola',
          clearError: true,
        );
      }
      return;
    }

    _submitLock = true;
    final previousStatus = state.status;
    if (!silent) {
      state = state.copyWith(
        status: TelaresStatus.drainingQueue,
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
          await _datasource.enviarTelares(job.payload);
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
                : (failed == 0 ? TelaresStatus.success : TelaresStatus.error),
        message:
            !silent && processed > 0
                ? 'Cola procesada: $processed registro(s). Pendientes: ${queue.length}'
                : null,
        errorMessage:
            !silent && failed > 0
                ? 'La cola se detuvo por error. Pendientes: ${queue.length}'
                : null,
      );
    } catch (error) {
      if (!silent) {
        state = state.copyWith(
          status: TelaresStatus.error,
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
      status: TelaresStatus.idle,
      clearError: true,
      clearMessage: true,
    );
  }

  Future<void> limpiarCola() async {
    await _guardarQueueAndTelemetry(const [], state.telemetry);
    state = state.copyWith(
      queue: const [],
      status: TelaresStatus.idle,
      message: 'Cola de telares limpiada',
      clearError: true,
    );
  }

  void limpiarFormulario() {
    state = state.copyWith(
      status: TelaresStatus.idle,
      fields: Map<String, String>.from(_defaultTelaresFields),
      registroMode: TelaresRegistroMode.primerCorteNoAprobado,
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
    final codigoPcp = (payload['codigopcp'] ?? '').toString();
    final mode = _modeTag(state.registroMode);

    final job = TelaresQueueJobModel(
      id: '${now.microsecondsSinceEpoch}-${state.queue.length}',
      codigoPcp: codigoPcp,
      modoRegistro: mode,
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
      status: TelaresStatus.queueing,
      queue: updatedQueue,
      telemetry: updatedTelemetry,
      message: 'Sin red estable. Registro guardado en cola segura.',
      clearError: true,
    );
  }

  Map<String, dynamic> _buildPayload() {
    final fields = <String, String>{};
    for (final entry in state.fields.entries) {
      fields[entry.key] = entry.value.trim();
    }

    final reloj = fields['reloj'] ?? '';
    if (fields['codigo_pcp']!.isEmpty) {
      throw Exception('Complete codigo PCP antes de registrar');
    }
    if (reloj.isEmpty) {
      throw Exception('Seleccione reloj para registrar');
    }

    switch (state.registroMode) {
      case TelaresRegistroMode.nuevoCorte:
        final payload = <String, dynamic>{
          'codigopcp': fields['codigo_pcp'],
          'si_no': 'si',
          'reloj': reloj,
          'puntaje_inicial': fields['puntaje_inicial'],
          'puntaje_nuevo': fields['puntaje_nuevo'],
          'telar_nuevo': fields['telar_nuevo'],
        };
        _validateRequired(payload, [
          'codigopcp',
          'reloj',
          'puntaje_inicial',
          'puntaje_nuevo',
          'telar_nuevo',
        ]);
        return payload;
      case TelaresRegistroMode.primerCorteNoAprobado:
        final payload = <String, dynamic>{
          'codigopcp': fields['codigo_pcp'],
          'si_no': 'no',
          'fecha_no_aprob': fields['fecha_no_aprob'],
          'observaciones': fields['observaciones'],
          'reloj': reloj,
          'puntaje_inicial': fields['puntaje_inicial'],
          'puntaje1': fields['puntaje1'],
          'telar': fields['telar'],
        };
        _validateRequired(payload, [
          'codigopcp',
          'fecha_no_aprob',
          'observaciones',
          'reloj',
          'puntaje_inicial',
          'puntaje1',
          'telar',
        ]);
        return payload;
      case TelaresRegistroMode.primerCorteAprobado:
        final payload = <String, dynamic>{
          'codigopcp': fields['codigo_pcp'],
          'si_no': 'no',
          'fecha_aprobado': fields['fecha_aprobado'],
          'aprobado_por': fields['aprobado_por'],
          'reloj': reloj,
          'puntaje_inicial': fields['puntaje_inicial'],
          'puntaje1': fields['puntaje1'],
          'telar': fields['telar'],
        };
        _validateRequired(payload, [
          'codigopcp',
          'fecha_aprobado',
          'aprobado_por',
          'reloj',
          'puntaje_inicial',
          'puntaje1',
          'telar',
        ]);
        return payload;
    }
  }

  void _validateRequired(Map<String, dynamic> payload, List<String> keys) {
    final missing =
        keys
            .where((key) => (payload[key] ?? '').toString().trim().isEmpty)
            .toList();
    if (missing.isNotEmpty) {
      throw Exception(
        'Complete campos obligatorios de telares: ${missing.join(', ')}',
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
      AppConstants.keyTelaresQueue,
      defaultValue: '',
    );
    final rawTelemetry = _storage.getValue(
      AppConstants.keyTelaresTelemetry,
      defaultValue: '',
    );

    var queue = <TelaresQueueJobModel>[];
    if (rawQueue.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawQueue);
        if (decoded is List) {
          queue =
              decoded
                  .whereType<Map>()
                  .map(
                    (map) => TelaresQueueJobModel.fromJson(
                      Map<String, dynamic>.from(map),
                    ),
                  )
                  .where((job) => job.id.isNotEmpty && job.payload.isNotEmpty)
                  .toList();
        }
      } catch (_) {
        queue = <TelaresQueueJobModel>[];
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
    List<TelaresQueueJobModel> queue,
    QueueTelemetryModel telemetry,
  ) async {
    final queueJson = jsonEncode(queue.map((item) => item.toJson()).toList());
    final telemetryJson = jsonEncode(telemetry.toJson());

    await _storage.setValue(AppConstants.keyTelaresQueue, queueJson);
    await _storage.setValue(AppConstants.keyTelaresTelemetry, telemetryJson);
  }

  String _modeTag(TelaresRegistroMode mode) {
    switch (mode) {
      case TelaresRegistroMode.nuevoCorte:
        return 'nuevo_corte';
      case TelaresRegistroMode.primerCorteNoAprobado:
        return 'primer_corte_no_aprobado';
      case TelaresRegistroMode.primerCorteAprobado:
        return 'primer_corte_aprobado';
    }
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

  String _cleanError(Object error) {
    return error.toString().replaceAll('Exception: ', '').trim();
  }
}

final telaresProvider = StateNotifierProvider<TelaresNotifier, TelaresState>(
  (ref) => TelaresNotifier(
    ref.read(telaresRemoteDatasourceProvider),
    ref.read(localStorageProvider),
  ),
);

const Map<String, String> _defaultTelaresFields = {
  'codigo_pcp': '',
  'articulo_urdido': '',
  'codigo_urdido': '',
  'nro_plegador_urdido': '',
  'op_urdido': '',
  'metros_urdido': '',
  'metros_engomado': '',
  'si_no': '',
  'reloj': '',
  'puntaje_inicial': '',
  'puntaje_anterior': '',
  'telar_anterior': '',
  'puntaje_nuevo': '',
  'telar_nuevo': '',
  'fecha_no_aprob': '',
  'observaciones': '',
  'puntaje1': '',
  'telar': '',
  'fecha_aprobado': '',
  'aprobado_por': '',
};
