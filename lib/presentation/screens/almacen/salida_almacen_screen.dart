import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/almacen_mov_queue_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/salida_almacen_provider.dart';
import '../../widgets/enterprise_backdrop.dart';
import '../../widgets/production/production_visuals.dart';
import '../../widgets/scanner/qr_scanner_page.dart';

class SalidaAlmacenScreen extends ConsumerStatefulWidget {
  const SalidaAlmacenScreen({super.key});

  @override
  ConsumerState<SalidaAlmacenScreen> createState() =>
      _SalidaAlmacenScreenState();
}

class _SalidaAlmacenScreenState extends ConsumerState<SalidaAlmacenScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _guiaController;
  late final TextEditingController _ocController;
  late final AnimationController _entryController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _guiaController = TextEditingController();
    _ocController = TextEditingController();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(_fadeAnimation);
  }

  @override
  void dispose() {
    _guiaController.dispose();
    _ocController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(salidaAlmacenProvider);
    final notifier = ref.read(salidaAlmacenProvider.notifier);
    final usuario = ref.watch(authProvider).user?.usuario ?? 'OPERARIO';
    _syncControllers(state);

    final plantas = _mergeOptions(state.plantasDisponibles, <String>[
      state.form.planta,
    ]);
    final ubicaciones = _mergeOptions(state.ubicacionesDisponibles, <String>[
      state.form.nuevaUbicacion,
    ]);

    final selectedPlanta = _safeSelection(
      selected: state.form.planta,
      options: plantas,
      fallback: 'PLANTA 1',
    );
    final selectedUbicacion = _safeSelection(
      selected: state.form.nuevaUbicacion,
      options: ubicaciones,
      fallback: 'URDIDO 1 (VERDE)',
    );

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: EnterpriseBackdrop()),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxWidth =
                        constraints.maxWidth >= 980
                            ? 860.0
                            : (constraints.maxWidth >= 700 ? 760.0 : 560.0);

                    return Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
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
                                      _buildFlowGuide(state),
                                      const SizedBox(height: 10),
                                      _buildScanPanel(
                                        state: state,
                                        usuario: usuario,
                                        onScan:
                                            () => _scanCodigo(notifier, state),
                                      ),
                                      const SizedBox(height: 10),
                                      if (!state.hasQrValido) ...[
                                        _buildStartHint(),
                                        const SizedBox(height: 10),
                                      ] else ...[
                                        _buildKardexPanel(state),
                                        const SizedBox(height: 10),
                                        _buildDataCard(
                                          title: 'Datos del codigo escaneado',
                                          children: [
                                            _buildReadOnlyNotice(),
                                            const SizedBox(height: 10),
                                            _buildFieldGrid(state),
                                            const SizedBox(height: 10),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: _readonlyField(
                                                    'Fecha salida',
                                                    state.form.fechaSalida,
                                                    icon: Icons.today_rounded,
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: _readonlyField(
                                                    'Hora salida',
                                                    state.form.horaSalida,
                                                    icon:
                                                        Icons.schedule_rounded,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        _buildDataCard(
                                          title: 'Ubicacion operativa',
                                          children: [
                                            _buildUltimaUbicacion(state),
                                            const SizedBox(height: 10),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: _dropdownField(
                                                    label: 'Planta',
                                                    value: selectedPlanta,
                                                    options: plantas,
                                                    onChanged:
                                                        state.isBusy
                                                            ? null
                                                            : notifier
                                                                .actualizarPlanta,
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: _dropdownField(
                                                    label: 'Nueva ubicacion',
                                                    value: selectedUbicacion,
                                                    options: ubicaciones,
                                                    onChanged:
                                                        state.isBusy
                                                            ? null
                                                            : notifier
                                                                .actualizarUbicacion,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            Container(
                                              width: double.infinity,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 8,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF8FAFC),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                  color:
                                                      CorporateTokens
                                                          .borderSoft,
                                                ),
                                              ),
                                              child: Text(
                                                _requiredHint(state),
                                                style: const TextStyle(
                                                  color:
                                                      CorporateTokens.slate500,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            if (state.muestraPickerVenta) ...[
                                              _selectionField(
                                                label: 'Hacia *',
                                                value:
                                                    state.form.destinoVenta
                                                            .trim()
                                                            .isNotEmpty
                                                        ? state
                                                            .form
                                                            .destinoVenta
                                                        : '-',
                                                icon: Icons.business_rounded,
                                                onTap:
                                                    state.isBusy
                                                        ? null
                                                        : () => _openSearchPicker(
                                                          title:
                                                              'Seleccionar destino (venta)',
                                                          options:
                                                              state
                                                                  .destinosVentaDisponibles,
                                                          selected:
                                                              state
                                                                  .form
                                                                  .destinoVenta,
                                                          onSelected:
                                                              notifier
                                                                  .actualizarDestinoVenta,
                                                        ),
                                              ),
                                              const SizedBox(height: 10),
                                            ],
                                            if (state.muestraPickerCliente) ...[
                                              _selectionField(
                                                label: 'Cliente *',
                                                value:
                                                    state.form.destinoCliente
                                                            .trim()
                                                            .isNotEmpty
                                                        ? state
                                                            .form
                                                            .destinoCliente
                                                        : '-',
                                                icon: Icons.store_rounded,
                                                onTap:
                                                    state.isBusy
                                                        ? null
                                                        : () => _openSearchPicker(
                                                          title:
                                                              'Seleccionar cliente',
                                                          options:
                                                              state
                                                                  .destinosClienteDisponibles,
                                                          selected:
                                                              state
                                                                  .form
                                                                  .destinoCliente,
                                                          onSelected:
                                                              notifier
                                                                  .actualizarDestinoCliente,
                                                        ),
                                              ),
                                              const SizedBox(height: 10),
                                            ],
                                            if (state.muestraNumeroGuia) ...[
                                              TextField(
                                                controller: _guiaController,
                                                enabled: !state.isBusy,
                                                onChanged:
                                                    notifier
                                                        .actualizarNumeroGuia,
                                                decoration: _inputDecoration(
                                                  label: 'Numero de guia *',
                                                  icon:
                                                      Icons
                                                          .receipt_long_rounded,
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                            ],
                                            if (state.muestraOrdenCompra) ...[
                                              TextField(
                                                controller: _ocController,
                                                enabled: !state.isBusy,
                                                onChanged:
                                                    notifier
                                                        .actualizarOrdenCompra,
                                                decoration: _inputDecoration(
                                                  label:
                                                      'Orden de compra (OC) *',
                                                  icon:
                                                      Icons.assignment_rounded,
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                            ],
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color:
                                                    CorporateTokens.surfaceTop,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color:
                                                      CorporateTokens
                                                          .borderSoft,
                                                ),
                                              ),
                                              child: Text(
                                                'Ubicacion payload: ${_safe(state.ubicacionPayload)}',
                                                style: const TextStyle(
                                                  color:
                                                      CorporateTokens.slate700,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                TextButton.icon(
                                                  onPressed:
                                                      state.isBusy ||
                                                              state
                                                                  .catalogosCargando
                                                          ? null
                                                          : () =>
                                                              notifier
                                                                  .cargarCatalogosDestino(),
                                                  icon:
                                                      state.catalogosCargando
                                                          ? const SizedBox(
                                                            width: 14,
                                                            height: 14,
                                                            child:
                                                                CircularProgressIndicator(
                                                                  strokeWidth:
                                                                      2,
                                                                ),
                                                          )
                                                          : const Icon(
                                                            Icons.sync_rounded,
                                                          ),
                                                  label: const Text(
                                                    'Recargar catalogos',
                                                  ),
                                                ),
                                                const Spacer(),
                                                Text(
                                                  'Venta ${state.destinosVentaDisponibles.length} | Cliente ${state.destinosClienteDisponibles.length}',
                                                  style: const TextStyle(
                                                    color:
                                                        CorporateTokens
                                                            .slate300,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        _buildSmartAlerts(state),
                                        const SizedBox(height: 10),
                                      ],
                                      _buildQueueCard(state, notifier),
                                      const SizedBox(height: 12),
                                      if (state.hasQrValido)
                                        _buildActionButtons(
                                          state: state,
                                          onConsultar:
                                              () =>
                                                  notifier
                                                      .consultarUltimaUbicacion(),
                                          onEnviar: () async {
                                            final confirmed =
                                                await _confirmarSalida(
                                                  state: state,
                                                  usuario: usuario,
                                                );
                                            if (!confirmed) return;
                                            await notifier.enviarSalida(
                                              usuario: usuario,
                                            );
                                          },
                                          onLimpiar: notifier.limpiarFormulario,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _scanCodigo(
    SalidaAlmacenNotifier notifier,
    SalidaAlmacenState state,
  ) async {
    if (state.isBusy) return;

    final scanned = await openQrScanner(
      context,
      title: 'Escanear QR de salida',
    );
    if (!mounted || scanned == null || scanned.trim().isEmpty) return;
    await notifier.procesarQrEscaneado(scanned.trim());
  }

  Widget _buildHeader(BuildContext context) {
    return ProductionHeader(
      title: 'Salida de Almacen',
      subtitle: 'Escaneo, ubicacion destino y validacion segura',
      icon: Icons.local_shipping_rounded,
      onBack: () => Navigator.pop(context),
      accentColor: const Color(0xFF2F7C92),
    );
  }

  Widget _buildStatusBanner(SalidaAlmacenState state) {
    return ProductionStatusBanner(
      message: state.infoMessage,
      errorMessage: state.errorMessage,
    );
  }

  Widget _buildStartHint() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CorporateTokens.borderSoft),
        boxShadow: CorporateTokens.cardShadow,
      ),
      child: const Row(
        children: [
          Icon(Icons.touch_app_rounded, color: CorporateTokens.cobalt600),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Escanee el QR del rollo. Despues se habilitan validacion, destino y envio.',
              style: TextStyle(
                color: CorporateTokens.navy900,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_rounded, size: 16, color: CorporateTokens.cobalt600),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Datos bloqueados por QR: se muestran para revision y no se editan en esta salida.',
              style: TextStyle(
                color: CorporateTokens.navy900,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartAlerts(SalidaAlmacenState state) {
    final alerts = _smartAlerts(state);
    if (alerts.isEmpty) return const SizedBox.shrink();

    return AnimatedSwitcher(
      duration: CorporateTokens.motionFast,
      child: Container(
        key: ValueKey(alerts.join('|')),
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CorporateTokens.borderSoft),
          boxShadow: CorporateTokens.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Alertas inteligentes',
              style: TextStyle(
                color: CorporateTokens.navy900,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            ...alerts.map(_buildAlertLine),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertLine(_SalidaSmartAlert alert) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: alert.color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(alert.icon, color: alert.color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              alert.message,
              style: const TextStyle(
                color: CorporateTokens.navy900,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlowGuide(SalidaAlmacenState state) {
    final scanned = state.hasQrValido;
    final ubicacionConsultada = state.ultimaUbicacion != null;
    final destinoCompleto =
        state.form.nuevaUbicacion.trim().isNotEmpty &&
        state.ubicacionPayload.trim().isNotEmpty;
    final ready = state.isFormValid;
    final hasError = (state.errorMessage ?? '').trim().isNotEmpty;

    final signal =
        hasError
            ? OperationSignalLevel.error
            : (ready
                ? OperationSignalLevel.ready
                : (scanned
                    ? OperationSignalLevel.warning
                    : OperationSignalLevel.neutral));
    final statusLabel =
        hasError
            ? 'REVISAR'
            : (ready ? 'LISTO' : (scanned ? 'EN PROCESO' : 'PENDIENTE'));
    final helper =
        hasError
            ? state.errorMessage!.trim()
            : !scanned
            ? 'Escanee el QR del rollo para llenar los datos automaticamente.'
            : !ubicacionConsultada
            ? 'Consulte la ultima ubicacion antes de enviar el movimiento.'
            : !ready
            ? _requiredHint(state)
            : 'Operacion lista. Revise el resumen final y envie.';

    return OperationFlowGuide(
      title: 'Guia operativa de salida',
      statusLabel: statusLabel,
      helperText: helper,
      signal: signal,
      accentColor: const Color(0xFF2F7C92),
      steps: [
        OperationStepData(
          label: 'Escanear QR',
          icon: Icons.qr_code_scanner_rounded,
          done: scanned,
          active: !scanned,
        ),
        OperationStepData(
          label: 'Verificar ubicacion',
          icon: Icons.location_searching_rounded,
          done: ubicacionConsultada,
          active: scanned && !ubicacionConsultada,
        ),
        OperationStepData(
          label: 'Completar destino',
          icon: Icons.pin_drop_rounded,
          done: destinoCompleto,
          active: scanned && ubicacionConsultada && !destinoCompleto,
        ),
        OperationStepData(
          label: 'Validar y enviar',
          icon: Icons.send_rounded,
          done: ready,
          active: ready,
        ),
      ],
      summary: [
        OperationSummaryItem(
          label: 'PCP',
          value: state.form.codigoPcp,
          icon: Icons.confirmation_number_rounded,
        ),
        OperationSummaryItem(
          label: 'Kardex',
          value: state.form.codigoKardex,
          icon: Icons.qr_code_2_rounded,
        ),
        OperationSummaryItem(
          label: 'Destino',
          value: state.ubicacionPayload,
          icon: Icons.place_rounded,
        ),
        OperationSummaryItem(
          label: 'Guia / OC',
          value: [
            state.form.numeroGuia.trim(),
            state.form.ordenCompra.trim(),
          ].where((item) => item.isNotEmpty).join(' / '),
          icon: Icons.receipt_long_rounded,
        ),
      ],
    );
  }

  Widget _buildScanPanel({
    required SalidaAlmacenState state,
    required String usuario,
    required VoidCallback onScan,
  }) {
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
            state.hasQrValido ? 'QR cargado' : 'Paso 1: Escanear QR',
            style: const TextStyle(
              color: CorporateTokens.navy900,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: CorporateTokens.primaryButtonGradient,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: state.isBusy ? null : onScan,
                    icon:
                        state.status == SalidaStatus.parsingQr
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Icon(Icons.qr_code_scanner_rounded),
                    label: Text(
                      state.hasQrValido ? 'Reescanear QR' : 'Escanear QR',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(46),
                      disabledBackgroundColor: Colors.transparent,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: CorporateTokens.surfaceBottom,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  state.hasQrValido ? 'QR ${state.form.qrCampos}' : 'Sin QR',
                  style: const TextStyle(
                    color: CorporateTokens.cobalt600,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _chip('Usuario: $usuario'),
              _chip(state.form.movimiento),
              _chip('Modo: SALIDA'),
              _chip(
                state.catalogosCargando
                    ? 'Catalogos destino...'
                    : 'Catalogos OK',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKardexPanel(SalidaAlmacenState state) {
    if (!state.muestraKardex) {
      return const SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CorporateTokens.borderSoft),
      ),
      child: Row(
        children: [
          const Icon(Icons.confirmation_number_rounded, size: 18),
          const SizedBox(width: 8),
          const Text(
            'Codigo Kardex:',
            style: TextStyle(
              color: CorporateTokens.navy900,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _safe(state.form.codigoKardex),
              style: const TextStyle(
                color: CorporateTokens.navy900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldGrid(SalidaAlmacenState state) {
    final items = <MapEntry<String, String>>[
      MapEntry('Codigo PCP', state.form.codigoPcp),
      MapEntry('Material', state.form.material),
      MapEntry('Titulo', state.form.titulo),
      MapEntry('Color', state.form.color),
      MapEntry('Lote', state.form.lote),
      MapEntry('Num caja', state.form.numCaja),
      MapEntry('Servicio', state.form.servicio),
    ];

    return Wrap(
      runSpacing: 10,
      spacing: 10,
      children:
          items.map((entry) {
            return SizedBox(
              width: 320,
              child: _readonlyField(entry.key, entry.value),
            );
          }).toList(),
    );
  }

  Widget _readonlyField(String label, String value, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: CorporateTokens.surfaceTop,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CorporateTokens.borderSoft),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: CorporateTokens.slate500),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: CorporateTokens.slate500,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _safe(value),
                  style: const TextStyle(
                    color: CorporateTokens.navy900,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataCard({
    required String title,
    required List<Widget> children,
  }) {
    return ProductionCard(
      title: title,
      icon: _dataCardIcon(title),
      accentColor: const Color(0xFF2F7C92),
      children: children,
    );
  }

  IconData _dataCardIcon(String title) {
    final value = title.toLowerCase();
    if (value.contains('ubicacion')) return Icons.pin_drop_rounded;
    if (value.contains('codigo')) return Icons.inventory_2_rounded;
    return Icons.assignment_rounded;
  }

  Widget _buildUltimaUbicacion(SalidaAlmacenState state) {
    final ubicacion = state.ultimaUbicacion;
    if (ubicacion == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: CorporateTokens.surfaceBottom,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Ultima ubicacion registrada: sin consulta reciente',
          style: TextStyle(color: CorporateTokens.slate500, fontSize: 12),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: CorporateTokens.surfaceBottom,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Ultima ubicacion registrada: ${_safe(ubicacion.almacen)} / ${_safe(ubicacion.ubicacion)}',
        style: const TextStyle(
          color: CorporateTokens.navy900,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _dropdownField({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String>? onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: options.contains(value) ? value : options.first,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: CorporateTokens.slate500),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CorporateTokens.borderSoft),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: CorporateTokens.cobalt600,
            width: 1.5,
          ),
        ),
      ),
      items:
          options
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
      onChanged: (next) {
        if (next == null || onChanged == null) return;
        onChanged(next);
      },
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: CorporateTokens.slate500),
      prefixIcon: Icon(icon, color: CorporateTokens.slate500),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: CorporateTokens.borderSoft),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: CorporateTokens.cobalt600,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _selectionField({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CorporateTokens.borderSoft),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: CorporateTokens.slate500),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: CorporateTokens.slate500,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
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
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: CorporateTokens.slate500,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueCard(
    SalidaAlmacenState state,
    SalidaAlmacenNotifier notifier,
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
                'Cola offline de salidas',
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
              _chip('Encolados ${telemetry.enqueuedTotal}'),
              _chip('Procesados ${telemetry.processedTotal}'),
              _chip('Fallos ${telemetry.failedAttemptsTotal}'),
              _chip('Reintentos ${telemetry.retryAttemptsTotal}'),
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
                      state.status == SalidaStatus.drainingQueue
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
                  side: BorderSide(
                    color: CorporateTokens.cobalt600.withValues(alpha: 0.30),
                  ),
                  minimumSize: const Size(48, 40),
                ),
                child: const Icon(Icons.delete_sweep_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (state.queue.isEmpty)
            const Text(
              'No hay movimientos pendientes.',
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
    SalidaQueueJobModel job,
    SalidaAlmacenNotifier notifier,
    bool isBusy,
  ) {
    final qrLabel = job.qrCampos > 0 ? 'QR ${job.qrCampos}' : 'Legacy';
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
                  '$qrLabel | ${_formatDate(job.createdAtIso)} | Guia: ${_safe(job.numeroGuia)} | Reintentos: ${job.attempts}',
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

  Widget _buildActionButtons({
    required SalidaAlmacenState state,
    required Future<void> Function() onConsultar,
    required Future<void> Function() onEnviar,
    required VoidCallback onLimpiar,
  }) {
    final isBusy = state.isBusy;
    final needsUbicacion = state.ultimaUbicacion == null;
    final canSend = !isBusy && state.isFormValid;

    return Column(
      children: [
        _buildSendSummary(state),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: CorporateTokens.motionFast,
          child:
              needsUbicacion
                  ? _contextPrimaryButton(
                    key: const ValueKey('consultar-ubicacion'),
                    onPressed: isBusy ? null : onConsultar,
                    icon:
                        state.status == SalidaStatus.consultandoUbicacion
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Icon(Icons.location_searching_rounded),
                    label:
                        state.status == SalidaStatus.consultandoUbicacion
                            ? 'Consultando ubicacion...'
                            : 'Paso 2: consultar ubicacion actual',
                  )
                  : canSend
                  ? _contextPrimaryButton(
                    key: const ValueKey('enviar-salida'),
                    onPressed: onEnviar,
                    icon:
                        state.status == SalidaStatus.validandoMovimiento ||
                                state.status == SalidaStatus.enviando
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Icon(Icons.verified_user_rounded),
                    label:
                        state.status == SalidaStatus.validandoMovimiento
                            ? 'Validando movimiento...'
                            : state.status == SalidaStatus.enviando
                            ? 'Enviando salida...'
                            : 'Paso 4: revisar y enviar',
                  )
                  : _disabledContextButton(
                    key: const ValueKey('completar-datos'),
                    label: 'Paso 3: complete los datos requeridos',
                  ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                state.hasQrValido
                    ? 'QR detectado: ${state.form.qrCampos} campos | Destino: ${_safe(state.ubicacionPayload)}'
                    : 'Escanee un QR para habilitar envio',
                style: const TextStyle(
                  color: CorporateTokens.slate500,
                  fontSize: 11,
                ),
              ),
            ),
            TextButton(
              onPressed: isBusy ? null : onLimpiar,
              child: const Text('Limpiar'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _contextPrimaryButton({
    required Key key,
    required Future<void> Function()? onPressed,
    required Widget icon,
    required String label,
  }) {
    return DecoratedBox(
      key: key,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: CorporateTokens.primaryButtonGradient,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332563EB),
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon,
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          disabledBackgroundColor: Colors.transparent,
        ),
      ),
    );
  }

  Widget _disabledContextButton({required Key key, required String label}) {
    return Container(
      key: key,
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CorporateTokens.borderSoft),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.edit_note_rounded, color: CorporateTokens.slate500),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: CorporateTokens.slate500,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSendSummary(SalidaAlmacenState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              state.isFormValid
                  ? const Color(0xFF86EFAC)
                  : CorporateTokens.borderSoft,
        ),
      ),
      child: Row(
        children: [
          Icon(
            state.isFormValid
                ? Icons.verified_rounded
                : Icons.info_outline_rounded,
            color:
                state.isFormValid
                    ? const Color(0xFF16A34A)
                    : CorporateTokens.slate500,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Resumen final: PCP ${_safe(state.form.codigoPcp)} -> ${_safe(state.ubicacionPayload)} | Guia ${_safe(state.form.numeroGuia)} | OC ${_safe(state.form.ordenCompra)}',
              style: const TextStyle(
                color: CorporateTokens.navy900,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmarSalida({
    required SalidaAlmacenState state,
    required String usuario,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          titlePadding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
          contentPadding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
          actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  color: Color(0xFF16A34A),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Confirmar salida',
                  style: TextStyle(
                    color: CorporateTokens.navy900,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Revise estos datos antes de registrar el movimiento.',
                  style: TextStyle(
                    color: CorporateTokens.slate500,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _confirmRow('Codigo PCP', state.form.codigoPcp),
                _confirmRow(
                  'Ubicacion actual',
                  state.ultimaUbicacion == null
                      ? 'Sin consulta'
                      : '${state.ultimaUbicacion!.almacen} / ${state.ultimaUbicacion!.ubicacion}',
                ),
                _confirmRow('Nueva ubicacion', state.ubicacionPayload),
                _confirmRow('Usuario', usuario),
                _confirmRow(
                  'Fecha y hora',
                  '${state.form.fechaSalida} ${state.form.horaSalida}',
                ),
                if (state.form.numeroGuia.trim().isNotEmpty)
                  _confirmRow('Numero de guia', state.form.numeroGuia),
                if (state.form.ordenCompra.trim().isNotEmpty)
                  _confirmRow('OC', state.form.ordenCompra),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Revisar'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.send_rounded),
              label: const Text('Confirmar envio'),
              style: ElevatedButton.styleFrom(
                backgroundColor: CorporateTokens.cobalt600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );

    return confirmed == true;
  }

  Widget _confirmRow(String label, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CorporateTokens.borderSoft),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 126,
            child: Text(
              label,
              style: const TextStyle(
                color: CorporateTokens.slate500,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              _safe(value),
              style: const TextStyle(
                color: CorporateTokens.navy900,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _syncControllers(SalidaAlmacenState state) {
    if (_guiaController.text != state.form.numeroGuia) {
      _guiaController.text = state.form.numeroGuia;
      _guiaController.selection = TextSelection.fromPosition(
        TextPosition(offset: _guiaController.text.length),
      );
    }
    if (_ocController.text != state.form.ordenCompra) {
      _ocController.text = state.form.ordenCompra;
      _ocController.selection = TextSelection.fromPosition(
        TextPosition(offset: _ocController.text.length),
      );
    }
  }

  Future<void> _openSearchPicker({
    required String title,
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelected,
  }) async {
    final cleanOptions = options
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    if (cleanOptions.isEmpty) {
      return;
    }

    String query = '';
    final picked = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final filtered = cleanOptions
                .where(
                  (item) =>
                      query.trim().isEmpty ||
                      item.toLowerCase().contains(query.toLowerCase()),
                )
                .toList(growable: false);
            return AlertDialog(
              titlePadding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              title: Text(title, style: const TextStyle(fontSize: 15)),
              content: SizedBox(
                width: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Buscar...',
                        isDense: true,
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (value) => setState(() => query = value),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 320,
                      child: ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, index) {
                          final option = filtered[index];
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading:
                                option == selected
                                    ? const Icon(
                                      Icons.check_circle_rounded,
                                      color: CorporateTokens.cobalt600,
                                    )
                                    : const Icon(
                                      Icons.circle_outlined,
                                      color: CorporateTokens.slate300,
                                    ),
                            title: Text(
                              option,
                              style: const TextStyle(fontSize: 13),
                            ),
                            onTap:
                                () => Navigator.of(dialogContext).pop(option),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (picked == null) return;
    onSelected(picked);
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: CorporateTokens.surfaceBottom,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: CorporateTokens.slate700,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _requiredHint(SalidaAlmacenState state) {
    if (state.muestraPickerVenta) {
      return 'Obligatorio: Hacia, Numero de guia y Orden de compra (OC).';
    }
    if (state.muestraPickerCliente) {
      return 'Obligatorio: Cliente y Numero de guia.';
    }
    if (state.muestraNumeroGuia) {
      return 'Obligatorio: Numero de guia.';
    }
    return 'Obligatorio: QR valido y ubicacion operativa.';
  }

  List<_SalidaSmartAlert> _smartAlerts(SalidaAlmacenState state) {
    final alerts = <_SalidaSmartAlert>[];
    final error = (state.errorMessage ?? '').trim();

    if (error.isNotEmpty) {
      alerts.add(
        _SalidaSmartAlert(
          icon: Icons.error_outline_rounded,
          color: const Color(0xFFDC2626),
          message: _stockErrorMessage(error),
        ),
      );
    }

    if (state.hasQrValido && state.ultimaUbicacion == null) {
      alerts.add(
        const _SalidaSmartAlert(
          icon: Icons.location_off_rounded,
          color: Color(0xFFF59E0B),
          message:
              'Aun no se confirma ubicacion en Stock Actual. Consulte antes de enviar.',
        ),
      );
    }

    final ultima = state.ultimaUbicacion;
    if (ultima != null && _looksLikeSalida(ultima.ubicacion)) {
      alerts.add(
        _SalidaSmartAlert(
          icon: Icons.warning_amber_rounded,
          color: const Color(0xFFF59E0B),
          message:
              'Este rollo ya figura en ${ultima.ubicacion}. Revise si realmente debe moverse otra vez.',
        ),
      );
    }

    if (state.muestraPickerVenta && state.form.destinoVenta.trim().isEmpty) {
      alerts.add(
        const _SalidaSmartAlert(
          icon: Icons.business_rounded,
          color: Color(0xFFDC2626),
          message: 'Falta destino venta. Seleccione proveedor o cliente real.',
        ),
      );
    }

    if (state.muestraPickerVenta &&
        _looksLikeCatalogHeader(state.form.destinoVenta)) {
      alerts.add(
        const _SalidaSmartAlert(
          icon: Icons.rule_rounded,
          color: Color(0xFFF59E0B),
          message:
              'Destino venta parece encabezado de catalogo. Si corresponde, seleccione el proveedor exacto.',
        ),
      );
    }

    if (state.muestraNumeroGuia && state.form.numeroGuia.trim().isEmpty) {
      alerts.add(
        const _SalidaSmartAlert(
          icon: Icons.receipt_long_rounded,
          color: Color(0xFFDC2626),
          message: 'Falta numero de guia para este tipo de salida.',
        ),
      );
    }

    if (state.muestraOrdenCompra && state.form.ordenCompra.trim().isEmpty) {
      alerts.add(
        const _SalidaSmartAlert(
          icon: Icons.assignment_rounded,
          color: Color(0xFFDC2626),
          message: 'Falta Orden de Compra (OC) para salida a venta.',
        ),
      );
    }

    if (state.isFormValid && error.isEmpty) {
      alerts.add(
        const _SalidaSmartAlert(
          icon: Icons.check_circle_rounded,
          color: Color(0xFF16A34A),
          message: 'Datos completos. Puede revisar y enviar la salida.',
        ),
      );
    }

    return alerts;
  }

  String _stockErrorMessage(String error) {
    final normalized = error.toLowerCase();
    if (normalized.contains('stock') ||
        normalized.contains('no se encuentra') ||
        normalized.contains('no encontrado')) {
      return 'El QR no pertenece al Stock Actual o no fue encontrado. Revise PCP/Kardex.';
    }
    if (normalized.contains('api local') ||
        normalized.contains('impresion') ||
        normalized.contains('192.168.')) {
      return 'La API local de impresion no esta disponible. Revise red o servidor local.';
    }
    return error;
  }

  bool _looksLikeSalida(String value) {
    final text = value.trim().toUpperCase();
    return text.contains('VENTA') ||
        text.contains('SALIDA') ||
        text.contains('DESPACH') ||
        text.contains('DEVOLUCION');
  }

  bool _looksLikeCatalogHeader(String value) {
    final text = value.trim().toUpperCase();
    return text == 'PROVEDORES DE VENTA' ||
        text == 'PROVEEDORES DE VENTA' ||
        text == 'CLIENTES' ||
        text == 'PROVEEDORES';
  }

  String _safe(String value) {
    final cleaned = value.trim();
    return cleaned.isEmpty ? '-' : cleaned;
  }

  String _safeSelection({
    required String selected,
    required List<String> options,
    required String fallback,
  }) {
    if (options.isEmpty) {
      return fallback;
    }
    if (options.contains(selected)) {
      return selected;
    }
    if (options.contains(fallback)) {
      return fallback;
    }
    return options.first;
  }

  List<String> _mergeOptions(List<String> base, List<String> extras) {
    final merged = <String>[...base];
    for (final extra in extras) {
      final clean = extra.trim();
      if (clean.isNotEmpty && !merged.contains(clean)) {
        merged.add(clean);
      }
    }
    return merged;
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

class _SalidaSmartAlert {
  final IconData icon;
  final Color color;
  final String message;

  const _SalidaSmartAlert({
    required this.icon,
    required this.color,
    required this.message,
  });
}
