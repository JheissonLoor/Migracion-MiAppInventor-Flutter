import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/legacy_modules_queue_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/contenedor_provider.dart';
import '../../widgets/enterprise_backdrop.dart';
import '../../widgets/scanner/qr_scanner_page.dart';

class ContenedorScreen extends ConsumerStatefulWidget {
  const ContenedorScreen({super.key});

  @override
  ConsumerState<ContenedorScreen> createState() => _ContenedorScreenState();
}

class _ContenedorScreenState extends ConsumerState<ContenedorScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _qrController;
  late final TextEditingController _nroConosController;
  late final TextEditingController _pesoBrutoController;
  late final TextEditingController _pesoNetoController;
  late final TextEditingController _numCajasController;
  late final AnimationController _entryController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    final current = ref.read(contenedorProvider);
    _qrController = TextEditingController(text: current.qrRaw);
    _nroConosController = TextEditingController(text: current.nroConos);
    _pesoBrutoController = TextEditingController(text: current.pesoBruto);
    _pesoNetoController = TextEditingController(text: current.pesoNeto);
    _numCajasController = TextEditingController(text: current.numCajasMovidas);

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
    _nroConosController.dispose();
    _pesoBrutoController.dispose();
    _pesoNetoController.dispose();
    _numCajasController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(contenedorProvider);
    final notifier = ref.read(contenedorProvider.notifier);
    final usuario = ref.watch(authProvider).user?.usuario ?? 'OPERARIO';

    ref.listen<ContenedorState>(contenedorProvider, (previous, next) {
      if (!mounted) return;
      _sync(_qrController, next.qrRaw);
      _sync(_nroConosController, next.nroConos);
      _sync(_pesoBrutoController, next.pesoBruto);
      _sync(_pesoNetoController, next.pesoNeto);
      _sync(_numCajasController, next.numCajasMovidas);
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
                            _buildCalcCard(state, notifier),
                            const SizedBox(height: 10),
                            _buildQueueCard(state, notifier),
                            const SizedBox(height: 12),
                            _buildActions(state, notifier, usuario),
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
                'Ingreso Contenedor',
                style: TextStyle(
                  color: CorporateTokens.navy900,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Registro de movimiento + actualizacion en /actualizar_datos',
                style: TextStyle(color: CorporateTokens.slate500, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBanner(ContenedorState state) {
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

  Widget _buildScanCard(ContenedorState state, ContenedorNotifier notifier) {
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
            label: 'QR de hilos (16 campos)',
            hint: 'Pegue o escanee el codigo',
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
                label: const Text('Escanear'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: state.isBusy ? null : notifier.parsearQr,
                icon:
                    state.status == ContenedorStatus.parsingQr
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.auto_fix_high_rounded),
                label: const Text('Validar QR'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildParsedCard(ContenedorState state) {
    final parsed = state.parsedQr;
    if (parsed == null) {
      return _buildCard(
        title: 'Datos escaneados',
        children: const [
          Text(
            'Aun no hay QR validado.',
            style: TextStyle(color: CorporateTokens.slate500, fontSize: 12),
          ),
        ],
      );
    }

    return _buildCard(
      title: 'Datos escaneados',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _chip('Campos', parsed.camposDetectados.toString()),
            _chip('Codigo HC', _safe(parsed.codigoPcp)),
            _chip('Kardex', _safe(parsed.codigoKardex)),
            _chip('Material', _safe(parsed.material)),
            _chip('Titulo', _safe(parsed.titulo)),
            _chip('Color', _safe(parsed.color)),
            _chip('Lote', _safe(parsed.lote)),
            _chip('Proveedor', _safe(parsed.proveedor)),
            _chip('Fecha ingreso', _safe(parsed.fechaIngreso)),
            _chip('Servicio', _safe(parsed.servicio)),
          ],
        ),
      ],
    );
  }

  Widget _buildCalcCard(ContenedorState state, ContenedorNotifier notifier) {
    return _buildCard(
      title: 'Calculo de movimiento',
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _nroConosController,
                onChanged: notifier.setNroConos,
                enabled: !state.isBusy && state.parsedQr != null,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _inputDecoration(
                  label: 'Nro. conos',
                  hint: '0',
                  icon: Icons.format_list_numbered_rounded,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _numCajasController,
                onChanged: notifier.setNumCajasMovidas,
                enabled: !state.isBusy && state.parsedQr != null,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _inputDecoration(
                  label: 'Nro. cajas a mover',
                  hint: '0',
                  icon: Icons.inventory_2_rounded,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _pesoBrutoController,
                onChanged: notifier.setPesoBruto,
                enabled: !state.isBusy && state.parsedQr != null,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _inputDecoration(
                  label: 'Peso bruto',
                  hint: '0',
                  icon: Icons.scale_rounded,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _pesoNetoController,
                onChanged: notifier.setPesoNeto,
                enabled: !state.isBusy && state.parsedQr != null,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _inputDecoration(
                  label: 'Peso neto',
                  hint: '0',
                  icon: Icons.monitor_weight_rounded,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: state.isBusy || state.parsedQr == null
              ? null
              : notifier.recalcularTotales,
          icon: state.status == ContenedorStatus.calculating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.calculate_rounded),
          label: const Text('Calcular totales'),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _chip('Total bobinas', _safe(state.totalBobinas)),
            _chip('Peso bruto total', _safe(state.pesoBrutoTotal)),
            _chip('Peso neto total', _safe(state.pesoNetoTotal)),
            _chip('Fecha salida', _safe(state.fechaSalida)),
          ],
        ),
      ],
    );
  }

  Widget _buildQueueCard(ContenedorState state, ContenedorNotifier notifier) {
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
                'Cola offline de contenedor',
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
                      state.status == ContenedorStatus.drainingQueue
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
    ContenedorQueueJobModel job,
    ContenedorNotifier notifier,
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
                  '${job.codigoHc} | Cajas: ${job.numCajasMovidas} | Bobinas: ${job.totalBobinas}',
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

  Widget _buildActions(
    ContenedorState state,
    ContenedorNotifier notifier,
    String usuario,
  ) {
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
            onPressed:
                state.isBusy ? null : () => notifier.enviarContenedor(usuario: usuario),
            icon:
                state.status == ContenedorStatus.sending
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
              state.status == ContenedorStatus.sending
                  ? 'Enviando...'
                  : 'Enviar datos',
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
              onPressed: state.isBusy ? null : notifier.limpiarFormulario,
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

  Future<void> _scanQr(ContenedorNotifier notifier) async {
    final scanned = await openQrScanner(
      context,
      title: 'Escanear QR para contenedor',
    );
    if (!mounted || scanned == null || scanned.trim().isEmpty) return;

    final clean = scanned.trim();
    _qrController.text = clean;
    notifier.setQrRaw(clean);
    await notifier.parsearQr();
  }

  void _sync(TextEditingController controller, String value) {
    if (controller.text == value) return;
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
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
