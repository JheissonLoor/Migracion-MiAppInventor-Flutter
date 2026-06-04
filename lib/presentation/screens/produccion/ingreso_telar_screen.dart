import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ingreso_telar_provider.dart';
import '../../widgets/enterprise_backdrop.dart';
import '../../widgets/production/production_visuals.dart';

class IngresoTelarScreen extends ConsumerStatefulWidget {
  const IngresoTelarScreen({super.key});

  @override
  ConsumerState<IngresoTelarScreen> createState() => _IngresoTelarScreenState();
}

class _IngresoTelarScreenState extends ConsumerState<IngresoTelarScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Map<String, TextEditingController> _controllers;
  bool _requestedInit = false;

  @override
  void initState() {
    super.initState();
    final initial = ref.read(ingresoTelarProvider).fields;
    _controllers = {
      for (final key in _fieldOrder)
        key: TextEditingController(text: initial[key] ?? ''),
    };

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.035),
      end: Offset.zero,
    ).animate(_fadeAnimation);
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
    final state = ref.watch(ingresoTelarProvider);
    final notifier = ref.read(ingresoTelarProvider.notifier);
    final usuario = ref.watch(authProvider).user?.usuario ?? '';
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    ref.listen<IngresoTelarState>(ingresoTelarProvider, (previous, next) {
      if (mounted && previous?.fields != next.fields) {
        _syncControllers(next.fields);
        _autofillOperationalDefaults(next, notifier);
      }
    });

    if (!_requestedInit && usuario.trim().isNotEmpty) {
      _requestedInit = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) notifier.inicializar(usuario);
      });
    }

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
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.only(bottom: 18 + bottomInset),
                    child: Column(
                      children: [
                        _header(context, state, notifier),
                        const SizedBox(height: 10),
                        _stateStrip(state),
                        const SizedBox(height: 10),
                        _buildFlowGuide(state),
                        const SizedBox(height: 10),
                        _buildSmartAlerts(state),
                        if (_hasBanner(state)) ...[
                          const SizedBox(height: 10),
                          _statusBanner(state),
                        ],
                        const SizedBox(height: 10),
                        _datosTelar(state, notifier),
                        const SizedBox(height: 10),
                        _materialColor(state, notifier),
                        const SizedBox(height: 10),
                        _proceso(state, notifier),
                        const SizedBox(height: 10),
                        _trama(state, notifier),
                        const SizedBox(height: 10),
                        _acciones(state, notifier, usuario),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(
    BuildContext context,
    IngresoTelarState state,
    IngresoTelarNotifier notifier,
  ) {
    return ProductionHeader(
      title: 'Ingreso Telar',
      subtitle: 'Flujo MIT renovado: telar, material, proceso y trama',
      icon: Icons.precision_manufacturing_outlined,
      onBack: () => Navigator.pop(context),
      accentColor: const Color(0xFFC18B61),
      trailing: IconButton(
        tooltip: 'Recargar catalogos',
        onPressed: state.isBusy ? null : notifier.cargarCatalogos,
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xFFEFF6FF),
          foregroundColor: CorporateTokens.cobalt600,
        ),
        icon:
            state.isLoadingCatalogs
                ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                : const Icon(Icons.sync_rounded),
      ),
    );
  }

  Widget _stateStrip(IngresoTelarState state) {
    final status = state.estadoActual.toUpperCase();
    final color =
        status == 'COMPLETADO'
            ? const Color(0xFF16A34A)
            : status == 'EN PROGRESO'
            ? CorporateTokens.cobalt600
            : CorporateTokens.slate500;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CorporateTokens.borderSoft),
        boxShadow: CorporateTokens.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: CorporateTokens.navy900,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.precision_manufacturing_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Estado del registro',
                  style: TextStyle(
                    color: CorporateTokens.navy900,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  state.catalogsLoaded
                      ? 'Catalogos listos para operacion'
                      : 'Esperando catalogos de produccion',
                  style: const TextStyle(
                    color: CorporateTokens.slate500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Text(
              state.estadoActual,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasBanner(IngresoTelarState state) {
    return (state.errorMessage?.trim().isNotEmpty == true) ||
        (state.message?.trim().isNotEmpty == true);
  }

  Widget _statusBanner(IngresoTelarState state) {
    return ProductionStatusBanner(
      message: state.message,
      errorMessage: state.errorMessage,
    );
  }

  Widget _buildFlowGuide(IngresoTelarState state) {
    final hasTelar = _fieldValue(state, 'telar').isNotEmpty;
    final hasArticulo = _fieldValue(state, 'articulo').isNotEmpty;
    final hasTrama = _fieldValue(state, 'trama').isNotEmpty;
    final hasFinalDate = _fieldValue(state, 'fecha_final').isNotEmpty;
    final hasError = (state.errorMessage ?? '').trim().isNotEmpty;
    final readyToSave = _isProgressReady(state);
    final readyToComplete = _isCompletionReady(state);

    final signal =
        hasError
            ? OperationSignalLevel.error
            : readyToComplete
            ? OperationSignalLevel.ready
            : readyToSave
            ? OperationSignalLevel.warning
            : OperationSignalLevel.neutral;

    final helper =
        hasError
            ? state.errorMessage!.trim()
            : readyToComplete
            ? 'Listo para cerrar produccion. Revise el resumen antes de completar.'
            : readyToSave
            ? 'Datos minimos completos. Puede guardar avance de telar.'
            : hasTelar
            ? 'Cargue progreso del telar y complete articulo/trama.'
            : 'Paso inicial: ingrese el telar y cargue progreso o sugeridos.';

    return OperationFlowGuide(
      title: 'Guia operativa de ingreso telar',
      statusLabel:
          hasError
              ? 'REVISAR'
              : readyToComplete
              ? 'LISTO'
              : readyToSave
              ? 'EN PROCESO'
              : 'PENDIENTE',
      helperText: helper,
      signal: signal,
      accentColor: const Color(0xFFC18B61),
      steps: [
        OperationStepData(
          label: 'Ingresar telar',
          icon: Icons.factory_rounded,
          done: hasTelar,
          active: !hasTelar,
        ),
        OperationStepData(
          label: 'Validar articulo',
          icon: Icons.assignment_turned_in_rounded,
          done: hasArticulo,
          active: hasTelar && !hasArticulo,
        ),
        OperationStepData(
          label: 'Registrar trama',
          icon: Icons.grain_rounded,
          done: hasTrama,
          active: hasArticulo && !hasTrama,
        ),
        OperationStepData(
          label: 'Cerrar produccion',
          icon: Icons.task_alt_rounded,
          done: readyToComplete,
          active: readyToSave && !hasFinalDate,
        ),
      ],
      summary: [
        OperationSummaryItem(
          label: 'Telar',
          value: _fieldValue(state, 'telar'),
          icon: Icons.settings_input_component_rounded,
        ),
        OperationSummaryItem(
          label: 'Articulo',
          value: _fieldValue(state, 'articulo'),
          icon: Icons.inventory_2_rounded,
        ),
        OperationSummaryItem(
          label: 'Estado',
          value: state.estadoActual,
          icon: Icons.verified_user_rounded,
        ),
      ],
    );
  }

  Widget _buildSmartAlerts(IngresoTelarState state) {
    final alerts = <String>[];
    final isProgressLoaded = _isProgressLoaded(state);
    final hasTelar = _fieldValue(state, 'telar').isNotEmpty;
    final readyToSave = _isProgressReady(state);
    final readyToComplete = _isCompletionReady(state);

    if (!state.catalogsLoaded) {
      alerts.add(
        'Catalogos pendientes: puede escribir manualmente, pero conviene recargar antes de operar.',
      );
    }
    if (!hasTelar) {
      alerts.add('Ingrese numero de telar para activar la carga de progreso.');
    }
    if (isProgressLoaded) {
      alerts.add(
        'Progreso activo cargado: telar y articulo quedan protegidos para evitar cambios accidentales.',
      );
    }
    if (readyToSave && !readyToComplete) {
      alerts.add(
        'Avance listo para guardar. Para completar produccion agregue fecha final.',
      );
    }
    if (readyToComplete) {
      alerts.add('Semaforo verde: datos listos para completar produccion.');
    }

    final color =
        (state.errorMessage ?? '').trim().isNotEmpty
            ? const Color(0xFFDC2626)
            : readyToComplete
            ? const Color(0xFF16A34A)
            : readyToSave
            ? const Color(0xFFD97706)
            : CorporateTokens.cobalt600;

    return AnimatedContainer(
      duration: CorporateTokens.motionFast,
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.traffic_rounded, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  readyToComplete
                      ? 'Listo para completar'
                      : readyToSave
                      ? 'Listo para guardar avance'
                      : 'Validacion operativa',
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final alert in alerts)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.bolt_rounded, color: color, size: 16),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      alert,
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
            ),
        ],
      ),
    );
  }

  Widget _datosTelar(IngresoTelarState state, IngresoTelarNotifier notifier) {
    final lockedByProgress = _isProgressLoaded(state);
    final hasTelar = _fieldValue(state, 'telar').isNotEmpty;
    return _section(
      step: '01',
      title: 'Datos del telar',
      subtitle: 'Ingrese el telar y cargue progreso o sugeridos.',
      icon: Icons.factory_rounded,
      child: LayoutBuilder(
        builder: (context, c) {
          return Column(
            children: [
              _row(c.maxWidth, [
                _field(
                  keyName: 'telar',
                  label: 'Num. telar',
                  hint: 'Ej: 49',
                  icon: Icons.settings_input_component_rounded,
                  keyboardType: TextInputType.number,
                  notifier: notifier,
                  enabled: !state.isBusy,
                  readOnly: lockedByProgress,
                  onEditingComplete: notifier.cargarProgresoPorTelar,
                ),
                _miniAction(
                  label:
                      state.status == IngresoTelarStatus.loadingProgress
                          ? 'Buscando...'
                          : 'Cargar telar',
                  icon: Icons.manage_search_rounded,
                  busy: state.status == IngresoTelarStatus.loadingProgress,
                  enabled: !state.isBusy && hasTelar && !lockedByProgress,
                  onPressed: notifier.cargarProgresoPorTelar,
                ),
              ]),
              const SizedBox(height: 10),
              _catalogField(
                keyName: 'articulo',
                label: 'Articulo',
                hint: 'Seleccionar articulo',
                icon: Icons.assignment_turned_in_rounded,
                values: state.articulos,
                notifier: notifier,
                enabled: !state.isBusy,
                readOnly: lockedByProgress,
              ),
              const SizedBox(height: 10),
              _row(c.maxWidth, [
                _field(
                  keyName: 'pas',
                  label: 'PAS',
                  hint: 'Auto/sugerido',
                  icon: Icons.view_week_rounded,
                  notifier: notifier,
                  enabled: !state.isBusy,
                  readOnly: lockedByProgress,
                ),
                _field(
                  keyName: 'ancho_peine',
                  label: 'Ancho peine',
                  hint: 'Auto/sugerido',
                  icon: Icons.straighten_rounded,
                  notifier: notifier,
                  enabled: !state.isBusy,
                  readOnly: lockedByProgress,
                ),
              ]),
            ],
          );
        },
      ),
    );
  }

  Widget _materialColor(
    IngresoTelarState state,
    IngresoTelarNotifier notifier,
  ) {
    return _section(
      step: '02',
      title: 'Material y color',
      subtitle: 'Catalogos reales cargados desde el backend FASE3.',
      icon: Icons.palette_rounded,
      child: LayoutBuilder(
        builder: (context, c) {
          return Column(
            children: [
              _row(c.maxWidth, [
                _catalogField(
                  keyName: 'material',
                  label: 'Material',
                  hint: 'Ej: ALGODON',
                  icon: Icons.category_rounded,
                  values: state.materiales,
                  notifier: notifier,
                  enabled: !state.isBusy,
                ),
                _catalogField(
                  keyName: 'titulo',
                  label: 'Titulo',
                  hint: 'Ej: 30/1',
                  icon: Icons.badge_rounded,
                  values: state.titulos,
                  notifier: notifier,
                  enabled: !state.isBusy,
                ),
              ]),
              const SizedBox(height: 10),
              _catalogField(
                keyName: 'color',
                label: 'Color',
                hint: 'Buscar color',
                icon: Icons.invert_colors_rounded,
                values: state.colores,
                notifier: notifier,
                enabled: !state.isBusy,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _proceso(IngresoTelarState state, IngresoTelarNotifier notifier) {
    return _section(
      step: '03',
      title: 'Proceso',
      subtitle: 'Metraje, hilos y peso total del registro.',
      icon: Icons.timeline_rounded,
      child: LayoutBuilder(
        builder: (context, c) {
          return Column(
            children: [
              _row(c.maxWidth, [
                _field(
                  keyName: 'hilos',
                  label: 'Hilos',
                  hint: 'Cantidad hilos',
                  icon: Icons.linear_scale_rounded,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  notifier: notifier,
                  enabled: !state.isBusy,
                ),
                _field(
                  keyName: 'mts',
                  label: 'Metraje (MTS)',
                  hint: 'Metros',
                  icon: Icons.square_foot_rounded,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  notifier: notifier,
                  enabled: !state.isBusy,
                ),
              ]),
              const SizedBox(height: 10),
              _field(
                keyName: 'peso_total',
                label: 'Peso total',
                hint: 'Calculado o manual',
                icon: Icons.scale_rounded,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                notifier: notifier,
                enabled: !state.isBusy,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _trama(IngresoTelarState state, IngresoTelarNotifier notifier) {
    return _section(
      step: '04',
      title: 'Registro trama',
      subtitle: 'Guardar progreso acumula; completar cierra produccion.',
      icon: Icons.grain_rounded,
      child: LayoutBuilder(
        builder: (context, c) {
          return Column(
            children: [
              _row(c.maxWidth, [
                _field(
                  keyName: 'trama',
                  label: 'Trama nueva',
                  hint: 'MTS producidos',
                  icon: Icons.add_chart_rounded,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  notifier: notifier,
                  enabled: !state.isBusy,
                ),
                _readOnly(
                  keyName: 'parcial',
                  label: 'Parcial acumulado',
                  hint: 'Auto desde backend',
                  icon: Icons.functions_rounded,
                ),
              ]),
              const SizedBox(height: 10),
              _row(c.maxWidth, [
                _dateField(
                  keyName: 'fecha_inicio',
                  label: 'Fecha inicio',
                  enabled: !state.isBusy,
                  onPick:
                      () => _pickDate(
                        current: _controllers['fecha_inicio']!.text,
                        onPicked: notifier.seleccionarFechaInicio,
                      ),
                ),
                _dateField(
                  keyName: 'fecha_final',
                  label: 'Fecha final',
                  enabled: !state.isBusy,
                  onPick:
                      () => _pickDate(
                        current: _controllers['fecha_final']!.text,
                        onPicked: notifier.seleccionarFechaFinal,
                      ),
                ),
              ]),
            ],
          );
        },
      ),
    );
  }

  Widget _acciones(
    IngresoTelarState state,
    IngresoTelarNotifier notifier,
    String usuario,
  ) {
    final readyToSave = _isProgressReady(state);
    final readyToComplete = _isCompletionReady(state);
    final canSave =
        readyToSave && !state.isBusy && state.estadoActual != 'COMPLETADO';
    final canComplete =
        readyToComplete && !state.isBusy && state.estadoActual != 'COMPLETADO';
    final showsSave =
        readyToSave &&
        (!readyToComplete || state.estadoActual != 'EN PROGRESO');

    return _section(
      step: 'OK',
      title: 'Acciones de registro',
      subtitle:
          usuario.trim().isEmpty
              ? 'Operario sin sesion'
              : 'Operario activo: $usuario',
      icon: Icons.verified_rounded,
      child: Column(
        children: [
          if (!readyToSave)
            _disabledContextButton('Complete telar, articulo y trama')
          else if (showsSave)
            _ActionButton(
              label:
                  state.status == IngresoTelarStatus.saving
                      ? 'Guardando progreso...'
                      : 'Revisar y guardar progreso',
              icon: Icons.save_rounded,
              busy: state.status == IngresoTelarStatus.saving,
              enabled: canSave,
              colors: const [Color(0xFF1D9B65), Color(0xFF16A34A)],
              onPressed: () async {
                final confirmed = await _confirmarRegistroTelar(
                  state: state,
                  usuario: usuario,
                  accion: 'guardar progreso',
                );
                if (confirmed) {
                  await notifier.guardarProgreso();
                }
              },
            ),
          if (readyToComplete) ...[
            if (showsSave) const SizedBox(height: 9),
            _ActionButton(
              label:
                  state.status == IngresoTelarStatus.completing
                      ? 'Completando produccion...'
                      : 'Revisar y completar produccion',
              icon: Icons.task_alt_rounded,
              busy: state.status == IngresoTelarStatus.completing,
              enabled: canComplete,
              colors: CorporateTokens.primaryButtonGradient,
              onPressed: () async {
                final confirmed = await _confirmarRegistroTelar(
                  state: state,
                  usuario: usuario,
                  accion: 'completar produccion',
                );
                if (confirmed) {
                  await notifier.completarRegistro();
                }
              },
            ),
          ],
          const SizedBox(height: 9),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: state.isBusy ? null : notifier.nuevoRegistro,
              icon: const Icon(Icons.cleaning_services_rounded),
              label: const Text('Nuevo registro'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({
    required String step,
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CorporateTokens.borderSoft),
        boxShadow: CorporateTokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: CorporateTokens.cobalt600.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: CorporateTokens.cobalt600),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: CorporateTokens.navy900,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: CorporateTokens.slate500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: CorporateTokens.navy900,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  step,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _row(double width, List<Widget> children) {
    if (width >= 620) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _withGaps(
          children.map((child) => Expanded(child: child)).toList(),
        ),
      );
    }
    return Column(children: _withGaps(children));
  }

  List<Widget> _withGaps(List<Widget> children, {double gap = 10}) {
    final spaced = <Widget>[];
    for (var index = 0; index < children.length; index++) {
      if (index > 0) spaced.add(SizedBox(height: gap, width: gap));
      spaced.add(children[index]);
    }
    return spaced;
  }

  Widget _miniAction({
    required String label,
    required IconData icon,
    required bool busy,
    required bool enabled,
    required Future<void> Function() onPressed,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(colors: CorporateTokens.primaryButtonGradient),
        boxShadow: [
          BoxShadow(
            color: CorporateTokens.cobalt600.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: enabled ? onPressed : null,
        icon:
            busy
                ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                : Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
        ),
      ),
    );
  }

  Widget _catalogField({
    required String keyName,
    required String label,
    required String hint,
    required IconData icon,
    required List<String> values,
    required IngresoTelarNotifier notifier,
    required bool enabled,
    bool readOnly = false,
  }) {
    return _field(
      keyName: keyName,
      label: label,
      hint: hint,
      icon: icon,
      notifier: notifier,
      enabled: enabled,
      readOnly: readOnly,
      suffixIcon: IconButton(
        onPressed:
            enabled && !readOnly
                ? () => _showPicker(
                  title: label,
                  values: values,
                  current: _controllers[keyName]!.text,
                  onSelected:
                      (value) => notifier.seleccionarCatalogo(keyName, value),
                )
                : null,
        icon: const Icon(Icons.keyboard_arrow_down_rounded),
      ),
    );
  }

  Widget _field({
    required String keyName,
    required String label,
    required String hint,
    required IconData icon,
    required IngresoTelarNotifier notifier,
    required bool enabled,
    bool readOnly = false,
    TextInputType? keyboardType,
    VoidCallback? onEditingComplete,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: _controllers[keyName],
      enabled: enabled,
      readOnly: readOnly,
      onChanged:
          readOnly ? null : (value) => notifier.actualizarCampo(keyName, value),
      onEditingComplete: readOnly ? null : onEditingComplete,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: CorporateTokens.navy900,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: CorporateTokens.slate500),
        suffixIcon: suffixIcon,
      ),
    );
  }

  Widget _readOnly({
    required String keyName,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextFormField(
      controller: _controllers[keyName],
      readOnly: true,
      enabled: false,
      style: const TextStyle(
        color: CorporateTokens.navy900,
        fontWeight: FontWeight.w800,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: CorporateTokens.slate500),
      ),
    );
  }

  Widget _dateField({
    required String keyName,
    required String label,
    required bool enabled,
    required VoidCallback onPick,
  }) {
    return TextFormField(
      controller: _controllers[keyName],
      readOnly: true,
      enabled: enabled,
      style: const TextStyle(
        color: CorporateTokens.navy900,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: 'YYYY-MM-DD',
        prefixIcon: const Icon(
          Icons.event_available_rounded,
          color: CorporateTokens.slate500,
        ),
        suffixIcon: IconButton(
          onPressed: enabled ? onPick : null,
          icon: const Icon(Icons.calendar_month_rounded),
        ),
      ),
      onTap: enabled ? onPick : null,
    );
  }

  Future<void> _showPicker({
    required String title,
    required List<String> values,
    required String current,
    required void Function(String) onSelected,
  }) async {
    final queryController = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        var filtered = values;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.72,
              minChildSize: 0.42,
              maxChildSize: 0.92,
              builder: (context, scrollController) {
                return Container(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    16 + MediaQuery.of(context).viewInsets.bottom,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(26),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: CorporateTokens.borderSoft,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Seleccionar $title',
                        style: const TextStyle(
                          color: CorporateTokens.navy900,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: queryController,
                        autofocus: true,
                        style: const TextStyle(color: CorporateTokens.navy900),
                        decoration: const InputDecoration(
                          hintText: 'Buscar...',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                        onChanged: (query) {
                          final needle = query.trim().toUpperCase();
                          setModalState(() {
                            filtered =
                                needle.isEmpty
                                    ? values
                                    : values
                                        .where(
                                          (item) => item.toUpperCase().contains(
                                            needle,
                                          ),
                                        )
                                        .toList(growable: false);
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child:
                            filtered.isEmpty
                                ? const Center(
                                  child: Text(
                                    'No hay resultados. Puede escribir manualmente.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: CorporateTokens.slate500,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                                : ListView.separated(
                                  controller: scrollController,
                                  itemCount: filtered.length,
                                  separatorBuilder:
                                      (_, __) => const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final value = filtered[index];
                                    final selected =
                                        value.trim().toUpperCase() ==
                                        current.trim().toUpperCase();
                                    return ListTile(
                                      leading: Icon(
                                        selected
                                            ? Icons.check_circle_rounded
                                            : Icons.radio_button_unchecked,
                                        color:
                                            selected
                                                ? CorporateTokens.cobalt600
                                                : CorporateTokens.slate500,
                                      ),
                                      title: Text(
                                        value,
                                        style: const TextStyle(
                                          color: CorporateTokens.navy900,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      onTap: () {
                                        onSelected(value);
                                        Navigator.pop(context);
                                      },
                                    );
                                  },
                                ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
    queryController.dispose();
  }

  Future<void> _pickDate({
    required String current,
    required void Function(DateTime) onPicked,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _parseLegacyDate(current) ?? DateTime.now(),
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2100, 12, 31),
    );
    if (picked != null) onPicked(picked);
  }

  DateTime? _parseLegacyDate(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    final parts = value.split('-');
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    return DateTime(year, month, day);
  }

  Widget _disabledContextButton(String label) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: CorporateTokens.surfaceTop,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CorporateTokens.borderSoft),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.lock_clock_rounded,
            color: CorporateTokens.slate500,
            size: 18,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: CorporateTokens.slate700,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _autofillOperationalDefaults(
    IngresoTelarState state,
    IngresoTelarNotifier notifier,
  ) {
    final hasTelar = _fieldValue(state, 'telar').isNotEmpty;
    if (!hasTelar) return;

    if (_fieldValue(state, 'fecha_inicio').isEmpty) {
      notifier.seleccionarFechaInicio(DateTime.now());
    }
  }

  bool _isProgressLoaded(IngresoTelarState state) {
    return state.estadoActual.toUpperCase() == 'EN PROGRESO' ||
        _fieldValue(state, 'parcial').isNotEmpty;
  }

  bool _isProgressReady(IngresoTelarState state) {
    return _fieldValue(state, 'telar').isNotEmpty &&
        _fieldValue(state, 'articulo').isNotEmpty &&
        _fieldValue(state, 'trama').isNotEmpty;
  }

  bool _isCompletionReady(IngresoTelarState state) {
    return _isProgressReady(state) &&
        _fieldValue(state, 'fecha_final').isNotEmpty;
  }

  String _fieldValue(IngresoTelarState state, String key) {
    return (state.fields[key] ?? '').trim();
  }

  Future<bool> _confirmarRegistroTelar({
    required IngresoTelarState state,
    required String usuario,
    required String accion,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text('Confirmar $accion'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Revise el resumen antes de enviar al backend.',
                  style: TextStyle(color: CorporateTokens.slate700),
                ),
                const SizedBox(height: 12),
                _confirmRow('Telar', _fieldValue(state, 'telar')),
                _confirmRow('Articulo', _fieldValue(state, 'articulo')),
                _confirmRow('Trama', _fieldValue(state, 'trama')),
                _confirmRow('Fecha inicio', _fieldValue(state, 'fecha_inicio')),
                _confirmRow('Fecha final', _fieldValue(state, 'fecha_final')),
                _confirmRow('Operario', usuario),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text('Confirmar'),
              ),
            ],
          ),
    );
    return confirmed == true;
  }

  Widget _confirmRow(String label, String value) {
    final safe = value.trim().isEmpty ? '-' : value.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: CorporateTokens.slate500,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Flexible(
            child: Text(
              safe,
              textAlign: TextAlign.right,
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

  void _syncControllers(Map<String, String> fields) {
    for (final entry in _controllers.entries) {
      final value = fields[entry.key] ?? '';
      if (entry.value.text != value) {
        entry.value.value = TextEditingValue(
          text: value,
          selection: TextSelection.collapsed(offset: value.length),
        );
      }
    }
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool busy;
  final bool enabled;
  final List<Color> colors;
  final Future<void> Function() onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.busy,
    required this.enabled,
    required this.colors,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(colors: colors),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: enabled ? onPressed : null,
        icon:
            busy
                ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                : Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
        ),
      ),
    );
  }
}

const List<String> _fieldOrder = [
  'telar',
  'articulo',
  'pas',
  'ancho_peine',
  'material',
  'color',
  'hilos',
  'mts',
  'titulo',
  'peso_total',
  'trama',
  'parcial',
  'fecha_inicio',
  'fecha_final',
];
