import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/remote/proveedor_remote_datasource.dart';

enum EditarProveedorStatus {
  idle,
  buscandoCodigo,
  buscandoTaras,
  guardando,
  success,
  error,
}

class EditarProveedorState {
  final EditarProveedorStatus status;
  final String proveedor;
  final String material;
  final String titulo;
  final String codigo;
  final String taraCono;
  final String taraBolsa;
  final String taraCaja;
  final String taraSaco;
  final String? message;
  final String? errorMessage;

  const EditarProveedorState({
    this.status = EditarProveedorStatus.idle,
    this.proveedor = '',
    this.material = '',
    this.titulo = '',
    this.codigo = '',
    this.taraCono = '',
    this.taraBolsa = '',
    this.taraCaja = '',
    this.taraSaco = '',
    this.message,
    this.errorMessage,
  });

  bool get isBusy =>
      status == EditarProveedorStatus.buscandoCodigo ||
      status == EditarProveedorStatus.buscandoTaras ||
      status == EditarProveedorStatus.guardando;

  bool get canBuscarCodigo =>
      proveedor.trim().isNotEmpty &&
      material.trim().isNotEmpty &&
      titulo.trim().isNotEmpty;

  bool get canGuardarTaras =>
      codigo.trim().isNotEmpty &&
      taraCono.trim().isNotEmpty &&
      taraBolsa.trim().isNotEmpty &&
      taraCaja.trim().isNotEmpty &&
      taraSaco.trim().isNotEmpty;

  EditarProveedorState copyWith({
    EditarProveedorStatus? status,
    String? proveedor,
    String? material,
    String? titulo,
    String? codigo,
    String? taraCono,
    String? taraBolsa,
    String? taraCaja,
    String? taraSaco,
    String? message,
    bool clearMessage = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return EditarProveedorState(
      status: status ?? this.status,
      proveedor: proveedor ?? this.proveedor,
      material: material ?? this.material,
      titulo: titulo ?? this.titulo,
      codigo: codigo ?? this.codigo,
      taraCono: taraCono ?? this.taraCono,
      taraBolsa: taraBolsa ?? this.taraBolsa,
      taraCaja: taraCaja ?? this.taraCaja,
      taraSaco: taraSaco ?? this.taraSaco,
      message: clearMessage ? null : (message ?? this.message),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final proveedorDatasourceProvider = Provider<ProveedorRemoteDatasource>(
  (ref) => ProveedorRemoteDatasource(),
);

class EditarProveedorNotifier extends StateNotifier<EditarProveedorState> {
  final ProveedorRemoteDatasource _datasource;

  EditarProveedorNotifier(this._datasource)
      : super(const EditarProveedorState());

  void setProveedor(String value) {
    state = state.copyWith(
      proveedor: value,
      status: EditarProveedorStatus.idle,
      clearError: true,
      clearMessage: true,
    );
  }

  void setMaterial(String value) {
    state = state.copyWith(
      material: value,
      status: EditarProveedorStatus.idle,
      clearError: true,
      clearMessage: true,
    );
  }

  void setTitulo(String value) {
    state = state.copyWith(
      titulo: value,
      status: EditarProveedorStatus.idle,
      clearError: true,
      clearMessage: true,
    );
  }

  void setTaraCono(String value) {
    state = state.copyWith(
      taraCono: value,
      status: EditarProveedorStatus.idle,
      clearError: true,
      clearMessage: true,
    );
  }

  void setTaraBolsa(String value) {
    state = state.copyWith(
      taraBolsa: value,
      status: EditarProveedorStatus.idle,
      clearError: true,
      clearMessage: true,
    );
  }

  void setTaraCaja(String value) {
    state = state.copyWith(
      taraCaja: value,
      status: EditarProveedorStatus.idle,
      clearError: true,
      clearMessage: true,
    );
  }

  void setTaraSaco(String value) {
    state = state.copyWith(
      taraSaco: value,
      status: EditarProveedorStatus.idle,
      clearError: true,
      clearMessage: true,
    );
  }

  Future<void> buscarCodigoProveedor() async {
    if (state.isBusy) return;

    if (!state.canBuscarCodigo) {
      state = state.copyWith(
        status: EditarProveedorStatus.error,
        errorMessage: 'Complete proveedor, material y titulo para buscar',
      );
      return;
    }

    state = state.copyWith(
      status: EditarProveedorStatus.buscandoCodigo,
      clearError: true,
      clearMessage: true,
    );

    try {
      final codigo = await _datasource.buscarCodigoProveedor(
        proveedor: state.proveedor,
        material: state.material,
        titulo: state.titulo,
      );

      state = state.copyWith(
        status: EditarProveedorStatus.success,
        codigo: codigo,
        message: 'Codigo encontrado: $codigo',
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        status: EditarProveedorStatus.error,
        errorMessage: _cleanError(error),
      );
    }
  }

  Future<void> buscarTarasProveedor() async {
    if (state.isBusy) return;

    if (state.codigo.trim().isEmpty) {
      state = state.copyWith(
        status: EditarProveedorStatus.error,
        errorMessage: 'Primero busque y seleccione un codigo valido',
      );
      return;
    }

    state = state.copyWith(
      status: EditarProveedorStatus.buscandoTaras,
      clearError: true,
      clearMessage: true,
    );

    try {
      final taras = await _datasource.obtenerTarasPorCodigo(state.codigo);

      state = state.copyWith(
        status: EditarProveedorStatus.success,
        taraCono: taras.taraCono,
        taraBolsa: taras.taraBolsa,
        taraCaja: taras.taraCaja,
        taraSaco: taras.taraSaco,
        message: 'Taras cargadas desde Google Apps Script',
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        status: EditarProveedorStatus.error,
        errorMessage: _cleanError(error),
      );
    }
  }

  Future<void> guardarTarasProveedor() async {
    if (state.isBusy) return;

    if (!state.canGuardarTaras) {
      state = state.copyWith(
        status: EditarProveedorStatus.error,
        errorMessage: 'Complete todas las taras antes de guardar cambios',
      );
      return;
    }

    state = state.copyWith(
      status: EditarProveedorStatus.guardando,
      clearError: true,
      clearMessage: true,
    );

    try {
      final message = await _datasource.actualizarTarasProveedor(
        codigo: state.codigo,
        taras: ProveedorTarasModel(
          taraCono: state.taraCono,
          taraBolsa: state.taraBolsa,
          taraCaja: state.taraCaja,
          taraSaco: state.taraSaco,
        ),
      );

      state = state.copyWith(
        status: EditarProveedorStatus.success,
        message: message,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        status: EditarProveedorStatus.error,
        errorMessage: _cleanError(error),
      );
    }
  }

  void limpiarFormulario() {
    state = const EditarProveedorState();
  }

  String _cleanError(Object error) {
    return error.toString().replaceAll('Exception: ', '').trim();
  }
}

final editarProveedorProvider =
    StateNotifierProvider<EditarProveedorNotifier, EditarProveedorState>(
      (ref) => EditarProveedorNotifier(ref.read(proveedorDatasourceProvider)),
    );
