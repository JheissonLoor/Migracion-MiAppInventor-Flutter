import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/datasources/remote/produccion_remote_datasource.dart';
import '../../providers/auth_provider.dart';
import '../../providers/produccion_historial_provider.dart';
import '../../widgets/enterprise_backdrop.dart';

class HistorialAdminScreen extends ConsumerStatefulWidget {
  const HistorialAdminScreen({super.key});

  @override
  ConsumerState<HistorialAdminScreen> createState() =>
      _HistorialAdminScreenState();
}

class _HistorialAdminScreenState extends ConsumerState<HistorialAdminScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
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

    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarUsuarios());
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  Future<void> _cargarUsuarios() async {
    final usuario = ref.read(authProvider).user?.usuario ?? '';
    await ref
        .read(historialAdminProvider.notifier)
        .cargarUsuarios(usuarioSesion: usuario);
  }

  Future<void> _buscar() async {
    await ref.read(historialAdminProvider.notifier).buscar();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(historialAdminProvider);
    final isLoading = state.status == ProduccionHistorialStatus.loading;

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
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    children: [
                      _buildHeader(state),
                      const SizedBox(height: 10),
                      _buildSearchPanel(state, isLoading),
                      const SizedBox(height: 10),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: CorporateTokens.motionNormal,
                          child: _buildContent(state),
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

  Widget _buildHeader(HistorialAdminState state) {
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
                'Historial Administrativo',
                style: TextStyle(
                  color: CorporateTokens.navy900,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Auditoria por usuario - movimientos de inventario',
                style: TextStyle(
                  color: CorporateTokens.slate500,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Recargar usuarios',
          onPressed: state.loadingUsuarios ? null : _cargarUsuarios,
          icon:
              state.loadingUsuarios
                  ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Icon(Icons.sync_rounded),
        ),
      ],
    );
  }

  Widget _buildSearchPanel(HistorialAdminState state, bool isLoading) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CorporateTokens.borderSoft),
        boxShadow: CorporateTokens.cardShadow,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final selector = _buildUserSelector(state, isLoading);
          final action = SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed:
                  isLoading || state.loadingUsuarios || state.usuarios.isEmpty
                      ? null
                      : _buscar,
              icon:
                  isLoading
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.manage_search_rounded),
              label: const Text('Buscar inventario'),
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                selector,
                const SizedBox(height: 10),
                SizedBox(width: double.infinity, child: action),
                _buildPanelFooter(state),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: selector),
                  const SizedBox(width: 12),
                  action,
                ],
              ),
              _buildPanelFooter(state),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUserSelector(HistorialAdminState state, bool isLoading) {
    if (state.loadingUsuarios) {
      return const _LoadingField(label: 'Cargando usuarios...');
    }

    if (state.usuarios.isEmpty) {
      return const _LoadingField(label: 'Sin usuarios disponibles');
    }

    final selected =
        state.usuarios.contains(state.usuarioSeleccionado)
            ? state.usuarioSeleccionado
            : state.usuarios.first;

    return DropdownButtonFormField<String>(
      value: selected,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Usuario a auditar',
        prefixIcon: Icon(Icons.badge_rounded),
      ),
      items:
          state.usuarios
              .map(
                (usuario) => DropdownMenuItem<String>(
                  value: usuario,
                  child: Text(
                    usuario,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              )
              .toList(),
      onChanged:
          isLoading
              ? null
              : (value) {
                if (value == null) {
                  return;
                }
                ref
                    .read(historialAdminProvider.notifier)
                    .seleccionarUsuario(value);
              },
    );
  }

  Widget _buildPanelFooter(HistorialAdminState state) {
    final text =
        state.infoMessage ??
        (state.errorMessage != null
            ? state.errorMessage!
            : 'Replica MIT: read_column(datos, columna 8) + Apps Script.');
    final color =
        state.errorMessage != null ? AppColors.error : CorporateTokens.slate500;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        children: [
          _StatusChip(
            icon: Icons.people_alt_rounded,
            label: '${state.usuarios.length} usuarios',
            color: CorporateTokens.cobalt600,
          ),
          _StatusChip(
            icon: Icons.inventory_2_rounded,
            label: '${state.items.length} movimientos',
            color: CorporateTokens.cyan500,
          ),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(HistorialAdminState state) {
    switch (state.status) {
      case ProduccionHistorialStatus.initial:
        return _EmptyState(
          key: const ValueKey('initial'),
          icon: Icons.manage_search_rounded,
          title: 'Seleccione un usuario',
          subtitle:
              'Use Buscar inventario para cargar fecha, hora, kardex, codigo, almacen, ubicacion y movimiento.',
          actionLabel: 'Buscar',
          onAction: _buscar,
        );
      case ProduccionHistorialStatus.loading:
        return const Center(
          key: ValueKey('loading'),
          child: CircularProgressIndicator(),
        );
      case ProduccionHistorialStatus.empty:
        return _EmptyState(
          key: const ValueKey('empty'),
          icon: Icons.inbox_rounded,
          title: 'Sin movimientos',
          subtitle: state.infoMessage ?? 'No hay registros para este usuario.',
          actionLabel: 'Reintentar',
          onAction: _buscar,
        );
      case ProduccionHistorialStatus.error:
        return _EmptyState(
          key: const ValueKey('error'),
          icon: Icons.error_outline_rounded,
          title: 'No se pudo consultar',
          subtitle: state.errorMessage ?? 'Error de historial administrativo.',
          actionLabel: 'Reintentar',
          onAction: _buscar,
          isError: true,
        );
      case ProduccionHistorialStatus.loaded:
        return LayoutBuilder(
          key: const ValueKey('loaded'),
          builder: (context, constraints) {
            if (constraints.maxWidth >= 900) {
              return _buildWideTable(state.items);
            }
            return _buildCardList(state.items);
          },
        );
    }
  }

  Widget _buildWideTable(List<HistorialAdminItem> items) {
    return RefreshIndicator(
      onRefresh: _buscar,
      child: ListView(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: CorporateTokens.borderSoft),
              boxShadow: CorporateTokens.cardShadow,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStatePropertyAll(
                  CorporateTokens.surfaceBottom,
                ),
                columns: const [
                  DataColumn(label: Text('Fecha')),
                  DataColumn(label: Text('Hora')),
                  DataColumn(label: Text('CKardex')),
                  DataColumn(label: Text('Codigo')),
                  DataColumn(label: Text('Almacen')),
                  DataColumn(label: Text('Ubicacion')),
                  DataColumn(label: Text('Movimiento')),
                ],
                rows:
                    items.map((item) {
                      return DataRow(
                        cells: [
                          DataCell(Text(item.fecha)),
                          DataCell(Text(item.hora)),
                          DataCell(Text(item.codigoKardex)),
                          DataCell(Text(item.codigo)),
                          DataCell(Text(item.almacen)),
                          DataCell(Text(item.ubicacion)),
                          DataCell(Text(item.movimiento)),
                        ],
                      );
                    }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardList(List<HistorialAdminItem> items) {
    return RefreshIndicator(
      onRefresh: _buscar,
      child: ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          return Container(
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
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: CorporateTokens.cobalt600.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.history_edu_rounded,
                        color: CorporateTokens.cobalt600,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.codigo.isEmpty
                            ? 'Movimiento sin codigo'
                            : item.codigo,
                        style: const TextStyle(
                          color: CorporateTokens.navy900,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Text(
                      '${item.fecha} ${item.hora}'.trim(),
                      style: const TextStyle(
                        color: CorporateTokens.slate500,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _InfoRow(label: 'Kardex', value: item.codigoKardex),
                _InfoRow(label: 'Almacen', value: item.almacen),
                _InfoRow(label: 'Ubicacion', value: item.ubicacion),
                _InfoRow(label: 'Movimiento', value: item.movimiento),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LoadingField extends StatelessWidget {
  final String label;

  const _LoadingField({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: CorporateTokens.surfaceTop,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CorporateTokens.borderSoft),
      ),
      child: Row(
        children: [
          const Icon(Icons.badge_rounded, color: CorporateTokens.slate500),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: CorporateTokens.slate500,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 94,
            child: Text(
              label,
              style: const TextStyle(
                color: CorporateTokens.slate500,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                color: CorporateTokens.navy900,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;
  final bool isError;

  const _EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.error : CorporateTokens.cobalt600;
    return Center(
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 540),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: CorporateTokens.borderSoft),
          boxShadow: CorporateTokens.cardShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 42),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: CorporateTokens.navy900,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: CorporateTokens.slate500,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
