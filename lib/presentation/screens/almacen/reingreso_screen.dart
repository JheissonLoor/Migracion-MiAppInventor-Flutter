import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/almacen_mov_queue_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reingreso_provider.dart';
import '../../widgets/enterprise_backdrop.dart';
import '../../widgets/local_api_status_chip.dart';
import '../../widgets/scanner/qr_scanner_page.dart';

class ReingresoScreen extends ConsumerStatefulWidget {
  const ReingresoScreen({super.key});

  @override
  ConsumerState<ReingresoScreen> createState() => _ReingresoScreenState();
}

class _ReingresoScreenState extends ConsumerState<ReingresoScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _qrController;
  late final TextEditingController _ubicacionController;
  late final TextEditingController _reenconadoController;
  late final TextEditingController _pesoBrutoController;

  late final AnimationController _entryController;

  @override
  void initState() {
    super.initState();
    _qrController = TextEditingController();
    _ubicacionController = TextEditingController();
    _reenconadoController = TextEditingController(text: '0');
    _pesoBrutoController = TextEditingController();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 840),
    )..forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _qrController.dispose();
    _ubicacionController.dispose();
    _reenconadoController.dispose();
    _pesoBrutoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reingresoProvider);
    final notifier = ref.read(reingresoProvider.notifier);
    final usuario = ref.watch(authProvider).user?.usuario ?? 'OPERARIO';
    final sidePadding = MediaQuery.sizeOf(context).width >= 920 ? 28.0 : 16.0;

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: EnterpriseBackdrop()),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(sidePadding, 12, sidePadding, 16),
              child: Column(
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 10),
                  _buildBanner(state),
                  const SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: Column(
                          children: [
                            _StaggerReveal(
                              controller: _entryController,
                              start: 0.05,
                              end: 0.55,
                              child: _buildQrCard(state, notifier),
                            ),
                            const SizedBox(height: 10),
                            _StaggerReveal(
                              controller: _entryController,
                              start: 0.13,
                              end: 0.72,
                              child: _buildPesoCard(state, notifier),
                            ),
                            const SizedBox(height: 10),
                            _StaggerReveal(
                              controller: _entryController,
                              start: 0.22,
                              end: 0.85,
                              child: _buildActionsCard(
                                state: state,
                                usuario: usuario,
                                notifier: notifier,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _StaggerReveal(
                              controller: _entryController,
                              start: 0.30,
                              end: 0.97,
                              child: _buildQueueCard(state, notifier),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _scanQr(ReingresoNotifier notifier, ReingresoState state) async {
    if (state.isBusy) return;

    final result = await openQrScanner(
      context,
      title: 'Escanear QR para reingreso',
    );
    if (!mounted || result == null || result.trim().isEmpty) return;

    _qrController.text = result;
    notifier.setQrRaw(result);
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
          icon: const Icon(Icons.arrow_back_rounded, color: CorporateTokens.navy900),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reingreso en almacen',
                style: TextStyle(
                  color: CorporateTokens.navy900,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Validacion de movimiento + envio a Google Forms',
                style: TextStyle(color: CorporateTokens.slate500, fontSize: 12),
              ),
            ],
          ),
        ),
        const LocalApiStatusChip(compact: true),
      ],
    );
  }

  Widget _buildBanner(ReingresoState state) {
    final hasError = (state.errorMessage ?? '').isNotEmpty;
    final hasMessage = (state.message ?? '').isNotEmpty;
    if (!hasError && !hasMessage) return const SizedBox.shrink();

    final isError = hasError;
    final bgColor = isError ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7);
    final borderColor = isError ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC);
    final iconColor = isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A);
    final text = isError ? state.errorMessage! : state.message!;

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

  Widget _buildQrCard(ReingresoState state, ReingresoNotifier notifier) {
    return _GlassBlock(
      title: 'Lectura de QR hilos',
      child: Column(
        children: [
          TextFormField(
            controller: _qrController,
            onChanged: notifier.setQrRaw,
            minLines: 2,
            maxLines: 4,
            style: const TextStyle(color: CorporateTokens.navy900),
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return 'Ingrese o escanee el QR';
              }
              return null;
            },
            decoration: _inputDecoration(
              label: 'Codigo QR',
              hint: 'Formato 14 o 16 campos',
              icon: Icons.qr_code_2_rounded,
              suffixIcon: IconButton(
                onPressed: () => _scanQr(notifier, state),
                tooltip: 'Escanear con camara',
                icon: const Icon(
                  Icons.camera_alt_rounded,
                  color: CorporateTokens.slate500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      state.isBusy
                          ? null
                          : () async {
                            if (_formKey.currentState?.validate() != true) {
                              return;
                            }
                            await notifier.parsearQrYTaras();
                            if (!mounted) return;
                            final latest = ref.read(reingresoProvider);
                            if (latest.parsed != null) {
                              // Sincroniza campos derivados del QR para evitar reingreso manual.
                              _ubicacionController.text = latest.nuevaUbicacion;
                              _reenconadoController.text =
                                  latest.cantidadReenconado;
                              _pesoBrutoController.text = latest.pesoBruto;
                            }
                          },
                  icon:
                      state.status == ReingresoStatus.parsingQr ||
                              state.status == ReingresoStatus.loadingTaras
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Icon(Icons.fact_check_rounded),
                  label: Text(
                    state.status == ReingresoStatus.loadingTaras
                        ? 'Cargando taras...'
                        : 'Parsear QR y cargar taras',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: CorporateTokens.cobalt600,
                    side: BorderSide(
                      color: CorporateTokens.cobalt600.withValues(alpha: 0.30),
                    ),
                    minimumSize: const Size.fromHeight(44),
                  ),
                ),
              ),
            ],
          ),
          if (state.parsed != null) ...[
            const SizedBox(height: 10),
            _buildParsedSummary(state),
          ],
        ],
      ),
    );
  }

  Widget _buildParsedSummary(ReingresoState state) {
    final parsed = state.parsed!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: CorporateTokens.surfaceBottom,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CorporateTokens.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Datos del QR',
            style: TextStyle(
              color: CorporateTokens.navy900,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          _infoRow('PCP', parsed.codigoPcp),
          _infoRow('Material', '${parsed.material} ${parsed.titulo}'),
          _infoRow('Color/Lote', '${parsed.color} / ${parsed.lote}'),
          _infoRow('Proveedor', parsed.proveedor),
          _infoRow(
            'Cajas/Bobinas',
            '${parsed.numCajas.toStringAsFixed(0)} / ${parsed.totalBobinas.toStringAsFixed(0)}',
          ),
        ],
      ),
    );
  }

  Widget _buildPesoCard(ReingresoState state, ReingresoNotifier notifier) {
    return _GlassBlock(
      title: 'Taras y pesos netos',
      child: Column(
        children: [
          if (state.taras == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CorporateTokens.surfaceTop,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: CorporateTokens.borderSoft),
              ),
              child: const Text(
                'Aun no hay taras cargadas. Parsee el QR para continuar.',
                style: TextStyle(color: CorporateTokens.slate500, fontSize: 12),
              ),
            )
          else
            Column(
              children: [
                _buildTarasStrip(state),
                const SizedBox(height: 10),
                _buildTaraSelector(state, notifier),
              ],
            ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _ubicacionController,
            onChanged: notifier.setNuevaUbicacion,
            textInputAction: TextInputAction.next,
            style: const TextStyle(color: CorporateTokens.navy900),
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return 'Ingrese nueva ubicacion';
              }
              return null;
            },
            decoration: _inputDecoration(
              label: 'Nueva ubicacion',
              hint: 'Ejemplo: A-12, TELAR-4, VENTA',
              icon: Icons.edit_location_alt_rounded,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _reenconadoController,
                  onChanged: notifier.setCantidadReenconado,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(color: CorporateTokens.navy900),
                  decoration: _inputDecoration(
                    label: 'Cant. reenconado',
                    hint: '0',
                    icon: Icons.linear_scale_rounded,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _pesoBrutoController,
                  onChanged: notifier.setPesoBruto,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(color: CorporateTokens.navy900),
                  validator: (value) {
                    final parsed = _toDouble(value ?? '');
                    if (parsed <= 0) {
                      return 'Peso invalido';
                    }
                    return null;
                  },
                  decoration: _inputDecoration(
                    label: 'Peso bruto',
                    hint: '0.00',
                    icon: Icons.scale_rounded,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _readonlyMetric(
            label: 'Peso neto calculado',
            value: state.pesoNeto.isEmpty ? '-' : '${state.pesoNeto} kg',
          ),
        ],
      ),
    );
  }

  Widget _buildTarasStrip(ReingresoState state) {
    final taras = state.taras!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: CorporateTokens.surfaceTop,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CorporateTokens.borderSoft),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          _chipInfo('Cono', taras.taraCono),
          _chipInfo('Caja', taras.taraCaja),
          _chipInfo('Bolsa', taras.taraBolsa),
          _chipInfo('Saco', taras.taraSaco),
        ],
      ),
    );
  }

  Widget _chipInfo(String label, double value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: CorporateTokens.surfaceBottom,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: CorporateTokens.borderSoft),
      ),
      child: Text(
        '$label: ${value.toStringAsFixed(2)}',
        style: const TextStyle(
          color: CorporateTokens.navy900,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTaraSelector(ReingresoState state, ReingresoNotifier notifier) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        _taraChip(
          label: 'Sin tara',
          value: TaraTipo.none,
          state: state,
          notifier: notifier,
        ),
        _taraChip(
          label: 'Caja',
          value: TaraTipo.caja,
          state: state,
          notifier: notifier,
        ),
        _taraChip(
          label: 'Bolsa',
          value: TaraTipo.bolsa,
          state: state,
          notifier: notifier,
        ),
        _taraChip(
          label: 'Saco',
          value: TaraTipo.saco,
          state: state,
          notifier: notifier,
        ),
      ],
    );
  }

  Widget _taraChip({
    required String label,
    required TaraTipo value,
    required ReingresoState state,
    required ReingresoNotifier notifier,
  }) {
    final selected = state.taraTipo == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: state.isBusy ? null : (_) => notifier.setTaraTipo(value),
      selectedColor: CorporateTokens.cobalt600.withValues(alpha: 0.15),
      backgroundColor: Colors.white,
      side: BorderSide(
        color:
            selected
                ? CorporateTokens.cobalt600
                : CorporateTokens.borderSoft,
      ),
      labelStyle: const TextStyle(
        color: CorporateTokens.navy900,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildActionsCard({
    required ReingresoState state,
    required String usuario,
    required ReingresoNotifier notifier,
  }) {
    return _GlassBlock(
      title: 'Registro de movimiento',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: CorporateTokens.surfaceTop,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: CorporateTokens.borderSoft),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Usuario operativo: $usuario',
                  style: const TextStyle(
                    color: CorporateTokens.navy900,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'El envio se realiza con validacion previa y luego Google Forms legacy.',
                  style: TextStyle(
                    color: CorporateTokens.slate500,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: CorporateTokens.primaryButtonGradient,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton.icon(
              onPressed:
                  state.isBusy
                      ? null
                      : () async {
                        if (_formKey.currentState?.validate() != true) {
                          return;
                        }
                        await notifier.enviarReingreso(usuario: usuario);
                      },
              icon:
                  state.status == ReingresoStatus.validating ||
                          state.status == ReingresoStatus.sending
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
                state.status == ReingresoStatus.validating
                    ? 'Validando movimiento...'
                    : state.status == ReingresoStatus.sending
                    ? 'Enviando reingreso...'
                    : 'Validar y enviar reingreso',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                disabledBackgroundColor: Colors.transparent,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed:
                  state.isBusy
                      ? null
                      : () {
                        _formKey.currentState?.reset();
                        _qrController.clear();
                        _ubicacionController.clear();
                        _reenconadoController.text = '0';
                        _pesoBrutoController.clear();
                        notifier.limpiar();
                      },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Limpiar formulario'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueCard(ReingresoState state, ReingresoNotifier notifier) {
    final telemetry = state.telemetry;
    return _GlassBlock(
      title: 'Cola offline de reingresos',
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: CorporateTokens.surfaceTop,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: CorporateTokens.borderSoft),
            ),
            child: Row(
              children: [
                Text(
                  'Pendientes: ${state.pendingQueue}',
                  style: const TextStyle(
                    color: CorporateTokens.navy900,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  'Encolados: ${telemetry.enqueuedTotal}',
                  style: const TextStyle(
                    color: CorporateTokens.slate500,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
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
                      state.isBusy ? null : notifier.procesarColaPendiente,
                  icon:
                      state.status == ReingresoStatus.drainingQueue
                          ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Icon(Icons.playlist_play_rounded),
                  label: const Text('Procesar cola'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: CorporateTokens.cobalt600,
                    side: BorderSide(
                      color: CorporateTokens.cobalt600.withValues(alpha: 0.30),
                    ),
                    minimumSize: const Size.fromHeight(40),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed:
                    state.isBusy || state.pendingQueue == 0
                        ? null
                        : notifier.limpiarCola,
                style: OutlinedButton.styleFrom(
                  foregroundColor: CorporateTokens.cobalt600,
                  side: BorderSide(color: CorporateTokens.cobalt600.withValues(alpha: 0.30)),
                  minimumSize: const Size(48, 40),
                ),
                child: const Icon(Icons.delete_sweep_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (state.queue.isEmpty)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'No hay reingresos pendientes.',
                style: TextStyle(color: CorporateTokens.slate300, fontSize: 11),
              ),
            )
          else
            ...state.queue.map(
              (job) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _buildQueueItem(job, notifier, state.isBusy),
              ),
            ),
          if (telemetry.lastError.trim().isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Ultimo error: ${telemetry.lastError}',
                style: const TextStyle(
                  color: Color(0xFFDC2626),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQueueItem(
    ReingresoQueueJobModel job,
    ReingresoNotifier notifier,
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
                  '${job.codigoPcp} -> ${job.nuevaUbicacion}',
                  style: const TextStyle(
                    color: CorporateTokens.navy900,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatDateLabel(job.createdAtIso)} | Reintentos: ${job.attempts}',
                  style: const TextStyle(color: CorporateTokens.slate500, fontSize: 10),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed:
                isBusy ? null : () => notifier.eliminarTrabajoCola(job.id),
            icon: const Icon(Icons.close_rounded, color: CorporateTokens.slate500),
          ),
        ],
      ),
    );
  }

  Widget _telemetryChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: CorporateTokens.surfaceBottom,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: CorporateTokens.borderSoft),
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

  Widget _readonlyMetric({required String label, required String value}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: CorporateTokens.surfaceTop,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CorporateTokens.borderSoft),
      ),
      child: Row(
        children: [
          const Icon(Icons.monitor_weight_rounded, color: CorporateTokens.slate500),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: CorporateTokens.slate500,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: CorporateTokens.navy900,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: CorporateTokens.slate500,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
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

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: CorporateTokens.slate500),
      hintStyle: const TextStyle(color: CorporateTokens.slate300),
      prefixIcon: Icon(icon, color: CorporateTokens.slate500, size: 18),
      suffixIcon: suffixIcon,
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

  String _formatDateLabel(String iso) {
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

class _GlassBlock extends StatelessWidget {
  final String title;
  final Widget child;

  const _GlassBlock({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
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
          child,
        ],
      ),
    );
  }
}

class _StaggerReveal extends StatelessWidget {
  final AnimationController controller;
  final double start;
  final double end;
  final Widget child;

  const _StaggerReveal({
    required this.controller,
    required this.start,
    required this.end,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(animation);

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(position: slide, child: child),
    );
  }
}

double _toDouble(String value) {
  return double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;
}
