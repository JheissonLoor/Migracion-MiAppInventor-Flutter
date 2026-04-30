import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inventario_cero_provider.dart';
import '../../widgets/local_api_status_chip.dart';
import '../../widgets/scanner/qr_scanner_page.dart';

class InventarioCeroScreen extends ConsumerStatefulWidget {
  const InventarioCeroScreen({super.key});

  @override
  ConsumerState<InventarioCeroScreen> createState() =>
      _InventarioCeroScreenState();
}

class _InventarioCeroScreenState extends ConsumerState<InventarioCeroScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _qrController;
  late final TextEditingController _pesoContenedorController;
  late final TextEditingController _cantidadBobinasController;
  late final TextEditingController _cantidadReenconadoController;
  late final TextEditingController _pesoBrutoController;
  late final TextEditingController _guiaController;
  late final TextEditingController _observacionesController;

  late final AnimationController _entryController;

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
    _pesoContenedorController = TextEditingController(text: '0.50');
    _cantidadBobinasController = TextEditingController();
    _cantidadReenconadoController = TextEditingController(text: '0');
    _pesoBrutoController = TextEditingController();
    _guiaController = TextEditingController();
    _observacionesController = TextEditingController();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 860),
    )..forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _qrController.dispose();
    _pesoContenedorController.dispose();
    _cantidadBobinasController.dispose();
    _cantidadReenconadoController.dispose();
    _pesoBrutoController.dispose();
    _guiaController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inventarioCeroProvider);
    final notifier = ref.read(inventarioCeroProvider.notifier);
    final usuario = ref.watch(authProvider).user?.usuario ?? 'OPERARIO';
    final sidePadding = MediaQuery.sizeOf(context).width >= 920 ? 28.0 : 16.0;

    _syncControllers(state);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              CorporateTokens.surfaceTop,
              CorporateTokens.surfaceBottom,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(sidePadding, 12, sidePadding, 16),
            child: Column(
              children: [
                _buildHeader(context),
                const SizedBox(height: 10),
                _buildBanner(state),
                const SizedBox(height: 10),
                Expanded(
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        children: [
                          _StaggerReveal(
                            controller: _entryController,
                            start: 0.05,
                            end: 0.56,
                            child: _buildQrCard(state, notifier),
                          ),
                          const SizedBox(height: 10),
                          _StaggerReveal(
                            controller: _entryController,
                            start: 0.14,
                            end: 0.74,
                            child: _buildPesosCard(state, notifier),
                          ),
                          const SizedBox(height: 10),
                          _StaggerReveal(
                            controller: _entryController,
                            start: 0.24,
                            end: 0.94,
                            child: _buildSubmitCard(
                              state: state,
                              notifier: notifier,
                              usuario: usuario,
                            ),
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
    );
  }

  Future<void> _scanQr(
    InventarioCeroNotifier notifier,
    InventarioCeroState state,
  ) async {
    if (state.isBusy) return;

    final result = await openQrScanner(
      context,
      title: 'Escanear QR para inventario',
    );
    if (!mounted || result == null || result.trim().isEmpty) return;

    _qrController.text = result;
    notifier.setQrRaw(result);
  }

  void _syncControllers(InventarioCeroState state) {
    // Mantiene UI y provider alineados cuando el parseo completa campos automaticamente.
    _setControllerText(_cantidadBobinasController, state.cantidadBobinas);
    _setControllerText(_cantidadReenconadoController, state.cantidadReenconado);
    _setControllerText(_pesoBrutoController, state.pesoBruto);
    _setControllerText(_pesoContenedorController, state.pesoContenedor);
    _setControllerText(_guiaController, state.guia);
    _setControllerText(_observacionesController, state.observaciones);
  }

  void _setControllerText(TextEditingController controller, String value) {
    if (controller.text == value) return;
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
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
          icon: const Icon(Icons.arrow_back_rounded, color: CorporateTokens.navy900),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Inventario fisico cero',
                style: TextStyle(
                  color: CorporateTokens.navy900,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Validacion PCP + registro controlado en backend',
                style: TextStyle(color: CorporateTokens.slate500, fontSize: 12),
              ),
            ],
          ),
        ),
        const LocalApiStatusChip(compact: true),
      ],
    );
  }

  Widget _buildBanner(InventarioCeroState state) {
    final hasError = (state.errorMessage ?? '').isNotEmpty;
    final hasMessage = (state.message ?? '').isNotEmpty;
    if (!hasError && !hasMessage) return const SizedBox.shrink();

    final isError = hasError;
    final bgColor = isError ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7);
    final borderColor = isError ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC);
    final iconColor = isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A);
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

  Widget _buildQrCard(
    InventarioCeroState state,
    InventarioCeroNotifier notifier,
  ) {
    return _GlassBlock(
      title: 'Lectura QR de hilos',
      child: Column(
        children: [
          TextFormField(
            controller: _qrController,
            onChanged: notifier.setQrRaw,
            minLines: 2,
            maxLines: 4,
            style: const TextStyle(color: CorporateTokens.navy900),
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return 'Ingrese o escanee el QR';
              }
              return null;
            },
            decoration: _inputDecoration(
              label: 'Codigo QR',
              hint: 'Formato hilos 14/16 campos',
              icon: Icons.qr_code_2_rounded,
              suffixIcon: IconButton(
                onPressed: () => _scanQr(notifier, state),
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
                            if (_formKey.currentState?.validate() != true) {
                              return;
                            }
                            await notifier.parsearQr();
                          },
                  icon:
                      state.status == InventarioCeroStatus.parsingQr
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Icon(Icons.auto_awesome_rounded),
                  label: const Text('Parsear QR'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: CorporateTokens.cobalt600,
                    side: BorderSide(
                      color: CorporateTokens.cobalt600.withValues(alpha: 0.30),
                    ),
                    minimumSize: const Size.fromHeight(44),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      state.isBusy || state.parsed == null
                          ? null
                          : () => notifier.verificarPcp(),
                  icon:
                      state.status == InventarioCeroStatus.verifyingPcp
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Icon(Icons.shield_outlined),
                  label: const Text('Verificar PCP'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: CorporateTokens.cobalt600,
                    side: BorderSide(
                      color: CorporateTokens.cobalt600.withValues(alpha: 0.30),
                    ),
                    minimumSize: const Size.fromHeight(44),
                  ),
                ),
              ),
            ],
          ),
          if (state.parsed != null) ...[
            const SizedBox(height: 10),
            _buildParsedSummary(state),
          ],
        ],
      ),
    );
  }

  Widget _buildParsedSummary(InventarioCeroState state) {
    final parsed = state.parsed!;
    final verification = state.verification;

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
            'Resumen de QR',
            style: TextStyle(
              color: CorporateTokens.navy900,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          _infoRow('PCP', parsed.codigoPcp),
          _infoRow('Kardex', parsed.codigoKardex),
          _infoRow('Material', '${parsed.material} ${parsed.titulo}'),
          _infoRow('Color/Lote', '${parsed.color} / ${parsed.lote}'),
          _infoRow('Proveedor', parsed.proveedor),
          _infoRow(
            'Cajas/Bobinas',
            '${parsed.numCajas.toStringAsFixed(0)} / ${parsed.totalBobinas.toStringAsFixed(0)}',
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color:
                  (verification?.existe ?? false)
                      ? const Color(0xFFFEE2E2)
                      : const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color:
                    (verification?.existe ?? false)
                        ? const Color(0xFFFCA5A5)
                        : const Color(0xFF86EFAC),
              ),
            ),
            child: Text(
              verification == null
                  ? 'Estado PCP: pendiente de verificacion'
                  : verification.existe
                  ? 'PCP ya existe: ${verification.almacen}-${verification.ubicacion} (fila ${verification.fila})'
                  : 'PCP disponible para registro en inventario cero',
              style: const TextStyle(
                color: CorporateTokens.navy900,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPesosCard(
    InventarioCeroState state,
    InventarioCeroNotifier notifier,
  ) {
    return _GlassBlock(
      title: 'Peso neto y contenedor',
      child: Column(
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _tipoChip(state, notifier, TipoContenedor.caja, 'Caja'),
              _tipoChip(state, notifier, TipoContenedor.bolsa, 'Bolsa'),
              _tipoChip(state, notifier, TipoContenedor.saco, 'Saco'),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _pesoContenedorController,
            onChanged: notifier.setPesoContenedor,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: CorporateTokens.navy900),
            validator: (value) {
              if (_toDouble(value ?? '') < 0) {
                return 'Peso contenedor invalido';
              }
              return null;
            },
            decoration: _inputDecoration(
              label: 'Peso contenedor',
              hint: '0.00',
              icon: Icons.inventory_rounded,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _cantidadBobinasController,
                  onChanged: notifier.setCantidadBobinas,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(color: CorporateTokens.navy900),
                  validator: (value) {
                    if (_toDouble(value ?? '') <= 0) {
                      return 'Bobinas invalida';
                    }
                    return null;
                  },
                  decoration: _inputDecoration(
                    label: 'Cant. bobinas',
                    hint: '0',
                    icon: Icons.straighten_rounded,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _cantidadReenconadoController,
                  onChanged: notifier.setCantidadReenconado,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(color: CorporateTokens.navy900),
                  decoration: _inputDecoration(
                    label: 'Cant. reenconado',
                    hint: '0',
                    icon: Icons.unfold_less_double_rounded,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _pesoBrutoController,
            onChanged: notifier.setPesoBruto,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: CorporateTokens.navy900),
            validator: (value) {
              if (_toDouble(value ?? '') <= 0) {
                return 'Peso bruto invalido';
              }
              return null;
            },
            decoration: _inputDecoration(
              label: 'Peso bruto',
              hint: '0.00',
              icon: Icons.scale_rounded,
            ),
          ),
          const SizedBox(height: 8),
          _readonlyMetric(
            label: 'Peso neto calculado',
            value: state.pesoNeto.isEmpty ? '-' : '${state.pesoNeto} kg',
          ),
        ],
      ),
    );
  }

  Widget _tipoChip(
    InventarioCeroState state,
    InventarioCeroNotifier notifier,
    TipoContenedor value,
    String label,
  ) {
    final selected = state.tipoContenedor == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected:
          state.isBusy ? null : (_) => notifier.setTipoContenedor(value),
      selectedColor: CorporateTokens.cobalt600.withValues(alpha: 0.15),
      backgroundColor: Colors.white,
      side: BorderSide(
        color:
            selected
                ? CorporateTokens.cobalt600
                : CorporateTokens.borderSoft,
      ),
      labelStyle: const TextStyle(
        color: CorporateTokens.navy900,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildSubmitCard({
    required InventarioCeroState state,
    required InventarioCeroNotifier notifier,
    required String usuario,
  }) {
    return _GlassBlock(
      title: 'Ubicacion y registro',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: state.almacen,
                  items:
                      AppConstants.almacenes
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(
                                item,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                  onChanged:
                      state.isBusy ? null : (v) => notifier.setAlmacen(v!),
                  dropdownColor: Colors.white,
                  style: const TextStyle(color: CorporateTokens.navy900),
                  icon: const Icon(
                    Icons.expand_more_rounded,
                    color: CorporateTokens.slate500,
                  ),
                  decoration: _inputDecoration(
                    label: 'Almacen',
                    hint: '',
                    icon: Icons.warehouse_rounded,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: state.ubicacion,
                  items:
                      _ubicaciones
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(
                                item,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                  onChanged:
                      state.isBusy ? null : (v) => notifier.setUbicacion(v!),
                  dropdownColor: Colors.white,
                  style: const TextStyle(color: CorporateTokens.navy900),
                  icon: const Icon(
                    Icons.expand_more_rounded,
                    color: CorporateTokens.slate500,
                  ),
                  decoration: _inputDecoration(
                    label: 'Ubicacion',
                    hint: '',
                    icon: Icons.pin_drop_rounded,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _guiaController,
            onChanged: notifier.setGuia,
            style: const TextStyle(color: CorporateTokens.navy900),
            decoration: _inputDecoration(
              label: 'Guia / referencia',
              hint: 'Opcional',
              icon: Icons.receipt_long_rounded,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _observacionesController,
            onChanged: notifier.setObservaciones,
            minLines: 2,
            maxLines: 3,
            style: const TextStyle(color: CorporateTokens.navy900),
            decoration: _inputDecoration(
              label: 'Observaciones',
              hint: 'Opcional',
              icon: Icons.notes_rounded,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: CorporateTokens.surfaceTop,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: CorporateTokens.borderSoft),
            ),
            child: Text(
              'Registro operado por: $usuario',
              style: const TextStyle(
                color: CorporateTokens.navy900,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
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
                      : () async {
                        if (_formKey.currentState?.validate() != true) {
                          return;
                        }
                        await notifier.registrarInventario(usuario: usuario);
                      },
              icon:
                  state.status == InventarioCeroStatus.sending
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Icon(Icons.save_rounded),
              label: Text(
                state.status == InventarioCeroStatus.sending
                    ? 'Registrando inventario...'
                    : 'Registrar inventario cero',
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
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed:
                  state.isBusy
                      ? null
                      : () {
                        _formKey.currentState?.reset();
                        _qrController.clear();
                        _guiaController.clear();
                        _observacionesController.clear();
                        notifier.limpiar();
                      },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Limpiar formulario'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _readonlyMetric({required String label, required String value}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: CorporateTokens.surfaceTop,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CorporateTokens.borderSoft),
      ),
      child: Row(
        children: [
          const Icon(Icons.monitor_weight_rounded, color: CorporateTokens.slate500),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: CorporateTokens.slate500,
                fontSize: 12,
              ),
            ),
          ),
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
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
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
}

class _GlassBlock extends StatelessWidget {
  final String title;
  final Widget child;

  const _GlassBlock({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
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
}

class _StaggerReveal extends StatelessWidget {
  final AnimationController controller;
  final double start;
  final double end;
  final Widget child;

  const _StaggerReveal({
    required this.controller,
    required this.start,
    required this.end,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(animation);

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(position: slide, child: child),
    );
  }
}

double _toDouble(String value) {
  return double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;
}
