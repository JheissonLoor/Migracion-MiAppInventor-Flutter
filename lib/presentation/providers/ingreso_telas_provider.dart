import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_constants.dart';
import '../../core/storage/local_storage.dart';
import '../../core/utils/ingreso_hilos_qr_parser.dart';
import '../../data/datasources/remote/legacy_modules_remote_datasource.dart';
import '../../data/models/almacen_mov_queue_models.dart';
import '../../data/models/legacy_modules_queue_models.dart';
import 'auth_provider.dart';
import 'legacy_modules_datasource_provider.dart';

enum IngresoTelasStatus {
  idle,
  parsingQr,
  consultingStock,
  sending,
  queueing,
  drainingQueue,
  success,
  error,
}

class IngresoTelasState {
  final IngresoTelasStatus status;
  final String qrRaw;
  final IngresoHilosQrData? parsedQr;
  final IngresoStockActualData? stockData;
  final List<IngresoTelasQueueJobModel> queue;
  final QueueTelemetryModel telemetry;
  final String? message;
  final String? errorMessage;

  const IngresoTelasState({
    this.status = IngresoTelasStatus.idle,
    this.qrRaw = '',
    this.parsedQr,
    this.stockData,
    this.queue = const [],
    this.telemetry = const QueueTelemetryModel(),
    this.message,
    this.errorMessage,
  });

  bool get isBusy =>
      status == IngresoTelasStatus.parsingQr ||
      status == IngresoTelasStatus.consultingStock ||
      status == IngresoTelasStatus.sending ||
      status == IngresoTelasStatus.queueing ||
      status == IngresoTelasStatus.drainingQueue;

  int get pendingQueue => queue.length;

  bool get canSubmit {
    return parsedQr != null &&
        stockData != null &&
        stockData!.codigoPcp.trim().isNotEmpty &&
        stockData!.codigoKardex.trim().isNotEmpty;
  }

  IngresoTelasState copyWith({
    IngresoTelasStatus? status,
    String? qrRaw,
    IngresoHilosQrData? parsedQr,
    bool clearParsedQr = false,
    IngresoStockActualData? stockData,
    bool clearStockData = false,
    List<IngresoTelasQueueJobModel>? queue,
    QueueTelemetryModel? telemetry,
    String? message,
    bool clearMessage = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return IngresoTelasState(
      status: status ?? this.status,
      qrRaw: qrRaw ?? this.qrRaw,
      parsedQr: clearParsedQr ? null : (parsedQr ?? this.parsedQr),
      stockData: clearStockData ? null : (stockData ?? this.stockData),
      queue: queue ?? this.queue,
      telemetry: telemetry ?? this.telemetry,
      message: clearMessage ? null : (message ?? this.message),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class IngresoTelasNotifier extends StateNotifier<IngresoTelasState> {
  final LegacyModulesRemoteDatasource _datasource;
  final LocalStorage _storage;

  bool _submitLock = false;
  String _lastSubmitSignature = '';
  DateTime? _lastSubmitAt;

  IngresoTelasNotifier(this._datasource, this._storage)
    : super(const IngresoTelasState()) {
    _loadQueueAndTelemetry();
  }

  void setQrRaw(String value) {
    state = state.copyWith(
      qrRaw: value,
      clearError: true,
      clearMessage: true,
      status: IngresoTelasStatus.idle,
    );
  }

  Future<void> parsearQrYConsultar() async {
    final raw = state.qrRaw.trim();
    if (raw.isEmpty) {
      state = state.copyWith(
        status: IngresoTelasStatus.error,
        errorMessage: 'Escanee o pegue un QR antes de procesar',
      );
      return;
    }

    state = state.copyWith(
      status: IngresoTelasStatus.parsingQr,
      clearError: true,
      clearMessage: true,
    );

    final result = IngresoHilosQrParser.parse(raw);
    if (!result.isValid || result.data == null) {
      state = state.copyWith(
        status: IngresoTelasStatus.error,
        errorMessage: result.error ?? 'No se pudo leer el QR',
      );
      return;
    }

    state = state.copyWith(
      parsedQr: result.data,
      status: IngresoTelasStatus.consultingStock,
      clearError: true,
      clearMessage: true,
    );

    await consultarStockActual();
  }

  Future<void> consultarStockActual() async {
    final parsed = state.parsedQr;
    if (parsed == null) {
      state = state.copyWith(
        status: IngresoTelasStatus.error,
        errorMessage: 'Debe parsear un QR antes de consultar stock',
      );
      return;
    }

    state = state.copyWith(
      status: IngresoTelasStatus.consultingStock,
      clearError: true,
      clearMessage: true,
    );

    try {
      final stock = await _datasource.consultarStockActualPcp(
        parsed.codigoPcp,
        fallbackCodigoPcp: parsed.codigoPcp,
        fallbackCodigoKardex: parsed.codigoKardex,
      );
      state = state.copyWith(
        status: IngresoTelasStatus.success,
        stockData: stock,
        message: 'Datos cargados correctamente desde /stock_actual_pcp',
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        status: IngresoTelasStatus.error,
        errorMessage: _cleanError(error),
      );
    }
  }

  Future<void> enviarIngreso() async {
    if (_submitLock || state.isBusy) return;
    if (!state.canSubmit || state.parsedQr == null || state.stockData == null) {
      state = state.copyWith(
        status: IngresoTelasStatus.error,
        errorMessage:
            'Datos incompletos. Vuelva a escanear y espere la consulta de stock.',
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
        status: IngresoTelasStatus.error,
        errorMessage:
            'Se detecto envio duplicado. Espere unos segundos antes de reenviar.',
      );
      return;
    }

    _submitLock = true;
    state = state.copyWith(
      status: IngresoTelasStatus.sending,
      clearError: true,
      clearMessage: true,
    );

    final form = _buildFormData();
    try {
      await _datasource.enviarIngresoTelas(form);

      _lastSubmitSignature = signature;
      _lastSubmitAt = now;

      state = state.copyWith(
        status: IngresoTelasStatus.success,
        qrRaw: '',
        clearParsedQr: true,
        clearStockData: true,
        message: 'Informacion almacenada correctamente',
        clearError: true,
      );
    } catch (error) {
      final message = _cleanError(error);
      if (_debeEncolar(message)) {
        await _encolar(form, message);
      } else {
        state = state.copyWith(
          status: IngresoTelasStatus.error,
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
          status: IngresoTelasStatus.success,
          message: 'No hay ingresos de telas pendientes',
          clearError: true,
        );
      }
      return;
    }

    _submitLock = true;
    final previousStatus = state.status;
    if (!silent) {
      state = state.copyWith(
        status: IngresoTelasStatus.drainingQueue,
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
          await _datasource.enviarIngresoTelas(
            IngresoTelasFormData(
              qrCampos: job.qrCampos,
              codigoKardex: job.codigoKardex,
              codigoPcp: job.codigoPcp,
              material: job.material,
              titulo: job.titulo,
              color: job.color,
              lote: job.lote,
              numCajas: job.numCajas,
              totalBobinas: job.totalBobinas,
              cantidadReenconado: job.cantidadReenconado,
              pesoBruto: job.pesoBruto,
              pesoNeto: job.pesoNeto,
              proveedor: job.proveedor,
              fechaIngreso: job.fechaIngreso,
              almacen: job.almacen,
              ubicacion: job.ubicacion,
              servicio: job.servicio,
              nombre: job.nombre,
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
                    ? IngresoTelasStatus.success
                    : IngresoTelasStatus.error),
        message:
            !silent && processed > 0
                ? 'Cola procesada: $processed ingreso(s). Pendientes: ${queue.length}'
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
      status: IngresoTelasStatus.idle,
      clearError: true,
      clearMessage: true,
    );
  }

  Future<void> limpiarCola() async {
    await _saveQueueAndTelemetry(
      const <IngresoTelasQueueJobModel>[],
      state.telemetry,
    );
    state = state.copyWith(
      queue: const <IngresoTelasQueueJobModel>[],
      status: IngresoTelasStatus.idle,
      message: 'Cola de ingreso telas limpiada',
      clearError: true,
    );
  }

  void limpiarFormulario() {
    state = state.copyWith(
      status: IngresoTelasStatus.idle,
      qrRaw: '',
      clearParsedQr: true,
      clearStockData: true,
      clearError: true,
      clearMessage: true,
    );
  }

  IngresoTelasFormData _buildFormData() {
    final parsed = state.parsedQr!;
    final stock = state.stockData!;

    return IngresoTelasFormData(
      qrCampos: parsed.camposDetectados,
      codigoKardex: stock.codigoKardex,
      codigoPcp: stock.codigoPcp,
      material: stock.material,
      titulo: stock.titulo,
      color: stock.color,
      lote: stock.lote,
      numCajas: stock.numCajas,
      totalBobinas: stock.totalBobinas,
      cantidadReenconado: stock.cantidadReenconado,
      pesoBruto: stock.pesoBruto,
      pesoNeto: stock.pesoNeto,
      proveedor: stock.proveedor,
      fechaIngreso: stock.fechaIngreso,
      almacen: stock.almacen,
      ubicacion: stock.ubicacion,
      servicio:
          stock.servicio.trim().isNotEmpty ? stock.servicio : parsed.servicio,
      nombre: stock.nombre,
    );
  }

  Future<void> _encolar(IngresoTelasFormData form, String baseError) async {
    final now = DateTime.now();
    final job = IngresoTelasQueueJobModel(
      id: '${now.microsecondsSinceEpoch}-${state.queue.length}',
      qrCampos: form.qrCampos,
      codigoKardex: form.codigoKardex,
      codigoPcp: form.codigoPcp,
      material: form.material,
      titulo: form.titulo,
      color: form.color,
      lote: form.lote,
      numCajas: form.numCajas,
      totalBobinas: form.totalBobinas,
      cantidadReenconado: form.cantidadReenconado,
      pesoBruto: form.pesoBruto,
      pesoNeto: form.pesoNeto,
      proveedor: form.proveedor,
      fechaIngreso: form.fechaIngreso,
      almacen: form.almacen,
      ubicacion: form.ubicacion,
      servicio: form.servicio,
      nombre: form.nombre,
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
      status: IngresoTelasStatus.queueing,
      queue: updatedQueue,
      telemetry: updatedTelemetry,
      qrRaw: '',
      clearParsedQr: true,
      clearStockData: true,
      message: 'Sin red estable. Ingreso guardado en cola segura.',
      clearError: true,
    );
  }

  String _signature() {
    final stock = state.stockData!;
    final parsed = state.parsedQr!;
    return [
      parsed.camposDetectados.toString(),
      stock.codigoPcp.trim().toUpperCase(),
      stock.fechaIngreso.trim().toUpperCase(),
      stock.ubicacion.trim().toUpperCase(),
    ].join('|');
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

  void _loadQueueAndTelemetry() {
    final rawQueue = _storage.getValue(
      AppConstants.keyIngresoTelasQueue,
      defaultValue: '',
    );
    final rawTelemetry = _storage.getValue(
      AppConstants.keyIngresoTelasTelemetry,
      defaultValue: '',
    );

    var queue = <IngresoTelasQueueJobModel>[];
    if (rawQueue.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawQueue);
        if (decoded is List) {
          queue =
              decoded
                  .whereType<Map>()
                  .map(
                    (item) => IngresoTelasQueueJobModel.fromJson(
                      Map<String, dynamic>.from(item),
                    ),
                  )
                  .where((job) => job.id.isNotEmpty)
                  .toList();
        }
      } catch (_) {
        queue = <IngresoTelasQueueJobModel>[];
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
    List<IngresoTelasQueueJobModel> queue,
    QueueTelemetryModel telemetry,
  ) async {
    final queueJson = jsonEncode(queue.map((item) => item.toJson()).toList());
    final telemetryJson = jsonEncode(telemetry.toJson());

    await _storage.setValue(AppConstants.keyIngresoTelasQueue, queueJson);
    await _storage.setValue(
      AppConstants.keyIngresoTelasTelemetry,
      telemetryJson,
    );
  }

  String _cleanError(Object error) {
    return error.toString().replaceAll('Exception: ', '').trim();
  }
}

final ingresoTelasProvider =
    StateNotifierProvider<IngresoTelasNotifier, IngresoTelasState>(
      (ref) => IngresoTelasNotifier(
        ref.read(legacyModulesDatasourceProvider),
        ref.read(localStorageProvider),
      ),
    );
