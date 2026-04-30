/// ============================================================================
/// CONSTANTES DE LA APLICACIÓN - CoolImport S.A.C.
/// ============================================================================
/// Define roles, formatos QR, y valores por defecto usados en todo el sistema.
/// ============================================================================

class AppConstants {
  // ════════════════════════════════════════════
  // ROLES DE USUARIO
  // ════════════════════════════════════════════
  // Estos roles vienen de la tabla 'usuarios' en Supabase.
  // El campo 'cargo' determina a qué menú se redirige.
  static const String rolAdmin = 'ADMINISTRADOR';
  static const String rolPCP = 'PCP';
  static const String rolOperario = 'OPERARIO';
  static const String rolAlmacenero = 'ALMACENERO';
  static const String rolRevisor = 'REVISOR';
  static const String rolUrdidor = 'URDIDOR';
  static const String rolEngomador = 'ENGOMADOR';

  // Roles que tienen acceso al menú de administración
  static const List<String> rolesAdmin = [rolAdmin, rolPCP];

  // Roles que ven el menú de producción
  static const List<String> rolesProduccion = [
    rolUrdidor,
    rolEngomador,
    rolOperario,
  ];

  // ════════════════════════════════════════════
  // FORMATOS DE QR
  // ════════════════════════════════════════════
  // El sistema maneja 4 formatos de QR diferentes:
  //
  // HILOS (14 campos):
  // CodigoPCP, CodigoKardex, Material, Titulo, Color, Lote, Proveedor,
  // Servicio, Guia, NumCajas, TotalBobinas, PesoBrutoTotal, PesoNetoTotal, Ubicacion
  //
  // HILOS EXTENDIDO (16 campos):
  // Los 14 anteriores + Almacen + FechaIngreso
  //
  // TELA CRUDA (8 campos):
  // CodigoTela, NumCorte, Telar, OP, Articulo, Metraje, Peso, Revisador
  //
  // LEGACY (6 campos):
  // Codigo, Articulo, Metros, Peso, Ubicacion, Fecha
  static const int qrCamposHilos = 14;
  static const int qrCamposHilosExtendido = 16;
  static const int qrCamposTelaCruda = 8;
  static const int qrCamposLegacy = 6;

  // ════════════════════════════════════════════
  // ALMACENES VÁLIDOS
  // ════════════════════════════════════════════
  static const List<String> almacenes = [
    'PLANTA 1',
    'PLANTA 2',
    'PLANTA 3',
    'ALMACEN CENTRAL',
  ];

  // ════════════════════════════════════════════
  // ESTADOS DE TELA
  // ════════════════════════════════════════════
  static const String estadoEnStock = 'EN STOCK';
  static const String estadoDespachado = 'DESPACHADO';
  static const String disponibleSi = 'SÍ';

  // ════════════════════════════════════════════
  // KEYS PARA ALMACENAMIENTO LOCAL (TinyDB equiv.)
  // ════════════════════════════════════════════
  static const String keyUsuario = 'usuario_nombre';
  static const String keyCargo = 'usuario_cargo';
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyLastLogin = 'last_login';
  static const String keyPrintQueue = 'print_queue_v1';
  static const String keyPrintTelemetry = 'print_telemetry_v1';
  static const String keyDespachoQueue = 'despacho_queue_v1';
  static const String keyDespachoTelemetry = 'despacho_telemetry_v1';
  static const String keySalidaQueue = 'salida_queue_v1';
  static const String keySalidaTelemetry = 'salida_telemetry_v1';
  static const String keySalidaCatalogosVenta = 'salida_catalogos_venta_v1';
  static const String keySalidaCatalogosCliente = 'salida_catalogos_cliente_v1';
  static const String keyReingresoQueue = 'reingreso_queue_v1';
  static const String keyReingresoTelemetry = 'reingreso_telemetry_v1';
  static const String keyUrdidoQueue = 'urdido_queue_v1';
  static const String keyUrdidoTelemetry = 'urdido_telemetry_v1';
  static const String keyEngomadoQueue = 'engomado_queue_v1';
  static const String keyEngomadoTelemetry = 'engomado_telemetry_v1';
  static const String keyTelaresQueue = 'telares_queue_v1';
  static const String keyTelaresTelemetry = 'telares_telemetry_v1';
  static const String keyCambioAlmacenQueue = 'cambio_almacen_queue_v1';
  static const String keyCambioAlmacenTelemetry = 'cambio_almacen_telemetry_v1';
  static const String keyCambioUbicacionQueue = 'cambio_ubicacion_queue_v1';
  static const String keyCambioUbicacionTelemetry =
      'cambio_ubicacion_telemetry_v1';
  static const String keyAgregarProveedorQueue = 'agregar_proveedor_queue_v1';
  static const String keyAgregarProveedorTelemetry =
      'agregar_proveedor_telemetry_v1';
  static const String keyIngresoTelasQueue = 'ingreso_telas_queue_v1';
  static const String keyIngresoTelasTelemetry = 'ingreso_telas_telemetry_v1';
  static const String keyContenedorQueue = 'contenedor_queue_v1';
  static const String keyContenedorTelemetry = 'contenedor_telemetry_v1';
  static const String keyReleasePilotChecklist = 'release_pilot_checklist_v1';
  static const String keyLocalApiUrl = 'local_api_url_v1';
  static const String keyTelaresLocalApiUrl = 'telares_local_api_url_v1';

  // ════════════════════════════════════════════
  // TIPOS DE PROCESO (Engomado)
  // ════════════════════════════════════════════
  static const String procesoEngomado = 'Engomado';
  static const String procesoEnsimaje = 'Ensimaje';
  static const String procesoVolteado = 'Volteado';
}
