/// ============================================================================
/// CONFIGURACIÓN DE ENTORNO - CoolImport S.A.C.
/// ============================================================================
/// Maneja las URLs y configuraciones para DEV y PROD.
/// En PRODUCCIÓN apunta a PythonAnywhere.
/// En DESARROLLO apunta a localhost (para testing).
/// ============================================================================

enum AppEnvironment { dev, prod }

class EnvironmentConfig {
  // ──────────────────────────────────────────
  // Cambiar aquí para alternar entre entornos
  // ──────────────────────────────────────────
  static const AppEnvironment currentEnv = AppEnvironment.prod;

  // ════════════════════════════════════════════
  // URLs del Backend Principal (PythonAnywhere)
  // ════════════════════════════════════════════
  static String get baseUrl {
    switch (currentEnv) {
      case AppEnvironment.dev:
        return 'http://10.0.2.2:5000'; // Emulador Android → localhost
      case AppEnvironment.prod:
        return 'https://coolimport.pythonanywhere.com';
    }
  }

  // ════════════════════════════════════════════
  // URL de la API Local (Impresión Zebra/Epson)
  // ════════════════════════════════════════════
  // Esta IP es FIJA en la red local de la planta.
  // Solo accesible desde la red WiFi de CoolImport.
  static const String localApiUrl = 'http://192.168.1.34:5001';
  static const List<String> localApiFallbackUrls = [
    'http://192.168.1.34:5001',
    'http://192.168.1.250:5001',
  ];

  // Endpoint local historico para modulo Telares (MIT App Inventor).
  static const String telaresLocalApiUrl = 'http://192.168.1.43:5000';
  static const List<String> telaresLocalApiFallbackUrls = [
    'http://192.168.1.43:5000',
    'http://192.168.1.34:5000',
  ];

  // ════════════════════════════════════════════
  // Timeouts (en segundos)
  // ════════════════════════════════════════════
  // Google Sheets puede tardar 5-10s en responder,
  // por eso el timeout del backend principal es alto.
  static const int connectTimeout = 15;
  static const int receiveTimeout = 30;

  // Timeout menor para API local (es red local, debe ser rápido)
  static const int localConnectTimeout = 5;
  static const int localReceiveTimeout = 10;

  // ════════════════════════════════════════════
  // Configuración de reintentos
  // ════════════════════════════════════════════
  static const int maxRetries = 2;
  static const int retryDelayMs = 1000;

  // ════════════════════════════════════════════
  // Feature flags
  // ════════════════════════════════════════════
  static bool get enableLogging => currentEnv == AppEnvironment.dev;
  static bool get enableOfflineCache => true;

  // Credencial de Google Sheets para el modulo Agregar Proveedor.
  // Para builds release, se recomienda pasar la credencial por
  // --dart-define=GOOGLE_SHEETS_SA_B64=... y mantener este flag en false.
  static const bool allowEmbeddedSheetsCredentials = bool.fromEnvironment(
    'ALLOW_EMBEDDED_SHEETS_CREDENTIALS',
    defaultValue: false,
  );
  static const String googleSheetsServiceAccountAsset =
      'assets/config/pcp_service_account.json';
}
