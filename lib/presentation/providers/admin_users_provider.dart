import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/remote/admin_users_remote_datasource.dart';
import 'auth_provider.dart';

enum AdminUsersStatus { idle, searching, saving, deleting, success, error }

class AdminUsersState {
  final AdminUsersStatus status;
  final String searchUser;
  final String user;
  final String password;
  final String rol;
  final bool existingUser;
  final String? message;
  final String? errorMessage;

  const AdminUsersState({
    this.status = AdminUsersStatus.idle,
    this.searchUser = '',
    this.user = '',
    this.password = '',
    this.rol = '',
    this.existingUser = false,
    this.message,
    this.errorMessage,
  });

  bool get isBusy =>
      status == AdminUsersStatus.searching ||
      status == AdminUsersStatus.saving ||
      status == AdminUsersStatus.deleting;

  bool get canSubmit =>
      user.trim().isNotEmpty &&
      password.trim().isNotEmpty &&
      rol.trim().isNotEmpty;

  AdminUsersState copyWith({
    AdminUsersStatus? status,
    String? searchUser,
    String? user,
    String? password,
    String? rol,
    bool? existingUser,
    String? message,
    bool clearMessage = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AdminUsersState(
      status: status ?? this.status,
      searchUser: searchUser ?? this.searchUser,
      user: user ?? this.user,
      password: password ?? this.password,
      rol: rol ?? this.rol,
      existingUser: existingUser ?? this.existingUser,
      message: clearMessage ? null : (message ?? this.message),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final adminUsersDatasourceProvider = Provider<AdminUsersRemoteDatasource>(
  (ref) => AdminUsersRemoteDatasource(ref.read(apiClientProvider)),
);

class AdminUsersNotifier extends StateNotifier<AdminUsersState> {
  final AdminUsersRemoteDatasource _datasource;

  AdminUsersNotifier(this._datasource) : super(const AdminUsersState());

  void setSearchUser(String value) {
    state = state.copyWith(
      searchUser: value,
      status: AdminUsersStatus.idle,
      clearError: true,
      clearMessage: true,
    );
  }

  void setUser(String value) {
    state = state.copyWith(
      user: value,
      status: AdminUsersStatus.idle,
      clearError: true,
      clearMessage: true,
    );
  }

  void setPassword(String value) {
    state = state.copyWith(
      password: value,
      status: AdminUsersStatus.idle,
      clearError: true,
      clearMessage: true,
    );
  }

  void setRol(String value) {
    state = state.copyWith(
      rol: value,
      status: AdminUsersStatus.idle,
      clearError: true,
      clearMessage: true,
    );
  }

  void prepararNuevo() {
    state = state.copyWith(
      user: '',
      password: '',
      rol: '',
      existingUser: false,
      status: AdminUsersStatus.idle,
      clearError: true,
      clearMessage: true,
    );
  }

  void limpiarTodo() {
    state = const AdminUsersState();
  }

  Future<void> buscarUsuario() async {
    if (state.isBusy) return;

    final target =
        state.searchUser.trim().isNotEmpty
            ? state.searchUser.trim()
            : state.user.trim();

    if (target.isEmpty) {
      state = state.copyWith(
        status: AdminUsersStatus.error,
        errorMessage: 'Debe ingresar el usuario a buscar',
      );
      return;
    }

    state = state.copyWith(
      status: AdminUsersStatus.searching,
      clearError: true,
      clearMessage: true,
    );

    try {
      final result = await _datasource.buscarUsuario(target);
      state = state.copyWith(
        status: AdminUsersStatus.success,
        searchUser: result.user,
        user: result.user,
        password: result.password,
        rol: result.rol,
        existingUser: true,
        message: 'Usuario cargado para edicion o eliminacion',
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        status: AdminUsersStatus.error,
        existingUser: false,
        errorMessage: _cleanError(error),
      );
    }
  }

  Future<void> registrarUsuario({required String usuarioActor}) async {
    if (state.isBusy) return;

    final validationError = _validarFormulario();
    if (validationError != null) {
      state = state.copyWith(
        status: AdminUsersStatus.error,
        errorMessage: validationError,
      );
      return;
    }

    state = state.copyWith(
      status: AdminUsersStatus.saving,
      clearError: true,
      clearMessage: true,
    );

    try {
      final message = await _datasource.registrarUsuario(
        user: state.user,
        password: state.password,
        rol: state.rol,
        usuarioActor: usuarioActor,
      );
      state = state.copyWith(
        status: AdminUsersStatus.success,
        searchUser: state.user,
        existingUser: true,
        message: message,
      );
    } catch (error) {
      state = state.copyWith(
        status: AdminUsersStatus.error,
        errorMessage: _cleanError(error),
      );
    }
  }

  Future<void> editarUsuario({required String usuarioActor}) async {
    if (state.isBusy) return;

    final validationError = _validarFormulario();
    if (validationError != null) {
      state = state.copyWith(
        status: AdminUsersStatus.error,
        errorMessage: validationError,
      );
      return;
    }

    state = state.copyWith(
      status: AdminUsersStatus.saving,
      clearError: true,
      clearMessage: true,
    );

    try {
      final message = await _datasource.editarUsuario(
        user: state.user,
        password: state.password,
        rol: state.rol,
        usuarioActor: usuarioActor,
      );
      state = state.copyWith(
        status: AdminUsersStatus.success,
        searchUser: state.user,
        existingUser: true,
        message: message,
      );
    } catch (error) {
      state = state.copyWith(
        status: AdminUsersStatus.error,
        errorMessage: _cleanError(error),
      );
    }
  }

  Future<void> eliminarUsuario({required String usuarioActor}) async {
    if (state.isBusy) return;

    final user = state.user.trim();
    if (user.isEmpty) {
      state = state.copyWith(
        status: AdminUsersStatus.error,
        errorMessage: 'Debe cargar un usuario antes de eliminar',
      );
      return;
    }

    state = state.copyWith(
      status: AdminUsersStatus.deleting,
      clearError: true,
      clearMessage: true,
    );

    try {
      final message = await _datasource.eliminarUsuario(
        user: user,
        usuarioActor: usuarioActor,
      );
      state = state.copyWith(
        status: AdminUsersStatus.success,
        searchUser: '',
        user: '',
        password: '',
        rol: '',
        existingUser: false,
        message: message,
      );
    } catch (error) {
      state = state.copyWith(
        status: AdminUsersStatus.error,
        errorMessage: _cleanError(error),
      );
    }
  }

  String? _validarFormulario() {
    if (state.user.trim().isEmpty ||
        state.password.trim().isEmpty ||
        state.rol.trim().isEmpty) {
      return 'Complete usuario, contrasena y cargo para continuar';
    }

    final rol = state.rol.trim().toUpperCase();
    if (!adminUsersRoles.map((item) => item.toUpperCase()).contains(rol)) {
      return 'Seleccione un cargo valido';
    }

    return null;
  }

  String _cleanError(Object error) {
    return error.toString().replaceAll('Exception: ', '').trim();
  }
}

final adminUsersProvider =
    StateNotifierProvider<AdminUsersNotifier, AdminUsersState>(
      (ref) => AdminUsersNotifier(ref.read(adminUsersDatasourceProvider)),
    );

const List<String> adminUsersRoles = [
  'Administrador',
  'AdministradorS',
  'Operario',
  'Revisador',
  'Engomador',
  'Urdidor',
];
