import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_constants.dart';
import '../../core/storage/local_storage.dart';
import '../../core/utils/cambio_ubicacion_qr_parser.dart';
import '../../data/datasources/remote/traslados_remote_datasource.dart';
import '../../data/models/almacen_mov_queue_models.dart';
import '../../data/models/traslados_queue_models.dart';
import 'auth_provider.dart';
import 'cambio_almacen_provider.dart';

enum CambioUbicacionStatus {
  idle,
  parsingQr,
  consultandoUbicacion,
  sending,
  queueing,
  drainingQueue,
  success,
  error,
}

const Map<String, List<String>> _ubicacionesPorPlanta = {
  'PLANTA 1': ['A', 'B', 'C', 'D', 'E', 'F', 'G (1ER PISO)'],
  'PLANTA 2': [
    'A',
    'A1',
    'A2',
    'A3',
    'A4',
    'B',
    'B1',
    'B2',
    'B3',
    'B4',
    'ALMACEN1',
    'ALMACEN2',
  ],
};

class CambioUbicacionState {
  final CambioUbicacionStatus status;
  final String qrRaw;
  final CambioUbicacionQrData? parsed;
  final String plantaSeleccionada;
  final String ubicacionSeleccionada;
  final String telar;
  final String fechaSalida;
  final String horaSalida;
  final String ultimaUbicacion;
  final List<CambioUbicacionQueueJobModel> queue;
  final QueueTelemetryModel telemetry;
  final String? message;
  final String? errorMessage;

  const CambioUbicacionState({
    this.status = CambioUbicacionStatus.idle,
    this.qrRaw = '',
    this.parsed,
    this.plantaSeleccionada = 'PLANTA 1',
    this.ubicacionSeleccionada = 'A',
    this.telar = '',
    this.fechaSalida = '',
    this.horaSalida = '',
    this.ultimaUbicacion = 'Sin registro',
    this.queue = const [],
    this.telemetry = const QueueTelemetryModel(),
    this.message,
    this.errorMessage,
  });

  bool get isBusy =>
      status == CambioUbicacionStatus.parsingQr ||
      status == CambioUbicacionStatus.consultandoUbicacion ||
      status == CambioUbicacionStatus.sending ||
      status == CambioUbicacionStatus.queueing ||
      status == CambioUbicacionStatus.drainingQueue;

  int get pendingQueue => queue.length;

  List<String> get plantas => _ubicacionesPorPlanta.keys.toList();

  List<String> get ubicacionesDisponibles {
    return _ubicacionesPorPlanta[plantaSeleccionada] ??
        _ubicacionesPorPlanta['PLANTA 1']!;
  }

  bool get canSubmit {
    return parsed != null &&
        plantaSeleccionada.trim().isNotEmpty &&
        ubicacionSeleccionada.trim().isNotEmpty;
  }

  CambioUbicacionState copyWith({
    CambioUbicacionStatus? status,
    String? qrRaw,
    CambioUbicacionQrData? parsed,
    bool clearParsed = false,
    String? plantaSeleccionada,
    String? ubicacionSeleccionada,
    String? telar,
    String? fechaSalida,
    String? horaSalida,
    String? ultimaUbicacion,
    List<CambioUbicacionQueueJobModel>? queue,
    QueueTelemetryModel? telemetry,
    String? message,
    bool clearMessage = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CambioUbicacionState(
      status: status ?? this.status,
      qrRaw: qrRaw ?? this.qrRaw,
      parsed: clearParsed ? null : (parsed ?? this.parsed),
      plantaSeleccionada: plantaSeleccionada ?? this.plantaSeleccionada,
      ubicacionSeleccionada:
          ubicacionSeleccionada ?? this.ubicacionSeleccionada,
      telar: telar ?? this.telar,
      fechaSalida: fechaSalida ?? this.fechaSalida,
      horaSalida: horaSalida ?? this.horaSalida,
      ultimaUbicacion: ultimaUbicacion ?? this.ultimaUbicacion,
      queue: queue ?? this.queue,
      telemetry: telemetry ?? this.telemetry,
      message: clearMessage ? null : (message ?? this.message),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class CambioUbicacionNotifier extends StateNotifier<CambioUbicacionState> {
  final TrasladosRemoteDatasource _datasource;
  final LocalStorage _storage;

  bool _submitLock = false;
  String _lastSubmitSignature = '';
  DateTime? _lastSubmitAt;

  CambioUbicacionNotifier(this._datasource, this._storage)
    : super(const CambioUbicacionState()) {
    _loadQueueAndTelemetry();
  }

  void setQrRaw(String value) {
    state = state.copyWith(qrRaw: value, clearError: true, clearMessage: true);
  }

  void setPlanta(String value) {
    final clean = value.trim();
    final opciones =
        _ubicacionesPorPlanta[clean] ?? _ubicacionesPorPlanta['PLANTA 1']!;
    final selected =
        opciones.contains(state.ubicacionSeleccionada)
            ? state.ubicacionSeleccionada
            : opciones.first;

    state = state.copyWith(
      plantaSeleccionada: clean,
      ubicacionSeleccionada: selected,
      clearError: true,
      clearMessage: true,
    );
  }

  void setUbicacion(String value) {
    state = state.copyWith(
      ubicacionSeleccionada: value.trim(),
      clearError: true,
      clearMessage: true,
    );
  }

  void setTelar(String value) {
    state = state.copyWith(
      telar: value.trim(),
      clearError: true,
      clearMessage: true,
    );
  }

  Future<void> parsearQr() async {
    final raw = state.qrRaw.trim();
    if (raw.isEmpty) {
      state = state.copyWith(
        status: CambioUbicacionStatus.error,
        errorMessage: 'Ingrese o escanee el QR antes de parsear',
      );
      return;
    }

    state = state.copyWith(
      status: CambioUbicacionStatus.parsingQr,
      clearError: true,
      clearMessage: true,
    );

    final result = CambioUbicacionQrParser.parse(raw);
    if (!result.isValid || result.data == null) {
      state = state.copyWith(
        status: CambioUbicacionStatus.error,
        errorMessage: result.error ?? 'No se pudo parsear el QR',
      );
      return;
    }

    final now = DateTime.now();
    state = state.copyWith(
      status: CambioUbicacionStatus.consultandoUbicacion,
      parsed: result.data,
      fechaSalida: _formatDate(now),
      horaSalida: _formatTime(now),
      clearError: true,
      clearMessage: true,
    );

    await _consultarUltimaUbicacion(parsed: result.data!);
  }

  Future<void> consultarUltimaUbicacionManual() async {
    final parsed = state.parsed;
    if (parsed == null) {
      state = state.copyWith(
        status: CambioUbicacionStatus.error,
        errorMessage: 'Debe parsear un QR antes de consultar ubicacion',
      );
      return;
    }

    state = state.copyWith(
      status: CambioUbicacionStatus.consultandoUbicacion,
      clearError: true,
      clearMessage: true,
    );

    await _consultarUltimaUbicacion(parsed: parsed);
  }

  Future<void> enviarCambio({required String usuario}) async {
    if (_submitLock || state.isBusy) return;
    if (!state.canSubmit || state.parsed == null) {
      state = state.copyWith(
        status: CambioUbicacionStatus.error,
        errorMessage: 'Complete escaneo QR y destino antes de enviar',
      );
      return;
    }

    final signature = _signature(usuario);
    final now = DateTime.now();
    final repeated =
        signature == _lastSubmitSignature &&
        _lastSubmitAt != null &&
        now.difference(_lastSubmitAt!).inSeconds < 8;
    if (repeated) {
      state = state.copyWith(
        status: CambioUbicacionStatus.error,
        errorMessage:
            'Se detecto envio duplicado. Espere unos segundos antes de reenviar',
      );
      return;
    }

    _submitLock = true;
    state = state.copyWith(
      status: CambioUbicacionStatus.sending,
      clearError: true,
      clearMessage: true,
    );

    try {
      final form = _buildForm(usuario);
      await _datasource.enviarCambioUbicacion(form);

      _lastSubmitSignature = signature;
      _lastSubmitAt = now;

      state = state.copyWith(
        status: CambioUbicacionStatus.success,
        message: 'Cambio de ubicacion enviado correctamente',
        clearError: true,
      );
    } catch (error) {
      final message = _cleanError(error);
      if (_debeEncolar(message)) {
        await _encolar(usuario: usuario, baseError: message);
      } else {
        state = state.copyWith(
          status: CambioUbicacionStatus.error,
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
          status: CambioUbicacionStatus.success,
          message: 'No hay cambios de ubicacion pendientes',
          clearError: true,
        );
      }
      return;
    }

    _submitLock = true;
    final previousStatus = state.status;
    if (!silent) {
      state = state.copyWith(
        status: CambioUbicacionStatus.drainingQueue,
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
          final form = CambioUbicacionFormData(
            qrCampos: job.qrCampos,
            codigoKardex: job.codigoKardex,
            codigoPcp: job.codigoPcp,
            planta: job.planta,
            ubicacion: job.ubicacion,
            fechaSalida: job.fechaSalida,
            horaSalida: job.horaSalida,
            servicio: job.servicio,
            usuario: job.usuario,
            telar: job.telar,
            movimiento: job.movimiento,
          );

          await _datasource.enviarCambioUbicacion(form);

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

      await _saveQueueAndTelemetry(queue, telemetry);

      state = state.copyWith(
        queue: queue,
        telemetry: telemetry,
        status:
            silent
                ? previousStatus
                : (failed == 0
                    ? CambioUbicacionStatus.success
                    : CambioUbicacionStatus.error),
        message:
            !silent && processed > 0
                ? 'Cola procesada: $processed cambio(s). Pendientes: ${queue.length}'
                : null,
        errorMessage:
            !silent && failed > 0
                ? 'La cola se detuvo por error. Pendientes: ${queue.length}'
                : null,
      );
    } finally {
      _submitLock = false;
    }
  }

  Future<void> eliminarTrabajoCola(String jobId) async {
    final updated = state.queue.where((job) => job.id != jobId).toList();
    await _saveQueueAndTelemetry(updated, state.telemetry);
    state = state.copyWith(
      queue: updated,
      status: CambioUbicacionStatus.idle,
      clearError: true,
      clearMessage: true,
    );
  }

  Future<void> limpiarCola() async {
    await _saveQueueAndTelemetry(
      const <CambioUbicacionQueueJobModel>[],
      state.telemetry,
    );
    state = state.copyWith(
      queue: const <CambioUbicacionQueueJobModel>[],
      status: CambioUbicacionStatus.idle,
      message: 'Cola de cambio ubicacion limpiada',
      clearError: true,
    );
  }

  void limpiarFormulario() {
    state = state.copyWith(
      status: CambioUbicacionStatus.idle,
      qrRaw: '',
      clearParsed: true,
      plantaSeleccionada: 'PLANTA 1',
      ubicacionSeleccionada: 'A',
      telar: '',
      fechaSalida: '',
      horaSalida: '',
      ultimaUbicacion: 'Sin registro',
      clearError: true,
      clearMessage: true,
    );
  }

  Future<void> _consultarUltimaUbicacion({
    required CambioUbicacionQrData parsed,
  }) async {
    try {
      final data = await _datasource.consultarUltimaUbicacion(parsed.codigoPcp);
      final almacen = data.almacen.trim().isEmpty ? 'Sin dato' : data.almacen;
      final ubicacion =
          data.ubicacion.trim().isEmpty ? 'Sin dato' : data.ubicacion;

      state = state.copyWith(
        status: CambioUbicacionStatus.success,
        ultimaUbicacion: '$almacen / $ubicacion',
        message:
            'QR cargado (${parsed.camposDetectados} campos). Ultima ubicacion consultada.',
        clearError: true,
      );
    } catch (_) {
      state = state.copyWith(
        status: CambioUbicacionStatus.success,
        ultimaUbicacion: 'Sin registro',
        message: 'QR cargado. No se encontro ultima ubicacion registrada.',
        clearError: true,
      );
    }
  }

  Future<void> _encolar({
    required String usuario,
    required String baseError,
  }) async {
    final form = _buildForm(usuario);
    final now = DateTime.now();

    final job = CambioUbicacionQueueJobModel(
      id: '${now.microsecondsSinceEpoch}-${state.queue.length}',
      qrCampos: form.qrCampos,
      codigoKardex: form.codigoKardex,
      codigoPcp: form.codigoPcp,
      material: state.parsed?.material ?? '',
      titulo: state.parsed?.titulo ?? '',
      color: state.parsed?.color ?? '',
      lote: state.parsed?.lote ?? '',
      numCaja: state.parsed?.numCaja ?? '',
      servicio: form.servicio,
      planta: form.planta,
      ubicacion: form.ubicacion,
      telar: form.telar,
      fechaSalida: form.fechaSalida,
      horaSalida: form.horaSalida,
      movimiento: form.movimiento,
      usuario: form.usuario,
      createdAtIso: now.toIso8601String(),
    );

    final updatedQueue = [...state.queue, job];
    final updatedTelemetry = state.telemetry.copyWith(
      enqueuedTotal: state.telemetry.enqueuedTotal + 1,
      lastAttemptAtIso: now.toIso8601String(),
      lastError: baseError,
    );

    await _saveQueueAndTelemetry(updatedQueue, updatedTelemetry);

    state = state.copyWith(
      status: CambioUbicacionStatus.queueing,
      queue: updatedQueue,
      telemetry: updatedTelemetry,
      message: 'Sin red estable. Cambio de ubicacion guardado en cola segura.',
      clearError: true,
    );
  }

  CambioUbicacionFormData _buildForm(String usuario) {
    final parsed = state.parsed;
    if (parsed == null) {
      throw Exception('No hay datos QR para construir el formulario');
    }

    final now = DateTime.now();
    final fechaSalida =
        state.fechaSalida.trim().isNotEmpty
            ? state.fechaSalida
            : _formatDate(now);
    final horaSalida =
        state.horaSalida.trim().isNotEmpty
            ? state.horaSalida
            : _formatTime(now);

    return CambioUbicacionFormData(
      qrCampos: parsed.camposDetectados,
      codigoKardex: parsed.codigoKardex,
      codigoPcp: parsed.codigoPcp,
      planta: state.plantaSeleccionada,
      ubicacion: state.ubicacionSeleccionada,
      fechaSalida: fechaSalida,
      horaSalida: horaSalida,
      servicio: parsed.servicio,
      usuario: usuario.trim(),
      telar: state.telar.trim(),
    );
  }

  void _loadQueueAndTelemetry() {
    final rawQueue = _storage.getValue(
      AppConstants.keyCambioUbicacionQueue,
      defaultValue: '',
    );
    final rawTelemetry = _storage.getValue(
      AppConstants.keyCambioUbicacionTelemetry,
      defaultValue: '',
    );

    var queue = <CambioUbicacionQueueJobModel>[];
    if (rawQueue.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawQueue);
        if (decoded is List) {
          queue =
              decoded
                  .whereType<Map>()
                  .map(
                    (item) => CambioUbicacionQueueJobModel.fromJson(
                      Map<String, dynamic>.from(item),
                    ),
                  )
                  .where((job) => job.id.isNotEmpty)
                  .toList();
        }
      } catch (_) {
        queue = <CambioUbicacionQueueJobModel>[];
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

  Future<void> _saveQueueAndTelemetry(
    List<CambioUbicacionQueueJobModel> queue,
    QueueTelemetryModel telemetry,
  ) async {
    final queueJson = jsonEncode(queue.map((item) => item.toJson()).toList());
    final telemetryJson = jsonEncode(telemetry.toJson());

    await _storage.setValue(AppConstants.keyCambioUbicacionQueue, queueJson);
    await _storage.setValue(
      AppConstants.keyCambioUbicacionTelemetry,
      telemetryJson,
    );
  }

  bool _debeEncolar(String message) {
    final text = message.toLowerCase();
    return text.contains('no se puede conectar') ||
        text.contains('timeout') ||
        text.contains('connection') ||
        text.contains('socket') ||
        text.contains('network') ||
        text.contains('internet');
  }

  String _signature(String usuario) {
    final parsed = state.parsed;
    return [
      parsed?.codigoPcp ?? '',
      state.plantaSeleccionada,
      state.ubicacionSeleccionada,
      usuario.trim(),
    ].join('|').toUpperCase();
  }

  String _formatDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = date.year.toString();
    return '$dd/$mm/$yyyy';
  }

  String _formatTime(DateTime date) {
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    final ss = date.second.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }

  String _cleanError(Object error) {
    return error.toString().replaceAll('Exception: ', '').trim();
  }
}

final cambioUbicacionProvider =
    StateNotifierProvider<CambioUbicacionNotifier, CambioUbicacionState>(
      (ref) => CambioUbicacionNotifier(
        ref.read(trasladosDatasourceProvider),
        ref.read(localStorageProvider),
      ),
    );
