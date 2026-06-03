import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/datasources/remote/produccion_remote_datasource.dart';
import '../../providers/auth_provider.dart';
import '../../providers/corte_rollo_provider.dart';
import '../../widgets/enterprise_backdrop.dart';
import '../../widgets/production/production_visuals.dart';

class CorteRolloScreen extends ConsumerStatefulWidget {
  const CorteRolloScreen({super.key});

  @override
  ConsumerState<CorteRolloScreen> createState() => _CorteRolloScreenState();
}

class _CorteRolloScreenState extends ConsumerState<CorteRolloScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    final initial = ref.read(corteRolloProvider).fields;
    _controllers = {
      for (final key in _fieldOrder)
        key: TextEditingController(text: initial[key] ?? ''),
    };
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
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
    final state = ref.watch(corteRolloProvider);
    final notifier = ref.read(corteRolloProvider.notifier);
    final usuario = ref.watch(authProvider).user?.usuario ?? '';

    ref.listen<CorteRolloState>(corteRolloProvider, (previous, next) {
      if (mounted && previous?.fields != next.fields) {
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
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  child: Column(
                    children: [
                      _header(context),
                      if (_hasBanner(state)) ...[
                        const SizedBox(height: 10),
                        _statusBanner(state),
                      ],
                      const SizedBox(height: 10),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            children: [
                              _corteCard(state, notifier, usuario),
                              if (state.corteResult != null) ...[
                                const SizedBox(height: 10),
                                _resultCard(state.corteResult!),
                              ],
                              const SizedBox(height: 10),
                              _trazabilidadCard(state, notifier),
                              if (state.trazabilidad != null) ...[
                                const SizedBox(height: 10),
                                _trazabilidadResult(state.trazabilidad!),
                              ],
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed:
                                      state.isBusy ? null : notifier.limpiar,
                                  icon: const Icon(
                                    Icons.cleaning_services_rounded,
                                  ),
                                  label: const Text('Limpiar pantalla'),
                                ),
                              ),
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

  Widget _header(BuildContext context) {
    return ProductionHeader(
      title: 'Corte de Rollo',
      subtitle: 'Trazabilidad madre / sub-rollos desde backend FASE3',
      icon: Icons.call_split_rounded,
      onBack: () => Navigator.pop(context),
      accentColor: const Color(0xFF2F7C92),
    );
  }

  bool _hasBanner(CorteRolloState state) {
    return (state.errorMessage?.trim().isNotEmpty == true) ||
        (state.message?.trim().isNotEmpty == true);
  }

  Widget _statusBanner(CorteRolloState state) {
    return ProductionStatusBanner(
      message: state.message,
      errorMessage: state.errorMessage,
    );
  }

  Widget _corteCard(
    CorteRolloState state,
    CorteRolloNotifier notifier,
    String usuario,
  ) {
    return _section(
      step: '01',
      title: 'Registrar corte',
      subtitle: 'Divide un rollo madre y registra un sub-rollo trazable.',
      icon: Icons.call_split_rounded,
      child: Column(
        children: [
          _field(
            keyName: 'codigo_madre',
            label: 'Codigo madre',
            hint: 'Ej: U22406005',
            icon: Icons.qr_code_rounded,
            notifier: notifier,
            enabled: !state.isBusy,
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, c) {
              return _row(c.maxWidth, [
                _field(
                  keyName: 'metros',
                  label: 'Metros a cortar',
                  hint: 'Ej: 200',
                  icon: Icons.straighten_rounded,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  notifier: notifier,
                  enabled: !state.isBusy,
                ),
                _field(
                  keyName: 'destino',
                  label: 'Destino',
                  hint: 'Ej: Telar 49',
                  icon: Icons.place_rounded,
                  notifier: notifier,
                  enabled: !state.isBusy,
                ),
              ]);
            },
          ),
          const SizedBox(height: 12),
          _ActionButton(
            label:
                state.status == CorteRolloStatus.cutting
                    ? 'Registrando corte...'
                    : 'Cortar / registrar',
            icon: Icons.content_cut_rounded,
            busy: state.status == CorteRolloStatus.cutting,
            enabled: !state.isBusy,
            colors: CorporateTokens.primaryButtonGradient,
            onPressed: () => notifier.cortar(usuario: usuario),
          ),
        ],
      ),
    );
  }

  Widget _resultCard(CorteRolloResult result) {
    return _section(
      step: 'OK',
      title: 'Corte registrado',
      subtitle: 'Resultado devuelto por /cortar_rollo.',
      icon: Icons.verified_rounded,
      child: Column(
        children: [
          _metricRow('Sub-rollo generado', result.codigoHijo),
          _metricRow('Restante madre', result.restante),
        ],
      ),
    );
  }

  Widget _trazabilidadCard(CorteRolloState state, CorteRolloNotifier notifier) {
    return _section(
      step: '02',
      title: 'Consultar trazabilidad',
      subtitle: 'Valida madre, consumo, restante e hijos.',
      icon: Icons.account_tree_rounded,
      child: Column(
        children: [
          _field(
            keyName: 'consulta_codigo',
            label: 'Codigo a consultar',
            hint: 'Ej: U22406005 o U22406005-1',
            icon: Icons.manage_search_rounded,
            notifier: notifier,
            enabled: !state.isBusy,
          ),
          const SizedBox(height: 12),
          _ActionButton(
            label:
                state.status == CorteRolloStatus.querying
                    ? 'Consultando trazabilidad...'
                    : 'Consultar trazabilidad',
            icon: Icons.search_rounded,
            busy: state.status == CorteRolloStatus.querying,
            enabled: !state.isBusy,
            colors: const [Color(0xFF0F766E), Color(0xFF14B8A6)],
            onPressed: notifier.consultar,
          ),
        ],
      ),
    );
  }

  Widget _trazabilidadResult(TrazabilidadRolloData data) {
    return _section(
      step: 'TRZ',
      title: 'Resultado de trazabilidad',
      subtitle:
          data.codigoMadre.isEmpty
              ? 'Detalle operativo'
              : 'Rollo madre ${data.codigoMadre}',
      icon: Icons.route_rounded,
      child: Column(
        children: [
          _metricRow('Total madre', data.totalMadre),
          _metricRow('Consumido', data.consumido),
          _metricRow('Restante', data.restante),
          _metricRow('Desperdicio', data.desperdicio),
          _metricRow('Sub-rollos', data.numHijos),
          if (data.hijos.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final hijo in data.hijos) _hijoTile(hijo),
          ],
        ],
      ),
    );
  }

  Widget _hijoTile(TrazabilidadRolloHijo hijo) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CorporateTokens.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hijo.codigoHijo,
            style: const TextStyle(
              color: CorporateTokens.navy900,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${hijo.metros} m | ${hijo.destino} | ${hijo.fecha}',
            style: const TextStyle(
              color: CorporateTokens.slate500,
              fontSize: 12,
              fontWeight: FontWeight.w600,
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

  Widget _field({
    required String keyName,
    required String label,
    required String hint,
    required IconData icon,
    required CorteRolloNotifier notifier,
    required bool enabled,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: _controllers[keyName],
      enabled: enabled,
      onChanged: (value) => notifier.actualizarCampo(keyName, value),
      keyboardType: keyboardType,
      style: const TextStyle(
        color: CorporateTokens.navy900,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: CorporateTokens.slate500),
      ),
    );
  }

  Widget _metricRow(String label, String value) {
    final safeValue = value.trim().isEmpty ? '-' : value.trim();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CorporateTokens.borderSoft),
      ),
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
          Text(
            safeValue,
            style: const TextStyle(
              color: CorporateTokens.navy900,
              fontSize: 13,
              fontWeight: FontWeight.w900,
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
            color: colors.first.withValues(alpha: 0.22),
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
  'codigo_madre',
  'metros',
  'destino',
  'consulta_codigo',
];
