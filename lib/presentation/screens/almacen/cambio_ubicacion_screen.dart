import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/traslados_queue_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cambio_ubicacion_provider.dart';
import '../../widgets/enterprise_backdrop.dart';
import '../../widgets/scanner/qr_scanner_page.dart';

class CambioUbicacionScreen extends ConsumerStatefulWidget {
  const CambioUbicacionScreen({super.key});

  @override
  ConsumerState<CambioUbicacionScreen> createState() =>
      _CambioUbicacionScreenState();
}

class _CambioUbicacionScreenState extends ConsumerState<CambioUbicacionScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _qrController;
  late final TextEditingController _telarController;
  late final AnimationController _entryController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    final initial = ref.read(cambioUbicacionProvider);
    _qrController = TextEditingController(text: initial.qrRaw);
    _telarController = TextEditingController(text: initial.telar);

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
    _qrController.dispose();
    _telarController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cambioUbicacionProvider);
    final notifier = ref.read(cambioUbicacionProvider.notifier);
    final usuario = ref.watch(authProvider).user?.usuario ?? 'OPERARIO';

    ref.listen<CambioUbicacionState>(cambioUbicacionProvider, (previous, next) {
      if (!mounted) return;
      if (_qrController.text != next.qrRaw) {
        _qrController.text = next.qrRaw;
      }
      if (_telarController.text != next.telar) {
        _telarController.text = next.telar;
      }
    });

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
                    _buildStatusBanner(state),
                    const SizedBox(height: 10),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildScanCard(state, notifier),
                            const SizedBox(height: 10),
                            _buildParsedCard(state),
                            const SizedBox(height: 10),
                            _buildDestinoCard(state, notifier),
                            const SizedBox(height: 10),
                            _buildUltimaUbicacionCard(state, notifier),
                            const SizedBox(height: 10),
                            _buildQueueCard(state, notifier),
                            const SizedBox(height: 12),
                            _buildActions(
                              state: state,
                              usuario: usuario,
                              onEnviar:
                                  () => notifier.enviarCambio(usuario: usuario),
                              onLimpiar: () {
                                _qrController.clear();
                                _telarController.clear();
                                notifier.limpiarFormulario();
                              },
                            ),
                          ],
                        ),
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
                'Cambio Ubicacion (Hilos)',
                style: TextStyle(
                  color: CorporateTokens.navy900,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Salidas en planta con contrato legacy Screen6',
                style: TextStyle(color: CorporateTokens.slate500, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBanner(CambioUbicacionState state) {
    final hasError = state.errorMessage?.trim().isNotEmpty == true;
    final hasInfo = state.message?.trim().isNotEmpty == true;
    if (!hasError && !hasInfo) {
      return const SizedBox.shrink();
    }

    final isError = hasError;
    final text = hasError ? state.errorMessage! : state.message!;
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

  Widget _buildScanCard(
    CambioUbicacionState state,
    CambioUbicacionNotifier notifier,
  ) {
    return _buildCard(
      title: 'Escaneo de QR',
      children: [
        TextField(
          controller: _qrController,
          onChanged: notifier.setQrRaw,
          minLines: 2,
          maxLines: 4,
          style: const TextStyle(color: CorporateTokens.navy900),
          decoration: _inputDecoration(
            label: 'QR crudo',
            hint: 'Pegue o escanee el codigo QR',
            icon: Icons.qr_code_2_rounded,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: state.isBusy ? null : () => _scanQr(notifier),
                icon: const Icon(Icons.camera_alt_rounded),
                label: const Text('Escanear con camara'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: state.isBusy ? null : notifier.parsearQr,
                icon:
                    state.status == CambioUbicacionStatus.parsingQr
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.auto_fix_high_rounded),
                label: const Text('Parsear QR'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildParsedCard(CambioUbicacionState state) {
    final parsed = state.parsed;
    if (parsed == null) {
      return _buildCard(
        title: 'Datos de salida',
        children: const [
          Text(
            'Aun no hay QR parseado. Escanee o pegue un codigo para precargar campos.',
            style: TextStyle(color: CorporateTokens.slate500, fontSize: 12),
          ),
        ],
      );
    }

    return _buildCard(
      title: 'Datos de salida',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _chip('Campos QR', parsed.camposDetectados.toString()),
            _chip('Codigo Kardex', _safe(parsed.codigoKardex)),
            _chip('Codigo PCP', _safe(parsed.codigoPcp)),
            _chip('Material', _safe(parsed.material)),
            _chip('Titulo', _safe(parsed.titulo)),
            _chip('Color', _safe(parsed.color)),
            _chip('Lote', _safe(parsed.lote)),
            _chip('Num Caja', _safe(parsed.numCaja)),
            _chip('Servicio', _safe(parsed.servicio)),
          ],
        ),
      ],
    );
  }

  Widget _buildDestinoCard(
    CambioUbicacionState state,
    CambioUbicacionNotifier notifier,
  ) {
    final ubicaciones = state.ubicacionesDisponibles;
    final selectedUbicacion =
        ubicaciones.contains(state.ubicacionSeleccionada)
            ? state.ubicacionSeleccionada
            : ubicaciones.first;

    return _buildCard(
      title: 'Destino de ubicacion',
      children: [
        DropdownButtonFormField<String>(
          value: state.plantaSeleccionada,
          onChanged:
              state.isBusy
                  ? null
                  : (value) => notifier.setPlanta(value ?? 'PLANTA 1'),
          items:
              state.plantas
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item,
                      child: Text(item),
                    ),
                  )
                  .toList(),
          decoration: _inputDecoration(
            label: 'Planta',
            hint: 'Seleccione planta',
            icon: Icons.factory_rounded,
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: selectedUbicacion,
          onChanged:
              state.isBusy
                  ? null
                  : (value) =>
                      notifier.setUbicacion(value ?? selectedUbicacion),
          items:
              ubicaciones
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item,
                      child: Text(item),
                    ),
                  )
                  .toList(),
          decoration: _inputDecoration(
            label: 'Ubicacion',
            hint: 'Seleccione ubicacion',
            icon: Icons.place_rounded,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _telarController,
          onChanged: notifier.setTelar,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: CorporateTokens.navy900),
          decoration: _inputDecoration(
            label: 'Telar (opcional)',
            hint: 'Ejemplo: 12',
            icon: Icons.precision_manufacturing_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildUltimaUbicacionCard(
    CambioUbicacionState state,
    CambioUbicacionNotifier notifier,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CorporateTokens.surfaceBottom,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CorporateTokens.borderSoft),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_searching_rounded,
            color: CorporateTokens.cobalt600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Ultima ubicacion registrada: ${state.ultimaUbicacion}',
              style: const TextStyle(
                color: CorporateTokens.navy900,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed:
                state.isBusy ? null : notifier.consultarUltimaUbicacionManual,
            icon:
                state.status == CambioUbicacionStatus.consultandoUbicacion
                    ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.refresh_rounded),
            label: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueCard(
    CambioUbicacionState state,
    CambioUbicacionNotifier notifier,
  ) {
    final telemetry = state.telemetry;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CorporateTokens.surfaceBottom,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CorporateTokens.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Cola offline de cambio ubicacion',
                style: TextStyle(
                  color: CorporateTokens.navy900,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                'Pendientes: ${state.pendingQueue}',
                style: TextStyle(
                  color:
                      state.pendingQueue > 0
                          ? const Color(0xFF16A34A)
                          : CorporateTokens.slate300,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _telemetryChip('Encolados', telemetry.enqueuedTotal.toString()),
              _telemetryChip('Procesados', telemetry.processedTotal.toString()),
              _telemetryChip(
                'Fallos',
                telemetry.failedAttemptsTotal.toString(),
              ),
              _telemetryChip(
                'Reintentos',
                telemetry.retryAttemptsTotal.toString(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      state.isBusy
                          ? null
                          : () => notifier.procesarColaPendiente(),
                  icon:
                      state.status == CambioUbicacionStatus.drainingQueue
                          ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.playlist_play_rounded),
                  label: const Text('Procesar cola'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed:
                    state.isBusy || state.pendingQueue == 0
                        ? null
                        : notifier.limpiarCola,
                child: const Icon(Icons.delete_sweep_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (state.queue.isEmpty)
            const Text(
              'No hay registros pendientes.',
              style: TextStyle(color: CorporateTokens.slate300, fontSize: 11),
            )
          else
            ...state.queue.map(
              (job) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _buildQueueItem(job, notifier, state.isBusy),
              ),
            ),
          if (telemetry.lastError.trim().isNotEmpty)
            Text(
              'Ultimo error: ${telemetry.lastError}',
              style: const TextStyle(
                color: Color(0xFFDC2626),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQueueItem(
    CambioUbicacionQueueJobModel job,
    CambioUbicacionNotifier notifier,
    bool isBusy,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: CorporateTokens.surfaceTop,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CorporateTokens.borderSoft),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${job.codigoPcp} | ${job.planta} > ${job.ubicacion}',
                  style: const TextStyle(
                    color: CorporateTokens.navy900,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatDate(job.createdAtIso)} | Reintentos: ${job.attempts}',
                  style: const TextStyle(
                    color: CorporateTokens.slate300,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed:
                isBusy ? null : () => notifier.eliminarTrabajoCola(job.id),
            icon: const Icon(
              Icons.close_rounded,
              color: CorporateTokens.slate500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions({
    required CambioUbicacionState state,
    required String usuario,
    required Future<void> Function() onEnviar,
    required VoidCallback onLimpiar,
  }) {
    return Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: CorporateTokens.primaryButtonGradient,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ElevatedButton.icon(
            onPressed: state.isBusy ? null : onEnviar,
            icon:
                state.status == CambioUbicacionStatus.sending
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : const Icon(Icons.send_rounded),
            label: Text(
              state.status == CambioUbicacionStatus.sending
                  ? 'Enviando cambio...'
                  : 'Registrar cambio de ubicacion',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              disabledBackgroundColor: Colors.transparent,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                'Usuario operativo: $usuario',
                style: const TextStyle(
                  color: CorporateTokens.slate500,
                  fontSize: 11,
                ),
              ),
            ),
            TextButton(
              onPressed: state.isBusy ? null : onLimpiar,
              child: const Text('Limpiar'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
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
          Text(
            title,
            style: const TextStyle(
              color: CorporateTokens.navy900,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: CorporateTokens.slate500),
      filled: true,
      fillColor: Colors.white,
      errorStyle: const TextStyle(color: Color(0xFFEF4444), fontSize: 11),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: CorporateTokens.borderSoft),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: CorporateTokens.cobalt600,
          width: 1.6,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
    );
  }

  Widget _chip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
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

  Widget _telemetryChip(String label, String value) {
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

  Future<void> _scanQr(CambioUbicacionNotifier notifier) async {
    final scanned = await openQrScanner(
      context,
      title: 'Escanear QR para cambio de ubicacion',
    );
    if (!mounted || scanned == null || scanned.trim().isEmpty) return;

    final clean = scanned.trim();
    _qrController.text = clean;
    notifier.setQrRaw(clean);
    await notifier.parsearQr();
  }

  String _safe(String value) {
    final clean = value.trim();
    return clean.isEmpty ? '-' : clean;
  }

  String _formatDate(String iso) {
    final date = DateTime.tryParse(iso);
    if (date == null) return '-';
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yy = date.year.toString();
    final hh = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yy $hh:$min';
  }
}
