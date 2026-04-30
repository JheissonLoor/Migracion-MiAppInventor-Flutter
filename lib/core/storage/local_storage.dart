/// ============================================================================
/// ALMACENAMIENTO LOCAL - CoolImport S.A.C.
/// ============================================================================
/// Reemplaza TinyDB de MIT App Inventor.
/// Guarda: usuario, cargo, estado de sesión.
/// Usa SharedPreferences (persiste entre reinicios de la app).
/// ============================================================================

import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_constants.dart';
import '../config/environment.dart';

class LocalStorage {
  late final SharedPreferences _prefs;

  /// Inicializar (llamar una vez en main.dart)
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ════════════════════════════════════════
  // SESIÓN DE USUARIO (equivalente a TinyDB)
  // ════════════════════════════════════════

  /// Guardar datos de sesión después del login exitoso.
  /// En MIT App Inventor esto era:
  ///   TinyDB1.StoreValue(tag: "usuario", value: usuario)
  ///   TinyDB1.StoreValue(tag: "cargo", value: cargo)
  Future<void> saveSession({
    required String usuario,
    required String cargo,
  }) async {
    await _prefs.setString(AppConstants.keyUsuario, usuario);
    await _prefs.setString(AppConstants.keyCargo, cargo);
    await _prefs.setBool(AppConstants.keyIsLoggedIn, true);
    await _prefs.setString(
      AppConstants.keyLastLogin,
      DateTime.now().toIso8601String(),
    );
  }

  /// Obtener nombre del usuario actual.
  /// En MIT App Inventor: TinyDB1.GetValue(tag: "usuario")
  String get usuario => _prefs.getString(AppConstants.keyUsuario) ?? '';

  /// Obtener cargo/rol del usuario actual.
  /// En MIT App Inventor: TinyDB1.GetValue(tag: "cargo")
  String get cargo => _prefs.getString(AppConstants.keyCargo) ?? '';

  /// Verificar si hay sesión activa.
  /// En MIT App Inventor: TinyDB1.GetValue(tag: "isLoggedIn")
  bool get isLoggedIn => _prefs.getBool(AppConstants.keyIsLoggedIn) ?? false;

  /// Cerrar sesión (limpiar datos).
  /// En MIT App Inventor: TinyDB1.ClearAll
  Future<void> clearSession() async {
    await _prefs.remove(AppConstants.keyUsuario);
    await _prefs.remove(AppConstants.keyCargo);
    await _prefs.setBool(AppConstants.keyIsLoggedIn, false);
  }

  // ════════════════════════════════════════
  // HELPERS DE ROL
  // ════════════════════════════════════════

  /// ¿El usuario actual es admin o PCP?
  bool get isAdmin => AppConstants.rolesAdmin.contains(cargo.toUpperCase());

  /// ¿El usuario actual es operario de producción?
  bool get isProduccion =>
      AppConstants.rolesProduccion.contains(cargo.toUpperCase());

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // CONFIGURACION OPERATIVA LOCAL
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  String get localApiUrl =>
      _prefs.getString(AppConstants.keyLocalApiUrl) ??
      EnvironmentConfig.localApiUrl;

  Future<void> setLocalApiUrl(String value) async {
    final sanitized = value.trim();
    if (sanitized.isEmpty) {
      await _prefs.remove(AppConstants.keyLocalApiUrl);
      return;
    }
    await _prefs.setString(AppConstants.keyLocalApiUrl, sanitized);
  }

  String get telaresLocalApiUrl =>
      _prefs.getString(AppConstants.keyTelaresLocalApiUrl) ??
      EnvironmentConfig.telaresLocalApiUrl;

  Future<void> setTelaresLocalApiUrl(String value) async {
    final sanitized = value.trim();
    if (sanitized.isEmpty) {
      await _prefs.remove(AppConstants.keyTelaresLocalApiUrl);
      return;
    }
    await _prefs.setString(AppConstants.keyTelaresLocalApiUrl, sanitized);
  }

  // ════════════════════════════════════════
  // ALMACENAMIENTO GENÉRICO
  // ════════════════════════════════════════

  /// Guardar valor genérico (para cualquier dato extra)
  Future<void> setValue(String key, String value) async {
    await _prefs.setString(key, value);
  }

  /// Obtener valor genérico
  String getValue(String key, {String defaultValue = ''}) {
    return _prefs.getString(key) ?? defaultValue;
  }

  /// Eliminar valor
  Future<void> removeValue(String key) async {
    await _prefs.remove(key);
  }
}
