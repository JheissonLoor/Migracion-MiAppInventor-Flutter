import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/datasources/remote/movimiento_telas_remote_datasource.dart';
import '../../providers/auth_provider.dart';
import '../../providers/movimiento_telas_provider.dart';
import '../../widgets/enterprise_backdrop.dart';
import '../../widgets/production/production_visuals.dart';

enum _IngresoTelasMode { none, nuevo, editar }

class IngresoTelasScreen extends ConsumerStatefulWidget {
  const IngresoTelasScreen({super.key});

  @override
  ConsumerState<IngresoTelasScreen> createState() => _IngresoTelasScreenState();
}

class _IngresoTelasScreenState extends ConsumerState<IngresoTelasScreen>
    with SingleTickerProviderStateMixin {
  static const _ops = <String>['', 'OPV', 'OPS'];
  static const _ccs = <String>[
    '',
    '1 - Normal',
    '2 - Dentro del rango',
    '3 - En observacion',
    '4 - Segunda',
    'R - Rechazado',
  ];
  static const _cds = <String>['', 'C', 'D'];

  final _codigoBusqueda = TextEditingController();
  final _numTelar = TextEditingController();
  final _codigoBase = TextEditingController();
  final _correlativo = TextEditingController();
  final _opNumero = TextEditingController();
  final _articulo = TextEditingController();
  final _numPlegador = TextEditingController();
  final _mts = TextEditingController();
  final _ancho = TextEditingController();
  final _peso = TextEditingController();
  final _fechaCorte = TextEditingController();
  final _fechaRevisado = TextEditingController();
  final _numCorte = TextEditingController();
  final _nombre = TextEditingController();
  final _fallaPrincipal = TextEditingController();
  final _fallasSecundarias = TextEditingController();
  final _fallas = List.generate(4, (_) => TextEditingController());

  late final AnimationController _entryController;
  late final Animation<double> _fade;

  _IngresoTelasMode _mode = _IngresoTelasMode.none;
  String _op = '';
  String _cc = '';
  String _cd = '';

  @override
  void initState() {
    super.initState();
    _fechaRevisado.text = _formatDate(DateTime.now());
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 640),
    )..forward();
    _fade = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = ref.read(authProvider).user?.usuario.trim() ?? '';
      if (user.isNotEmpty) {
        _nombre.text = user;
      }
      ref.read(movimientoTelasProvider.notifier).cargarCatalogos();
    });
  }

  @override
  void dispose() {
    _codigoBusqueda.dispose();
    _numTelar.dispose();
    _codigoBase.dispose();
    _correlativo.dispose();
    _opNumero.dispose();
    _articulo.dispose();
    _numPlegador.dispose();
    _mts.dispose();
    _ancho.dispose();
    _peso.dispose();
    _fechaCorte.dispose();
    _fechaRevisado.dispose();
    _numCorte.dispose();
    _nombre.dispose();
    _fallaPrincipal.dispose();
    _fallasSecundarias.dispose();
    for (final controller in _fallas) {
      controller.dispose();
    }
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final state = ref.watch(movimientoTelasProvider);
    final notifier = ref.read(movimientoTelasProvider.notifier);
    final viewportWidth = MediaQuery.of(context).size.width;
    final isTablet = viewportWidth >= 980;
    final horizontalPadding = isTablet ? 22.0 : 14.0;
    final user = auth.user?.usuario.trim() ?? '';
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    if (_nombre.text.trim().isEmpty && user.isNotEmpty) {
      _nombre.text = user;
    }

    ref.listen<MovimientoTelasState>(movimientoTelasProvider, (previous, next) {
      if (!mounted) return;
      _codigoBase.text = next.codigoBase;
      _correlativo.text = next.correlativo;
      _numCorte.text = next.numCorte;
      if (next.edicionData != null &&
          previous?.edicionData != next.edicionData) {
        _aplicarEdicion(next.edicionData!);
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: EnterpriseBackdrop()),
          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  12,
                  horizontalPadding,
                  16,
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.only(bottom: 18 + bottomInset),
                  child: Column(
                    children: [
                      _header(context),
                      if ((state.errorMessage ?? '').isNotEmpty ||
                          (state.message ?? '').isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _banner(state),
                      ],
                      const SizedBox(height: 10),
                      _buildFlowGuide(state),
                      const SizedBox(height: 10),
                      _buildSmartAlerts(state),
                      const SizedBox(height: 10),
                      _modeSelector(state, notifier),
                      if (_mode == _IngresoTelasMode.editar) ...[
                        const SizedBox(height: 10),
                        _editSearchCard(state, notifier),
                      ],
                      if (_mode != _IngresoTelasMode.none) ...[
                        const SizedBox(height: 10),
                        if (isTablet && _mode == _IngresoTelasMode.nuevo)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 5,
                                child: _formCard(state, notifier),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 3,
                                child: _qrCard(state, notifier),
                              ),
                            ],
                          )
                        else
                          Column(
                            children: [
                              _formCard(state, notifier),
                              if (_mode == _IngresoTelasMode.nuevo) ...[
                                const SizedBox(height: 10),
                                _qrCard(state, notifier),
                              ],
                            ],
                          ),
                      ],
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

  Widget _header(BuildContext context) {
    return ProductionHeader(
      title: 'Ingreso de Telas',
      subtitle: 'Registro de corte, calidad, QR e impresion',
      icon: Icons.add_box_rounded,
      onBack: () => Navigator.pop(context),
      accentColor: const Color(0xFF0EA5A4),
    );
  }

  Widget _modeSelector(
    MovimientoTelasState state,
    MovimientoTelasNotifier notifier,
  ) {
    return _card(
      'Operacion',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seleccione primero que va a realizar. Esto replica el flujo MIT: Nuevo o Editar.',
            style: TextStyle(
              color: CorporateTokens.slate500,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 620;
              final buttons = [
                _modeButton(
                  title: 'Nuevo corte',
                  subtitle: 'Generar codigo, registrar corte y emitir QR.',
                  icon: Icons.add_circle_outline_rounded,
                  selected: _mode == _IngresoTelasMode.nuevo,
                  onPressed:
                      state.isBusy
                          ? null
                          : () {
                            _limpiar(notifier, keepMode: true);
                            setState(() => _mode = _IngresoTelasMode.nuevo);
                          },
                ),
                _modeButton(
                  title: 'Editar corte',
                  subtitle: 'Buscar codigo de tela y actualizar datos.',
                  icon: Icons.edit_note_rounded,
                  selected: _mode == _IngresoTelasMode.editar,
                  onPressed:
                      state.isBusy
                          ? null
                          : () {
                            _limpiar(notifier, keepMode: true);
                            setState(() => _mode = _IngresoTelasMode.editar);
                          },
                ),
              ];
              if (stacked) {
                return Column(children: _withSpacing(buttons));
              }
              return Row(
                children:
                    buttons
                        .map((button) => Expanded(child: button))
                        .expand((child) => [child, const SizedBox(width: 10)])
                        .toList()
                      ..removeLast(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _modeButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback? onPressed,
  }) {
    final color = selected ? const Color(0xFF0EA5A4) : CorporateTokens.slate500;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.all(14),
        side: BorderSide(
          color:
              selected ? const Color(0xFF0EA5A4) : CorporateTokens.borderSoft,
          width: selected ? 1.6 : 1,
        ),
        backgroundColor:
            selected ? const Color(0xFFEAFDFC) : const Color(0xFFF8FAFC),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: selected ? CorporateTokens.navy900 : color,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: CorporateTokens.slate500,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (selected)
            const Icon(Icons.check_circle_rounded, color: Color(0xFF0EA5A4)),
        ],
      ),
    );
  }

  Widget _editSearchCard(
    MovimientoTelasState state,
    MovimientoTelasNotifier notifier,
  ) {
    final isBusy = state.isBusy;
    return _card(
      'Buscar tela para editar',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ingrese el CodigoTela exacto. Ejemplo: T30F030626-1-01.',
            style: TextStyle(
              color: CorporateTokens.slate500,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 620;
              final input = _input(
                _codigoBusqueda,
                'Codigo de tela',
                icon: Icons.manage_search_rounded,
              );
              final button = _primaryButton(
                onPressed:
                    isBusy
                        ? null
                        : () =>
                            notifier.buscarTelaParaEditar(_codigoBusqueda.text),
                icon:
                    state.status == MovimientoTelasStatus.searchingEdit
                        ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.search_rounded, size: 18),
                label: 'Buscar',
              );

              if (stacked) {
                return Column(
                  children: [input, const SizedBox(height: 10), button],
                );
              }
              return Row(
                children: [
                  Expanded(child: input),
                  const SizedBox(width: 10),
                  SizedBox(width: 180, child: button),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _formCard(
    MovimientoTelasState state,
    MovimientoTelasNotifier notifier,
  ) {
    final isBusy = state.isBusy;
    final corteReady = _isCorteReady();
    final isEditMode = _mode == _IngresoTelasMode.editar;

    return _card(
      isEditMode ? 'Datos del corte a editar' : 'Datos del corte nuevo',
      Column(
        children: [
          _section(
            icon: Icons.factory_rounded,
            title: 'Identificacion operativa',
            subtitle: 'Datos base para generar codigo y asociar la orden.',
            child: Column(
              children: [
                _adaptiveGrid(
                  mobileColumns: 1,
                  tabletColumns: 3,
                  desktopColumns: 3,
                  children: [
                    _input(
                      _numTelar,
                      'Numero de telar',
                      icon: Icons.precision_manufacturing_rounded,
                      number: true,
                      readOnly: isEditMode,
                    ),
                    DropdownButtonFormField<String>(
                      value: _op,
                      onChanged:
                          isBusy ? null : (v) => setState(() => _op = v ?? ''),
                      decoration: _decoration(
                        'Prefijo OP',
                        Icons.assignment_rounded,
                      ),
                      items:
                          _ops
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e.isEmpty ? 'Seleccione OP' : e),
                                ),
                              )
                              .toList(),
                    ),
                    _input(
                      _opNumero,
                      'Numero de orden',
                      icon: Icons.confirmation_number_rounded,
                      number: true,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                state.articulos.isEmpty
                    ? _input(
                      _articulo,
                      'Articulo',
                      icon: Icons.inventory_2_rounded,
                    )
                    : DropdownButtonFormField<String>(
                      value:
                          _articulo.text.trim().isEmpty
                              ? null
                              : _articulo.text.trim(),
                      onChanged:
                          isBusy
                              ? null
                              : (v) => setState(() => _articulo.text = v ?? ''),
                      decoration: _decoration(
                        'Articulo',
                        Icons.inventory_2_rounded,
                      ),
                      isExpanded: true,
                      items:
                          state.articulos
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                    ),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 720) {
                      return Column(
                        children: [
                          _input(
                            _codigoBase,
                            'Codigo base',
                            icon: Icons.qr_code_2_rounded,
                            readOnly: true,
                          ),
                          const SizedBox(height: 10),
                          _input(
                            _correlativo,
                            'Correlativo',
                            icon: Icons.format_list_numbered_rounded,
                            readOnly: true,
                          ),
                          const SizedBox(height: 10),
                          if (!isEditMode)
                            SizedBox(
                              width: double.infinity,
                              child: _primaryButton(
                                onPressed:
                                    isBusy
                                        ? null
                                        : () => _generarCodigo(notifier),
                                icon:
                                    state.status ==
                                            MovimientoTelasStatus.generatingCode
                                        ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                        : const Icon(
                                          Icons.auto_awesome_rounded,
                                          size: 18,
                                        ),
                                label: 'Generar codigo',
                              ),
                            ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: _input(
                            _codigoBase,
                            'Codigo base',
                            icon: Icons.qr_code_2_rounded,
                            readOnly: true,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _input(
                            _correlativo,
                            'Correlativo',
                            icon: Icons.format_list_numbered_rounded,
                            readOnly: true,
                          ),
                        ),
                        if (!isEditMode) ...[
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 190,
                            child: _primaryButton(
                              onPressed:
                                  isBusy
                                      ? null
                                      : () => _generarCodigo(notifier),
                              icon:
                                  state.status ==
                                          MovimientoTelasStatus.generatingCode
                                      ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                      : const Icon(
                                        Icons.auto_awesome_rounded,
                                        size: 18,
                                      ),
                              label: 'Generar codigo',
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _section(
            icon: Icons.straighten_rounded,
            title: 'Medidas del corte',
            subtitle: 'Metricas principales de produccion para el registro.',
            child: _adaptiveGrid(
              mobileColumns: 2,
              tabletColumns: 4,
              desktopColumns: 5,
              children: [
                _input(
                  _numPlegador,
                  'Num. plegador',
                  icon: Icons.view_timeline_rounded,
                  number: true,
                ),
                _input(
                  _mts,
                  'Metro corte (MTS)',
                  icon: Icons.timeline_rounded,
                  decimal: true,
                ),
                _input(
                  _ancho,
                  'Ancho',
                  icon: Icons.width_full_rounded,
                  decimal: true,
                ),
                _input(
                  _peso,
                  'Peso (KG)',
                  icon: Icons.scale_rounded,
                  decimal: true,
                  suffix: IconButton(
                    tooltip: 'Validar rendimiento',
                    onPressed:
                        isBusy
                            ? null
                            : () => notifier.validarRendimiento(
                              articulo: _articulo.text,
                              mts: _mts.text,
                              peso: _peso.text,
                            ),
                    icon: const Icon(Icons.speed_rounded),
                  ),
                ),
                _input(
                  _numCorte,
                  'Num. corte',
                  icon: Icons.pin_rounded,
                  number: true,
                  readOnly: _codigoBase.text.trim().isNotEmpty,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _section(
            icon: Icons.fact_check_rounded,
            title: 'Control de calidad y fecha',
            subtitle: 'Clasificacion de calidad y trazabilidad temporal.',
            child: _adaptiveGrid(
              mobileColumns: 1,
              tabletColumns: 2,
              desktopColumns: 4,
              children: [
                DropdownButtonFormField<String>(
                  value: _cc,
                  onChanged:
                      isBusy ? null : (v) => setState(() => _cc = v ?? ''),
                  decoration: _decoration(
                    'Clasificacion C.C.',
                    Icons.category_rounded,
                  ),
                  items:
                      _ccs
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(e.isEmpty ? 'Seleccione C.C.' : e),
                            ),
                          )
                          .toList(),
                ),
                DropdownButtonFormField<String>(
                  value: _cd,
                  onChanged:
                      isBusy ? null : (v) => setState(() => _cd = v ?? ''),
                  decoration: _decoration(
                    'Tipo C/D',
                    Icons.rule_folder_rounded,
                  ),
                  items:
                      _cds
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(e.isEmpty ? 'Seleccione C/D' : e),
                            ),
                          )
                          .toList(),
                ),
                _input(
                  _fechaCorte,
                  'Fecha de corte',
                  icon: Icons.event_rounded,
                  readOnly: true,
                  suffix: IconButton(
                    onPressed: _pickFechaCorte,
                    icon: const Icon(Icons.calendar_month_rounded),
                  ),
                ),
                _input(
                  _fechaRevisado,
                  'Fecha de revisado',
                  icon: Icons.today_rounded,
                  readOnly: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _section(
            icon: Icons.report_problem_rounded,
            title: 'Responsable y fallas',
            subtitle:
                'Seleccione desde catalogo igual que en MIT: principal y hasta 4 secundarias.',
            child: Column(
              children: [
                _adaptiveGrid(
                  mobileColumns: 1,
                  tabletColumns: 2,
                  desktopColumns: 3,
                  children: [
                    _responsableField(),
                    _fallaField(
                      controller: _fallaPrincipal,
                      label: 'Falla principal',
                      codigos: state.codigosFalla,
                      enabled: !isBusy,
                      requiredField: true,
                    ),
                    _infoTile(
                      icon: Icons.rule_rounded,
                      title: 'Regla',
                      value: 'La falla principal es obligatoria.',
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _adaptiveGrid(
                  mobileColumns: 1,
                  tabletColumns: 2,
                  desktopColumns: 4,
                  children: [
                    for (var index = 0; index < _fallas.length; index++)
                      _fallaField(
                        controller: _fallas[index],
                        label: 'Falla secundaria ${index + 1}',
                        codigos: state.codigosFalla,
                        enabled: !isBusy,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 560;
              final action = _mainActionButton(
                state: state,
                notifier: notifier,
                isBusy: isBusy,
                corteReady: corteReady,
                isEditMode: isEditMode,
              );
              if (stacked) {
                return Column(
                  children: [
                    action,
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: isBusy ? null : () => _limpiar(notifier),
                        icon: const Icon(Icons.cleaning_services_rounded),
                        label: const Text('Limpiar formulario'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                        ),
                      ),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: action),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isBusy ? null : () => _limpiar(notifier),
                      icon: const Icon(Icons.cleaning_services_rounded),
                      label: const Text('Limpiar formulario'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _mainActionButton({
    required MovimientoTelasState state,
    required MovimientoTelasNotifier notifier,
    required bool isBusy,
    required bool corteReady,
    required bool isEditMode,
  }) {
    if (isEditMode) {
      final editReady = _isEditReady();
      return _primaryButton(
        onPressed:
            isBusy || !editReady ? null : () => _confirmarYEditar(notifier),
        icon:
            state.status == MovimientoTelasStatus.savingEdit
                ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                : const Icon(Icons.save_rounded, size: 18),
        label: 'Guardar edicion',
      );
    }

    return _primaryButton(
      onPressed:
          isBusy || !corteReady
              ? null
              : () => _confirmarYRegistrarCorte(notifier),
      icon:
          state.status == MovimientoTelasStatus.sendingCorte
              ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
              : const Icon(Icons.task_alt_rounded, size: 18),
      label: 'Registrar corte',
    );
  }

  Widget _qrCard(MovimientoTelasState state, MovimientoTelasNotifier notifier) {
    final isBusy = state.isBusy;
    final qrReady = _isQrReady();
    return _card(
      'Etiqueta QR',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Genera, registra e imprime la etiqueta desde este panel.',
            style: TextStyle(
              fontSize: 12,
              color: CorporateTokens.slate500,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          if (state.qrRaw.trim().isEmpty)
            qrReady
                ? SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: isBusy ? null : () => _generarQr(notifier),
                    icon: const Icon(Icons.qr_code_rounded),
                    label: const Text('Paso 4: generar QR'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 46),
                    ),
                  ),
                )
                : _disabledContextButton('Complete datos para generar QR'),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child:
                state.qrRaw.trim().isNotEmpty
                    ? Container(
                      key: const ValueKey('qr-ready'),
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F9FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFD7E6FA)),
                      ),
                      child: Column(
                        children: [
                          QrImageView(
                            data: state.qrRaw,
                            size: 184,
                            version: QrVersions.auto,
                            backgroundColor: Colors.white,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.qrResumen,
                            style: const TextStyle(
                              fontSize: 12,
                              color: CorporateTokens.navy900,
                            ),
                          ),
                        ],
                      ),
                    )
                    : Container(
                      key: const ValueKey('qr-empty'),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7FAFF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE0EBFA)),
                      ),
                      child: const Text(
                        'Aun no hay QR generado.',
                        style: TextStyle(
                          fontSize: 12,
                          color: CorporateTokens.slate500,
                        ),
                      ),
                    ),
          ),
          const SizedBox(height: 12),
          if (state.qrRaw.trim().isNotEmpty && !state.canImprimir)
            _primaryButton(
              onPressed:
                  !state.canRegistrarDato || isBusy
                      ? null
                      : notifier.registrarDatoQr,
              icon: const Icon(Icons.cloud_upload_rounded, size: 18),
              label: 'Paso 5: registrar dato QR',
            ),
          if (state.canImprimir)
            _primaryButton(
              onPressed: isBusy ? null : notifier.imprimirEtiqueta,
              icon: const Icon(Icons.print_rounded, size: 18),
              label: 'Paso 6: imprimir etiqueta',
            ),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: isBusy ? null : notifier.limpiarWorkflowQr,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reiniciar flujo QR'),
          ),
        ],
      ),
    );
  }

  Widget _section({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6FAFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCE8F8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F2FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 17, color: CorporateTokens.cobalt800),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: CorporateTokens.navy900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: CorporateTokens.slate500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _adaptiveGrid({
    required List<Widget> children,
    int mobileColumns = 1,
    int tabletColumns = 2,
    int desktopColumns = 3,
    double spacing = 10,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int columns;
        if (width >= 1100) {
          columns = desktopColumns;
        } else if (width >= 760) {
          columns = tabletColumns;
        } else if (width >= 480) {
          columns = mobileColumns;
        } else {
          columns = 1;
        }

        if (columns < 1) {
          columns = 1;
        }
        if (columns > children.length) {
          columns = children.length;
        }
        if (columns <= 0) {
          columns = 1;
        }

        final itemWidth = (width - ((columns - 1) * spacing)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children:
              children
                  .map((child) => SizedBox(width: itemWidth, child: child))
                  .toList(),
        );
      },
    );
  }

  List<Widget> _withSpacing(List<Widget> children, {double gap = 10}) {
    final result = <Widget>[];
    for (var index = 0; index < children.length; index++) {
      if (index > 0) result.add(SizedBox(height: gap));
      result.add(children[index]);
    }
    return result;
  }

  Widget _infoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD8E4F5)),
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
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: CorporateTokens.slate500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    color: CorporateTokens.navy900,
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

  Widget _responsableField() {
    final value = _nombre.text.trim().isEmpty ? 'Sin usuario' : _nombre.text;
    return _infoTile(
      icon: Icons.badge_rounded,
      title: 'Responsable',
      value: value,
    );
  }

  Widget _fallaField({
    required TextEditingController controller,
    required String label,
    required List<String> codigos,
    required bool enabled,
    bool requiredField = false,
  }) {
    if (codigos.isEmpty) {
      return _input(
        controller,
        requiredField ? '$label *' : label,
        icon:
            requiredField
                ? Icons.warning_amber_rounded
                : Icons.playlist_add_check_rounded,
      );
    }

    final selected = controller.text.trim();
    return TextFormField(
      controller: controller,
      readOnly: true,
      enabled: enabled,
      onTap:
          enabled
              ? () => _showFallaPicker(
                controller: controller,
                label: label,
                codigos: codigos,
                requiredField: requiredField,
              )
              : null,
      decoration: _decoration(
        requiredField ? '$label *' : label,
        requiredField
            ? Icons.warning_amber_rounded
            : Icons.playlist_add_check_rounded,
      ).copyWith(
        hintText: requiredField ? 'Seleccione falla' : 'Sin falla',
        helperText: 'Toque para buscar en ${codigos.length} fallas',
        suffixIcon: IconButton(
          tooltip:
              selected.isNotEmpty && !requiredField
                  ? 'Quitar falla'
                  : 'Buscar falla',
          onPressed:
              !enabled
                  ? null
                  : () {
                    if (selected.isNotEmpty && !requiredField) {
                      setState(controller.clear);
                      return;
                    }
                    _showFallaPicker(
                      controller: controller,
                      label: label,
                      codigos: codigos,
                      requiredField: requiredField,
                    );
                  },
          icon: Icon(
            selected.isNotEmpty && !requiredField
                ? Icons.close_rounded
                : Icons.manage_search_rounded,
          ),
        ),
      ),
      style: const TextStyle(
        color: CorporateTokens.navy900,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Future<void> _showFallaPicker({
    required TextEditingController controller,
    required String label,
    required List<String> codigos,
    required bool requiredField,
  }) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => _FallaPickerSheet(
            title: label,
            codigos: codigos,
            currentValue: controller.text,
            allowClear: !requiredField,
          ),
    );
    if (selected == null || !mounted) return;
    setState(() => controller.text = selected);
  }

  Widget _card(String title, Widget child) {
    return ProductionCard(
      title: title,
      icon: _cardIcon(title),
      accentColor: const Color(0xFF0EA5A4),
      children: [child],
    );
  }

  Widget _banner(MovimientoTelasState state) {
    return ProductionStatusBanner(
      message: state.message,
      errorMessage: state.errorMessage,
    );
  }

  Widget _buildSmartAlerts(MovimientoTelasState state) {
    final alerts = <String>[];
    final error = (state.errorMessage ?? '').trim();
    if (error.isNotEmpty) alerts.add(error);
    if (_mode == _IngresoTelasMode.none) {
      alerts.add(
        'Seleccione Nuevo o Editar para mostrar solo los campos necesarios.',
      );
    }
    if (_mode == _IngresoTelasMode.editar && _codigoBase.text.trim().isEmpty) {
      alerts.add('Modo editar: busque el CodigoTela antes de modificar datos.');
    }
    if (_codigoBase.text.trim().isEmpty && _numTelar.text.trim().isNotEmpty) {
      alerts.add('Genere el codigo para bloquear base, correlativo y corte.');
    }
    if (state.rendimiento != null) {
      alerts.add(state.rendimiento!.message);
    }
    if (_fechaCorte.text.trim().isEmpty) {
      alerts.add('Fecha de corte pendiente. Seleccionela antes de registrar.');
    }
    if (_nombre.text.trim().isNotEmpty) {
      alerts.add('Revisor autocompletado con el usuario activo.');
    }
    if (_isCorteReady()) {
      alerts.add('Datos de corte completos. Revise y registre el corte.');
    }
    if (state.qrRaw.trim().isNotEmpty) {
      alerts.add('QR generado. Registre el dato antes de imprimir etiqueta.');
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
                            : const Color(0xFF0EA5A4),
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

  Widget _buildFlowGuide(MovimientoTelasState state) {
    final hasMode = _mode != _IngresoTelasMode.none;
    final isEditMode = _mode == _IngresoTelasMode.editar;
    final editLoaded = isEditMode && _codigoBase.text.trim().isNotEmpty;
    final baseReady =
        _numTelar.text.trim().isNotEmpty &&
        _op.trim().isNotEmpty &&
        _opNumero.text.trim().isNotEmpty &&
        _articulo.text.trim().isNotEmpty;
    final codeReady =
        _codigoBase.text.trim().isNotEmpty &&
        _correlativo.text.trim().isNotEmpty &&
        _numCorte.text.trim().isNotEmpty;
    final corteReady = _isCorteReady();
    final qrReady = state.qrRaw.trim().isNotEmpty;
    final hasError = (state.errorMessage ?? '').trim().isNotEmpty;

    final signal =
        hasError
            ? OperationSignalLevel.error
            : !hasMode
            ? OperationSignalLevel.neutral
            : isEditMode
            ? (_isEditReady()
                ? OperationSignalLevel.ready
                : (editLoaded
                    ? OperationSignalLevel.warning
                    : OperationSignalLevel.neutral))
            : (qrReady
                ? OperationSignalLevel.ready
                : (codeReady || baseReady
                    ? OperationSignalLevel.warning
                    : OperationSignalLevel.neutral));
    final helper =
        hasError
            ? state.errorMessage!.trim()
            : !hasMode
            ? 'Seleccione Nuevo o Editar para iniciar el flujo correcto.'
            : isEditMode && !editLoaded
            ? 'Busque el CodigoTela antes de editar.'
            : isEditMode && _isEditReady()
            ? 'Edicion lista. Revise y guarde cambios.'
            : isEditMode
            ? 'Complete articulo, medidas, calidad, fecha y falla principal.'
            : qrReady
            ? 'QR listo. Registre el dato y luego imprima la etiqueta.'
            : corteReady
            ? 'Datos completos. Puede registrar corte o generar QR.'
            : codeReady
            ? 'Complete calidad, fechas y medidas antes de registrar.'
            : 'Llene telar, OP y articulo; luego genere el codigo.';

    return OperationFlowGuide(
      title: 'Guia operativa de ingreso de telas',
      statusLabel:
          hasError
              ? 'REVISAR'
              : !hasMode
              ? 'SELECCIONAR'
              : isEditMode
              ? (_isEditReady() ? 'EDICION LISTA' : 'EDITANDO')
              : (qrReady ? 'QR LISTO' : (corteReady ? 'LISTO' : 'PENDIENTE')),
      helperText: helper,
      signal: signal,
      accentColor: const Color(0xFF0EA5A4),
      steps: [
        OperationStepData(
          label: 'Modo',
          icon: Icons.touch_app_rounded,
          done: hasMode,
          active: !hasMode,
        ),
        OperationStepData(
          label: isEditMode ? 'Buscar tela' : 'Generar codigo',
          icon: isEditMode ? Icons.manage_search_rounded : Icons.tag_rounded,
          done: isEditMode ? editLoaded : codeReady,
          active:
              hasMode && (isEditMode ? !editLoaded : baseReady && !codeReady),
        ),
        OperationStepData(
          label: isEditMode ? 'Editar campos' : 'Completar corte',
          icon: Icons.content_cut_rounded,
          done: isEditMode ? _isEditReady() : corteReady,
          active:
              isEditMode
                  ? editLoaded && !_isEditReady()
                  : codeReady && !corteReady,
        ),
        OperationStepData(
          label: isEditMode ? 'Guardar' : 'QR e impresion',
          icon: isEditMode ? Icons.save_rounded : Icons.qr_code_rounded,
          done: isEditMode ? _isEditReady() : qrReady,
          active: isEditMode ? _isEditReady() : corteReady && !qrReady,
        ),
      ],
      summary: [
        OperationSummaryItem(
          label: 'Codigo',
          value: _codigoCompleto(),
          icon: Icons.confirmation_number_rounded,
        ),
        OperationSummaryItem(
          label: 'Articulo',
          value: _articulo.text,
          icon: Icons.inventory_2_rounded,
        ),
        OperationSummaryItem(
          label: 'MTS / KG',
          value: '${_mts.text} / ${_peso.text}',
          icon: Icons.scale_rounded,
        ),
        OperationSummaryItem(
          label: 'Revisor',
          value: _nombre.text,
          icon: Icons.badge_rounded,
        ),
      ],
    );
  }

  IconData _cardIcon(String title) {
    final value = title.toLowerCase();
    if (value.contains('qr')) return Icons.qr_code_rounded;
    if (value.contains('corte')) return Icons.content_cut_rounded;
    return Icons.assignment_rounded;
  }

  Widget _primaryButton({
    required VoidCallback? onPressed,
    required Widget icon,
    required String label,
  }) {
    final isEnabled = onPressed != null;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              isEnabled
                  ? const [Color(0xFF265ECF), Color(0xFF1B86D7)]
                  : const [Color(0xFFA0AEC0), Color(0xFF94A3B8)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow:
            isEnabled
                ? const [
                  BoxShadow(
                    color: Color(0x331B86D7),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ]
                : const [],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon,
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          disabledBackgroundColor: Colors.transparent,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }

  Widget _disabledContextButton(String label) {
    return Container(
      width: double.infinity,
      height: 46,
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

  Widget _input(
    TextEditingController controller,
    String label, {
    required IconData icon,
    bool readOnly = false,
    bool number = false,
    bool decimal = false,
    Widget? suffix,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      keyboardType:
          decimal
              ? const TextInputType.numberWithOptions(decimal: true)
              : (number ? TextInputType.number : TextInputType.text),
      style: const TextStyle(
        color: Color(0xFF0B1B33),
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      decoration: _decoration(label, icon).copyWith(suffixIcon: suffix),
    );
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: CorporateTokens.slate500,
        fontWeight: FontWeight.w600,
      ),
      floatingLabelStyle: const TextStyle(
        color: CorporateTokens.cobalt600,
        fontWeight: FontWeight.w700,
      ),
      prefixIcon: Icon(icon, color: CorporateTokens.slate500, size: 20),
      filled: true,
      fillColor: const Color(0xFFFDFEFF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD8E4F5)),
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

  Future<void> _generarCodigo(MovimientoTelasNotifier notifier) async {
    final fecha = _parseDate(_fechaRevisado.text) ?? DateTime.now();
    if (_fechaCorte.text.trim().isEmpty) {
      _fechaCorte.text = _formatDate(DateTime.now());
    }
    await notifier.generarCodigo(
      numTelar: _numTelar.text,
      fechaRevisado: fecha,
    );
  }

  Future<void> _registrarCorte(MovimientoTelasNotifier notifier) async {
    final error = _validarCorte();
    if (error != null) return notifier.notificarError(error);

    final fallas = _fallasSeleccionadas();

    final payload = MovimientoTelaCortePayload(
      codigoBase: _codigoBase.text,
      correlativo: _correlativo.text,
      opPrefijo: _op,
      opNumero: _opNumero.text,
      articulo: _articulo.text,
      numTelar: _numTelar.text,
      numPlegador: _numPlegador.text,
      metroCorte: _mts.text,
      ancho: _ancho.text,
      peso: _peso.text,
      cc: _cc,
      cd: _cd,
      fechaCorte: _fechaCorte.text,
      fechaRevisado: _fechaRevisado.text,
      fallasSecundarias: fallas,
      numCorte: _numCorte.text,
      nombre: _nombre.text,
      fallaPrincipal: _fallaPrincipal.text,
    );
    await notifier.registrarCorte(payload);
  }

  Future<void> _confirmarYRegistrarCorte(
    MovimientoTelasNotifier notifier,
  ) async {
    final error = _validarCorte();
    if (error != null) return notifier.notificarError(error);

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: const Text('Confirmar corte'),
            content: SizedBox(
              width: 520,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _confirmRow('Codigo', _codigoCompleto()),
                  _confirmRow('Telar', _numTelar.text),
                  _confirmRow('OP', '$_op${_opNumero.text}'),
                  _confirmRow('Articulo', _articulo.text),
                  _confirmRow('MTS / KG', '${_mts.text} / ${_peso.text}'),
                  _confirmRow('Revisor', _nombre.text),
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
    if (confirmed == true) {
      await _registrarCorte(notifier);
    }
  }

  Future<void> _confirmarYEditar(MovimientoTelasNotifier notifier) async {
    final error = _validarEdicion();
    if (error != null) return notifier.notificarError(error);

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: const Text('Confirmar edicion'),
            content: SizedBox(
              width: 520,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _confirmRow('Codigo', _codigoCompleto()),
                  _confirmRow('OP', '$_op${_opNumero.text}'),
                  _confirmRow('Articulo', _articulo.text),
                  _confirmRow('MTS / KG', '${_mts.text} / ${_peso.text}'),
                  _confirmRow('Falla principal', _fallaPrincipal.text),
                  _confirmRow('Responsable', _nombre.text),
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
                icon: const Icon(Icons.save_rounded),
                label: const Text('Guardar edicion'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await _editarTela(notifier);
    }
  }

  Future<void> _editarTela(MovimientoTelasNotifier notifier) async {
    final error = _validarEdicion();
    if (error != null) return notifier.notificarError(error);

    final payload = MovimientoTelaEditPayload(
      codigoTela: _codigoCompleto(),
      opPrefijo: _op,
      opNumero: _opNumero.text,
      articulo: _articulo.text,
      metroCorte: _mts.text,
      ancho: _ancho.text,
      peso: _peso.text,
      cc: _cc,
      cd: _cd,
      fechaCorte: _fechaCorte.text,
      fallaPrincipal: _fallaPrincipal.text,
      fallasSecundarias: _fallasSeleccionadas(),
    );

    await notifier.editarTelaCruda(payload);
  }

  void _generarQr(MovimientoTelasNotifier notifier) {
    final error = _validarQr();
    if (error != null) {
      return notifier.notificarError(error);
    }
    notifier.generarQr(
      codigoBase: _codigoBase.text,
      correlativo: _correlativo.text,
      numCorte: _numCorte.text,
      numTelar: _numTelar.text,
      opPrefijo: _op,
      opNumero: _opNumero.text,
      articulo: _articulo.text,
      mts: _mts.text,
      peso: _peso.text,
      nombre: _nombre.text,
    );
  }

  String? _validarCorte() {
    if (_codigoBase.text.trim().isEmpty) {
      return 'Primero genere el codigo.';
    }
    if (_numTelar.text.trim().isEmpty ||
        _correlativo.text.trim().isEmpty ||
        _articulo.text.trim().isEmpty ||
        _peso.text.trim().isEmpty ||
        _ancho.text.trim().isEmpty ||
        _mts.text.trim().isEmpty ||
        _fechaCorte.text.trim().isEmpty ||
        _numCorte.text.trim().isEmpty ||
        _op.trim().isEmpty ||
        _opNumero.text.trim().isEmpty ||
        _cc.trim().isEmpty ||
        _cd.trim().isEmpty) {
      return 'Complete todos los campos obligatorios de CORTE.';
    }
    if (_fallaPrincipal.text.trim().isEmpty) {
      return 'Ingrese la falla principal.';
    }
    return null;
  }

  String? _validarEdicion() {
    if (_codigoCompleto().trim().isEmpty) {
      return 'Primero busque un CodigoTela para editar.';
    }
    if (_articulo.text.trim().isEmpty ||
        _mts.text.trim().isEmpty ||
        _ancho.text.trim().isEmpty ||
        _peso.text.trim().isEmpty ||
        _fechaCorte.text.trim().isEmpty ||
        _op.trim().isEmpty ||
        _opNumero.text.trim().isEmpty ||
        _cc.trim().isEmpty ||
        _cd.trim().isEmpty) {
      return 'Complete los campos obligatorios de edicion.';
    }
    if (_fallaPrincipal.text.trim().isEmpty) {
      return 'Seleccione la falla principal.';
    }
    return null;
  }

  bool _isCorteReady() => _validarCorte() == null;

  bool _isQrReady() => _validarQr() == null;

  bool _isEditReady() => _validarEdicion() == null;

  String? _validarQr() {
    if (_codigoBase.text.trim().isEmpty ||
        _correlativo.text.trim().isEmpty ||
        _numCorte.text.trim().isEmpty ||
        _numTelar.text.trim().isEmpty ||
        _op.trim().isEmpty ||
        _opNumero.text.trim().isEmpty ||
        _articulo.text.trim().isEmpty ||
        _mts.text.trim().isEmpty ||
        _peso.text.trim().isEmpty ||
        _nombre.text.trim().isEmpty) {
      return 'Complete campos obligatorios antes de generar QR.';
    }
    return null;
  }

  Future<void> _pickFechaCorte() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 3),
    );
    if (date != null) {
      _fechaCorte.text = _formatDate(date);
    }
  }

  List<String> _fallasSeleccionadas() {
    return _fallas
        .map((controller) => controller.text.trim())
        .where((value) => value.isNotEmpty)
        .take(4)
        .toList(growable: false);
  }

  String _codigoCompleto() {
    final base = _codigoBase.text.trim();
    final correlativo = _correlativo.text.trim();
    if (base.isEmpty) return correlativo;
    if (base.endsWith('-')) return '$base$correlativo';
    return base;
  }

  void _aplicarEdicion(MovimientoTelaEdicionData data) {
    _numTelar.text = data.numTelar;
    _codigoBase.text = data.codigoBase;
    _correlativo.text = data.correlativo;
    _op = _ops.contains(data.opPrefijo) ? data.opPrefijo : '';
    _opNumero.text = data.opNumero;
    _articulo.text = data.articulo;
    _numPlegador.text = data.numPlegador;
    _mts.text = data.metroCorte;
    _ancho.text = data.ancho;
    _peso.text = data.peso;
    _cc = _ccs.contains(data.cc) ? data.cc : '';
    _cd = _cds.contains(data.cd) ? data.cd : '';
    _fechaCorte.text = data.fechaCorte;
    _fechaRevisado.text =
        data.fechaRevisado.isNotEmpty
            ? data.fechaRevisado
            : _formatDate(DateTime.now());
    _numCorte.text = data.numCorte;
    _nombre.text = data.nombre;
    _fallaPrincipal.text = data.fallaPrincipal;
    for (var index = 0; index < _fallas.length; index++) {
      _fallas[index].text =
          index < data.fallasSecundarias.length
              ? data.fallasSecundarias[index]
              : '';
    }
    setState(() {});
  }

  void _limpiar(MovimientoTelasNotifier notifier, {bool keepMode = false}) {
    _numTelar.clear();
    _codigoBusqueda.clear();
    _codigoBase.clear();
    _correlativo.clear();
    _opNumero.clear();
    _articulo.clear();
    _numPlegador.clear();
    _mts.clear();
    _ancho.clear();
    _peso.clear();
    _fechaCorte.clear();
    _fechaRevisado.text = _formatDate(DateTime.now());
    _numCorte.clear();
    _fallaPrincipal.clear();
    _fallasSecundarias.clear();
    for (final controller in _fallas) {
      controller.clear();
    }
    _op = '';
    _cc = '';
    _cd = '';
    if (!keepMode) {
      _mode = _IngresoTelasMode.none;
    }
    notifier.resetFormulario();
    setState(() {});
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
            width: 110,
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

  String _formatDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    return '$dd/$mm/${date.year}';
  }

  DateTime? _parseDate(String raw) {
    final parts = raw.split('/');
    if (parts.length != 3) {
      return null;
    }
    final dd = int.tryParse(parts[0]);
    final mm = int.tryParse(parts[1]);
    final yy = int.tryParse(parts[2]);
    if (dd == null || mm == null || yy == null) {
      return null;
    }
    return DateTime(yy, mm, dd);
  }
}

class _FallaPickerSheet extends StatefulWidget {
  final String title;
  final List<String> codigos;
  final String currentValue;
  final bool allowClear;

  const _FallaPickerSheet({
    required this.title,
    required this.codigos,
    required this.currentValue,
    required this.allowClear,
  });

  @override
  State<_FallaPickerSheet> createState() => _FallaPickerSheetState();
}

class _FallaPickerSheetState extends State<_FallaPickerSheet> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredCodigos();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.48,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
        return AnimatedPadding(
          duration: CorporateTokens.motionFast,
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: CorporateTokens.slate300,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: CorporateTokens.primaryButtonGradient,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.manage_search_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: const TextStyle(
                                color: CorporateTokens.navy900,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              '${widget.codigos.length} codigos disponibles',
                              style: const TextStyle(
                                color: CorporateTokens.slate500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: TextField(
                    controller: _search,
                    autofocus: true,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Buscar por codigo o descripcion',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(
                          color: CorporateTokens.borderSoft,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(
                          color: CorporateTokens.borderSoft,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (filtered.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text(
                        'No hay coincidencias',
                        style: TextStyle(
                          color: CorporateTokens.slate500,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
                      itemCount: filtered.length + (widget.allowClear ? 1 : 0),
                      separatorBuilder:
                          (_, __) => const Divider(
                            height: 1,
                            color: CorporateTokens.borderSoft,
                          ),
                      itemBuilder: (context, index) {
                        if (widget.allowClear && index == 0) {
                          return ListTile(
                            leading: const Icon(Icons.close_rounded),
                            title: const Text('Sin falla'),
                            subtitle: const Text('Limpiar esta seleccion'),
                            onTap: () => Navigator.pop(context, ''),
                          );
                        }

                        final item =
                            filtered[index - (widget.allowClear ? 1 : 0)];
                        final selected = item == widget.currentValue.trim();
                        return ListTile(
                          selected: selected,
                          selectedTileColor: CorporateTokens.cobalt600
                              .withValues(alpha: 0.08),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          leading: Icon(
                            selected
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color:
                                selected
                                    ? CorporateTokens.cobalt600
                                    : CorporateTokens.slate500,
                          ),
                          title: Text(
                            item,
                            style: const TextStyle(
                              color: CorporateTokens.navy900,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          onTap: () => Navigator.pop(context, item),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<String> _filteredCodigos() {
    final query = _normalize(_search.text);
    if (query.isEmpty) return widget.codigos;
    return widget.codigos
        .where((item) => _normalize(item).contains(query))
        .toList(growable: false);
  }

  String _normalize(String value) {
    return value.toLowerCase().trim();
  }
}
