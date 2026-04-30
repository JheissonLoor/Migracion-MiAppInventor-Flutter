import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/datasources/remote/produccion_remote_datasource.dart';
import '../../providers/auth_provider.dart';
import '../../providers/produccion_historial_provider.dart';
import '../../widgets/enterprise_backdrop.dart';

class HistorialUrdidoScreen extends ConsumerStatefulWidget {
  const HistorialUrdidoScreen({super.key});

  @override
  ConsumerState<HistorialUrdidoScreen> createState() =>
      _HistorialUrdidoScreenState();
}

class _HistorialUrdidoScreenState extends ConsumerState<HistorialUrdidoScreen>
    with SingleTickerProviderStateMixin {
  static const List<String> _filtros = ['TODAS', 'URDIDORA 1', 'URDIDORA 2'];

  late final AnimationController _entryController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  String _filtroSeleccionado = 'TODAS';
  bool _openingResumen = false;

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
      begin: const Offset(0, 0.03),
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
    await ref
        .read(historialUrdidoProvider.notifier)
        .cargar(urdidora: _filtroSeleccionado);
  }

  Future<void> _abrirResumenOperario() async {
    if (_openingResumen) {
      return;
    }

    final operario = ref.read(authProvider).user?.usuario ?? '';
    if (operario.trim().isEmpty) {
      return;
    }

    setState(() => _openingResumen = true);
    try {
      final resumen = await ref
          .read(historialUrdidoProvider.notifier)
          .cargarResumenOperario(operario);
      if (!mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Mis registros'),
            content: SingleChildScrollView(
              child: Text(
                resumen.isEmpty ? 'No hay registros en esta sesion.' : resumen,
                style: const TextStyle(
                  color: CorporateTokens.navy900,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          );
        },
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceAll('Exception: ', '').trim()),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _openingResumen = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(historialUrdidoProvider);
    final usuario = ref.watch(authProvider).user?.usuario ?? 'Operario';

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
                      _buildHeader(usuario),
                      const SizedBox(height: 10),
                      _buildFilterPanel(state),
                      const SizedBox(height: 10),
                      Expanded(child: _buildContent(state)),
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

  Widget _buildHeader(String usuario) {
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
                'Historial Urdido',
                style: TextStyle(
                  color: CorporateTokens.navy900,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Seguimiento productivo de $usuario',
                style: const TextStyle(
                  color: CorporateTokens.slate500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: _openingResumen ? null : _abrirResumenOperario,
          icon:
              _openingResumen
                  ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Icon(Icons.receipt_long_rounded, size: 18),
          label: const Text('Mis registros'),
        ),
      ],
    );
  }

  Widget _buildFilterPanel(HistorialUrdidoState state) {
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
          const Text(
            'Filtro de urdidora',
            style: TextStyle(
              color: CorporateTokens.navy900,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _filtros.map((filtro) {
                  final selected = _filtroSeleccionado == filtro;
                  return ChoiceChip(
                    label: Text(filtro),
                    selected: selected,
                    onSelected:
                        state.status == ProduccionHistorialStatus.loading
                            ? null
                            : (_) {
                              setState(() => _filtroSeleccionado = filtro);
                              _cargar();
                            },
                  );
                }).toList(),
          ),
          if ((state.infoMessage ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              state.infoMessage!,
              style: const TextStyle(
                color: CorporateTokens.slate500,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent(HistorialUrdidoState state) {
    switch (state.status) {
      case ProduccionHistorialStatus.initial:
      case ProduccionHistorialStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case ProduccionHistorialStatus.empty:
        return _EmptyState(
          icon: Icons.inbox_rounded,
          title: 'Sin registros',
          subtitle: state.infoMessage ?? 'No hay datos para este filtro.',
          actionLabel: 'Recargar',
          onAction: _cargar,
        );
      case ProduccionHistorialStatus.error:
        return _EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Error de consulta',
          subtitle: state.errorMessage ?? 'No se pudo cargar el historial.',
          actionLabel: 'Reintentar',
          onAction: _cargar,
          isError: true,
        );
      case ProduccionHistorialStatus.loaded:
        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 860) {
              return _buildWideTable(state.items);
            }
            return _buildCardList(state.items);
          },
        );
    }
  }

  Widget _buildWideTable(List<UrdidoHistorialTablaItem> items) {
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
                  DataColumn(label: Text('Codigo urdido')),
                  DataColumn(label: Text('Articulo')),
                  DataColumn(label: Text('Metros')),
                  DataColumn(label: Text('Peso hilos')),
                  DataColumn(label: Text('Fecha')),
                ],
                rows:
                    items.map((item) {
                      return DataRow(
                        cells: [
                          DataCell(Text(item.codigoUrdido)),
                          DataCell(Text(item.articulo)),
                          DataCell(Text(item.metrosUrdido)),
                          DataCell(Text(item.pesoHilosUrdido)),
                          DataCell(Text(item.fecha)),
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

  Widget _buildCardList(List<UrdidoHistorialTablaItem> items) {
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          return Container(
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.codigoUrdido,
                        style: const TextStyle(
                          color: CorporateTokens.navy900,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _badge(item.fecha),
                  ],
                ),
                const SizedBox(height: 8),
                _infoRow('Articulo', item.articulo),
                _infoRow('Metros', item.metrosUrdido),
                _infoRow('Peso hilos', item.pesoHilosUrdido),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: CorporateTokens.cobalt600.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: CorporateTokens.cobalt600,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: const TextStyle(
                color: CorporateTokens.slate500,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
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
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final Future<void> Function() onAction;
  final bool isError;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isError ? const Color(0xFFDC2626) : CorporateTokens.cobalt600;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 52, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: CorporateTokens.navy900,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: CorporateTokens.slate500,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
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
