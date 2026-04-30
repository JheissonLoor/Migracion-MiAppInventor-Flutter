/// ============================================================================
/// SISTEMA DE ERRORES - CoolImport S.A.C.
/// ============================================================================
/// Errores tipados para manejar cada situación de forma limpia.
/// En MIT App Inventor todo se manejaba con Notifier.ShowAlert.
/// Aquí cada error tiene su tipo, mensaje y acción recomendada.
/// ============================================================================

/// Error base abstracto
abstract class Failure {
  final String message;
  final String? actionMessage; // Mensaje de acción para el operario
  const Failure(this.message, {this.actionMessage});
}

/// Error de red (sin WiFi, sin internet)
class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'Sin conexión a internet'])
      : super(
          message,
          actionMessage: 'Verifica tu conexión WiFi e intenta de nuevo.',
        );
}

/// Error del servidor (PythonAnywhere caído, 500, etc.)
class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure(String message, {this.statusCode})
      : super(
          message,
          actionMessage: 'El servidor no responde. Intenta en unos minutos.',
        );
}

/// Error de autenticación (contraseña incorrecta)
class AuthFailure extends Failure {
  const AuthFailure([String message = 'Contraseña incorrecta'])
      : super(
          message,
          actionMessage: 'Verifique su contraseña o contacte a PCP.',
        );
}

/// Error de datos (formato QR inválido, campo vacío, etc.)
class DataFailure extends Failure {
  const DataFailure(String message)
      : super(
          message,
          actionMessage: 'Verifica los datos ingresados.',
        );
}

/// Error de impresora (API local no disponible)
class PrinterFailure extends Failure {
  const PrinterFailure([
    String message = 'No se puede conectar a la impresora',
  ]) : super(
          message,
          actionMessage: 'Verifica que la PC de impresión esté encendida '
              'y conectada a la red.',
        );
}

/// Error de elemento no encontrado (PCP no existe, etc.)
class NotFoundFailure extends Failure {
  const NotFoundFailure(String message)
      : super(
          message,
          actionMessage: 'El código escaneado no existe en el sistema.',
        );
}

/// Error de operación restringida (movimiento bloqueado)
class RestrictedFailure extends Failure {
  const RestrictedFailure(String message)
      : super(
          message,
          actionMessage: 'Esta operación está restringida. Contacte a PCP.',
        );
}

/// Error de cache local
class CacheFailure extends Failure {
  const CacheFailure([String message = 'Error de almacenamiento local'])
      : super(message);
}
