/// ============================================================================
/// DATASOURCE DE AUTENTICACIÓN - CoolImport S.A.C.
/// ============================================================================
/// Reemplaza el componente Web "inicio_sesion" de MIT App Inventor.
///
/// En MIT App Inventor:
///   Web1.Url = "https://coolimport.pythonanywhere.com/inicio_sesion"
///   Web1.PostText(jsonEncode({"password": passwordBox.Text}))
///   → Web1.GotText → verificar responseCode == 200
///
/// Aquí: se usa el ApiClient centralizado.
/// ============================================================================

import '../../models/user_model.dart';
import '../../../core/contracts/api_contracts.dart';
import '../../../core/network/api_client.dart';
import '../../../core/errors/failures.dart';

class AuthRemoteDatasource {
  final ApiClient _apiClient;

  AuthRemoteDatasource(this._apiClient);

  /// Iniciar sesión con contraseña.
  ///
  /// El backend busca en Supabase tabla "usuarios" por campo "contraseña"
  /// y retorna: {"data": ["nombre_usuario", "cargo"]}
  ///
  /// Nota: el backend actual autentica por contraseña plana (sin hash).
  /// Esto es una limitación del backend que NO debemos cambiar.
  Future<UserModel> login(String password) async {
    if (password.trim().isEmpty) {
      throw const DataFailure('La contraseña es obligatoria');
    }

    final response = await _apiClient.post(
      ApiRoutes.inicioSesion,
      data: ApiPayloads.inicioSesion(password),
    );

    if (response.success) {
      // El backend retorna: {"data": ["NombreUsuario", "CARGO"]}
      final data = response.responseData;

      if (data is List && data.length >= 2) {
        return UserModel(
          usuario: data[0].toString(),
          cargo: data[1].toString(),
        );
      }

      throw const DataFailure('Respuesta inesperada del servidor');
    }

    // Error del backend
    if (response.statusCode == 404) {
      throw const AuthFailure(
        'Su CONTRASEÑA no está registrada en el sistema, '
        'diríjase a PCP para ser registrado',
      );
    }

    throw ServerFailure(
      response.message ?? 'Error al iniciar sesión',
      statusCode: response.statusCode,
    );
  }
}
