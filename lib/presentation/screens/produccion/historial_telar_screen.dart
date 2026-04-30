import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/datasources/remote/produccion_remote_datasource.dart';
import '../../providers/produccion_historial_provider.dart';
import '../../widgets/enterprise_backdrop.dart';

class HistorialTelarScreen extends ConsumerStatefulWidget {
  const HistorialTelarScreen({super.key});

  @override
  ConsumerState<HistorialTelarScreen> createState() =>
      _HistorialTelarScreenState();
}

class _HistorialTelarScreenState extends ConsumerState<HistorialTelarScreen>
    with SingleTickerProviderStateMixin {
  static const List<String> _telarOptions = [
    'TODOS',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
  ];

  late final AnimationController _entryController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  String _filtroSeleccionado = 'TODOS';

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
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    await ref
        .read(historialTelarProvider.notifier)
        .cargar(telar: _filtroSeleccionado);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(historialTelarProvider);

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
                      _buildHeader(context),
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
                'Historial Telar',
                style: TextStyle(
                  color: CorporateTokens.navy900,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Consulta de registros de ingreso telar',
                style: TextStyle(color: CorporateTokens.slate500, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterPanel(HistorialTelarState state) {
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
            'Filtro de telar',
            style: TextStyle(
              color: CorporateTokens.navy900,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filtroSeleccionado,
                  items:
                      _telarOptions.map((item) {
                        return DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        );
                      }).toList(),
                  onChanged:
                      state.status == ProduccionHistorialStatus.loading
                          ? null
                          : (value) {
                            if (value == null) {
                              return;
                            }
                            setState(() => _filtroSeleccionado = value);
                          },
                  decoration: const InputDecoration(
                    labelText: 'Telar',
                    prefixIcon: Icon(Icons.filter_alt_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed:
                      state.status == ProduccionHistorialStatus.loading
                          ? null
                          : _cargar,
                  icon:
                      state.status == ProduccionHistorialStatus.loading
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Icon(Icons.search_rounded),
                  label: const Text('Cargar'),
                ),
              ),
            ],
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

  Widget _buildContent(HistorialTelarState state) {
    switch (state.status) {
      case ProduccionHistorialStatus.initial:
        return _InfoState(
          icon: Icons.filter_alt_rounded,
          title: 'Esperando filtro',
          subtitle: 'Seleccione un telar y cargue registros.',
          actionLabel: 'Cargar ahora',
          onAction: _cargar,
        );
      case ProduccionHistorialStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case ProduccionHistorialStatus.empty:
        return _InfoState(
          icon: Icons.inbox_rounded,
          title: 'Sin registros',
          subtitle: state.infoMessage ?? 'No se encontraron datos.',
          actionLabel: 'Reintentar',
          onAction: _cargar,
        );
      case ProduccionHistorialStatus.error:
        return _InfoState(
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
            if (constraints.maxWidth >= 980) {
              return _buildWideTable(state.items);
            }
            return _buildCardList(state.items);
          },
        );
    }
  }

  Widget _buildWideTable(List<TelarHistorialTablaItem> items) {
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
                  DataColumn(label: Text('Telar')),
                  DataColumn(label: Text('Articulo')),
                  DataColumn(label: Text('Hilos')),
                  DataColumn(label: Text('Titulo')),
                  DataColumn(label: Text('Mts')),
                  DataColumn(label: Text('Fecha inicio')),
                  DataColumn(label: Text('Peso')),
                  DataColumn(label: Text('Estado')),
                ],
                rows:
                    items.map((item) {
                      return DataRow(
                        cells: [
                          DataCell(Text(item.telar)),
                          DataCell(Text(item.articulo)),
                          DataCell(Text(item.hilos)),
                          DataCell(Text(item.titulo)),
                          DataCell(Text(item.mts)),
                          DataCell(Text(item.fechaInicio)),
                          DataCell(Text(item.pesoTotal)),
                          DataCell(_estadoChip(item.estado)),
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

  Widget _buildCardList(List<TelarHistorialTablaItem> items) {
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: CorporateTokens.cobalt600.withValues(
                          alpha: 0.10,
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Telar ${item.telar}',
                        style: const TextStyle(
                          color: CorporateTokens.cobalt600,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    _estadoChip(item.estado),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.articulo.isEmpty ? '-' : item.articulo,
                  style: const TextStyle(
                    color: CorporateTokens.navy900,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                _infoRow('Hilos', item.hilos),
                _infoRow('Titulo', item.titulo),
                _infoRow('Mts', item.mts),
                _infoRow('Fecha inicio', item.fechaInicio),
                _infoRow('Peso', item.pesoTotal),
                if (item.parcial.isNotEmpty) _infoRow('Parcial', item.parcial),
                if (item.caract.isNotEmpty) _infoRow('Caract', item.caract),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _estadoChip(String estado) {
    final normalized = estado.toUpperCase();
    final isCompletado = normalized.contains('COMPLETADO');
    final color =
        isCompletado ? const Color(0xFF16A34A) : CorporateTokens.cobalt600;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        estado.isEmpty ? '-' : estado,
        style: TextStyle(
          color: color,
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
            width: 88,
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

class _InfoState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final Future<void> Function() onAction;
  final bool isError;

  const _InfoState({
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
