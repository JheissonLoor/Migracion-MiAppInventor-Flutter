import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_constants.dart';
import '../../core/storage/local_storage.dart';
import '../../core/utils/cambio_almacen_qr_parser.dart';
import '../../data/datasources/remote/traslados_remote_datasource.dart';
import '../../data/models/almacen_mov_queue_models.dart';
import '../../data/models/traslados_queue_models.dart';
import 'auth_provider.dart';

enum CambioAlmacenStatus {
  idle,
  parsingQr,
  sending,
  queueing,
  drainingQueue,
  success,
  error,
}

const Map<String, List<String>> _ubicacionesPorAlmacen = {
  'PLANTA 1': [
    'Pretelar',
    'Engomado',
    'Acabado',
    'Casa de Francisco',
    'Pasadizo',
  ],
  'PLANTA 2': ['A', 'B'],
  'PLANTA 3': ['A1'],
  'TINTORERIA': ['Busatex', 'Mercurio', 'Nortextil', 'Rami', 'Terrot'],
};

const List<String> _almacenesLegacy = [
  'PLANTA 1',
  'PLANTA 2',
  'PLANTA 3',
  'TINTORERIA',
];

class CambioAlmacenState {
  final CambioAlmacenStatus status;
  final String qrRaw;
  final CambioAlmacenQrData? parsed;
  final String almacenSeleccionado;
  final String ubicacionSeleccionada;
  final String fechaSalida;
  final String horaSalida;
  final List<CambioAlmacenQueueJobModel> queue;
  final QueueTelemetryModel telemetry;
  final String? message;
  final String? errorMessage;

  const CambioAlmacenState({
    this.status = CambioAlmacenStatus.idle,
    this.qrRaw = '',
    this.parsed,
    this.almacenSeleccionado = 'PLANTA 1',
    this.ubicacionSeleccionada = 'Pretelar',
    this.fechaSalida = '',
    this.horaSalida = '',
    this.queue = const [],
    this.telemetry = const QueueTelemetryModel(),
    this.message,
    this.errorMessage,
  });

  bool get isBusy =>
      status == CambioAlmacenStatus.parsingQr ||
      status == CambioAlmacenStatus.sending ||
      status == CambioAlmacenStatus.queueing ||
      status == CambioAlmacenStatus.drainingQueue;

  int get pendingQueue => queue.length;

  List<String> get almacenes => _almacenesLegacy;

  List<String> get ubicacionesDisponibles {
    return _ubicacionesPorAlmacen[almacenSeleccionado] ??
        _ubicacionesPorAlmacen['TINTORERIA']!;
  }

  bool get canSubmit {
    return parsed != null &&
        almacenSeleccionado.trim().isNotEmpty &&
        ubicacionSeleccionada.trim().isNotEmpty;
  }

  CambioAlmacenState copyWith({
    CambioAlmacenStatus? status,
    String? qrRaw,
    CambioAlmacenQrData? parsed,
    bool clearParsed = false,
    String? almacenSeleccionado,
    String? ubicacionSeleccionada,
    String? fechaSalida,
    String? horaSalida,
    List<CambioAlmacenQueueJobModel>? queue,
    QueueTelemetryModel? telemetry,
    String? message,
    bool clearMessage = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CambioAlmacenState(
      status: status ?? this.status,
      qrRaw: qrRaw ?? this.qrRaw,
      parsed: clearParsed ? null : (parsed ?? this.parsed),
      almacenSeleccionado: almacenSeleccionado ?? this.almacenSeleccionado,
      ubicacionSeleccionada:
          ubicacionSeleccionada ?? this.ubicacionSeleccionada,
      fechaSalida: fechaSalida ?? this.fechaSalida,
      horaSalida: horaSalida ?? this.horaSalida,
      queue: queue ?? this.queue,
      telemetry: telemetry ?? this.telemetry,
      message: clearMessage ? null : (message ?? this.message),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final trasladosDatasourceProvider = Provider<TrasladosRemoteDatasource>(
  (ref) => TrasladosRemoteDatasource(ref.read(apiClientProvider)),
);

class CambioAlmacenNotifier extends StateNotifier<CambioAlmacenState> {
  final TrasladosRemoteDatasource _datasource;
  final LocalStorage _storage;

  bool _submitLock = false;
  String _lastSubmitSignature = '';
  DateTime? _lastSubmitAt;

  CambioAlmacenNotifier(this._datasource, this._storage)
    : super(const CambioAlmacenState()) {
    _loadQueueAndTelemetry();
  }

  void setQrRaw(String value) {
    state = state.copyWith(qrRaw: value, clearError: true, clearMessage: true);
  }

  void setAlmacen(String value) {
    final clean = value.trim();
    final nextUbicaciones =
        _ubicacionesPorAlmacen[clean] ?? _ubicacionesPorAlmacen['TINTORERIA']!;
    final selected =
        nextUbicaciones.contains(state.ubicacionSeleccionada)
            ? state.ubicacionSeleccionada
            : nextUbicaciones.first;

    state = state.copyWith(
      almacenSeleccionado: clean,
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

  Future<void> parsearQr() async {
    final raw = state.qrRaw.trim();
    if (raw.isEmpty) {
      state = state.copyWith(
        status: CambioAlmacenStatus.error,
        errorMessage: 'Ingrese o escanee el QR antes de parsear',
      );
      return;
    }

    state = state.copyWith(
      status: CambioAlmacenStatus.parsingQr,
      clearError: true,
      clearMessage: true,
    );

    final result = CambioAlmacenQrParser.parse(raw);
    if (!result.isValid || result.data == null) {
      state = state.copyWith(
        status: CambioAlmacenStatus.error,
        errorMessage: result.error ?? 'No se pudo parsear el QR',
      );
      return;
    }

    final now = DateTime.now();
    state = state.copyWith(
      status: CambioAlmacenStatus.success,
      parsed: result.data,
      fechaSalida: _formatDate(now),
      horaSalida: _formatTime(now),
      message:
          'QR cargado (${result.data!.camposDetectados} campos). Verifique destino y envie.',
      clearError: true,
    );
  }

  Future<void> enviarCambio({required String usuario}) async {
    if (_submitLock || state.isBusy) return;
    if (!state.canSubmit || state.parsed == null) {
      state = state.copyWith(
        status: CambioAlmacenStatus.error,
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
        status: CambioAlmacenStatus.error,
        errorMessage:
            'Se detecto envio duplicado. Espere unos segundos antes de reenviar',
      );
      return;
    }

    _submitLock = true;
    state = state.copyWith(
      status: CambioAlmacenStatus.sending,
      clearError: true,
      clearMessage: true,
    );

    try {
      final form = _buildForm(usuario);
      await _datasource.enviarCambioAlmacen(form);

      _lastSubmitSignature = signature;
      _lastSubmitAt = now;

      state = state.copyWith(
        status: CambioAlmacenStatus.success,
        message: 'Cambio de almacen registrado en Google Forms',
        clearError: true,
      );
    } catch (error) {
      final message = _cleanError(error);
      if (_debeEncolar(message)) {
        await _encolar(usuario: usuario, baseError: message);
      } else {
        state = state.copyWith(
          status: CambioAlmacenStatus.error,
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
          status: CambioAlmacenStatus.success,
          message: 'No hay cambios de almacen pendientes',
          clearError: true,
        );
      }
      return;
    }

    _submitLock = true;
    final previousStatus = state.status;
    if (!silent) {
      state = state.copyWith(
        status: CambioAlmacenStatus.drainingQueue,
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
          final form = CambioAlmacenFormData(
            qrCampos: job.qrCampos,
            numTelar: job.numTelar,
            codigoTelas: job.codigoTelas,
            ordenOperacion: job.ordenOperacion,
            articulo: job.articulo,
            numPlegador: job.numPlegador,
            metroCorte: job.metroCorte,
            pesoKg: job.pesoKg,
            fechaCorte: job.fechaCorte,
            fechaRevisado: job.fechaRevisado,
            almacen: job.almacen,
            ubicacion: job.ubicacion,
            fechaSalida: job.fechaSalida,
            horaSalida: job.horaSalida,
            servicio: job.servicio,
          );

          await _datasource.enviarCambioAlmacen(form);

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
                    ? CambioAlmacenStatus.success
                    : CambioAlmacenStatus.error),
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
      status: CambioAlmacenStatus.idle,
      clearError: true,
      clearMessage: true,
    );
  }

  Future<void> limpiarCola() async {
    await _saveQueueAndTelemetry(
      const <CambioAlmacenQueueJobModel>[],
      state.telemetry,
    );
    state = state.copyWith(
      queue: const <CambioAlmacenQueueJobModel>[],
      status: CambioAlmacenStatus.idle,
      message: 'Cola de cambio almacen limpiada',
      clearError: true,
    );
  }

  void limpiarFormulario() {
    final defaultUbicacion = _ubicacionesPorAlmacen['PLANTA 1']!.first;
    state = state.copyWith(
      status: CambioAlmacenStatus.idle,
      qrRaw: '',
      clearParsed: true,
      almacenSeleccionado: 'PLANTA 1',
      ubicacionSeleccionada: defaultUbicacion,
      fechaSalida: '',
      horaSalida: '',
      clearError: true,
      clearMessage: true,
    );
  }

  Future<void> _encolar({
    required String usuario,
    required String baseError,
  }) async {
    final form = _buildForm(usuario);
    final now = DateTime.now();

    final job = CambioAlmacenQueueJobModel(
      id: '${now.microsecondsSinceEpoch}-${state.queue.length}',
      qrCampos: form.qrCampos,
      numTelar: form.numTelar,
      codigoTelas: form.codigoTelas,
      ordenOperacion: form.ordenOperacion,
      articulo: form.articulo,
      numPlegador: form.numPlegador,
      metroCorte: form.metroCorte,
      pesoKg: form.pesoKg,
      fechaCorte: form.fechaCorte,
      fechaRevisado: form.fechaRevisado,
      fechaSalida: form.fechaSalida,
      horaSalida: form.horaSalida,
      servicio: form.servicio,
      almacen: form.almacen,
      ubicacion: form.ubicacion,
      usuario: usuario.trim(),
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
      status: CambioAlmacenStatus.queueing,
      queue: updatedQueue,
      telemetry: updatedTelemetry,
      message: 'Sin red estable. Cambio de almacen guardado en cola segura.',
      clearError: true,
    );
  }

  CambioAlmacenFormData _buildForm(String usuario) {
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

    return CambioAlmacenFormData(
      qrCampos: parsed.camposDetectados,
      numTelar: parsed.numTelar,
      codigoTelas: parsed.codigoTelas,
      ordenOperacion: parsed.ordenOperacion,
      articulo: parsed.articulo,
      numPlegador: parsed.numPlegador,
      metroCorte: parsed.metroCorte,
      pesoKg: parsed.pesoKg,
      fechaCorte: parsed.fechaCorte,
      fechaRevisado: parsed.fechaRevisado,
      almacen: state.almacenSeleccionado,
      ubicacion: state.ubicacionSeleccionada,
      fechaSalida: fechaSalida,
      horaSalida: horaSalida,
      servicio: parsed.servicio,
    );
  }

  void _loadQueueAndTelemetry() {
    final rawQueue = _storage.getValue(
      AppConstants.keyCambioAlmacenQueue,
      defaultValue: '',
    );
    final rawTelemetry = _storage.getValue(
      AppConstants.keyCambioAlmacenTelemetry,
      defaultValue: '',
    );

    var queue = <CambioAlmacenQueueJobModel>[];
    if (rawQueue.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawQueue);
        if (decoded is List) {
          queue =
              decoded
                  .whereType<Map>()
                  .map(
                    (item) => CambioAlmacenQueueJobModel.fromJson(
                      Map<String, dynamic>.from(item),
                    ),
                  )
                  .where((job) => job.id.isNotEmpty)
                  .toList();
        }
      } catch (_) {
        queue = <CambioAlmacenQueueJobModel>[];
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
    List<CambioAlmacenQueueJobModel> queue,
    QueueTelemetryModel telemetry,
  ) async {
    final queueJson = jsonEncode(queue.map((item) => item.toJson()).toList());
    final telemetryJson = jsonEncode(telemetry.toJson());

    await _storage.setValue(AppConstants.keyCambioAlmacenQueue, queueJson);
    await _storage.setValue(
      AppConstants.keyCambioAlmacenTelemetry,
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
      parsed?.codigoTelas ?? '',
      parsed?.numTelar ?? '',
      state.almacenSeleccionado,
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

final cambioAlmacenProvider =
    StateNotifierProvider<CambioAlmacenNotifier, CambioAlmacenState>(
      (ref) => CambioAlmacenNotifier(
        ref.read(trasladosDatasourceProvider),
        ref.read(localStorageProvider),
      ),
    );
