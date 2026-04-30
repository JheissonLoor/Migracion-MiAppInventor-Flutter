import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/almacen_mov_queue_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/salida_almacen_provider.dart';
import '../../widgets/enterprise_backdrop.dart';
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
                                      _buildScanPanel(
                                        state: state,
                                        usuario: usuario,
                                        onScan:
                                            () => _scanCodigo(notifier, state),
                                      ),
                                      const SizedBox(height: 10),
                                      _buildKardexPanel(state),
                                      const SizedBox(height: 10),
                                      _buildDataCard(
                                        title: 'Datos del codigo escaneado',
                                        children: [
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
                                                  icon: Icons.schedule_rounded,
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
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF8FAFC),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color:
                                                    CorporateTokens.borderSoft,
                                              ),
                                            ),
                                            child: Text(
                                              _requiredHint(state),
                                              style: const TextStyle(
                                                color: CorporateTokens.slate500,
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
                                                      ? state.form.destinoVenta
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
                                                  notifier.actualizarNumeroGuia,
                                              decoration: _inputDecoration(
                                                label: 'Numero de guia *',
                                                icon:
                                                    Icons.receipt_long_rounded,
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
                                                label: 'Orden de compra (OC) *',
                                                icon: Icons.assignment_rounded,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                          ],
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: CorporateTokens.surfaceTop,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color:
                                                    CorporateTokens.borderSoft,
                                              ),
                                            ),
                                            child: Text(
                                              'Ubicacion payload: ${_safe(state.ubicacionPayload)}',
                                              style: const TextStyle(
                                                color: CorporateTokens.slate700,
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
                                                                strokeWidth: 2,
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
                                                      CorporateTokens.slate300,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      _buildQueueCard(state, notifier),
                                      const SizedBox(height: 12),
                                      _buildActionButtons(
                                        state: state,
                                        onConsultar:
                                            () =>
                                                notifier
                                                    .consultarUltimaUbicacion(),
                                        onEnviar:
                                            () => notifier.enviarSalida(
                                              usuario: usuario,
                                            ),
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
                'Salida de Almacen',
                style: TextStyle(
                  color: CorporateTokens.navy900,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Flujo MIT 1:1: escaneo, validacion y envio seguro',
                style: TextStyle(color: CorporateTokens.slate500, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBanner(SalidaAlmacenState state) {
    final hasError = state.errorMessage?.trim().isNotEmpty == true;
    final hasInfo = state.infoMessage?.trim().isNotEmpty == true;
    if (!hasError && !hasInfo) {
      return const SizedBox.shrink();
    }

    final isError = hasError;
    final text = hasError ? state.errorMessage! : state.infoMessage!;

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
          const Text(
            'Escaneo de QR',
            style: TextStyle(
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
                    label: const Text('Escanear QR'),
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
    final canSend = !isBusy && state.isFormValid;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
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
            label: const Text('Consultar ultima ubicacion'),
            style: OutlinedButton.styleFrom(
              foregroundColor: CorporateTokens.cobalt600,
              side: BorderSide(
                color: CorporateTokens.cobalt600.withValues(alpha: 0.30),
              ),
              minimumSize: const Size.fromHeight(44),
            ),
          ),
        ),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: CorporateTokens.primaryButtonGradient,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ElevatedButton.icon(
            onPressed: canSend ? onEnviar : null,
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
                    : const Icon(Icons.send_rounded),
            label: Text(
              state.status == SalidaStatus.validandoMovimiento
                  ? 'Validando movimiento...'
                  : state.status == SalidaStatus.enviando
                  ? 'Enviando salida...'
                  : 'Validar y enviar salida',
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
