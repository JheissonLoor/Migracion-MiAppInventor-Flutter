import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/datasources/remote/almacen_remote_datasource.dart';
import '../../providers/almacen_provider.dart';
import '../../widgets/enterprise_backdrop.dart';
import '../../widgets/scanner/qr_scanner_page.dart';

class ConsultaAlmacenScreen extends ConsumerStatefulWidget {
  const ConsultaAlmacenScreen({super.key});

  @override
  ConsumerState<ConsultaAlmacenScreen> createState() =>
      _ConsultaAlmacenScreenState();
}

class _ConsultaAlmacenScreenState
    extends ConsumerState<ConsultaAlmacenScreen>
    with TickerProviderStateMixin {
  final _codigoController = TextEditingController();
  final _focusNode = FocusNode();

  late final AnimationController _entryController;
  late final AnimationController _shimmerController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    )..forward();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnim = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(_fadeAnim);
  }

  @override
  void dispose() {
    _entryController.dispose();
    _shimmerController.dispose();
    _codigoController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _buscar() {
    FocusScope.of(context).unfocus();
    HapticFeedback.mediumImpact();
    ref.read(consultaAlmacenProvider.notifier).buscar(_codigoController.text);
  }

  void _limpiar() {
    _codigoController.clear();
    ref.read(consultaAlmacenProvider.notifier).limpiar();
    _focusNode.requestFocus();
    HapticFeedback.lightImpact();
  }

  Future<void> _escanearQR() async {
    HapticFeedback.selectionClick();
    final result = await openQrScanner(
      context,
      title: 'Escanear Codigo PCP',
    );
    if (result != null && result.isNotEmpty && mounted) {
      _codigoController.text = result;
      HapticFeedback.heavyImpact();
      _buscar();
    }
  }

  Color _colorPorPlanta(String planta) {
    final p = planta.toUpperCase();
    if (p.contains('PLANTA 1')) return const Color(0xFF2563EB);
    if (p.contains('PLANTA 2')) return const Color(0xFF16A34A);
    if (p.contains('PLANTA 3')) return const Color(0xFFEA580C);
    if (p.contains('CENTRAL')) return const Color(0xFF7C3AED);
    return CorporateTokens.cobalt600;
  }

  IconData _iconPorPlanta(String planta) {
    final p = planta.toUpperCase();
    if (p.contains('PLANTA 1')) return Icons.factory_rounded;
    if (p.contains('PLANTA 2')) return Icons.warehouse_rounded;
    if (p.contains('PLANTA 3')) return Icons.domain_rounded;
    if (p.contains('CENTRAL')) return Icons.hub_rounded;
    return Icons.location_on_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(consultaAlmacenProvider);

    if (state.status == ConsultaStatus.loading) {
      if (!_shimmerController.isAnimating) _shimmerController.repeat();
    } else {
      if (_shimmerController.isAnimating) _shimmerController.stop();
    }

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: EnterpriseBackdrop()),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 12),
                    _buildSearchPanel(state),
                    if (state.status == ConsultaStatus.loaded)
                      _buildResultsBar(state),
                    const SizedBox(height: 6),
                    Expanded(child: _buildContent(state)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 16, 0),
      child: Row(
        children: [
          _SoftPill(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_rounded, color: CorporateTokens.navy900, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Consultar Ubicacion',
                  style: TextStyle(
                    color: CorporateTokens.navy900,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Buscar la ultima ubicacion registrada del material',
                  style: TextStyle(
                    color: CorporateTokens.slate500,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _SoftPill(
            onTap: _escanearQR,
            highlighted: true,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 18),
                SizedBox(width: 6),
                Text(
                  'Escanear',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
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

  Widget _buildSearchPanel(ConsultaAlmacenState state) {
    final isLoading = state.status == ConsultaStatus.loading;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white,
          border: Border.all(color: CorporateTokens.borderSoft),
          boxShadow: CorporateTokens.cardShadow,
        ),
        child: Column(
          children: [
            TextField(
              controller: _codigoController,
              focusNode: _focusNode,
              style: const TextStyle(
                color: CorporateTokens.navy900,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-]')),
              ],
              decoration: InputDecoration(
                hintText: 'Codigo PCP (ej: PCP-1234)',
                hintStyle: TextStyle(
                  color: CorporateTokens.slate300,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                filled: true,
                fillColor: CorporateTokens.surfaceTop,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: CorporateTokens.borderSoft),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: CorporateTokens.cobalt600,
                    width: 1.5,
                  ),
                ),
                prefixIcon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                CorporateTokens.cobalt600,
                              ),
                            ),
                          ),
                        )
                      : Icon(
                          Icons.search_rounded,
                          key: const ValueKey('search'),
                          color: CorporateTokens.slate300,
                          size: 22,
                        ),
                ),
                suffixIcon: _codigoController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: CorporateTokens.slate300,
                          size: 20,
                        ),
                        onPressed: _limpiar,
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _buscar(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _ActionButton(
                    label: 'Buscar ubicacion',
                    icon: Icons.location_searching_rounded,
                    isLoading: isLoading,
                    onTap: isLoading ? null : _buscar,
                    gradient: CorporateTokens.primaryButtonGradient,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: _ActionButton(
                    label: 'Escanear QR',
                    icon: Icons.qr_code_scanner_rounded,
                    onTap: _escanearQR,
                    gradient: const [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsBar(ConsultaAlmacenState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF16A34A).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: const Color(0xFF16A34A).withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 14),
                const SizedBox(width: 5),
                Text(
                  '${state.results.length} resultado${state.results.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: Color(0xFF16A34A),
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: CorporateTokens.surfaceBottom,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: CorporateTokens.borderSoft),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.tag_rounded, color: CorporateTokens.slate500, size: 13),
                const SizedBox(width: 4),
                Text(
                  state.searchedCode ?? '',
                  style: TextStyle(
                    fontSize: 11,
                    color: CorporateTokens.slate700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          _SoftPill(
            onTap: _limpiar,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.close_rounded, color: CorporateTokens.slate500, size: 14),
                const SizedBox(width: 4),
                Text(
                  'Limpiar',
                  style: TextStyle(
                    color: CorporateTokens.slate500,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ConsultaAlmacenState state) {
    switch (state.status) {
      case ConsultaStatus.initial:
        return _buildInitialState();
      case ConsultaStatus.loading:
        return _buildLoadingState();
      case ConsultaStatus.empty:
        return _buildEmptyState(
          icon: Icons.search_off_rounded,
          title: 'Sin Resultados',
          subtitle: 'No se encontro ubicacion para\n"${state.searchedCode}"',
          actionLabel: 'Buscar otro codigo',
          onAction: _limpiar,
        );
      case ConsultaStatus.error:
        return _buildEmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Error en la Busqueda',
          subtitle: state.errorMessage ?? 'Error desconocido',
          actionLabel: 'Reintentar',
          onAction: _buscar,
          isError: true,
        );
      case ConsultaStatus.loaded:
        return _buildResults(state);
    }
  }

  Widget _buildInitialState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CorporateTokens.cobalt600.withValues(alpha: 0.08),
                border: Border.all(
                  color: CorporateTokens.cobalt600.withValues(alpha: 0.15),
                ),
              ),
              child: Icon(
                Icons.location_searching_rounded,
                size: 40,
                color: CorporateTokens.cobalt600.withValues(alpha: 0.60),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Buscar Ubicacion',
              style: TextStyle(
                color: CorporateTokens.navy900,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Escanea un QR o ingresa el codigo PCP\npara consultar la ultima ubicacion',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: CorporateTokens.slate500,
                fontSize: 13,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: CorporateTokens.cobalt600.withValues(alpha: 0.06),
                border: Border.all(
                  color: CorporateTokens.cobalt600.withValues(alpha: 0.12),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tips_and_updates_rounded,
                      size: 16, color: CorporateTokens.cobalt600.withValues(alpha: 0.70)),
                  const SizedBox(width: 8),
                  Text(
                    'Tip: Usa el boton QR para buscar mas rapido',
                    style: TextStyle(
                      color: CorporateTokens.slate500,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: List.generate(3, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, child) {
                final t = _shimmerController.value;
                return Opacity(
                  opacity: 0.4 + (0.4 * (0.5 + 0.5 * (1.0 - ((t - 0.5).abs() * 2)))),
                  child: child,
                );
              },
              child: Container(
                height: 110,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                  border: Border.all(color: CorporateTokens.borderSoft),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 5,
                      decoration: BoxDecoration(
                        color: CorporateTokens.borderSoft,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 140, height: 14,
                              decoration: BoxDecoration(
                                color: CorporateTokens.steel200,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              width: 200, height: 10,
                              decoration: BoxDecoration(
                                color: CorporateTokens.steel200.withValues(alpha: 0.60),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                Container(
                                  width: 80, height: 10,
                                  decoration: BoxDecoration(
                                    color: CorporateTokens.steel200.withValues(alpha: 0.40),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Container(
                                  width: 60, height: 10,
                                  decoration: BoxDecoration(
                                    color: CorporateTokens.steel200.withValues(alpha: 0.40),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
    bool isError = false,
  }) {
    final color = isError ? const Color(0xFFDC2626) : CorporateTokens.cobalt600;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.08),
                border: Border.all(color: color.withValues(alpha: 0.18)),
              ),
              child: Icon(icon, size: 38, color: color),
            ),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(
              color: CorporateTokens.navy900, fontSize: 18, fontWeight: FontWeight.w700,
            )),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center, style: TextStyle(
              color: CorporateTokens.slate500, fontSize: 13, height: 1.5,
            )),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              _ActionButton(
                label: actionLabel,
                icon: Icons.refresh_rounded,
                onTap: onAction,
                gradient: isError
                    ? const [Color(0xFFDC2626), Color(0xFFEF4444)]
                    : CorporateTokens.primaryButtonGradient,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResults(ConsultaAlmacenState state) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: state.results.length,
      itemBuilder: (context, index) {
        final result = state.results[index];
        final plantaColor = _colorPorPlanta(result.planta);
        final plantaIcon = _iconPorPlanta(result.planta);

        return _StaggerItem(
          controller: _entryController,
          index: index,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ResultCard(
              result: result,
              color: plantaColor,
              icon: plantaIcon,
            ),
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  WIDGETS
// ══════════════════════════════════════════════════════════════════

class _StaggerItem extends StatelessWidget {
  final AnimationController controller;
  final int index;
  final Widget child;

  const _StaggerItem({
    required this.controller,
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final start = (0.30 + (index * 0.08)).clamp(0.0, 0.85);
    final end = (0.55 + (index * 0.08)).clamp(0.25, 1.0);
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    final offset = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(animation);

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(position: offset, child: child),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final AlmacenResult result;
  final Color color;
  final IconData icon;

  const _ResultCard({required this.result, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        border: Border.all(color: color.withValues(alpha: 0.20)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [color, color.withValues(alpha: 0.40)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, size: 22, color: color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                result.codigoPcp,
                                style: const TextStyle(
                                  color: CorporateTokens.navy900,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(result.planta, style: TextStyle(
                                  color: color, fontSize: 11, fontWeight: FontWeight.w700,
                                )),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 1,
                      color: CorporateTokens.borderSoft,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: CorporateTokens.cobalt600.withValues(alpha: 0.05),
                        border: Border.all(
                          color: CorporateTokens.cobalt600.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.pin_drop_rounded, size: 16,
                              color: CorporateTokens.cobalt600.withValues(alpha: 0.70)),
                          const SizedBox(width: 8),
                          Text('Ubicacion: ', style: TextStyle(
                            color: CorporateTokens.slate500, fontSize: 12,
                          )),
                          Flexible(
                            child: Text(result.ubicacion, style: const TextStyle(
                              color: CorporateTokens.cobalt600, fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ), overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _DetailChip(Icons.calendar_today_rounded, result.fecha),
                        const SizedBox(width: 8),
                        _DetailChip(Icons.schedule_rounded, result.hora),
                        const Spacer(),
                        _DetailChip(Icons.person_rounded, result.operario),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _DetailChip(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: CorporateTokens.slate300),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(
          color: CorporateTokens.slate500, fontSize: 11, fontWeight: FontWeight.w600,
        ), overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isLoading;
  final List<Color> gradient;

  const _ActionButton({
    required this.label, required this.icon, this.onTap,
    this.isLoading = false, required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(colors: gradient),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(
                  strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ))
              else
                Icon(icon, color: Colors.white, size: 17),
              const SizedBox(width: 7),
              Flexible(child: Text(label, style: const TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700,
              ), overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SoftPill extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool highlighted;

  const _SoftPill({required this.child, required this.onTap, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: highlighted ? CorporateTokens.cobalt600 : Colors.white,
            border: Border.all(
              color: highlighted ? CorporateTokens.cobalt600 : CorporateTokens.borderSoft,
            ),
            boxShadow: highlighted ? null : CorporateTokens.cardShadow,
          ),
          child: child,
        ),
      ),
    );
  }
}
