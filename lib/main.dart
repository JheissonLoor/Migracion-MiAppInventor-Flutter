// ============================================================================
// MAIN - CoolImport S.A.C. App Flutter
// ============================================================================
// Entry point de la aplicacion.
// Inicializa almacenamiento local, providers, tema y rutas.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_constants.dart';
import 'core/storage/local_storage.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/screens/almacen/consulta_almacen_screen.dart';
import 'presentation/screens/almacen/cambio_almacen_screen.dart';
import 'presentation/screens/almacen/cambio_ubicacion_screen.dart';
import 'presentation/screens/almacen/historial_screen.dart';
import 'presentation/screens/almacen/impresion_etiqueta_screen.dart';
import 'presentation/screens/almacen/inventario_cero_screen.dart';
import 'presentation/screens/almacen/reingreso_screen.dart';
import 'presentation/screens/almacen/salida_almacen_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/home/admin_home_screen.dart';
import 'presentation/screens/home/operario_home_screen.dart';
import 'presentation/screens/produccion/engomado_screen.dart';
import 'presentation/screens/produccion/historial_admin_screen.dart';
import 'presentation/screens/produccion/historial_telar_screen.dart';
import 'presentation/screens/produccion/historial_tela_cruda_screen.dart';
import 'presentation/screens/produccion/historial_urdido_screen.dart';
import 'presentation/screens/produccion/ingreso_telar_screen.dart';
import 'presentation/screens/produccion/telares_screen.dart';
import 'presentation/screens/produccion/urdido_screen.dart';
import 'presentation/screens/stock/consulta_stock_screen.dart';
import 'presentation/screens/system/admin_users_screen.dart';
import 'presentation/screens/system/agregar_proveedor_screen.dart';
import 'presentation/screens/system/editar_proveedor_screen.dart';
import 'presentation/screens/system/local_api_settings_screen.dart';
import 'presentation/screens/system/migration_status_screen.dart';
import 'presentation/screens/system/release_readiness_screen.dart';
import 'presentation/screens/system/telemetria_operativa_screen.dart';
import 'presentation/screens/telas/contenedor_screen.dart';
import 'presentation/screens/telas/gestion_stock_telas_screen.dart';
import 'presentation/screens/telas/ingreso_telas_screen.dart';
import 'presentation/widgets/auth_role_guard.dart';
import 'presentation/widgets/queue_sync_bootstrap.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  final localStorage = LocalStorage();
  await localStorage.init();

  runApp(
    ProviderScope(
      overrides: [localStorageProvider.overrideWithValue(localStorage)],
      child: const QueueSyncBootstrap(child: CoolImportApp()),
    ),
  );
}

class CoolImportApp extends ConsumerWidget {
  const CoolImportApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget securedRoute({
      required String moduleName,
      required Widget child,
      List<String> allowedRoles = const [],
      List<String> extraAllowedRoles = const [],
    }) {
      return AuthRoleGuard(
        moduleName: moduleName,
        allowedRoles: allowedRoles,
        extraAllowedRoles: extraAllowedRoles,
        child: child,
      );
    }

    return MaterialApp(
      title: 'CoolImport PCP',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/login',
      routes: {
        // Autenticacion
        '/login': (context) => const LoginScreen(),

        // Menus principales
        '/operario_home':
            (context) => securedRoute(
              moduleName: 'Inicio Operativo',
              child: const OperarioHomeScreen(),
            ),
        '/admin_home':
            (context) => securedRoute(
              moduleName: 'Panel Administrativo',
              allowedRoles: AppConstants.rolesAdmin,
              extraAllowedRoles: const ['ADMINISTRADORS'],
              child: const AdminHomeScreen(),
            ),

        // Modulos migrados
        '/consulta_almacen':
            (context) => securedRoute(
              moduleName: 'Consulta Almacen',
              child: const ConsultaAlmacenScreen(),
            ),
        '/historial':
            (context) => securedRoute(
              moduleName: 'Historial',
              child: const HistorialScreen(),
            ),
        '/salida_almacen':
            (context) => securedRoute(
              moduleName: 'Salida de Almacen',
              child: const SalidaAlmacenScreen(),
            ),
        '/reingreso':
            (context) => securedRoute(
              moduleName: 'Reingreso',
              child: const ReingresoScreen(),
            ),
        '/impresion_etiqueta':
            (context) => securedRoute(
              moduleName: 'Impresion de Etiqueta',
              child: const ImpresionEtiquetaScreen(),
            ),
        '/urdido':
            (context) =>
                securedRoute(moduleName: 'Urdido', child: const UrdidoScreen()),
        '/consulta_stock':
            (context) => securedRoute(
              moduleName: 'Consulta Stock',
              child: const ConsultaStockScreen(),
            ),
        '/inventario_cero':
            (context) => securedRoute(
              moduleName: 'Inventario Cero',
              child: const InventarioCeroScreen(),
            ),
        '/gestion_stock_telas':
            (context) => securedRoute(
              moduleName: 'Gestion Stock Telas',
              child: const GestionStockTelasScreen(),
            ),
        '/engomado':
            (context) => securedRoute(
              moduleName: 'Engomado',
              child: const EngomadoScreen(),
            ),
        '/telares':
            (context) => securedRoute(
              moduleName: 'Telares',
              child: const TelaresScreen(),
            ),
        '/historial_urdido':
            (context) => securedRoute(
              moduleName: 'Historial Urdido',
              child: const HistorialUrdidoScreen(),
            ),
        '/historial_telar':
            (context) => securedRoute(
              moduleName: 'Historial Telar',
              child: const HistorialTelarScreen(),
            ),
        '/historial_tela_cruda':
            (context) => securedRoute(
              moduleName: 'Historial Tela Cruda',
              child: const HistorialTelaCrudaScreen(),
            ),
        '/historial_admin':
            (context) => securedRoute(
              moduleName: 'Historial Administrativo',
              allowedRoles: AppConstants.rolesAdmin,
              extraAllowedRoles: const ['ADMINISTRADORS'],
              child: const HistorialAdminScreen(),
            ),
        '/ingreso_telar':
            (context) => securedRoute(
              moduleName: 'Ingreso Telar',
              child: const IngresoTelarScreen(),
            ),

        // Modulos legacy administrativos / telas
        '/cambio_almacen':
            (context) => securedRoute(
              moduleName: 'Cambio de Almacen (Telar)',
              child: const CambioAlmacenScreen(),
            ),
        '/cambio_ubicacion':
            (context) => securedRoute(
              moduleName: 'Cambio de Ubicacion (Hilos)',
              child: const CambioUbicacionScreen(),
            ),
        '/agregar_proveedor':
            (context) => securedRoute(
              moduleName: 'Agregar Proveedor',
              child: const AgregarProveedorScreen(),
            ),
        '/editar_proveedor':
            (context) => securedRoute(
              moduleName: 'Editar Proveedor',
              child: const EditarProveedorScreen(),
            ),
        '/ingreso_telas':
            (context) => securedRoute(
              moduleName: 'Ingreso de Telas',
              child: const IngresoTelasScreen(),
            ),
        '/contenedor':
            (context) => securedRoute(
              moduleName: 'Ingreso Contenedor',
              child: const ContenedorScreen(),
            ),

        // Sistema
        '/admin_users':
            (context) => securedRoute(
              moduleName: 'Administrar Usuarios',
              allowedRoles: AppConstants.rolesAdmin,
              extraAllowedRoles: const ['ADMINISTRADORS'],
              child: const AdminUsersScreen(),
            ),
        '/telemetria_operativa':
            (context) => securedRoute(
              moduleName: 'Telemetria Operativa',
              allowedRoles: AppConstants.rolesAdmin,
              extraAllowedRoles: const ['ADMINISTRADORS'],
              child: const TelemetriaOperativaScreen(),
            ),
        '/estado_migracion':
            (context) => securedRoute(
              moduleName: 'Estado de Migracion',
              allowedRoles: AppConstants.rolesAdmin,
              extraAllowedRoles: const ['ADMINISTRADORS'],
              child: const MigrationStatusScreen(),
            ),
        '/release_readiness':
            (context) => securedRoute(
              moduleName: 'Release Readiness',
              allowedRoles: AppConstants.rolesAdmin,
              extraAllowedRoles: const ['ADMINISTRADORS'],
              child: const ReleaseReadinessScreen(),
            ),
        '/local_api_settings':
            (context) => securedRoute(
              moduleName: 'Configuracion API local',
              allowedRoles: AppConstants.rolesAdmin,
              extraAllowedRoles: const ['ADMINISTRADORS'],
              child: const LocalApiSettingsScreen(),
            ),
      },
    );
  }
}
