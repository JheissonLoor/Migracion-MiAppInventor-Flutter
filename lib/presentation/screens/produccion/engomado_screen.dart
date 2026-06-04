import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/produccion_queue_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/engomado_provider.dart';
import '../../widgets/enterprise_backdrop.dart';
import '../../widgets/production/production_visuals.dart';
import '../../widgets/scanner/qr_scanner_page.dart';

class EngomadoScreen extends ConsumerStatefulWidget {
  const EngomadoScreen({super.key});

  @override
  ConsumerState<EngomadoScreen> createState() => _EngomadoScreenState();
}

class _EngomadoScreenState extends ConsumerState<EngomadoScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers;
  late final AnimationController _entryController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    final initial = ref.read(engomadoProvider).fields;
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
    final state = ref.watch(engomadoProvider);
    final notifier = ref.read(engomadoProvider.notifier);
    final usuario = ref.watch(authProvider).user?.usuario ?? 'OPERARIO';
    final proceso = _controllers['tipo_proceso']!.text.trim();
    final hasCodigo = _field(state, 'codigopcp').isNotEmpty;
    final hasLink =
        state.urdidoSnapshot.isNotEmpty ||
        _field(state, 'codigo_urdido').isNotEmpty;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    ref.listen<EngomadoState>(engomadoProvider, (previous, next) {
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
                            _buildFlowGuide(state, proceso),
                            const SizedBox(height: 10),
                            _buildScanCard(state, notifier),
                            const SizedBox(height: 10),
                            if (hasLink) ...[
                              _buildSnapshotCard(state),
                              const SizedBox(height: 10),
                              _buildSmartAlerts(state, proceso),
                              const SizedBox(height: 10),
                              _buildMainFormCard(
                                state: state,
                                notifier: notifier,
                                usuario: usuario,
                                proceso:
                                    proceso.isEmpty
                                        ? AppConstants.procesoEngomado
                                        : proceso,
                              ),
                              const SizedBox(height: 10),
                            ] else ...[
                              _buildLockedHint(
                                hasCodigo
                                    ? 'Presione "Buscar urdido" para vincular la referencia y habilitar el proceso.'
                                    : 'Escanee o ingrese PCP para iniciar engomado.',
                              ),
                              const SizedBox(height: 10),
                            ],
                            _buildQueueCard(state, notifier),
                            const SizedBox(height: 12),
                            if (hasLink)
                              _buildActionButtons(
                                state: state,
                                usuario: usuario,
                                onEnviar: () async {
                                  final confirmed = await _confirmarRegistro(
                                    state: state,
                                    usuario: usuario,
                                    proceso:
                                        proceso.isEmpty
                                            ? AppConstants.procesoEngomado
                                            : proceso,
                                  );
                                  if (!confirmed) return;
                                  await notifier.enviarEngomado(
                                    usuario: usuario,
                                  );
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
      title: 'Engomado',
      subtitle: 'Vinculacion con urdido, proceso y control offline',
      icon: Icons.settings_suggest_rounded,
      onBack: () => Navigator.pop(context),
      accentColor: const Color(0xFFB67A5A),
    );
  }

  Widget _buildStatusBanner(EngomadoState state) {
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
              color: const Color(0xFFFFF1EA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.link_off_rounded, color: Color(0xFFB67A5A)),
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

  Widget _buildSmartAlerts(EngomadoState state, String proceso) {
    final alerts = <String>[];
    final error = (state.errorMessage ?? '').trim();
    if (error.isNotEmpty) alerts.add(error);
    if (_field(state, 'tipo_proceso').isEmpty) {
      alerts.add('Tipo de proceso sugerido automaticamente: ENGOMADO.');
    }
    if (_field(state, 'operario').isEmpty) {
      alerts.add('Operario pendiente; se autocompleta con el usuario activo.');
    }
    if (_field(state, 'codigopcp').isNotEmpty) {
      alerts.add('Codigo PCP bloqueado por escaneo/vinculacion.');
    }
    if (_isProcesoReady(state, proceso)) {
      alerts.add('Datos completos. Revise el resumen y envie.');
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
                            : const Color(0xFFB67A5A),
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

  Widget _buildFlowGuide(EngomadoState state, String proceso) {
    final scanned = _field(state, 'codigopcp').isNotEmpty;
    final linked =
        state.urdidoSnapshot.isNotEmpty ||
        _field(state, 'codigo_urdido').isNotEmpty;
    final processReady = _isProcesoReady(state, proceso);
    final hasError = (state.errorMessage ?? '').trim().isNotEmpty;

    final signal =
        hasError
            ? OperationSignalLevel.error
            : (processReady
                ? OperationSignalLevel.ready
                : (scanned
                    ? OperationSignalLevel.warning
                    : OperationSignalLevel.neutral));
    final helper =
        hasError
            ? state.errorMessage!.trim()
            : processReady
            ? 'Proceso listo. Revise metros, peso final y plegador antes de enviar.'
            : linked
            ? 'Urdido vinculado. Complete los datos del proceso.'
            : scanned
            ? 'Codigo recibido. Busque urdido para vincular la referencia.'
            : 'Escanee el PCP para vincular el urdido base.';

    return OperationFlowGuide(
      title: 'Guia operativa de engomado',
      statusLabel:
          hasError
              ? 'REVISAR'
              : (processReady
                  ? 'LISTO'
                  : (scanned ? 'EN PROCESO' : 'PENDIENTE')),
      helperText: helper,
      signal: signal,
      accentColor: const Color(0xFFB67A5A),
      steps: [
        OperationStepData(
          label: 'Escanear PCP',
          icon: Icons.qr_code_scanner_rounded,
          done: scanned,
          active: !scanned,
        ),
        OperationStepData(
          label: 'Vincular urdido',
          icon: Icons.link_rounded,
          done: linked,
          active: scanned && !linked,
        ),
        OperationStepData(
          label: 'Completar proceso',
          icon: Icons.settings_suggest_rounded,
          done: processReady,
          active: linked && !processReady,
        ),
        OperationStepData(
          label: 'Enviar seguro',
          icon: Icons.send_rounded,
          done: processReady,
          active: processReady,
        ),
      ],
      summary: [
        OperationSummaryItem(
          label: 'PCP',
          value: _field(state, 'codigopcp'),
          icon: Icons.confirmation_number_rounded,
        ),
        OperationSummaryItem(
          label: 'Proceso',
          value: proceso,
          icon: Icons.category_rounded,
        ),
        OperationSummaryItem(
          label: 'Urdido',
          value:
              _field(state, 'codigo_urdido').isNotEmpty
                  ? _field(state, 'codigo_urdido')
                  : (state.urdidoSnapshot['codigo_urdido'] ?? ''),
          icon: Icons.link_rounded,
        ),
        OperationSummaryItem(
          label: 'Metros / Peso',
          value:
              '${_field(state, 'metros_engomado')} / ${_field(state, 'peso_engomado_final')}',
          icon: Icons.timeline_rounded,
        ),
      ],
    );
  }

  Widget _buildScanCard(EngomadoState state, EngomadoNotifier notifier) {
    return _buildCard(
      title: 'Escaneo y vinculacion',
      children: [
        _buildTextField(
          keyName: 'codigopcp',
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
                    : () => notifier.buscarUrdidoDesdeQr(
                      _controllers['codigopcp']!.text,
                    ),
            icon:
                state.status == EngomadoStatus.loadingUrdido
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.link_rounded),
            label: const Text('Buscar urdido y cargar referencia'),
          ),
        ),
      ],
    );
  }

  Widget _buildSnapshotCard(EngomadoState state) {
    final data = state.urdidoSnapshot;
    if (data.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CorporateTokens.surfaceBottom,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: CorporateTokens.borderSoft),
        ),
        child: const Text(
          'Aun no hay urdido vinculado. Escanee un codigo PCP para precargar.',
          style: TextStyle(color: CorporateTokens.slate500, fontSize: 12),
        ),
      );
    }

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
          const Text(
            'Referencia de urdido',
            style: TextStyle(
              color: CorporateTokens.navy900,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _snapshotChip('Codigo Urdido', data['codigo_urdido']),
              _snapshotChip('Plegador', data['nro_plegador_urdido']),
              _snapshotChip('Hilos', data['cantidad_hilos_urdido']),
              _snapshotChip('Metros', data['metros_urdido']),
              _snapshotChip('Ancho', data['ancho_plegador_urdido']),
              _snapshotChip('Peso inicial', data['peso_inicial_urdido']),
              _snapshotChip('Articulo', data['articulo_urdido']),
              _snapshotChip('OP', data['op_urdido']),
            ],
          ),
        ],
      ),
    );
  }

  Widget _snapshotChip(String label, String? value) {
    final safe = (value ?? '').trim().isEmpty ? '-' : value!.trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: CorporateTokens.borderSoft),
      ),
      child: Text(
        '$label: $safe',
        style: const TextStyle(
          color: CorporateTokens.slate700,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMainFormCard({
    required EngomadoState state,
    required EngomadoNotifier notifier,
    required String usuario,
    required String proceso,
  }) {
    final lockedByLink =
        state.urdidoSnapshot.isNotEmpty ||
        _field(state, 'codigo_urdido').isNotEmpty;
    return _buildCard(
      title: 'Formulario de proceso',
      children: [
        _buildDropdownField(
          keyName: 'tipo_proceso',
          label: 'Tipo de proceso',
          options: const [
            AppConstants.procesoEngomado,
            AppConstants.procesoEnsimaje,
            AppConstants.procesoVolteado,
          ],
          notifier: notifier,
        ),
        const SizedBox(height: 8),
        _buildDropdownField(
          keyName: 'turno',
          label: 'Turno',
          options: const ['Manana', 'Noche'],
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
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: _buildProcesoFields(
            key: ValueKey<String>(proceso),
            proceso: proceso,
            state: state,
            notifier: notifier,
            lockedByLink: lockedByLink,
          ),
        ),
      ],
    );
  }

  Widget _buildProcesoFields({
    required Key key,
    required String proceso,
    required EngomadoState state,
    required EngomadoNotifier notifier,
    required bool lockedByLink,
  }) {
    final normalized = proceso.toLowerCase();
    if (normalized == AppConstants.procesoVolteado.toLowerCase()) {
      return Column(
        key: key,
        children: [
          _buildTextField(
            keyName: 'fecha_volteado',
            label: 'Fecha volteado',
            hint: 'dd/mm/yyyy',
            icon: Icons.event_rounded,
            notifier: notifier,
            validator: (value) => _required(value, 'fecha volteado'),
          ),
          const SizedBox(height: 8),
          _buildTextField(
            keyName: 'plegador_final_volteado',
            label: 'Plegador final volteado',
            hint: 'Ejemplo: PF-18',
            icon: Icons.style_rounded,
            notifier: notifier,
            validator: (value) => _required(value, 'plegador final volteado'),
          ),
          const SizedBox(height: 8),
          _buildTextField(
            keyName: 'observacion',
            label: 'Observaciones',
            hint: 'Opcional',
            icon: Icons.notes_rounded,
            notifier: notifier,
            minLines: 3,
            maxLines: 4,
          ),
        ],
      );
    }

    final isEnsimaje = normalized == AppConstants.procesoEnsimaje.toLowerCase();
    return Column(
      key: key,
      children: [
        _buildTextField(
          keyName: 'hora_inicial',
          label: 'Hora inicial',
          hint: 'HH:MM',
          icon: Icons.schedule_rounded,
          notifier: notifier,
          validator: (value) => _required(value, 'hora inicial'),
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
          keyName: 'metros_engomado',
          label: 'Metros proceso',
          hint: 'Ejemplo: 12400',
          icon: Icons.timeline_rounded,
          notifier: notifier,
          validator: (value) => _required(value, 'metros proceso'),
        ),
        const SizedBox(height: 8),
        _buildTextField(
          keyName: 'tipo_plegador',
          label: 'Tipo de plegador',
          hint: 'Ejemplo: DIRECTO',
          icon: Icons.category_rounded,
          notifier: notifier,
        ),
        const SizedBox(height: 8),
        _buildTextField(
          keyName: 'ancho_plegador',
          label: 'Ancho plegador',
          hint: 'Ejemplo: 1.80',
          icon: Icons.straighten_rounded,
          notifier: notifier,
          validator: (value) => _required(value, 'ancho plegador'),
        ),
        if (!isEnsimaje) ...[
          const SizedBox(height: 8),
          _buildTextField(
            keyName: 'porcentaje_solido',
            label: 'Porcentaje solido',
            hint: 'Opcional',
            icon: Icons.percent_rounded,
            notifier: notifier,
          ),
        ],
        const SizedBox(height: 8),
        _buildTextField(
          keyName: 'peso_engomado_final',
          label: 'Peso final',
          hint: 'Ejemplo: 820',
          icon: Icons.monitor_weight_rounded,
          notifier: notifier,
          validator: (value) => _required(value, 'peso final'),
        ),
        const SizedBox(height: 8),
        _buildTextField(
          keyName: 'plegador_final_engomado',
          label: 'Plegador final',
          hint: 'Ejemplo: PF-12',
          icon: Icons.dataset_rounded,
          notifier: notifier,
          validator: (value) => _required(value, 'plegador final'),
        ),
        if (!isEnsimaje) ...[
          const SizedBox(height: 8),
          _buildTextField(
            keyName: 'viscosidad_engomado',
            label: 'Viscosidad',
            hint: 'Opcional',
            icon: Icons.science_rounded,
            notifier: notifier,
          ),
          const SizedBox(height: 8),
          _buildTextField(
            keyName: 'velocidad_engomadora',
            label: 'Velocidad engomadora',
            hint: 'Opcional',
            icon: Icons.speed_rounded,
            notifier: notifier,
          ),
        ],
        const SizedBox(height: 8),
        _buildTextField(
          keyName: 'formula_engomado',
          label: 'Formula',
          hint: 'Opcional',
          icon: Icons.functions_rounded,
          notifier: notifier,
        ),
        const SizedBox(height: 8),
        _buildDropdownField(
          keyName: 'titulo',
          label: 'Titulo',
          options: state.titulos,
          notifier: notifier,
          allowManual: true,
        ),
        const SizedBox(height: 8),
        _buildDropdownField(
          keyName: 'material',
          label: 'Material',
          options: state.materiales,
          notifier: notifier,
          allowManual: true,
        ),
        if (isEnsimaje) ...[
          const SizedBox(height: 8),
          _buildTextField(
            keyName: 'codigo_urdido',
            label: 'Codigo urdido',
            hint: 'Viene del escaneo',
            icon: Icons.link_rounded,
            notifier: notifier,
            readOnly: lockedByLink,
            validator: (value) => _required(value, 'codigo urdido'),
          ),
          const SizedBox(height: 8),
          _buildTextField(
            keyName: 'giro_encerado',
            label: 'Giro encerado',
            hint: 'Ejemplo: 120',
            icon: Icons.rotate_90_degrees_ccw_rounded,
            notifier: notifier,
            validator: (value) => _required(value, 'giro encerado'),
          ),
          const SizedBox(height: 8),
          _buildTextField(
            keyName: 'kilo_ensimaje',
            label: 'Kilos ensimaje',
            hint: 'Ejemplo: 18.5',
            icon: Icons.scale_rounded,
            notifier: notifier,
            validator: (value) => _required(value, 'kilo ensimaje'),
          ),
        ],
        const SizedBox(height: 8),
        _buildTextField(
          keyName: 'observacion',
          label: 'Observaciones',
          hint: 'Opcional',
          icon: Icons.notes_rounded,
          notifier: notifier,
          minLines: 3,
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildQueueCard(EngomadoState state, EngomadoNotifier notifier) {
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
                'Cola offline de Engomado',
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
                      state.status == EngomadoStatus.drainingQueue
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
              'No hay procesos pendientes.',
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
    EngomadoQueueJobModel job,
    EngomadoNotifier notifier,
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
                  '${job.codigoPcp} | ${job.tipoProceso}',
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
    required EngomadoState state,
    required String usuario,
    required Future<void> Function() onEnviar,
    required VoidCallback onLimpiar,
  }) {
    final proceso =
        _field(state, 'tipo_proceso').isEmpty
            ? AppConstants.procesoEngomado
            : _field(state, 'tipo_proceso');
    final ready = _isProcesoReady(state, proceso);
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
                    state.status == EngomadoStatus.sending
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
                  state.status == EngomadoStatus.sending
                      ? 'Enviando proceso...'
                      : 'Revisar y registrar proceso',
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
            : _disabledContextButton('Complete datos requeridos del proceso'),
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
      accentColor: const Color(0xFFB67A5A),
      children: children,
    );
  }

  IconData _cardIcon(String title) {
    final value = title.toLowerCase();
    if (value.contains('escaneo')) return Icons.qr_code_scanner_rounded;
    if (value.contains('referencia')) return Icons.link_rounded;
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
    required EngomadoNotifier notifier,
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
    required EngomadoNotifier notifier,
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

  Future<void> _scanQr(EngomadoNotifier notifier) async {
    final scanned = await openQrScanner(
      context,
      title: 'Escanear QR para Engomado',
    );
    if (!mounted || scanned == null || scanned.trim().isEmpty) return;
    _controllers['codigopcp']!.text = scanned.trim();
    notifier.actualizarCampo('codigopcp', scanned.trim());
    await notifier.buscarUrdidoDesdeQr(scanned);
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
    EngomadoState state,
    EngomadoNotifier notifier,
    String usuario,
  ) {
    final linked =
        state.urdidoSnapshot.isNotEmpty ||
        _field(state, 'codigo_urdido').isNotEmpty;
    if (!linked) return;

    if (_field(state, 'tipo_proceso').isEmpty) {
      const value = AppConstants.procesoEngomado;
      _controllers['tipo_proceso']!.text = value;
      notifier.actualizarCampo('tipo_proceso', value);
    }
    if (_field(state, 'turno').isEmpty) {
      const value = 'Manana';
      _controllers['turno']!.text = value;
      notifier.actualizarCampo('turno', value);
    }
    if (_field(state, 'operario').isEmpty && usuario.trim().isNotEmpty) {
      _controllers['operario']!.text = usuario.trim();
      notifier.actualizarCampo('operario', usuario.trim());
    }
    final now = DateTime.now();
    if (_field(state, 'hora_inicial').isEmpty) {
      final value = _formatLocalTime(now);
      _controllers['hora_inicial']!.text = value;
      notifier.actualizarCampo('hora_inicial', value);
    }
  }

  void _limpiar(EngomadoNotifier notifier) {
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

  String _field(EngomadoState state, String key) {
    return (state.fields[key] ?? _controllers[key]?.text ?? '').trim();
  }

  bool _isProcesoReady(EngomadoState state, String proceso) {
    final normalized = proceso.toLowerCase();
    final common =
        _field(state, 'codigopcp').isNotEmpty &&
        _field(state, 'tipo_proceso').isNotEmpty &&
        _field(state, 'turno').isNotEmpty &&
        _field(state, 'operario').isNotEmpty;
    if (!common) return false;

    if (normalized == AppConstants.procesoVolteado.toLowerCase()) {
      return _field(state, 'fecha_volteado').isNotEmpty &&
          _field(state, 'plegador_final_volteado').isNotEmpty;
    }

    final processBase =
        _field(state, 'hora_inicial').isNotEmpty &&
        _field(state, 'hora_final').isNotEmpty &&
        _field(state, 'metros_engomado').isNotEmpty &&
        _field(state, 'ancho_plegador').isNotEmpty &&
        _field(state, 'peso_engomado_final').isNotEmpty &&
        _field(state, 'plegador_final_engomado').isNotEmpty;
    if (!processBase) return false;

    if (normalized == AppConstants.procesoEnsimaje.toLowerCase()) {
      return _field(state, 'codigo_urdido').isNotEmpty &&
          _field(state, 'giro_encerado').isNotEmpty &&
          _field(state, 'kilo_ensimaje').isNotEmpty;
    }

    return true;
  }

  Future<bool> _confirmarRegistro({
    required EngomadoState state,
    required String usuario,
    required String proceso,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: const Text('Confirmar proceso'),
            content: SizedBox(
              width: 520,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _confirmRow('PCP', _field(state, 'codigopcp')),
                  _confirmRow('Proceso', proceso),
                  _confirmRow(
                    'Codigo urdido',
                    _field(state, 'codigo_urdido').isNotEmpty
                        ? _field(state, 'codigo_urdido')
                        : (state.urdidoSnapshot['codigo_urdido'] ?? ''),
                  ),
                  _confirmRow('Metros', _field(state, 'metros_engomado')),
                  _confirmRow(
                    'Peso final',
                    _field(state, 'peso_engomado_final'),
                  ),
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

const List<String> _fieldKeys = [
  'codigopcp',
  'tipo_proceso',
  'turno',
  'operario',
  'hora_inicial',
  'hora_final',
  'metros_engomado',
  'tipo_plegador',
  'ancho_plegador',
  'porcentaje_solido',
  'peso_engomado_final',
  'plegador_final_engomado',
  'viscosidad_engomado',
  'formula_engomado',
  'velocidad_engomadora',
  'titulo',
  'material',
  'observacion',
  'codigo_urdido',
  'giro_encerado',
  'kilo_ensimaje',
  'fecha_volteado',
  'plegador_final_volteado',
];
