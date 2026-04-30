import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/produccion_queue_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/engomado_provider.dart';
import '../../widgets/enterprise_backdrop.dart';
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

    ref.listen<EngomadoState>(engomadoProvider, (previous, next) {
      if (!mounted) return;
      if (previous?.fields != next.fields) {
        _syncControllers(next.fields);
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
                        child: Form(
                          key: _formKey,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          child: Column(
                            children: [
                              _buildScanCard(state, notifier),
                              const SizedBox(height: 10),
                              _buildSnapshotCard(state),
                              const SizedBox(height: 10),
                              _buildMainFormCard(
                                state: state,
                                notifier: notifier,
                                usuario: usuario,
                                proceso: proceso,
                              ),
                              const SizedBox(height: 10),
                              _buildQueueCard(state, notifier),
                              const SizedBox(height: 12),
                              _buildActionButtons(
                                state: state,
                                usuario: usuario,
                                onEnviar:
                                    () => notifier.enviarEngomado(
                                      usuario: usuario,
                                    ),
                                onLimpiar: () => _limpiar(notifier),
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
                'Engomado',
                style: TextStyle(
                  color: CorporateTokens.navy900,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Proceso productivo con respaldo offline',
                style: TextStyle(color: CorporateTokens.slate500, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBanner(EngomadoState state) {
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
                    : const Icon(Icons.send_rounded),
            label: Text(
              state.status == EngomadoStatus.sending
                  ? 'Enviando proceso...'
                  : 'Registrar proceso',
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
    required EngomadoNotifier notifier,
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
