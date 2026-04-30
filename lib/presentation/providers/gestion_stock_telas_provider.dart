import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_constants.dart';
import '../../core/storage/local_storage.dart';
import '../../core/utils/tela_qr_codec.dart';
import '../../data/datasources/remote/telas_remote_datasource.dart';
import '../../data/models/despacho_queue_job_model.dart';
import 'auth_provider.dart';

enum GestionTab { ingreso, despacho }

enum GestionStatus {
  idle,
  parsingQr,
  registrandoIngreso,
  validandoRollo,
  imprimiendoDespacho,
  queueingDespacho,
  drainingDespachoQueue,
  success,
  error,
}

class GestionStockTelasState {
  final GestionTab activeTab;
  final GestionStatus status;

  // Ingreso
  final String qrRaw;
  final TelaQrNormalized? qrIngreso;
  final String almacen;
  final String ubicacion;
  final String observacionesIngreso;

  // Despacho
  final String codigoDespachoInput;
  final String destinoDespacho;
  final String guiaDespacho;
  final String observacionesDespacho;
  final List<RolloDespachoItem> carrito;

  // Cola offline de despacho
  final List<DespachoQueueJobModel> despachoQueue;
  final DespachoQueueTelemetryModel telemetry;
  final bool localApiDisponible;

  final String? message;
  final String? errorMessage;

  const GestionStockTelasState({
    this.activeTab = GestionTab.ingreso,
    this.status = GestionStatus.idle,
    this.qrRaw = '',
    this.qrIngreso,
    this.almacen = 'PLANTA 1',
    this.ubicacion = 'A',
    this.observacionesIngreso = '',
    this.codigoDespachoInput = '',
    this.destinoDespacho = '',
    this.guiaDespacho = '',
    this.observacionesDespacho = '',
    this.carrito = const [],
    this.despachoQueue = const [],
    this.telemetry = const DespachoQueueTelemetryModel(),
    this.localApiDisponible = false,
    this.message,
    this.errorMessage,
  });

  bool get isBusy =>
      status == GestionStatus.parsingQr ||
      status == GestionStatus.registrandoIngreso ||
      status == GestionStatus.validandoRollo ||
      status == GestionStatus.imprimiendoDespacho ||
      status == GestionStatus.queueingDespacho ||
      status == GestionStatus.drainingDespachoQueue;

  int get pendingDespachos => despachoQueue.length;

  double get totalMetros =>
      carrito.fold<double>(0, (sum, item) => sum + item.metraje);
  double get totalPeso =>
      carrito.fold<double>(0, (sum, item) => sum + item.peso);

  GestionStockTelasState copyWith({
    GestionTab? activeTab,
    GestionStatus? status,
    String? qrRaw,
    TelaQrNormalized? qrIngreso,
    bool clearQrIngreso = false,
    String? almacen,
    String? ubicacion,
    String? observacionesIngreso,
    String? codigoDespachoInput,
    String? destinoDespacho,
    String? guiaDespacho,
    String? observacionesDespacho,
    List<RolloDespachoItem>? carrito,
    List<DespachoQueueJobModel>? despachoQueue,
    DespachoQueueTelemetryModel? telemetry,
    bool? localApiDisponible,
    String? message,
    bool clearMessage = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return GestionStockTelasState(
      activeTab: activeTab ?? this.activeTab,
      status: status ?? this.status,
      qrRaw: qrRaw ?? this.qrRaw,
      qrIngreso: clearQrIngreso ? null : (qrIngreso ?? this.qrIngreso),
      almacen: almacen ?? this.almacen,
      ubicacion: ubicacion ?? this.ubicacion,
      observacionesIngreso: observacionesIngreso ?? this.observacionesIngreso,
      codigoDespachoInput: codigoDespachoInput ?? this.codigoDespachoInput,
      destinoDespacho: destinoDespacho ?? this.destinoDespacho,
      guiaDespacho: guiaDespacho ?? this.guiaDespacho,
      observacionesDespacho:
          observacionesDespacho ?? this.observacionesDespacho,
      carrito: carrito ?? this.carrito,
      despachoQueue: despachoQueue ?? this.despachoQueue,
      telemetry: telemetry ?? this.telemetry,
      localApiDisponible: localApiDisponible ?? this.localApiDisponible,
      message: clearMessage ? null : (message ?? this.message),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final telasDatasourceProvider = Provider<TelasRemoteDatasource>(
  (ref) => TelasRemoteDatasource(
    ref.read(apiClientProvider),
    ref.read(localApiClientProvider),
  ),
);

class GestionStockTelasNotifier extends StateNotifier<GestionStockTelasState> {
  final TelasRemoteDatasource _datasource;
  final LocalStorage _storage;

  bool _printLock = false;

  GestionStockTelasNotifier(this._datasource, this._storage)
    : super(const GestionStockTelasState()) {
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    _loadQueueAndTelemetry();
    await refrescarEstadoApiLocal();
  }

  void cambiarTab(GestionTab tab) {
    state = state.copyWith(
      activeTab: tab,
      clearError: true,
      clearMessage: true,
      status: GestionStatus.idle,
    );
  }

  void setQrRaw(String value) {
    state = state.copyWith(qrRaw: value, clearError: true, clearMessage: true);
  }

  void setAlmacen(String value) {
    state = state.copyWith(almacen: value);
  }

  void setUbicacion(String value) {
    state = state.copyWith(ubicacion: value);
  }

  void setObservacionesIngreso(String value) {
    state = state.copyWith(observacionesIngreso: value);
  }

  void setCodigoDespachoInput(String value) {
    state = state.copyWith(
      codigoDespachoInput: value,
      clearError: true,
      clearMessage: true,
    );
  }

  void setDestinoDespacho(String value) {
    state = state.copyWith(destinoDespacho: value, clearError: true);
  }

  void setGuiaDespacho(String value) {
    state = state.copyWith(guiaDespacho: value, clearError: true);
  }

  void setObservacionesDespacho(String value) {
    state = state.copyWith(observacionesDespacho: value);
  }

  Future<void> parsearQrIngreso() async {
    if (state.qrRaw.trim().isEmpty) {
      state = state.copyWith(
        status: GestionStatus.error,
        errorMessage: 'Ingrese o escanee el QR de tela',
      );
      return;
    }

    state = state.copyWith(
      status: GestionStatus.parsingQr,
      clearError: true,
      clearMessage: true,
    );

    try {
      final normalized = TelaQrCodec.normalizeForIngreso(state.qrRaw);
      state = state.copyWith(
        status: GestionStatus.success,
        qrIngreso: normalized,
        message: 'QR valido y normalizado para backend',
      );
    } catch (error) {
      state = state.copyWith(
        status: GestionStatus.error,
        errorMessage: _cleanError(error),
      );
    }
  }

  Future<void> registrarIngreso({required String usuario}) async {
    if (state.qrIngreso == null) {
      await parsearQrIngreso();
      if (state.qrIngreso == null) return;
    }

    state = state.copyWith(
      status: GestionStatus.registrandoIngreso,
      clearError: true,
      clearMessage: true,
    );

    try {
      final result = await _datasource.registrarIngresoTela(
        codigoQr: state.qrIngreso!.codigoQrNormalizado,
        almacen: state.almacen,
        ubicacion: state.ubicacion,
        observaciones: state.observacionesIngreso,
        usuario: usuario,
      );

      state = state.copyWith(
        status: GestionStatus.success,
        message: result.message,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        status: GestionStatus.error,
        errorMessage: _cleanError(error),
      );
    }
  }

  Future<void> agregarRolloAlCarrito() async {
    if (state.codigoDespachoInput.trim().isEmpty) {
      state = state.copyWith(
        status: GestionStatus.error,
        errorMessage: 'Ingrese un codigo de rollo o QR para despacho',
      );
      return;
    }

    final codigo = TelaQrCodec.extractCodigoRollo(state.codigoDespachoInput);
    if (codigo.isEmpty) {
      state = state.copyWith(
        status: GestionStatus.error,
        errorMessage: 'No se pudo extraer codigo del valor ingresado',
      );
      return;
    }

    final exists = state.carrito.any((item) => item.codigo == codigo);
    if (exists) {
      state = state.copyWith(
        status: GestionStatus.error,
        errorMessage: 'Ese rollo ya esta agregado en el carrito',
      );
      return;
    }

    state = state.copyWith(
      status: GestionStatus.validandoRollo,
      clearError: true,
      clearMessage: true,
    );

    try {
      final rollo = await _datasource.validarRolloDespacho(codigo);
      final newCarrito = [...state.carrito, rollo];
      state = state.copyWith(
        status: GestionStatus.success,
        carrito: newCarrito,
        codigoDespachoInput: '',
        message: 'Rollo ${rollo.codigo} agregado al carrito',
      );
    } catch (error) {
      state = state.copyWith(
        status: GestionStatus.error,
        errorMessage: _cleanError(error),
      );
    }
  }

  void quitarRollo(String codigo) {
    final newCarrito =
        state.carrito.where((item) => item.codigo != codigo).toList();
    state = state.copyWith(carrito: newCarrito, status: GestionStatus.idle);
  }

  void limpiarIngreso() {
    state = state.copyWith(
      qrRaw: '',
      clearQrIngreso: true,
      observacionesIngreso: '',
      status: GestionStatus.idle,
      clearError: true,
      clearMessage: true,
    );
  }

  void limpiarDespacho() {
    state = state.copyWith(
      codigoDespachoInput: '',
      destinoDespacho: '',
      guiaDespacho: '',
      observacionesDespacho: '',
      carrito: const [],
      status: GestionStatus.idle,
      clearError: true,
      clearMessage: true,
    );
  }

  Future<void> imprimirDespacho({required String usuario}) async {
    if (_printLock || state.isBusy) return;

    if (state.carrito.isEmpty) {
      state = state.copyWith(
        status: GestionStatus.error,
        errorMessage: 'Agregue al menos un rollo al carrito',
      );
      return;
    }
    if (state.destinoDespacho.trim().isEmpty) {
      state = state.copyWith(
        status: GestionStatus.error,
        errorMessage: 'Ingrese destino para el despacho',
      );
      return;
    }

    _printLock = true;
    state = state.copyWith(
      status: GestionStatus.imprimiendoDespacho,
      clearError: true,
      clearMessage: true,
    );

    try {
      final result = await _datasource.imprimirDespacho(
        rollos: state.carrito,
        destino: state.destinoDespacho,
        guia: state.guiaDespacho,
        observaciones: state.observacionesDespacho,
        usuario: usuario,
      );

      await refrescarEstadoApiLocal();

      state = state.copyWith(
        status: GestionStatus.success,
        message:
            '${result.message} | ${result.correlativo} | ${result.impresora}',
        carrito: const [],
        codigoDespachoInput: '',
        destinoDespacho: '',
        guiaDespacho: '',
        observacionesDespacho: '',
        clearError: true,
      );
    } catch (error) {
      final errorMessage = _cleanError(error);
      final shouldQueue = await _debeEncolar(errorMessage);

      if (shouldQueue) {
        await _encolarDespacho(usuario: usuario, baseError: errorMessage);
      } else {
        state = state.copyWith(
          status: GestionStatus.error,
          errorMessage: errorMessage,
        );
      }
    } finally {
      _printLock = false;
    }
  }

  Future<void> procesarColaDespacho({bool silent = false}) async {
    if (_printLock || state.isBusy) return;

    if (state.despachoQueue.isEmpty) {
      if (!silent) {
        state = state.copyWith(
          status: GestionStatus.success,
          message: 'No hay despachos pendientes en cola',
          clearError: true,
        );
      }
      return;
    }

    _printLock = true;
    final previousStatus = state.status;
    if (!silent) {
      state = state.copyWith(
        status: GestionStatus.drainingDespachoQueue,
        clearError: true,
        clearMessage: true,
      );
    }

    try {
      final available = await _datasource.isLocalApiDisponible();
      state = state.copyWith(localApiDisponible: available);
      if (!available) {
        throw Exception('API local offline. No se puede procesar la cola.');
      }

      var queue = [...state.despachoQueue];
      var telemetry = state.telemetry;
      var processed = 0;
      var failed = 0;

      while (queue.isNotEmpty) {
        final job = queue.first;
        final nowIso = DateTime.now().toIso8601String();

        try {
          await _datasource.imprimirDespacho(
            rollos: job.rollos.map(_toRolloItem).toList(),
            destino: job.destino,
            guia: job.guia,
            observaciones: job.observaciones,
            usuario: job.usuario,
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
      await refrescarEstadoApiLocal();

      final pending = queue.length;
      state = state.copyWith(
        despachoQueue: queue,
        telemetry: telemetry,
        status:
            silent
                ? previousStatus
                : (failed == 0 ? GestionStatus.success : GestionStatus.error),
        message:
            !silent && processed > 0
                ? 'Cola procesada: $processed despacho(s). Pendientes: $pending'
                : null,
        errorMessage:
            !silent && failed > 0
                ? 'La cola se detuvo por error de impresion. Pendientes: $pending'
                : null,
      );
    } catch (error) {
      if (!silent) {
        state = state.copyWith(
          status: GestionStatus.error,
          errorMessage: _cleanError(error),
        );
      }
    } finally {
      _printLock = false;
    }
  }

  Future<void> quitarTrabajoCola(String jobId) async {
    final updated =
        state.despachoQueue.where((job) => job.id != jobId).toList();
    await _guardarQueueAndTelemetry(updated, state.telemetry);
    state = state.copyWith(
      despachoQueue: updated,
      status: GestionStatus.idle,
      clearError: true,
      clearMessage: true,
    );
  }

  Future<void> limpiarColaDespacho() async {
    await _guardarQueueAndTelemetry(const [], state.telemetry);
    state = state.copyWith(
      despachoQueue: const [],
      status: GestionStatus.idle,
      message: 'Cola de despacho limpiada',
      clearError: true,
    );
  }

  Future<void> refrescarEstadoApiLocal() async {
    try {
      final disponible = await _datasource.isLocalApiDisponible();
      state = state.copyWith(localApiDisponible: disponible);
    } catch (_) {
      state = state.copyWith(localApiDisponible: false);
    }
  }

  Future<void> _encolarDespacho({
    required String usuario,
    required String baseError,
  }) async {
    final now = DateTime.now();
    final rollos = state.carrito.map(_toQueueRollo).toList();

    final job = DespachoQueueJobModel(
      id: '${now.microsecondsSinceEpoch}-${state.despachoQueue.length}',
      rollos: rollos,
      destino: state.destinoDespacho,
      guia: state.guiaDespacho,
      observaciones: state.observacionesDespacho,
      usuario: usuario,
      createdAtIso: now.toIso8601String(),
    );

    final updatedQueue = [...state.despachoQueue, job];
    final updatedTelemetry = state.telemetry.copyWith(
      enqueuedTotal: state.telemetry.enqueuedTotal + 1,
      lastAttemptAtIso: now.toIso8601String(),
      lastError: baseError,
    );

    await _guardarQueueAndTelemetry(updatedQueue, updatedTelemetry);

    state = state.copyWith(
      status: GestionStatus.queueingDespacho,
      despachoQueue: updatedQueue,
      telemetry: updatedTelemetry,
      localApiDisponible: false,
      carrito: const [],
      codigoDespachoInput: '',
      destinoDespacho: '',
      guiaDespacho: '',
      observacionesDespacho: '',
      clearError: true,
      message: 'API local no disponible. Despacho guardado en cola segura.',
    );
  }

  Future<bool> _debeEncolar(String message) async {
    final text = message.toLowerCase();

    if (text.contains('no se puede conectar') ||
        text.contains('connection') ||
        text.contains('timeout') ||
        text.contains('socket')) {
      return true;
    }

    final apiOk = await _datasource.isLocalApiDisponible();
    return !apiOk;
  }

  void _loadQueueAndTelemetry() {
    final rawQueue = _storage.getValue(
      AppConstants.keyDespachoQueue,
      defaultValue: '',
    );
    final rawTelemetry = _storage.getValue(
      AppConstants.keyDespachoTelemetry,
      defaultValue: '',
    );

    var queue = <DespachoQueueJobModel>[];
    if (rawQueue.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawQueue);
        if (decoded is List) {
          queue =
              decoded
                  .whereType<Map>()
                  .map(
                    (map) => DespachoQueueJobModel.fromJson(
                      Map<String, dynamic>.from(map),
                    ),
                  )
                  .where((job) => job.id.isNotEmpty && job.rollos.isNotEmpty)
                  .toList();
        }
      } catch (_) {
        queue = <DespachoQueueJobModel>[];
      }
    }

    var telemetry = const DespachoQueueTelemetryModel();
    if (rawTelemetry.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawTelemetry);
        if (decoded is Map) {
          telemetry = DespachoQueueTelemetryModel.fromJson(
            Map<String, dynamic>.from(decoded),
          );
        }
      } catch (_) {
        telemetry = const DespachoQueueTelemetryModel();
      }
    }

    state = state.copyWith(despachoQueue: queue, telemetry: telemetry);
  }

  Future<void> _guardarQueueAndTelemetry(
    List<DespachoQueueJobModel> queue,
    DespachoQueueTelemetryModel telemetry,
  ) async {
    final queueJson = jsonEncode(queue.map((item) => item.toJson()).toList());
    final telemetryJson = jsonEncode(telemetry.toJson());

    await _storage.setValue(AppConstants.keyDespachoQueue, queueJson);
    await _storage.setValue(AppConstants.keyDespachoTelemetry, telemetryJson);
  }

  DespachoQueueRolloModel _toQueueRollo(RolloDespachoItem item) {
    return DespachoQueueRolloModel(
      codigo: item.codigo,
      articulo: item.articulo,
      metraje: item.metraje,
      peso: item.peso,
      ubicacion: item.ubicacion,
    );
  }

  RolloDespachoItem _toRolloItem(DespachoQueueRolloModel item) {
    return RolloDespachoItem(
      codigo: item.codigo,
      articulo: item.articulo,
      metraje: item.metraje,
      peso: item.peso,
      ubicacion: item.ubicacion,
    );
  }

  String _cleanError(Object error) {
    return error.toString().replaceAll('Exception: ', '').trim();
  }
}

final gestionStockTelasProvider =
    StateNotifierProvider<GestionStockTelasNotifier, GestionStockTelasState>(
      (ref) => GestionStockTelasNotifier(
        ref.read(telasDatasourceProvider),
        ref.read(localStorageProvider),
      ),
    );
