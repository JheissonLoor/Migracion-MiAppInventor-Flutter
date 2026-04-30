import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/remote/produccion_remote_datasource.dart';
import 'auth_provider.dart';

enum ProduccionHistorialStatus { initial, loading, loaded, empty, error }

class HistorialUrdidoState {
  final ProduccionHistorialStatus status;
  final List<UrdidoHistorialTablaItem> items;
  final String filtroActual;
  final String? errorMessage;
  final String? infoMessage;

  const HistorialUrdidoState({
    this.status = ProduccionHistorialStatus.initial,
    this.items = const [],
    this.filtroActual = 'TODAS',
    this.errorMessage,
    this.infoMessage,
  });

  HistorialUrdidoState copyWith({
    ProduccionHistorialStatus? status,
    List<UrdidoHistorialTablaItem>? items,
    String? filtroActual,
    String? errorMessage,
    bool clearError = false,
    String? infoMessage,
    bool clearInfo = false,
  }) {
    return HistorialUrdidoState(
      status: status ?? this.status,
      items: items ?? this.items,
      filtroActual: filtroActual ?? this.filtroActual,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      infoMessage: clearInfo ? null : (infoMessage ?? this.infoMessage),
    );
  }
}

class HistorialTelarState {
  final ProduccionHistorialStatus status;
  final List<TelarHistorialTablaItem> items;
  final String filtroActual;
  final String? errorMessage;
  final String? infoMessage;

  const HistorialTelarState({
    this.status = ProduccionHistorialStatus.initial,
    this.items = const [],
    this.filtroActual = 'TODOS',
    this.errorMessage,
    this.infoMessage,
  });

  HistorialTelarState copyWith({
    ProduccionHistorialStatus? status,
    List<TelarHistorialTablaItem>? items,
    String? filtroActual,
    String? errorMessage,
    bool clearError = false,
    String? infoMessage,
    bool clearInfo = false,
  }) {
    return HistorialTelarState(
      status: status ?? this.status,
      items: items ?? this.items,
      filtroActual: filtroActual ?? this.filtroActual,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      infoMessage: clearInfo ? null : (infoMessage ?? this.infoMessage),
    );
  }
}

class HistorialTelaCrudaState {
  final ProduccionHistorialStatus status;
  final List<TelaCrudaHistorialItem> items;
  final String usuario;
  final String? errorMessage;
  final String? infoMessage;

  const HistorialTelaCrudaState({
    this.status = ProduccionHistorialStatus.initial,
    this.items = const [],
    this.usuario = '',
    this.errorMessage,
    this.infoMessage,
  });

  HistorialTelaCrudaState copyWith({
    ProduccionHistorialStatus? status,
    List<TelaCrudaHistorialItem>? items,
    String? usuario,
    String? errorMessage,
    bool clearError = false,
    String? infoMessage,
    bool clearInfo = false,
  }) {
    return HistorialTelaCrudaState(
      status: status ?? this.status,
      items: items ?? this.items,
      usuario: usuario ?? this.usuario,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      infoMessage: clearInfo ? null : (infoMessage ?? this.infoMessage),
    );
  }
}

class HistorialAdminState {
  final ProduccionHistorialStatus status;
  final List<HistorialAdminItem> items;
  final List<String> usuarios;
  final String usuarioSeleccionado;
  final bool loadingUsuarios;
  final String? errorMessage;
  final String? infoMessage;

  const HistorialAdminState({
    this.status = ProduccionHistorialStatus.initial,
    this.items = const [],
    this.usuarios = const [],
    this.usuarioSeleccionado = '',
    this.loadingUsuarios = false,
    this.errorMessage,
    this.infoMessage,
  });

  HistorialAdminState copyWith({
    ProduccionHistorialStatus? status,
    List<HistorialAdminItem>? items,
    List<String>? usuarios,
    String? usuarioSeleccionado,
    bool? loadingUsuarios,
    String? errorMessage,
    bool clearError = false,
    String? infoMessage,
    bool clearInfo = false,
  }) {
    return HistorialAdminState(
      status: status ?? this.status,
      items: items ?? this.items,
      usuarios: usuarios ?? this.usuarios,
      usuarioSeleccionado: usuarioSeleccionado ?? this.usuarioSeleccionado,
      loadingUsuarios: loadingUsuarios ?? this.loadingUsuarios,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      infoMessage: clearInfo ? null : (infoMessage ?? this.infoMessage),
    );
  }
}

final produccionHistorialDatasourceProvider =
    Provider<ProduccionRemoteDatasource>(
      (ref) => ProduccionRemoteDatasource(
        ref.read(apiClientProvider),
        ref.read(localStorageProvider),
      ),
    );

class HistorialUrdidoNotifier extends StateNotifier<HistorialUrdidoState> {
  final ProduccionRemoteDatasource _datasource;

  HistorialUrdidoNotifier(this._datasource)
    : super(const HistorialUrdidoState());

  Future<void> cargar({String urdidora = 'TODAS'}) async {
    final filtro = urdidora.trim().isEmpty ? 'TODAS' : urdidora.trim();
    state = state.copyWith(
      status: ProduccionHistorialStatus.loading,
      filtroActual: filtro,
      clearError: true,
      clearInfo: true,
      items: const [],
    );

    try {
      final items = await _datasource.consultarHistorialUrdidoTabla(filtro);
      if (items.isEmpty) {
        state = state.copyWith(
          status: ProduccionHistorialStatus.empty,
          items: const [],
          infoMessage: _emptyUrdidoMessage(filtro),
        );
        return;
      }

      state = state.copyWith(
        status: ProduccionHistorialStatus.loaded,
        items: items,
        infoMessage: 'Mostrando ${items.length} registros',
      );
    } catch (error) {
      state = state.copyWith(
        status: ProduccionHistorialStatus.error,
        errorMessage: _cleanError(error),
      );
    }
  }

  Future<String> cargarResumenOperario(String operario) async {
    return _datasource.consultarHistorialUrdidoOperario(operario);
  }

  String _emptyUrdidoMessage(String filtro) {
    final upper = filtro.toUpperCase();
    if (upper.contains('1') && !upper.contains('2')) {
      return 'No hay registros para Urdidora 1.';
    }
    if (upper.contains('2') && !upper.contains('1')) {
      return 'No hay registros para Urdidora 2.';
    }
    return 'No hay registros de urdido.';
  }

  String _cleanError(Object error) {
    return error.toString().replaceAll('Exception: ', '').trim();
  }
}

class HistorialTelarNotifier extends StateNotifier<HistorialTelarState> {
  final ProduccionRemoteDatasource _datasource;

  HistorialTelarNotifier(this._datasource) : super(const HistorialTelarState());

  Future<void> cargar({String telar = 'TODOS'}) async {
    final filtro = telar.trim().isEmpty ? 'TODOS' : telar.trim();
    state = state.copyWith(
      status: ProduccionHistorialStatus.loading,
      filtroActual: filtro,
      clearError: true,
      clearInfo: true,
      items: const [],
    );

    try {
      final items = await _datasource.consultarHistorialTelarTabla(filtro);
      if (items.isEmpty) {
        state = state.copyWith(
          status: ProduccionHistorialStatus.empty,
          items: const [],
          infoMessage: 'No se encontraron registros.',
        );
        return;
      }

      state = state.copyWith(
        status: ProduccionHistorialStatus.loaded,
        items: items,
        infoMessage: 'Mostrando ${items.length} registros',
      );
    } catch (error) {
      state = state.copyWith(
        status: ProduccionHistorialStatus.error,
        errorMessage: _cleanError(error),
      );
    }
  }

  String _cleanError(Object error) {
    return error.toString().replaceAll('Exception: ', '').trim();
  }
}

class HistorialTelaCrudaNotifier
    extends StateNotifier<HistorialTelaCrudaState> {
  final ProduccionRemoteDatasource _datasource;

  HistorialTelaCrudaNotifier(this._datasource)
    : super(const HistorialTelaCrudaState());

  Future<void> cargar({required String usuario}) async {
    final safeUsuario = usuario.trim();
    if (safeUsuario.isEmpty) {
      state = state.copyWith(
        status: ProduccionHistorialStatus.error,
        errorMessage: 'No hay usuario en sesion para consultar tela cruda.',
      );
      return;
    }

    state = state.copyWith(
      status: ProduccionHistorialStatus.loading,
      usuario: safeUsuario,
      items: const [],
      clearError: true,
      clearInfo: true,
    );

    try {
      final items = await _datasource.consultarHistorialTelaCruda(safeUsuario);
      if (items.isEmpty) {
        state = state.copyWith(
          status: ProduccionHistorialStatus.empty,
          items: const [],
          infoMessage: 'No hay registros de tela cruda para $safeUsuario.',
        );
        return;
      }

      final fuera = items.where((item) => item.rendimientoFuera).length;
      state = state.copyWith(
        status: ProduccionHistorialStatus.loaded,
        items: items,
        infoMessage:
            fuera > 0
                ? 'Mostrando ${items.length} registros. $fuera con rendimiento fuera.'
                : 'Mostrando ${items.length} registros.',
      );
    } catch (error) {
      state = state.copyWith(
        status: ProduccionHistorialStatus.error,
        errorMessage: _cleanError(error),
      );
    }
  }

  String _cleanError(Object error) {
    return error.toString().replaceAll('Exception: ', '').trim();
  }
}

class HistorialAdminNotifier extends StateNotifier<HistorialAdminState> {
  final ProduccionRemoteDatasource _datasource;

  HistorialAdminNotifier(this._datasource) : super(const HistorialAdminState());

  Future<void> cargarUsuarios({required String usuarioSesion}) async {
    state = state.copyWith(
      loadingUsuarios: true,
      clearError: true,
      clearInfo: true,
    );

    try {
      final usuarios = await _datasource.cargarUsuariosHistorialAdmin();
      final fallback = usuarioSesion.trim();
      final nextUsuarios =
          usuarios.isEmpty && fallback.isNotEmpty ? [fallback] : usuarios;
      final selected =
          nextUsuarios.any(
                (item) => item.toUpperCase() == fallback.toUpperCase(),
              )
              ? nextUsuarios.firstWhere(
                (item) => item.toUpperCase() == fallback.toUpperCase(),
              )
              : nextUsuarios.isNotEmpty
              ? nextUsuarios.first
              : '';

      state = state.copyWith(
        usuarios: nextUsuarios,
        usuarioSeleccionado:
            state.usuarioSeleccionado.trim().isNotEmpty
                ? state.usuarioSeleccionado
                : selected,
        loadingUsuarios: false,
        infoMessage:
            nextUsuarios.isEmpty
                ? 'No se cargaron usuarios.'
                : '${nextUsuarios.length} usuarios disponibles.',
      );
    } catch (error) {
      final fallback = usuarioSesion.trim();
      state = state.copyWith(
        usuarios: fallback.isEmpty ? const [] : [fallback],
        usuarioSeleccionado: fallback,
        loadingUsuarios: false,
        errorMessage: _cleanError(error),
      );
    }
  }

  void seleccionarUsuario(String usuario) {
    state = state.copyWith(
      usuarioSeleccionado: usuario.trim(),
      clearError: true,
      clearInfo: true,
    );
  }

  Future<void> buscar() async {
    final usuario = state.usuarioSeleccionado.trim();
    if (usuario.isEmpty) {
      state = state.copyWith(
        status: ProduccionHistorialStatus.error,
        errorMessage: 'Seleccione usuario para buscar inventario.',
      );
      return;
    }

    state = state.copyWith(
      status: ProduccionHistorialStatus.loading,
      items: const [],
      clearError: true,
      clearInfo: true,
    );

    try {
      final items = await _datasource.consultarHistorialAdmin(usuario);
      if (items.isEmpty) {
        state = state.copyWith(
          status: ProduccionHistorialStatus.empty,
          items: const [],
          infoMessage: 'No hay movimientos para $usuario.',
        );
        return;
      }

      state = state.copyWith(
        status: ProduccionHistorialStatus.loaded,
        items: items,
        infoMessage: 'Mostrando ${items.length} movimientos de $usuario.',
      );
    } catch (error) {
      state = state.copyWith(
        status: ProduccionHistorialStatus.error,
        errorMessage: _cleanError(error),
      );
    }
  }

  String _cleanError(Object error) {
    return error.toString().replaceAll('Exception: ', '').trim();
  }
}

final historialUrdidoProvider =
    StateNotifierProvider<HistorialUrdidoNotifier, HistorialUrdidoState>(
      (ref) => HistorialUrdidoNotifier(
        ref.read(produccionHistorialDatasourceProvider),
      ),
    );

final historialTelarProvider =
    StateNotifierProvider<HistorialTelarNotifier, HistorialTelarState>(
      (ref) => HistorialTelarNotifier(
        ref.read(produccionHistorialDatasourceProvider),
      ),
    );

final historialTelaCrudaProvider =
    StateNotifierProvider<HistorialTelaCrudaNotifier, HistorialTelaCrudaState>(
      (ref) => HistorialTelaCrudaNotifier(
        ref.read(produccionHistorialDatasourceProvider),
      ),
    );

final historialAdminProvider =
    StateNotifierProvider<HistorialAdminNotifier, HistorialAdminState>(
      (ref) => HistorialAdminNotifier(
        ref.read(produccionHistorialDatasourceProvider),
      ),
    );
