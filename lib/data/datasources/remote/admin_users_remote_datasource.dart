import '../../../core/contracts/api_contracts.dart';
import '../../../core/network/api_client.dart';
import '../../models/admin_user_model.dart';

class AdminUsersRemoteDatasource {
  final ApiClient _client;

  AdminUsersRemoteDatasource(this._client);

  Future<AdminUserModel> buscarUsuario(String user) async {
    final safeUser = user.trim();
    if (safeUser.isEmpty) {
      throw Exception('Debe ingresar el usuario a buscar');
    }

    final response = await _client.post(
      ApiRoutes.adminUsers,
      data: ApiPayloads.adminUsersBuscar(user: safeUser),
    );

    if (!response.success) {
      throw Exception(response.message ?? 'No se pudo consultar el usuario');
    }

    _throwIfBusinessError(response.data);

    final parsed = _parseAdminUser(response.responseData);
    if (parsed != null) {
      return parsed;
    }

    final message = response.responseMessage.trim();
    if (message.isNotEmpty) {
      throw Exception(message);
    }

    throw Exception('No se encontro el usuario solicitado');
  }

  Future<String> registrarUsuario({
    required String user,
    required String password,
    required String rol,
    required String usuarioActor,
  }) async {
    final response = await _client.post(
      ApiRoutes.newUsers,
      data: ApiPayloads.newUsersCrear(
        user: user,
        password: password,
        rol: rol,
        usuarioActor: usuarioActor,
      ),
    );

    if (!response.success) {
      throw Exception(response.message ?? 'No se pudo registrar el usuario');
    }

    _throwIfBusinessError(response.data);
    return _resolveSuccessMessage(
      response,
      fallback: 'Usuario registrado correctamente',
    );
  }

  Future<String> editarUsuario({
    required String user,
    required String password,
    required String rol,
    required String usuarioActor,
  }) async {
    final response = await _client.post(
      ApiRoutes.adminUsers,
      data: ApiPayloads.adminUsersEditar(
        user: user,
        password: password,
        rol: rol,
        usuarioActor: usuarioActor,
      ),
    );

    if (!response.success) {
      throw Exception(response.message ?? 'No se pudo editar el usuario');
    }

    _throwIfBusinessError(response.data);
    return _resolveSuccessMessage(
      response,
      fallback: 'Usuario actualizado correctamente',
    );
  }

  Future<String> eliminarUsuario({
    required String user,
    required String usuarioActor,
  }) async {
    final response = await _client.post(
      ApiRoutes.adminUsers,
      data: ApiPayloads.adminUsersEliminar(
        user: user,
        usuarioActor: usuarioActor,
      ),
    );

    if (!response.success) {
      throw Exception(response.message ?? 'No se pudo eliminar el usuario');
    }

    _throwIfBusinessError(response.data);
    return _resolveSuccessMessage(
      response,
      fallback: 'Usuario eliminado correctamente',
    );
  }

  String _resolveSuccessMessage(
    ApiResponse response, {
    required String fallback,
  }) {
    final message = response.responseMessage.trim();
    if (message.isNotEmpty) return message;
    return fallback;
  }

  void _throwIfBusinessError(dynamic data) {
    if (data is! Map) return;
    final error = (data['error'] ?? '').toString().trim();
    if (error.isNotEmpty) {
      throw Exception(error);
    }
  }

  AdminUserModel? _parseAdminUser(dynamic source) {
    if (source == null) {
      return null;
    }

    if (source is AdminUserModel) {
      return source;
    }

    if (source is Map) {
      final map = Map<String, dynamic>.from(source);
      final user = _readAny(map, const ['user', 'usuario', 'nombre']);
      final password = _readAny(map, const ['password', 'contrasena', 'clave']);
      final rol = _readAny(map, const ['rol', 'cargo', 'role']);
      if (user.isNotEmpty && rol.isNotEmpty) {
        return AdminUserModel(user: user, password: password, rol: rol);
      }
      return null;
    }

    if (source is List) {
      if (source.length >= 3 && !_containsNested(source)) {
        final user = source[0].toString().trim();
        final password = source[1].toString().trim();
        final rol = source[2].toString().trim();
        if (user.isNotEmpty && rol.isNotEmpty) {
          return AdminUserModel(user: user, password: password, rol: rol);
        }
      }

      for (final item in source) {
        final nested = _parseAdminUser(item);
        if (nested != null) {
          return nested;
        }
      }
    }

    return null;
  }

  String _readAny(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = (source[key] ?? '').toString().trim();
      if (value.isNotEmpty) {
        return value;
      }
    }
    return '';
  }

  bool _containsNested(List<dynamic> values) {
    for (final value in values) {
      if (value is List || value is Map) {
        return true;
      }
    }
    return false;
  }
}
