import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/datasources/remote/almacen_remote_datasource.dart';
import '../../providers/almacen_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/enterprise_backdrop.dart';

class HistorialScreen extends ConsumerStatefulWidget {
  const HistorialScreen({super.key});

  @override
  ConsumerState<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends ConsumerState<HistorialScreen>
    with SingleTickerProviderStateMixin {
  String _filtroSeleccionado = 'SALIDA';

  late final AnimationController _entryController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    )..forward();
    _fadeAnim = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(_fadeAnim);

    WidgetsBinding.instance.addPostFrameCallback((_) => _buscarHistorial());
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  void _buscarHistorial() {
    final usuario = ref.read(authProvider).user?.usuario ?? '';
    ref.read(historialProvider.notifier).buscar(
          usuario: usuario,
          filtro: _filtroSeleccionado,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(historialProvider);
    final authState = ref.watch(authProvider);
    final usuario = authState.user?.usuario ?? 'Usuario';

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
                    _buildHeader(usuario),
                    const SizedBox(height: 10),
                    _buildFilterPanel(),
                    const SizedBox(height: 10),
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

  Widget _buildHeader(String usuario) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 16, 0),
      child: Row(
        children: [
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CorporateTokens.borderSoft),
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: CorporateTokens.navy900, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Historial',
                  style: TextStyle(
                    color: CorporateTokens.navy900,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Movimientos de $usuario',
                  style: TextStyle(
                    color: CorporateTokens.slate500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: CorporateTokens.cobalt600.withValues(alpha: 0.10),
              border: Border.all(
                color: CorporateTokens.cobalt600.withValues(alpha: 0.20),
              ),
            ),
            child: const Icon(Icons.person_rounded,
                color: CorporateTokens.cobalt600, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white,
          border: Border.all(color: CorporateTokens.borderSoft),
          boxShadow: CorporateTokens.cardShadow,
        ),
        child: Row(
          children: [
            _buildFilterChip(
              label: 'SALIDA',
              icon: Icons.output_rounded,
              isSelected: _filtroSeleccionado == 'SALIDA',
              color: const Color(0xFFDC2626),
            ),
            const SizedBox(width: 4),
            _buildFilterChip(
              label: 'REINGRESO',
              icon: Icons.input_rounded,
              isSelected: _filtroSeleccionado == 'REINGRESO',
              color: const Color(0xFF16A34A),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _filtroSeleccionado = label);
          _buscarHistorial();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: isSelected ? color.withValues(alpha: 0.10) : Colors.transparent,
            border: isSelected
                ? Border.all(color: color.withValues(alpha: 0.30))
                : Border.all(color: Colors.transparent),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? color : CorporateTokens.slate300,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                  color: isSelected ? color : CorporateTokens.slate300,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(HistorialState state) {
    switch (state.status) {
      case ConsultaStatus.initial:
      case ConsultaStatus.loading:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(CorporateTokens.cobalt600),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Cargando historial...',
                style: TextStyle(
                  color: CorporateTokens.slate500,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );

      case ConsultaStatus.empty:
        return _buildEmptyState(
          icon: Icons.history_rounded,
          title: 'Sin Movimientos',
          subtitle: 'No hay movimientos de tipo\n"$_filtroSeleccionado" registrados',
          actionLabel: 'Recargar',
          onAction: _buscarHistorial,
        );

      case ConsultaStatus.error:
        return _buildEmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Error',
          subtitle: state.errorMessage ?? 'Error al cargar historial',
          actionLabel: 'Reintentar',
          onAction: _buscarHistorial,
          isError: true,
        );

      case ConsultaStatus.loaded:
        return _buildHistorialList(state);
    }
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
              width: 80,
              height: 80,
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
              TextButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(actionLabel),
                style: TextButton.styleFrom(
                  foregroundColor: CorporateTokens.cobalt600,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: CorporateTokens.cobalt600.withValues(alpha: 0.25),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHistorialList(HistorialState state) {
    return RefreshIndicator(
      onRefresh: () async => _buscarHistorial(),
      color: CorporateTokens.cobalt600,
      backgroundColor: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        itemCount: state.items.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: CorporateTokens.cobalt600.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: CorporateTokens.cobalt600.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Text(
                      '${state.items.length} movimiento${state.items.length != 1 ? 's' : ''}',
                      style: const TextStyle(
                        color: CorporateTokens.cobalt600,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.swipe_down_rounded, size: 16, color: CorporateTokens.slate300),
                  const SizedBox(width: 4),
                  Text(
                    'Desliza para actualizar',
                    style: TextStyle(fontSize: 11, color: CorporateTokens.slate300),
                  ),
                ],
              ),
            );
          }

          final item = state.items[index - 1];
          final isSalida = item.isSalida;
          final statusColor = isSalida
              ? const Color(0xFFDC2626)
              : const Color(0xFF16A34A);

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _HistorialCard(item: item, statusColor: statusColor),
          );
        },
      ),
    );
  }
}

class _HistorialCard extends StatelessWidget {
  final HistorialItem item;
  final Color statusColor;

  const _HistorialCard({required this.item, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    final isSalida = item.isSalida;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
        border: Border.all(color: statusColor.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(item.codigoPcp, style: const TextStyle(
                            color: CorporateTokens.navy900, fontSize: 15,
                            fontWeight: FontWeight.w700,
                          )),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isSalida ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                                color: statusColor, size: 14,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                isSalida ? 'SAL' : 'REING',
                                style: TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.w700, color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (item.codigoKardex.isNotEmpty)
                      _infoRow(Icons.tag_rounded, 'C. Kardex', item.codigoKardex),
                    if (item.codigoKardex.isNotEmpty) const SizedBox(height: 4),
                    _infoRow(Icons.warehouse_rounded, 'Almacen', item.almacen),
                    const SizedBox(height: 4),
                    _infoRow(Icons.pin_drop_rounded, 'Ubicacion', item.ubicacion,
                        highlight: true),
                    const SizedBox(height: 4),
                    _infoRow(Icons.schedule_rounded, 'Fecha/Hora',
                        '${item.fecha} ${item.hora}'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value,
      {bool highlight = false}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: CorporateTokens.slate300),
        const SizedBox(width: 6),
        Text('$label: ', style: TextStyle(
          color: CorporateTokens.slate500, fontSize: 12,
        )),
        Flexible(
          child: Text(value, style: TextStyle(
            color: highlight ? CorporateTokens.cobalt600 : CorporateTokens.navy900,
            fontSize: 12,
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
          ), overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
