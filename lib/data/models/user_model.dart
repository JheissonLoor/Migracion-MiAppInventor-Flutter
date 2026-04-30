/// ============================================================================
/// MODELO DE USUARIO - CoolImport S.A.C.
/// ============================================================================
/// Representa un usuario autenticado.
/// Los datos vienen de Supabase tabla "usuarios" vía el endpoint /inicio_sesion.
/// ============================================================================

class UserModel {
  final String usuario;
  final String cargo;

  const UserModel({
    required this.usuario,
    required this.cargo,
  });

  /// Crear desde JSON del backend
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      usuario: json['usuario'] ?? '',
      cargo: json['cargo'] ?? '',
    );
  }

  /// Crear desde array (formato actual del backend: ["nombre", "cargo"])
  factory UserModel.fromList(List<dynamic> data) {
    return UserModel(
      usuario: data.isNotEmpty ? data[0].toString() : '',
      cargo: data.length > 1 ? data[1].toString() : '',
    );
  }

  Map<String, dynamic> toJson() => {
        'usuario': usuario,
        'cargo': cargo,
      };

  @override
  String toString() => 'UserModel(usuario: $usuario, cargo: $cargo)';
}
