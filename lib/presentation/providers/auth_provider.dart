/// ============================================================================
/// PROVIDER DE AUTENTICACIÓN - CoolImport S.A.C.
/// ============================================================================
/// Maneja el estado de autenticación de la app.
/// Reemplaza la lógica de Screen1 de MIT App Inventor:
///   - Botón1.Click → Web.PostText
///   - Web.GotText → verificar respuesta → TinyDB.StoreValue → abrir Screen2
/// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/local_storage.dart';
import '../../data/datasources/remote/auth_remote_datasource.dart';
import '../../data/models/user_model.dart';

// ════════════════════════════════════════
// Estado de autenticación
// ════════════════════════════════════════
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

// ════════════════════════════════════════
// Notifier (lógica de negocio)
// ════════════════════════════════════════
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRemoteDatasource _authDatasource;
  final LocalStorage _localStorage;

  AuthNotifier(this._authDatasource, this._localStorage)
    : super(const AuthState()) {
    // Al crear, verificar si hay sesión guardada (TinyDB equivalente)
    _checkSavedSession();
  }

  /// Verificar si hay sesión guardada en SharedPreferences.
  /// Equivalente a Screen1.Initialize → TinyDB.GetValue("isLoggedIn")
  void _checkSavedSession() {
    if (_localStorage.isLoggedIn) {
      state = AuthState(
        status: AuthStatus.authenticated,
        user: UserModel(
          usuario: _localStorage.usuario,
          cargo: _localStorage.cargo,
        ),
      );
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// Iniciar sesión.
  /// Equivalente a:
  ///   Botón1.Click → Web1.PostText({"password": passwordBox.Text})
  ///   Web1.GotText → if responseCode == 200 → TinyDB.StoreValue → open Screen2
  Future<void> login(String password) async {
    // Mostrar loading (equivalente a progress.Visible = true)
    state = state.copyWith(status: AuthStatus.loading);

    try {
      // Llamar al backend
      final user = await _authDatasource.login(password);

      // Guardar en SharedPreferences (equivalente a TinyDB.StoreValue)
      await _localStorage.saveSession(usuario: user.usuario, cargo: user.cargo);

      // Éxito
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      // Error (equivalente a Notifier.ShowAlert)
      state = AuthState(status: AuthStatus.error, errorMessage: e.toString());
    }
  }

  /// Cerrar sesión.
  /// Equivalente a: TinyDB.ClearAll → close Screen → open Screen1
  Future<void> logout() async {
    await _localStorage.clearSession();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

// ════════════════════════════════════════
// Providers de Riverpod
// ════════════════════════════════════════

/// Provider del ApiClient (singleton)
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

/// Provider del cliente para API local de impresion (singleton)
final localApiClientProvider = Provider<LocalApiClient>(
  (ref) => LocalApiClient(ref.read(localStorageProvider)),
);

/// Provider del LocalStorage (singleton)
final localStorageProvider = Provider<LocalStorage>((ref) => LocalStorage());

/// Provider del datasource de auth
final authDatasourceProvider = Provider<AuthRemoteDatasource>((ref) {
  return AuthRemoteDatasource(ref.read(apiClientProvider));
});

/// Provider principal de autenticación
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.read(authDatasourceProvider),
    ref.read(localStorageProvider),
  );
});
