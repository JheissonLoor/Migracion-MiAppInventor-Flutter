import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../providers/local_api_health_provider.dart';
import '../../providers/reingreso_provider.dart';
import '../../providers/release_readiness_provider.dart';
import '../../providers/salida_almacen_provider.dart';
import '../../providers/telares_provider.dart';
import '../../providers/urdido_provider.dart';
import '../../widgets/enterprise_backdrop.dart';

class ReleaseReadinessScreen extends ConsumerStatefulWidget {
  const ReleaseReadinessScreen({super.key});

  @override
  ConsumerState<ReleaseReadinessScreen> createState() =>
      _ReleaseReadinessScreenState();
}

class _ReleaseReadinessScreenState extends ConsumerState<ReleaseReadinessScreen>
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
    final checklist = ref.watch(releaseReadinessProvider);
    final checklistNotifier = ref.read(releaseReadinessProvider.notifier);
    final localApi = ref.watch(localApiHealthProvider);

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
    final gestionTelas = ref.watch(gestionStockTelasProvider);
    final impresion = ref.watch(impresionEtiquetaProvider);

    final modules = <_QueueMetric>[
      _QueueMetric(
        module: 'Salida',
        pending: salida.pendingQueue,
        lastError: salida.telemetry.lastError,
      ),
      _QueueMetric(
        module: 'Reingreso',
        pending: reingreso.pendingQueue,
        lastError: reingreso.telemetry.lastError,
      ),
      _QueueMetric(
        module: 'Urdido',
        pending: urdido.pendingQueue,
        lastError: urdido.telemetry.lastError,
      ),
      _QueueMetric(
        module: 'Engomado',
        pending: engomado.pendingQueue,
        lastError: engomado.telemetry.lastError,
      ),
      _QueueMetric(
        module: 'Telares',
        pending: telares.pendingQueue,
        lastError: telares.telemetry.lastError,
      ),
      _QueueMetric(
        module: 'Cambio Almacen',
        pending: cambioAlmacen.pendingQueue,
        lastError: cambioAlmacen.telemetry.lastError,
      ),
      _QueueMetric(
        module: 'Cambio Ubicacion',
        pending: cambioUbicacion.pendingQueue,
        lastError: cambioUbicacion.telemetry.lastError,
      ),
      _QueueMetric(
        module: 'Agregar Proveedor',
        pending: agregarProveedor.pendingQueue,
        lastError: agregarProveedor.telemetry.lastError,
      ),
      _QueueMetric(
        module: 'Ingreso Telas',
        pending: ingresoTelas.pendingQueue,
        lastError: ingresoTelas.telemetry.lastError,
      ),
      _QueueMetric(
        module: 'Contenedor',
        pending: contenedor.pendingQueue,
        lastError: contenedor.telemetry.lastError,
      ),
      _QueueMetric(
        module: 'Despacho Telas',
        pending: gestionTelas.pendingDespachos,
        lastError: gestionTelas.telemetry.lastError,
      ),
      _QueueMetric(
        module: 'Impresion',
        pending: impresion.queue.length,
        lastError: impresion.telemetry.lastError,
      ),
    ];

    final totalPending = modules.fold<int>(
      0,
      (sum, item) => sum + item.pending,
    );
    final modulesWithError =
        modules
            .where((item) => item.lastError.trim().isNotEmpty)
            .map((item) => item.module)
            .toList();
    final modulesWithPending =
        modules
            .where((item) => item.pending > 0)
            .map((item) => item.module)
            .toList();

    final gateApiLocal = localApi.available;
    final gateQueue = totalPending == 0;
    final gateErrors = modulesWithError.isEmpty;
    final gateChecklist = checklist.requiredForGoCompleted;

    final isGo = gateApiLocal && gateQueue && gateErrors && gateChecklist;
    final progress = checklist.completionPercent;

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
                    _buildDecisionCard(
                      isGo: isGo,
                      gateApiLocal: gateApiLocal,
                      gateQueue: gateQueue,
                      gateErrors: gateErrors,
                      gateChecklist: gateChecklist,
                      totalPending: totalPending,
                      progress: progress,
                    ),
                    const SizedBox(height: 10),
                    if (_statusMessage?.trim().isNotEmpty == true)
                      _buildStatusBanner(
                        text: _statusMessage!,
                        isError: _statusIsError,
                      ),
                    if (_statusMessage?.trim().isNotEmpty == true)
                      const SizedBox(height: 10),
                    _buildPrimaryActions(checklistNotifier),
                    const SizedBox(height: 8),
                    _buildSecondaryActions(
                      isGo: isGo,
                      gateApiLocal: gateApiLocal,
                      gateQueue: gateQueue,
                      gateErrors: gateErrors,
                      gateChecklist: gateChecklist,
                      totalPending: totalPending,
                      modulesWithPending: modulesWithPending,
                      modulesWithError: modulesWithError,
                      checklist: checklist,
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView(
                        children: [
                          _buildChecklistCard(checklist, checklistNotifier),
                          const SizedBox(height: 10),
                          _buildQueueHealthCard(modules),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
                'Release Readiness',
                style: TextStyle(
                  color: CorporateTokens.navy900,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Tablero go/no-go para piloto en planta',
                style: TextStyle(color: CorporateTokens.slate500, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDecisionCard({
    required bool isGo,
    required bool gateApiLocal,
    required bool gateQueue,
    required bool gateErrors,
    required bool gateChecklist,
    required int totalPending,
    required double progress,
  }) {
    final badgeBg = isGo ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2);
    final badgeColor = isGo ? const Color(0xFF15803D) : const Color(0xFFB91C1C);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CorporateTokens.borderSoft),
        boxShadow: CorporateTokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.28)),
                ),
                child: Text(
                  isGo ? 'GO PILOTO' : 'NO-GO',
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Checklist ${(progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: CorporateTokens.navy900,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _gateChip('API local', gateApiLocal),
              _gateChip('Colas en cero', gateQueue),
              _gateChip('Sin errores activos', gateErrors),
              _gateChip('Checklist requerido', gateChecklist),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Pendientes en cola: $totalPending',
            style: const TextStyle(
              color: CorporateTokens.slate700,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _gateChip(String label, bool ok) {
    final color = ok ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Text(
        '$label: ${ok ? 'OK' : 'Bloqueado'}',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildPrimaryActions(ReleaseReadinessNotifier checklistNotifier) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
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
            label: Text(_syncing ? 'Sincronizando...' : 'Sincronizar ahora'),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: _syncing ? null : checklistNotifier.markRequiredAsChecked,
          icon: const Icon(Icons.done_all_rounded),
          label: const Text('Completar req.'),
        ),
      ],
    );
  }

  Widget _buildSecondaryActions({
    required bool isGo,
    required bool gateApiLocal,
    required bool gateQueue,
    required bool gateErrors,
    required bool gateChecklist,
    required int totalPending,
    required List<String> modulesWithPending,
    required List<String> modulesWithError,
    required ReleaseReadinessState checklist,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed:
              () => Navigator.pushNamed(context, '/telemetria_operativa'),
          icon: const Icon(Icons.monitor_heart_rounded),
          label: const Text('Telemetria'),
        ),
        OutlinedButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/estado_migracion'),
          icon: const Icon(Icons.track_changes_rounded),
          label: const Text('Estado migracion'),
        ),
        OutlinedButton.icon(
          onPressed:
              () => _copyGoNoGoReport(
                isGo: isGo,
                gateApiLocal: gateApiLocal,
                gateQueue: gateQueue,
                gateErrors: gateErrors,
                gateChecklist: gateChecklist,
                totalPending: totalPending,
                modulesWithPending: modulesWithPending,
                modulesWithError: modulesWithError,
                checklist: checklist,
              ),
          icon: const Icon(Icons.copy_all_rounded),
          label: const Text('Copiar reporte'),
        ),
      ],
    );
  }

  Widget _buildChecklistCard(
    ReleaseReadinessState checklist,
    ReleaseReadinessNotifier checklistNotifier,
  ) {
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
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Checklist piloto',
                  style: TextStyle(
                    color: CorporateTokens.navy900,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: checklistNotifier.resetAll,
                child: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...checklist.items.map((item) {
            final checked = checklist.isChecked(item.id);
            return CheckboxListTile(
              value: checked,
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged:
                  (value) => checklistNotifier.toggle(item.id, value == true),
              title: Text(
                item.title,
                style: const TextStyle(
                  color: CorporateTokens.navy900,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                item.detail,
                style: const TextStyle(
                  color: CorporateTokens.slate500,
                  fontSize: 11,
                ),
              ),
              secondary:
                  item.requiredForGo
                      ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF2563EB,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Requerido',
                          style: TextStyle(
                            color: Color(0xFF2563EB),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                      : null,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildQueueHealthCard(List<_QueueMetric> modules) {
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
          const Text(
            'Salud de colas por modulo',
            style: TextStyle(
              color: CorporateTokens.navy900,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ...modules.map((item) {
            final hasError = item.lastError.trim().isNotEmpty;
            final pendingColor =
                item.pending > 0
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFF16A34A);

            return Container(
              margin: const EdgeInsets.only(bottom: 7),
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: CorporateTokens.surfaceBottom,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.module,
                          style: const TextStyle(
                            color: CorporateTokens.navy900,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (hasError)
                          Text(
                            item.lastError,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFDC2626),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: pendingColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: pendingColor.withValues(alpha: 0.30),
                      ),
                    ),
                    child: Text(
                      'Pend: ${item.pending}',
                      style: TextStyle(
                        color: pendingColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
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

  Future<void> _syncAllQueues() async {
    if (_syncing) return;
    setState(() {
      _syncing = true;
      _statusMessage = null;
      _statusIsError = false;
    });

    try {
      await ref.read(localApiHealthProvider.notifier).manualRefresh();
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
        _statusMessage = 'Sincronizacion terminada. Revise el estado GO/NO-GO.';
        _statusIsError = false;
      });
    } catch (_) {
      setState(() {
        _statusMessage = 'No se pudo completar la sincronizacion de colas.';
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

  Future<void> _copyGoNoGoReport({
    required bool isGo,
    required bool gateApiLocal,
    required bool gateQueue,
    required bool gateErrors,
    required bool gateChecklist,
    required int totalPending,
    required List<String> modulesWithPending,
    required List<String> modulesWithError,
    required ReleaseReadinessState checklist,
  }) async {
    final now = DateTime.now();
    final date =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final pendingText =
        modulesWithPending.isEmpty ? 'ninguno' : modulesWithPending.join(', ');
    final errorText =
        modulesWithError.isEmpty ? 'ninguno' : modulesWithError.join(', ');

    final report =
        StringBuffer()
          ..writeln('CoolImport PCP - Release Readiness')
          ..writeln('Fecha: $date $time')
          ..writeln('Decision: ${isGo ? 'GO PILOTO' : 'NO-GO'}')
          ..writeln('')
          ..writeln('Gates:')
          ..writeln('- API local: ${gateApiLocal ? 'OK' : 'Bloqueado'}')
          ..writeln('- Colas en cero: ${gateQueue ? 'OK' : 'Bloqueado'}')
          ..writeln('- Sin errores activos: ${gateErrors ? 'OK' : 'Bloqueado'}')
          ..writeln(
            '- Checklist requerido: ${gateChecklist ? 'OK' : 'Bloqueado'}',
          )
          ..writeln('')
          ..writeln(
            'Checklist: ${checklist.completedRequiredCount}/${checklist.requiredCount} requeridos',
          )
          ..writeln('Pendientes en cola: $totalPending')
          ..writeln('Modulos con pendientes: $pendingText')
          ..writeln('Modulos con error: $errorText');

    await Clipboard.setData(ClipboardData(text: report.toString()));
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reporte copiado al portapapeles')),
    );
  }
}

class _QueueMetric {
  final String module;
  final int pending;
  final String lastError;

  const _QueueMetric({
    required this.module,
    required this.pending,
    required this.lastError,
  });
}
