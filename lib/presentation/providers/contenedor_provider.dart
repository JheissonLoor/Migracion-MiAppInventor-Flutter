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

enum ContenedorStatus {
  idle,
  parsingQr,
  calculating,
  sending,
  queueing,
  drainingQueue,
  success,
  error,
}

class ContenedorState {
  final ContenedorStatus status;
  final String qrRaw;
  final IngresoHilosQrData? parsedQr;
  final String nroConos;
  final String pesoBruto;
  final String pesoNeto;
  final String numCajasMovidas;
  final String totalBobinas;
  final String pesoBrutoTotal;
  final String pesoNetoTotal;
  final String fechaSalida;
  final List<ContenedorQueueJobModel> queue;
  final QueueTelemetryModel telemetry;
  final String? message;
  final String? errorMessage;

  const ContenedorState({
    this.status = ContenedorStatus.idle,
    this.qrRaw = '',
    this.parsedQr,
    this.nroConos = '',
    this.pesoBruto = '',
    this.pesoNeto = '',
    this.numCajasMovidas = '',
    this.totalBobinas = '',
    this.pesoBrutoTotal = '',
    this.pesoNetoTotal = '',
    this.fechaSalida = '',
    this.queue = const [],
    this.telemetry = const QueueTelemetryModel(),
    this.message,
    this.errorMessage,
  });

  bool get isBusy =>
      status == ContenedorStatus.parsingQr ||
      status == ContenedorStatus.calculating ||
      status == ContenedorStatus.sending ||
      status == ContenedorStatus.queueing ||
      status == ContenedorStatus.drainingQueue;

  int get pendingQueue => queue.length;

  bool get canCalculate =>
      parsedQr != null &&
      nroConos.trim().isNotEmpty &&
      pesoBruto.trim().isNotEmpty &&
      pesoNeto.trim().isNotEmpty &&
      numCajasMovidas.trim().isNotEmpty;

  bool get canSubmit =>
      parsedQr != null &&
      totalBobinas.trim().isNotEmpty &&
      pesoBrutoTotal.trim().isNotEmpty &&
      pesoNetoTotal.trim().isNotEmpty;

  ContenedorState copyWith({
    ContenedorStatus? status,
    String? qrRaw,
    IngresoHilosQrData? parsedQr,
    bool clearParsedQr = false,
    String? nroConos,
    String? pesoBruto,
    String? pesoNeto,
    String? numCajasMovidas,
    String? totalBobinas,
    String? pesoBrutoTotal,
    String? pesoNetoTotal,
    String? fechaSalida,
    List<ContenedorQueueJobModel>? queue,
    QueueTelemetryModel? telemetry,
    String? message,
    bool clearMessage = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ContenedorState(
      status: status ?? this.status,
      qrRaw: qrRaw ?? this.qrRaw,
      parsedQr: clearParsedQr ? null : (parsedQr ?? this.parsedQr),
      nroConos: nroConos ?? this.nroConos,
      pesoBruto: pesoBruto ?? this.pesoBruto,
      pesoNeto: pesoNeto ?? this.pesoNeto,
      numCajasMovidas: numCajasMovidas ?? this.numCajasMovidas,
      totalBobinas: totalBobinas ?? this.totalBobinas,
      pesoBrutoTotal: pesoBrutoTotal ?? this.pesoBrutoTotal,
      pesoNetoTotal: pesoNetoTotal ?? this.pesoNetoTotal,
      fechaSalida: fechaSalida ?? this.fechaSalida,
      queue: queue ?? this.queue,
      telemetry: telemetry ?? this.telemetry,
      message: clearMessage ? null : (message ?? this.message),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ContenedorNotifier extends StateNotifier<ContenedorState> {
  final LegacyModulesRemoteDatasource _datasource;
  final LocalStorage _storage;

  bool _submitLock = false;
  String _lastSubmitSignature = '';
  DateTime? _lastSubmitAt;

  ContenedorNotifier(this._datasource, this._storage)
    : super(const ContenedorState()) {
    _loadQueueAndTelemetry();
  }

  void setQrRaw(String value) {
    state = state.copyWith(
      qrRaw: value,
      clearError: true,
      clearMessage: true,
      status: ContenedorStatus.idle,
    );
  }

  void setNroConos(String value) {
    state = state.copyWith(
      nroConos: value,
      clearError: true,
      clearMessage: true,
      status: ContenedorStatus.idle,
    );
  }

  void setPesoBruto(String value) {
    state = state.copyWith(
      pesoBruto: value,
      clearError: true,
      clearMessage: true,
      status: ContenedorStatus.idle,
    );
  }

  void setPesoNeto(String value) {
    state = state.copyWith(
      pesoNeto: value,
      clearError: true,
      clearMessage: true,
      status: ContenedorStatus.idle,
    );
  }

  void setNumCajasMovidas(String value) {
    state = state.copyWith(
      numCajasMovidas: value,
      clearError: true,
      clearMessage: true,
      status: ContenedorStatus.idle,
    );
  }

  Future<void> parsearQr() async {
    final raw = state.qrRaw.trim();
    if (raw.isEmpty) {
      state = state.copyWith(
        status: ContenedorStatus.error,
        errorMessage: 'Escanee o pegue un QR antes de procesar',
      );
      return;
    }

    state = state.copyWith(
      status: ContenedorStatus.parsingQr,
      clearError: true,
      clearMessage: true,
    );

    final result = IngresoHilosQrParser.parse(raw);
    if (!result.isValid || result.data == null) {
      state = state.copyWith(
        status: ContenedorStatus.error,
        errorMessage: result.error ?? 'No se pudo parsear el QR',
      );
      return;
    }

    final parsed = result.data!;
    if (parsed.camposDetectados != 16) {
      state = state.copyWith(
        status: ContenedorStatus.error,
        errorMessage:
            'Contenedor solo admite QR de 16 campos (con kardex y servicio).',
      );
      return;
    }

    state = state.copyWith(
      status: ContenedorStatus.success,
      parsedQr: parsed,
      nroConos: '',
      pesoBruto: '',
      pesoNeto: '',
      numCajasMovidas: '',
      totalBobinas: '',
      pesoBrutoTotal: '',
      pesoNetoTotal: '',
      fechaSalida: _formatDate(DateTime.now()),
      message: 'QR validado. Ingrese conos, pesos y cajas para calcular.',
      clearError: true,
    );
  }

  Future<void> recalcularTotales() async {
    if (!state.canCalculate) {
      state = state.copyWith(
        status: ContenedorStatus.error,
        errorMessage:
            'Complete nro. conos, peso bruto, peso neto y cajas para calcular.',
      );
      return;
    }

    state = state.copyWith(
      status: ContenedorStatus.calculating,
      clearError: true,
      clearMessage: true,
    );

    final cajas = _toDouble(state.numCajasMovidas);
    final conos = _toDouble(state.nroConos);
    final bruto = _toDouble(state.pesoBruto);
    final neto = _toDouble(state.pesoNeto);

    if (cajas <= 0 || conos <= 0 || bruto <= 0 || neto <= 0) {
      state = state.copyWith(
        status: ContenedorStatus.error,
        errorMessage:
            'Los campos numericos deben ser mayores a cero para calcular.',
      );
      return;
    }

    state = state.copyWith(
      status: ContenedorStatus.success,
      totalBobinas: _formatNumber(conos * cajas),
      pesoBrutoTotal: _formatNumber(bruto * cajas),
      pesoNetoTotal: _formatNumber(neto * cajas),
      message: 'Totales recalculados correctamente',
      clearError: true,
    );
  }

  Future<void> enviarContenedor({required String usuario}) async {
    if (_submitLock || state.isBusy) return;
    if (!state.canSubmit || state.parsedQr == null) {
      state = state.copyWith(
        status: ContenedorStatus.error,
        errorMessage: 'Primero calcule los totales antes de enviar',
      );
      return;
    }

    final signature = _signature(usuario);
    final now = DateTime.now();
    final duplicated =
        signature == _lastSubmitSignature &&
        _lastSubmitAt != null &&
        now.difference(_lastSubmitAt!).inSeconds < 8;
    if (duplicated) {
      state = state.copyWith(
        status: ContenedorStatus.error,
        errorMessage:
            'Se detecto envio duplicado. Espere unos segundos para reenviar.',
      );
      return;
    }

    _submitLock = true;
    state = state.copyWith(
      status: ContenedorStatus.sending,
      clearError: true,
      clearMessage: true,
    );

    final form = _buildFormData(usuario);

    try {
      await _datasource.enviarContenedor(form);
      final stockMessage = await _datasource.actualizarDatosContenedor(form);

      _lastSubmitSignature = signature;
      _lastSubmitAt = now;

      state = state.copyWith(
        status: ContenedorStatus.success,
        qrRaw: '',
        clearParsedQr: true,
        nroConos: '',
        pesoBruto: '',
        pesoNeto: '',
        numCajasMovidas: '',
        totalBobinas: '',
        pesoBrutoTotal: '',
        pesoNetoTotal: '',
        fechaSalida: _formatDate(DateTime.now()),
        message: 'Contenedor enviado. $stockMessage',
        clearError: true,
      );
    } catch (error) {
      final message = _cleanError(error);
      if (_debeEncolar(message)) {
        await _encolar(form, message);
      } else {
        state = state.copyWith(
          status: ContenedorStatus.error,
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
          status: ContenedorStatus.success,
          message: 'No hay registros de contenedor pendientes',
          clearError: true,
        );
      }
      return;
    }

    _submitLock = true;
    final previousStatus = state.status;
    if (!silent) {
      state = state.copyWith(
        status: ContenedorStatus.drainingQueue,
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
          final form = ContenedorFormData(
            qrCampos: job.qrCampos,
            codigoHc: job.codigoHc,
            material: job.material,
            titulo: job.titulo,
            color: job.color,
            lote: job.lote,
            numCajasMovidas: job.numCajasMovidas,
            nroConos: job.nroConos,
            pesoBruto: job.pesoBruto,
            pesoNeto: job.pesoNeto,
            totalBobinas: job.totalBobinas,
            pesoBrutoTotal: job.pesoBrutoTotal,
            pesoNetoTotal: job.pesoNetoTotal,
            proveedor: job.proveedor,
            fechaIngreso: job.fechaIngreso,
            fechaSalida: job.fechaSalida,
            nombreOperario: job.nombreOperario,
            usuario: job.usuario,
          );

          await _datasource.enviarContenedor(form);
          await _datasource.actualizarDatosContenedor(form);

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
                    ? ContenedorStatus.success
                    : ContenedorStatus.error),
        message:
            !silent && processed > 0
                ? 'Cola procesada: $processed registro(s). Pendientes: ${queue.length}'
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
      status: ContenedorStatus.idle,
      clearError: true,
      clearMessage: true,
    );
  }

  Future<void> limpiarCola() async {
    await _saveQueueAndTelemetry(
      const <ContenedorQueueJobModel>[],
      state.telemetry,
    );
    state = state.copyWith(
      queue: const <ContenedorQueueJobModel>[],
      status: ContenedorStatus.idle,
      message: 'Cola de contenedor limpiada',
      clearError: true,
    );
  }

  void limpiarFormulario() {
    state = state.copyWith(
      status: ContenedorStatus.idle,
      qrRaw: '',
      clearParsedQr: true,
      nroConos: '',
      pesoBruto: '',
      pesoNeto: '',
      numCajasMovidas: '',
      totalBobinas: '',
      pesoBrutoTotal: '',
      pesoNetoTotal: '',
      fechaSalida: _formatDate(DateTime.now()),
      clearError: true,
      clearMessage: true,
    );
  }

  ContenedorFormData _buildFormData(String usuario) {
    final parsed = state.parsedQr!;

    return ContenedorFormData(
      qrCampos: parsed.camposDetectados,
      codigoHc: parsed.codigoPcp.trim(),
      material: parsed.material.trim(),
      titulo: parsed.titulo.trim(),
      color: parsed.color.trim(),
      lote: parsed.lote.trim(),
      numCajasMovidas: _normalizeNumeric(state.numCajasMovidas),
      nroConos: _normalizeNumeric(state.nroConos),
      pesoBruto: _normalizeNumeric(state.pesoBruto),
      pesoNeto: _normalizeNumeric(state.pesoNeto),
      totalBobinas: _normalizeNumeric(state.totalBobinas),
      pesoBrutoTotal: _normalizeNumeric(state.pesoBrutoTotal),
      pesoNetoTotal: _normalizeNumeric(state.pesoNetoTotal),
      proveedor: parsed.proveedor.trim(),
      fechaIngreso: parsed.fechaIngreso.trim(),
      fechaSalida:
          state.fechaSalida.trim().isNotEmpty
              ? state.fechaSalida.trim()
              : _formatDate(DateTime.now()),
      nombreOperario: usuario.trim(),
      usuario: usuario.trim(),
    );
  }

  Future<void> _encolar(ContenedorFormData form, String baseError) async {
    final now = DateTime.now();
    final job = ContenedorQueueJobModel(
      id: '${now.microsecondsSinceEpoch}-${state.queue.length}',
      qrCampos: form.qrCampos,
      codigoHc: form.codigoHc,
      material: form.material,
      titulo: form.titulo,
      color: form.color,
      lote: form.lote,
      numCajasMovidas: form.numCajasMovidas,
      nroConos: form.nroConos,
      pesoBruto: form.pesoBruto,
      pesoNeto: form.pesoNeto,
      totalBobinas: form.totalBobinas,
      pesoBrutoTotal: form.pesoBrutoTotal,
      pesoNetoTotal: form.pesoNetoTotal,
      proveedor: form.proveedor,
      fechaIngreso: form.fechaIngreso,
      fechaSalida: form.fechaSalida,
      nombreOperario: form.nombreOperario,
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
      status: ContenedorStatus.queueing,
      queue: updatedQueue,
      telemetry: updatedTelemetry,
      qrRaw: '',
      clearParsedQr: true,
      nroConos: '',
      pesoBruto: '',
      pesoNeto: '',
      numCajasMovidas: '',
      totalBobinas: '',
      pesoBrutoTotal: '',
      pesoNetoTotal: '',
      fechaSalida: _formatDate(DateTime.now()),
      message: 'Sin red estable. Contenedor guardado en cola segura.',
      clearError: true,
    );
  }

  String _signature(String usuario) {
    final parsed = state.parsedQr!;
    return [
      parsed.codigoPcp.trim().toUpperCase(),
      _normalizeNumeric(state.numCajasMovidas),
      _normalizeNumeric(state.totalBobinas),
      usuario.trim().toUpperCase(),
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
      AppConstants.keyContenedorQueue,
      defaultValue: '',
    );
    final rawTelemetry = _storage.getValue(
      AppConstants.keyContenedorTelemetry,
      defaultValue: '',
    );

    var queue = <ContenedorQueueJobModel>[];
    if (rawQueue.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawQueue);
        if (decoded is List) {
          queue =
              decoded
                  .whereType<Map>()
                  .map(
                    (item) => ContenedorQueueJobModel.fromJson(
                      Map<String, dynamic>.from(item),
                    ),
                  )
                  .where((job) => job.id.isNotEmpty)
                  .toList();
        }
      } catch (_) {
        queue = <ContenedorQueueJobModel>[];
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
    List<ContenedorQueueJobModel> queue,
    QueueTelemetryModel telemetry,
  ) async {
    final queueJson = jsonEncode(queue.map((item) => item.toJson()).toList());
    final telemetryJson = jsonEncode(telemetry.toJson());

    await _storage.setValue(AppConstants.keyContenedorQueue, queueJson);
    await _storage.setValue(AppConstants.keyContenedorTelemetry, telemetryJson);
  }

  String _normalizeNumeric(String value) {
    final parsed = _toDouble(value);
    if (parsed == parsed.roundToDouble()) {
      return parsed.toInt().toString();
    }
    return parsed
        .toStringAsFixed(3)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value
        .toStringAsFixed(3)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  double _toDouble(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0;
  }

  String _formatDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = date.year.toString();
    return '$dd/$mm/$yyyy';
  }

  String _cleanError(Object error) {
    return error.toString().replaceAll('Exception: ', '').trim();
  }
}

final contenedorProvider =
    StateNotifierProvider<ContenedorNotifier, ContenedorState>(
      (ref) => ContenedorNotifier(
        ref.read(legacyModulesDatasourceProvider),
        ref.read(localStorageProvider),
      ),
    );
