import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_constants.dart';
import '../../core/storage/local_storage.dart';
import '../../core/utils/ingreso_hilos_qr_parser.dart';
import '../../data/datasources/remote/movimientos_remote_datasource.dart';
import '../../data/models/almacen_mov_queue_models.dart';
import 'auth_provider.dart';

const List<String> _plantaOpciones = <String>['PLANTA 1', 'PLANTA 2'];
const List<String> _ubicacionesPlanta1 = <String>[
  'URDIDO 1 (VERDE)',
  'URDIDO 2 (AZUL)',
  'VENTA',
  'TEÑIDO',
  'TRAMA',
  'DEVOLUCION',
  'TRASLADO DE BIENES PARA TRANSFORMACION',
];
const List<String> _ubicacionesPlanta2 = <String>[
  'TRAMA',
  'URDIDO 3 (PEÑON)',
  'VENTA',
  'TEÑIDO',
  'TRASLADO DE BIENES PARA TRANSFORMACION',
];
const List<String> _fallbackDestinosVenta = <String>['PROVEDORES DE VENTA'];
const List<String> _fallbackDestinosCliente = <String>['PROVEDORES DE VENTA'];

List<String> _ubicacionesPorPlanta(String planta) {
  return _normalizeForComparison(planta) == 'PLANTA 1'
      ? _ubicacionesPlanta1
      : _ubicacionesPlanta2;
}

bool _esUbicacionVentaOTraslado(String ubicacion) {
  final key = _normalizeForComparison(ubicacion);
  return key == 'VENTA' || key == 'TRASLADO DE BIENES PARA TRANSFORMACION';
}

bool _esUbicacionTenido(String ubicacion) {
  return _normalizeForComparison(ubicacion) == 'TENIDO';
}

bool _esUbicacionDevolucion(String ubicacion) {
  return _normalizeForComparison(ubicacion) == 'DEVOLUCION';
}

String _normalizeForComparison(String input) {
  return input
      .trim()
      .toUpperCase()
      .replaceAll('Ã‘', 'N')
      .replaceAll('Ñ', 'N')
      .replaceAll('Á', 'A')
      .replaceAll('É', 'E')
      .replaceAll('Í', 'I')
      .replaceAll('Ó', 'O')
      .replaceAll('Ú', 'U')
      .replaceAll(RegExp(r'\s+'), ' ');
}

String _safeFirst(List<String> values, {String fallback = ''}) {
  return values.isNotEmpty ? values.first : fallback;
}

String? _findOptionMatch(String rawValue, List<String> options) {
  final value = rawValue.trim();
  if (value.isEmpty || options.isEmpty) {
    return null;
  }

  for (final option in options) {
    if (option.trim() == value) {
      return option;
    }
  }

  final normalizedTarget = _normalizeForComparison(value);
  for (final option in options) {
    if (_normalizeForComparison(option) == normalizedTarget) {
      return option;
    }
  }

  return null;
}

String _safePick(String current, List<String> options, {String fallback = ''}) {
  if (options.isEmpty) {
    final currentValue = current.trim();
    if (currentValue.isNotEmpty) {
      return currentValue;
    }
    return fallback.trim();
  }

  final currentMatch = _findOptionMatch(current, options);
  if (currentMatch != null) {
    return currentMatch;
  }

  final fallbackMatch = _findOptionMatch(fallback, options);
  if (fallbackMatch != null) {
    return fallbackMatch;
  }

  return _safeFirst(options, fallback: fallback);
}

enum SalidaStatus {
  initial,
  parsingQr,
  consultandoUbicacion,
  validandoMovimiento,
  enviando,
  queueing,
  drainingQueue,
  bloqueado,
  exito,
  error,
}

class SalidaFormData {
  final String qrRaw;
  final int qrCampos;
  final String codigoKardex;
  final String codigoPcp;
  final String material;
  final String titulo;
  final String color;
  final String lote;
  final String numCaja;
  final String planta;
  final String nuevaUbicacion;
  final String destinoVenta;
  final String destinoCliente;
  final String numeroGuia;
  final String ordenCompra;
  final String telar;
  final String fechaSalida;
  final String horaSalida;
  final String servicio;
  final String movimiento;

  // Campos legacy del flujo antiguo; se conservan por compatibilidad de cola.
  final String numCajas;
  final String totalBobinas;
  final String pesoBrutoTotal;
  final String pesoNetoTotal;

  const SalidaFormData({
    this.qrRaw = '',
    this.qrCampos = 0,
    this.codigoKardex = '',
    this.codigoPcp = '',
    this.material = '',
    this.titulo = '',
    this.color = '',
    this.lote = '',
    this.numCaja = '',
    this.planta = 'PLANTA 1',
    this.nuevaUbicacion = 'URDIDO 1 (VERDE)',
    this.destinoVenta = '',
    this.destinoCliente = '',
    this.numeroGuia = '',
    this.ordenCompra = '',
    this.telar = '',
    this.fechaSalida = '',
    this.horaSalida = '',
    this.servicio = '',
    this.movimiento = 'SALIDA',
    this.numCajas = '',
    this.totalBobinas = '',
    this.pesoBrutoTotal = '',
    this.pesoNetoTotal = '',
  });

  SalidaFormData copyWith({
    String? qrRaw,
    int? qrCampos,
    String? codigoKardex,
    String? codigoPcp,
    String? material,
    String? titulo,
    String? color,
    String? lote,
    String? numCaja,
    String? planta,
    String? nuevaUbicacion,
    String? destinoVenta,
    String? destinoCliente,
    String? numeroGuia,
    String? ordenCompra,
    String? telar,
    String? fechaSalida,
    String? horaSalida,
    String? servicio,
    String? movimiento,
    String? numCajas,
    String? totalBobinas,
    String? pesoBrutoTotal,
    String? pesoNetoTotal,
  }) {
    return SalidaFormData(
      qrRaw: qrRaw ?? this.qrRaw,
      qrCampos: qrCampos ?? this.qrCampos,
      codigoKardex: codigoKardex ?? this.codigoKardex,
      codigoPcp: codigoPcp ?? this.codigoPcp,
      material: material ?? this.material,
      titulo: titulo ?? this.titulo,
      color: color ?? this.color,
      lote: lote ?? this.lote,
      numCaja: numCaja ?? this.numCaja,
      planta: planta ?? this.planta,
      nuevaUbicacion: nuevaUbicacion ?? this.nuevaUbicacion,
      destinoVenta: destinoVenta ?? this.destinoVenta,
      destinoCliente: destinoCliente ?? this.destinoCliente,
      numeroGuia: numeroGuia ?? this.numeroGuia,
      ordenCompra: ordenCompra ?? this.ordenCompra,
      telar: telar ?? this.telar,
      fechaSalida: fechaSalida ?? this.fechaSalida,
      horaSalida: horaSalida ?? this.horaSalida,
      servicio: servicio ?? this.servicio,
      movimiento: movimiento ?? this.movimiento,
      numCajas: numCajas ?? this.numCajas,
      totalBobinas: totalBobinas ?? this.totalBobinas,
      pesoBrutoTotal: pesoBrutoTotal ?? this.pesoBrutoTotal,
      pesoNetoTotal: pesoNetoTotal ?? this.pesoNetoTotal,
    );
  }
}

class SalidaAlmacenState {
  final SalidaStatus status;
  final SalidaFormData form;
  final List<String> plantasDisponibles;
  final List<String> ubicacionesDisponibles;
  final List<String> destinosVentaDisponibles;
  final List<String> destinosClienteDisponibles;
  final bool catalogosCargando;
  final UbicacionAlmacenData? ultimaUbicacion;
  final List<SalidaQueueJobModel> queue;
  final QueueTelemetryModel telemetry;
  final String? errorMessage;
  final String? infoMessage;
  final DateTime? lastSuccessAt;

  const SalidaAlmacenState({
    this.status = SalidaStatus.initial,
    this.form = const SalidaFormData(),
    this.plantasDisponibles = _plantaOpciones,
    this.ubicacionesDisponibles = _ubicacionesPlanta1,
    this.destinosVentaDisponibles = _fallbackDestinosVenta,
    this.destinosClienteDisponibles = _fallbackDestinosCliente,
    this.catalogosCargando = false,
    this.ultimaUbicacion,
    this.queue = const [],
    this.telemetry = const QueueTelemetryModel(),
    this.errorMessage,
    this.infoMessage,
    this.lastSuccessAt,
  });

  bool get isBusy =>
      status == SalidaStatus.parsingQr ||
      status == SalidaStatus.consultandoUbicacion ||
      status == SalidaStatus.validandoMovimiento ||
      status == SalidaStatus.enviando ||
      status == SalidaStatus.queueing ||
      status == SalidaStatus.drainingQueue;

  bool get hasQrValido => form.qrCampos == 14 || form.qrCampos == 16;
  bool get muestraKardex => form.codigoKardex.trim().isNotEmpty;
  int get pendingQueue => queue.length;
  bool get muestraPickerVenta =>
      _esUbicacionVentaOTraslado(form.nuevaUbicacion);
  bool get muestraPickerCliente => _esUbicacionDevolucion(form.nuevaUbicacion);
  bool get muestraNumeroGuia =>
      muestraPickerVenta ||
      muestraPickerCliente ||
      _esUbicacionTenido(form.nuevaUbicacion);
  bool get muestraOrdenCompra => muestraPickerVenta;

  String get ubicacionPayload {
    final ubicacionBase = form.nuevaUbicacion.trim();
    if (muestraPickerVenta && form.destinoVenta.trim().isNotEmpty) {
      return '$ubicacionBase - ${form.destinoVenta.trim()}';
    }
    if (muestraPickerCliente && form.destinoCliente.trim().isNotEmpty) {
      return '$ubicacionBase - ${form.destinoCliente.trim()}';
    }
    return ubicacionBase;
  }

  bool get isFormValid {
    final requiereGuia =
        muestraPickerVenta ||
        muestraPickerCliente ||
        _esUbicacionTenido(form.nuevaUbicacion);
    final requiereOrdenCompra = muestraPickerVenta;

    return hasQrValido &&
        form.codigoPcp.trim().isNotEmpty &&
        form.nuevaUbicacion.trim().isNotEmpty &&
        form.fechaSalida.trim().isNotEmpty &&
        form.horaSalida.trim().isNotEmpty &&
        (!muestraPickerVenta || form.destinoVenta.trim().isNotEmpty) &&
        (!muestraPickerCliente || form.destinoCliente.trim().isNotEmpty) &&
        (!requiereGuia || form.numeroGuia.trim().isNotEmpty) &&
        (!requiereOrdenCompra || form.ordenCompra.trim().isNotEmpty);
  }

  SalidaAlmacenState copyWith({
    SalidaStatus? status,
    SalidaFormData? form,
    List<String>? plantasDisponibles,
    List<String>? ubicacionesDisponibles,
    List<String>? destinosVentaDisponibles,
    List<String>? destinosClienteDisponibles,
    bool? catalogosCargando,
    UbicacionAlmacenData? ultimaUbicacion,
    bool clearUltimaUbicacion = false,
    List<SalidaQueueJobModel>? queue,
    QueueTelemetryModel? telemetry,
    String? errorMessage,
    bool clearError = false,
    String? infoMessage,
    bool clearInfo = false,
    DateTime? lastSuccessAt,
  }) {
    return SalidaAlmacenState(
      status: status ?? this.status,
      form: form ?? this.form,
      plantasDisponibles: plantasDisponibles ?? this.plantasDisponibles,
      ubicacionesDisponibles:
          ubicacionesDisponibles ?? this.ubicacionesDisponibles,
      destinosVentaDisponibles:
          destinosVentaDisponibles ?? this.destinosVentaDisponibles,
      destinosClienteDisponibles:
          destinosClienteDisponibles ?? this.destinosClienteDisponibles,
      catalogosCargando: catalogosCargando ?? this.catalogosCargando,
      ultimaUbicacion:
          clearUltimaUbicacion
              ? null
              : (ultimaUbicacion ?? this.ultimaUbicacion),
      queue: queue ?? this.queue,
      telemetry: telemetry ?? this.telemetry,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      infoMessage: clearInfo ? null : (infoMessage ?? this.infoMessage),
      lastSuccessAt: lastSuccessAt ?? this.lastSuccessAt,
    );
  }
}

final movimientosDatasourceProvider = Provider<MovimientosRemoteDatasource>(
  (ref) => MovimientosRemoteDatasource(ref.read(apiClientProvider)),
);

class SalidaAlmacenNotifier extends StateNotifier<SalidaAlmacenState> {
  final MovimientosRemoteDatasource _datasource;
  final LocalStorage _storage;

  bool _submitLock = false;
  String _lastSubmitSignature = '';
  DateTime? _lastSubmitAt;

  SalidaAlmacenNotifier(this._datasource, this._storage)
    : super(const SalidaAlmacenState()) {
    _bootstrap();
  }

  void _bootstrap() {
    final ubicacionesIniciales = _ubicacionesPorPlanta(state.form.planta);
    final destinoInicial = _safeFirst(
      ubicacionesIniciales,
      fallback: state.form.nuevaUbicacion,
    );
    state = state.copyWith(
      form: state.form.copyWith(nuevaUbicacion: destinoInicial),
      ubicacionesDisponibles: ubicacionesIniciales,
      plantasDisponibles: _plantaOpciones,
    );
    _loadCatalogosCache();
    _loadQueueAndTelemetry();
    Future.microtask(() => cargarCatalogosDestino(silent: true));
  }

  void actualizarCodigo(String value) {
    state = state.copyWith(
      form: state.form.copyWith(codigoPcp: value),
      clearError: true,
      clearInfo: true,
    );
  }

  void actualizarDestino(String value) {
    actualizarUbicacion(value);
  }

  void actualizarNumCajas(String value) {
    state = state.copyWith(
      form: state.form.copyWith(numCajas: value),
      clearError: true,
    );
  }

  void actualizarTotalBobinas(String value) {
    state = state.copyWith(
      form: state.form.copyWith(totalBobinas: value),
      clearError: true,
    );
  }

  void actualizarPesoBruto(String value) {
    state = state.copyWith(
      form: state.form.copyWith(pesoBrutoTotal: value),
      clearError: true,
    );
  }

  void actualizarPesoNeto(String value) {
    state = state.copyWith(
      form: state.form.copyWith(pesoNetoTotal: value),
      clearError: true,
    );
  }

  void actualizarPlanta(String value) {
    final planta = _safePick(value, _plantaOpciones, fallback: 'PLANTA 1');
    final ubicaciones = _ubicacionesPorPlanta(planta);
    final ubicacionSeleccionada = _safeFirst(
      ubicaciones,
      fallback: state.form.nuevaUbicacion,
    );
    final formBase = state.form.copyWith(
      planta: planta,
      nuevaUbicacion: ubicacionSeleccionada,
    );
    final formAjustado = _applyUbicacionRules(
      formBase,
      resetSelections: true,
      clearDynamicInputs: true,
    );

    state = state.copyWith(
      form: formAjustado,
      ubicacionesDisponibles: ubicaciones,
      clearError: true,
      clearInfo: true,
    );
  }

  void actualizarUbicacion(String value) {
    final ubicacion = _safePick(
      value,
      state.ubicacionesDisponibles,
      fallback: _safeFirst(
        state.ubicacionesDisponibles,
        fallback: state.form.nuevaUbicacion,
      ),
    );
    final formAjustado = _applyUbicacionRules(
      state.form.copyWith(nuevaUbicacion: ubicacion),
      resetSelections: true,
      clearDynamicInputs: true,
    );

    state = state.copyWith(
      form: formAjustado,
      clearError: true,
      clearInfo: true,
    );
  }

  void actualizarDestinoVenta(String value) {
    state = state.copyWith(
      form: state.form.copyWith(
        destinoVenta: _safePick(value, state.destinosVentaDisponibles),
      ),
      clearError: true,
      clearInfo: true,
    );
  }

  void actualizarDestinoCliente(String value) {
    state = state.copyWith(
      form: state.form.copyWith(
        destinoCliente: _safePick(value, state.destinosClienteDisponibles),
      ),
      clearError: true,
      clearInfo: true,
    );
  }

  void actualizarNumeroGuia(String value) {
    state = state.copyWith(
      form: state.form.copyWith(numeroGuia: value),
      clearError: true,
      clearInfo: true,
    );
  }

  void actualizarOrdenCompra(String value) {
    state = state.copyWith(
      form: state.form.copyWith(ordenCompra: value),
      clearError: true,
      clearInfo: true,
    );
  }

  Future<void> cargarCatalogosDestino({bool silent = false}) async {
    if (state.catalogosCargando) return;

    if (!silent) {
      state = state.copyWith(
        status: SalidaStatus.initial,
        catalogosCargando: true,
        clearError: true,
        clearInfo: true,
      );
    } else {
      state = state.copyWith(catalogosCargando: true, clearError: true);
    }

    try {
      final catalogos = await _datasource.obtenerCatalogosSalida();
      final ventas =
          catalogos.destinosVenta.isNotEmpty
              ? catalogos.destinosVenta
              : _fallbackDestinosVenta;
      final clientes =
          catalogos.destinosCliente.isNotEmpty
              ? catalogos.destinosCliente
              : _fallbackDestinosCliente;

      state = state.copyWith(
        destinosVentaDisponibles: ventas,
        destinosClienteDisponibles: clientes,
        catalogosCargando: true,
      );

      final formSincronizado = _applyUbicacionRules(
        state.form.copyWith(
          destinoVenta: _safePick(
            state.form.destinoVenta,
            ventas,
            fallback: _safeFirst(ventas),
          ),
          destinoCliente: _safePick(
            state.form.destinoCliente,
            clientes,
            fallback: _safeFirst(clientes),
          ),
        ),
      );

      await _guardarCatalogosCache(ventas, clientes);

      final catalogoLimitado = ventas.length <= 1 || clientes.length <= 1;

      state = state.copyWith(
        form: formSincronizado,
        catalogosCargando: false,
        infoMessage:
            silent
                ? state.infoMessage
                : catalogoLimitado
                ? 'Catalogos cargados con pocos elementos (${ventas.length}/${clientes.length}). Revise columnas 13/14 en datosKardex.'
                : 'Catalogos de destino cargados (${ventas.length}/${clientes.length})',
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        catalogosCargando: false,
        status: silent ? state.status : SalidaStatus.error,
        errorMessage:
            silent
                ? null
                : 'No se pudieron cargar catalogos de destino (${_cleanError(error)})',
      );
    }
  }

  Future<void> procesarQrEscaneado(
    String raw, {
    bool autoConsultarUbicacion = true,
  }) async {
    final qrRaw = raw.trim();
    if (qrRaw.isEmpty) return;

    state = state.copyWith(
      status: SalidaStatus.parsingQr,
      clearError: true,
      clearInfo: true,
    );

    final parseResult = IngresoHilosQrParser.parse(qrRaw);
    if (!parseResult.isValid || parseResult.data == null) {
      state = state.copyWith(
        status: SalidaStatus.error,
        errorMessage: parseResult.error ?? 'No se pudo parsear el QR escaneado',
      );
      return;
    }

    final parsed = parseResult.data!;
    final now = DateTime.now();
    final plantaDetectada = parsed.almacen.trim();
    final planta =
        _normalizeForComparison(plantaDetectada).startsWith('PLANTA ')
            ? _safePick(plantaDetectada, _plantaOpciones, fallback: 'PLANTA 1')
            : _safePick(
              state.form.planta,
              _plantaOpciones,
              fallback: 'PLANTA 1',
            );
    final ubicaciones = _ubicacionesPorPlanta(planta);
    final ubicacionDesdeQr = parsed.ubicacion.trim();
    final ubicacionPreferida =
        ubicacionDesdeQr.isNotEmpty
            ? ubicacionDesdeQr
            : state.form.nuevaUbicacion;
    final ubicacionSeleccionada = _safePick(
      ubicacionPreferida,
      ubicaciones,
      fallback: _safeFirst(ubicaciones, fallback: 'URDIDO 1 (VERDE)'),
    );

    final formBase = state.form.copyWith(
      qrRaw: qrRaw,
      qrCampos: parsed.camposDetectados,
      codigoKardex: parsed.codigoKardex,
      codigoPcp: parsed.codigoPcp,
      material: parsed.material,
      titulo: parsed.titulo,
      color: parsed.color,
      lote: parsed.lote,
      numCaja: parsed.numCajas,
      planta: planta,
      nuevaUbicacion: ubicacionSeleccionada,
      fechaSalida: _formatDate(now),
      horaSalida: _formatTime(now),
      servicio: parsed.servicio,
      movimiento: 'SALIDA',
      // Compatibilidad del flujo antiguo.
      numCajas: parsed.numCajas,
      totalBobinas: parsed.totalBobinas,
      pesoBrutoTotal: parsed.pesoBruto,
      pesoNetoTotal: parsed.pesoNeto,
    );
    final formAjustado = _applyUbicacionRules(
      formBase,
      resetSelections: true,
      clearDynamicInputs: true,
    );

    state = state.copyWith(
      status: SalidaStatus.initial,
      form: formAjustado,
      ubicacionesDisponibles: ubicaciones,
      clearUltimaUbicacion: true,
      infoMessage:
          'QR de ${parsed.camposDetectados} campos cargado. Listo para validar salida.',
      clearError: true,
    );

    if (autoConsultarUbicacion) {
      await consultarUltimaUbicacion(silent: true);
    }
  }

  Future<void> consultarUltimaUbicacion({bool silent = false}) async {
    final codigo = state.form.codigoPcp.trim();
    if (codigo.isEmpty) {
      if (!silent) {
        state = state.copyWith(
          status: SalidaStatus.error,
          errorMessage: 'Escanee un QR o ingrese codigo PCP antes de consultar',
        );
      }
      return;
    }

    state = state.copyWith(
      status: SalidaStatus.consultandoUbicacion,
      clearError: true,
      clearInfo: silent,
    );

    try {
      final ubicacion = await _datasource.obtenerUltimaUbicacion(codigo);
      state = state.copyWith(
        status: SalidaStatus.initial,
        ultimaUbicacion: ubicacion,
        infoMessage:
            silent
                ? state.infoMessage
                : 'Ultima ubicacion cargada (${ubicacion.almacen} / ${ubicacion.ubicacion})',
        clearError: true,
      );
    } catch (error) {
      if (!silent) {
        state = state.copyWith(
          status: SalidaStatus.error,
          errorMessage: _cleanError(error),
        );
      } else {
        state = state.copyWith(status: SalidaStatus.initial);
      }
    }
  }

  Future<void> enviarSalida({required String usuario}) async {
    if (_submitLock || state.isBusy) return;

    if (!state.isFormValid) {
      final missing = _missingRequiredFields(state.form);
      state = state.copyWith(
        status: SalidaStatus.error,
        errorMessage:
            missing.isEmpty
                ? 'Complete los datos obligatorios antes de enviar la salida'
                : 'Faltan campos obligatorios: ${missing.join(', ')}',
      );
      return;
    }

    final signature = _buildSignature(state.form, usuario);
    final now = DateTime.now();
    final isRepeated =
        signature == _lastSubmitSignature &&
        _lastSubmitAt != null &&
        now.difference(_lastSubmitAt!).inSeconds < 8;
    if (isRepeated) {
      state = state.copyWith(
        status: SalidaStatus.error,
        errorMessage:
            'Se detecto envio duplicado. Espere unos segundos antes de reenviar',
      );
      return;
    }

    _submitLock = true;
    state = state.copyWith(
      status: SalidaStatus.validandoMovimiento,
      clearError: true,
      clearInfo: true,
    );

    try {
      final formPayload = _buildLegacyFormPayload(usuario);
      await _ejecutarFlujoSalida(
        codigoPcp: formPayload.codigoPcp,
        nuevaUbicacion: state.form.nuevaUbicacion.trim(),
        usuario: usuario,
        formPayload: formPayload,
        numCajas: state.form.numCajas,
        totalBobinas: state.form.totalBobinas,
        pesoBrutoTotal: state.form.pesoBrutoTotal,
        pesoNetoTotal: state.form.pesoNetoTotal,
      );

      _lastSubmitSignature = signature;
      _lastSubmitAt = now;

      state = state.copyWith(
        status: SalidaStatus.exito,
        infoMessage: 'Salida registrada correctamente',
        clearError: true,
        lastSuccessAt: DateTime.now(),
        form: _clearFormAfterSuccess(state.form),
        clearUltimaUbicacion: true,
      );
    } catch (error) {
      final message = _cleanError(error);
      if (_debeEncolar(message)) {
        await _encolarSalida(usuario: usuario, baseError: message);
      } else {
        state = state.copyWith(
          status: SalidaStatus.error,
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
          status: SalidaStatus.exito,
          infoMessage: 'No hay salidas pendientes en cola',
          clearError: true,
        );
      }
      return;
    }

    _submitLock = true;
    final previousStatus = state.status;
    if (!silent) {
      state = state.copyWith(
        status: SalidaStatus.drainingQueue,
        clearError: true,
        clearInfo: true,
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
          final formPayload = SalidaLegacyFormData(
            qrCampos: job.qrCampos,
            codigoKardex: job.codigoKardex,
            codigoPcp: job.codigoPcp,
            planta: job.planta,
            ubicacion:
                job.ubicacionPayload.trim().isNotEmpty
                    ? job.ubicacionPayload.trim()
                    : job.nuevaUbicacion,
            fechaSalida: job.fechaSalida,
            horaSalida: job.horaSalida,
            servicio: job.servicio,
            usuario: job.usuario,
            movimiento:
                job.movimiento.trim().isNotEmpty ? job.movimiento : 'SALIDA',
            lote: job.lote,
            telar: job.telar,
            numeroGuia: job.numeroGuia,
            ordenCompra: job.ordenCompra,
            pesoNeto: job.pesoNetoTotal,
          );

          await _ejecutarFlujoSalida(
            codigoPcp: job.codigoPcp,
            nuevaUbicacion: job.nuevaUbicacion,
            usuario: job.usuario,
            formPayload: formPayload,
            numCajas: job.numCajas,
            totalBobinas: job.totalBobinas,
            pesoBrutoTotal: job.pesoBrutoTotal,
            pesoNetoTotal: job.pesoNetoTotal,
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
                : (failed == 0 ? SalidaStatus.exito : SalidaStatus.error),
        infoMessage:
            !silent && processed > 0
                ? 'Cola procesada: $processed salida(s). Pendientes: ${queue.length}'
                : null,
        errorMessage:
            !silent && failed > 0
                ? 'La cola se detuvo por error. Pendientes: ${queue.length}'
                : null,
      );
    } catch (error) {
      if (!silent) {
        state = state.copyWith(
          status: SalidaStatus.error,
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
      status: SalidaStatus.initial,
      clearError: true,
      clearInfo: true,
    );
  }

  Future<void> limpiarCola() async {
    await _guardarQueueAndTelemetry(const [], state.telemetry);
    state = state.copyWith(
      queue: const [],
      status: SalidaStatus.initial,
      infoMessage: 'Cola de salidas limpiada',
      clearError: true,
    );
  }

  void limpiarFormulario() {
    final formLimpio = _applyUbicacionRules(
      SalidaFormData(
        planta: state.form.planta,
        nuevaUbicacion: state.form.nuevaUbicacion,
        destinoVenta: state.form.destinoVenta,
        destinoCliente: state.form.destinoCliente,
      ),
      clearDynamicInputs: true,
    );
    state = state.copyWith(
      form: formLimpio,
      clearUltimaUbicacion: true,
      status: SalidaStatus.initial,
      clearError: true,
      clearInfo: true,
    );
  }

  Future<void> _encolarSalida({
    required String usuario,
    required String baseError,
  }) async {
    final now = DateTime.now();
    final form = state.form;
    final job = SalidaQueueJobModel(
      id: '${now.microsecondsSinceEpoch}-${state.queue.length}',
      qrCampos: form.qrCampos,
      codigoKardex: form.codigoKardex.trim(),
      codigoPcp: form.codigoPcp.trim(),
      material: form.material.trim(),
      titulo: form.titulo.trim(),
      color: form.color.trim(),
      lote: form.lote.trim(),
      numCaja: form.numCaja.trim(),
      planta: form.planta.trim(),
      nuevaUbicacion: form.nuevaUbicacion.trim(),
      ubicacionPayload: state.ubicacionPayload,
      destinoVenta: form.destinoVenta.trim(),
      destinoCliente: form.destinoCliente.trim(),
      fechaSalida: form.fechaSalida.trim(),
      horaSalida: form.horaSalida.trim(),
      servicio: form.servicio.trim(),
      movimiento:
          form.movimiento.trim().isNotEmpty ? form.movimiento.trim() : 'SALIDA',
      telar: form.telar.trim(),
      numeroGuia: form.numeroGuia.trim(),
      ordenCompra: form.ordenCompra.trim(),
      // Compatibilidad del flujo anterior.
      numCajas: form.numCajas.trim(),
      totalBobinas: form.totalBobinas.trim(),
      pesoBrutoTotal: form.pesoBrutoTotal.trim(),
      pesoNetoTotal: form.pesoNetoTotal.trim(),
      usuario: usuario.trim(),
      createdAtIso: now.toIso8601String(),
    );

    final updatedQueue = [...state.queue, job];
    final updatedTelemetry = state.telemetry.copyWith(
      enqueuedTotal: state.telemetry.enqueuedTotal + 1,
      lastAttemptAtIso: now.toIso8601String(),
      lastError: baseError,
    );

    await _guardarQueueAndTelemetry(updatedQueue, updatedTelemetry);

    state = state.copyWith(
      status: SalidaStatus.queueing,
      queue: updatedQueue,
      telemetry: updatedTelemetry,
      infoMessage: 'Sin red estable. Salida guardada en cola segura.',
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

  Future<void> _ejecutarFlujoSalida({
    required String codigoPcp,
    required String nuevaUbicacion,
    required String usuario,
    required SalidaLegacyFormData formPayload,
    required String numCajas,
    required String totalBobinas,
    required String pesoBrutoTotal,
    required String pesoNetoTotal,
  }) async {
    final validacion = await _datasource.validarMovimientoSalida(
      codigoPcp: codigoPcp,
      nuevaUbicacion: nuevaUbicacion,
      usuario: usuario,
    );

    if (!validacion.permitido) {
      throw Exception(validacion.mensaje);
    }

    if (formPayload.qrCampos == 14 || formPayload.qrCampos == 16) {
      state = state.copyWith(status: SalidaStatus.enviando);
      await _datasource.enviarFormularioSalida(formPayload);
      return;
    }

    // Compatibilidad para trabajos antiguos que usaban /actualizar_datos.
    state = state.copyWith(status: SalidaStatus.enviando);
    await _datasource.actualizarStockSalida(
      codigoPcp: codigoPcp,
      numCajas: _toDouble(numCajas),
      totalBobinas: _toDouble(totalBobinas),
      pesoBrutoTotal: _toDouble(pesoBrutoTotal),
      pesoNetoTotal: _toDouble(pesoNetoTotal),
      usuario: usuario,
    );
  }

  SalidaLegacyFormData _buildLegacyFormPayload(String usuario) {
    final now = DateTime.now();
    final fechaSalida =
        state.form.fechaSalida.trim().isNotEmpty
            ? state.form.fechaSalida.trim()
            : _formatDate(now);
    final horaSalida =
        state.form.horaSalida.trim().isNotEmpty
            ? state.form.horaSalida.trim()
            : _formatTime(now);

    return SalidaLegacyFormData(
      qrCampos: state.form.qrCampos,
      codigoKardex: state.form.codigoKardex.trim(),
      codigoPcp: state.form.codigoPcp.trim(),
      planta: state.form.planta.trim(),
      ubicacion: state.ubicacionPayload,
      fechaSalida: fechaSalida,
      horaSalida: horaSalida,
      servicio: state.form.servicio.trim(),
      usuario: usuario.trim(),
      movimiento:
          state.form.movimiento.trim().isNotEmpty
              ? state.form.movimiento.trim()
              : 'SALIDA',
      lote: state.form.lote.trim(),
      telar: state.form.telar.trim(),
      numeroGuia: state.form.numeroGuia.trim(),
      ordenCompra: state.form.ordenCompra.trim(),
      pesoNeto: state.form.pesoNetoTotal.trim(),
    );
  }

  SalidaFormData _clearFormAfterSuccess(SalidaFormData current) {
    return SalidaFormData(
      planta: current.planta,
      nuevaUbicacion: current.nuevaUbicacion,
      destinoVenta: current.destinoVenta,
      destinoCliente: current.destinoCliente,
    );
  }

  void _loadQueueAndTelemetry() {
    final rawQueue = _storage.getValue(
      AppConstants.keySalidaQueue,
      defaultValue: '',
    );
    final rawTelemetry = _storage.getValue(
      AppConstants.keySalidaTelemetry,
      defaultValue: '',
    );

    var queue = <SalidaQueueJobModel>[];
    if (rawQueue.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawQueue);
        if (decoded is List) {
          queue =
              decoded
                  .whereType<Map>()
                  .map(
                    (item) => SalidaQueueJobModel.fromJson(
                      Map<String, dynamic>.from(item),
                    ),
                  )
                  .where((job) => job.id.isNotEmpty && job.codigoPcp.isNotEmpty)
                  .toList();
        }
      } catch (_) {
        queue = <SalidaQueueJobModel>[];
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

  void _loadCatalogosCache() {
    final rawVenta = _storage.getValue(
      AppConstants.keySalidaCatalogosVenta,
      defaultValue: '',
    );
    final rawCliente = _storage.getValue(
      AppConstants.keySalidaCatalogosCliente,
      defaultValue: '',
    );

    final ventas = _decodeCatalogList(rawVenta, _fallbackDestinosVenta);
    final clientes = _decodeCatalogList(rawCliente, _fallbackDestinosCliente);

    state = state.copyWith(
      destinosVentaDisponibles: ventas,
      destinosClienteDisponibles: clientes,
    );

    final formSincronizado = _applyUbicacionRules(
      state.form.copyWith(
        destinoVenta: _safePick(
          state.form.destinoVenta,
          ventas,
          fallback: _safeFirst(ventas),
        ),
        destinoCliente: _safePick(
          state.form.destinoCliente,
          clientes,
          fallback: _safeFirst(clientes),
        ),
      ),
    );

    state = state.copyWith(form: formSincronizado);
  }

  Future<void> _guardarCatalogosCache(
    List<String> ventas,
    List<String> clientes,
  ) async {
    await _storage.setValue(
      AppConstants.keySalidaCatalogosVenta,
      jsonEncode(ventas),
    );
    await _storage.setValue(
      AppConstants.keySalidaCatalogosCliente,
      jsonEncode(clientes),
    );
  }

  List<String> _decodeCatalogList(String raw, List<String> fallback) {
    final source = raw.trim();
    if (source.isEmpty) {
      return fallback;
    }

    try {
      final decoded = jsonDecode(source);
      if (decoded is List) {
        final result = <String>{};
        for (final item in decoded) {
          final value = (item ?? '').toString().trim();
          if (value.isNotEmpty) {
            result.add(value);
          }
        }
        if (result.isNotEmpty) {
          return result.toList(growable: false);
        }
      }
    } catch (_) {
      final parsed = source
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toSet()
          .toList(growable: false);
      if (parsed.isNotEmpty) {
        return parsed;
      }
    }

    return fallback;
  }

  Future<void> _guardarQueueAndTelemetry(
    List<SalidaQueueJobModel> queue,
    QueueTelemetryModel telemetry,
  ) async {
    final queueJson = jsonEncode(queue.map((item) => item.toJson()).toList());
    final telemetryJson = jsonEncode(telemetry.toJson());

    await _storage.setValue(AppConstants.keySalidaQueue, queueJson);
    await _storage.setValue(AppConstants.keySalidaTelemetry, telemetryJson);
  }

  List<String> _missingRequiredFields(SalidaFormData form) {
    final missing = <String>[];
    final esVentaOTraslado = _esUbicacionVentaOTraslado(form.nuevaUbicacion);
    final esTenido = _esUbicacionTenido(form.nuevaUbicacion);
    final esDevolucion = _esUbicacionDevolucion(form.nuevaUbicacion);
    final requiereGuia = esVentaOTraslado || esTenido || esDevolucion;

    if (!(form.qrCampos == 14 || form.qrCampos == 16)) {
      missing.add('QR valido (14/16 campos)');
    }
    if (form.codigoPcp.trim().isEmpty) {
      missing.add('Codigo PCP');
    }
    if (form.nuevaUbicacion.trim().isEmpty) {
      missing.add('Nueva ubicacion');
    }
    if (form.fechaSalida.trim().isEmpty) {
      missing.add('Fecha de salida');
    }
    if (form.horaSalida.trim().isEmpty) {
      missing.add('Hora de salida');
    }
    if (esVentaOTraslado && form.destinoVenta.trim().isEmpty) {
      missing.add('Hacia');
    }
    if (esDevolucion && form.destinoCliente.trim().isEmpty) {
      missing.add('Cliente');
    }
    if (requiereGuia && form.numeroGuia.trim().isEmpty) {
      missing.add('Numero de guia');
    }
    if (esVentaOTraslado && form.ordenCompra.trim().isEmpty) {
      missing.add('Orden de compra (OC)');
    }

    return missing;
  }

  String _buildSignature(SalidaFormData form, String usuario) {
    final ubicacionPayload = _buildUbicacionPayload(form);
    return [
      form.qrCampos.toString(),
      form.codigoPcp.trim().toUpperCase(),
      form.nuevaUbicacion.trim().toUpperCase(),
      ubicacionPayload.toUpperCase(),
      form.numeroGuia.trim().toUpperCase(),
      form.ordenCompra.trim().toUpperCase(),
      form.fechaSalida.trim(),
      form.horaSalida.trim(),
      form.lote.trim().toUpperCase(),
      usuario.trim().toUpperCase(),
    ].join('|');
  }

  SalidaFormData _applyUbicacionRules(
    SalidaFormData form, {
    bool resetSelections = false,
    bool clearDynamicInputs = false,
  }) {
    final ventaOptions =
        state.destinosVentaDisponibles.isNotEmpty
            ? state.destinosVentaDisponibles
            : _fallbackDestinosVenta;
    final clienteOptions =
        state.destinosClienteDisponibles.isNotEmpty
            ? state.destinosClienteDisponibles
            : _fallbackDestinosCliente;

    final esVentaOTraslado = _esUbicacionVentaOTraslado(form.nuevaUbicacion);
    final esTenido = _esUbicacionTenido(form.nuevaUbicacion);
    final esDevolucion = _esUbicacionDevolucion(form.nuevaUbicacion);

    final destinoVentaDefault = _safeFirst(
      ventaOptions,
      fallback: form.destinoVenta,
    );
    final destinoClienteDefault = _safeFirst(
      clienteOptions,
      fallback: form.destinoCliente,
    );

    var destinoVenta = form.destinoVenta.trim();
    var destinoCliente = form.destinoCliente.trim();
    var numeroGuia = form.numeroGuia;
    var ordenCompra = form.ordenCompra;

    if (esVentaOTraslado) {
      if (resetSelections || destinoVenta.isEmpty) {
        destinoVenta = destinoVentaDefault;
      } else {
        destinoVenta = _safePick(
          destinoVenta,
          ventaOptions,
          fallback: destinoVentaDefault,
        );
      }
      if (resetSelections || destinoCliente.isEmpty) {
        destinoCliente = destinoClienteDefault;
      } else {
        destinoCliente = _safePick(
          destinoCliente,
          clienteOptions,
          fallback: destinoClienteDefault,
        );
      }
      if (clearDynamicInputs || resetSelections) {
        numeroGuia = '';
        ordenCompra = '';
      }
    } else if (esTenido) {
      if (resetSelections || destinoVenta.isEmpty) {
        destinoVenta = destinoVentaDefault;
      } else {
        destinoVenta = _safePick(
          destinoVenta,
          ventaOptions,
          fallback: destinoVentaDefault,
        );
      }
      if (resetSelections || destinoCliente.isEmpty) {
        destinoCliente = destinoClienteDefault;
      } else {
        destinoCliente = _safePick(
          destinoCliente,
          clienteOptions,
          fallback: destinoClienteDefault,
        );
      }
      if (clearDynamicInputs || resetSelections) {
        numeroGuia = '';
        ordenCompra = '';
      }
    } else if (esDevolucion) {
      if (resetSelections || destinoCliente.isEmpty) {
        destinoCliente = destinoClienteDefault;
      } else {
        destinoCliente = _safePick(
          destinoCliente,
          clienteOptions,
          fallback: destinoClienteDefault,
        );
      }
      if (resetSelections || destinoVenta.isEmpty) {
        destinoVenta = destinoVentaDefault;
      } else {
        destinoVenta = _safePick(
          destinoVenta,
          ventaOptions,
          fallback: destinoVentaDefault,
        );
      }
      if (clearDynamicInputs || resetSelections) {
        numeroGuia = '';
        ordenCompra = '';
      }
    } else {
      if (resetSelections || destinoCliente.isEmpty) {
        destinoCliente = destinoClienteDefault;
      } else {
        destinoCliente = _safePick(
          destinoCliente,
          clienteOptions,
          fallback: destinoClienteDefault,
        );
      }
      if (resetSelections || destinoVenta.isEmpty) {
        destinoVenta = destinoVentaDefault;
      } else {
        destinoVenta = _safePick(
          destinoVenta,
          ventaOptions,
          fallback: destinoVentaDefault,
        );
      }
      if (clearDynamicInputs || resetSelections) {
        numeroGuia = '';
        ordenCompra = '';
      }
    }

    return form.copyWith(
      destinoVenta: destinoVenta,
      destinoCliente: destinoCliente,
      numeroGuia: numeroGuia,
      ordenCompra: ordenCompra,
    );
  }

  String _buildUbicacionPayload(SalidaFormData form) {
    final ubicacionBase = form.nuevaUbicacion.trim();
    if (_esUbicacionVentaOTraslado(ubicacionBase) &&
        form.destinoVenta.trim().isNotEmpty) {
      return '$ubicacionBase - ${form.destinoVenta.trim()}';
    }
    if (_esUbicacionDevolucion(ubicacionBase) &&
        form.destinoCliente.trim().isNotEmpty) {
      return '$ubicacionBase - ${form.destinoCliente.trim()}';
    }
    return ubicacionBase;
  }

  String _formatDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yy = date.year.toString();
    return '$dd/$mm/$yy';
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

final salidaAlmacenProvider =
    StateNotifierProvider<SalidaAlmacenNotifier, SalidaAlmacenState>(
      (ref) => SalidaAlmacenNotifier(
        ref.read(movimientosDatasourceProvider),
        ref.read(localStorageProvider),
      ),
    );

double _toDouble(String value) {
  final normalized = value.replaceAll(' ', '').replaceAll(',', '.').trim();
  return double.tryParse(normalized) ?? 0;
}
