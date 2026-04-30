import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/despacho_queue_job_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gestion_stock_telas_provider.dart';
import '../../widgets/enterprise_backdrop.dart';
import '../../widgets/local_api_status_chip.dart';
import '../../widgets/scanner/qr_scanner_page.dart';

class GestionStockTelasScreen extends ConsumerStatefulWidget {
  const GestionStockTelasScreen({super.key});

  @override
  ConsumerState<GestionStockTelasScreen> createState() =>
      _GestionStockTelasScreenState();
}

class _GestionStockTelasScreenState
    extends ConsumerState<GestionStockTelasScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _qrController;
  late final TextEditingController _obsIngresoController;
  late final TextEditingController _codigoDespachoController;
  late final TextEditingController _destinoController;
  late final TextEditingController _guiaController;
  late final TextEditingController _obsDespachoController;

  late final AnimationController _entryController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  static const _ubicaciones = <String>[
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'A1',
    'A2',
    'A3',
    'B1',
    'B2',
    'B3',
    'ALMACEN1',
    'ALMACEN2',
  ];

  @override
  void initState() {
    super.initState();
    _qrController = TextEditingController();
    _obsIngresoController = TextEditingController();
    _codigoDespachoController = TextEditingController();
    _destinoController = TextEditingController();
    _guiaController = TextEditingController();
    _obsDespachoController = TextEditingController();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(_fadeAnimation);
  }

  @override
  void dispose() {
    _entryController.dispose();
    _qrController.dispose();
    _obsIngresoController.dispose();
    _codigoDespachoController.dispose();
    _destinoController.dispose();
    _guiaController.dispose();
    _obsDespachoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gestionStockTelasProvider);
    final notifier = ref.read(gestionStockTelasProvider.notifier);
    final usuario = ref.watch(authProvider).user?.usuario ?? 'OPERARIO';
    _syncControllersFromState(state);

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: EnterpriseBackdrop()),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 10),
                      _buildMessageBanner(state),
                      const SizedBox(height: 10),
                      _buildTabSelector(state, notifier),
                      const SizedBox(height: 10),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          child:
                              state.activeTab == GestionTab.ingreso
                                  ? _buildIngresoTab(state, notifier, usuario)
                                  : _buildDespachoTab(state, notifier, usuario),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _syncControllersFromState(GestionStockTelasState state) {
    _syncController(_codigoDespachoController, state.codigoDespachoInput);
    _syncController(_destinoController, state.destinoDespacho);
    _syncController(_guiaController, state.guiaDespacho);
    _syncController(_obsDespachoController, state.observacionesDespacho);
  }

  void _syncController(TextEditingController controller, String value) {
    if (controller.text == value) return;
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  Future<void> _scanIngresoQr(
    GestionStockTelasNotifier notifier,
    GestionStockTelasState state,
  ) async {
    if (state.isBusy) return;

    final result = await openQrScanner(
      context,
      title: 'Escanear QR de ingreso tela',
    );
    if (!mounted || result == null || result.trim().isEmpty) return;

    _qrController.text = result;
    notifier.setQrRaw(result);
  }

  Future<void> _scanDespachoQr(
    GestionStockTelasNotifier notifier,
    GestionStockTelasState state,
  ) async {
    if (state.isBusy) return;

    final result = await openQrScanner(
      context,
      title: 'Escanear QR para despacho',
    );
    if (!mounted || result == null || result.trim().isEmpty) return;

    _codigoDespachoController.text = result;
    notifier.setCodigoDespachoInput(result);
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
                'Gestion Stock Telas',
                style: TextStyle(
                  color: CorporateTokens.navy900,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Ingreso y despacho con trazabilidad empresarial',
                style: TextStyle(color: CorporateTokens.slate500, fontSize: 12),
              ),
            ],
          ),
        ),
        const LocalApiStatusChip(compact: true),
      ],
    );
  }

  Widget _buildMessageBanner(GestionStockTelasState state) {
    final hasError = (state.errorMessage ?? '').isNotEmpty;
    final hasMessage = (state.message ?? '').isNotEmpty;
    if (!hasError && !hasMessage) return const SizedBox.shrink();

    final isError = hasError;
    final bgColor = isError ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7);
    final borderColor = isError ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC);
    final iconColor = isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A);
    final icon =
        isError ? Icons.error_outline_rounded : Icons.check_circle_rounded;
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
          Icon(icon, color: iconColor, size: 18),
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

  Widget _buildTabSelector(
    GestionStockTelasState state,
    GestionStockTelasNotifier notifier,
  ) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CorporateTokens.borderSoft),
      ),
      child: Row(
        children: [
          _buildTabButton(
            selected: state.activeTab == GestionTab.ingreso,
            label: 'Ingreso',
            icon: Icons.add_box_rounded,
            onTap: () => notifier.cambiarTab(GestionTab.ingreso),
          ),
          _buildTabButton(
            selected: state.activeTab == GestionTab.despacho,
            label: 'Despacho',
            icon: Icons.local_shipping_rounded,
            onTap: () => notifier.cambiarTab(GestionTab.despacho),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required bool selected,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient:
                selected
                    ? const LinearGradient(
                      colors: CorporateTokens.primaryButtonGradient,
                    )
                    : null,
            color: selected ? null : Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected ? Colors.white : CorporateTokens.slate500,
                size: 17,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : CorporateTokens.slate500,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIngresoTab(
    GestionStockTelasState state,
    GestionStockTelasNotifier notifier,
    String usuario,
  ) {
    return SingleChildScrollView(
      key: const ValueKey<String>('ingreso-tab'),
      child: Column(
        children: [
          _buildGlassCard(
            title: 'QR de tela revisada',
            child: Column(
              children: [
                TextFormField(
                  controller: _qrController,
                  onChanged: notifier.setQrRaw,
                  minLines: 2,
                  maxLines: 4,
                  style: const TextStyle(color: CorporateTokens.navy900),
                  decoration: _inputDecoration(
                    label: 'Codigo QR completo',
                    hint: 'Pega o escanea el texto QR de 8 campos',
                    icon: Icons.qr_code_2_rounded,
                    suffixIcon: IconButton(
                      onPressed: () => _scanIngresoQr(notifier, state),
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
                                : () => notifier.parsearQrIngreso(),
                        icon:
                            state.status == GestionStatus.parsingQr
                                ? const SizedBox(
                                  width: 15,
                                  height: 15,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : const Icon(Icons.verified_rounded),
                        label: const Text('Validar QR'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: CorporateTokens.cobalt600,
                          side: BorderSide(
                            color: CorporateTokens.cobalt600.withValues(alpha: 0.30),
                          ),
                          minimumSize: const Size.fromHeight(42),
                        ),
                      ),
                    ),
                  ],
                ),
                if (state.qrIngreso != null) ...[
                  const SizedBox(height: 10),
                  _buildQrResumen(state),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          _buildGlassCard(
            title: 'Ubicacion fisica',
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        label: 'Almacen',
                        value: state.almacen,
                        items: AppConstants.almacenes,
                        onChanged:
                            state.isBusy
                                ? null
                                : (v) => notifier.setAlmacen(v!),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildDropdown(
                        label: 'Ubicacion',
                        value: state.ubicacion,
                        items: _ubicaciones,
                        onChanged:
                            state.isBusy
                                ? null
                                : (v) => notifier.setUbicacion(v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _obsIngresoController,
                  onChanged: notifier.setObservacionesIngreso,
                  minLines: 2,
                  maxLines: 3,
                  style: const TextStyle(color: CorporateTokens.navy900),
                  decoration: _inputDecoration(
                    label: 'Observaciones',
                    hint: 'Notas opcionales del ingreso',
                    icon: Icons.notes_rounded,
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
                            : () => notifier.registrarIngreso(usuario: usuario),
                    icon:
                        state.status == GestionStatus.registrandoIngreso
                            ? const SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Icon(Icons.save_rounded),
                    label: const Text('Registrar ingreso en stock'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(46),
                      disabledBackgroundColor: Colors.transparent,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed:
                        state.isBusy
                            ? null
                            : () {
                              _qrController.clear();
                              _obsIngresoController.clear();
                              notifier.limpiarIngreso();
                            },
                    child: const Text('Limpiar ingreso'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrResumen(GestionStockTelasState state) {
    final tela = state.qrIngreso!.parsed;
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
            'Datos parseados',
            style: TextStyle(
              color: CorporateTokens.navy900,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          _infoRow('Codigo', tela.codigoTela),
          _infoRow('Articulo', tela.articulo),
          _infoRow('Metraje', tela.metraje.toString()),
          _infoRow('Peso', tela.peso.toString()),
          _infoRow('Revisador', tela.revisador),
        ],
      ),
    );
  }

  Widget _buildDespachoTab(
    GestionStockTelasState state,
    GestionStockTelasNotifier notifier,
    String usuario,
  ) {
    return SingleChildScrollView(
      key: const ValueKey<String>('despacho-tab'),
      child: Column(
        children: [
          _buildGlassCard(
            title: 'Agregar rollos al carrito',
            child: Column(
              children: [
                TextField(
                  controller: _codigoDespachoController,
                  onChanged: notifier.setCodigoDespachoInput,
                  style: const TextStyle(color: CorporateTokens.navy900),
                  decoration: _inputDecoration(
                    label: 'Codigo de rollo o QR',
                    hint: 'Ejemplo: T1C150126-01',
                    icon: Icons.qr_code_scanner_rounded,
                    suffixIcon: IconButton(
                      onPressed: () => _scanDespachoQr(notifier, state),
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
                                  await notifier.agregarRolloAlCarrito();
                                  _codigoDespachoController.clear();
                                },
                        icon:
                            state.status == GestionStatus.validandoRollo
                                ? const SizedBox(
                                  width: 15,
                                  height: 15,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : const Icon(Icons.playlist_add_rounded),
                        label: const Text('Validar y agregar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: CorporateTokens.cobalt600,
                          side: BorderSide(
                            color: CorporateTokens.cobalt600.withValues(alpha: 0.30),
                          ),
                          minimumSize: const Size.fromHeight(42),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _buildGlassCard(
            title: 'Carrito de despacho',
            child: Column(
              children: [
                _buildCarritoHeader(state),
                const SizedBox(height: 8),
                if (state.carrito.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: CorporateTokens.surfaceTop,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: CorporateTokens.borderSoft),
                    ),
                    child: const Text(
                      'Aun no hay rollos en el carrito.',
                      style: TextStyle(color: CorporateTokens.slate300, fontSize: 12),
                    ),
                  )
                else
                  ...state.carrito.map(
                    (item) => _buildRolloItem(item, notifier, state.isBusy),
                  ),
                const SizedBox(height: 10),
                TextField(
                  controller: _destinoController,
                  onChanged: notifier.setDestinoDespacho,
                  style: const TextStyle(color: CorporateTokens.navy900),
                  decoration: _inputDecoration(
                    label: 'Destino',
                    hint: 'Cliente o area de destino',
                    icon: Icons.flag_rounded,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _guiaController,
                  onChanged: notifier.setGuiaDespacho,
                  style: const TextStyle(color: CorporateTokens.navy900),
                  decoration: _inputDecoration(
                    label: 'Guia / referencia',
                    hint: 'Opcional',
                    icon: Icons.receipt_long_rounded,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _obsDespachoController,
                  onChanged: notifier.setObservacionesDespacho,
                  minLines: 2,
                  maxLines: 3,
                  style: const TextStyle(color: CorporateTokens.navy900),
                  decoration: _inputDecoration(
                    label: 'Observaciones',
                    hint: 'Opcional',
                    icon: Icons.description_rounded,
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
                            : () => notifier.imprimirDespacho(usuario: usuario),
                    icon:
                        state.status == GestionStatus.imprimiendoDespacho
                            ? const SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Icon(Icons.print_rounded),
                    label: const Text('Generar e imprimir despacho'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(46),
                      disabledBackgroundColor: Colors.transparent,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed:
                        state.isBusy
                            ? null
                            : () {
                              _codigoDespachoController.clear();
                              _destinoController.clear();
                              _guiaController.clear();
                              _obsDespachoController.clear();
                              notifier.limpiarDespacho();
                            },
                    child: const Text('Limpiar despacho'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _buildDespachoQueueCard(state, notifier),
        ],
      ),
    );
  }

  Widget _buildCarritoHeader(GestionStockTelasState state) {
    return Container(
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
            'Rollos: ${state.carrito.length}',
            style: const TextStyle(
              color: CorporateTokens.navy900,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Metros: ${state.totalMetros.toStringAsFixed(2)}',
            style: const TextStyle(color: CorporateTokens.slate500, fontSize: 11),
          ),
          const SizedBox(width: 10),
          Text(
            'Peso: ${state.totalPeso.toStringAsFixed(2)}',
            style: const TextStyle(color: CorporateTokens.slate500, fontSize: 11),
          ),
          const Spacer(),
          Text(
            'Cola: ${state.pendingDespachos}',
            style: TextStyle(
              color:
                  state.pendingDespachos > 0
                      ? const Color(0xFF16A34A)
                      : CorporateTokens.slate300,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDespachoQueueCard(
    GestionStockTelasState state,
    GestionStockTelasNotifier notifier,
  ) {
    final telemetry = state.telemetry;
    return _buildGlassCard(
      title: 'Cola offline de despacho + telemetria',
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
                  'Pendientes: ${state.pendingDespachos}',
                  style: const TextStyle(
                    color: CorporateTokens.navy900,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  state.localApiDisponible
                      ? 'API local online'
                      : 'API local offline',
                  style: TextStyle(
                    color:
                        state.localApiDisponible
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFDC2626),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
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
                      state.isBusy ? null : notifier.procesarColaDespacho,
                  icon:
                      state.status == GestionStatus.drainingDespachoQueue
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
                    minimumSize: const Size.fromHeight(42),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed:
                    state.isBusy ? null : notifier.refrescarEstadoApiLocal,
                style: OutlinedButton.styleFrom(
                  foregroundColor: CorporateTokens.cobalt600,
                  side: BorderSide(color: CorporateTokens.cobalt600.withValues(alpha: 0.30)),
                  minimumSize: const Size(50, 42),
                ),
                child: const Icon(Icons.refresh_rounded),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed:
                    state.isBusy || state.pendingDespachos == 0
                        ? null
                        : notifier.limpiarColaDespacho,
                style: OutlinedButton.styleFrom(
                  foregroundColor: CorporateTokens.cobalt600,
                  side: BorderSide(color: CorporateTokens.cobalt600.withValues(alpha: 0.30)),
                  minimumSize: const Size(50, 42),
                ),
                child: const Icon(Icons.delete_sweep_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (state.despachoQueue.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CorporateTokens.surfaceTop,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: CorporateTokens.borderSoft),
              ),
              child: const Text(
                'No hay trabajos pendientes en cola.',
                style: TextStyle(color: CorporateTokens.slate300, fontSize: 12),
              ),
            )
          else
            ...state.despachoQueue.map(
              (job) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildQueueItem(job, notifier, state.isBusy),
              ),
            ),
          if (telemetry.lastError.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
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
        ],
      ),
    );
  }

  Widget _buildQueueItem(
    DespachoQueueJobModel job,
    GestionStockTelasNotifier notifier,
    bool isBusy,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
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
                  '${job.rollos.length} rollo(s) | ${job.destino}',
                  style: const TextStyle(
                    color: CorporateTokens.navy900,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Metros: ${job.totalMetros.toStringAsFixed(2)} | Peso: ${job.totalPeso.toStringAsFixed(2)}',
                  style: const TextStyle(color: CorporateTokens.slate500, fontSize: 11),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_formatDate(job.createdAtIso)} | Reintentos: ${job.attempts}',
                  style: const TextStyle(color: CorporateTokens.slate300, fontSize: 10),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: isBusy ? null : () => notifier.quitarTrabajoCola(job.id),
            icon: const Icon(Icons.close_rounded, color: CorporateTokens.slate500),
          ),
        ],
      ),
    );
  }

  Widget _telemetryChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: CorporateTokens.surfaceBottom,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: CorporateTokens.borderSoft),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: CorporateTokens.slate700,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildRolloItem(
    dynamic item,
    GestionStockTelasNotifier notifier,
    bool isBusy,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
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
                    item.codigo,
                    style: const TextStyle(
                      color: CorporateTokens.navy900,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.articulo,
                    style: const TextStyle(color: CorporateTokens.slate500, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.metraje} m | ${item.peso} kg | ${item.ubicacion}',
                    style: const TextStyle(color: CorporateTokens.slate300, fontSize: 11),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed:
                  isBusy ? null : () => notifier.quitarRollo(item.codigo),
              icon: const Icon(Icons.close_rounded, color: CorporateTokens.slate500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard({required String title, required Widget child}) {
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

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?>? onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items:
          items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(item, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
      onChanged: onChanged,
      icon: const Icon(Icons.expand_more_rounded, color: CorporateTokens.slate500),
      dropdownColor: Colors.white,
      style: const TextStyle(color: CorporateTokens.navy900),
      decoration: _inputDecoration(
        label: label,
        hint: '',
        icon: Icons.tune_rounded,
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 74,
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
    );
  }

  String _formatDate(String iso) {
    final date = DateTime.tryParse(iso);
    if (date == null) return '-';

    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yy = date.year;
    final hh = date.hour.toString().padLeft(2, '0');
    final mi = date.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yy $hh:$mi';
  }
}
