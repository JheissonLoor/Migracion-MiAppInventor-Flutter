import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/datasources/remote/movimiento_telas_remote_datasource.dart';
import '../../providers/auth_provider.dart';
import '../../providers/movimiento_telas_provider.dart';
import '../../widgets/enterprise_backdrop.dart';

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

  late final AnimationController _entryController;
  late final Animation<double> _fade;

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
    if (_nombre.text.trim().isEmpty && user.isNotEmpty) {
      _nombre.text = user;
    }

    ref.listen<MovimientoTelasState>(movimientoTelasProvider, (_, next) {
      if (!mounted) return;
      _codigoBase.text = next.codigoBase;
      if (next.correlativo.trim().isNotEmpty) {
        _correlativo.text = next.correlativo;
      }
      if (next.numCorte.trim().isNotEmpty) {
        _numCorte.text = next.numCorte;
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
                child: Column(
                  children: [
                    _header(context),
                    if ((state.errorMessage ?? '').isNotEmpty ||
                        (state.message ?? '').isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _banner(state),
                    ],
                    const SizedBox(height: 10),
                    Expanded(
                      child: SingleChildScrollView(
                        child:
                            isTablet
                                ? Row(
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
                                : Column(
                                  children: [
                                    _formCard(state, notifier),
                                    const SizedBox(height: 10),
                                    _qrCard(state, notifier),
                                  ],
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

  Widget _header(BuildContext context) {
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ingreso de Telas',
                style: TextStyle(
                  color: CorporateTokens.navy900,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Registro de corte - movimientoTelas (modo nuevo)',
                style: TextStyle(color: CorporateTokens.slate500, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _pill('Enterprise 2026'),
                  const SizedBox(width: 6),
                  _pill('Operacion critica'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _formCard(
    MovimientoTelasState state,
    MovimientoTelasNotifier notifier,
  ) {
    final isBusy = state.isBusy;
    final fallaActual = _fallaPrincipal.text.trim();
    final fallaCatalogoValue =
        state.codigosFalla.contains(fallaActual) ? fallaActual : null;

    return _card(
      'Datos del corte',
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
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 190,
                          child: _primaryButton(
                            onPressed:
                                isBusy ? null : () => _generarCodigo(notifier),
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
                ),
                _input(
                  _numCorte,
                  'Num. corte',
                  icon: Icons.pin_rounded,
                  number: true,
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
                'Control de defecto principal y observaciones complementarias.',
            child: Column(
              children: [
                _adaptiveGrid(
                  mobileColumns: 1,
                  tabletColumns: 2,
                  desktopColumns: 3,
                  children: [
                    _input(
                      _nombre,
                      'Revisador',
                      icon: Icons.badge_rounded,
                      readOnly: true,
                    ),
                    _input(
                      _fallaPrincipal,
                      'Falla principal',
                      icon: Icons.warning_amber_rounded,
                    ),
                    state.codigosFalla.isEmpty
                        ? _infoTile(
                          icon: Icons.info_outline_rounded,
                          title: 'Catalogo de fallas',
                          value: 'Sin codigos cargados',
                        )
                        : DropdownButtonFormField<String>(
                          value: fallaCatalogoValue,
                          onChanged:
                              isBusy
                                  ? null
                                  : (v) => setState(
                                    () => _fallaPrincipal.text = v ?? '',
                                  ),
                          decoration: _decoration(
                            'Codigo falla sugerido',
                            Icons.list_alt_rounded,
                          ),
                          isExpanded: true,
                          items:
                              state.codigosFalla
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ),
                                  )
                                  .toList(),
                        ),
                  ],
                ),
                const SizedBox(height: 10),
                _input(
                  _fallasSecundarias,
                  'Fallas secundarias (separadas por ;)',
                  icon: Icons.grid_view_rounded,
                  maxLines: 2,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 560;
              if (stacked) {
                return Column(
                  children: [
                    _primaryButton(
                      onPressed:
                          isBusy ? null : () => _registrarCorte(notifier),
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
                    ),
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
                  Expanded(
                    child: _primaryButton(
                      onPressed:
                          isBusy ? null : () => _registrarCorte(notifier),
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
                    ),
                  ),
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

  Widget _qrCard(MovimientoTelasState state, MovimientoTelasNotifier notifier) {
    final isBusy = state.isBusy;
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
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isBusy ? null : () => _generarQr(notifier),
              icon: const Icon(Icons.qr_code_rounded),
              label: const Text('Generar QR'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 46)),
            ),
          ),
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
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 360) {
                return Column(
                  children: [
                    _primaryButton(
                      onPressed:
                          !state.canRegistrarDato || isBusy
                              ? null
                              : notifier.registrarDatoQr,
                      icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                      label: 'Registrar dato',
                    ),
                    const SizedBox(height: 10),
                    _primaryButton(
                      onPressed:
                          !state.canImprimir || isBusy
                              ? null
                              : notifier.imprimirEtiqueta,
                      icon: const Icon(Icons.print_rounded, size: 18),
                      label: 'Imprimir etiqueta',
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: _primaryButton(
                      onPressed:
                          !state.canRegistrarDato || isBusy
                              ? null
                              : notifier.registrarDatoQr,
                      icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                      label: 'Registrar dato',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _primaryButton(
                      onPressed:
                          !state.canImprimir || isBusy
                              ? null
                              : notifier.imprimirEtiqueta,
                      icon: const Icon(Icons.print_rounded, size: 18),
                      label: 'Imprimir etiqueta',
                    ),
                  ),
                ],
              );
            },
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

  Widget _card(String title, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFEFFFF), Color(0xFFF5F9FF)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD6E3F5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A05102A),
            blurRadius: 22,
            offset: Offset(0, 8),
          ),
          BoxShadow(
            color: Color(0x140A4EA3),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FF),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFCAE0FA)),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: CorporateTokens.navy900,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _banner(MovimientoTelasState state) {
    final isError = (state.errorMessage ?? '').isNotEmpty;
    final text = isError ? state.errorMessage! : state.message!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: isError ? const Color(0xFFFFE9E9) : const Color(0xFFE9F8EE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isError ? const Color(0xFFF8B4B4) : const Color(0xFF9BDBAF),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline,
            size: 18,
            color: isError ? const Color(0xFFB91C1C) : const Color(0xFF166534),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: CorporateTokens.navy900,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFCAE0FA)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF1A4A86),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
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
    await notifier.generarCodigo(
      numTelar: _numTelar.text,
      fechaRevisado: fecha,
    );
  }

  Future<void> _registrarCorte(MovimientoTelasNotifier notifier) async {
    final error = _validarCorte();
    if (error != null) return notifier.notificarError(error);

    final fallas =
        _fallasSecundarias.text
            .split(';')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .take(4)
            .toList();

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

  void _generarQr(MovimientoTelasNotifier notifier) {
    final error = _validarQr();
    if (error != null) {
      return notifier.notificarError(error);
    }
    notifier.generarQr(
      codigoBase: _codigoBase.text,
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

  String? _validarQr() {
    if (_codigoBase.text.trim().isEmpty ||
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

  void _limpiar(MovimientoTelasNotifier notifier) {
    _numTelar.clear();
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
    _op = '';
    _cc = '';
    _cd = '';
    notifier.resetFormulario();
    setState(() {});
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
