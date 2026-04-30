import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_constants.dart';
import '../../core/storage/local_storage.dart';
import '../../core/utils/qr_image_encoder.dart';
import '../../data/models/almacen_mov_queue_models.dart';
import '../../data/datasources/remote/impresion_local_remote_datasource.dart';
import '../../data/datasources/remote/produccion_remote_datasource.dart';
import '../../data/models/etiqueta_payload.dart';
import '../../data/models/print_job_model.dart';
import 'auth_provider.dart';

enum ImpresionEtiquetaStatus {
  idle,
  parsing,
  generatingKardex,
  printing,
  queueing,
  drainingQueue,
  success,
  error,
}

class ImpresionEtiquetaState {
  final ImpresionEtiquetaStatus status;
  final String qrRaw;
  final EtiquetaPayload? payload;
  final String generatedKardex;
  final List<PrintJobModel> queue;
  final QueueTelemetryModel telemetry;
  final bool localApiDisponible;
  final String? message;
  final String? errorMessage;

  const ImpresionEtiquetaState({
    this.status = ImpresionEtiquetaStatus.idle,
    this.qrRaw = '',
    this.payload,
    this.generatedKardex = '',
    this.queue = const [],
    this.telemetry = const QueueTelemetryModel(),
    this.localApiDisponible = false,
    this.message,
    this.errorMessage,
  });

  bool get isBusy =>
      status == ImpresionEtiquetaStatus.parsing ||
      status == ImpresionEtiquetaStatus.generatingKardex ||
      status == ImpresionEtiquetaStatus.printing ||
      status == ImpresionEtiquetaStatus.queueing ||
      status == ImpresionEtiquetaStatus.drainingQueue;

  ImpresionEtiquetaState copyWith({
    ImpresionEtiquetaStatus? status,
    String? qrRaw,
    EtiquetaPayload? payload,
    bool clearPayload = false,
    String? generatedKardex,
    bool clearGeneratedKardex = false,
    List<PrintJobModel>? queue,
    QueueTelemetryModel? telemetry,
    bool? localApiDisponible,
    String? message,
    bool clearMessage = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ImpresionEtiquetaState(
      status: status ?? this.status,
      qrRaw: qrRaw ?? this.qrRaw,
      payload: clearPayload ? null : (payload ?? this.payload),
      generatedKardex:
          clearGeneratedKardex ? '' : (generatedKardex ?? this.generatedKardex),
      queue: queue ?? this.queue,
      telemetry: telemetry ?? this.telemetry,
      localApiDisponible: localApiDisponible ?? this.localApiDisponible,
      message: clearMessage ? null : (message ?? this.message),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final impresionEtiquetaDatasourceProvider =
    Provider<ImpresionLocalRemoteDatasource>(
      (ref) => ImpresionLocalRemoteDatasource(ref.read(localApiClientProvider)),
    );

final impresionEtiquetaProduccionDatasourceProvider =
    Provider<ProduccionRemoteDatasource>(
      (ref) => ProduccionRemoteDatasource(
        ref.read(apiClientProvider),
        ref.read(localStorageProvider),
      ),
    );

class ImpresionEtiquetaNotifier extends StateNotifier<ImpresionEtiquetaState> {
  final ImpresionLocalRemoteDatasource _datasource;
  final ProduccionRemoteDatasource _produccionDatasource;
  final LocalStorage _storage;

  bool _printLock = false;

  ImpresionEtiquetaNotifier(
    this._datasource,
    this._produccionDatasource,
    this._storage,
  ) : super(const ImpresionEtiquetaState()) {
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    _loadQueueAndTelemetry();
    await refrescarEstadoApi();
  }

  void setQrRaw(String value) {
    state = state.copyWith(
      qrRaw: value,
      clearPayload: true,
      clearGeneratedKardex: true,
      clearError: true,
      clearMessage: true,
      status: ImpresionEtiquetaStatus.idle,
    );
  }

  Future<void> parsearQr() async {
    if (state.qrRaw.trim().isEmpty) {
      state = state.copyWith(
        status: ImpresionEtiquetaStatus.error,
        errorMessage: 'Ingrese o escanee un QR para continuar',
      );
      return;
    }

    state = state.copyWith(
      status: ImpresionEtiquetaStatus.parsing,
      clearError: true,
      clearMessage: true,
    );

    try {
      final payload = EtiquetaPayloadBuilder.fromQrRaw(
        state.qrRaw,
        codigoKardexOverride: state.generatedKardex,
      );
      state = state.copyWith(
        status: ImpresionEtiquetaStatus.success,
        payload: payload,
        message: 'QR listo para generar etiqueta',
      );
    } catch (error) {
      state = state.copyWith(
        status: ImpresionEtiquetaStatus.error,
        errorMessage: _cleanError(error),
      );
    }
  }

  Future<void> generarKardex({
    required String material,
    required String titulo,
    required String color,
  }) async {
    if (state.isBusy) return;

    state = state.copyWith(
      status: ImpresionEtiquetaStatus.generatingKardex,
      clearError: true,
      clearMessage: true,
    );

    try {
      final kardex = await _produccionDatasource.generarKardex(
        material: material,
        titulo: titulo,
        color: color,
      );

      final payload =
          state.qrRaw.trim().isEmpty
              ? state.payload
              : EtiquetaPayloadBuilder.fromQrRaw(
                state.qrRaw,
                codigoKardexOverride: kardex,
              );

      state = state.copyWith(
        status: ImpresionEtiquetaStatus.success,
        generatedKardex: kardex,
        payload: payload,
        message: 'Kardex generado: $kardex',
      );
    } catch (error) {
      state = state.copyWith(
        status: ImpresionEtiquetaStatus.error,
        errorMessage: _cleanError(error),
      );
    }
  }

  Future<void> imprimirConFallbackOffline() async {
    if (_printLock || state.isBusy) return;

    _printLock = true;
    try {
      final payload =
          state.payload ??
          EtiquetaPayloadBuilder.fromQrRaw(
            state.qrRaw,
            codigoKardexOverride: state.generatedKardex,
          );

      state = state.copyWith(
        status: ImpresionEtiquetaStatus.printing,
        payload: payload,
        clearError: true,
        clearMessage: true,
      );

      final imageBase64 = await QrImageEncoder.toBase64Png(payload.qrRaw);
      await _datasource.generarPdfEtiqueta(
        payload: payload,
        imageBase64: imageBase64,
      );
      final printResult = await _datasource.imprimirEtiqueta();

      await refrescarEstadoApi();

      state = state.copyWith(
        status: ImpresionEtiquetaStatus.success,
        message: printResult.message,
        clearError: true,
      );
    } catch (error) {
      final message = _cleanError(error);
      final shouldQueue = await _debeEncolar(message);

      if (shouldQueue) {
        await _encolarTrabajoActual();
        state = state.copyWith(
          status: ImpresionEtiquetaStatus.success,
          message: 'API local no disponible. Etiqueta guardada en cola segura.',
          errorMessage: null,
        );
      } else {
        state = state.copyWith(
          status: ImpresionEtiquetaStatus.error,
          errorMessage: message,
        );
      }
    } finally {
      _printLock = false;
    }
  }

  Future<void> procesarColaPendiente({bool silent = false}) async {
    if (_printLock || state.isBusy) return;
    if (state.queue.isEmpty) {
      if (!silent) {
        state = state.copyWith(
          status: ImpresionEtiquetaStatus.success,
          message: 'No hay etiquetas pendientes en cola',
          clearError: true,
        );
      }
      return;
    }

    _printLock = true;
    final previousStatus = state.status;
    if (!silent) {
      state = state.copyWith(
        status: ImpresionEtiquetaStatus.drainingQueue,
        clearError: true,
        clearMessage: true,
      );
    }

    try {
      final available = await _datasource.isApiDisponible();
      state = state.copyWith(localApiDisponible: available);
      if (!available) {
        throw Exception('API local offline. No se puede procesar la cola.');
      }

      var queue = [...state.queue];
      var processed = 0;
      var telemetry = state.telemetry;

      while (queue.isNotEmpty) {
        final job = queue.first;
        final nowIso = DateTime.now().toIso8601String();
        try {
          final payload = EtiquetaPayload(
            qrRaw: job.qrRaw,
            text: job.text,
            codigo: job.codigo,
            codigoKardex: '',
            lote: job.lote,
            articulo: job.articulo,
            metraje: job.metraje,
            revisador: job.revisador,
          );

          final imageBase64 = await QrImageEncoder.toBase64Png(payload.qrRaw);
          await _datasource.generarPdfEtiqueta(
            payload: payload,
            imageBase64: imageBase64,
          );
          await _datasource.imprimirEtiqueta();

          queue.removeAt(0);
          processed++;
          telemetry = telemetry.copyWith(
            processedTotal: telemetry.processedTotal + 1,
            lastProcessedAtIso: nowIso,
            lastAttemptAtIso: nowIso,
            lastError: '',
          );
        } catch (error) {
          final updated = job.copyWith(attempts: job.attempts + 1);
          queue[0] = updated;
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
      await refrescarEstadoApi();

      final pending = queue.length;
      state = state.copyWith(
        status:
            silent
                ? previousStatus
                : (pending == 0
                    ? ImpresionEtiquetaStatus.success
                    : ImpresionEtiquetaStatus.error),
        queue: queue,
        telemetry: telemetry,
        message:
            !silent && processed > 0
                ? 'Cola procesada: $processed impresiones enviadas. Pendientes: $pending'
                : null,
        errorMessage:
            silent || pending == 0
                ? null
                : 'Se detuvo la cola por error de impresion. Pendientes: $pending',
      );
    } catch (error) {
      if (!silent) {
        state = state.copyWith(
          status: ImpresionEtiquetaStatus.error,
          errorMessage: _cleanError(error),
        );
      }
    } finally {
      _printLock = false;
    }
  }

  Future<void> eliminarTrabajoCola(String jobId) async {
    final updated = state.queue.where((item) => item.id != jobId).toList();
    await _guardarQueueAndTelemetry(updated, state.telemetry);
    state = state.copyWith(
      queue: updated,
      status: ImpresionEtiquetaStatus.idle,
      clearError: true,
      clearMessage: true,
    );
  }

  Future<void> limpiarCola() async {
    await _guardarQueueAndTelemetry(const [], state.telemetry);
    state = state.copyWith(
      queue: const [],
      status: ImpresionEtiquetaStatus.idle,
      message: 'Cola de impresion limpiada',
      clearError: true,
    );
  }

  void limpiarFormulario() {
    state = state.copyWith(
      qrRaw: '',
      clearPayload: true,
      clearGeneratedKardex: true,
      status: ImpresionEtiquetaStatus.idle,
      clearError: true,
      clearMessage: true,
    );
  }

  Future<void> refrescarEstadoApi() async {
    final available = await _datasource.isApiDisponible();
    state = state.copyWith(localApiDisponible: available);
  }

  Future<void> _encolarTrabajoActual() async {
    final payload =
        state.payload ??
        EtiquetaPayloadBuilder.fromQrRaw(
          state.qrRaw,
          codigoKardexOverride: state.generatedKardex,
        );

    final now = DateTime.now();
    final job = PrintJobModel(
      id: '${now.microsecondsSinceEpoch}-${state.queue.length}',
      qrRaw: payload.qrRaw,
      text: payload.text,
      codigo: payload.codigo,
      lote: payload.lote,
      articulo: payload.articulo,
      metraje: payload.metraje,
      revisador: payload.revisador,
      createdAtIso: now.toIso8601String(),
    );

    final updated = [...state.queue, job];
    final updatedTelemetry = state.telemetry.copyWith(
      enqueuedTotal: state.telemetry.enqueuedTotal + 1,
      lastAttemptAtIso: now.toIso8601String(),
    );
    await _guardarQueueAndTelemetry(updated, updatedTelemetry);
    state = state.copyWith(
      queue: updated,
      telemetry: updatedTelemetry,
      status: ImpresionEtiquetaStatus.queueing,
      payload: payload,
    );
  }

  Future<bool> _debeEncolar(String errorMessage) async {
    final text = errorMessage.toLowerCase();

    if (text.contains('no se puede conectar') ||
        text.contains('connection') ||
        text.contains('timeout') ||
        text.contains('socket')) {
      return true;
    }

    final apiOk = await _datasource.isApiDisponible();
    return !apiOk;
  }

  void _loadQueueAndTelemetry() {
    final raw = _storage.getValue(AppConstants.keyPrintQueue, defaultValue: '');
    final rawTelemetry = _storage.getValue(
      AppConstants.keyPrintTelemetry,
      defaultValue: '',
    );

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

    if (raw.trim().isEmpty) {
      state = state.copyWith(queue: const [], telemetry: telemetry);
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        state = state.copyWith(queue: const [], telemetry: telemetry);
        return;
      }

      final queue =
          decoded
              .whereType<Map>()
              .map(
                (item) =>
                    PrintJobModel.fromJson(Map<String, dynamic>.from(item)),
              )
              .where((job) => job.id.isNotEmpty && job.qrRaw.isNotEmpty)
              .toList();

      state = state.copyWith(queue: queue, telemetry: telemetry);
    } catch (_) {
      state = state.copyWith(queue: const [], telemetry: telemetry);
    }
  }

  Future<void> _guardarQueueAndTelemetry(
    List<PrintJobModel> queue,
    QueueTelemetryModel telemetry,
  ) async {
    final json = jsonEncode(queue.map((item) => item.toJson()).toList());
    final telemetryJson = jsonEncode(telemetry.toJson());
    await _storage.setValue(AppConstants.keyPrintQueue, json);
    await _storage.setValue(AppConstants.keyPrintTelemetry, telemetryJson);
  }

  String _cleanError(Object error) {
    return error.toString().replaceAll('Exception: ', '').trim();
  }
}

final impresionEtiquetaProvider =
    StateNotifierProvider<ImpresionEtiquetaNotifier, ImpresionEtiquetaState>(
      (ref) => ImpresionEtiquetaNotifier(
        ref.read(impresionEtiquetaDatasourceProvider),
        ref.read(impresionEtiquetaProduccionDatasourceProvider),
        ref.read(localStorageProvider),
      ),
    );
