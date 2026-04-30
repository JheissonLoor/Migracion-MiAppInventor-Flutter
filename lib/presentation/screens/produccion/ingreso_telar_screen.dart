import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ingreso_telar_provider.dart';
import '../../widgets/enterprise_backdrop.dart';

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
      begin: const Offset(0, 0.03),
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

    ref.listen<IngresoTelarState>(ingresoTelarProvider, (previous, next) {
      if (!mounted) {
        return;
      }
      if (previous?.fields != next.fields) {
        _syncControllers(next.fields);
      }
    });

    if (!_requestedInit && usuario.trim().isNotEmpty) {
      _requestedInit = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        notifier.inicializar(usuario);
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
                  child: Column(
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 10),
                      _buildStateRow(state),
                      if (_hasBanner(state)) ...[
                        const SizedBox(height: 10),
                        _buildStatusBanner(state),
                      ],
                      const SizedBox(height: 10),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildDatosCard(state, notifier),
                              const SizedBox(height: 10),
                              _buildFechasCard(state, notifier),
                              const SizedBox(height: 10),
                              _buildActionCard(state, notifier, usuario),
                            ],
                          ),
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
                'Ingreso Telar',
                style: TextStyle(
                  color: CorporateTokens.navy900,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Flujo MIT 1:1 con UI corporativa moderna',
                style: TextStyle(color: CorporateTokens.slate500, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStateRow(IngresoTelarState state) {
    final isCompletado = state.estadoActual.toUpperCase() == 'COMPLETADO';
    final isProgreso = state.estadoActual.toUpperCase() == 'EN PROGRESO';

    final color =
        isCompletado
            ? const Color(0xFF16A34A)
            : isProgreso
            ? CorporateTokens.cobalt600
            : CorporateTokens.slate500;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CorporateTokens.borderSoft),
        boxShadow: CorporateTokens.cardShadow,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.flag_rounded,
            size: 18,
            color: CorporateTokens.navy900,
          ),
          const SizedBox(width: 8),
          const Text(
            'Estado actual:',
            style: TextStyle(
              color: CorporateTokens.navy900,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
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
                fontWeight: FontWeight.w800,
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

  Widget _buildStatusBanner(IngresoTelarState state) {
    final isError = state.errorMessage?.trim().isNotEmpty == true;
    final text = isError ? state.errorMessage! : state.message!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: isError ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isError ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
            size: 18,
            color: isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
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

  Widget _buildDatosCard(
    IngresoTelarState state,
    IngresoTelarNotifier notifier,
  ) {
    return _buildCard(
      title: 'Datos de telar',
      subtitle: 'Se autocompleta Articulo desde el numero de telar',
      child: Column(
        children: [
          _buildTextField(
            keyName: 'telar',
            label: 'Telar',
            hint: 'Numero de telar',
            icon: Icons.precision_manufacturing_rounded,
            keyboardType: TextInputType.number,
            notifier: notifier,
            enabled: !state.isBusy,
            onEditingComplete: () => notifier.buscarArticuloActual(),
            suffixIcon: IconButton(
              onPressed:
                  state.isBusy ? null : () => notifier.buscarArticuloActual(),
              tooltip: 'Buscar articulo del telar',
              icon: const Icon(Icons.manage_search_rounded),
            ),
          ),
          const SizedBox(height: 9),
          _buildTextField(
            keyName: 'articulo',
            label: 'Articulo',
            hint: 'Auto-completa al ingresar telar',
            icon: Icons.category_rounded,
            notifier: notifier,
            enabled: !state.isBusy,
          ),
          const SizedBox(height: 9),
          _buildTextField(
            keyName: 'hilo',
            label: 'Hilo',
            hint: 'Hilo',
            icon: Icons.texture_rounded,
            notifier: notifier,
            enabled: !state.isBusy,
          ),
          const SizedBox(height: 9),
          _buildTextField(
            keyName: 'titulo',
            label: 'Titulo',
            hint: 'Titulo',
            icon: Icons.badge_rounded,
            notifier: notifier,
            enabled: !state.isBusy,
          ),
          const SizedBox(height: 9),
          _buildTextField(
            keyName: 'metraje',
            label: 'Metraje',
            hint: 'Metraje',
            icon: Icons.straighten_rounded,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            notifier: notifier,
            enabled: !state.isBusy,
          ),
        ],
      ),
    );
  }

  Widget _buildFechasCard(
    IngresoTelarState state,
    IngresoTelarNotifier notifier,
  ) {
    return _buildCard(
      title: 'Fechas y cierre',
      subtitle: 'Formato legacy: YYYY-M-D',
      child: Column(
        children: [
          _buildDateField(
            keyName: 'fecha_inicio',
            label: 'Fecha inicio',
            icon: Icons.event_available_rounded,
            enabled: !state.isBusy,
            onPick:
                () => _pickDate(
                  current: _controllers['fecha_inicio']!.text,
                  onPicked: notifier.seleccionarFechaInicio,
                ),
          ),
          const SizedBox(height: 9),
          _buildDateField(
            keyName: 'fecha_final',
            label: 'Fecha final',
            icon: Icons.event_rounded,
            enabled: !state.isBusy,
            onPick:
                () => _pickDate(
                  current: _controllers['fecha_final']!.text,
                  onPicked: notifier.seleccionarFechaFinal,
                ),
          ),
          const SizedBox(height: 9),
          _buildTextField(
            keyName: 'peso_total',
            label: 'Peso total',
            hint: 'Peso total',
            icon: Icons.scale_rounded,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            notifier: notifier,
            enabled: !state.isBusy,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    IngresoTelarState state,
    IngresoTelarNotifier notifier,
    String usuario,
  ) {
    return _buildCard(
      title: 'Acciones',
      subtitle:
          usuario.trim().isEmpty ? 'Operario sin sesion' : 'Operario: $usuario',
      child: Column(
        children: [
          _ActionButton(
            label:
                state.status == IngresoTelarStatus.saving
                    ? 'Guardando progreso...'
                    : 'Guardar progreso',
            icon: Icons.save_rounded,
            busy: state.status == IngresoTelarStatus.saving,
            enabled: !state.isBusy,
            colors: const [Color(0xFF1D9B65), Color(0xFF16A34A)],
            onPressed: notifier.guardarProgreso,
          ),
          const SizedBox(height: 8),
          _ActionButton(
            label:
                state.status == IngresoTelarStatus.completing
                    ? 'Completando registro...'
                    : 'Completar',
            icon: Icons.task_alt_rounded,
            busy: state.status == IngresoTelarStatus.completing,
            enabled: !state.isBusy,
            colors: CorporateTokens.primaryButtonGradient,
            onPressed: notifier.completarRegistro,
          ),
          const SizedBox(height: 8),
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

  Widget _buildCard({
    required String title,
    required String subtitle,
    required Widget child,
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
              fontSize: 16,
              fontWeight: FontWeight.w700,
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
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String keyName,
    required String label,
    required String hint,
    required IconData icon,
    required IngresoTelarNotifier notifier,
    required bool enabled,
    TextInputType? keyboardType,
    VoidCallback? onEditingComplete,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: _controllers[keyName],
      enabled: enabled,
      onChanged: (value) => notifier.actualizarCampo(keyName, value),
      onEditingComplete: onEditingComplete,
      keyboardType: keyboardType,
      style: const TextStyle(color: CorporateTokens.navy900),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: CorporateTokens.slate500),
        suffixIcon: suffixIcon,
      ),
    );
  }

  Widget _buildDateField({
    required String keyName,
    required String label,
    required IconData icon,
    required bool enabled,
    required VoidCallback onPick,
  }) {
    return TextFormField(
      controller: _controllers[keyName],
      readOnly: true,
      enabled: enabled,
      style: const TextStyle(color: CorporateTokens.navy900),
      decoration: InputDecoration(
        labelText: label,
        hintText: 'YYYY-M-D',
        prefixIcon: Icon(icon, color: CorporateTokens.slate500),
        suffixIcon: IconButton(
          onPressed: enabled ? onPick : null,
          icon: const Icon(Icons.calendar_month_rounded),
        ),
      ),
      onTap: enabled ? onPick : null,
    );
  }

  Future<void> _pickDate({
    required String current,
    required void Function(DateTime) onPicked,
  }) async {
    final initialDate = _parseLegacyDate(current) ?? DateTime.now();
    final firstDate = DateTime(2020, 1, 1);
    final lastDate = DateTime(2100, 12, 31);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      onPicked(picked);
    }
  }

  DateTime? _parseLegacyDate(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      return null;
    }

    final parts = value.split('-');
    if (parts.length != 3) {
      return null;
    }

    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) {
      return null;
    }

    if (month < 1 || month > 12 || day < 1 || day > 31) {
      return null;
    }

    return DateTime(year, month, day);
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
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(colors: colors),
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
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
    );
  }
}

const List<String> _fieldOrder = [
  'telar',
  'articulo',
  'hilo',
  'titulo',
  'metraje',
  'fecha_inicio',
  'fecha_final',
  'peso_total',
];
