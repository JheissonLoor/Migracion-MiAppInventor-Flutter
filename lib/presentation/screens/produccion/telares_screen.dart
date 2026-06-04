import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/produccion_queue_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/telares_provider.dart';
import '../../widgets/enterprise_backdrop.dart';
import '../../widgets/production/production_visuals.dart';
import '../../widgets/scanner/qr_scanner_page.dart';

class TelaresScreen extends ConsumerStatefulWidget {
  const TelaresScreen({super.key});

  @override
  ConsumerState<TelaresScreen> createState() => _TelaresScreenState();
}

class _TelaresScreenState extends ConsumerState<TelaresScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers;
  late final AnimationController _entryController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    final initial = ref.read(telaresProvider).fields;
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
    final state = ref.watch(telaresProvider);
    final notifier = ref.read(telaresProvider.notifier);
    final usuario = ref.watch(authProvider).user?.usuario ?? 'OPERARIO';
    final hasCodigo = _field(state, 'codigo_pcp').isNotEmpty;
    final hasPrecarga =
        _field(state, 'codigo_urdido').isNotEmpty ||
        _field(state, 'articulo_urdido').isNotEmpty;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    ref.listen<TelaresState>(telaresProvider, (previous, next) {
      if (!mounted) return;
      if (previous?.fields != next.fields) {
        _syncControllers(next.fields);
        _autofillDefaults(next, notifier);
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
                              _buildResumenCard(),
                              const SizedBox(height: 10),
                              _buildRegistroCard(state, notifier),
                              const SizedBox(height: 10),
                            ] else ...[
                              _buildLockedHint(
                                hasCodigo
                                    ? 'Presione "Buscar datos" para habilitar el registro de calidad.'
                                    : 'Escanee o ingrese codigo PCP para iniciar.',
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
                                  await notifier.enviarRegistro(
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
      title: 'Telares',
      subtitle: 'Control de corte, calidad y cola segura',
      icon: Icons.grid_view_rounded,
      onBack: () => Navigator.pop(context),
      accentColor: const Color(0xFF9A7A57),
      trailing: IconButton(
        onPressed: () => Navigator.pushNamed(context, '/historial_telar'),
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xFFF8FAFC),
          side: const BorderSide(color: CorporateTokens.borderSoft),
        ),
        icon: const Icon(
          Icons.view_timeline_rounded,
          color: CorporateTokens.navy900,
        ),
      ),
    );
  }

  Widget _buildStatusBanner(TelaresState state) {
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
              Icons.rule_folder_rounded,
              color: Color(0xFF9A7A57),
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

  Widget _buildSmartAlerts(TelaresState state) {
    final alerts = <String>[];
    final error = (state.errorMessage ?? '').trim();
    if (error.isNotEmpty) alerts.add(error);
    if (_field(state, 'reloj').isEmpty) {
      alerts.add('Reloj sugerido automaticamente: A. Cambielo si corresponde.');
    }
    if (state.isNuevoCorte) {
      alerts.add(
        'Modo detectado: nuevo corte. Complete puntaje y telar nuevo.',
      );
    } else if (state.registroMode == TelaresRegistroMode.primerCorteAprobado) {
      alerts.add('Modo: primer corte aprobado. Confirme fecha y aprobador.');
    } else {
      alerts.add('Modo: primer corte no aprobado. Complete observaciones.');
    }
    if (_isRegistroReady(state)) {
      alerts.add('Datos completos. Revise el resumen antes de registrar.');
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
                            : const Color(0xFF9A7A57),
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

  Widget _buildFlowGuide(TelaresState state) {
    final scanned = _field(state, 'codigo_pcp').isNotEmpty;
    final loaded =
        _field(state, 'codigo_urdido').isNotEmpty ||
        _field(state, 'articulo_urdido').isNotEmpty;
    final registroReady = _isRegistroReady(state);
    final hasError = (state.errorMessage ?? '').trim().isNotEmpty;

    final signal =
        hasError
            ? OperationSignalLevel.error
            : (registroReady
                ? OperationSignalLevel.ready
                : (scanned
                    ? OperationSignalLevel.warning
                    : OperationSignalLevel.neutral));
    final helper =
        hasError
            ? state.errorMessage!.trim()
            : registroReady
            ? 'Registro listo. Revise telar, puntaje y modo antes de enviar.'
            : loaded
            ? 'Datos cargados. Complete los campos de calidad.'
            : scanned
            ? 'Codigo recibido. Busque datos de telar para precargar.'
            : 'Escanee o ingrese el codigo PCP del rollo.';

    return OperationFlowGuide(
      title: 'Guia operativa de telares',
      statusLabel:
          hasError
              ? 'REVISAR'
              : (registroReady
                  ? 'LISTO'
                  : (scanned ? 'EN PROCESO' : 'PENDIENTE')),
      helperText: helper,
      signal: signal,
      accentColor: const Color(0xFF9A7A57),
      steps: [
        OperationStepData(
          label: 'Escanear PCP',
          icon: Icons.qr_code_scanner_rounded,
          done: scanned,
          active: !scanned,
        ),
        OperationStepData(
          label: 'Precargar datos',
          icon: Icons.manage_search_rounded,
          done: loaded,
          active: scanned && !loaded,
        ),
        OperationStepData(
          label: 'Calidad y telar',
          icon: Icons.fact_check_rounded,
          done: registroReady,
          active: loaded && !registroReady,
        ),
        OperationStepData(
          label: 'Enviar seguro',
          icon: Icons.send_rounded,
          done: registroReady,
          active: registroReady,
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
          icon: Icons.inventory_2_rounded,
        ),
        OperationSummaryItem(
          label: 'Modo',
          value: _modeLabel(state.registroMode),
          icon: Icons.rule_rounded,
        ),
        OperationSummaryItem(
          label: 'Telar / Puntaje',
          value:
              state.isNuevoCorte
                  ? '${_field(state, 'telar_nuevo')} / ${_field(state, 'puntaje_nuevo')}'
                  : '${_field(state, 'telar')} / ${_field(state, 'puntaje1')}',
          icon: Icons.precision_manufacturing_rounded,
        ),
      ],
    );
  }

  Widget _buildScanCard(TelaresState state, TelaresNotifier notifier) {
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
                state.status == TelaresStatus.loadingScanData
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.manage_search_rounded),
            label: const Text('Buscar datos de telar por codigo'),
          ),
        ),
      ],
    );
  }

  Widget _buildResumenCard() {
    return _buildCard(
      title: 'Resumen de urdido / engomado',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _snapshotChip('Articulo', _controllers['articulo_urdido']!.text),
            _snapshotChip('Codigo urdido', _controllers['codigo_urdido']!.text),
            _snapshotChip(
              'Plegador',
              _controllers['nro_plegador_urdido']!.text,
            ),
            _snapshotChip('OP', _controllers['op_urdido']!.text),
            _snapshotChip('Metros urdido', _controllers['metros_urdido']!.text),
            _snapshotChip(
              'Metros engomado',
              _controllers['metros_engomado']!.text,
            ),
            _snapshotChip(
              'Puntaje inicial',
              _controllers['puntaje_inicial']!.text,
            ),
            _snapshotChip(
              'Puntaje anterior',
              _controllers['puntaje_anterior']!.text,
            ),
            _snapshotChip(
              'Telar anterior',
              _controllers['telar_anterior']!.text,
            ),
          ],
        ),
      ],
    );
  }

  Widget _snapshotChip(String label, String value) {
    final safe = value.trim().isEmpty ? '-' : value.trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: CorporateTokens.surfaceBottom,
        borderRadius: BorderRadius.circular(999),
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

  Widget _buildRegistroCard(TelaresState state, TelaresNotifier notifier) {
    return _buildCard(
      title: 'Registro de corte',
      children: [
        _buildDropdownField(
          keyName: 'reloj',
          label: 'Reloj',
          options: const ['A', 'B', 'C', 'D'],
          notifier: notifier,
        ),
        const SizedBox(height: 8),
        if (state.isNuevoCorte) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: CorporateTokens.cobalt600.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: CorporateTokens.cobalt600.withValues(alpha: 0.25),
              ),
            ),
            child: const Text(
              'Modo automatico: REGISTRAR NUEVO CORTE',
              style: TextStyle(
                color: CorporateTokens.navy900,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildTextField(
            keyName: 'puntaje_nuevo',
            label: 'Puntaje nuevo',
            hint: 'Ejemplo: 92',
            icon: Icons.score_rounded,
            notifier: notifier,
            validator: (value) => _required(value, 'puntaje nuevo'),
          ),
          const SizedBox(height: 8),
          _buildTextField(
            keyName: 'telar_nuevo',
            label: 'Telar nuevo',
            hint: 'Ejemplo: 18',
            icon: Icons.precision_manufacturing_rounded,
            notifier: notifier,
            validator: (value) => _required(value, 'telar nuevo'),
          ),
        ] else ...[
          const Text(
            'Primer corte de calidad',
            style: TextStyle(
              color: CorporateTokens.navy900,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('No aprobado'),
                selected:
                    state.registroMode ==
                    TelaresRegistroMode.primerCorteNoAprobado,
                onSelected:
                    state.isBusy
                        ? null
                        : (_) => notifier.seleccionarModoPrimerCorte(
                          aprobado: false,
                        ),
              ),
              ChoiceChip(
                label: const Text('Aprobado'),
                selected:
                    state.registroMode ==
                    TelaresRegistroMode.primerCorteAprobado,
                onSelected:
                    state.isBusy
                        ? null
                        : (_) =>
                            notifier.seleccionarModoPrimerCorte(aprobado: true),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildTextField(
            keyName: 'puntaje1',
            label: 'Puntaje 1',
            hint: 'Ejemplo: 88',
            icon: Icons.score_rounded,
            notifier: notifier,
            validator: (value) => _required(value, 'puntaje 1'),
          ),
          const SizedBox(height: 8),
          _buildTextField(
            keyName: 'telar',
            label: 'Telar',
            hint: 'Ejemplo: 15',
            icon: Icons.precision_manufacturing_rounded,
            notifier: notifier,
            validator: (value) => _required(value, 'telar'),
          ),
          const SizedBox(height: 8),
          if (state.registroMode ==
              TelaresRegistroMode.primerCorteAprobado) ...[
            _buildTextField(
              keyName: 'fecha_aprobado',
              label: 'Fecha de aprobacion',
              hint: 'dd/mm/yyyy',
              icon: Icons.event_available_rounded,
              notifier: notifier,
              validator: (value) => _required(value, 'fecha aprobacion'),
            ),
            const SizedBox(height: 8),
            _buildDropdownField(
              keyName: 'aprobado_por',
              label: 'Aprobado por',
              options: const [
                'SANDRA',
                'RAUL INGA',
                'CESAR CISNEROS',
                'CARLOS',
              ],
              notifier: notifier,
              allowManual: true,
            ),
          ] else ...[
            _buildTextField(
              keyName: 'fecha_no_aprob',
              label: 'Fecha no aprobacion',
              hint: 'dd/mm/yyyy',
              icon: Icons.event_busy_rounded,
              notifier: notifier,
              validator: (value) => _required(value, 'fecha no aprobacion'),
            ),
            const SizedBox(height: 8),
            _buildTextField(
              keyName: 'observaciones',
              label: 'Observaciones',
              hint: 'Detalle de no aprobacion',
              icon: Icons.notes_rounded,
              notifier: notifier,
              validator: (value) => _required(value, 'observaciones'),
              minLines: 3,
              maxLines: 4,
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildQueueCard(TelaresState state, TelaresNotifier notifier) {
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
                'Cola offline de Telares',
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
                      state.status == TelaresStatus.drainingQueue
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
    TelaresQueueJobModel job,
    TelaresNotifier notifier,
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
                  '${job.codigoPcp} | ${job.modoRegistro}',
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
    required TelaresState state,
    required String usuario,
    required Future<void> Function() onEnviar,
    required VoidCallback onLimpiar,
  }) {
    final ready = _isRegistroReady(state);
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
                    state.status == TelaresStatus.sending
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
                  state.status == TelaresStatus.sending
                      ? 'Enviando registro...'
                      : 'Revisar y registrar en telares',
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
            : _disabledContextButton('Complete calidad y telar'),
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
      accentColor: const Color(0xFF9A7A57),
      children: children,
    );
  }

  IconData _cardIcon(String title) {
    final value = title.toLowerCase();
    if (value.contains('escaneo')) return Icons.qr_code_scanner_rounded;
    if (value.contains('resumen')) return Icons.analytics_rounded;
    if (value.contains('registro')) return Icons.fact_check_rounded;
    if (value.contains('cola')) return Icons.sync_alt_rounded;
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
    required TelaresNotifier notifier,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    int minLines = 1,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: _controllers[keyName],
      minLines: minLines,
      maxLines: maxLines,
      onChanged: (value) => notifier.actualizarCampo(keyName, value),
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
    required TelaresNotifier notifier,
    bool allowManual = false,
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
      );
    }

    return DropdownButtonFormField<String>(
      value: selected.isEmpty ? null : selected,
      onChanged: (value) {
        final newValue = value ?? '';
        _controllers[keyName]!.text = newValue;
        notifier.actualizarCampo(keyName, newValue);
      },
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

  Future<void> _scanQr(TelaresNotifier notifier) async {
    final scanned = await openQrScanner(
      context,
      title: 'Escanear QR para Telares',
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

  void _autofillDefaults(TelaresState state, TelaresNotifier notifier) {
    final loaded =
        _field(state, 'codigo_urdido').isNotEmpty ||
        _field(state, 'articulo_urdido').isNotEmpty;
    if (!loaded) return;

    if (_field(state, 'reloj').isEmpty) {
      const value = 'A';
      _controllers['reloj']!.text = value;
      notifier.actualizarCampo('reloj', value);
    }

    final today = _formatLocalDate(DateTime.now());
    if (state.registroMode == TelaresRegistroMode.primerCorteAprobado &&
        _field(state, 'fecha_aprobado').isEmpty) {
      _controllers['fecha_aprobado']!.text = today;
      notifier.actualizarCampo('fecha_aprobado', today);
    }
    if (state.registroMode == TelaresRegistroMode.primerCorteNoAprobado &&
        _field(state, 'fecha_no_aprob').isEmpty) {
      _controllers['fecha_no_aprob']!.text = today;
      notifier.actualizarCampo('fecha_no_aprob', today);
    }
  }

  void _limpiar(TelaresNotifier notifier) {
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

  String _field(TelaresState state, String key) {
    return (state.fields[key] ?? _controllers[key]?.text ?? '').trim();
  }

  bool _isRegistroReady(TelaresState state) {
    if (_field(state, 'codigo_pcp').isEmpty || _field(state, 'reloj').isEmpty) {
      return false;
    }

    if (state.registroMode == TelaresRegistroMode.nuevoCorte) {
      return _field(state, 'puntaje_nuevo').isNotEmpty &&
          _field(state, 'telar_nuevo').isNotEmpty;
    }

    final basePrimerCorte =
        _field(state, 'puntaje1').isNotEmpty &&
        _field(state, 'telar').isNotEmpty;
    if (!basePrimerCorte) return false;

    if (state.registroMode == TelaresRegistroMode.primerCorteAprobado) {
      return _field(state, 'fecha_aprobado').isNotEmpty &&
          _field(state, 'aprobado_por').isNotEmpty;
    }

    return _field(state, 'fecha_no_aprob').isNotEmpty &&
        _field(state, 'observaciones').isNotEmpty;
  }

  Future<bool> _confirmarRegistro({
    required TelaresState state,
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
            title: const Text('Confirmar registro de telar'),
            content: SizedBox(
              width: 520,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _confirmRow('PCP', _field(state, 'codigo_pcp')),
                  _confirmRow('Codigo urdido', _field(state, 'codigo_urdido')),
                  _confirmRow('Modo', _modeLabel(state.registroMode)),
                  _confirmRow(
                    'Telar',
                    state.isNuevoCorte
                        ? _field(state, 'telar_nuevo')
                        : _field(state, 'telar'),
                  ),
                  _confirmRow(
                    'Puntaje',
                    state.isNuevoCorte
                        ? _field(state, 'puntaje_nuevo')
                        : _field(state, 'puntaje1'),
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

  String _formatLocalDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yy = date.year.toString();
    return '$dd/$mm/$yy';
  }

  String _modeLabel(TelaresRegistroMode mode) {
    switch (mode) {
      case TelaresRegistroMode.nuevoCorte:
        return 'Nuevo corte';
      case TelaresRegistroMode.primerCorteAprobado:
        return 'Primer corte aprobado';
      case TelaresRegistroMode.primerCorteNoAprobado:
        return 'Primer corte no aprobado';
    }
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
  'codigo_pcp',
  'articulo_urdido',
  'codigo_urdido',
  'nro_plegador_urdido',
  'op_urdido',
  'metros_urdido',
  'metros_engomado',
  'si_no',
  'reloj',
  'puntaje_inicial',
  'puntaje_anterior',
  'telar_anterior',
  'puntaje_nuevo',
  'telar_nuevo',
  'fecha_no_aprob',
  'observaciones',
  'puntaje1',
  'telar',
  'fecha_aprobado',
  'aprobado_por',
];
