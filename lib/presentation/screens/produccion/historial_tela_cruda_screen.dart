import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/datasources/remote/produccion_remote_datasource.dart';
import '../../providers/auth_provider.dart';
import '../../providers/produccion_historial_provider.dart';
import '../../widgets/enterprise_backdrop.dart';

class HistorialTelaCrudaScreen extends ConsumerStatefulWidget {
  const HistorialTelaCrudaScreen({super.key});

  @override
  ConsumerState<HistorialTelaCrudaScreen> createState() =>
      _HistorialTelaCrudaScreenState();
}

class _HistorialTelaCrudaScreenState
    extends ConsumerState<HistorialTelaCrudaScreen>
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

    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    final usuario = ref.read(authProvider).user?.usuario ?? '';
    await ref
        .read(historialTelaCrudaProvider.notifier)
        .cargar(usuario: usuario);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(historialTelaCrudaProvider);
    final usuario = ref.watch(authProvider).user?.usuario ?? 'Operario';
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
                      _buildHeader(usuario, isLoading),
                      const SizedBox(height: 10),
                      _buildStatusCard(state),
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

  Widget _buildHeader(String usuario, bool isLoading) {
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
                'Historial Tela Cruda',
                style: TextStyle(
                  color: CorporateTokens.navy900,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'IngresoTela - registros de $usuario',
                style: const TextStyle(
                  color: CorporateTokens.slate500,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: isLoading ? null : _cargar,
          icon:
              isLoading
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Icon(Icons.sync_rounded, size: 18),
          label: const Text('Actualizar'),
        ),
      ],
    );
  }

  Widget _buildStatusCard(HistorialTelaCrudaState state) {
    final fuera = state.items.where((item) => item.rendimientoFuera).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CorporateTokens.borderSoft),
        boxShadow: CorporateTokens.cardShadow,
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _StatusChip(
            icon: Icons.person_rounded,
            label: state.usuario.isEmpty ? 'Usuario en sesion' : state.usuario,
            color: CorporateTokens.cobalt600,
          ),
          _StatusChip(
            icon: Icons.table_rows_rounded,
            label: '${state.items.length} registros',
            color: CorporateTokens.cyan500,
          ),
          _StatusChip(
            icon: fuera > 0 ? Icons.warning_amber_rounded : Icons.verified,
            label: fuera > 0 ? '$fuera rendimiento fuera' : 'Rendimiento OK',
            color: fuera > 0 ? AppColors.warning : AppColors.success,
          ),
          if ((state.infoMessage ?? '').isNotEmpty)
            Text(
              state.infoMessage!,
              style: const TextStyle(
                color: CorporateTokens.slate500,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(HistorialTelaCrudaState state) {
    switch (state.status) {
      case ProduccionHistorialStatus.initial:
      case ProduccionHistorialStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case ProduccionHistorialStatus.empty:
        return _EmptyState(
          key: const ValueKey('empty'),
          icon: Icons.inbox_rounded,
          title: 'Sin registros',
          subtitle: state.infoMessage ?? 'No hay tela cruda para este usuario.',
          actionLabel: 'Actualizar',
          onAction: _cargar,
        );
      case ProduccionHistorialStatus.error:
        return _EmptyState(
          key: const ValueKey('error'),
          icon: Icons.error_outline_rounded,
          title: 'No se pudo cargar',
          subtitle: state.errorMessage ?? 'Error al consultar tela cruda.',
          actionLabel: 'Reintentar',
          onAction: _cargar,
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

  Widget _buildWideTable(List<TelaCrudaHistorialItem> items) {
    return RefreshIndicator(
      onRefresh: _cargar,
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
                  DataColumn(label: Text('Cod Tela')),
                  DataColumn(label: Text('OP')),
                  DataColumn(label: Text('Articulo')),
                  DataColumn(label: Text('Telar')),
                  DataColumn(label: Text('Plegador')),
                  DataColumn(label: Text('CC')),
                  DataColumn(label: Text('Metro')),
                  DataColumn(label: Text('Peso')),
                  DataColumn(label: Text('Fecha revisado')),
                  DataColumn(label: Text('Rendimiento')),
                  DataColumn(label: Text('Validacion')),
                ],
                rows:
                    items.map((item) {
                      return DataRow(
                        color:
                            item.rendimientoFuera
                                ? WidgetStatePropertyAll(
                                  AppColors.warning.withValues(alpha: 0.12),
                                )
                                : null,
                        cells: [
                          DataCell(Text(item.codTela)),
                          DataCell(Text(item.op)),
                          DataCell(Text(item.articulo)),
                          DataCell(Text(item.telar)),
                          DataCell(Text(item.plegador)),
                          DataCell(Text(item.cc)),
                          DataCell(Text(item.metro)),
                          DataCell(Text(item.peso)),
                          DataCell(Text(item.fechaRevisado)),
                          DataCell(Text(item.rendimiento)),
                          DataCell(Text(item.validacionRendimiento)),
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

  Widget _buildCardList(List<TelaCrudaHistorialItem> items) {
    return RefreshIndicator(
      onRefresh: _cargar,
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
              border: Border.all(
                color:
                    item.rendimientoFuera
                        ? AppColors.warning.withValues(alpha: 0.65)
                        : CorporateTokens.borderSoft,
              ),
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
                        gradient: const LinearGradient(
                          colors: CorporateTokens.primaryButtonGradient,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.texture_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.codTela.isEmpty ? 'Sin codigo' : item.codTela,
                            style: const TextStyle(
                              color: CorporateTokens.navy900,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${item.fecha} ${item.hora}'.trim(),
                            style: const TextStyle(
                              color: CorporateTokens.slate500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (item.rendimientoFuera)
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.warning,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _InfoRow(label: 'OP', value: item.op),
                _InfoRow(label: 'Articulo', value: item.articulo),
                _InfoRow(label: 'Fecha revisado', value: item.fechaRevisado),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetricChip(label: 'Telar', value: item.telar),
                    _MetricChip(label: 'Plegador', value: item.plegador),
                    _MetricChip(label: 'CC', value: item.cc),
                    _MetricChip(label: 'Metro', value: item.metro),
                    _MetricChip(label: 'Peso', value: item.peso),
                    _MetricChip(
                      label: 'Rend.',
                      value: item.rendimiento,
                      highlight: item.rendimientoFuera,
                    ),
                    _MetricChip(
                      label: 'Valid.',
                      value: item.validacionRendimiento,
                      highlight: item.rendimientoFuera,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
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
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
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

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _MetricChip({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = highlight ? AppColors.warning : CorporateTokens.cobalt600;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            TextSpan(
              text: value.isEmpty ? '-' : value,
              style: const TextStyle(
                color: CorporateTokens.navy900,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ],
        ),
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
        constraints: const BoxConstraints(maxWidth: 520),
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
