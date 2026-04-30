import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../providers/agregar_proveedor_provider.dart';
import '../providers/cambio_almacen_provider.dart';
import '../providers/cambio_ubicacion_provider.dart';
import '../providers/contenedor_provider.dart';
import '../providers/engomado_provider.dart';
import '../providers/gestion_stock_telas_provider.dart';
import '../providers/impresion_etiqueta_provider.dart';
import '../providers/ingreso_telas_provider.dart';
import '../providers/reingreso_provider.dart';
import '../providers/salida_almacen_provider.dart';
import '../providers/telares_provider.dart';
import '../providers/urdido_provider.dart';

/// Ejecuta sincronizacion de colas al iniciar app, al volver a foreground
/// y en ciclos periodicos mientras la app este abierta.
class QueueSyncBootstrap extends ConsumerStatefulWidget {
  final Widget child;

  const QueueSyncBootstrap({super.key, required this.child});

  @override
  ConsumerState<QueueSyncBootstrap> createState() => _QueueSyncBootstrapState();
}

class _QueueSyncBootstrapState extends ConsumerState<QueueSyncBootstrap>
    with WidgetsBindingObserver {
  Timer? _timer;
  StreamSubscription<dynamic>? _connectivitySubscription;
  final Connectivity _connectivity = Connectivity();
  bool _syncRunning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _trySyncQueues();
      _timer = Timer.periodic(const Duration(seconds: 45), (_) {
        _trySyncQueues();
      });

      _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
        result,
      ) {
        if (_hasNetwork(result)) {
          _trySyncQueues();
        }
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _trySyncQueues();
    }
  }

  bool _hasNetwork(dynamic result) {
    if (result is ConnectivityResult) {
      return result != ConnectivityResult.none;
    }
    if (result is List<ConnectivityResult>) {
      return result.any((item) => item != ConnectivityResult.none);
    }
    return true;
  }

  Future<void> _trySyncQueues() async {
    if (!mounted || _syncRunning) return;

    final authState = ref.read(authProvider);
    final isAuthenticated = authState.status == AuthStatus.authenticated;
    if (!isAuthenticated) {
      return;
    }

    _syncRunning = true;
    try {
      // Ordenado para priorizar movimientos criticos de inventario.
      await ref
          .read(salidaAlmacenProvider.notifier)
          .procesarColaPendiente(silent: true);
      await ref
          .read(reingresoProvider.notifier)
          .procesarColaPendiente(silent: true);
      await ref
          .read(urdidoProvider.notifier)
          .procesarColaPendiente(silent: true);
      await ref
          .read(engomadoProvider.notifier)
          .procesarColaPendiente(silent: true);
      await ref
          .read(telaresProvider.notifier)
          .procesarColaPendiente(silent: true);
      await ref
          .read(cambioAlmacenProvider.notifier)
          .procesarColaPendiente(silent: true);
      await ref
          .read(cambioUbicacionProvider.notifier)
          .procesarColaPendiente(silent: true);
      await ref
          .read(agregarProveedorProvider.notifier)
          .procesarColaPendiente(silent: true);
      await ref
          .read(ingresoTelasProvider.notifier)
          .procesarColaPendiente(silent: true);
      await ref
          .read(contenedorProvider.notifier)
          .procesarColaPendiente(silent: true);
      await ref
          .read(gestionStockTelasProvider.notifier)
          .procesarColaDespacho(silent: true);
      await ref
          .read(impresionEtiquetaProvider.notifier)
          .procesarColaPendiente(silent: true);
    } catch (_) {
      // Silencioso: la cola se reintentara en el siguiente ciclo.
    } finally {
      _syncRunning = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        _trySyncQueues();
      }
    });

    return widget.child;
  }
}
