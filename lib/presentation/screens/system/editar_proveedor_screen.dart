import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../providers/editar_proveedor_provider.dart';
import '../../widgets/enterprise_backdrop.dart';

class EditarProveedorScreen extends ConsumerStatefulWidget {
  const EditarProveedorScreen({super.key});

  @override
  ConsumerState<EditarProveedorScreen> createState() =>
      _EditarProveedorScreenState();
}

class _EditarProveedorScreenState extends ConsumerState<EditarProveedorScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _proveedorController;
  late final TextEditingController _materialController;
  late final TextEditingController _tituloController;
  late final TextEditingController _codigoController;
  late final TextEditingController _taraConoController;
  late final TextEditingController _taraBolsaController;
  late final TextEditingController _taraCajaController;
  late final TextEditingController _taraSacoController;

  late final AnimationController _entryController;

  @override
  void initState() {
    super.initState();
    final initial = ref.read(editarProveedorProvider);

    _proveedorController = TextEditingController(text: initial.proveedor);
    _materialController = TextEditingController(text: initial.material);
    _tituloController = TextEditingController(text: initial.titulo);
    _codigoController = TextEditingController(text: initial.codigo);
    _taraConoController = TextEditingController(text: initial.taraCono);
    _taraBolsaController = TextEditingController(text: initial.taraBolsa);
    _taraCajaController = TextEditingController(text: initial.taraCaja);
    _taraSacoController = TextEditingController(text: initial.taraSaco);

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    )..forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _proveedorController.dispose();
    _materialController.dispose();
    _tituloController.dispose();
    _codigoController.dispose();
    _taraConoController.dispose();
    _taraBolsaController.dispose();
    _taraCajaController.dispose();
    _taraSacoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editarProveedorProvider);
    final notifier = ref.read(editarProveedorProvider.notifier);

    ref.listen<EditarProveedorState>(editarProveedorProvider, (prev, next) {
      if (!mounted) return;
      _syncControllers(next);
    });

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: EnterpriseBackdrop()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  _StaggerSection(
                    controller: _entryController,
                    begin: 0.02,
                    end: 0.24,
                    child: _buildHeader(context),
                  ),
                  const SizedBox(height: 10),
                  _StaggerSection(
                    controller: _entryController,
                    begin: 0.08,
                    end: 0.34,
                    child: _buildStatusBanner(state),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: Column(
                          children: [
                            _StaggerSection(
                              controller: _entryController,
                              begin: 0.14,
                              end: 0.40,
                              child: _buildLookupCard(state, notifier),
                            ),
                            const SizedBox(height: 10),
                            _StaggerSection(
                              controller: _entryController,
                              begin: 0.22,
                              end: 0.52,
                              child: _buildTarasCard(state, notifier),
                            ),
                            const SizedBox(height: 10),
                            _StaggerSection(
                              controller: _entryController,
                              begin: 0.28,
                              end: 0.64,
                              child: _buildActions(state, notifier),
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
                'Editar Proveedor',
                style: TextStyle(
                  color: CorporateTokens.navy900,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Gestion de taras con Google Apps Script legacy',
                style: TextStyle(color: CorporateTokens.slate500, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBanner(EditarProveedorState state) {
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

  Widget _buildLookupCard(
    EditarProveedorState state,
    EditarProveedorNotifier notifier,
  ) {
    return _buildCard(
      title: 'Busqueda de proveedor',
      children: [
        _buildTextField(
          controller: _proveedorController,
          label: 'Proveedor',
          hint: 'Ejemplo: HILADOS PERU',
          icon: Icons.business_rounded,
          onChanged: notifier.setProveedor,
          validator: (value) => _required(value, 'proveedor'),
        ),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _materialController,
          label: 'Material',
          hint: 'Ejemplo: POLIESTER',
          icon: Icons.inventory_2_rounded,
          onChanged: notifier.setMaterial,
          validator: (value) => _required(value, 'material'),
        ),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _tituloController,
          label: 'Titulo',
          hint: 'Ejemplo: 40/2',
          icon: Icons.text_fields_rounded,
          onChanged: notifier.setTitulo,
          validator: (value) => _required(value, 'titulo'),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed:
                    state.isBusy ? null : () => notifier.buscarCodigoProveedor(),
                icon:
                    state.status == EditarProveedorStatus.buscandoCodigo
                        ? const SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.search_rounded),
                label: const Text('Buscar proveedor'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: state.isBusy || state.codigo.trim().isEmpty
                    ? null
                    : () => notifier.buscarTarasProveedor(),
                icon: state.status == EditarProveedorStatus.buscandoTaras
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.data_object_rounded),
                label: const Text('Buscar datos'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildTextField(
          controller: _codigoController,
          label: 'Codigo',
          hint: 'Codigo interno encontrado',
          icon: Icons.confirmation_number_rounded,
          onChanged: (_) {},
          readOnly: true,
        ),
      ],
    );
  }

  Widget _buildTarasCard(
    EditarProveedorState state,
    EditarProveedorNotifier notifier,
  ) {
    return _buildCard(
      title: 'Taras del proveedor',
      children: [
        _buildTaraField(
          controller: _taraConoController,
          label: 'Tara cono',
          icon: Icons.adjust_rounded,
          onChanged: notifier.setTaraCono,
        ),
        const SizedBox(height: 8),
        _buildTaraField(
          controller: _taraBolsaController,
          label: 'Tara bolsa',
          icon: Icons.shopping_bag_rounded,
          onChanged: notifier.setTaraBolsa,
        ),
        const SizedBox(height: 8),
        _buildTaraField(
          controller: _taraCajaController,
          label: 'Tara caja',
          icon: Icons.inventory_rounded,
          onChanged: notifier.setTaraCaja,
        ),
        const SizedBox(height: 8),
        _buildTaraField(
          controller: _taraSacoController,
          label: 'Tara saco',
          icon: Icons.backpack_rounded,
          onChanged: notifier.setTaraSaco,
        ),
      ],
    );
  }

  Widget _buildActions(
    EditarProveedorState state,
    EditarProveedorNotifier notifier,
  ) {
    return _buildCard(
      title: 'Acciones',
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: state.isBusy
                ? null
                : () {
                    if (_formKey.currentState?.validate() != true) {
                      return;
                    }
                    notifier.guardarTarasProveedor();
                  },
            icon: state.status == EditarProveedorStatus.guardando
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
              state.status == EditarProveedorStatus.guardando
                  ? 'Guardando cambios...'
                  : 'Guardar proveedor',
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: state.isBusy
                ? null
                : () {
                    notifier.limpiarFormulario();
                    _formKey.currentState?.reset();
                  },
            icon: const Icon(Icons.cleaning_services_rounded),
            label: const Text('Limpiar campos'),
          ),
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
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ValueChanged<String> onChanged,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      readOnly: readOnly,
      validator: validator,
      style: const TextStyle(color: CorporateTokens.navy900),
      decoration: _inputDecoration(label: label, hint: hint, icon: icon),
    );
  }

  Widget _buildTaraField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ValueChanged<String> onChanged,
  }) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      validator: (value) => _required(value, label.toLowerCase()),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      style: const TextStyle(color: CorporateTokens.navy900),
      decoration: _inputDecoration(label: label, hint: '0.00', icon: icon),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: CorporateTokens.slate500),
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

  void _syncControllers(EditarProveedorState state) {
    if (_proveedorController.text != state.proveedor) {
      _proveedorController.text = state.proveedor;
    }
    if (_materialController.text != state.material) {
      _materialController.text = state.material;
    }
    if (_tituloController.text != state.titulo) {
      _tituloController.text = state.titulo;
    }
    if (_codigoController.text != state.codigo) {
      _codigoController.text = state.codigo;
    }
    if (_taraConoController.text != state.taraCono) {
      _taraConoController.text = state.taraCono;
    }
    if (_taraBolsaController.text != state.taraBolsa) {
      _taraBolsaController.text = state.taraBolsa;
    }
    if (_taraCajaController.text != state.taraCaja) {
      _taraCajaController.text = state.taraCaja;
    }
    if (_taraSacoController.text != state.taraSaco) {
      _taraSacoController.text = state.taraSaco;
    }
  }
}

class _StaggerSection extends StatelessWidget {
  final AnimationController controller;
  final double begin;
  final double end;
  final Widget child;

  const _StaggerSection({
    required this.controller,
    required this.begin,
    required this.end,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(animation);

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(position: slide, child: child),
    );
  }
}
