import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_constants.dart';
import '../../core/storage/local_storage.dart';
import '../../core/utils/qr_parser.dart';
import '../../data/datasources/remote/reingreso_remote_datasource.dart';
import '../../data/models/almacen_mov_queue_models.dart';
import 'auth_provider.dart';

enum ReingresoStatus {
  idle,
  parsingQr,
  loadingTaras,
  validating,
  sending,
  queueing,
  drainingQueue,
  blocked,
  success,
  error,
}

enum TaraTipo { none, caja, bolsa, saco }

class ReingresoState {
  final ReingresoStatus status;
  final String qrRaw;
  final QrHilos? parsed;
  final TarasData? taras;
  final TaraTipo taraTipo;
  final String nuevaUbicacion;
  final String cantidadReenconado;
  final String pesoBruto;
  final String pesoNeto;
  final List<ReingresoQueueJobModel> queue;
  final QueueTelemetryModel telemetry;
  final String? message;
  final String? errorMessage;

  const ReingresoState({
    this.status = ReingresoStatus.idle,
    this.qrRaw = '',
    this.parsed,
    this.taras,
    this.taraTipo = TaraTipo.none,
    this.nuevaUbicacion = '',
    this.cantidadReenconado = '0',
    this.pesoBruto = '',
    this.pesoNeto = '',
    this.queue = const [],
    this.telemetry = const QueueTelemetryModel(),
    this.message,
    this.errorMessage,
  });

  bool get isBusy =>
      status == ReingresoStatus.parsingQr ||
      status == ReingresoStatus.loadingTaras ||
      status == ReingresoStatus.validating ||
      status == ReingresoStatus.sending ||
      status == ReingresoStatus.queueing ||
      status == ReingresoStatus.drainingQueue;

  int get pendingQueue => queue.length;

  bool get canSubmit {
    return parsed != null &&
        nuevaUbicacion.trim().isNotEmpty &&
        _toDouble(pesoBruto) > 0 &&
        _toDouble(pesoNeto) > 0;
  }

  ReingresoState copyWith({
    ReingresoStatus? status,
    String? qrRaw,
    QrHilos? parsed,
    bool clearParsed = false,
    TarasData? taras,
    bool clearTaras = false,
    TaraTipo? taraTipo,
    String? nuevaUbicacion,
    String? cantidadReenconado,
    String? pesoBruto,
    String? pesoNeto,
    List<ReingresoQueueJobModel>? queue,
    QueueTelemetryModel? telemetry,
    String? message,
    bool clearMessage = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ReingresoState(
      status: status ?? this.status,
      qrRaw: qrRaw ?? this.qrRaw,
      parsed: clearParsed ? null : (parsed ?? this.parsed),
      taras: clearTaras ? null : (taras ?? this.taras),
      taraTipo: taraTipo ?? this.taraTipo,
      nuevaUbicacion: nuevaUbicacion ?? this.nuevaUbicacion,
      cantidadReenconado: cantidadReenconado ?? this.cantidadReenconado,
      pesoBruto: pesoBruto ?? this.pesoBruto,
      pesoNeto: pesoNeto ?? this.pesoNeto,
      queue: queue ?? this.queue,
      telemetry: telemetry ?? this.telemetry,
      message: clearMessage ? null : (message ?? this.message),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final reingresoDatasourceProvider = Provider<ReingresoRemoteDatasource>(
  (ref) => ReingresoRemoteDatasource(ref.read(apiClientProvider)),
);

class ReingresoNotifier extends StateNotifier<ReingresoState> {
  final ReingresoRemoteDatasource _datasource;
  final LocalStorage _storage;

  bool _submitLock = false;
  String _lastSubmitSignature = '';
  DateTime? _lastSubmitAt;

  ReingresoNotifier(this._datasource, this._storage)
    : super(const ReingresoState()) {
    _bootstrap();
  }

  void _bootstrap() {
    _loadQueueAndTelemetry();
  }

  void setQrRaw(String value) {
    state = state.copyWith(qrRaw: value, clearError: true, clearMessage: true);
  }

  void setNuevaUbicacion(String value) {
    state = state.copyWith(
      nuevaUbicacion: value,
      clearError: true,
      clearMessage: true,
    );
  }

  void setCantidadReenconado(String value) {
    state = state.copyWith(cantidadReenconado: value, clearError: true);
    _recalcularPesoNeto();
  }

  void setPesoBruto(String value) {
    state = state.copyWith(pesoBruto: value, clearError: true);
    _recalcularPesoNeto();
  }

  void setTaraTipo(TaraTipo value) {
    state = state.copyWith(taraTipo: value, clearError: true);
    _recalcularPesoNeto();
  }

  Future<void> parsearQrYTaras() async {
    if (state.qrRaw.trim().isEmpty) {
      state = state.copyWith(
        status: ReingresoStatus.error,
        errorMessage: 'Ingrese o escanee el QR para continuar',
      );
      return;
    }

    state = state.copyWith(
      status: ReingresoStatus.parsingQr,
      clearError: true,
      clearMessage: true,
    );

    try {
      final parsedResult = QrParser.parse(state.qrRaw);
      if (!parsedResult.isValid || parsedResult.hilos == null) {
        throw Exception('El QR no corresponde a hilos (formato 14/16 campos)');
      }

      final parsed = parsedResult.hilos!;
      state = state.copyWith(
        parsed: parsed,
        pesoBruto: parsed.pesoBruto.toString(),
        nuevaUbicacion:
            state.nuevaUbicacion.isEmpty
                ? parsed.ubicacion
                : state.nuevaUbicacion,
        status: ReingresoStatus.loadingTaras,
      );

      final taras = await _datasource.obtenerTaras(
        material: parsed.material,
        titulo: parsed.titulo,
        proveedor: parsed.proveedor,
      );

      state = state.copyWith(
        status: ReingresoStatus.success,
        taras: taras,
        message: 'QR parseado y taras cargadas',
        clearError: true,
      );
      _recalcularPesoNeto();
    } catch (error) {
      state = state.copyWith(
        status: ReingresoStatus.error,
        errorMessage: _cleanError(error),
      );
    }
  }

  void _recalcularPesoNeto() {
    final parsed = state.parsed;
    if (parsed == null) return;

    final pesoBruto = _toDouble(state.pesoBruto);
    if (pesoBruto <= 0) {
      state = state.copyWith(pesoNeto: '');
      return;
    }

    final taras = state.taras;
    final taraCono = taras?.taraCono ?? 0;
    final taraCaja = taras?.taraCaja ?? 0;
    final taraBolsa = taras?.taraBolsa ?? 0;
    final taraSaco = taras?.taraSaco ?? 0;

    final totalBobinas = parsed.totalBobinas;
    final reenconado = _toDouble(state.cantidadReenconado);
    final taraReenconado = reenconado * 0.03;

    var taraContenedor = 0.0;
    switch (state.taraTipo) {
      case TaraTipo.caja:
        taraContenedor = taraCaja;
      case TaraTipo.bolsa:
        taraContenedor = taraBolsa;
      case TaraTipo.saco:
        taraContenedor = taraSaco;
      case TaraTipo.none:
        taraContenedor = 0;
    }

    final pesoNeto =
        (pesoBruto -
                ((totalBobinas * taraCono) + taraReenconado + taraContenedor))
            .abs();
    state = state.copyWith(pesoNeto: pesoNeto.toStringAsFixed(2));
  }

  Future<void> enviarReingreso({required String usuario}) async {
    if (_submitLock || state.isBusy) return;
    if (!state.canSubmit || state.parsed == null) {
      state = state.copyWith(
        status: ReingresoStatus.error,
        errorMessage:
            'Complete los datos obligatorios antes de enviar reingreso',
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
        status: ReingresoStatus.error,
        errorMessage: 'Envio duplicado detectado. Espere unos segundos.',
      );
      return;
    }

    _submitLock = true;
    try {
      final form = _buildFormData(usuario);

      state = state.copyWith(
        status: ReingresoStatus.validating,
        clearError: true,
        clearMessage: true,
      );

      await _validarYEnviar(
        codigoPcp: form.codigoPcp,
        nuevaUbicacion: state.nuevaUbicacion,
        usuario: usuario,
        formData: form,
      );

      _lastSubmitSignature = signature;
      _lastSubmitAt = now;
      state = state.copyWith(
        status: ReingresoStatus.success,
        message: 'Reingreso enviado a Google Forms',
        clearError: true,
      );
    } catch (error) {
      final message = _cleanError(error);
      if (_debeEncolar(message)) {
        await _encolarReingreso(usuario: usuario, baseError: message);
      } else {
        state = state.copyWith(
          status: ReingresoStatus.error,
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
          status: ReingresoStatus.success,
          message: 'No hay reingresos pendientes en cola',
          clearError: true,
        );
      }
      return;
    }

    _submitLock = true;
    final previousStatus = state.status;
    if (!silent) {
      state = state.copyWith(
        status: ReingresoStatus.drainingQueue,
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
          final formData = ReingresoFormData(
            codigoPcp: job.codigoPcp,
            codigoKardex: job.codigoKardex,
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
            fechaSalida: job.fechaSalida,
            horaSalida: job.horaSalida,
            servicio: job.servicio,
            usuario: job.usuario,
            movimiento: job.movimiento,
          );

          await _validarYEnviar(
            codigoPcp: job.codigoPcp,
            nuevaUbicacion: job.nuevaUbicacion,
            usuario: job.usuario,
            formData: formData,
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

      await _guardarQueueAndTelemetry(queue, telemetry);

      state = state.copyWith(
        queue: queue,
        telemetry: telemetry,
        status:
            silent
                ? previousStatus
                : (failed == 0
                    ? ReingresoStatus.success
                    : ReingresoStatus.error),
        message:
            !silent && processed > 0
                ? 'Cola procesada: $processed reingreso(s). Pendientes: ${queue.length}'
                : null,
        errorMessage:
            !silent && failed > 0
                ? 'La cola se detuvo por error. Pendientes: ${queue.length}'
                : null,
      );
    } catch (error) {
      if (!silent) {
        state = state.copyWith(
          status: ReingresoStatus.error,
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
      status: ReingresoStatus.idle,
      clearError: true,
      clearMessage: true,
    );
  }

  Future<void> limpiarCola() async {
    await _guardarQueueAndTelemetry(const [], state.telemetry);
    state = state.copyWith(
      queue: const [],
      status: ReingresoStatus.idle,
      message: 'Cola de reingresos limpiada',
      clearError: true,
    );
  }

  void limpiar() {
    state = state.copyWith(
      status: ReingresoStatus.idle,
      qrRaw: '',
      clearParsed: true,
      clearTaras: true,
      taraTipo: TaraTipo.none,
      nuevaUbicacion: '',
      cantidadReenconado: '0',
      pesoBruto: '',
      pesoNeto: '',
      clearError: true,
      clearMessage: true,
    );
  }

  Future<void> _encolarReingreso({
    required String usuario,
    required String baseError,
  }) async {
    final form = _buildFormData(usuario);
    final now = DateTime.now();

    final job = ReingresoQueueJobModel(
      id: '${now.microsecondsSinceEpoch}-${state.queue.length}',
      nuevaUbicacion: state.nuevaUbicacion.trim(),
      usuario: usuario.trim(),
      createdAtIso: now.toIso8601String(),
      codigoPcp: form.codigoPcp,
      codigoKardex: form.codigoKardex,
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
      fechaSalida: form.fechaSalida,
      horaSalida: form.horaSalida,
      servicio: form.servicio,
      movimiento: form.movimiento,
    );

    final updatedQueue = [...state.queue, job];
    final updatedTelemetry = state.telemetry.copyWith(
      enqueuedTotal: state.telemetry.enqueuedTotal + 1,
      lastAttemptAtIso: now.toIso8601String(),
      lastError: baseError,
    );

    await _guardarQueueAndTelemetry(updatedQueue, updatedTelemetry);

    state = state.copyWith(
      status: ReingresoStatus.queueing,
      queue: updatedQueue,
      telemetry: updatedTelemetry,
      message: 'Sin red estable. Reingreso guardado en cola segura.',
      clearError: true,
    );
  }

  bool _debeEncolar(String message) {
    final text = message.toLowerCase();
    return text.contains('no se puede conectar') ||
        text.contains('timeout') ||
        text.contains('connection') ||
        text.contains('wifi') ||
        text.contains('socket');
  }

  Future<void> _validarYEnviar({
    required String codigoPcp,
    required String nuevaUbicacion,
    required String usuario,
    required ReingresoFormData formData,
  }) async {
    final validation = await _datasource.validarMovimiento(
      codigoPcp: codigoPcp,
      nuevaUbicacion: nuevaUbicacion,
      usuario: usuario,
    );
    if (!validation.permitido) {
      throw Exception(validation.mensaje);
    }

    await _datasource.enviarFormularioReingreso(formData);
  }

  ReingresoFormData _buildFormData(String usuario) {
    final parsed = state.parsed;
    if (parsed == null) {
      throw Exception('No hay QR parseado para construir reingreso');
    }

    final now = DateTime.now();
    final fechaSalida = _formatDate(now);
    final horaSalida = _formatTime(now);

    return ReingresoFormData(
      codigoPcp: parsed.codigoPcp,
      codigoKardex: parsed.codigoKardex,
      material: parsed.material,
      titulo: parsed.titulo,
      color: parsed.color,
      lote: parsed.lote,
      numCajas: parsed.numCajas.toStringAsFixed(0),
      totalBobinas: parsed.totalBobinas.toStringAsFixed(0),
      cantidadReenconado: state.cantidadReenconado.trim(),
      pesoBruto: state.pesoBruto.trim(),
      pesoNeto: state.pesoNeto.trim(),
      proveedor: parsed.proveedor,
      fechaIngreso:
          parsed.fechaIngreso?.trim().isNotEmpty == true
              ? parsed.fechaIngreso!.trim()
              : fechaSalida,
      fechaSalida: fechaSalida,
      horaSalida: horaSalida,
      servicio: parsed.servicio,
      usuario: usuario,
    );
  }

  void _loadQueueAndTelemetry() {
    final rawQueue = _storage.getValue(
      AppConstants.keyReingresoQueue,
      defaultValue: '',
    );
    final rawTelemetry = _storage.getValue(
      AppConstants.keyReingresoTelemetry,
      defaultValue: '',
    );

    var queue = <ReingresoQueueJobModel>[];
    if (rawQueue.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawQueue);
        if (decoded is List) {
          queue =
              decoded
                  .whereType<Map>()
                  .map(
                    (map) => ReingresoQueueJobModel.fromJson(
                      Map<String, dynamic>.from(map),
                    ),
                  )
                  .where((job) => job.id.isNotEmpty && job.codigoPcp.isNotEmpty)
                  .toList();
        }
      } catch (_) {
        queue = <ReingresoQueueJobModel>[];
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
    List<ReingresoQueueJobModel> queue,
    QueueTelemetryModel telemetry,
  ) async {
    final queueJson = jsonEncode(queue.map((item) => item.toJson()).toList());
    final telemetryJson = jsonEncode(telemetry.toJson());

    await _storage.setValue(AppConstants.keyReingresoQueue, queueJson);
    await _storage.setValue(AppConstants.keyReingresoTelemetry, telemetryJson);
  }

  String _signature(String usuario) {
    final parsed = state.parsed;
    return [
      parsed?.codigoPcp ?? '',
      state.nuevaUbicacion.trim().toUpperCase(),
      state.pesoBruto.trim(),
      state.pesoNeto.trim(),
      usuario.toUpperCase(),
    ].join('|');
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

final reingresoProvider =
    StateNotifierProvider<ReingresoNotifier, ReingresoState>(
      (ref) => ReingresoNotifier(
        ref.read(reingresoDatasourceProvider),
        ref.read(localStorageProvider),
      ),
    );

double _toDouble(String value) {
  return double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;
}
