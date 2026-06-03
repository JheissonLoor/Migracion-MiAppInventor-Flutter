import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/remote/produccion_remote_datasource.dart';
import 'auth_provider.dart';

enum CorteRolloStatus { idle, cutting, querying, success, error }

class CorteRolloState {
  final CorteRolloStatus status;
  final Map<String, String> fields;
  final CorteRolloResult? corteResult;
  final TrazabilidadRolloData? trazabilidad;
  final String? message;
  final String? errorMessage;

  const CorteRolloState({
    this.status = CorteRolloStatus.idle,
    this.fields = const {},
    this.corteResult,
    this.trazabilidad,
    this.message,
    this.errorMessage,
  });

  bool get isBusy =>
      status == CorteRolloStatus.cutting || status == CorteRolloStatus.querying;

  CorteRolloState copyWith({
    CorteRolloStatus? status,
    Map<String, String>? fields,
    CorteRolloResult? corteResult,
    bool clearCorteResult = false,
    TrazabilidadRolloData? trazabilidad,
    bool clearTrazabilidad = false,
    String? message,
    bool clearMessage = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CorteRolloState(
      status: status ?? this.status,
      fields: fields ?? this.fields,
      corteResult: clearCorteResult ? null : (corteResult ?? this.corteResult),
      trazabilidad:
          clearTrazabilidad ? null : (trazabilidad ?? this.trazabilidad),
      message: clearMessage ? null : (message ?? this.message),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final corteRolloRemoteDatasourceProvider = Provider<ProduccionRemoteDatasource>(
  (ref) => ProduccionRemoteDatasource(
    ref.read(apiClientProvider),
    ref.read(localStorageProvider),
  ),
);

class CorteRolloNotifier extends StateNotifier<CorteRolloState> {
  final ProduccionRemoteDatasource _datasource;

  CorteRolloNotifier(this._datasource)
    : super(CorteRolloState(fields: Map<String, String>.from(_defaultFields)));

  void actualizarCampo(String key, String value) {
    final updated = Map<String, String>.from(state.fields);
    updated[key] = value;
    state = state.copyWith(
      status: CorteRolloStatus.idle,
      fields: updated,
      clearError: true,
      clearMessage: true,
    );
  }

  Future<void> cortar({required String usuario}) async {
    if (state.isBusy) return;

    final missing = _missingRequired(['codigo_madre', 'metros']);
    if (missing.isNotEmpty) {
      state = state.copyWith(
        status: CorteRolloStatus.error,
        errorMessage: 'Complete campos obligatorios: ${missing.join(', ')}.',
      );
      return;
    }

    state = state.copyWith(
      status: CorteRolloStatus.cutting,
      clearError: true,
      clearMessage: true,
      clearCorteResult: true,
    );

    try {
      final result = await _datasource.cortarRollo(
        codigoMadre: state.fields['codigo_madre'] ?? '',
        metros: state.fields['metros'] ?? '',
        destino: state.fields['destino'] ?? '',
        usuario: usuario,
      );
      final updated = Map<String, String>.from(state.fields)
        ..['consulta_codigo'] =
            result.codigoHijo.isNotEmpty
                ? result.codigoHijo
                : (state.fields['codigo_madre'] ?? '');

      state = state.copyWith(
        status: CorteRolloStatus.success,
        fields: updated,
        corteResult: result,
        message:
            result.message.isNotEmpty
                ? result.message
                : 'Corte registrado correctamente.',
      );
    } catch (error) {
      state = state.copyWith(
        status: CorteRolloStatus.error,
        errorMessage: _cleanError(error),
      );
    }
  }

  Future<void> consultar() async {
    if (state.isBusy) return;

    final codigo = (state.fields['consulta_codigo'] ?? '').trim();
    if (codigo.isEmpty) {
      state = state.copyWith(
        status: CorteRolloStatus.error,
        errorMessage: 'Ingrese codigo madre o sub-rollo para consultar.',
      );
      return;
    }

    state = state.copyWith(
      status: CorteRolloStatus.querying,
      clearError: true,
      clearMessage: true,
      clearTrazabilidad: true,
    );

    try {
      final data = await _datasource.consultarTrazabilidadRollo(codigo);
      state = state.copyWith(
        status: CorteRolloStatus.success,
        trazabilidad: data,
        message:
            data.message.isNotEmpty
                ? data.message
                : 'Trazabilidad consultada correctamente.',
      );
    } catch (error) {
      state = state.copyWith(
        status: CorteRolloStatus.error,
        errorMessage: _cleanError(error),
      );
    }
  }

  void limpiar() {
    state = CorteRolloState(fields: Map<String, String>.from(_defaultFields));
  }

  List<String> _missingRequired(List<String> keys) {
    return keys
        .where((key) => (state.fields[key] ?? '').trim().isEmpty)
        .map(_labelForKey)
        .toList(growable: false);
  }

  String _labelForKey(String key) {
    return switch (key) {
      'codigo_madre' => 'Codigo madre',
      'metros' => 'Metros',
      _ => key,
    };
  }

  String _cleanError(Object error) {
    return error.toString().replaceAll('Exception: ', '').trim();
  }
}

final corteRolloProvider =
    StateNotifierProvider<CorteRolloNotifier, CorteRolloState>(
      (ref) => CorteRolloNotifier(ref.read(corteRolloRemoteDatasourceProvider)),
    );

const Map<String, String> _defaultFields = {
  'codigo_madre': '',
  'metros': '',
  'destino': '',
  'consulta_codigo': '',
};
