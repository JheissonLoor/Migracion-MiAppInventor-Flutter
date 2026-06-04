import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/produccion_queue_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/urdido_provider.dart';
import '../../widgets/enterprise_backdrop.dart';
import '../../widgets/production/production_visuals.dart';
import '../../widgets/scanner/qr_scanner_page.dart';

class UrdidoScreen extends ConsumerStatefulWidget {
  const UrdidoScreen({super.key});

  @override
  ConsumerState<UrdidoScreen> createState() => _UrdidoScreenState();
}

class _UrdidoScreenState extends ConsumerState<UrdidoScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers;
  late final AnimationController _entryController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    final initial = ref.read(urdidoProvider).fields;
    _controllers = {
      for (final key in _fieldKeys)
        key: TextEditingController(text: initial[key] ?? ''),
    };
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
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(urdidoProvider);
    final notifier = ref.read(urdidoProvider.notifier);
    final usuario = ref.watch(authProvider).user?.usuario ?? 'OPERARIO';
    final hasCodigo = _field(state, 'codigo_pcp').isNotEmpty;
    final hasPrecarga = _field(state, 'codigo_urdido').isNotEmpty;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    ref.listen<UrdidoState>(urdidoProvider, (previous, next) {
      if (!mounted) return;
      if (previous?.fields != next.fields) {
        _syncControllers(next.fields);
        _autofillDefaults(next, notifier, usuario);
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
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.only(bottom: 18 + bottomInset),
                  child: Column(
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 10),
                      _buildStatusBanner(state),
                      const SizedBox(height: 10),
                      Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: Column(
                          children: [
                            _buildFlowGuide(state),
                            const SizedBox(height: 10),
                            _buildScanCard(state, notifier),
                            const SizedBox(height: 10),
                            if (hasPrecarga) ...[
                              _buildSmartAlerts(state),
                              const SizedBox(height: 10),
                              _buildMainFormCard(state, notifier, usuario),
                              const SizedBox(height: 10),
                            ] else ...[
                              _buildLockedHint(
                                hasCodigo
                                    ? 'Presione "Precargar datos" para habilitar el formulario de urdido.'
                                    : 'Escanee o ingrese el codigo PCP para iniciar el registro.',
                              ),
                              const SizedBox(height: 10),
                            ],
                            _buildQueueCard(state, notifier),
                            const SizedBox(height: 12),
                            if (hasPrecarga)
                              _buildActionButtons(
                                state: state,
                                usuario: usuario,
                                onEnviar: () async {
                                  final confirmed = await _confirmarRegistro(
                                    state: state,
                                    usuario: usuario,
                                  );
                                  if (!confirmed) return;
                                  await notifier.enviarUrdido(usuario: usuario);
                                },
                                onLimpiar: () => _limpiar(notifier),
                              ),
                          ],
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

  Widget _buildHeader(BuildContext context) {
    return ProductionHeader(
      title: 'Urdido',
      subtitle: 'Escaneo, urdidora, metros y cola offline',
      icon: Icons.settings_rounded,
      onBack: () => Navigator.pop(context),
      accentColor: const Color(0xFFD48F54),
      trailing: IconButton(
        onPressed: () => Navigator.pushNamed(context, '/historial_urdido'),
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xFFF8FAFC),
          side: const BorderSide(color: CorporateTokens.borderSoft),
        ),
        icon: const Icon(
          Icons.inventory_rounded,
          color: CorporateTokens.navy900,
        ),
      ),
    );
  }

  Widget _buildStatusBanner(UrdidoState state) {
    return ProductionStatusBanner(
      message: state.message,
      errorMessage: state.errorMessage,
    );
  }

  Widget _buildLockedHint(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CorporateTokens.borderSoft),
        boxShadow: CorporateTokens.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.lock_clock_rounded,
              color: Color(0xFFD48F54),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: CorporateTokens.navy900,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartAlerts(UrdidoState state) {
    final alerts = <String>[];
    final error = (state.errorMessage ?? '').trim();
    if (error.isNotEmpty) alerts.add(error);
    if (_field(state, 'fecha_urdido').isEmpty) {
      alerts.add(
        'Fecha de urdido pendiente; se completa automaticamente al precargar.',
      );
    }
    if (_field(state, 'hora_inicio').isEmpty) {
      alerts.add(
        'Hora inicio pendiente; se completa automaticamente al precargar.',
      );
    }
    if (_field(state, 'codigo_urdido').isNotEmpty) {
      alerts.add(
        'Identificadores de urdido bloqueados por precarga para evitar errores.',
      );
    }
    if (_isUrdidoReady(state)) {
      alerts.add('Datos completos. Revise el resumen y envie el registro.');
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CorporateTokens.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Alertas operativas',
            style: TextStyle(
              color: CorporateTokens.navy900,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          ...alerts.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    item == error && error.isNotEmpty
                        ? Icons.error_outline_rounded
                        : Icons.info_outline_rounded,
                    size: 17,
                    color:
                        item == error && error.isNotEmpty
                            ? const Color(0xFFDC2626)
                            : const Color(0xFFD48F54),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: CorporateTokens.navy900,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
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

  Widget _buildFlowGuide(UrdidoState state) {
    final scanned = _field(state, 'codigo_pcp').isNotEmpty;
    final loaded = _field(state, 'codigo_urdido').isNotEmpty;
    final coreReady =
        loaded &&
        _field(state, 'turno').isNotEmpty &&
        _field(state, 'operario').isNotEmpty &&
        _field(state, 'orden_pedido').isNotEmpty &&
        _field(state, 'articulo').isNotEmpty &&
        _field(state, 'metros_urdido').isNotEmpty &&
        _field(state, 'num_plegador').isNotEmpty;
    final hasError = (state.errorMessage ?? '').trim().isNotEmpty;

    final signal =
        hasError
            ? OperationSignalLevel.error
            : (coreReady
                ? OperationSignalLevel.ready
                : (scanned
                    ? OperationSignalLevel.warning
                    : OperationSignalLevel.neutral));
    final helper =
        hasError
            ? state.errorMessage!.trim()
            : coreReady
            ? 'Formulario listo. Revise metros, plegador y operario antes de enviar.'
            : loaded
            ? 'Datos precargados. Complete campos obligatorios de urdido.'
            : scanned
            ? 'Codigo recibido. Precargue datos antes de registrar.'
            : 'Escanee el PCP para recuperar datos base del proceso.';

    return OperationFlowGuide(
      title: 'Guia operativa de urdido',
      statusLabel:
          hasError
              ? 'REVISAR'
              : (coreReady ? 'LISTO' : (scanned ? 'EN PROCESO' : 'PENDIENTE')),
      helperText: helper,
      signal: signal,
      accentColor: const Color(0xFFD48F54),
      steps: [
        OperationStepData(
          label: 'Escanear PCP',
          icon: Icons.qr_code_scanner_rounded,
          done: scanned,
          active: !scanned,
        ),
        OperationStepData(
          label: 'Precargar urdido',
          icon: Icons.manage_search_rounded,
          done: loaded,
          active: scanned && !loaded,
        ),
        OperationStepData(
          label: 'Completar produccion',
          icon: Icons.assignment_rounded,
          done: coreReady,
          active: loaded && !coreReady,
        ),
        OperationStepData(
          label: 'Enviar seguro',
          icon: Icons.send_rounded,
          done: coreReady,
          active: coreReady,
        ),
      ],
      summary: [
        OperationSummaryItem(
          label: 'PCP',
          value: _field(state, 'codigo_pcp'),
          icon: Icons.confirmation_number_rounded,
        ),
        OperationSummaryItem(
          label: 'Urdido',
          value: _field(state, 'codigo_urdido'),
          icon: Icons.tag_rounded,
        ),
        OperationSummaryItem(
          label: 'Articulo',
          value: _field(state, 'articulo'),
          icon: Icons.inventory_2_rounded,
        ),
        OperationSummaryItem(
          label: 'Metros / Plegador',
          value:
              '${_field(state, 'metros_urdido')} / ${_field(state, 'num_plegador')}',
          icon: Icons.timeline_rounded,
        ),
      ],
    );
  }

  Widget _buildScanCard(UrdidoState state, UrdidoNotifier notifier) {
    return _buildCard(
      title: 'Escaneo y precarga',
      children: [
        _buildTextField(
          keyName: 'codigo_pcp',
          label: 'Codigo PCP',
          hint: 'Ejemplo: PCP-2026-0001',
          icon: Icons.qr_code_2_rounded,
          notifier: notifier,
          validator: (value) => _required(value, 'codigo PCP'),
          suffixIcon: IconButton(
            onPressed: state.isBusy ? null : () => _scanQr(notifier),
            tooltip: 'Escanear con camara',
            icon: const Icon(
              Icons.camera_alt_rounded,
              color: CorporateTokens.slate500,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed:
                state.isBusy
                    ? null
                    : () => notifier.buscarDesdeQr(
                      _controllers['codigo_pcp']!.text,
                    ),
            icon:
                state.status == UrdidoStatus.loadingScanData
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.manage_search_rounded),
            label: const Text('Escanear y precargar datos de urdido'),
          ),
        ),
      ],
    );
  }

  Widget _buildMainFormCard(
    UrdidoState state,
    UrdidoNotifier notifier,
    String usuario,
  ) {
    final lockedByPrecarga = _field(state, 'codigo_urdido').isNotEmpty;
    return _buildCard(
      title: 'Formulario de Urdido',
      children: [
        _buildDropdownField(
          keyName: 'turno',
          label: 'Turno',
          options: const ['Manana', 'Noche'],
          notifier: notifier,
        ),
        const SizedBox(height: 8),
        _buildDropdownField(
          keyName: 'tipo_proceso',
          label: 'Tipo de proceso',
          options: const ['Produccion', 'Servicio'],
          notifier: notifier,
        ),
        const SizedBox(height: 8),
        _buildTextField(
          keyName: 'operario',
          label: 'Operario',
          hint: usuario,
          icon: Icons.person_rounded,
          notifier: notifier,
          validator: (value) => _required(value, 'operario'),
        ),
        const SizedBox(height: 8),
        _buildTextField(
          keyName: 'codigo_urdido',
          label: 'Codigo urdido',
          hint: 'Autocompletado por escaneo',
          icon: Icons.confirmation_number_rounded,
          notifier: notifier,
          readOnly: lockedByPrecarga,
          validator: (value) => _required(value, 'codigo urdido'),
        ),
        const SizedBox(height: 8),
        _buildTextField(
          keyName: 'orden_pedido',
          label: 'Orden de pedido',
          hint: 'Ejemplo: OP-4552',
          icon: Icons.assignment_rounded,
          notifier: notifier,
          readOnly: lockedByPrecarga,
          validator: (value) => _required(value, 'orden de pedido'),
        ),
        const SizedBox(height: 8),
        _buildDropdownField(
          keyName: 'articulo',
          label: 'Articulo',
          options: state.articulos,
          notifier: notifier,
          allowManual: true,
          enabled: !lockedByPrecarga,
        ),
        const SizedBox(height: 8),
        _buildDropdownField(
          keyName: 'titulo',
          label: 'Titulo',
          options: state.titulos,
          notifier: notifier,
          allowManual: true,
          enabled: !lockedByPrecarga,
        ),
        const SizedBox(height: 8),
        _buildDropdownField(
          keyName: 'material',
          label: 'Material',
          options: state.materiales,
          notifier: notifier,
          allowManual: true,
          enabled: !lockedByPrecarga,
        ),
        const SizedBox(height: 8),
        _buildTextField(
          keyName: 'fecha_urdido',
          label: 'Fecha urdido',
          hint: 'dd/mm/yyyy',
          icon: Icons.event_rounded,
          notifier: notifier,
          validator: (value) => _required(value, 'fecha urdido'),
        ),
        const SizedBox(height: 8),
        _buildTextField(
          keyName: 'hora_inicio',
          label: 'Hora inicio',
          hint: 'HH:MM',
          icon: Icons.schedule_rounded,
          notifier: notifier,
          validator: (value) => _required(value, 'hora inicio'),
        ),
        const SizedBox(height: 8),
        _buildTextField(
          keyName: 'hora_final',
          label: 'Hora final',
          hint: 'HH:MM',
          icon: Icons.schedule_send_rounded,
          notifier: notifier,
          validator: (value) => _required(value, 'hora final'),
        ),
        const SizedBox(height: 8),
        _buildTextField(
          keyName: 'cantidad_hilos',
          label: 'Cantidad de hilos',
          hint: 'Ejemplo: 4800',
          icon: Icons.numbers_rounded,
          notifier: notifier,
          validator: (value) => _required(value, 'cantidad de hilos'),
        ),
        const SizedBox(height: 8),
        _buildTextField(
          keyName: 'ancho_plegador',
          label: 'Ancho de plegador',
          hint: 'Ejemplo: 1.75',
          icon: Icons.straighten_rounded,
          notifier: notifier,
          validator: (value) => _required(value, 'ancho de plegador'),
        ),
        const SizedBox(height: 8),
        _buildTextField(
          keyName: 'metros_urdido',
          label: 'Metros urdidos',
          hint: 'Ejemplo: 12500',
          icon: Icons.timeline_rounded,
          notifier: notifier,
          validator: (value) => _required(value, 'metros urdidos'),
        ),
        const SizedBox(height: 8),
        _buildTextField(
          keyName: 'peso_hilos_urdido',
          label: 'Peso hilo urdido',
          hint: 'Ejemplo: 820',
          icon: Icons.scale_rounded,
          notifier: notifier,
          validator: (value) => _required(value, 'peso de hilos'),
        ),
        const SizedBox(height: 8),
        _buildTextField(
          keyName: 'num_plegador',
          label: 'Numero de plegador',
          hint: 'Ejemplo: 3',
          icon: Icons.format_list_numbered_rounded,
          notifier: notifier,
          validator: (value) => _required(value, 'numero de plegador'),
        ),
        const SizedBox(height: 12),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 8),
          title: const Text(
            'Campos avanzados',
            style: TextStyle(
              color: CorporateTokens.navy900,
              fontWeight: FontWeight.w700,
            ),
          ),
          children: [
            for (final field in _advancedFields) ...[
              _buildTextField(
                keyName: field.key,
                label: field.label,
                hint: 'Opcional',
                icon: field.icon,
                notifier: notifier,
                minLines: field.multiline ? 3 : 1,
                maxLines: field.multiline ? 4 : 1,
              ),
              const SizedBox(height: 8),
            ],
            for (int i = 1; i <= 7; i++) ...[
              _buildDropdownField(
                keyName: 'hilo_color$i',
                label: 'Hilo color $i',
                options: state.colores,
                notifier: notifier,
                allowManual: true,
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildQueueCard(UrdidoState state, UrdidoNotifier notifier) {
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
                'Cola offline de Urdido',
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
                      state.status == UrdidoStatus.drainingQueue
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
    UrdidoQueueJobModel job,
    UrdidoNotifier notifier,
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
                  '${job.codigoPcp} | ${job.codigoUrdido}',
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

  Widget _buildActionButtons({
    required UrdidoState state,
    required String usuario,
    required Future<void> Function() onEnviar,
    required VoidCallback onLimpiar,
  }) {
    final ready = _isUrdidoReady(state);
    return Column(
      children: [
        ready
            ? DecoratedBox(
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
                          await onEnviar();
                        },
                icon:
                    state.status == UrdidoStatus.sending
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.verified_user_rounded),
                label: Text(
                  state.status == UrdidoStatus.sending
                      ? 'Enviando urdido...'
                      : 'Revisar y registrar urdido',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  disabledBackgroundColor: Colors.transparent,
                ),
              ),
            )
            : _disabledContextButton('Complete campos obligatorios de urdido'),
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
    return ProductionCard(
      title: title,
      icon: _cardIcon(title),
      accentColor: const Color(0xFFD48F54),
      children: children,
    );
  }

  IconData _cardIcon(String title) {
    final value = title.toLowerCase();
    if (value.contains('escaneo')) return Icons.qr_code_scanner_rounded;
    if (value.contains('cola')) return Icons.sync_alt_rounded;
    if (value.contains('formulario')) return Icons.assignment_rounded;
    return Icons.view_agenda_rounded;
  }

  Widget _disabledContextButton(String label) {
    return Container(
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

  Widget _buildTextField({
    required String keyName,
    required String label,
    required String hint,
    required IconData icon,
    required UrdidoNotifier notifier,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    int minLines = 1,
    int maxLines = 1,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: _controllers[keyName],
      minLines: minLines,
      maxLines: maxLines,
      readOnly: readOnly,
      onChanged:
          readOnly ? null : (value) => notifier.actualizarCampo(keyName, value),
      validator: validator,
      style: const TextStyle(color: CorporateTokens.navy900),
      decoration: _inputDecoration(
        label: label,
        hint: hint,
        icon: icon,
        suffixIcon: suffixIcon,
      ),
    );
  }

  Widget _buildDropdownField({
    required String keyName,
    required String label,
    required List<String> options,
    required UrdidoNotifier notifier,
    bool allowManual = false,
    bool enabled = true,
  }) {
    final selected = _controllers[keyName]!.text.trim();
    final cleaned =
        options
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toSet()
            .toList();
    if (selected.isNotEmpty && !cleaned.contains(selected)) {
      cleaned.insert(0, selected);
    }

    if (cleaned.isEmpty || allowManual) {
      return _buildTextField(
        keyName: keyName,
        label: label,
        hint: 'Ingrese $label',
        icon: Icons.edit_note_rounded,
        notifier: notifier,
        readOnly: !enabled,
      );
    }

    return DropdownButtonFormField<String>(
      value: selected.isEmpty ? null : selected,
      onChanged:
          enabled
              ? (value) {
                final newValue = value ?? '';
                _controllers[keyName]!.text = newValue;
                notifier.actualizarCampo(keyName, newValue);
              }
              : null,
      items:
          cleaned
              .map(
                (item) =>
                    DropdownMenuItem<String>(value: item, child: Text(item)),
              )
              .toList(),
      decoration: _inputDecoration(
        label: label,
        hint: 'Seleccione $label',
        icon: Icons.arrow_drop_down_circle_rounded,
      ),
    );
  }

  Future<void> _scanQr(UrdidoNotifier notifier) async {
    final scanned = await openQrScanner(
      context,
      title: 'Escanear QR para Urdido',
    );
    if (!mounted || scanned == null || scanned.trim().isEmpty) return;
    _controllers['codigo_pcp']!.text = scanned.trim();
    notifier.actualizarCampo('codigo_pcp', scanned.trim());
    await notifier.buscarDesdeQr(scanned);
  }

  void _syncControllers(Map<String, String> fields) {
    for (final key in _fieldKeys) {
      final value = fields[key] ?? '';
      final controller = _controllers[key]!;
      if (controller.text != value) {
        controller.text = value;
      }
    }
  }

  void _autofillDefaults(
    UrdidoState state,
    UrdidoNotifier notifier,
    String usuario,
  ) {
    if (_field(state, 'codigo_urdido').isEmpty) return;
    if (_field(state, 'operario').isEmpty && usuario.trim().isNotEmpty) {
      _controllers['operario']!.text = usuario.trim();
      notifier.actualizarCampo('operario', usuario.trim());
    }
    if (_field(state, 'turno').isEmpty) {
      const value = 'Manana';
      _controllers['turno']!.text = value;
      notifier.actualizarCampo('turno', value);
    }
    if (_field(state, 'tipo_proceso').isEmpty) {
      const value = 'Produccion';
      _controllers['tipo_proceso']!.text = value;
      notifier.actualizarCampo('tipo_proceso', value);
    }
    final now = DateTime.now();
    if (_field(state, 'fecha_urdido').isEmpty) {
      final value = _formatLocalDate(now);
      _controllers['fecha_urdido']!.text = value;
      notifier.actualizarCampo('fecha_urdido', value);
    }
    if (_field(state, 'hora_inicio').isEmpty) {
      final value = _formatLocalTime(now);
      _controllers['hora_inicio']!.text = value;
      notifier.actualizarCampo('hora_inicio', value);
    }
  }

  void _limpiar(UrdidoNotifier notifier) {
    notifier.limpiarFormulario();
    for (final key in _fieldKeys) {
      _controllers[key]!.clear();
    }
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

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: CorporateTokens.slate500),
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

  String? _required(String? value, String field) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingrese $field';
    }
    return null;
  }

  String _field(UrdidoState state, String key) {
    return (state.fields[key] ?? _controllers[key]?.text ?? '').trim();
  }

  bool _isUrdidoReady(UrdidoState state) {
    final required = [
      'codigo_pcp',
      'codigo_urdido',
      'turno',
      'operario',
      'orden_pedido',
      'articulo',
      'tipo_proceso',
      'fecha_urdido',
      'cantidad_hilos',
      'hora_inicio',
      'hora_final',
      'ancho_plegador',
      'metros_urdido',
      'peso_hilos_urdido',
      'num_plegador',
      'titulo',
      'material',
    ];
    return required.every((key) => _field(state, key).isNotEmpty);
  }

  Future<bool> _confirmarRegistro({
    required UrdidoState state,
    required String usuario,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: const Text('Confirmar urdido'),
            content: SizedBox(
              width: 520,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _confirmRow('PCP', _field(state, 'codigo_pcp')),
                  _confirmRow('Codigo urdido', _field(state, 'codigo_urdido')),
                  _confirmRow('Articulo', _field(state, 'articulo')),
                  _confirmRow('Metros', _field(state, 'metros_urdido')),
                  _confirmRow('Plegador', _field(state, 'num_plegador')),
                  _confirmRow('Usuario', usuario),
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
                label: const Text('Confirmar registro'),
              ),
            ],
          ),
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
        children: [
          SizedBox(
            width: 120,
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
              value.trim().isEmpty ? '-' : value.trim(),
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

  String _formatLocalDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yy = date.year.toString();
    return '$dd/$mm/$yy';
  }

  String _formatLocalTime(DateTime date) {
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
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

class _AdvancedField {
  final String key;
  final String label;
  final IconData icon;
  final bool multiline;

  const _AdvancedField({
    required this.key,
    required this.label,
    required this.icon,
    this.multiline = false,
  });
}

const List<_AdvancedField> _advancedFields = [
  _AdvancedField(
    key: 'ayudante_operario',
    label: 'Ayudante de operario',
    icon: Icons.group_rounded,
  ),
  _AdvancedField(key: 'ce_pe', label: 'C/E o P/E', icon: Icons.tune_rounded),
  _AdvancedField(
    key: 'cantidad_fajas',
    label: 'Cantidad de fajas',
    icon: Icons.texture_rounded,
  ),
  _AdvancedField(key: 'hilo_cm', label: 'Hilo por cm', icon: Icons.grid_3x3),
  _AdvancedField(key: 'altura', label: 'Altura', icon: Icons.height_rounded),
  _AdvancedField(
    key: 'peso_plegador',
    label: 'Peso plegador',
    icon: Icons.monitor_weight_rounded,
  ),
  _AdvancedField(
    key: 'desplazamiento',
    label: 'Desplazamiento',
    icon: Icons.compare_arrows_rounded,
  ),
  _AdvancedField(key: 'tension', label: 'Tension', icon: Icons.speed_rounded),
  _AdvancedField(
    key: 'velo_urdido',
    label: 'Velocidad urdido',
    icon: Icons.av_timer_rounded,
  ),
  _AdvancedField(
    key: 'velo_plegador',
    label: 'Velocidad plegador',
    icon: Icons.motion_photos_on_rounded,
  ),
  _AdvancedField(
    key: 'freno_plegador',
    label: 'Freno plegador',
    icon: Icons.settings_input_component,
  ),
  _AdvancedField(
    key: 'peso_merma',
    label: 'Peso merma',
    icon: Icons.delete_outline_rounded,
  ),
  _AdvancedField(
    key: 'giro_encerado',
    label: 'Giro encerado',
    icon: Icons.rotate_90_degrees_ccw_rounded,
  ),
  _AdvancedField(
    key: 'peso_ensimaje',
    label: 'Peso ensimaje',
    icon: Icons.science_rounded,
  ),
  _AdvancedField(key: 'pasadas', label: 'Pasadas', icon: Icons.repeat_rounded),
  _AdvancedField(
    key: 'observacion',
    label: 'Observaciones',
    icon: Icons.notes_rounded,
    multiline: true,
  ),
];

const List<String> _fieldKeys = [
  'codigo_pcp',
  'codigo_urdido',
  'turno',
  'operario',
  'ayudante_operario',
  'orden_pedido',
  'articulo',
  'tipo_proceso',
  'fecha_urdido',
  'ce_pe',
  'cantidad_hilos',
  'hora_inicio',
  'ancho_plegador',
  'metros_urdido',
  'peso_hilos_urdido',
  'cantidad_fajas',
  'hilo_cm',
  'altura',
  'peso_plegador',
  'desplazamiento',
  'tension',
  'num_plegador',
  'velo_urdido',
  'velo_plegador',
  'freno_plegador',
  'peso_merma',
  'titulo',
  'material',
  'numero_color_hilo',
  'hilo_color1',
  'hilo_color2',
  'hilo_color3',
  'hilo_color4',
  'hilo_color5',
  'hilo_color6',
  'hilo_color7',
  'hora_final',
  'giro_encerado',
  'peso_ensimaje',
  'observacion',
  'pasadas',
];
