import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_constants.dart';
import '../../core/storage/local_storage.dart';
import '../../data/datasources/remote/legacy_modules_remote_datasource.dart';
import '../../data/models/almacen_mov_queue_models.dart';
import '../../data/models/legacy_modules_queue_models.dart';
import 'auth_provider.dart';
import 'legacy_modules_datasource_provider.dart';

enum AgregarProveedorStatus {
  idle,
  saving,
  queueing,
  drainingQueue,
  success,
  error,
}

class AgregarProveedorState {
  final AgregarProveedorStatus status;
  final String proveedor;
  final String material;
  final String titulo;
  final String taraCono;
  final String taraBolsa;
  final String taraCaja;
  final String taraSaco;
  final List<AgregarProveedorQueueJobModel> queue;
  final QueueTelemetryModel telemetry;
  final String? message;
  final String? errorMessage;

  const AgregarProveedorState({
    this.status = AgregarProveedorStatus.idle,
    this.proveedor = '',
    this.material = '',
    this.titulo = '',
    this.taraCono = '',
    this.taraBolsa = '',
    this.taraCaja = '',
    this.taraSaco = '',
    this.queue = const [],
    this.telemetry = const QueueTelemetryModel(),
    this.message,
    this.errorMessage,
  });

  bool get isBusy =>
      status == AgregarProveedorStatus.saving ||
      status == AgregarProveedorStatus.queueing ||
      status == AgregarProveedorStatus.drainingQueue;

  int get pendingQueue => queue.length;

  bool get canSubmit =>
      proveedor.trim().isNotEmpty &&
      material.trim().isNotEmpty &&
      titulo.trim().isNotEmpty;

  AgregarProveedorState copyWith({
    AgregarProveedorStatus? status,
    String? proveedor,
    String? material,
    String? titulo,
    String? taraCono,
    String? taraBolsa,
    String? taraCaja,
    String? taraSaco,
    List<AgregarProveedorQueueJobModel>? queue,
    QueueTelemetryModel? telemetry,
    String? message,
    bool clearMessage = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AgregarProveedorState(
      status: status ?? this.status,
      proveedor: proveedor ?? this.proveedor,
      material: material ?? this.material,
      titulo: titulo ?? this.titulo,
      taraCono: taraCono ?? this.taraCono,
      taraBolsa: taraBolsa ?? this.taraBolsa,
      taraCaja: taraCaja ?? this.taraCaja,
      taraSaco: taraSaco ?? this.taraSaco,
      queue: queue ?? this.queue,
      telemetry: telemetry ?? this.telemetry,
      message: clearMessage ? null : (message ?? this.message),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AgregarProveedorNotifier extends StateNotifier<AgregarProveedorState> {
  final LegacyModulesRemoteDatasource _datasource;
  final LocalStorage _storage;

  bool _submitLock = false;
  String _lastSubmitSignature = '';
  DateTime? _lastSubmitAt;

  AgregarProveedorNotifier(this._datasource, this._storage)
    : super(const AgregarProveedorState()) {
    _loadQueueAndTelemetry();
  }

  void setProveedor(String value) {
    state = state.copyWith(
      proveedor: value,
      clearError: true,
      clearMessage: true,
      status: AgregarProveedorStatus.idle,
    );
  }

  void setMaterial(String value) {
    state = state.copyWith(
      material: value,
      clearError: true,
      clearMessage: true,
      status: AgregarProveedorStatus.idle,
    );
  }

  void setTitulo(String value) {
    state = state.copyWith(
      titulo: value,
      clearError: true,
      clearMessage: true,
      status: AgregarProveedorStatus.idle,
    );
  }

  void setTaraCono(String value) {
    state = state.copyWith(
      taraCono: value,
      clearError: true,
      clearMessage: true,
    );
  }

  void setTaraBolsa(String value) {
    state = state.copyWith(
      taraBolsa: value,
      clearError: true,
      clearMessage: true,
    );
  }

  void setTaraCaja(String value) {
    state = state.copyWith(
      taraCaja: value,
      clearError: true,
      clearMessage: true,
    );
  }

  void setTaraSaco(String value) {
    state = state.copyWith(
      taraSaco: value,
      clearError: true,
      clearMessage: true,
    );
  }

  Future<void> registrarProveedor() async {
    if (_submitLock || state.isBusy) return;

    if (!state.canSubmit) {
      state = state.copyWith(
        status: AgregarProveedorStatus.error,
        errorMessage: 'Complete proveedor, material y titulo antes de guardar',
      );
      return;
    }

    final signature = _signature();
    final now = DateTime.now();
    final duplicated =
        signature == _lastSubmitSignature &&
        _lastSubmitAt != null &&
        now.difference(_lastSubmitAt!).inSeconds < 8;

    if (duplicated) {
      state = state.copyWith(
        status: AgregarProveedorStatus.error,
        errorMessage:
            'Se detecto un envio duplicado. Espere unos segundos para reenviar.',
      );
      return;
    }

    _submitLock = true;
    state = state.copyWith(
      status: AgregarProveedorStatus.saving,
      clearError: true,
      clearMessage: true,
    );

    final payload = _buildPayload();

    try {
      await _datasource.registrarProveedor(payload);

      _lastSubmitSignature = signature;
      _lastSubmitAt = now;

      state = state.copyWith(
        status: AgregarProveedorStatus.success,
        proveedor: '',
        material: '',
        titulo: '',
        taraCono: '',
        taraBolsa: '',
        taraCaja: '',
        taraSaco: '',
        message: 'Proveedor registrado correctamente',
        clearError: true,
      );
    } catch (error) {
      final message = _cleanError(error);
      if (_debeEncolar(message)) {
        await _encolar(payload, message);
      } else {
        state = state.copyWith(
          status: AgregarProveedorStatus.error,
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
          status: AgregarProveedorStatus.success,
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
        status: AgregarProveedorStatus.drainingQueue,
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
          await _datasource.registrarProveedor(
            AgregarProveedorPayload(
              proveedor: job.proveedor,
              material: job.material,
              titulo: job.titulo,
              taraCono: job.taraCono,
              taraBolsa: job.taraBolsa,
              taraCaja: job.taraCaja,
              taraSaco: job.taraSaco,
            ),
          );

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
                    ? AgregarProveedorStatus.success
                    : AgregarProveedorStatus.error),
        message:
            !silent && processed > 0
                ? 'Cola procesada: $processed proveedor(es). Pendientes: ${queue.length}'
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
      status: AgregarProveedorStatus.idle,
      clearError: true,
      clearMessage: true,
    );
  }

  Future<void> limpiarCola() async {
    await _saveQueueAndTelemetry(
      const <AgregarProveedorQueueJobModel>[],
      state.telemetry,
    );
    state = state.copyWith(
      queue: const <AgregarProveedorQueueJobModel>[],
      status: AgregarProveedorStatus.idle,
      message: 'Cola de proveedores limpiada',
      clearError: true,
    );
  }

  void limpiarFormulario() {
    state = state.copyWith(
      status: AgregarProveedorStatus.idle,
      proveedor: '',
      material: '',
      titulo: '',
      taraCono: '',
      taraBolsa: '',
      taraCaja: '',
      taraSaco: '',
      clearError: true,
      clearMessage: true,
    );
  }

  Future<void> _encolar(
    AgregarProveedorPayload payload,
    String baseError,
  ) async {
    final now = DateTime.now();

    final job = AgregarProveedorQueueJobModel(
      id: '${now.microsecondsSinceEpoch}-${state.queue.length}',
      proveedor: payload.proveedor,
      material: payload.material,
      titulo: payload.titulo,
      taraCono: payload.taraCono,
      taraBolsa: payload.taraBolsa,
      taraCaja: payload.taraCaja,
      taraSaco: payload.taraSaco,
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
      status: AgregarProveedorStatus.queueing,
      queue: updatedQueue,
      telemetry: updatedTelemetry,
      proveedor: '',
      material: '',
      titulo: '',
      taraCono: '',
      taraBolsa: '',
      taraCaja: '',
      taraSaco: '',
      message:
          'Sin conexion estable. Registro de proveedor guardado en cola segura.',
      clearError: true,
    );
  }

  AgregarProveedorPayload _buildPayload() {
    return AgregarProveedorPayload(
      proveedor: state.proveedor.trim(),
      material: state.material.trim(),
      titulo: state.titulo.trim(),
      taraCono: _sanitizeTara(state.taraCono),
      taraBolsa: _sanitizeTara(state.taraBolsa),
      taraCaja: _sanitizeTara(state.taraCaja),
      taraSaco: _sanitizeTara(state.taraSaco),
    );
  }

  String _sanitizeTara(String value) {
    final clean = value.trim().replaceAll(',', '.');
    if (clean.isEmpty) return '0';
    final parsed = double.tryParse(clean);
    if (parsed == null) return '0';
    if (parsed == parsed.roundToDouble()) {
      return parsed.toInt().toString();
    }
    return parsed
        .toStringAsFixed(3)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  String _signature() {
    return [
      state.proveedor.trim().toUpperCase(),
      state.material.trim().toUpperCase(),
      state.titulo.trim().toUpperCase(),
      _sanitizeTara(state.taraCono),
      _sanitizeTara(state.taraBolsa),
      _sanitizeTara(state.taraCaja),
      _sanitizeTara(state.taraSaco),
    ].join('|');
  }

  bool _debeEncolar(String message) {
    final text = message.toLowerCase();
    final isConfig =
        text.contains('credencial') ||
        text.contains('service account') ||
        text.contains('google_sheets_sa_b64') ||
        text.contains('worksheet');
    if (isConfig) return false;

    return text.contains('no se puede conectar') ||
        text.contains('timeout') ||
        text.contains('connection') ||
        text.contains('socket') ||
        text.contains('network') ||
        text.contains('internet');
  }

  void _loadQueueAndTelemetry() {
    final rawQueue = _storage.getValue(
      AppConstants.keyAgregarProveedorQueue,
      defaultValue: '',
    );
    final rawTelemetry = _storage.getValue(
      AppConstants.keyAgregarProveedorTelemetry,
      defaultValue: '',
    );

    var queue = <AgregarProveedorQueueJobModel>[];
    if (rawQueue.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawQueue);
        if (decoded is List) {
          queue =
              decoded
                  .whereType<Map>()
                  .map(
                    (item) => AgregarProveedorQueueJobModel.fromJson(
                      Map<String, dynamic>.from(item),
                    ),
                  )
                  .where((job) => job.id.isNotEmpty)
                  .toList();
        }
      } catch (_) {
        queue = <AgregarProveedorQueueJobModel>[];
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
    List<AgregarProveedorQueueJobModel> queue,
    QueueTelemetryModel telemetry,
  ) async {
    final queueJson = jsonEncode(queue.map((item) => item.toJson()).toList());
    final telemetryJson = jsonEncode(telemetry.toJson());

    await _storage.setValue(AppConstants.keyAgregarProveedorQueue, queueJson);
    await _storage.setValue(
      AppConstants.keyAgregarProveedorTelemetry,
      telemetryJson,
    );
  }

  String _cleanError(Object error) {
    return error.toString().replaceAll('Exception: ', '').trim();
  }
}

final agregarProveedorProvider =
    StateNotifierProvider<AgregarProveedorNotifier, AgregarProveedorState>(
      (ref) => AgregarProveedorNotifier(
        ref.read(legacyModulesDatasourceProvider),
        ref.read(localStorageProvider),
      ),
    );
