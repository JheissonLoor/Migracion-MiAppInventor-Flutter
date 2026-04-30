import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/contracts/api_contracts.dart';
import '../../data/datasources/remote/produccion_remote_datasource.dart';
import 'auth_provider.dart';

enum IngresoTelarStatus {
  idle,
  loadingProgress,
  loadingArticulo,
  saving,
  completing,
  success,
  error,
}

class IngresoTelarState {
  final IngresoTelarStatus status;
  final Map<String, String> fields;
  final String estadoActual;
  final String? message;
  final String? errorMessage;
  final bool initialized;

  const IngresoTelarState({
    this.status = IngresoTelarStatus.idle,
    this.fields = const {},
    this.estadoActual = 'NUEVO',
    this.message,
    this.errorMessage,
    this.initialized = false,
  });

  bool get isBusy =>
      status == IngresoTelarStatus.loadingProgress ||
      status == IngresoTelarStatus.loadingArticulo ||
      status == IngresoTelarStatus.saving ||
      status == IngresoTelarStatus.completing;

  IngresoTelarState copyWith({
    IngresoTelarStatus? status,
    Map<String, String>? fields,
    String? estadoActual,
    String? message,
    bool clearMessage = false,
    String? errorMessage,
    bool clearError = false,
    bool? initialized,
  }) {
    return IngresoTelarState(
      status: status ?? this.status,
      fields: fields ?? this.fields,
      estadoActual: estadoActual ?? this.estadoActual,
      message: clearMessage ? null : (message ?? this.message),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      initialized: initialized ?? this.initialized,
    );
  }
}

final ingresoTelarRemoteDatasourceProvider =
    Provider<ProduccionRemoteDatasource>(
      (ref) => ProduccionRemoteDatasource(
        ref.read(apiClientProvider),
        ref.read(localStorageProvider),
      ),
    );

class IngresoTelarNotifier extends StateNotifier<IngresoTelarState> {
  final ProduccionRemoteDatasource _datasource;
  String _operario = '';

  IngresoTelarNotifier(this._datasource)
    : super(
        IngresoTelarState(
          fields: Map<String, String>.from(_defaultIngresoTelarFields),
        ),
      );

  Future<void> inicializar(String operario) async {
    final safeOperario = operario.trim();
    if (safeOperario.isEmpty) {
      return;
    }

    if (state.initialized &&
        _operario.toUpperCase() == safeOperario.toUpperCase()) {
      return;
    }

    _operario = safeOperario;
    await cargarProgreso();
  }

  void actualizarCampo(String key, String value) {
    final updated = Map<String, String>.from(state.fields);
    updated[key] = value;
    state = state.copyWith(
      fields: updated,
      status: IngresoTelarStatus.idle,
      clearError: true,
      clearMessage: true,
    );
  }

  void seleccionarFechaInicio(DateTime date) {
    actualizarCampo('fecha_inicio', _legacyDate(date));
  }

  void seleccionarFechaFinal(DateTime date) {
    actualizarCampo('fecha_final', _legacyDate(date));
  }

  Future<void> cargarProgreso() async {
    if (_operario.isEmpty || state.isBusy) {
      return;
    }

    state = state.copyWith(
      status: IngresoTelarStatus.loadingProgress,
      clearError: true,
      clearMessage: true,
    );

    try {
      final progress = await _datasource.cargarProgresoIngresoTelar(_operario);
      if (progress == null) {
        state = state.copyWith(
          status: IngresoTelarStatus.success,
          initialized: true,
          estadoActual: 'NUEVO',
          message: 'Sin registro en progreso. Llene los campos para comenzar.',
        );
        return;
      }

      state = state.copyWith(
        status: IngresoTelarStatus.success,
        initialized: true,
        fields: {
          ...Map<String, String>.from(_defaultIngresoTelarFields),
          ...progress.toFields(),
        },
        estadoActual: 'EN PROGRESO',
        message: 'Registro en progreso cargado.',
      );
    } catch (error) {
      state = state.copyWith(
        status: IngresoTelarStatus.error,
        initialized: true,
        errorMessage: _cleanError(error),
      );
    }
  }

  Future<void> buscarArticuloActual() async {
    if (state.isBusy) {
      return;
    }

    final telar = (state.fields['telar'] ?? '').trim();
    if (telar.isEmpty) {
      return;
    }

    state = state.copyWith(
      status: IngresoTelarStatus.loadingArticulo,
      clearError: true,
      clearMessage: true,
    );

    try {
      final articulo = await _datasource.obtenerArticuloActualTelar(telar);
      final updated = Map<String, String>.from(state.fields);
      if (articulo.isNotEmpty) {
        updated['articulo'] = articulo;
      }
      state = state.copyWith(
        status: IngresoTelarStatus.success,
        fields: updated,
        message:
            articulo.isEmpty
                ? 'No se encontro articulo para el telar.'
                : 'Articulo autocompletado.',
      );
    } catch (error) {
      state = state.copyWith(
        status: IngresoTelarStatus.error,
        errorMessage: _cleanError(error),
      );
    }
  }

  Future<void> guardarProgreso() async {
    if (state.isBusy) {
      return;
    }

    final telar = (state.fields['telar'] ?? '').trim();
    final articulo = (state.fields['articulo'] ?? '').trim();

    if (telar.isEmpty || articulo.isEmpty) {
      state = state.copyWith(
        status: IngresoTelarStatus.error,
        errorMessage: 'Debe ingresar al menos Telar y Articulo.',
      );
      return;
    }

    state = state.copyWith(
      status: IngresoTelarStatus.saving,
      clearError: true,
      clearMessage: true,
    );

    try {
      final payload = _buildPayload(accion: 'guardar', estado: 'EN PROGRESO');
      final message = await _datasource.enviarIngresoTelar(payload);
      state = state.copyWith(
        status: IngresoTelarStatus.success,
        estadoActual: 'EN PROGRESO',
        message: message,
      );
    } catch (error) {
      state = state.copyWith(
        status: IngresoTelarStatus.error,
        errorMessage: _cleanError(error),
      );
    }
  }

  Future<void> completarRegistro() async {
    if (state.isBusy) {
      return;
    }

    final telar = (state.fields['telar'] ?? '').trim();
    final fechaFinal = (state.fields['fecha_final'] ?? '').trim();
    final pesoTotal = (state.fields['peso_total'] ?? '').trim();

    if (telar.isEmpty || fechaFinal.isEmpty || pesoTotal.isEmpty) {
      state = state.copyWith(
        status: IngresoTelarStatus.error,
        errorMessage:
            'Para completar necesita: Telar, Fecha Final y Peso Total.',
      );
      return;
    }

    state = state.copyWith(
      status: IngresoTelarStatus.completing,
      clearError: true,
      clearMessage: true,
    );

    try {
      final payload = _buildPayload(accion: 'completar', estado: 'COMPLETADO');
      final message = await _datasource.enviarIngresoTelar(payload);
      state = state.copyWith(
        status: IngresoTelarStatus.success,
        estadoActual: 'COMPLETADO',
        message: message,
      );
    } catch (error) {
      state = state.copyWith(
        status: IngresoTelarStatus.error,
        errorMessage: _cleanError(error),
      );
    }
  }

  void nuevoRegistro() {
    state = state.copyWith(
      status: IngresoTelarStatus.idle,
      fields: Map<String, String>.from(_defaultIngresoTelarFields),
      estadoActual: 'NUEVO',
      clearError: true,
      message: 'Campos limpiados. Listo para nuevo registro.',
    );
  }

  Map<String, dynamic> _buildPayload({
    required String accion,
    required String estado,
  }) {
    final fields = state.fields;
    return ApiPayloads.ingresoTelar(
      telar: fields['telar'] ?? '',
      articulo: fields['articulo'] ?? '',
      hilo: fields['hilo'] ?? '',
      titulo: fields['titulo'] ?? '',
      metraje: fields['metraje'] ?? '',
      fechaInicio: fields['fecha_inicio'] ?? '',
      fechaFinal: fields['fecha_final'] ?? '',
      pesoTotal: fields['peso_total'] ?? '',
      estado: estado,
      operario: _operario,
      accion: accion,
    );
  }

  String _legacyDate(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }

  String _cleanError(Object error) {
    return error.toString().replaceAll('Exception: ', '').trim();
  }
}

final ingresoTelarProvider =
    StateNotifierProvider<IngresoTelarNotifier, IngresoTelarState>(
      (ref) =>
          IngresoTelarNotifier(ref.read(ingresoTelarRemoteDatasourceProvider)),
    );

const Map<String, String> _defaultIngresoTelarFields = {
  'telar': '',
  'articulo': '',
  'hilo': '',
  'titulo': '',
  'metraje': '',
  'fecha_inicio': '',
  'fecha_final': '',
  'peso_total': '',
};
