/// ============================================================================
/// PROVIDER DE ALMACÉN - CoolImport S.A.C.
/// ============================================================================
/// Maneja el estado de las pantallas de almacén:
///   - Consulta Almacén (ubicación por código PCP)
///   - Historial de movimientos
/// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/almacen_remote_datasource.dart';
import 'auth_provider.dart';

// ════════════════════════════════════════
// PROVIDERS BASE
// ════════════════════════════════════════

/// Datasource de almacén
final almacenDatasourceProvider = Provider<AlmacenRemoteDatasource>((ref) {
  return AlmacenRemoteDatasource(ref.read(apiClientProvider));
});

// ════════════════════════════════════════
// CONSULTA ALMACÉN
// ════════════════════════════════════════

enum ConsultaStatus { initial, loading, loaded, error, empty }

class ConsultaAlmacenState {
  final ConsultaStatus status;
  final List<AlmacenResult> results;
  final String? errorMessage;
  final String? searchedCode;

  const ConsultaAlmacenState({
    this.status = ConsultaStatus.initial,
    this.results = const [],
    this.errorMessage,
    this.searchedCode,
  });

  ConsultaAlmacenState copyWith({
    ConsultaStatus? status,
    List<AlmacenResult>? results,
    String? errorMessage,
    String? searchedCode,
  }) {
    return ConsultaAlmacenState(
      status: status ?? this.status,
      results: results ?? this.results,
      errorMessage: errorMessage,
      searchedCode: searchedCode ?? this.searchedCode,
    );
  }
}

class ConsultaAlmacenNotifier extends StateNotifier<ConsultaAlmacenState> {
  final AlmacenRemoteDatasource _datasource;

  ConsultaAlmacenNotifier(this._datasource)
      : super(const ConsultaAlmacenState());

  /// Buscar ubicación por código PCP
  Future<void> buscar(String codigoPcp) async {
    if (codigoPcp.trim().isEmpty) {
      state = const ConsultaAlmacenState(
        status: ConsultaStatus.error,
        errorMessage: 'Ingrese un código PCP para buscar',
      );
      return;
    }

    state = ConsultaAlmacenState(
      status: ConsultaStatus.loading,
      searchedCode: codigoPcp.trim(),
    );

    try {
      final results = await _datasource.consultarUbicacion(codigoPcp.trim());
      if (results.isEmpty) {
        state = ConsultaAlmacenState(
          status: ConsultaStatus.empty,
          searchedCode: codigoPcp.trim(),
        );
      } else {
        state = ConsultaAlmacenState(
          status: ConsultaStatus.loaded,
          results: results,
          searchedCode: codigoPcp.trim(),
        );
      }
    } catch (e) {
      state = ConsultaAlmacenState(
        status: ConsultaStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
        searchedCode: codigoPcp.trim(),
      );
    }
  }

  /// Limpiar resultados
  void limpiar() {
    state = const ConsultaAlmacenState();
  }
}

final consultaAlmacenProvider =
    StateNotifierProvider<ConsultaAlmacenNotifier, ConsultaAlmacenState>((ref) {
  return ConsultaAlmacenNotifier(ref.read(almacenDatasourceProvider));
});

// ════════════════════════════════════════
// HISTORIAL
// ════════════════════════════════════════

class HistorialState {
  final ConsultaStatus status;
  final List<HistorialItem> items;
  final String? errorMessage;
  final String filtroActual;

  const HistorialState({
    this.status = ConsultaStatus.initial,
    this.items = const [],
    this.errorMessage,
    this.filtroActual = 'SALIDA',
  });

  HistorialState copyWith({
    ConsultaStatus? status,
    List<HistorialItem>? items,
    String? errorMessage,
    String? filtroActual,
  }) {
    return HistorialState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage,
      filtroActual: filtroActual ?? this.filtroActual,
    );
  }
}

class HistorialNotifier extends StateNotifier<HistorialState> {
  final AlmacenRemoteDatasource _datasource;

  HistorialNotifier(this._datasource) : super(const HistorialState());

  /// Buscar historial
  Future<void> buscar({required String usuario, required String filtro}) async {
    state = HistorialState(
      status: ConsultaStatus.loading,
      filtroActual: filtro,
    );

    try {
      final items = await _datasource.consultarHistorial(
        usuario: usuario,
        filtro: filtro,
      );
      if (items.isEmpty) {
        state = HistorialState(
          status: ConsultaStatus.empty,
          filtroActual: filtro,
        );
      } else {
        state = HistorialState(
          status: ConsultaStatus.loaded,
          items: items,
          filtroActual: filtro,
        );
      }
    } catch (e) {
      state = HistorialState(
        status: ConsultaStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
        filtroActual: filtro,
      );
    }
  }

  /// Cambiar filtro
  void cambiarFiltro(String filtro) {
    state = state.copyWith(filtroActual: filtro);
  }
}

final historialProvider =
    StateNotifierProvider<HistorialNotifier, HistorialState>((ref) {
  return HistorialNotifier(ref.read(almacenDatasourceProvider));
});
