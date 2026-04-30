import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../providers/agregar_proveedor_provider.dart';
import '../../providers/cambio_almacen_provider.dart';
import '../../providers/cambio_ubicacion_provider.dart';
import '../../providers/contenedor_provider.dart';
import '../../providers/engomado_provider.dart';
import '../../providers/gestion_stock_telas_provider.dart';
import '../../providers/impresion_etiqueta_provider.dart';
import '../../providers/ingreso_telas_provider.dart';
import '../../providers/reingreso_provider.dart';
import '../../providers/salida_almacen_provider.dart';
import '../../providers/telares_provider.dart';
import '../../providers/urdido_provider.dart';
import '../../widgets/enterprise_backdrop.dart';

class TelemetriaOperativaScreen extends ConsumerStatefulWidget {
  const TelemetriaOperativaScreen({super.key});

  @override
  ConsumerState<TelemetriaOperativaScreen> createState() =>
      _TelemetriaOperativaScreenState();
}

class _TelemetriaOperativaScreenState
    extends ConsumerState<TelemetriaOperativaScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryController;
  late final Animation<double> _fadeAnimation;

  bool _syncing = false;
  String? _statusMessage;
  bool _statusIsError = false;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final salida = ref.watch(salidaAlmacenProvider);
    final reingreso = ref.watch(reingresoProvider);
    final urdido = ref.watch(urdidoProvider);
    final engomado = ref.watch(engomadoProvider);
    final telares = ref.watch(telaresProvider);
    final cambioAlmacen = ref.watch(cambioAlmacenProvider);
    final cambioUbicacion = ref.watch(cambioUbicacionProvider);
    final agregarProveedor = ref.watch(agregarProveedorProvider);
    final ingresoTelas = ref.watch(ingresoTelasProvider);
    final contenedor = ref.watch(contenedorProvider);
    final despacho = ref.watch(gestionStockTelasProvider);
    final etiqueta = ref.watch(impresionEtiquetaProvider);

    final modules = <_ModuleTelemetry>[
      _ModuleTelemetry(
        moduleName: 'Salida Almacen',
        pending: salida.pendingQueue,
        enqueued: salida.telemetry.enqueuedTotal,
        processed: salida.telemetry.processedTotal,
        failed: salida.telemetry.failedAttemptsTotal,
        retries: salida.telemetry.retryAttemptsTotal,
        lastError: salida.telemetry.lastError,
      ),
      _ModuleTelemetry(
        moduleName: 'Reingreso',
        pending: reingreso.pendingQueue,
        enqueued: reingreso.telemetry.enqueuedTotal,
        processed: reingreso.telemetry.processedTotal,
        failed: reingreso.telemetry.failedAttemptsTotal,
        retries: reingreso.telemetry.retryAttemptsTotal,
        lastError: reingreso.telemetry.lastError,
      ),
      _ModuleTelemetry(
        moduleName: 'Urdido',
        pending: urdido.pendingQueue,
        enqueued: urdido.telemetry.enqueuedTotal,
        processed: urdido.telemetry.processedTotal,
        failed: urdido.telemetry.failedAttemptsTotal,
        retries: urdido.telemetry.retryAttemptsTotal,
        lastError: urdido.telemetry.lastError,
      ),
      _ModuleTelemetry(
        moduleName: 'Engomado',
        pending: engomado.pendingQueue,
        enqueued: engomado.telemetry.enqueuedTotal,
        processed: engomado.telemetry.processedTotal,
        failed: engomado.telemetry.failedAttemptsTotal,
        retries: engomado.telemetry.retryAttemptsTotal,
        lastError: engomado.telemetry.lastError,
      ),
      _ModuleTelemetry(
        moduleName: 'Telares',
        pending: telares.pendingQueue,
        enqueued: telares.telemetry.enqueuedTotal,
        processed: telares.telemetry.processedTotal,
        failed: telares.telemetry.failedAttemptsTotal,
        retries: telares.telemetry.retryAttemptsTotal,
        lastError: telares.telemetry.lastError,
      ),
      _ModuleTelemetry(
        moduleName: 'Cambio Almacen',
        pending: cambioAlmacen.pendingQueue,
        enqueued: cambioAlmacen.telemetry.enqueuedTotal,
        processed: cambioAlmacen.telemetry.processedTotal,
        failed: cambioAlmacen.telemetry.failedAttemptsTotal,
        retries: cambioAlmacen.telemetry.retryAttemptsTotal,
        lastError: cambioAlmacen.telemetry.lastError,
      ),
      _ModuleTelemetry(
        moduleName: 'Cambio Ubicacion',
        pending: cambioUbicacion.pendingQueue,
        enqueued: cambioUbicacion.telemetry.enqueuedTotal,
        processed: cambioUbicacion.telemetry.processedTotal,
        failed: cambioUbicacion.telemetry.failedAttemptsTotal,
        retries: cambioUbicacion.telemetry.retryAttemptsTotal,
        lastError: cambioUbicacion.telemetry.lastError,
      ),
      _ModuleTelemetry(
        moduleName: 'Agregar Proveedor',
        pending: agregarProveedor.pendingQueue,
        enqueued: agregarProveedor.telemetry.enqueuedTotal,
        processed: agregarProveedor.telemetry.processedTotal,
        failed: agregarProveedor.telemetry.failedAttemptsTotal,
        retries: agregarProveedor.telemetry.retryAttemptsTotal,
        lastError: agregarProveedor.telemetry.lastError,
      ),
      _ModuleTelemetry(
        moduleName: 'Ingreso Telas',
        pending: ingresoTelas.pendingQueue,
        enqueued: ingresoTelas.telemetry.enqueuedTotal,
        processed: ingresoTelas.telemetry.processedTotal,
        failed: ingresoTelas.telemetry.failedAttemptsTotal,
        retries: ingresoTelas.telemetry.retryAttemptsTotal,
        lastError: ingresoTelas.telemetry.lastError,
      ),
      _ModuleTelemetry(
        moduleName: 'Contenedor',
        pending: contenedor.pendingQueue,
        enqueued: contenedor.telemetry.enqueuedTotal,
        processed: contenedor.telemetry.processedTotal,
        failed: contenedor.telemetry.failedAttemptsTotal,
        retries: contenedor.telemetry.retryAttemptsTotal,
        lastError: contenedor.telemetry.lastError,
      ),
      _ModuleTelemetry(
        moduleName: 'Despacho Telas',
        pending: despacho.pendingDespachos,
        enqueued: despacho.telemetry.enqueuedTotal,
        processed: despacho.telemetry.processedTotal,
        failed: despacho.telemetry.failedAttemptsTotal,
        retries: despacho.telemetry.retryAttemptsTotal,
        lastError: despacho.telemetry.lastError,
      ),
      _ModuleTelemetry(
        moduleName: 'Impresion Etiqueta',
        pending: etiqueta.queue.length,
        enqueued: etiqueta.telemetry.enqueuedTotal,
        processed: etiqueta.telemetry.processedTotal,
        failed: etiqueta.telemetry.failedAttemptsTotal,
        retries: etiqueta.telemetry.retryAttemptsTotal,
        lastError: etiqueta.telemetry.lastError,
      ),
    ];

    final totalPending = modules.fold<int>(
      0,
      (sum, item) => sum + item.pending,
    );
    final totalEnqueued = modules.fold<int>(
      0,
      (sum, item) => sum + item.enqueued,
    );
    final totalProcessed = modules.fold<int>(
      0,
      (sum, item) => sum + item.processed,
    );
    final totalFailed = modules.fold<int>(0, (sum, item) => sum + item.failed);
    final totalRetries = modules.fold<int>(
      0,
      (sum, item) => sum + item.retries,
    );

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: EnterpriseBackdrop()),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 10),
                    if (_statusMessage?.trim().isNotEmpty == true)
                      _buildStatusBanner(
                        text: _statusMessage!,
                        isError: _statusIsError,
                      ),
                    if (_statusMessage?.trim().isNotEmpty == true)
                      const SizedBox(height: 10),
                    _buildKpiCard(
                      totalPending: totalPending,
                      totalEnqueued: totalEnqueued,
                      totalProcessed: totalProcessed,
                      totalFailed: totalFailed,
                      totalRetries: totalRetries,
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.separated(
                        itemCount: modules.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder:
                            (context, index) =>
                                _buildModuleCard(modules[index]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _syncing ? null : _syncAllQueues,
        icon:
            _syncing
                ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                : const Icon(Icons.sync_rounded),
        label: Text(_syncing ? 'Sincronizando...' : 'Sincronizar colas'),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            side: const BorderSide(color: CorporateTokens.borderSoft),
          ),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: CorporateTokens.navy900,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Telemetria Operativa',
                style: TextStyle(
                  color: CorporateTokens.navy900,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Monitoreo de colas y reintentos en planta',
                style: TextStyle(color: CorporateTokens.slate500, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBanner({required String text, required bool isError}) {
    final bgColor = isError ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7);
    final borderColor =
        isError ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC);
    final iconColor =
        isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
            color: iconColor,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: CorporateTokens.navy900,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required int totalPending,
    required int totalEnqueued,
    required int totalProcessed,
    required int totalFailed,
    required int totalRetries,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CorporateTokens.borderSoft),
        boxShadow: CorporateTokens.cardShadow,
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _kpiChip(
            'Pendientes',
            totalPending.toString(),
            const Color(0xFF0EA5E9),
          ),
          _kpiChip(
            'Encolados',
            totalEnqueued.toString(),
            const Color(0xFF2563EB),
          ),
          _kpiChip(
            'Procesados',
            totalProcessed.toString(),
            const Color(0xFF16A34A),
          ),
          _kpiChip('Fallos', totalFailed.toString(), const Color(0xFFDC2626)),
          _kpiChip(
            'Reintentos',
            totalRetries.toString(),
            const Color(0xFFF59E0B),
          ),
        ],
      ),
    );
  }

  Widget _kpiChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildModuleCard(_ModuleTelemetry module) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CorporateTokens.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            module.moduleName,
            style: const TextStyle(
              color: CorporateTokens.navy900,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _miniChip('Pend', module.pending),
              _miniChip('Encolados', module.enqueued),
              _miniChip('Procesados', module.processed),
              _miniChip('Fallos', module.failed),
              _miniChip('Reintentos', module.retries),
            ],
          ),
          if (module.lastError.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Ultimo error: ${module.lastError}',
              style: const TextStyle(
                color: Color(0xFFDC2626),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _miniChip(String label, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: CorporateTokens.surfaceBottom,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: CorporateTokens.slate700,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _syncAllQueues() async {
    if (_syncing) return;
    setState(() {
      _syncing = true;
      _statusMessage = null;
      _statusIsError = false;
    });

    try {
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

      setState(() {
        _statusMessage = 'Sincronizacion ejecutada. Revise KPIs y pendientes.';
        _statusIsError = false;
      });
    } catch (_) {
      setState(() {
        _statusMessage = 'No se pudo sincronizar todas las colas.';
        _statusIsError = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _syncing = false;
        });
      }
    }
  }
}

class _ModuleTelemetry {
  final String moduleName;
  final int pending;
  final int enqueued;
  final int processed;
  final int failed;
  final int retries;
  final String lastError;

  const _ModuleTelemetry({
    required this.moduleName,
    required this.pending,
    required this.enqueued,
    required this.processed,
    required this.failed,
    required this.retries,
    required this.lastError,
  });
}
